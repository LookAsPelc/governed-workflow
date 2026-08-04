#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/governed-workflow-tests.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file_equals() { cmp -s "$1" "$2" || fail "files differ: $1 $2"; }
assert_contains() { grep -Fq -- "$1" "$2" || fail "missing $1 in $2"; }
assert_rejected_unchanged() {
  local name="$1" content="$2" expected="${3:-malformed}"
  printf '%b' "$content" > "$home/AGENTS.md"
  cp "$home/AGENTS.md" "$tmp/$name.before"
  if CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply --write-global-agents > "$tmp/$name.out" 2>&1; then
    fail "$name malformed markers unexpectedly accepted"
  fi
  assert_file_equals "$home/AGENTS.md" "$tmp/$name.before"
  assert_contains "$expected" "$tmp/$name.out"
}

home="$tmp/codex-home"
mkdir -p "$home"
printf 'before\nuser instructions\n' > "$home/AGENTS.md"
cp "$home/AGENTS.md" "$tmp/before"

canonical_start='<!-- governed-workflow:start -->'
canonical_end='<!-- governed-workflow:end -->'
legacy_start='<!-- governed-workers:start -->'
legacy_end='<!-- governed-workers:end -->'

# The Sol skill and config paths are upstream identifiers, not this package's
# public name; keep their exact spelling unchanged while exercising migration.
grep -F 'sol-governed-workers' "$root/scripts/apply-harness.sh" > "$tmp/sol-paths.before"
grep -F 'sol-governed-workers' "$root/scripts/harness-status.sh" >> "$tmp/sol-paths.before"
assert_contains 'sol-governed-workers' "$root/templates/AGENTS.global.recommended.md"

# Default mode is read-only, even when the write flag is present.
CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --write-global-agents > "$tmp/dry-run.out"
assert_file_equals "$home/AGENTS.md" "$tmp/before"
assert_contains "dry-run complete" "$tmp/dry-run.out"

# Explicit apply writes the managed block and retains unrelated content.
CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply --write-global-agents > "$tmp/apply.out"
assert_contains "before" "$home/AGENTS.md"
assert_contains "user instructions" "$home/AGENTS.md"
assert_contains "$canonical_start" "$home/AGENTS.md"
assert_contains "$canonical_end" "$home/AGENTS.md"
cp "$home/AGENTS.md" "$tmp/after-first-apply"

# A second apply must be byte-for-byte idempotent.
CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply --write-global-agents > "$tmp/second.out"
assert_file_equals "$home/AGENTS.md" "$tmp/after-first-apply"
assert_contains "unchanged:" "$tmp/second.out"

# A single well-formed legacy block migrates only on explicit apply. The
# dry-run must leave the legacy bytes untouched, and the result has exactly
# one canonical block with no legacy markers.
printf '%b' "before\n$legacy_start\nlegacy instructions\n$legacy_end\nafter\n" > "$home/AGENTS.md"
cp "$home/AGENTS.md" "$tmp/legacy-before"
CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --write-global-agents > "$tmp/legacy-dry-run.out"
assert_file_equals "$home/AGENTS.md" "$tmp/legacy-before"
assert_contains "would update:" "$tmp/legacy-dry-run.out"
CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply --write-global-agents > "$tmp/legacy-apply.out"
assert_contains "before" "$home/AGENTS.md"
assert_contains "after" "$home/AGENTS.md"
assert_contains "$canonical_start" "$home/AGENTS.md"
assert_contains "$canonical_end" "$home/AGENTS.md"
! grep -Fq -- "$legacy_start" "$home/AGENTS.md" || fail "legacy start marker survived migration"
! grep -Fq -- "$legacy_end" "$home/AGENTS.md" || fail "legacy end marker survived migration"
[[ "$(grep -Fc -- "$canonical_start" "$home/AGENTS.md")" -eq 1 ]] || fail "migration duplicated canonical start marker"
[[ "$(grep -Fc -- "$canonical_end" "$home/AGENTS.md")" -eq 1 ]] || fail "migration duplicated canonical end marker"
cp "$home/AGENTS.md" "$tmp/legacy-after-first-apply"
CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply --write-global-agents > "$tmp/legacy-second.out"
assert_file_equals "$home/AGENTS.md" "$tmp/legacy-after-first-apply"
assert_contains "unchanged:" "$tmp/legacy-second.out"

