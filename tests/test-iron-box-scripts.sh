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
portable = json.loads((root / "plugin.json").read_text(encoding="utf-8"))
assert portable["$schema"] == "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
assert portable["name"] == "iron-box" and portable["version"] == "0.3.0"
assert not {"agents", "skills", "category"}.intersection(portable)
assert "plugin.json" in json.loads(
    (root / "iron-box-package.json").read_text(encoding="utf-8")
)["runtimeRequired"]
assert ".github/plugin/marketplace.json" in json.loads(
    (root / "iron-box-package.json").read_text(encoding="utf-8")
)["runtimeRequired"]
PY

# Stale Luna catalog or index mutation and Luna-only thread fallback wording must
# not return to tracked policy, docs, or executable files.  Thread mode is a
# global topology; the Codex role assets remain ordinary gpt-5.6-luna roles.
python3 - "$root" <<'PY'
import json
import pathlib
import subprocess
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
tracked = subprocess.check_output(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
    cwd=root,
    text=True,
).splitlines()
patterns = (
    "Luna catalog " + "compatibility",
    "V1/V2 " + "catalog",
    "catalog " + "copy",
    "model " + "catalog",
    "model " + "index",
    "Luna's preferred route is a new " + "thread",
    "For Luna's " + "route",
    "catalog/" + "index",
)
for relative in tracked:
    if relative.startswith("temp/"):
        continue
    path = root / relative
    if path.suffix.lower() not in {".md", ".py", ".sh", ".toml", ".json", ".yml", ".yaml"}:
        continue
    text = path.read_text(encoding="utf-8", errors="replace").casefold()
    for pattern in patterns:
        if pattern.casefold() in text:
            raise SystemExit(f"stale Luna/catalog wording in {relative}: {pattern}")

roles = {
    "luna-worker.toml": "luna_worker",
    "luna-researcher.toml": "luna_researcher",
    "luna-debugger.toml": "luna_debugger",
    "luna-verifier.toml": "luna_verifier",
}
for filename, expected_name in roles.items():
    path = root / "assets" / "codex" / "agents" / filename
    with path.open("rb") as handle:
        role = tomllib.load(handle)
    assert role["name"] == expected_name
    assert role["model"] == "gpt-5.6-luna"
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
grep -Fq 'bootstrap: activated 7 package files' "$tmp/bootstrap.out" || fail 'bootstrap did not create all package payloads'
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
