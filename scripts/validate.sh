#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v python3 >/dev/null 2>&1 || { echo "Python 3.11+ is required for offline JSON/frontmatter checks" >&2; exit 127; }
python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else "Python 3.11+ is required (tomllib is used by this validator)")'
# CI validates development fixtures too; the production command defaults to
# runtime-only completeness so an installed package need not ship test files.
python3 "$root/scripts/iron_box.py" validate-package --development

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
portable_data = tomllib.loads(portable_profile)
# The portable profile is a generic Multi-Agent V2 fragment.  Keep parsing it
# here for syntax validation, but do not impose the Desktop profile's settings
# (or an agents-only shape) on this intentionally smaller portable fragment.
if not isinstance(portable_data, dict):
    raise SystemExit("portable profile must contain a TOML table")
print("valid portable Iron Box TOML profile")
forbidden_profile_terms = re.compile(
    r"sandbox|approval|mcp|credential|token|project[ _-]?trust|(?:^|[= ])/(?:[^/\n]|$)|\\\\",
    re.IGNORECASE,
)
if forbidden_profile_terms.search(portable_profile):
    raise SystemExit("portable Iron Box profile contains a forbidden security, path, or trust setting")
print("portable profile excludes security, path, and trust settings")

desktop_profile_path = root / "templates" / "codex-desktop.recommended.toml"
with desktop_profile_path.open("rb") as handle:
    desktop_data = tomllib.load(handle)
expected_desktop = {
    "model": "gpt-5.6-terra",
    "approvals_reviewer": "auto_review",
    "features": {
        "memories": True,
        "default_mode_request_user_input": True,
        "fast_mode": False,
        "js_repl": False,
        "multi_agent_v2": {
            "enabled": True,
            "hide_spawn_agent_metadata": False,
            "expose_spawn_agent_model_overrides": True,
            "max_concurrent_threads_per_session": 4,
            "tool_namespace": "agents",
        },
    },
    "memories": {"generate_memories": True, "use_memories": True},
    "agents": {
        "enabled": True,
        "max_depth": 2,
        "default_subagent_model": "gpt-5.6-luna",
        "default_subagent_reasoning_effort": "high",
    },
    "sandbox_workspace_write": {"network_access": True},
    "desktop": {
        "followUpQueueMode": "steer",
        "conversationDetailMode": "STEPS_COMMANDS",
        "ambient-suggestions-enabled": True,
        "runCodexInWindowsSubsystemForLinux": True,
        "integratedTerminalShell": "wsl",
        "show-context-window-usage": True,
        "defaultTerminalLocation": "right",
        "usePointerCursors": True,
        "hotkey-window-projectless-default-enabled": True,
        "keepRemoteControlAwakeWhilePluggedIn": True,
        "selected-avatar-id": "custom:jax",
        "avatar-overlay-mascot-width-px": 224,
        "appearanceLightCodeThemeId": "everforest",
        "appearanceDarkCodeThemeId": "ayu",
        "appearanceTheme": "system",
        "enabled-reasoning-efforts": ["low", "medium", "high", "xhigh", "ultra", "max"],
    },
}


def assert_expected_values(actual, expected, path=""):
    unexpected = set(actual) - set(expected)
    if unexpected:
        names = ", ".join(sorted(unexpected))
        prefix = path or "Desktop profile"
        raise SystemExit(f"{prefix} contains unexpected setting(s): {names}")
    for key, expected_value in expected.items():
        key_path = f"{path}.{key}" if path else key
        if key not in actual:
            raise SystemExit(f"Desktop profile is missing {key_path!r}")
        actual_value = actual[key]
        if isinstance(expected_value, dict):
            if not isinstance(actual_value, dict):
                raise SystemExit(f"Desktop profile {key_path!r} must be a TOML table")
            assert_expected_values(actual_value, expected_value, key_path)
        elif actual_value != expected_value:
            raise SystemExit(
                f"Desktop profile {key_path!r} must be {expected_value!r}, got {actual_value!r}"
            )


assert_expected_values(desktop_data, expected_desktop)
print("Codex Desktop recommended profile has the expected TOML contract")

