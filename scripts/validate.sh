#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v python3 >/dev/null 2>&1 || { echo "python3 is required for offline JSON/frontmatter checks" >&2; exit 127; }

python3 - "$root" <<'PY'
import json
import pathlib
import re
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
json_files = [
    root / "plugin.json",
    root / ".codex-plugin" / "plugin.json",
    root / ".agents" / "plugins" / "marketplace.json",
    root / ".github" / "plugin" / "marketplace.json",
]
for path in json_files:
    with path.open(encoding="utf-8") as handle:
        json.load(handle)
    print(f"valid JSON: {path.relative_to(root)}")

public_name = "iron-box"
# Keep the historical spelling out of public validation output while still
# checking that manifests and prose do not reintroduce it.
legacy_name = "governed-" + "workers"
manifest_names = []
for path in json_files:
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    if payload.get("name") != public_name:
        raise SystemExit(
            f"manifest {path.relative_to(root)} must use {public_name!r}"
        )
    manifest_names.append(payload["name"])
    if "marketplace" in path.name:
        plugins = payload.get("plugins")
        if not isinstance(plugins, list) or not plugins:
            raise SystemExit(f"manifest {path.relative_to(root)} has no plugins")
        for plugin in plugins:
            if plugin.get("name") != public_name:
                raise SystemExit(
                    f"manifest plugin in {path.relative_to(root)} must use {public_name!r}"
                )
    raw = path.read_text(encoding="utf-8")
    if re.search(r"(?<!sol-)" + re.escape(legacy_name), raw):
        raise SystemExit(
            f"manifest {path.relative_to(root)} contains prohibited legacy identity {legacy_name!r}"
        )
if set(manifest_names) != {public_name}:
    raise SystemExit("all four manifests must use one iron-box identity")
print("consistent public manifest identity: iron-box")

frontmatter_files = [
    *root.glob("agents/*.md"),
    *root.glob("skills/*/SKILL.md"),
]
for path in frontmatter_files:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if len(lines) < 3 or lines[0] != "---" or "---" not in lines[1:]:
        raise SystemExit(f"missing frontmatter: {path.relative_to(root)}")
    close = lines[1:].index("---") + 1
    fields = {}
    for line in lines[1:close]:
        if ":" not in line:
            raise SystemExit(f"invalid frontmatter line in {path.relative_to(root)}: {line!r}")
        key, value = line.split(":", 1)
        if not key.strip() or not value.strip():
            raise SystemExit(f"empty frontmatter field in {path.relative_to(root)}: {line!r}")
        fields[key.strip()] = value.strip()
    for required in ("name", "description"):
        if not fields.get(required):
            raise SystemExit(f"missing frontmatter {required!r}: {path.relative_to(root)}")
    print(f"valid frontmatter: {path.relative_to(root)}")

template = (root / "templates" / "AGENTS.global.recommended.md").read_text(encoding="utf-8")
start_marker = "<!-- iron-box:start -->"
end_marker = "<!-- iron-box:end -->"
if template.count(start_marker) != 1 or template.count(end_marker) != 1:
    raise SystemExit("managed AGENTS template must contain exactly one marker pair")
start_at = template.index(start_marker)
end_at = template.index(end_marker)
if start_at > end_at:
    raise SystemExit("managed AGENTS template markers are out of order")
if template[:start_at].strip() or template[end_at + len(end_marker):].strip():
    raise SystemExit("managed AGENTS template contains content outside its marker block")
print("valid managed AGENTS markers: templates/AGENTS.global.recommended.md")

# Jax is an optional companion asset: installations may omit the entire
# assets/pets tree, but a checked-in Jax package must be self-consistent and
# match the Codex V2 atlas contract.  Keep this check dependency-free so the
# repository validator remains usable in a fresh checkout.
jax_dir = root / "assets" / "pets" / "jax"
if jax_dir.exists():
    if not jax_dir.is_dir():
        raise SystemExit("assets/pets/jax must be a directory when present")
    jax_manifest_path = jax_dir / "pet.json"
    with jax_manifest_path.open(encoding="utf-8") as handle:
        jax_manifest = json.load(handle)
    if not isinstance(jax_manifest, dict):
        raise SystemExit("assets/pets/jax/pet.json must contain an object")
    expected_jax = {
        "id": "jax",
        "displayName": "Jax",
        "spriteVersionNumber": 2,
        "spritesheetPath": "spritesheet.webp",
    }
    for key, value in expected_jax.items():
        if jax_manifest.get(key) != value:
            raise SystemExit(
                f"assets/pets/jax/pet.json must set {key!r} to {value!r}"
            )
    if (
        not isinstance(jax_manifest.get("description"), str)
        or not jax_manifest["description"].strip()
    ):
        raise SystemExit("assets/pets/jax/pet.json must contain a non-empty description")
    sprite_path = jax_dir / jax_manifest["spritesheetPath"]
    if sprite_path.parent != jax_dir or not sprite_path.is_file():
        raise SystemExit("assets/pets/jax spritesheetPath must name a local file")
    sprite = sprite_path.read_bytes()
    # VP8L stores width/height as two 14-bit little-endian values after the
    # 0x2f signature.  This avoids requiring Pillow or ImageMagick for checks.
    if (
        len(sprite) < 25
        or sprite[:4] != b"RIFF"
        or sprite[8:12] != b"WEBP"
        or sprite[12:16] != b"VP8L"
        or sprite[20] != 0x2F
    ):
        raise SystemExit("assets/pets/jax/spritesheet.webp must be a VP8L WebP")
    dimensions = int.from_bytes(sprite[21:25], "little")
    width = (dimensions & 0x3FFF) + 1
    height = ((dimensions >> 14) & 0x3FFF) + 1
    if (width, height) != (1536, 2288):
        raise SystemExit(
            f"assets/pets/jax/spritesheet.webp must be 1536x2288, got {width}x{height}"
        )
    print("valid optional Jax companion asset: assets/pets/jax")
