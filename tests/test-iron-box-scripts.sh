#!/usr/bin/env bash
set -euo pipefail

# Contributor-side package tests. This file intentionally does not invoke a
# Codex/Copilot client. It validates the package and exercises the bounded,
# idempotent package bootstrap against an isolated temporary CODEX_HOME; the
# host application still owns the user-facing onboarding flow. The historical
# filename is retained so existing local CI commands continue to work.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/iron-box-package-tests.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
same() { cmp -s "$1" "$2" || fail "files differ: $1 $2"; }

validate() {
  python3 "$root/scripts/iron_box.py" validate-package "$@"
}

expect_invalid() {
  if validate "$@" >"$tmp/invalid.out" 2>&1; then
    fail "accepted invalid package: $1"
  fi
}

before="$tmp/sentinel.before"
cp "$root/iron-box-package.json" "$before"
validate "$root" >"$tmp/runtime.out"
validate "$root" --development >"$tmp/development.out"
grep -Fq 'package integrity: valid' "$tmp/runtime.out" || fail 'runtime validation did not pass'
grep -Fq 'package integrity: valid' "$tmp/development.out" || fail 'development validation did not pass'
same "$root/iron-box-package.json" "$before"

# The root manifest is the portable Agent Plugins 1.0 contract.  Client
# compatibility manifests remain separate and must not leak client-only fields
# such as agents/skills into the portable shape.
python3 - "$root" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
package = json.loads((root / "iron-box-package.json").read_text(encoding="utf-8"))
portable = json.loads((root / "plugin.json").read_text(encoding="utf-8"))
assert portable["$schema"] == "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
assert portable["name"] == package["name"] and portable["version"] == package["version"]
assert not {"agents", "skills", "category"}.intersection(portable)
assert "plugin.json" in package["runtimeRequired"]
assert ".github/plugin/marketplace.json" in package["runtimeRequired"]
codex = json.loads((root / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8"))
github = json.loads((root / ".github" / "plugin" / "marketplace.json").read_text(encoding="utf-8"))
assert codex["version"] == package["version"]
assert github["metadata"]["version"] == package["version"]
assert github["plugins"][0]["version"] == package["version"]
PY

# Codex profile assets are optional conveniences; dynamic task framing remains
# the manager's responsibility.
python3 - "$root" <<'PY'
import json
import pathlib
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
package = json.loads((root / "iron-box-package.json").read_text(encoding="utf-8"))

roles = {
    "luna-worker.toml": ("luna_worker", "gpt-6-luna", "workspace-write"),
    "luna-researcher.toml": ("luna_researcher", "gpt-6-luna", "read-only"),
    "luna-debugger.toml": ("luna_debugger", "gpt-6-luna", "workspace-write"),
    "luna-verifier.toml": ("luna_verifier", "gpt-6-luna", "read-only"),
    "sol-peer.toml": ("sol_peer", "gpt-6-sol", "read-only"),
}
for filename, (expected_name, expected_model, expected_sandbox) in roles.items():
    path = root / "assets" / "codex" / "agents" / filename
    with path.open("rb") as handle:
        role = tomllib.load(handle)
    assert role["name"] == expected_name
    assert role["model"] == expected_model
    assert "model_reasoning_effort" not in role
    assert role["sandbox_mode"] == expected_sandbox

assert {
    path for path in package["runtimeRequired"] if path.startswith("assets/codex/agents/")
} == {f"assets/codex/agents/{filename}" for filename in roles}

with (root / "templates" / "codex-desktop.recommended.toml").open("rb") as handle:
    desktop = tomllib.load(handle)
agents = desktop["agents"]
assert desktop["model"] == "gpt-6-sol"
assert desktop["model_reasoning_effort"] == "low"
assert agents["default_subagent_model"] == "gpt-6-luna"
assert "default_subagent_reasoning_effort" not in agents
PY

# Marketplace catalogs may carry independent names, while the Iron Box version
# remains coupled to the package metadata.
python3 - "$root" "$tmp/independent-marketplace" <<'PY'
import json
import pathlib
import shutil
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target)
codex = target / ".agents/plugins/marketplace.json"
catalog = json.loads(codex.read_text(encoding="utf-8"))
catalog["name"] = "team-catalog"
codex.write_text(json.dumps(catalog), encoding="utf-8")
github = target / ".github/plugin/marketplace.json"
catalog = json.loads(github.read_text(encoding="utf-8"))
catalog["name"] = "copilot-catalog"
github.write_text(json.dumps(catalog), encoding="utf-8")
subprocess.run(
    [sys.executable, str(target / "scripts/iron_box.py"), "validate-package", str(target)],
    check=True,
)
PY

# The checker exposes validation plus one bounded package bootstrap. It never
# retains the old installer/status entry points or AGENTS marker patcher.
if python3 "$root/scripts/iron_box.py" status >"$tmp/status.out" 2>&1; then
  fail 'legacy status command is still accepted'
fi
if python3 "$root/scripts/iron_box.py" apply >"$tmp/apply.out" 2>&1; then
  fail 'legacy apply command is still accepted'
fi
[[ ! -e "$root/scripts/apply-iron-box.sh" ]] || fail 'legacy apply wrapper remains'
[[ ! -e "$root/scripts/iron-box-status.sh" ]] || fail 'legacy status wrapper remains'
if grep -Fq '<!-- iron-box:' "$root/templates/AGENTS.global.recommended.md"; then
  fail 'marker machinery remains in AGENTS template'
fi

# Bootstrap is one idempotent operation: it creates missing role/Jax payloads,
# leaves matching files untouched, and refuses a conflicting user file.
mkdir -p "$tmp/codex-home"
python3 "$root/scripts/iron_box.py" activate-package "$tmp/codex-home" >"$tmp/bootstrap.out"
python3 "$root/scripts/iron_box.py" activate-package "$tmp/codex-home" >>"$tmp/bootstrap.out"
grep -Fq 'bootstrap: applied 7 package changes' "$tmp/bootstrap.out" || fail 'bootstrap did not create all package payloads'
grep -Fq 'bootstrap: already active' "$tmp/bootstrap.out" || fail 'bootstrap was not idempotent'
printf 'different role\n' >"$tmp/codex-home/agents/luna-worker.toml"
if python3 "$root/scripts/iron_box.py" activate-package "$tmp/codex-home" >"$tmp/bootstrap-conflict.out" 2>&1; then
  fail 'bootstrap accepted a conflicting role file'
fi

# Only exact profiles from the committed 0.3.1 payload may be replaced or
# retired. Fixtures are frozen from c526ce5775ff7239bd0069803cb688da0be7f280.
python3 - "$root" "$tmp/legacy-tests" <<'PY'
import hashlib
import pathlib
import shutil
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
temporary = pathlib.Path(sys.argv[2])
fixtures = root / "tests/fixtures/iron-box-0.3.1/agents"
current_profiles = {
    "luna-worker.toml": "agents/luna-worker.toml",
    "luna-researcher.toml": "agents/luna-researcher.toml",
    "luna-debugger.toml": "agents/luna-debugger.toml",
    "luna-verifier.toml": "agents/luna-verifier.toml",
    "sol-peer.toml": "agents/sol-peer.toml",
}
retired_profile = "agents/sol-advisor.toml"
sys.path.insert(0, str(root / "scripts"))
import iron_box

for filename, target in current_profiles.items():
    assert hashlib.sha256((fixtures / filename).read_bytes()).hexdigest() == iron_box.UPGRADABLE_PROFILE_SHA256[target]
assert hashlib.sha256((fixtures / "sol-advisor.toml").read_bytes()).hexdigest() == iron_box.RETIRED_PROFILE_SHA256[retired_profile]

def activate(home, dry_run=False):
    command = [sys.executable, str(root / "scripts/iron_box.py"), "activate-package", str(home)]
    if dry_run:
        command.append("--dry-run")
    return subprocess.run(command, capture_output=True, text=True)

# Exact old profiles upgrade, the retired profile is removed, and rerunning is
# idempotent after the 0.4.0 payloads are active.
upgrade = temporary / "upgrade"
upgrade_agents = upgrade / "agents"
upgrade_agents.mkdir(parents=True)
for filename in (*current_profiles, "sol-advisor.toml"):
    shutil.copyfile(fixtures / filename, upgrade_agents / filename)
result = activate(upgrade)
assert result.returncode == 0, result.stderr
assert "bootstrap: applied 8 package changes" in result.stdout
for filename, target in current_profiles.items():
    assert (upgrade / target).read_bytes() == (root / "assets/codex/agents" / filename).read_bytes()
assert not (upgrade / retired_profile).exists()
assert not list(upgrade_agents.glob(".*.iron-box-backup-*"))
assert activate(upgrade).stdout.strip() == "bootstrap: already active"

# Dry-run reports the planned upgrade and retirement without writing targets or
# staging backup files.
dry_run_home = temporary / "dry-run"
dry_run_agents = dry_run_home / "agents"
dry_run_agents.mkdir(parents=True)
shutil.copyfile(fixtures / "luna-worker.toml", dry_run_agents / "luna-worker.toml")
shutil.copyfile(fixtures / "sol-advisor.toml", dry_run_agents / "sol-advisor.toml")
before_worker = (dry_run_agents / "luna-worker.toml").read_bytes()
before_advisor = (dry_run_agents / "sol-advisor.toml").read_bytes()
result = activate(dry_run_home, dry_run=True)
assert result.returncode == 0, result.stderr
assert "bootstrap: would replace " in result.stdout
assert "bootstrap: would remove " in result.stdout
assert "bootstrap: would create " in result.stdout
assert (dry_run_agents / "luna-worker.toml").read_bytes() == before_worker
assert (dry_run_agents / "sol-advisor.toml").read_bytes() == before_advisor
assert not list(dry_run_agents.glob(".*.iron-box-backup-*"))
assert not (dry_run_home / "pets").exists()

# A modified legacy profile is a conflict. No earlier profile or asset is
# changed, even though several exact legacy profiles were already preflighted.
modified_legacy = temporary / "modified-legacy"
modified_agents = modified_legacy / "agents"
modified_agents.mkdir(parents=True)
for filename in current_profiles:
    shutil.copyfile(fixtures / filename, modified_agents / filename)
shutil.copyfile(fixtures / "sol-advisor.toml", modified_agents / "sol-advisor.toml")
changed_sol_peer = modified_agents / "sol-peer.toml"
changed_sol_peer.write_bytes(changed_sol_peer.read_bytes() + b"local edit\n")
result = activate(modified_legacy)
assert result.returncode != 0 and "bootstrap conflict" in result.stderr
assert (modified_agents / "luna-worker.toml").read_bytes() == (fixtures / "luna-worker.toml").read_bytes()
assert changed_sol_peer.read_bytes() == (fixtures / "sol-peer.toml").read_bytes() + b"local edit\n"
assert (modified_agents / "sol-advisor.toml").read_bytes() == (fixtures / "sol-advisor.toml").read_bytes()
assert not (modified_legacy / "pets").exists()

# A modified retired profile also blocks all otherwise-valid upgrades.
modified_retired = temporary / "modified-retired"
retired_agents = modified_retired / "agents"
retired_agents.mkdir(parents=True)
shutil.copyfile(fixtures / "luna-worker.toml", retired_agents / "luna-worker.toml")
shutil.copyfile(fixtures / "sol-advisor.toml", retired_agents / "sol-advisor.toml")
retired = retired_agents / "sol-advisor.toml"
retired.write_bytes(retired.read_bytes() + b"local edit\n")
result = activate(modified_retired)
assert result.returncode != 0 and "bootstrap conflict" in result.stderr
assert (retired_agents / "luna-worker.toml").read_bytes() == (fixtures / "luna-worker.toml").read_bytes()
assert retired.read_bytes() == (fixtures / "sol-advisor.toml").read_bytes() + b"local edit\n"
assert not (modified_retired / "pets").exists()

# If a later write keeps failing, restore both a previously upgraded profile
# and the retired file removed earlier without invoking that writer again.
rollback = temporary / "rollback"
rollback_agents = rollback / "agents"
rollback_agents.mkdir(parents=True)
shutil.copyfile(fixtures / "luna-worker.toml", rollback_agents / "luna-worker.toml")
shutil.copyfile(fixtures / "sol-advisor.toml", rollback_agents / "sol-advisor.toml")
original_write = iron_box._atomic_write
write_count = 0
failed = False

def fail_persistently_after_first_write(target, contents):
    global write_count, failed
    if failed:
        raise OSError("persistent simulated write failure")
    write_count += 1
    if write_count == 2:
        failed = True
        raise OSError("persistent simulated write failure")
    return original_write(target, contents)

iron_box._atomic_write = fail_persistently_after_first_write
try:
    iron_box.activate_package(root, rollback)
except OSError as error:
    assert str(error) == "persistent simulated write failure"
else:
    raise AssertionError("activation unexpectedly succeeded after injected failure")
finally:
    iron_box._atomic_write = original_write
assert write_count == 2
assert (rollback_agents / "luna-worker.toml").read_bytes() == (fixtures / "luna-worker.toml").read_bytes()
assert (rollback_agents / "sol-advisor.toml").read_bytes() == (fixtures / "sol-advisor.toml").read_bytes()
assert not (rollback_agents / "luna-researcher.toml").exists()
assert not (rollback / "pets").exists()
assert not list(rollback_agents.glob(".*.iron-box-backup-*"))

# A target edited after preflight is left intact; earlier changes are rolled
# back from staged copies when the immediately-before-write check detects it.
concurrent_existing = temporary / "concurrent-existing"
concurrent_agents = concurrent_existing / "agents"
concurrent_agents.mkdir(parents=True)
for filename in ("luna-worker.toml", "luna-researcher.toml", "sol-advisor.toml"):
    shutil.copyfile(fixtures / filename, concurrent_agents / filename)
researcher = concurrent_agents / "luna-researcher.toml"
concurrent_bytes = b"external edit after preflight\n"
original_check = iron_box._assert_target_matches_snapshot
injected = False

def edit_existing_before_check(home, target, expected):
    global injected
    if target == researcher and not injected:
        researcher.write_bytes(concurrent_bytes)
        injected = True
    return original_check(home, target, expected)

iron_box._assert_target_matches_snapshot = edit_existing_before_check
try:
    iron_box.activate_package(root, concurrent_existing)
except SystemExit as error:
    assert "changed after preflight" in str(error)
else:
    raise AssertionError("activation overwrote a profile changed after preflight")
finally:
    iron_box._assert_target_matches_snapshot = original_check
assert (concurrent_agents / "luna-worker.toml").read_bytes() == (fixtures / "luna-worker.toml").read_bytes()
assert researcher.read_bytes() == concurrent_bytes
assert (concurrent_agents / "sol-advisor.toml").read_bytes() == (fixtures / "sol-advisor.toml").read_bytes()
assert not list(concurrent_agents.glob(".*.iron-box-backup-*"))
assert not (concurrent_existing / "pets").exists()

# A target that was missing at preflight must remain absent until its own
# create step; a newly appeared user file blocks activation and stays intact.
concurrent_missing = temporary / "concurrent-missing"
missing_agents = concurrent_missing / "agents"
missing_agents.mkdir(parents=True)
shutil.copyfile(fixtures / "sol-advisor.toml", missing_agents / "sol-advisor.toml")
worker = missing_agents / "luna-worker.toml"
concurrent_worker_bytes = b"external file appeared after preflight\n"
injected = False

def add_missing_before_check(home, target, expected):
    global injected
    if target == worker and expected is None and not injected:
        worker.write_bytes(concurrent_worker_bytes)
        injected = True
    return original_check(home, target, expected)

iron_box._assert_target_matches_snapshot = add_missing_before_check
try:
    iron_box.activate_package(root, concurrent_missing)
except SystemExit as error:
    assert "changed after preflight" in str(error)
else:
    raise AssertionError("activation overwrote a target that appeared after preflight")
finally:
    iron_box._assert_target_matches_snapshot = original_check
assert worker.read_bytes() == concurrent_worker_bytes
assert (missing_agents / "sol-advisor.toml").read_bytes() == (fixtures / "sol-advisor.toml").read_bytes()
assert not list(missing_agents.glob(".*.iron-box-backup-*"))
assert not (concurrent_missing / "pets").exists()
PY

# Validate a runtime-only checkout after removing development fixtures. This
# protects the package contract from accidentally making CI-only files part of
# the installed payload.
python3 - "$root" "$tmp/runtime-only" <<'PY'
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target, ignore=shutil.ignore_patterns(".git", "__pycache__", "*.pyc"))
manifest = json.loads((target / "iron-box-package.json").read_text())
for relative in manifest["developmentRequired"]:
    path = target / relative
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()
PY
validate "$tmp/runtime-only" >"$tmp/runtime-only.out"

