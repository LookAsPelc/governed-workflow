#!/usr/bin/env python3
"""Package validation and the bounded Iron Box runtime bootstrap.

Validation remains read-only.  ``activate-package`` is deliberately narrower
than an installer: after validation it creates only missing packaged role and
Jax asset files, preserves matching user files, rejects conflicts, and rolls
back files created by a failed invocation.  It never controls a client or
edits a user's broader configuration.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import tempfile
from pathlib import Path
from pathlib import PurePosixPath, PureWindowsPath
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
AGENT_PLUGINS_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"

# These files are Codex-specific provisioning payloads kept beside the
# portable Agent Plugins core.  The portable manifest intentionally does not
# expose client agents; Codex makes these definitions available through one
# bounded, idempotent activation operation.
BOOTSTRAP_FILES = (
    ("assets/codex/agents/luna-worker.toml", "agents/luna-worker.toml"),
    ("assets/codex/agents/luna-researcher.toml", "agents/luna-researcher.toml"),
    ("assets/codex/agents/luna-debugger.toml", "agents/luna-debugger.toml"),
    ("assets/codex/agents/luna-verifier.toml", "agents/luna-verifier.toml"),
    ("assets/codex/agents/sol-advisor.toml", "agents/sol-advisor.toml"),
    ("assets/codex/agents/sol-peer.toml", "agents/sol-peer.toml"),
    ("assets/pets/jax/pet.json", "pets/jax/pet.json"),
    ("assets/pets/jax/spritesheet.webp", "pets/jax/spritesheet.webp"),
)


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


def regular_directory(path: Path) -> None:
    """Reject a symlink or non-directory before using a package root."""
    if path.is_symlink():
        raise SystemExit(f"refusing symlink: {path}")
    if path.exists() and not path.is_dir():
        raise SystemExit(f"refusing non-directory: {path}")


def regular_target(path: Path, *, allow_missing: bool = True) -> None:
    """Reject symlinks and non-regular payload files."""
    if path.is_symlink():
        raise SystemExit(f"refusing symlink: {path}")
    if path.exists() and not path.is_file():
        raise SystemExit(f"refusing non-regular file: {path}")
    if not allow_missing and not path.exists():
        raise SystemExit(f"file not found: {path}")


def validate_portable_manifest(manifest: Any, *, expected_name: str, expected_version: str) -> None:
    """Validate only Iron Box's offline invariants for the portable manifest.

    Agent Plugins owns the manifest schema.  Runtime validation does not try to
    reproduce that external schema; it checks the package identity, version,
    schema declaration, and keeps client-only provisioning fields out of the
    portable core.
    """
    if not isinstance(manifest, dict):
        raise SystemExit("portable plugin.json must contain an object")
    if manifest.get("$schema") != AGENT_PLUGINS_SCHEMA:
        raise SystemExit("portable plugin.json must target Agent Plugins 1.0.0")
    if manifest.get("name") != expected_name:
        raise SystemExit("portable plugin.json identity mismatch")
    if manifest.get("version") != expected_version:
        raise SystemExit("portable plugin.json version mismatch")
    if any(field in manifest for field in ("agents", "skills", "category", "interface")):
        raise SystemExit(
            "portable plugin.json exposes client-specific provisioning fields"
        )


def validate_codex_plugin_manifest(
    manifest: Any, *, expected_name: str, expected_version: str
) -> None:
    """Validate the Codex plugin provisioning manifest used by Iron Box."""
    if not isinstance(manifest, dict):
        raise SystemExit("Codex plugin manifest must contain an object")
    if manifest.get("name") != expected_name:
        raise SystemExit("Codex plugin manifest identity mismatch")
    if manifest.get("version") != expected_version:
        raise SystemExit("Codex plugin manifest version mismatch")
    if manifest.get("skills") != "./skills/":
        raise SystemExit("Codex plugin manifest must expose ./skills/")


def validate_codex_marketplace_manifest(
    manifest: Any, *, expected_name: str
) -> None:
    """Validate that the Codex marketplace references the packaged plugin."""
    if not isinstance(manifest, dict) or not isinstance(manifest.get("plugins"), list):
        raise SystemExit("Codex marketplace must declare a plugins array")
    for plugin in manifest["plugins"]:
        if not isinstance(plugin, dict) or plugin.get("name") != expected_name:
            continue
        source = plugin.get("source")
        if not isinstance(source, dict) or source.get("source") != "local":
            continue
        if source.get("path") not in (".", "./"):
            continue
        return
    raise SystemExit("Codex marketplace does not reference the Iron Box plugin")


def validate_github_marketplace_manifest(
    manifest: Any, *, expected_name: str, expected_version: str
) -> None:
    """Validate the Copilot marketplace entry and its package version metadata."""
    if not isinstance(manifest, dict) or not isinstance(manifest.get("plugins"), list):
        raise SystemExit("GitHub marketplace must declare a plugins array")
    metadata = manifest.get("metadata")
    if not isinstance(metadata, dict) or metadata.get("version") != expected_version:
        raise SystemExit("GitHub marketplace metadata version mismatch")
    for plugin in manifest["plugins"]:
        if not isinstance(plugin, dict) or plugin.get("name") != expected_name:
            continue
        if plugin.get("version") != expected_version:
            raise SystemExit("GitHub marketplace Iron Box plugin version mismatch")
        if plugin.get("source") not in (".", "./"):
            raise SystemExit("GitHub marketplace Iron Box plugin source mismatch")
        return
    raise SystemExit("GitHub marketplace does not contain the Iron Box plugin")


def validate_package(
    package_root: Path = ROOT, *, require_development: bool = False
) -> dict[str, tuple[str, ...]]:
    """Validate the package sentinel and every declared payload file.

    Runtime validation is read-only and rejects symlinked path components so a
    malformed package cannot make the checker inspect a file outside its root.
    Development-only fixtures are checked when explicitly requested by CI.
    Optional payloads may be absent as a complete group, but a partially
    present group is rejected.
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
    if (
        payload.get("schemaVersion") != 1
        or payload.get("name") != "iron-box"
        or not isinstance(payload.get("version"), str)
    ):
        raise SystemExit(
            "package sentinel must declare schemaVersion 1, name iron-box, and a version"
        )

    expected_version = payload["version"]
    # The root manifest is the portable Agent Plugins contract.  The remaining
    # manifests are client/distribution compatibility layers and are checked
    # separately below; they do not replace or augment portable fields.
    portable_path = package_root / "plugin.json"
    regular_target(portable_path, allow_missing=False)
    try:
        portable = json.loads(portable_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SystemExit(f"invalid portable manifest plugin.json: {exc}") from exc
    validate_portable_manifest(
        portable, expected_name=payload["name"], expected_version=expected_version
    )

    # Client/distribution manifests have different semantics.  A marketplace
    # may have its own identity and metadata; only its Iron Box plugin entry is
    # coupled to the package identity/version where that host requires it.
    def read_client_manifest(manifest_name: str) -> Any:
        manifest_path = package_root / manifest_name
        regular_target(manifest_path, allow_missing=False)
        try:
            return json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise SystemExit(f"invalid package manifest {manifest_name}: {exc}") from exc

    try:
        validate_codex_plugin_manifest(
            read_client_manifest(".codex-plugin/plugin.json"),
            expected_name=payload["name"],
            expected_version=expected_version,
        )
        validate_codex_marketplace_manifest(
            read_client_manifest(".agents/plugins/marketplace.json"),
            expected_name=payload["name"],
        )
        validate_github_marketplace_manifest(
            read_client_manifest(".github/plugin/marketplace.json"),
            expected_name=payload["name"],
            expected_version=expected_version,
        )
    except SystemExit as exc:
        raise SystemExit(str(exc)) from exc

    result: dict[str, tuple[str, ...]] = {}
    for category in ("runtimeRequired", "developmentRequired", "optionalPayload"):
        declared = payload.get(category)
        if category == "optionalPayload" and declared is None:
            result[category] = ()
            continue
        if not isinstance(declared, list) or (
            category != "optionalPayload" and not declared
        ):
            raise SystemExit(
                f"package sentinel {category} must be a non-empty array"
            )
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
        raise SystemExit(
            "package path declared in both required and optional categories: "
            f"{sorted(optional_overlap)}"
        )

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
            if category == "optionalPayload" and not target.exists():
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


def package_status(package_root: Path = ROOT, *, require_development: bool = False) -> int:
    """Print a concise read-only validation result for CI."""
    manifest = validate_package(package_root, require_development=require_development)
    for category, paths in manifest.items():
        print(f"{category}: {len(paths)} files")
    print("package integrity: valid")
    return 0


def _atomic_copy(source: Path, target: Path) -> None:
    """Create one missing bootstrap file without exposing a partial write."""
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.", dir=str(target.parent))
    try:
        with os.fdopen(fd, "wb") as destination, source.open("rb") as origin:
            shutil.copyfileobj(origin, destination)
        os.replace(temporary, target)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def activate_package(package_root: Path, codex_home: Path, *, dry_run: bool = False) -> int:
    """Activate packaged roles and Jax assets as one idempotent operation.

    Existing matching files are left untouched.  A different existing file is
    a conflict, so activation fails before any write.  If a later copy fails,
    files created by this invocation are removed, giving the host a small,
    recoverable rollback boundary without overwriting user data.
    """
    manifest = validate_package(package_root)
    declared = set(manifest["runtimeRequired"])
    for source_relative, _ in BOOTSTRAP_FILES:
        if source_relative not in declared:
            raise SystemExit(f"bootstrap payload is not runtimeRequired: {source_relative}")
    regular_directory(codex_home)
    targets: list[tuple[Path, Path]] = []
    for source_relative, target_relative in BOOTSTRAP_FILES:
        source = package_root.joinpath(*source_relative.split("/"))
        target = codex_home.joinpath(*target_relative.split("/"))
        regular_target(source, allow_missing=False)
        current = codex_home
        for component in target.relative_to(codex_home).parts[:-1]:
            current = current / component
            regular_directory(current)
        regular_target(target)
        if target.exists() and target.read_bytes() != source.read_bytes():
            raise SystemExit(f"bootstrap conflict: {target}")
        targets.append((source, target))

    missing = [(source, target) for source, target in targets if not target.exists()]
    if dry_run:
        for _, target in missing:
            print(f"bootstrap: would create {target}")
        if not missing:
            print("bootstrap: already active")
        return 0

    created: list[Path] = []
    try:
        for source, target in missing:
            _atomic_copy(source, target)
            created.append(target)
    except BaseException:
        for target in reversed(created):
            try:
                target.unlink()
            except FileNotFoundError:
                pass
        raise
    if missing:
        print(f"bootstrap: activated {len(missing)} package files")
    else:
        print("bootstrap: already active")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate an Iron Box package or run its bounded package bootstrap."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    package_parser = subparsers.add_parser("validate-package")
    package_parser.add_argument("package_root", nargs="?", type=Path)
    package_parser.add_argument("--development", action="store_true")
    activate_parser = subparsers.add_parser(
        "activate-package",
        help="copy matching packaged roles and Jax assets into one CODEX_HOME",
    )
    activate_parser.add_argument("codex_home", type=Path)
    activate_parser.add_argument("package_root", nargs="?", type=Path)
    activate_parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if args.command == "validate-package":
        package_root = args.package_root or ROOT
        return package_status(package_root.expanduser(), require_development=args.development)
    if args.command == "activate-package":
        package_root = args.package_root or ROOT
        return activate_package(package_root.expanduser(), args.codex_home.expanduser(), dry_run=args.dry_run)
    parser.error("unknown command")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
