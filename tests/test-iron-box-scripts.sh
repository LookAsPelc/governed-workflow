#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/iron-box-tests.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
contains() { grep -Fq -- "$1" "$2" || fail "missing '$1' in $2"; }
same() { cmp -s "$1" "$2" || fail "files differ: $1 $2"; }

home="$tmp/codex-home"
mkdir -p "$home/model-catalogs"
printf 'unrelated\n' > "$home/AGENTS.md"
cp "$home/AGENTS.md" "$tmp/agents.before"

# Even --apply has no effect without an explicitly selected action.
CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --apply > "$tmp/no-action"
same "$home/AGENTS.md" "$tmp/agents.before"
contains 'no Iron Box action selected' "$tmp/no-action"

# New targets are written atomically without creating or claiming backups.
absent_home="$tmp/absent-home"
mkdir -p "$absent_home"
CODEX_HOME="$absent_home" bash "$root/scripts/apply-iron-box.sh" --apply --write-global-agents --profile > "$tmp/absent.apply"
[[ ! -e "$absent_home/AGENTS.md.bak" ]] || fail 'backup created for new AGENTS target'
[[ ! -e "$absent_home/config.toml.bak" ]] || fail 'backup created for new config target'
if grep -Fq 'backup=' "$tmp/absent.apply"; then fail 'new-target apply falsely reported backup'; fi

# Status is read-only and uses PATH lookup, never client execution.
fake_bin="$tmp/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nprintf executed > "$FAKE_EXEC_LOG"\n' > "$fake_bin/codex"
printf '#!/usr/bin/env bash\nprintf executed > "$FAKE_EXEC_LOG"\n' > "$fake_bin/copilot"
chmod +x "$fake_bin/codex" "$fake_bin/copilot"
PATH="$fake_bin:/usr/bin:/bin" FAKE_EXEC_LOG="$tmp/executed" CODEX_HOME="$home" \
  bash "$root/scripts/iron-box-status.sh" > "$tmp/status.absent"
contains 'Codex: available' "$tmp/status.absent"
contains 'Copilot: available' "$tmp/status.absent"
[[ ! -e "$tmp/executed" ]] || fail 'status executed a client'

# Build a representative config/catalog. Status reports configured capabilities
# without claiming that a live client probe passed.
cat > "$home/config.toml" <<EOF
model = "old"
model_catalog_json = "$home/model-catalogs/catalog.json"
secret = "preserve-me"
sandbox_mode = "workspace-write"
approvals_reviewer = "auto_review"

[plugins."browser@openai-bundled"]
enabled = true
[plugins."computer-use@openai-bundled"]
enabled = true
EOF
cat > "$home/model-catalogs/catalog.json" <<'EOF'
{
  "models": [
    {"slug": "gpt-5.6-luna", "multi_agent_version": "v1", "unrelated": "keep"},
    {"slug": "gpt-5.6-terra", "multi_agent_version": "v2", "unrelated": "keep"}
  ]
}
EOF
CODEX_HOME="$home" bash "$root/scripts/iron-box-status.sh" > "$tmp/status.v1"
contains 'browser capability: configured (not live-verified)' "$tmp/status.v1"
contains 'computer-use capability: configured (not live-verified)' "$tmp/status.v1"
contains 'Luna compatibility: requires a live client probe' "$tmp/status.v1"

# The removed native Luna override flags are rejected and must not mutate any
# catalog, cache, or config file.
cp "$home/config.toml" "$tmp/native.config.before"
cp "$home/model-catalogs/catalog.json" "$tmp/native.catalog.before"
if CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --apply --legacy-catalog-edit > "$tmp/native.removed" 2>&1; then
  fail 'removed native Luna flag accepted'
fi
same "$home/config.toml" "$tmp/native.config.before"
same "$home/model-catalogs/catalog.json" "$tmp/native.catalog.before"
contains 'unrecognized arguments' "$tmp/native.removed"