else:
    print("optional Jax companion asset not present: skipped")

portable_profile = (root / "templates" / "iron-box.portable.toml").read_text(encoding="utf-8")
forbidden_profile_terms = re.compile(
    r"sandbox|approval|mcp|credential|token|project[ _-]?trust|(?:^|[= ])/(?:[^/\n]|$)|\\\\",
    re.IGNORECASE,
)
if forbidden_profile_terms.search(portable_profile):
    raise SystemExit("portable Iron Box profile contains a forbidden security, path, or trust setting")
print("portable profile excludes security, path, and trust settings")

# Project-owned prose must use the corrected public identity. The historical
# Sol's upstream identifier is explicitly allowed by the negative lookbehind.
public_text_files = [
    root / "LICENSE",
    root / "README.md",
    root / "docs" / "privacy.md",
    *root.glob("agents/*.md"),
    *root.glob("skills/**/*.md"),
    *root.glob("templates/*.md"),
]
legacy_pattern = re.compile(r"(?<!sol-)" + re.escape(legacy_name))
for path in public_text_files:
    text = path.read_text(encoding="utf-8")
    if legacy_pattern.search(text):
        raise SystemExit(
            f"project-owned text {path.relative_to(root)} contains prohibited legacy identity {legacy_name!r}"
        )
print("no prohibited project-owned legacy identity in public text")

required_iron_box_identifiers = {
    root / "templates" / "AGENTS.global.recommended.md": (
        "iron-box:start",
        "iron-box:end",
        "root agent is the orchestrator",
        "Never interrupt a running worker merely to change its reasoning level",
        "Sol is normally medium",
    ),
    root / "templates" / "iron-box.portable.toml": (
        "default_subagent_model = \"gpt-5.6-luna\"",
        "default_subagent_reasoning_effort = \"high\"",
    ),
    root / "scripts" / "iron-box-status.sh": ("read-only",),
    root / "scripts" / "apply-iron-box.sh": ("dry-run",),
}
for path, identifiers in required_iron_box_identifiers.items():
    text = path.read_text(encoding="utf-8")
    missing = [identifier for identifier in identifiers if identifier not in text]
    if missing:
        raise SystemExit(
            f"{path.relative_to(root)} is missing required Iron Box identifiers: {', '.join(missing)}"
        )
print("required Iron Box identifiers present")

codex_agents_dir = root / "assets" / "codex" / "agents"
expected_codex_roles = {
    "luna-worker.toml": ("luna_worker", "gpt-5.6-luna", "workspace-write"),
    "terra-worker.toml": ("terra_worker", "gpt-5.6-terra", "workspace-write"),
    "sol-advisor.toml": ("sol_advisor", "gpt-5.6-sol", "read-only"),
}
if not codex_agents_dir.is_dir():
    raise SystemExit("missing Codex role assets directory: assets/codex/agents")
for filename, (name, model, sandbox_mode) in expected_codex_roles.items():
    path = codex_agents_dir / filename
    if not path.is_file():
        raise SystemExit(f"missing required Codex role asset: {path.relative_to(root)}")
    with path.open("rb") as handle:
        profile = tomllib.load(handle)
    actual = (profile.get("name"), profile.get("model"), profile.get("sandbox_mode"))
    expected = (name, model, sandbox_mode)
    if actual != expected:
        raise SystemExit(
            f"{path.relative_to(root)} must set name/model/sandbox_mode to {expected!r}, got {actual!r}"
        )
    print(f"valid Codex role asset: {path.relative_to(root)}")
PY

# bash -n is an offline parser and does not execute any harness action.
bash -n "$root"/scripts/*.sh "$root"/tests/test-iron-box-scripts.sh
echo "valid shell: scripts/*.sh tests/test-iron-box-scripts.sh"
echo "offline validation passed"
