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
from pathlib import PurePosixPath, PureWindowsPath
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
PACKAGE_SENTINEL = ROOT / "iron-box-package.json"

# Codex loads custom roles from explicit registrations in config.toml.  Keep
# the registration path relative to CODEX_HOME so the package remains
# portable between Unix and Windows installations.
CODEX_ROLE_REGISTRATIONS = {
    "luna-worker": "luna_worker",
    "terra-worker": "terra_worker",
    "sol-advisor": "sol_advisor",
}


def _normalise_declared_path(value: Any) -> str:
    """Validate a package-relative POSIX path without touching the filesystem."""
    if not isinstance(value, str) or not value or "\\" in value:
        raise SystemExit(f"invalid package path: {value!r}")
    posix = PurePosixPath(value)
    windows = PureWindowsPath(value)
    if posix.is_absolute() or windows.is_absolute() or windows.drive:
        raise SystemExit(f"package path must be relative: {value!r}")
    parts = posix.parts
    if not parts or any(part in ("", ".", "..") for part in parts):
        raise SystemExit(f"package path is not normalized: {value!r}")
    normalized = "/".join(parts)
    if normalized != value:
        raise SystemExit(f"package path is not normalized: {value!r}")
    return normalized


def validate_package(package_root: Path = ROOT, *, require_development: bool = True) -> dict[str, tuple[str, ...]]:
    """Validate the immutable package manifest and all declared payload files.

    This is development/CI-only validation. It performs no writes and rejects
    symlinked path components so a package cannot escape its own root.
    """
    regular_directory(package_root)
    sentinel = package_root / "iron-box-package.json"
    regular_target(sentinel, allow_missing=False)
    try:
        payload = json.loads(sentinel.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SystemExit(f"invalid package sentinel {sentinel}: {exc}") from exc
    if not isinstance(payload, dict):
        raise SystemExit("package sentinel must contain an object")
    if payload.get("schemaVersion") != 1 or payload.get("name") != "iron-box" or not isinstance(payload.get("version"), str):
        raise SystemExit("package sentinel must declare schemaVersion 1, name iron-box, and a version")
    expected_version = payload["version"]
    manifest_paths = ("plugin.json", ".codex-plugin/plugin.json", ".agents/plugins/marketplace.json", ".github/plugin/marketplace.json")
    for manifest_name in manifest_paths:
        manifest_path = package_root / manifest_name
        regular_target(manifest_path, allow_missing=False)
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise SystemExit(f"invalid package manifest {manifest_name}: {exc}") from exc
        if manifest.get("name") != payload["name"]:
            raise SystemExit(f"package manifest identity mismatch: {manifest_name}")
        versions = [manifest.get("version"), manifest.get("metadata", {}).get("version")]
        versions.extend(item.get("version") for item in manifest.get("plugins", []) if isinstance(item, dict))
        for version in versions:
            if version is not None and version != expected_version:
                raise SystemExit(f"package manifest version mismatch: {manifest_name}")
        for item in manifest.get("plugins", []):
            if isinstance(item, dict) and item.get("name") != payload["name"]:
                raise SystemExit(f"package manifest plugin identity mismatch: {manifest_name}")
    result: dict[str, tuple[str, ...]] = {}
    for category in ("runtimeRequired", "developmentRequired", "optionalPayload"):
        declared = payload.get(category)
        if category == "optionalPayload" and declared is None:
            result[category] = ()
            continue
        if not isinstance(declared, list) or (category != "optionalPayload" and not declared):
            raise SystemExit(f"package sentinel {category} must be a non-empty array")
        paths = tuple(_normalise_declared_path(item) for item in declared)
        if len(set(paths)) != len(paths):
            raise SystemExit(f"package sentinel {category} contains duplicate paths")
        result[category] = paths
    overlap = set(result["runtimeRequired"]) & set(result["developmentRequired"])
    if overlap:
        raise SystemExit(f"package path declared in both categories: {sorted(overlap)}")
    optional_overlap = (
        set(result["runtimeRequired"]) | set(result["developmentRequired"])
    ) & set(result["optionalPayload"])
    if optional_overlap:
        raise SystemExit(f"package path declared in both required and optional categories: {sorted(optional_overlap)}")
    optional_groups: dict[str, list[Path]] = {}
    for category, paths in result.items():
        if category == "developmentRequired" and not require_development:
            continue
        for relative in paths:
            target = package_root.joinpath(*relative.split("/"))
            current = package_root
            for component in target.relative_to(package_root).parts:
                current = current / component
                if current.is_symlink():
                    raise SystemExit(f"package path escapes via symlink: {relative}")
            if category == "optionalPayload" and not target.exists() and not target.is_symlink():
                optional_groups.setdefault(str(Path(relative).parent), []).append(target)
                continue
            regular_target(target, allow_missing=False)
            if category == "optionalPayload":
                optional_groups.setdefault(str(Path(relative).parent), []).append(target)
    for group, targets in optional_groups.items():
        present = [target.exists() for target in targets]
        if any(present) and not all(present):
            raise SystemExit(f"optional payload group is incomplete: {group}")
    return result


def package_status(package_root: Path = ROOT) -> int:
    """Print package validation status for CI; never mutates the package."""
    manifest = validate_package(package_root)
    for category, paths in manifest.items():
        print(f"{category}: {len(paths)} files")
    print("package integrity: valid")
    return 0


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


def validate_config_structure(text: str, *, allow_role_registrations: bool = False) -> None:
    """Reject TOML spellings our line-preserving updater cannot safely edit.

    Profile edits intentionally reject nested ``[agents.*]`` tables.  Role
    installation is the one allow-listed operation that creates those tables,
    so it opts in explicitly while retaining all other structural safeguards.
    """
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
            if (
                len(parts) > 1
                and parts[0] in TARGET_TABLES
                and not (allow_role_registrations and parts[0] == "agents")
            ):
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


def codex_role_paths(home: Path) -> list[tuple[str, Path, Path]]:
    """Return the packaged role and CODEX_HOME destination for each role."""
    destination_dir = home / "agents"
    return [
        (name, CODEX_ROLE_ASSET_DIR / f"{name}.toml", destination_dir / f"{name}.toml")
        for name in CODEX_ROLE_NAMES
    ]


def codex_role_registration_values(
    role_name: str, source: Path
) -> tuple[str, str, str]:
    """Return the config key, portable path, and packaged description."""
    role_key = CODEX_ROLE_REGISTRATIONS[role_name]
    profile = parse_toml(source)
    description = profile.get("description")
    if not isinstance(description, str) or not description.strip():
        raise SystemExit(f"Codex role asset has no description: {source}")
    return role_key, f"agents/{source.name}", description


def _registration_config_update(
    original: str,
    registrations: list[tuple[str, str, str]],
    *,
    force: bool,
) -> tuple[str, dict[str, str]]:
    """Validate and line-preservingly add/update ``[agents.<role>]`` tables."""
    validate_config_structure(original, allow_role_registrations=True)
    if original:
        try:
            parsed = tomllib.loads(original)
        except tomllib.TOMLDecodeError as exc:
            raise SystemExit(f"malformed TOML config: {exc}") from exc
    else:
        parsed = {}
    agents = parsed.get("agents", {})
    if not isinstance(agents, dict):
        raise SystemExit("unsafe agents value in config; expected a table")
    expected = {
        role_key: {"config_file": config_file, "description": description}
        for role_key, config_file, description in registrations
    }
    registration_state: dict[str, str] = {}
    for role_key, values in expected.items():
        existing = agents.get(role_key)
        if existing is None:
            registration_state[role_key] = "missing"
            continue
        if not isinstance(existing, dict):
            raise SystemExit(f"unsafe agents.{role_key} registration in config")
        matching = all(existing.get(key) == value for key, value in values.items())
        registration_state[role_key] = "matching" if matching else "different"
        if not matching and not force:
            raise SystemExit(
                f"refusing differing Codex role registration agents.{role_key}; use --force to replace"
            )

    if not original:
        lines: list[str] = []
        for role_key, config_file, description in registrations:
            lines.extend(
                (
                    f"[agents.{role_key}]\n",
                    f"config_file = {toml_value(config_file)}\n",
                    f"description = {toml_value(description)}\n",
                    "\n",
                )
            )
        return "".join(lines), registration_state

    eol = "\r\n" if "\r\n" in original else "\n"
    lines = original.splitlines(keepends=True)
    section: tuple[str, ...] = ()
    seen: set[tuple[str, ...]] = set()
    wanted = {
        ("agents", role_key): values for role_key, values in expected.items()
    }
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
        values = wanted.get(key[:-1])
        if values is None or key[-1] not in values:
            continue
        seen.add(key)
        newline = line_eol(raw)
        body = raw[:-len(newline)] if newline else raw
        equals = body.find("=")
        value_part = body[equals + 1 :]
        comment = ""
        if "#" in value_part:
            comment = " " + value_part[value_part.index("#") :].lstrip()
        lines[index] = body[: equals + 1] + " " + toml_value(values[key[-1]]) + comment + newline

    # Add absent keys to an existing registration table, or append a new
    # table.  Existing unrelated keys/comments remain byte-for-byte intact.
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
    deferred: list[tuple[str, ...]] = []
    for section_name, values in wanted.items():
        missing = [
            key for key in values
            if section_name + (key,) not in seen
        ]
        if not missing:
            continue
        if section_name in section_ranges:
            insertions.setdefault(section_ranges[section_name][1], []).extend(
                f"{key} = {toml_value(values[key])}{eol}" for key in missing
            )
        else:
            deferred.append(section_name)
    if deferred:
        if lines and not lines[-1].endswith(("\n", "\r")):
            lines[-1] += eol
        for section_name in deferred:
            lines.append("[" + ".".join(section_name) + "]" + eol)
            lines.extend(
                f"{key} = {toml_value(expected[section_name[1]][key])}{eol}"
                for key in ("config_file", "description")
            )
            lines.append(eol)
    if insertions:
        lines = [
            line
            for index in range(len(lines) + 1)
            for line in ([*insertions.get(index, [])] + ([lines[index]] if index < len(lines) else []))
        ]
    return "".join(lines), registration_state


def install_codex_roles(home: Path, *, dry_run: bool, force: bool) -> None:
    """Install packaged Codex roles with an explicit apply and optional force.

    All targets are checked before the first write so a conflicting role cannot
    leave a partially-installed set behind.  Byte-identical targets are kept.
    """
    # Validate CODEX_HOME itself, not only its agents child.  Otherwise a
    # symlinked home could redirect all role writes outside the selected root.
    regular_directory(home)
    destination_dir = home / "agents"
    destination_preexisted = destination_dir.exists()
    regular_directory(destination_dir)
    plans: list[tuple[str, Path, Path, bytes, bool, bytes | None, int | None]] = []
    registrations: list[tuple[str, str, str]] = []
    for name, source, target in codex_role_paths(home):
        regular_target(source, allow_missing=False)
        regular_target(target)
        data = source.read_bytes()
        role_key, config_file, description = codex_role_registration_values(name, source)
        registrations.append((role_key, config_file, description))
        existing = target.exists()
        original = target.read_bytes() if existing else None
        original_mode = stat.S_IMODE(target.stat().st_mode) if existing else None
        identical = existing and target.read_bytes() == data
        if existing and not identical and not force:
            raise SystemExit(
                f"refusing differing managed Codex role target: {target}; use --force to replace"
            )
        plans.append((name, source, target, data, identical, original, original_mode))

    config_path = home / "config.toml"
    regular_target(config_path)
    original_config = read_text(config_path) if config_path.exists() else ""
    updated_config, registration_state = _registration_config_update(
        original_config, registrations, force=force
    )
    config_changed = updated_config != original_config
    config_backup = Path(str(config_path) + ".bak")
    regular_target(config_backup)

    if dry_run:
        for name, source, target, _data, identical, _original, _mode in plans:
            if identical:
                print(f"Codex role {name}: unchanged ({target})")
            else:
                print(f"Codex role {name}: would install {source} -> {target}")
        for role_key, _config_file, _description in registrations:
            state = registration_state[role_key]
            print(
                f"Codex role {role_key}: {state if state == 'matching' else 'would register'}"
                f" ({config_path})"
            )
        return

    written: list[tuple[Path, bytes | None, int | None]] = []
    config_backup_original = config_backup.read_bytes() if config_backup.exists() else None
    config_backup_mode = stat.S_IMODE(config_backup.stat().st_mode) if config_backup.exists() else None
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
        if config_changed:
            written.append(
                (
                    config_path,
                    original_config.encode("utf-8") if config_path.exists() else None,
                    stat.S_IMODE(config_path.stat().st_mode) if config_path.exists() else None,
                )
            )
            atomic_write(config_path, updated_config.encode("utf-8"), backup=True)
            print(f"Codex role registrations: updated ({config_path})")
        else:
            print(f"Codex role registrations: unchanged ({config_path})")
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
        try:
            regular_target(config_backup)
            if config_backup_original is None:
                if config_backup.exists():
                    config_backup.unlink()
            else:
                config_backup.write_bytes(config_backup_original)
                if config_backup_mode is not None:
                    os.chmod(config_backup, config_backup_mode)
        except BaseException as backup_error:
            raise RuntimeError(f"Codex role installation rollback failed for backup: {backup_error}") from backup_error
        if not destination_preexisted and destination_dir.exists():
            try:
                destination_dir.rmdir()
            except OSError:
                pass
        raise


def codex_roles_status(home: Path, config_data: dict[str, Any] | None = None) -> None:
    registrations: dict[str, Any] = {}
    if config_data is not None:
        agents = config_data.get("agents", {})
        if isinstance(agents, dict):
            registrations = agents
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
        role_key = CODEX_ROLE_REGISTRATIONS[name]
        registration = registrations.get(role_key)
        expected_path = f"agents/{source.name}"
        expected_description = None
        if source.exists() and source.is_file():
            try:
                expected_description = parse_toml(source).get("description")
            except SystemExit:
                expected_description = None
        registration_state = "missing"
        if isinstance(registration, dict):
            if (
                registration.get("config_file") == expected_path
                and isinstance(expected_description, str)
                and registration.get("description") == expected_description
            ):
                registration_state = "matching"
            else:
                registration_state = "different"
        print(
            f"Codex role {name}: {state}; registration {registration_state} ({target})"
        )


def status() -> int:
    home = codex_home()
    config = home / "config.toml"
    print("Iron Box status (read-only; no client or network invocation)")
    for label, names in (("Codex", ("codex",)), ("Copilot", ("copilot", "github-copilot-cli"))):
        found = next((shutil.which(name) for name in names if shutil.which(name)), None)
        print(f"{label}: {'available (' + found + ')' if found else 'absent'}")
    if not config.exists():
        codex_roles_status(home, {})
        print(f"config: absent ({config})")
        print("catalog: not configured")
        print("browser capability: not configured (not live-verified)")
        print("computer-use capability: not configured (not live-verified)")
        print("Luna compatibility: requires a live client probe")
        return 0
    try:
        parsed = parse_toml(config)
    except SystemExit as exc:
        codex_roles_status(home, None)
        print(f"config: malformed ({config}; {exc})")
        return 0
    codex_roles_status(home, parsed)
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
        print(f"{capability} capability: {'configured' if enabled else 'not configured'} (not live-verified)")
    raw_catalog = parsed.get("model_catalog_json")
    catalog = Path(raw_catalog).expanduser() if isinstance(raw_catalog, str) and raw_catalog else None
    if catalog is not None and not catalog.is_absolute():
        catalog = home / catalog
    if catalog is None:
        print("catalog: not configured")
        print("Luna compatibility: requires a live client probe (catalog not configured)")
        return 0
    if not catalog.exists():
        print(f"catalog: missing ({catalog})")
        print("Luna compatibility: requires a live client probe (catalog missing)")
        return 0
    try:
        catalog.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"catalog: unreadable ({catalog}; {exc})")
        print("Luna compatibility: requires a live client probe")
        return 0
    print(f"catalog: present ({catalog})")
    print("Luna compatibility: requires a live client probe")
    return 0


