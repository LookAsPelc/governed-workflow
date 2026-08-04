#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v python3 >/dev/null 2>&1 || { echo "python3 is required for offline JSON/frontmatter checks" >&2; exit 127; }

python3 - "$root" <<'PY'
import json
import pathlib
import re
import sys

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

public_name = "governed-workflow"
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
    raise SystemExit("all four manifests must use one governed-workflow identity")
print("consistent public manifest identity: governed-workflow")

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
start_marker = "<!-- governed-workflow:start -->"
end_marker = "<!-- governed-workflow:end -->"
if template.count(start_marker) != 1 or template.count(end_marker) != 1:
    raise SystemExit("managed AGENTS template must contain exactly one marker pair")
start_at = template.index(start_marker)
end_at = template.index(end_marker)
if start_at > end_at:
    raise SystemExit("managed AGENTS template markers are out of order")
if template[:start_at].strip() or template[end_at + len(end_marker):].strip():
    raise SystemExit("managed AGENTS template contains content outside its marker block")
print("valid managed AGENTS markers: templates/AGENTS.global.recommended.md")

# Project-owned prose must use the corrected public identity. The historical
# marker remains intentionally supported by apply-harness.sh and its tests;
# those compatibility files are excluded from this public-text check. Sol's
# upstream identifier is explicitly allowed by the negative lookbehind.
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

required_sol_identifiers = {
    root / "plugin.json": ("Sol-Governed Codex", "sol-governed"),
    root / ".codex-plugin" / "plugin.json": ("Sol-Governed Codex", "sol-governed"),
    root / ".github" / "plugin" / "marketplace.json": ("Sol-Governed",),
    root / "templates" / "AGENTS.global.recommended.md": ("sol-governed-workers",),
    root / "scripts" / "apply-harness.sh": ("sol-governed-workers",),
    root / "scripts" / "harness-status.sh": (
        "sol-governed-workers",
        "sol-governed.config.toml",
        "sol-governed-high.config.toml",
    ),
}
for path, identifiers in required_sol_identifiers.items():
    text = path.read_text(encoding="utf-8")
    missing = [identifier for identifier in identifiers if identifier not in text]
    if missing:
        raise SystemExit(
            f"{path.relative_to(root)} is missing required Sol identifiers: {', '.join(missing)}"
        )
print("required Sol identifiers retained")
PY

# bash -n is an offline parser and does not execute any harness action.
bash -n "$root"/scripts/*.sh "$root"/tests/test-harness-scripts.sh
echo "valid shell: scripts/*.sh tests/test-harness-scripts.sh"
echo "offline validation passed"