# Every malformed shape is rejected before any target write, for both marker
# dialects. Mixed valid blocks are ambiguous and are also read-only rejects.
assert_rejected_unchanged canonical-missing-end "unrelated\n$canonical_start\npartial\n"
assert_rejected_unchanged canonical-missing-start "unrelated\npartial\n$canonical_end\n"
assert_rejected_unchanged canonical-reversed "$canonical_end\nold\n$canonical_start\n"
assert_rejected_unchanged canonical-duplicate "$canonical_start\nold\n$canonical_start\nold\n$canonical_end\n"
assert_rejected_unchanged canonical-inline-start "prefix $canonical_start\nold\n$canonical_end\n"
assert_rejected_unchanged canonical-inline-end "$canonical_start\nold\n$canonical_end suffix\n"
assert_rejected_unchanged legacy-missing-end "unrelated\n$legacy_start\npartial\n"
assert_rejected_unchanged legacy-missing-start "unrelated\npartial\n$legacy_end\n"
assert_rejected_unchanged legacy-reversed "$legacy_end\nold\n$legacy_start\n"
assert_rejected_unchanged legacy-duplicate "$legacy_start\nold\n$legacy_start\nold\n$legacy_end\n"
assert_rejected_unchanged legacy-inline-start "prefix $legacy_start\nold\n$legacy_end\n"
assert_rejected_unchanged legacy-inline-end "$legacy_start\nold\n$legacy_end suffix\n"
assert_rejected_unchanged both-names "$canonical_start\ncanonical\n$canonical_end\n$legacy_start\nlegacy\n$legacy_end\n" ambiguous

# Prefix and suffix CRLF bytes remain exact around the replaced block.
printf 'prefix\r\n<!-- governed-workers:start -->\r\nold\r\n<!-- governed-workers:end -->\r\nsuffix\r\n' > "$home/AGENTS.md"
CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply --write-global-agents >/dev/null
python3 - "$home/AGENTS.md" <<'PY'
import pathlib
import sys

data = pathlib.Path(sys.argv[1]).read_bytes()
assert data.startswith(b"prefix\r\n"), data[:20]
assert data.endswith(b"\r\nsuffix\r\n"), data[-20:]
assert data.count(b"<!-- governed-workflow:start -->") == 1
assert data.count(b"<!-- governed-workflow:end -->") == 1
assert b"<!-- governed-workers:start -->" not in data
assert b"<!-- governed-workers:end -->" not in data
PY

# Status checks PATH only; fake clients must not be executed.
fake_bin="$tmp/fake-bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nprintf executed > "$FAKE_EXEC_LOG"\n' > "$fake_bin/codex"
cp "$fake_bin/codex" "$fake_bin/copilot"
chmod +x "$fake_bin/codex" "$fake_bin/copilot"
PATH="$fake_bin:/usr/bin:/bin" FAKE_EXEC_LOG="$tmp/client-executed" CODEX_HOME="$home" \
  bash "$root/scripts/harness-status.sh" > "$tmp/status.out"
assert_contains "codex: present" "$tmp/status.out"
assert_contains "copilot: present" "$tmp/status.out"
[[ ! -e "$tmp/client-executed" ]] || fail "status executed a client binary"

# HOME fallback is exactly $HOME/.codex when CODEX_HOME is unset.
fallback_home="$tmp/fallback-home"
HOME="$fallback_home" env -u CODEX_HOME bash "$root/scripts/apply-harness.sh" --apply --write-global-agents >/dev/null
[[ -f "$fallback_home/.codex/AGENTS.md" ]] || fail "HOME fallback did not use .codex"

# A reviewed installer runs only after --apply and receives no --force.
sol_skill="$tmp/reviewed-sol"
mkdir -p "$sol_skill/scripts"
printf '#!/usr/bin/env bash\nprintf "ARGS:%%s\\n" "$*" > "$INSTALL_LOG"\n' > "$sol_skill/scripts/install_global_infra.sh"
printf '#!/usr/bin/env bash\nprintf "validated:%%s\\n" "$*" >> "$INSTALL_LOG"\n' > "$sol_skill/scripts/validate_setup.sh"
chmod +x "$sol_skill/scripts"/*.sh
INSTALL_LOG="$tmp/installer.log" CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --install-sol "$sol_skill" >/dev/null
[[ ! -e "$tmp/installer.log" ]] || fail "installer ran during dry-run"
INSTALL_LOG="$tmp/installer.log" CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply --install-sol "$sol_skill" >/dev/null
assert_contains "ARGS:" "$tmp/installer.log"
! grep -Fq -- '--force' "$tmp/installer.log" || fail "installer was forced"

# Validation is opt-in and is always explicitly offline.
rm -f "$tmp/installer.log"
INSTALL_LOG="$tmp/installer.log" CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --apply >/dev/null
[[ ! -e "$tmp/installer.log" ]] || fail "validator ran without --validate-sol"
INSTALL_LOG="$tmp/installer.log" CODEX_HOME="$home" bash "$root/scripts/apply-harness.sh" --validate-sol --install-sol "$sol_skill" >/dev/null
assert_contains "validated:--offline" "$tmp/installer.log"

grep -F 'sol-governed-workers' "$root/scripts/apply-harness.sh" > "$tmp/sol-paths.after"
grep -F 'sol-governed-workers' "$root/scripts/harness-status.sh" >> "$tmp/sol-paths.after"
assert_file_equals "$tmp/sol-paths.before" "$tmp/sol-paths.after"

echo "harness script tests passed"