def apply_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Apply explicit Iron Box changes (dry-run by default).")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--write-global-agents", "--global-agents", action="store_true")
    parser.add_argument("--profile", "--apply-profile", "--portable-profile", action="store_true")
    parser.add_argument("--install-codex-roles", "--codex-roles", action="store_true")
    parser.add_argument("--force", action="store_true", help="replace differing managed Codex role targets")
    args = parser.parse_args(argv)
    home = codex_home()
    dry = not args.apply
    if args.force and not args.install_codex_roles:
        parser.error("--force requires --install-codex-roles")
    if not (args.write_global_agents or args.profile or args.install_codex_roles):
        print("no Iron Box action selected; use --write-global-agents, --profile, or --install-codex-roles")
        print("dry-run complete; no changes were made" if dry else "apply complete; no changes were requested")
        return 0
    if args.write_global_agents:
        update_agents(home / "AGENTS.md", dry_run=dry)
    if args.profile:
        apply_profile(home / "config.toml", dry_run=dry)
    if args.install_codex_roles:
        install_codex_roles(home, dry_run=dry, force=args.force)
    print("dry-run complete; no changes were made" if dry else "apply complete")
    return 0


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "validate-package":
        package_root = Path(sys.argv[2]).expanduser() if len(sys.argv) > 2 else ROOT
        if len(sys.argv) > 3:
            raise SystemExit("usage: iron_box.py validate-package [package-root]")
        return package_status(package_root)
    if len(sys.argv) > 1 and sys.argv[1] == "status":
        return status()
    if len(sys.argv) > 1 and sys.argv[1] == "apply":
        return apply_main(sys.argv[2:])
    raise SystemExit("usage: iron_box.py {status|apply} ...")


if __name__ == "__main__":
    raise SystemExit(main())
