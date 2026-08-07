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
grep -Fq 'bootstrap: activated 5 package files' "$tmp/bootstrap.out" || fail 'bootstrap did not create all package payloads'
grep -Fq 'bootstrap: already active' "$tmp/bootstrap.out" || fail 'bootstrap was not idempotent'
printf 'different role\n' >"$tmp/codex-home/agents/luna-worker.toml"
if python3 "$root/scripts/iron_box.py" activate-package "$tmp/codex-home" >"$tmp/bootstrap-conflict.out" 2>&1; then
  fail 'bootstrap accepted a conflicting role file'
fi

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