# Global AGENTS and portable profile are dry-runs by default and idempotent on
# explicit apply. Existing unrelated instructions and security settings stay.
CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --write-global-agents --profile > "$tmp/dry"
same "$home/AGENTS.md" "$tmp/agents.before"
[[ "$(grep -c 'iron-box:start' "$home/AGENTS.md" || true)" -eq 0 ]] || fail 'dry-run changed AGENTS'
contains 'dry-run complete' "$tmp/dry"
CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --apply --write-global-agents --profile > "$tmp/apply"
contains 'iron-box:start' "$home/AGENTS.md"
contains 'secret = "preserve-me"' "$home/config.toml"
contains 'sandbox_mode = "workspace-write"' "$home/config.toml"
contains 'approvals_reviewer = "auto_review"' "$home/config.toml"
contains '[plugins."browser@openai-bundled"]' "$home/config.toml"
python3 - "$home/config.toml" <<'PY'
import sys, tomllib
tomllib.load(open(sys.argv[1], "rb"))
PY
[[ -f "$home/config.toml.bak" ]] || fail 'profile backup missing'
[[ -f "$home/AGENTS.md.bak" ]] || fail 'AGENTS backup missing'
same "$home/AGENTS.md.bak" "$tmp/agents.before"
cp "$home/AGENTS.md" "$tmp/agents.after"
cp "$home/config.toml" "$tmp/config.after"
CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --apply --write-global-agents --profile > "$tmp/reapply"
same "$home/AGENTS.md" "$tmp/agents.after"
same "$home/config.toml" "$tmp/config.after"
contains 'unchanged' "$tmp/reapply"

# Malformed and duplicate managed AGENTS markers are rejected without writes.
for malformed in \
  $'before\n<!-- iron-box:start -->\npartial\n' \
  $'<!-- iron-box:start -->\none\n<!-- iron-box:start -->\ntwo\n<!-- iron-box:end -->\n'; do
  printf '%s' "$malformed" > "$home/AGENTS.md"
  cp "$home/AGENTS.md" "$tmp/agents.malformed.before"
  if CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --apply --write-global-agents > "$tmp/agents.malformed.out" 2>&1; then
    fail 'malformed AGENTS markers accepted'
  fi
  same "$home/AGENTS.md" "$tmp/agents.malformed.before"
  contains 'malformed Iron Box' "$tmp/agents.malformed.out"
done
printf 'unrelated\n' > "$home/AGENTS.md"

# Unsafe duplicate target keys and malformed TOML are rejected before a write.
cat > "$home/config.toml" <<'EOF'
model = "one"
model = "two"
EOF
cp "$home/config.toml" "$tmp/duplicate.before"
if CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --apply --profile > "$tmp/duplicate.out" 2>&1; then fail 'duplicate key accepted'; fi
same "$home/config.toml" "$tmp/duplicate.before"
contains 'malformed TOML' "$tmp/duplicate.out"

# Quoted root keys and target array/nested tables are unsafe for the
# line-preserving updater and must be rejected before any write.
for unsafe in \
  $'"model" = "one"\n' \
  $'["features"]\nmemories = false\n' \
  $'features = { memories = false }\n' \
  $'[[agents]]\nenabled = true\n' \
  $'[agents.nested]\nenabled = true\n'; do
  printf '%s' "$unsafe" > "$home/config.toml"
  cp "$home/config.toml" "$tmp/unsafe.before"
  if CODEX_HOME="$home" bash "$root/scripts/apply-iron-box.sh" --apply --profile > "$tmp/unsafe.out" 2>&1; then
    fail 'unsafe TOML target accepted'
  fi
  same "$home/config.toml" "$tmp/unsafe.before"
  contains 'unsafe' "$tmp/unsafe.out"
done


# Codex role installation is consent-gated, idempotent, and refuses managed
# drift unless --force is explicitly supplied.  Status remains read-only.
roles_home="$tmp/roles-home"
mkdir -p "$roles_home"
CODEX_HOME="$roles_home" bash "$root/scripts/apply-iron-box.sh" --install-codex-roles > "$tmp/roles.dry"
contains "would install" "$tmp/roles.dry"
[[ ! -e "$roles_home/agents" ]] || fail 'role dry-run created destination directory'
CODEX_HOME="$roles_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.apply"
for role in luna-worker terra-worker sol-advisor; do
  same "$root/assets/codex/agents/$role.toml" "$roles_home/agents/$role.toml"
  [[ "$(stat -c '%a' "$roles_home/agents/$role.toml")" == 644 ]] || fail "unexpected permissions for $role"
