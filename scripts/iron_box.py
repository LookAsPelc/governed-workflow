#!/usr/bin/env python3
"""Offline Iron Box status and explicitly-approved configuration edits.

This module deliberately uses only the Python standard library.  Status never
starts a client and apply only edits the small, allow-listed surfaces exposed by
the command line wrappers.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python 3.10 fallback message
    tomllib = None  # type: ignore[assignment]


ROOT = Path(__file__).resolve().parent.parent
PROFILE_PATH = ROOT / "templates" / "iron-box.portable.toml"
AGENTS_TEMPLATE = ROOT / "templates" / "AGENTS.global.recommended.md"
AGENTS_START = "<!-- iron-box:start -->"
AGENTS_END = "<!-- iron-box:end -->"
CODEX_ROLE_NAMES = ("luna-worker", "terra-worker", "sol-advisor")
CODEX_ROLE_ASSET_DIR = ROOT / "assets" / "codex" / "agents"


def codex_home() -> Path:
    value = os.environ.get("CODEX_HOME") or (
        str(Path(os.environ["HOME"]) / ".codex") if os.environ.get("HOME") else ""
    )
    if not value:
        raise SystemExit("HOME or CODEX_HOME must be set")
    return Path(value).expanduser()


def regular_target(path: Path, *, allow_missing: bool = True) -> None:
    if path.is_symlink():
        raise SystemExit(f"refusing symlink: {path}")
    if path.exists() and not path.is_file():
        raise SystemExit(f"refusing non-regular file: {path}")
    if not allow_missing and not path.exists():
        raise SystemExit(f"file not found: {path}")


def regular_directory(path: Path) -> None:
    """Reject a symlink or non-directory before using a directory as a root."""
    if path.is_symlink():
        raise SystemExit(f"refusing symlink: {path}")
    if path.exists() and not path.is_dir():
        raise SystemExit(f"refusing non-directory: {path}")


def atomic_write(path: Path, data: bytes, *, backup: bool = True) -> bool:
    regular_target(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    had_existing = path.exists()
    if backup and had_existing:
        backup_path = Path(str(path) + ".bak")
        regular_target(backup_path)
        backup_temporary: str | None = None
        try:
            backup_fd, backup_temporary = tempfile.mkstemp(prefix=f".{backup_path.name}.", dir=str(path.parent))
            with os.fdopen(backup_fd, "wb") as destination, path.open("rb") as source:
                shutil.copyfileobj(source, destination)
            os.chmod(backup_temporary, stat.S_IMODE(path.stat().st_mode))
            os.replace(backup_temporary, backup_path)
        except BaseException:
            if backup_temporary is not None:
                try:
                    os.unlink(backup_temporary)
                except FileNotFoundError:
                    pass
            raise
    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o644
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise
    return had_existing


def read_text(path: Path) -> str:
    regular_target(path, allow_missing=False)
    with path.open("r", encoding="utf-8", newline="") as handle:
        return handle.read()


def line_eol(line: str) -> str:
    if line.endswith("\r\n"):
        return "\r\n"
    if line.endswith(("\n", "\r")):
        return line[-1]
    return ""


def marker_bounds(text: str, start: str, end: str, label: str) -> tuple[int, int]:
    starts: list[tuple[int, int]] = []
    ends: list[tuple[int, int]] = []
    offset = 0
    for line in text.splitlines(keepends=True):
        logical = line.rstrip("\r\n")
        if start in logical:
            if logical.strip() != start:
                raise SystemExit(f"malformed inline Iron Box start marker in {label}")
            starts.append((offset, offset + len(line)))
        if end in logical:
            if logical.strip() != end:
                raise SystemExit(f"malformed inline Iron Box end marker in {label}")
            ends.append((offset, offset + len(line)))
        offset += len(line)
    if not starts and not ends:
        return -1, -1
    if len(starts) != 1 or len(ends) != 1:
        raise SystemExit(f"malformed Iron Box markers in {label}")
    if starts[0][0] > ends[0][0]:
        raise SystemExit(f"malformed Iron Box marker order in {label}")
    return starts[0][0], ends[0][1]


def update_agents(path: Path, *, dry_run: bool) -> None:
    regular_target(path)
    template = read_text(AGENTS_TEMPLATE)
    start, end = marker_bounds(template, AGENTS_START, AGENTS_END, str(AGENTS_TEMPLATE))
    if start < 0 or template[:start].strip() or template[end:].strip():
        raise SystemExit("managed AGENTS template must contain only one Iron Box block")
    block = template[start:end]
    original = read_text(path) if path.exists() else ""
    old_start, old_end = marker_bounds(original, AGENTS_START, AGENTS_END, str(path))
    if old_start < 0:
        eol = "\r\n" if "\r\n" in original else "\n"
        separator = eol if original and not original.endswith(("\n", "\r")) else ""
        updated = original + separator + block.replace("\n", eol)
    else:
        target_block = original[old_start:old_end]
        eol = "\r\n" if target_block.endswith("\r\n") else "\n"
        replacement = block.replace("\r\n", "\n").replace("\n", eol)
        if not line_eol(target_block):
            replacement = replacement.rstrip("\r\n")
        updated = original[:old_start] + replacement + original[old_end:]
    if updated == original:
        print(f"global AGENTS: unchanged ({path})")
    elif dry_run:
        print(f"global AGENTS: would update ({path})")
    else:
        had_existing = atomic_write(path, updated.encode("utf-8"), backup=True)
        suffix = f"; backup={path}.bak" if had_existing else ""
        print(f"global AGENTS: updated ({path}){suffix}")


def parse_toml(path: Path) -> dict[str, Any]:
    if tomllib is None:
        raise SystemExit("Python 3.11 or newer is required for TOML validation")
    try:
        with path.open("rb") as handle:
            value = tomllib.load(handle)
    except FileNotFoundError:
        return {}
    except (OSError, tomllib.TOMLDecodeError) as exc:
        raise SystemExit(f"malformed TOML {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise SystemExit(f"TOML root is not a table: {path}")
    return value


def flatten(table: dict[str, Any], prefix: tuple[str, ...] = ()) -> dict[tuple[str, ...], Any]:
    result: dict[tuple[str, ...], Any] = {}
    for key, value in table.items():
        current = prefix + (key,)
        if isinstance(value, dict):
            result.update(flatten(value, current))
        else:
            result[current] = value
    return result


def toml_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, int):
        return str(value)
    raise SystemExit(f"unsupported portable profile value: {value!r}")


def strip_toml_comment(line: str) -> str:
    quoted = False
    escaped = False
    for index, char in enumerate(line):
        if char == '"' and not escaped:
            quoted = not quoted
        if char == "#" and not quoted:
            return line[:index]
        escaped = char == "\\" and not escaped
        if char != "\\":
            escaped = False
    return line


KEY_RE = re.compile(r"^\s*([A-Za-z0-9_-]+(?:\s*\.\s*[A-Za-z0-9_-]+)*)\s*=")
SECTION_RE = re.compile(r"^\s*\[([^\[].*?)\]\s*$")
TARGET_TABLES = {"features", "memories", "agents", "desktop"}


def validate_config_structure(text: str) -> None:
    """Reject TOML spellings our line-preserving updater cannot safely edit."""
    section: tuple[str, ...] = ()
    for raw in text.splitlines(keepends=True):
        logical = strip_toml_comment(raw).strip()
        if not logical:
            continue
        if logical.startswith("[["):
            match = re.match(r"^\[\[\s*([^\].\s]+)", logical)
            if match and match.group(1) in TARGET_TABLES:
                raise SystemExit(f"unsafe array-table target in config: {match.group(1)}")
            section = ()
            continue
        section_match = SECTION_RE.match(logical)
        if section_match:
            raw_section = section_match.group(1)
            raw_parts = tuple(part.strip() for part in raw_section.split("."))
            parts = tuple(part.strip('"\'') for part in raw_parts)
            if parts and parts[0] in TARGET_TABLES and any(
                part.startswith(('"', "'")) for part in raw_parts
            ):
                raise SystemExit(f"unsafe quoted target table in config: [{raw_section}]")
            if len(parts) > 1 and parts[0] in TARGET_TABLES:
                raise SystemExit(f"unsafe nested target table in config: {'.'.join(parts)}")
            section = parts
            continue
        if "=" not in logical:
            continue
        left = logical.split("=", 1)[0].strip()
        if left.startswith(('"', "'")):
            raise SystemExit(f"unsafe quoted key in config: {left}")
        if not KEY_RE.match(logical):
            raise SystemExit(f"unsafe or unsupported key syntax in config: {left}")
        if not section and left.split(".", 1)[0].strip() in TARGET_TABLES:
            raise SystemExit(f"unsafe inline or dotted target table definition: {left}")


def config_key_occurrences(text: str) -> dict[tuple[str, ...], list[int]]:
    section: tuple[str, ...] = ()
    occurrences: dict[tuple[str, ...], list[int]] = {}
    for number, raw in enumerate(text.splitlines(keepends=True)):
        logical = strip_toml_comment(raw).strip()
        if not logical:
            continue
        if logical.startswith("[["):
            section = ()
            continue
        section_match = SECTION_RE.match(logical)
        if section_match:
            section = tuple(part.strip() for part in section_match.group(1).split("."))
            continue
        key_match = KEY_RE.match(logical)
        if key_match:
            key = tuple(part.strip() for part in key_match.group(1).split("."))
            occurrences.setdefault(section + key, []).append(number)
    return occurrences


def apply_profile(path: Path, *, dry_run: bool) -> None:
    profile = parse_toml(PROFILE_PATH)
    allowed = {
        ("model",),
        ("model_reasoning_effort",),
        ("features", "memories"),
        ("features", "default_mode_request_user_input"),
        ("memories", "generate_memories"),
        ("memories", "use_memories"),
        ("agents", "enabled"),
        ("agents", "max_threads"),
        ("agents", "max_depth"),
        ("agents", "default_subagent_model"),
        ("agents", "default_subagent_reasoning_effort"),
        ("desktop", "followUpQueueMode"),
        ("desktop", "keepRemoteControlAwakeWhilePluggedIn"),
        ("desktop", "usePointerCursors"),
        ("desktop", "conversationDetailMode"),
        ("desktop", "ambient-suggestions-enabled"),
        ("desktop", "show-context-window-usage"),
        ("desktop", "defaultTerminalLocation"),
        ("desktop", "hotkey-window-projectless-default-enabled"),
    }
    values = flatten(profile)
    unknown = set(values) - allowed
    if unknown:
        raise SystemExit(f"portable profile contains unsafe keys: {sorted(unknown)}")
    regular_target(path)
    original = read_text(path) if path.exists() else ""
    parse_toml(path) if path.exists() else {}
    validate_config_structure(original)
    occurrences = config_key_occurrences(original)
    for key in values:
        if len(occurrences.get(key, [])) > 1:
            raise SystemExit(f"duplicate target key in config: {'.'.join(key)}")
    if not original:
        lines = []
        for section in ((), ("features",), ("memories",), ("agents",), ("desktop",)):
            if section:
                lines.append("[" + ".".join(section) + "]\n")
            for key, value in values.items():
                if key[:-1] == section:
                    lines.append(f"{key[-1]} = {toml_value(value)}\n")
            if section:
                lines.append("\n")
        updated = "".join(lines)
    else:
        lines = original.splitlines(keepends=True)
        section: tuple[str, ...] = ()
        seen: set[tuple[str, ...]] = set()
        for index, raw in enumerate(lines):
            logical = strip_toml_comment(raw).strip()
            section_match = SECTION_RE.match(logical)
            if section_match:
                section = tuple(part.strip() for part in section_match.group(1).split("."))
                continue
            key_match = KEY_RE.match(logical)
            if not key_match:
                continue
            key = section + tuple(part.strip() for part in key_match.group(1).split("."))
            if key not in values:
                continue
            seen.add(key)
            newline = line_eol(raw)
            body = raw[:-len(newline)] if newline else raw
            equals = body.find("=")
            comment = ""
            value_part = body[equals + 1 :]
            if "#" in value_part:
                comment = " " + value_part[value_part.index("#") :].lstrip()
            lines[index] = body[: equals + 1] + " " + toml_value(values[key]) + comment + newline
        # Append absent keys inside an existing table rather than declaring a
        # duplicate table (which TOML correctly rejects). Unrelated bytes are
        # retained; only new lines are inserted at the end of each table.
        section_ranges: dict[tuple[str, ...], tuple[int, int]] = {}
        current: tuple[str, ...] = ()
        section_start = 0
        for index, raw in enumerate(lines):
            match = SECTION_RE.match(strip_toml_comment(raw).strip())
            if match:
                if current:
                    section_ranges[current] = (section_start, index)
                elif () not in section_ranges:
                    section_ranges[()] = (0, index)
                current = tuple(part.strip() for part in match.group(1).split("."))
                section_start = index
        section_ranges[current] = (section_start, len(lines))
        insertions: dict[int, list[str]] = {}
        deferred_sections: list[tuple[str, ...]] = []
        for wanted_section in ((), ("features",), ("memories",), ("agents",), ("desktop",)):
            missing = [key for key in values if key[:-1] == wanted_section and key not in seen]
            if not missing:
                continue
            if wanted_section in section_ranges:
                index = section_ranges[wanted_section][1]
                insertions.setdefault(index, [])
                insertions[index].extend(f"{key[-1]} = {toml_value(values[key])}\n" for key in missing)
            else:
                deferred_sections.append(wanted_section)
        if deferred_sections:
            if lines and not lines[-1].endswith(("\n", "\r")):
                lines[-1] += "\n"
            for wanted_section in deferred_sections:
                lines.append("[" + ".".join(wanted_section) + "]\n")
                lines.extend(
                    f"{key[-1]} = {toml_value(values[key])}\n"
                    for key in values
                    if key[:-1] == wanted_section and key not in seen
                )
                lines.append("\n")
        if insertions:
            lines = [
                line
                for index in range(len(lines) + 1)
                for line in ([*insertions.get(index, [])] + ([lines[index]] if index < len(lines) else []))
            ]
        updated = "".join(lines)
    if updated == original:
        print(f"portable profile: unchanged ({path})")
    elif dry_run:
        print(f"portable profile: would update ({path})")
    else:
        had_existing = atomic_write(path, updated.encode("utf-8"))
        suffix = f"; backup={path}.bak" if had_existing else ""
        print(f"portable profile: updated ({path}){suffix}")


def catalog_path(home: Path, config: Path) -> Path | None:
    if not config.exists():
        return None
    parsed = parse_toml(config)
    raw = parsed.get("model_catalog_json")
    if not isinstance(raw, str) or not raw:
        return None
    candidate = Path(raw).expanduser()
    if not candidate.is_absolute():
        candidate = home / candidate
    return candidate


def load_json(path: Path) -> Any:
    regular_target(path, allow_missing=False)

    def reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"duplicate JSON key: {key}")
            result[key] = value
        return result

    try:
        return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicate_keys)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        raise SystemExit(f"malformed JSON {path}: {exc}") from exc


def luna_version(payload: Any) -> str | None:
    if not isinstance(payload, dict) or not isinstance(payload.get("models"), list):
        return None
    versions = [m.get("multi_agent_version") for m in payload["models"] if isinstance(m, dict) and m.get("slug") == "gpt-5.6-luna"]
    if len(versions) != 1:
        return None
    return versions[0] if isinstance(versions[0], str) else None


def find_json_object(text: str, slug: str) -> tuple[int, int]:
    matches = list(re.finditer(r'"slug"\s*:\s*"' + re.escape(slug) + r'"', text))
    if len(matches) != 1:
        raise SystemExit(f"catalog must contain exactly one {slug} model")
    hit = matches[0]
    start = text.rfind("{", 0, hit.start())
    if start < 0:
        raise SystemExit("cannot locate Luna catalog object")
    depth = 0
    quote = False
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if quote:
            if char == '"' and not escaped:
                quote = False
            escaped = char == "\\" and not escaped
            if char != "\\":
                escaped = False
            continue
        if char == '"':
            quote = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return start, index + 1
    raise SystemExit("unterminated Luna catalog object")


def mutate_luna_catalog(path: Path, *, dry_run: bool) -> None:
    text = read_text(path)
    payload = load_json(path)
    if luna_version(payload) != "v1":
        raise SystemExit("native Luna fallback requires exactly one Luna entry with multi_agent_version=v1")
    start, end = find_json_object(text, "gpt-5.6-luna")
    object_text = text[start:end]
    matches = list(re.finditer(r'("multi_agent_version"\s*:\s*)"v1"', object_text))
    if len(matches) != 1:
        raise SystemExit("Luna object must contain exactly one multi_agent_version=v1")
    match = matches[0]
    updated = text[: start + match.start(0)] + match.group(1) + '"v2"' + text[start + match.end(0) :]
    if dry_run:
        print(f"native Luna V2: would update only Luna multi_agent_version in {path}")
    else:
        had_existing = atomic_write(path, updated.encode("utf-8"))
        suffix = f"; backup={path}.bak" if had_existing else ""
        print(f"native Luna V2: updated only Luna multi_agent_version in {path}{suffix}")


def copy_cache(home: Path, source: Path, *, dry_run: bool) -> None:
    regular_target(source, allow_missing=False)
    payload = load_json(source)
    if luna_version(payload) != "v2":
        raise SystemExit("fresh models_cache must contain Luna multi_agent_version=v2")
    target = home / "models_cache.json"
    if source.resolve() == target.resolve():
        print(f"models_cache: already current ({target})")
        return
    if dry_run:
        print(f"models_cache: would copy fresh cache {source} -> {target}")
    else:
        had_existing = atomic_write(target, source.read_bytes())
        suffix = f"; backup={target}.bak" if had_existing else ""
        print(f"models_cache: copied fresh cache to {target}{suffix}")


def codex_role_paths(home: Path) -> list[tuple[str, Path, Path]]:
    """Return the packaged role and CODEX_HOME destination for each role."""
    destination_dir = home / "agents"
    return [
        (name, CODEX_ROLE_ASSET_DIR / f"{name}.toml", destination_dir / f"{name}.toml")
        for name in CODEX_ROLE_NAMES
    ]


def install_codex_roles(home: Path, *, dry_run: bool, force: bool) -> None:
    """Install packaged Codex roles with an explicit apply and optional force.

    All targets are checked before the first write so a conflicting role cannot
    leave a partially-installed set behind.  Byte-identical targets are kept.
    """
    # Validate CODEX_HOME itself, not only its agents child.  Otherwise a
    # symlinked home could redirect all role writes outside the selected root.
    regular_directory(home)
    destination_dir = home / "agents"
    regular_directory(destination_dir)
    plans: list[tuple[str, Path, Path, bytes, bool, bytes | None, int | None]] = []
    for name, source, target in codex_role_paths(home):
        regular_target(source, allow_missing=False)
        regular_target(target)
        data = source.read_bytes()
        existing = target.exists()
        original = target.read_bytes() if existing else None
        original_mode = stat.S_IMODE(target.stat().st_mode) if existing else None
        identical = existing and target.read_bytes() == data
        if existing and not identical and not force:
            raise SystemExit(
                f"refusing differing managed Codex role target: {target}; use --force to replace"
            )
        plans.append((name, source, target, data, identical, original, original_mode))

    if dry_run:
        for name, source, target, _data, identical, _original, _mode in plans:
            if identical:
                print(f"Codex role {name}: unchanged ({target})")
            else:
                print(f"Codex role {name}: would install {source} -> {target}")
        return

    written: list[tuple[Path, bytes | None, int | None]] = []
    try:
        for name, source, target, data, identical, original, original_mode in plans:
            if identical:
                print(f"Codex role {name}: unchanged ({target})")
                continue
            # Include the current target before invoking the write so a
            # failure after os.replace is rolled back as well.
            written.append((target, original, original_mode))
            atomic_write(target, data, backup=False)
            print(f"Codex role {name}: installed {source} -> {target}")
    except BaseException:
        rollback_errors: list[BaseException] = []
        for target, original, original_mode in reversed(written):
            try:
                regular_target(target)
                if original is None:
                    if target.exists():
                        target.unlink()
                    continue
                # Rollback is deliberately independent of atomic_write so an
                # injected/late write failure cannot also break restoration.
                fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.rollback.", dir=str(target.parent))
                try:
                    with os.fdopen(fd, "wb") as handle:
                        handle.write(original)
                    os.chmod(temporary, original_mode or 0o644)
                    os.replace(temporary, target)
                except BaseException:
                    try:
                        os.unlink(temporary)
                    except FileNotFoundError:
                        pass
                    raise
            except BaseException as rollback_error:
                rollback_errors.append(rollback_error)
        if rollback_errors:
            details = "; ".join(str(error) for error in rollback_errors)
            raise RuntimeError(
                f"Codex role installation failed and rollback was incomplete: {details}"
            ) from rollback_errors[0]
        raise


def codex_roles_status(home: Path) -> None:
    for name, source, target in codex_role_paths(home):
        if not source.exists():
            state = "packaged asset missing"
        elif target.is_symlink() or (target.exists() and not target.is_file()):
            state = "different (destination is not a regular file)"
        elif not target.exists():
            state = "missing"
        elif target.read_bytes() == source.read_bytes():
            state = "matching"
        else:
            state = "different"
        print(f"Codex role {name}: {state} ({target})")


def set_catalog_config(config: Path, catalog: Path, *, dry_run: bool) -> None:
    # This is intentionally separate from the portable profile: an absolute
    # runtime path is only written by the explicit native fallback action.
    text = read_text(config) if config.exists() else ""
    parse_toml(config) if config.exists() else {}
    validate_config_structure(text)
    occurrences = config_key_occurrences(text)
    key = ("model_catalog_json",)
    if len(occurrences.get(key, [])) > 1:
        raise SystemExit("duplicate target key in config: model_catalog_json")
    rendered = toml_value(str(catalog))
    if not text:
        updated = f"model_catalog_json = {rendered}\n"
    elif key in occurrences:
        lines = text.splitlines(keepends=True)
        for index, raw in enumerate(lines):
            if index not in occurrences[key]:
                continue
            newline = line_eol(raw)
            body = raw[:-len(newline)] if newline else raw
            equals = body.find("=")
            lines[index] = body[: equals + 1] + " " + rendered + newline
        updated = "".join(lines)
    else:
        lines = text.splitlines(keepends=True)
        first_table = len(lines)
        for index, raw in enumerate(lines):
            logical = strip_toml_comment(raw).strip()
            if logical.startswith("["):
                first_table = index
                break
        insertion = f"model_catalog_json = {rendered}\n"
        if first_table > 0 and not lines[first_table - 1].endswith(("\n", "\r")):
            insertion = "\n" + insertion
        lines.insert(first_table, insertion)
        updated = "".join(lines)
    if updated == text:
        print(f"model_catalog_json: unchanged ({config})")
    elif dry_run:
        print(f"model_catalog_json: would set to derived catalog ({config})")
    else:
        had_existing = atomic_write(config, updated.encode("utf-8"))
        suffix = f"; backup={config}.bak" if had_existing else ""
        print(f"model_catalog_json: set derived catalog ({config}){suffix}")


def status() -> int:
    home = codex_home()
    config = home / "config.toml"
    print("Iron Box status (read-only; no client or network invocation)")
    codex_roles_status(home)
    for label, names in (("Codex", ("codex",)), ("Copilot", ("copilot", "github-copilot-cli"))):
        found = next((shutil.which(name) for name in names if shutil.which(name)), None)
        print(f"{label}: {'available (' + found + ')' if found else 'absent'}")
    if not config.exists():
        print(f"config: absent ({config})")
        print("catalog: not configured")
        print("browser capability: unknown (config absent)")
        print("computer-use capability: unknown (config absent)")
        print("native Luna V2: unknown")
        return 0
    try:
        parsed = parse_toml(config)
    except SystemExit as exc:
        print(f"config: malformed ({config}; {exc})")
        return 0
    print(f"config: present ({config})")
    plugins = parsed.get("plugins", {})
    if not isinstance(plugins, dict):
        plugins = {}
    plugin_names = {str(key).lower(): value for key, value in plugins.items()}
    shell_policy = parsed.get("shell_environment_policy", {})
    if not isinstance(shell_policy, dict):
        shell_policy = {}
    shell_set = shell_policy.get("set", {})
    if not isinstance(shell_set, dict):
        shell_set = {}
    mcp_servers = parsed.get("mcp_servers", {})
    if not isinstance(mcp_servers, dict):
        mcp_servers = {}
    mcp_text = json.dumps(mcp_servers, ensure_ascii=False).lower()
    for capability, needle in (("browser", "browser"), ("computer-use", "computer-use")):
        enabled = any(needle in key and isinstance(value, dict) and value.get("enabled") is True for key, value in plugin_names.items())
        if capability == "browser":
            enabled = enabled or bool(shell_set.get("BROWSER_USE_AVAILABLE_BACKENDS")) or "browser" in mcp_text
        else:
            enabled = enabled or str(shell_set.get("SKY_CUA_NATIVE_PIPE", "")) == "1" or "computer-use" in mcp_text
        print(f"{capability} capability: {'available' if enabled else 'unavailable'}")
    catalog = catalog_path(home, config)
    if catalog is None:
        print("catalog: not configured")
        print("native Luna V2: unknown (catalog not configured)")
        return 0
    if not catalog.exists():
        print(f"catalog: missing ({catalog})")
        print("native Luna V2: unknown (catalog missing)")
        return 0
    try:
        payload = load_json(catalog)
        version = luna_version(payload)
    except SystemExit as exc:
        print(f"catalog: malformed ({catalog}; {exc})")
        print("native Luna V2: unknown")
        return 0
    print(f"catalog: present ({catalog})")
    print(f"native Luna V2: {'compatible' if version == 'v2' else 'incompatible' if version == 'v1' else 'unknown'}")
    cache = home / "models_cache.json"
    if cache.exists():
        try:
            cache_version = luna_version(load_json(cache))
        except SystemExit:
            cache_version = None
        if version and cache_version and version != cache_version:
            print(f"native Luna override: STALE WARNING (catalog={version}, models_cache={cache_version})")
        elif version and cache_version is None:
            print("native Luna override: STALE WARNING (models_cache malformed or has no Luna entry)")
        else:
            print("native Luna override: clear")
    else:
        print("native Luna override: STALE WARNING (models_cache missing)")
    return 0


def apply_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Apply explicit Iron Box changes (dry-run by default).")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--write-global-agents", "--global-agents", action="store_true")
    parser.add_argument("--profile", "--apply-profile", "--portable-profile", action="store_true")
    parser.add_argument("--native-luna-v2", "--native-luna-fallback", action="store_true")
    parser.add_argument("--install-codex-roles", "--codex-roles", action="store_true")
    parser.add_argument("--force", action="store_true", help="replace differing managed Codex role targets")
    parser.add_argument("--copy-models-cache", "--refresh-models-cache", metavar="PATH", nargs="?", const="")
    args = parser.parse_args(argv)
    if args.copy_models_cache and not args.native_luna_v2:
        parser.error("--copy-models-cache requires --native-luna-v2")
    home = codex_home()
    config = home / "config.toml"
    dry = not args.apply
    if args.force and not args.install_codex_roles:
        parser.error("--force requires --install-codex-roles")
    if not (args.write_global_agents or args.profile or args.native_luna_v2 or args.install_codex_roles):
        print("no Iron Box action selected; use --write-global-agents, --profile, --native-luna-v2, or --install-codex-roles")
        print("dry-run complete; no changes were made" if dry else "apply complete; no changes were requested")
        return 0
    if args.write_global_agents:
        update_agents(home / "AGENTS.md", dry_run=dry)
    if args.profile:
        apply_profile(config, dry_run=dry)
    if args.install_codex_roles:
        install_codex_roles(home, dry_run=dry, force=args.force)
    if args.native_luna_v2:
        catalog = catalog_path(home, config)
        if catalog is None:
            catalog = home / "model-catalogs" / "desktop-multi-agent.json"
            print(f"native Luna V2: derived catalog path {catalog}")
        source = None
        if args.copy_models_cache is not None:
            source = Path(args.copy_models_cache).expanduser() if args.copy_models_cache else home / "models_cache.json"
        # Preflight every native target before the first write. A rejected
        # config (for example an unsafe quoted key) must not leave a mutated
        # catalog or refreshed cache behind.
        if args.apply:
            if source is not None:
                copy_cache(home, source, dry_run=True)
            mutate_luna_catalog(catalog, dry_run=True)
            set_catalog_config(config, catalog, dry_run=True)
        if source is not None:
            copy_cache(home, source, dry_run=dry)
        mutate_luna_catalog(catalog, dry_run=dry)
        set_catalog_config(config, catalog, dry_run=dry)
        print("native Luna fallback remains an explicit override; status reports stale mismatches")
    print("dry-run complete; no changes were made" if dry else "apply complete")
    return 0


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "status":
        return status()
    if len(sys.argv) > 1 and sys.argv[1] == "apply":
        return apply_main(sys.argv[2:])
    raise SystemExit("usage: iron_box.py {status|apply} ...")


if __name__ == "__main__":
    raise SystemExit(main())
