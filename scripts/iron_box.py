#!/usr/bin/env python3
"""Contributor-side validation for an Iron Box package.

This checker is intentionally read-only.  It validates the immutable package
sentinel and its declared payloads for CI/development use; it is not an
installer, client controller, status reporter, or configuration editor.
Runtime onboarding is performed by the host application's supported plugin
flow and must not invoke this module.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from pathlib import PurePosixPath, PureWindowsPath
from typing import Any


ROOT = Path(__file__).resolve().parent.parent


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
    # Iron Box currently targets Codex Desktop.  Validate only the Codex plugin
    # manifest and its local marketplace entry; legacy Copilot manifests are
    # intentionally not part of the package contract.
    manifest_paths = (
        ".codex-plugin/plugin.json",
        ".agents/plugins/marketplace.json",
    )
    for manifest_name in manifest_paths:
        manifest_path = package_root / manifest_name
        regular_target(manifest_path, allow_missing=False)
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise SystemExit(f"invalid package manifest {manifest_name}: {exc}") from exc
        if not isinstance(manifest, dict) or manifest.get("name") != payload["name"]:
            raise SystemExit(f"package manifest identity mismatch: {manifest_name}")
        versions = [manifest.get("version")]
        metadata = manifest.get("metadata")
        if isinstance(metadata, dict):
            versions.append(metadata.get("version"))
        plugins = manifest.get("plugins")
        if isinstance(plugins, list):
            for item in plugins:
                if isinstance(item, dict):
                    versions.append(item.get("version"))
                    if item.get("name") != payload["name"]:
                        raise SystemExit(
                            f"package manifest plugin identity mismatch: {manifest_name}"
                        )
        for version in versions:
            if version is not None and version != expected_version:
                raise SystemExit(f"package manifest version mismatch: {manifest_name}")

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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Read-only contributor validation for an Iron Box package."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    package_parser = subparsers.add_parser("validate-package")
    package_parser.add_argument("package_root", nargs="?", type=Path)
    package_parser.add_argument("--development", action="store_true")
    args = parser.parse_args()
    if args.command != "validate-package":  # pragma: no cover - argparse enforces this
        parser.error("unknown command")
    package_root = args.package_root or ROOT
    return package_status(package_root.expanduser(), require_development=args.development)


if __name__ == "__main__":
    raise SystemExit(main())