done
CODEX_HOME="$roles_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.reapply"
contains 'unchanged' "$tmp/roles.reapply"
printf 'drift\n' > "$roles_home/agents/luna-worker.toml"
cp "$roles_home/agents/luna-worker.toml" "$tmp/role.drift.before"
if CODEX_HOME="$roles_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.drift" 2>&1; then
  fail 'differing managed role accepted without --force'
fi
same "$roles_home/agents/luna-worker.toml" "$tmp/role.drift.before"
contains 'use --force' "$tmp/roles.drift"
CODEX_HOME="$roles_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles --force > "$tmp/roles.force"
same "$root/assets/codex/agents/luna-worker.toml" "$roles_home/agents/luna-worker.toml"
CODEX_HOME="$roles_home" bash "$root/scripts/iron-box-status.sh" > "$tmp/roles.status"
contains 'Codex role luna-worker: matching' "$tmp/roles.status"
contains 'Codex role terra-worker: matching' "$tmp/roles.status"
contains 'Codex role sol-advisor: matching' "$tmp/roles.status"

# Status distinguishes missing and differing targets without changing them.
status_home="$tmp/status-roles-home"
mkdir -p "$status_home/agents"
cp "$root/assets/codex/agents/luna-worker.toml" "$status_home/agents/luna-worker.toml"
printf 'different\n' > "$status_home/agents/terra-worker.toml"
CODEX_HOME="$status_home" bash "$root/scripts/iron-box-status.sh" > "$tmp/roles.status.mixed"
contains 'Codex role luna-worker: matching' "$tmp/roles.status.mixed"
contains 'Codex role terra-worker: different' "$tmp/roles.status.mixed"
contains 'Codex role sol-advisor: missing' "$tmp/roles.status.mixed"

# A symlinked target or agents directory is refused before any write.
symlink_target_home="$tmp/symlink-target-home"
mkdir -p "$symlink_target_home/agents"
ln -s "$tmp/role-link-target" "$symlink_target_home/agents/luna-worker.toml"
if CODEX_HOME="$symlink_target_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.symlink-target" 2>&1; then
  fail 'symlinked role target accepted'
fi
contains 'refusing symlink' "$tmp/roles.symlink-target"
[[ ! -e "$symlink_target_home/agents/terra-worker.toml" ]] || fail 'symlink refusal wrote a later role'
symlink_dir_home="$tmp/symlink-dir-home"
mkdir -p "$symlink_dir_home" "$tmp/real-agents"
ln -s "$tmp/real-agents" "$symlink_dir_home/agents"
if CODEX_HOME="$symlink_dir_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.symlink-dir" 2>&1; then
  fail 'symlinked agents directory accepted'
fi
contains 'refusing symlink' "$tmp/roles.symlink-dir"
[[ ! -e "$tmp/real-agents/luna-worker.toml" ]] || fail 'directory symlink refusal wrote a role'

# CODEX_HOME itself must be a real directory.  A symlink or regular file root
# is refused before role installation can redirect or partially create targets.
symlink_home="$tmp/symlink-home"
real_home="$tmp/real-home"
mkdir -p "$real_home"
ln -s "$real_home" "$symlink_home"
if CODEX_HOME="$symlink_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.symlink-home" 2>&1; then
  fail 'symlinked CODEX_HOME accepted'
fi
contains 'refusing symlink' "$tmp/roles.symlink-home"
[[ ! -e "$real_home/agents" ]] || fail 'symlinked CODEX_HOME wrote role directory'
file_home="$tmp/file-home"
printf 'not a directory\n' > "$file_home"
if CODEX_HOME="$file_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.file-home" 2>&1; then
  fail 'non-directory CODEX_HOME accepted'
