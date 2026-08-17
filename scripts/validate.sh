#!/usr/bin/env bash
set -euo pipefail

# Contributor/CI validation only. This script never installs a plugin, edits
# CODEX_HOME, invokes a client, or claims runtime capability.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v python3 >/dev/null 2>&1 || {
  echo "Python 3.11+ is required for contributor validation" >&2
  exit 127
}
python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else "Python 3.11+ is required (tomllib is used by this validator)")'
python3 "$root/scripts/iron_box.py" validate-package --development

python3 - "$root" <<'PY'
import json
import pathlib
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
for path in (*root.glob("agents/*.md"), *root.glob("skills/*/SKILL.md")):
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) < 3 or lines[0] != "---" or "---" not in lines[1:]:
        raise SystemExit(f"missing frontmatter: {path.relative_to(root)}")
    close = lines[1:].index("---") + 1
    fields = {}
    for line in lines[1:close]:
        if ":" not in line:
            raise SystemExit(f"invalid frontmatter: {path.relative_to(root)}")
        key, value = line.split(":", 1)
        if not key.strip() or not value.strip():
            raise SystemExit(f"empty frontmatter field: {path.relative_to(root)}")
        fields[key.strip()] = value.strip()
    if not fields.get("name") or not fields.get("description"):
        raise SystemExit(f"frontmatter needs name/description: {path.relative_to(root)}")
print("valid skill and agent frontmatter")

template = (root / "templates" / "AGENTS.global.recommended.md").read_text(encoding="utf-8")
if "iron-box:start" in template or "iron-box:end" in template:
    raise SystemExit("AGENTS template must be markerless")
print("valid markerless AGENTS template")

for filename, required in {
    "task.json": {"goal", "protected_constraints", "acceptance_criteria"},
    "state.json": {"remaining_todos", "verified_progress", "important_decisions", "blockers", "uncertainty", "do_not_reuse"},
}.items():
    path = root / "templates" / "iron-box-state" / filename
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or set(payload) != required:
        raise SystemExit(f"invalid durable-state template: {path.relative_to(root)}")
print("valid durable-state templates")

onboarding = root / "skills" / "iron-box-onboarding" / "SKILL.md"
if onboarding.stat().st_size > 6_000:
    raise SystemExit(f"onboarding skill exceeds 6000 bytes: {onboarding.stat().st_size}")
print(f"onboarding skill size: {onboarding.stat().st_size} bytes")

jax_dir = root / "assets" / "pets" / "jax"
jax = json.loads((jax_dir / "pet.json").read_text(encoding="utf-8"))
for key, expected in {
    "id": "jax",
    "displayName": "Jax",
    "spriteVersionNumber": 2,
    "spritesheetPath": "spritesheet.webp",
}.items():
    if jax.get(key) != expected:
        raise SystemExit(f"Jax pet manifest must set {key!r} to {expected!r}")
sprite_path = jax_dir / jax["spritesheetPath"]
sprite = sprite_path.read_bytes()
if (
    len(sprite) < 25
    or sprite[:4] != b"RIFF"
    or sprite[8:12] != b"WEBP"
    or sprite[12:16] != b"VP8L"
    or sprite[20] != 0x2F
):
    raise SystemExit("Jax spritesheet must be a VP8L WebP")
dimensions = int.from_bytes(sprite[21:25], "little")
width = (dimensions & 0x3FFF) + 1
height = ((dimensions >> 14) & 0x3FFF) + 1
if (width, height) != (1536, 2288):
    raise SystemExit(f"Jax spritesheet must be 1536x2288, got {width}x{height}")
print("valid Jax pet asset")

roles = {
    "luna-worker.toml": ("luna_worker", "gpt-5.6-luna", "workspace-write"),
    "luna-verifier.toml": ("luna_verifier", "gpt-5.6-luna", "read-only"),
    "sol-peer.toml": ("sol_peer", "gpt-5.6-sol", "read-only"),
}
roles_dir = root / "assets" / "codex" / "agents"
for filename, (name, model, sandbox) in roles.items():
    path = roles_dir / filename
    with path.open("rb") as handle:
        role = tomllib.load(handle)
    if (
        role.get("name") != name
        or role.get("model") != model
        or role.get("sandbox_mode") != sandbox
        or not isinstance(role.get("developer_instructions"), str)
    ):
        raise SystemExit(f"{path.relative_to(root)} has an invalid role identity")
print(f"valid Codex role assets: {len(roles)}")

with (root / "templates" / "codex-desktop.recommended.toml").open("rb") as handle:
    desktop = tomllib.load(handle)
agents = desktop.get("agents", {})
if (
    agents.get("default_subagent_model") != "gpt-5.6-luna"
    or agents.get("default_subagent_reasoning_effort") != "medium"
    or "max_depth" in agents
):
    raise SystemExit("invalid recommended Luna subagent configuration")
print("valid recommended Luna subagent configuration")
PY

# Syntax checks are local and do not execute any host client.
bash -n "$root"/scripts/*.sh "$root"/tests/test-iron-box-scripts.sh "$root"/tests/test-desktop-path.sh
python3 -m py_compile "$root/scripts/iron_box.py" "$root/tests/check_desktop_path.py" "$root/tests/test-marketplace-e2e.py"
echo "valid shell and Python syntax"
echo "offline validation passed"
