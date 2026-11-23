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

# The Codex desktop settings template remains an onboarding reference.
python3 - "$root" <<'PYTEST'
import pathlib
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
with (root / "templates/codex-desktop.recommended.toml").open("rb") as handle:
    desktop = tomllib.load(handle)
agents = desktop["agents"]
assert desktop["model"] == "gpt-6.1-terra"
assert desktop["model_reasoning_effort"] == "medium"
assert agents["default_subagent_model"] == "gpt-6-luna"
assert "default_subagent_reasoning_effort" not in agents
PYTEST

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

# Bootstrap installs only the packaged Jax assets and preserves user-owned
# profiles and global instructions.
mkdir -p "$tmp/codex-home"
mkdir -p "$tmp/codex-home/agents"
printf 'keep this user profile\n' >"$tmp/codex-home/agents/personal-profile.toml"
printf 'legacy agent profile\n' >"$tmp/codex-home/agents/sol-security.toml"
printf 'user instructions\n' >"$tmp/codex-home/AGENTS.md"
python3 "$root/scripts/iron_box.py" activate-package "$tmp/codex-home" >"$tmp/bootstrap.out"
python3 "$root/scripts/iron_box.py" activate-package "$tmp/codex-home" >>"$tmp/bootstrap.out"
grep -Fq 'bootstrap: applied 2 package changes' "$tmp/bootstrap.out" || fail 'bootstrap did not create all package payloads'
grep -Fq 'bootstrap: already active' "$tmp/bootstrap.out" || fail 'bootstrap was not idempotent'
[[ "$(cat "$tmp/codex-home/agents/personal-profile.toml")" == 'keep this user profile' ]] || fail 'bootstrap changed an unrelated user profile'
[[ "$(cat "$tmp/codex-home/agents/sol-security.toml")" == 'legacy agent profile' ]] || fail 'bootstrap changed an agent definition'
[[ "$(cat "$tmp/codex-home/AGENTS.md")" == 'user instructions' ]] || fail 'bootstrap changed global AGENTS.md'

# Existing client-specific files remain untouched during activation.
upgrade_home="$tmp/upgrade-home"
mkdir -p "$upgrade_home/agents"
printf 'custom agent profile\n' >"$upgrade_home/agents/luna-worker.toml"
printf 'global instructions\n' >"$upgrade_home/AGENTS.md"
python3 "$root/scripts/iron_box.py" activate-package "$upgrade_home" >"$tmp/upgrade.out"
grep -Fq 'bootstrap: applied 2 package changes' "$tmp/upgrade.out" || fail 'activation did not install Jax assets'
[[ "$(cat "$upgrade_home/agents/luna-worker.toml")" == 'custom agent profile' ]] || fail 'activation changed a client-specific profile'
[[ "$(cat "$upgrade_home/AGENTS.md")" == 'global instructions' ]] || fail 'activation changed global AGENTS.md'

# Generic safety checks cover a clean install, dry-run, retry after an
# interrupted write, and a user file appearing after preflight.
python3 - "$root" "$tmp/bootstrap-safety" <<'PYTEST'
import pathlib
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
temporary = pathlib.Path(sys.argv[2])
sys.path.insert(0, str(root / "scripts"))
import iron_box


def activate(home):
    return subprocess.run(
        [sys.executable, str(root / "scripts/iron_box.py"), "activate-package", str(home)],
        capture_output=True,
        text=True,
    )


def expected_payloads():
    return {
        target: (root / source).read_bytes()
        for source, target in iron_box.BOOTSTRAP_FILES
    }


# A clean activation is retryable after a write fails partway through.
retry_home = temporary / "retry-after-failure"
payloads = expected_payloads()
original_write = iron_box._atomic_write
write_count = 0


def fail_after_two_writes(target, contents):
    global write_count
    write_count += 1
    if write_count > 1:
        raise OSError("injected persistent write failure")
    return original_write(target, contents)


iron_box._atomic_write = fail_after_two_writes
try:
    iron_box.activate_package(root, retry_home)
except OSError as error:
    assert str(error) == "injected persistent write failure"
else:
    raise AssertionError("activation unexpectedly succeeded after injected failure")
finally:
    iron_box._atomic_write = original_write
assert write_count == 2
assert (retry_home / "pets/jax/pet.json").read_bytes() == payloads["pets/jax/pet.json"]
assert not (retry_home / "pets/jax/spritesheet.webp").exists()

result = activate(retry_home)
assert result.returncode == 0, result.stderr
assert "bootstrap: applied 1 package changes" in result.stdout
for target, contents in payloads.items():
    assert (retry_home / target).read_bytes() == contents
assert activate(retry_home).stdout.strip() == "bootstrap: already active"

# Dry-run reports clean-install creates without creating target files.
dry_run_home = temporary / "dry-run"
result = subprocess.run(
    [sys.executable, str(root / "scripts/iron_box.py"), "activate-package", str(dry_run_home), "--dry-run"],
    capture_output=True,
    text=True,
)
assert result.returncode == 0, result.stderr
assert result.stdout.count("bootstrap: would create ") == len(iron_box.BOOTSTRAP_FILES)
assert not dry_run_home.exists()

# A target that appears after preflight remains intact and blocks activation.
concurrent_home = temporary / "concurrent-missing"
worker = concurrent_home / "pets/jax/pet.json"
concurrent_worker_bytes = b"external file appeared after preflight\n"
original_check = iron_box._assert_target_matches_snapshot
injected = False


def add_missing_before_check(home, target, expected):
    global injected
    if target == worker and expected is None and not injected:
        worker.parent.mkdir(parents=True, exist_ok=True)
        worker.write_bytes(concurrent_worker_bytes)
        injected = True
    return original_check(home, target, expected)


iron_box._assert_target_matches_snapshot = add_missing_before_check
try:
    iron_box.activate_package(root, concurrent_home)
except SystemExit as error:
    assert "changed after preflight" in str(error)
else:
    raise AssertionError("activation overwrote a target that appeared after preflight")
finally:
    iron_box._assert_target_matches_snapshot = original_check
assert worker.read_bytes() == concurrent_worker_bytes
PYTEST

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