fi
contains 'refusing non-directory' "$tmp/roles.file-home"

# A late write failure is transactional: an already-created role is removed
# and an overwritten role is restored byte-for-byte.  Inject after the second
# atomic replacement so rollback must cover both states.
python3 - "$root" "$tmp/late-role-home" <<'PY'
import importlib.util
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
home = pathlib.Path(sys.argv[2])
(home / "agents").mkdir(parents=True)
module_spec = importlib.util.spec_from_file_location("iron_box", root / "scripts" / "iron_box.py")
assert module_spec and module_spec.loader
iron_box = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(iron_box)

terra = home / "agents" / "terra-worker.toml"
sol = home / "agents" / "sol-advisor.toml"
terra.write_bytes(b"original terra\n")
sol.write_bytes(b"original sol\n")
before = {terra: terra.read_bytes(), sol: sol.read_bytes()}
real_atomic_write = iron_box.atomic_write
calls = 0

def fail_late(path, data, *, backup=True):
    global calls
    calls += 1
    result = real_atomic_write(path, data, backup=backup)
    if calls == 2:
        raise RuntimeError("injected late role-write failure")
    return result

iron_box.atomic_write = fail_late
try:
    iron_box.install_codex_roles(home, dry_run=False, force=True)
except RuntimeError as exc:
    assert str(exc) == "injected late role-write failure"
else:
    raise AssertionError("injected late role-write failure was not raised")

luna = home / "agents" / "luna-worker.toml"
assert not luna.exists(), "transaction left a newly-created role behind"
for path, data in before.items():
    assert path.read_bytes() == data, f"transaction failed to restore {path}"
PY

# A conflict in a later role proves the all-target preflight leaves earlier
# targets untouched; dry-run and refusal also leave the complete state intact.
conflict_home="$tmp/later-conflict-home"
mkdir -p "$conflict_home/agents"
printf 'later conflict\n' > "$conflict_home/agents/terra-worker.toml"
if CODEX_HOME="$conflict_home" bash "$root/scripts/apply-iron-box.sh" --apply --install-codex-roles > "$tmp/roles.later-conflict" 2>&1; then
  fail 'later role conflict accepted'
fi
contains 'use --force' "$tmp/roles.later-conflict"
[[ ! -e "$conflict_home/agents/luna-worker.toml" ]] || fail 'later conflict wrote earlier role'
CODEX_HOME="$conflict_home" bash "$root/scripts/apply-iron-box.sh" --install-codex-roles > "$tmp/roles.later-dry" 2>&1 || true
[[ ! -e "$conflict_home/agents/luna-worker.toml" ]] || fail 'conflict dry-run wrote earlier role'

# Integration-style parser check against the installed Codex binary.  It uses
# an isolated CODEX_HOME and `features list`: no model call, user config, or
# network.  The command must actually load the generated configuration.
if codex_bin="$(command -v codex 2>/dev/null)"; then
  parser_home="$tmp/parser-home"
  mkdir -p "$parser_home"
  CODEX_HOME="$parser_home" bash "$root/scripts/apply-iron-box.sh" --apply --profile --install-codex-roles > "$tmp/parser-install"
  if ! CODEX_HOME="$parser_home" "$codex_bin" features list > "$tmp/parser-check" 2>&1; then
    cat "$tmp/parser-check" >&2
    fail 'installed Codex rejected generated isolated config'
  fi
  malformed_home="$tmp/parser-malformed-home"
  mkdir -p "$malformed_home"
  printf 'model = [\n' > "$malformed_home/config.toml"
  if CODEX_HOME="$malformed_home" "$codex_bin" features list > "$tmp/parser-malformed" 2>&1; then
    fail 'Codex accepted malformed isolated config'
  fi
  contains 'TOML parse error' "$tmp/parser-malformed"
  echo 'Codex config load check passed (isolated CODEX_HOME; no model call)'
else
  echo 'Codex parser check skipped (codex not on PATH)'
fi

echo 'Iron Box script tests passed'