# The detailed Desktop-choice protocol lives in the onboarding reference so the
# injected SKILL stays below Codex's size limit.  Keep its safety boundaries
# executable rather than relying on prose review alone.
onboarding_text = (root / "skills" / "iron-box-onboarding" / "SKILL.md").read_text(encoding="utf-8")
setup_protocol = (root / "skills" / "iron-box-onboarding" / "references" / "setup-protocol.md").read_text(encoding="utf-8")
setup_contract = onboarding_text + "\n" + setup_protocol
for pattern, message in (
    (r"compatible\s+Codex\s+Desktop", "onboarding must gate the preset to compatible Codex Desktop"),
    (r"current\s+client/version.*document", "onboarding must verify current client/version documentation"),
    (r"accept,\s*decline,\s*or\s*customize\s+each\s+group", "onboarding must offer per-group choice"),
    (r"consent\s+before\s+writing", "onboarding must require consent before each accepted group write"),
    (r"never\s+use\s+a\s+shell\s+workaround", "onboarding must prohibit shell workarounds"),
    (r"Jax.*installed\s+and\s+visible", "onboarding must defer Jax selection until installed and visible"),
):
    if not re.search(pattern, setup_contract, re.IGNORECASE | re.DOTALL):
        raise SystemExit(message)
print("onboarding Desktop-preset consent and Jax gating contract present")

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
    ),
    root / "templates" / "iron-box.portable.toml": (
        "[features.multi_agent_v2]",
        "tool_namespace = \"agents\"",
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

# The orchestration skill is intentionally validated by contract-level
# identifiers rather than exact prose, so wording can evolve without making
# this offline check brittle.
orchestration_skill = root / "skills" / "iron-box-orchestration" / "SKILL.md"
orchestration_text = orchestration_skill.read_text(encoding="utf-8")
orchestration_lines = orchestration_text.splitlines()
orchestration_close = orchestration_lines[1:].index("---") + 1
orchestration_body = "\n".join(orchestration_lines[orchestration_close + 1 :])
if not all(
    re.search(pattern, orchestration_body, re.IGNORECASE | re.DOTALL)
    for pattern in (r"\bluna\b", r"new[- ]thread|delegate.{0,40}thread")
):
    raise SystemExit(
        "orchestration skill must define the Luna new-thread rule"
    )
for identifier in ("25x", "10x", "Max"):
    if identifier.lower() not in orchestration_body.lower():
        raise SystemExit(
            f"orchestration skill is missing model-routing cost identifier {identifier!r}"
        )
if not re.search(r"sol.{0,40}low", orchestration_body, re.IGNORECASE | re.DOTALL):
    raise SystemExit("orchestration skill is missing the Sol Low routing identifier")

# Keep these checks semantic and text-oriented: the contract may be rewritten,
# but it must retain the routing decisions and evidence obligations below.
def require_orchestration(pattern: str, message: str) -> None:
    if not re.search(pattern, orchestration_body, re.IGNORECASE | re.DOTALL):
        raise SystemExit(message)


require_orchestration(
    r"luna.{0,120}(?:max|xhigh).{0,180}(?:prefer|priority).{0,180}(?:before|ahead|prior).{0,180}sol\s+low",
    "orchestration skill must allow Luna Max preference before Sol Low",
)
require_orchestration(
    r"luna\s+(?:medium\s*\+|medium(?:/|\s+or\s+)high)|minimum\s+luna\s+medium",
    "orchestration skill must require Luna Medium or higher",
)
if re.search(r"luna\s+low", orchestration_body, re.IGNORECASE):
    raise SystemExit("orchestration skill must not route work to Luna Low")
require_orchestration(
    r"root.{0,100}(?:owns?|orchestrat|triage|scope)",
    "orchestration skill must establish root ownership or triage",
)
require_orchestration(
    r"(?:worker\s+report|worker.{0,30}escalat).{0,160}root",
    "orchestration skill must route worker reports or escalations through root",
)
# The diagram is the stable proof that Luna/Terra return to Root triage rather
# than acquiring direct worker-to-worker escalation authority.
require_orchestration(
    r"W\[Worker\s+report\].{0,80}R\{Root\s+triage\}",
    "orchestration skill must show worker reports entering Root triage",
)
for worker in ("L", "T"):
    require_orchestration(
        rf"\b{worker}(?:\[[^\]]+\])?\s*-->\s*[^\n]*\bR\b",
        f"orchestration skill must route {worker} reports back to Root",
    )

for identifier, pattern in {
    "context packet": r"context\s+packet",
    "objective": r"\bobjective\b",
    "settled decisions": r"settled\s+decisions?",
    "owned files/interfaces": r"owned\s+files?(?:\s+or\s+interfaces)?|owned\s+interfaces?",
    "acceptance and verification": r"acceptance.{0,40}verification",
    "relevant evidence": r"relevant\s+evidence",
    "known risks": r"known\s+risks?",
}.items():
    require_orchestration(
        pattern,
        f"orchestration skill context packet is missing {identifier}",
    )

require_orchestration(
    r"\bPASS\b.{0,220}(?:evidence.{0,140}every.{0,80}criterion|every.{0,80}criterion.{0,140}evidence)",
    "orchestration skill must define PASS as evidence for every criterion",
)
require_orchestration(
    r"\bREVISE\b.{0,180}(?:(?:correctable|correct)\s+deficien|deficien.{0,100}(?:correctable|correct))",
    "orchestration skill must define REVISE as a correctable deficiency",
)
require_orchestration(
    r"\bBLOCKED\b.{0,220}(?:missing.{0,120}(?:decision|access|proof)|(?:decision|access|proof).{0,120}missing)",
    "orchestration skill must define BLOCKED as missing decision, access, or proof",
)
client_terms = re.compile(r"\b(?:codex|copilot|v1|v2)\b", re.IGNORECASE)
match = client_terms.search(orchestration_text)
if match:
    raise SystemExit(
        "orchestration skill contains prohibited client-specific term "
        f"{match.group(0)!r}"
    )
print("valid orchestration skill portability, routing, escalation, and client-neutrality contracts")

codex_agents_dir = root / "assets" / "codex" / "agents"
expected_codex_roles = {
    "luna-worker.toml": {
        "name": "luna_worker",
        "model": "gpt-5.6-luna",
        "model_reasoning_effort": "high",
        "sandbox_mode": "workspace-write",
    },
    "terra-worker.toml": {
        "name": "terra_worker",
        "model": "gpt-5.6-terra",
        "sandbox_mode": "workspace-write",
        "omitted": {"model_reasoning_effort"},
    },
    "sol-advisor.toml": {
        "name": "sol_advisor",
        "model": "gpt-5.6-sol",
        "omitted": {"model_reasoning_effort", "sandbox_mode"},
        "read_only_text": ("description", "developer_instructions"),
    },
}
if not codex_agents_dir.is_dir():
    raise SystemExit("missing Codex role assets directory: assets/codex/agents")
for filename, expected in expected_codex_roles.items():
    path = codex_agents_dir / filename
    if not path.is_file():
        raise SystemExit(f"missing required Codex role asset: {path.relative_to(root)}")
    with path.open("rb") as handle:
        profile = tomllib.load(handle)
    for key in ("name", "model", "model_reasoning_effort", "sandbox_mode"):
        if key in expected and profile.get(key) != expected[key]:
            raise SystemExit(f"{path.relative_to(root)} must set {key!r} to {expected[key]!r}")
    for key in expected.get("omitted", set()):
        if key in profile:
            raise SystemExit(f"{path.relative_to(root)} must omit {key!r}")
    read_only_fields = expected.get("read_only_text", ())
    if read_only_fields and not any(
        "read-only" in str(profile.get(key, "")).lower() for key in read_only_fields
    ):
        raise SystemExit(f"{path.relative_to(root)} description/instructions must say read-only")
    print(f"valid Codex role asset: {path.relative_to(root)}")
PY

# bash -n is an offline parser and does not execute any harness action.
bash -n "$root"/scripts/*.sh "$root"/tests/test-iron-box-scripts.sh "$root"/tests/test-desktop-path.sh
python3 -m py_compile "$root/tests/check_desktop_path.py"
echo "valid shell: scripts/*.sh tests/test-iron-box-scripts.sh"
echo "offline validation passed"