# Missing required payloads, malformed identity/version, path traversal, and
# symlink escapes must fail before any package mutation.
python3 - "$root" "$tmp/missing" <<'PY'
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target, symlinks=True)
manifest = json.loads((target / "iron-box-package.json").read_text())
(target / manifest["runtimeRequired"][-1]).unlink()
PY
expect_invalid "$tmp/missing"

python3 - "$root" "$tmp/wrong-identity" <<'PY'
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target, symlinks=True)
path = target / "iron-box-package.json"
data = json.loads(path.read_text())
data["name"] = "not-iron-box"
path.write_text(json.dumps(data))
PY
expect_invalid "$tmp/wrong-identity"

python3 - "$root" "$tmp/wrong-version" <<'PY'
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target, symlinks=True)
path = target / "iron-box-package.json"
data = json.loads(path.read_text())
data["version"] = "9.9.9"
path.write_text(json.dumps(data))
PY
expect_invalid "$tmp/wrong-version"

python3 - "$root" "$tmp/invalid-portable" <<'PY'
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target, symlinks=True)
path = target / "plugin.json"
data = json.loads(path.read_text(encoding="utf-8"))
data["agents"] = "agents/"
path.write_text(json.dumps(data))
PY
expect_invalid "$tmp/invalid-portable"

python3 - "$root" "$tmp/traversal" <<'PY'
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target, symlinks=True)
path = target / "iron-box-package.json"
data = json.loads(path.read_text())
data["runtimeRequired"] = ["../outside"]
path.write_text(json.dumps(data))
PY
expect_invalid "$tmp/traversal"

python3 - "$root" "$tmp/escaped" <<'PY'
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
shutil.copytree(root, target, symlinks=True)
outside = target / "outside.txt"
outside.write_text("outside")
(target / "escape").symlink_to(outside)
path = target / "iron-box-package.json"
data = json.loads(path.read_text())
data["optionalPayload"] = ["escape"]
path.write_text(json.dumps(data))
PY
expect_invalid "$tmp/escaped"

echo 'Iron Box contributor package tests passed'
