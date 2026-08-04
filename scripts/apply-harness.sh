#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: apply-harness.sh [--apply] [--write-global-agents]
                        [--install-sol PATH] [--validate-sol]

Without --apply this command is a dry-run. Global AGENTS.md is changed only
when both --apply and --write-global-agents are supplied.
EOF
}

apply=0
write_global_agents=0
install_sol_path=""
validate_sol=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1 ;;
    --write-global-agents) write_global_agents=1 ;;
    --install-sol)
      shift
      if [[ $# -eq 0 || "$1" == -* ]]; then
        echo "--install-sol requires a reviewed upstream Sol skill path" >&2
        exit 64
      fi
      install_sol_path="$1"
      ;;
    --validate-sol) validate_sol=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 64 ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
template="$repo_root/templates/AGENTS.global.recommended.md"
if [[ -n "${CODEX_HOME:-}" ]]; then
  codex_home="$CODEX_HOME"
elif [[ -n "${HOME:-}" ]]; then
  codex_home="$HOME/.codex"
else
  codex_home=""
fi
if [[ -z "$codex_home" ]]; then
  echo "HOME or CODEX_HOME must be set" >&2
  exit 64
fi
agents_path="$codex_home/AGENTS.md"

# Resolve an explicit skill path without guessing at other installers. The
# caller owns review of this upstream source; this script passes no --force.
sol_skill_dir=""
sol_installer=""
sol_validator=""
if [[ -n "$install_sol_path" ]]; then
  if [[ -d "$install_sol_path" ]]; then
    sol_skill_dir="$(cd "$install_sol_path" && pwd -P)"
  elif [[ -f "$install_sol_path" && "$(basename "$install_sol_path")" == "install_global_infra.sh" ]]; then
    sol_skill_dir="$(cd "$(dirname "$install_sol_path")/.." && pwd -P)"
  else
    echo "reviewed Sol skill path must be a skill directory or install_global_infra.sh" >&2
    exit 66
  fi
  sol_installer="$sol_skill_dir/scripts/install_global_infra.sh"
  sol_validator="$sol_skill_dir/scripts/validate_setup.sh"
  [[ -f "$sol_installer" ]] || { echo "missing Sol installer: $sol_installer" >&2; exit 66; }
  if [[ $validate_sol -eq 1 && ! -f "$sol_validator" ]]; then
    echo "missing Sol validator: $sol_validator" >&2
    exit 66
  fi
fi

if [[ ! -f "$template" ]]; then
  echo "missing managed AGENTS template: $template" >&2
  exit 66
fi

if [[ $write_global_agents -eq 1 ]]; then
  if [[ $apply -eq 1 ]]; then
    echo "global AGENTS.md: apply"
  else
    echo "global AGENTS.md: dry-run"
    echo "  would update only the governed-workflow marker block: $agents_path"
  fi
else
  echo "global AGENTS.md: unchanged (pass --write-global-agents to opt in)"
fi

# Python is used only from its standard library for exact text slicing and an
# atomic replace. This preserves every byte outside the managed marker pair.
check_or_write_agents() {
  local mode="$1"
  if [[ "$mode" == write ]]; then
    if [[ -L "$agents_path" ]]; then
      echo "refusing to write symlink: $agents_path" >&2
      return 2
    fi
    if [[ -e "$agents_path" && ! -f "$agents_path" ]]; then
      echo "refusing non-regular AGENTS.md: $agents_path" >&2
      return 2
    fi
  fi
  python3 - "$agents_path" "$template" "$mode" <<'PY'
import os
import pathlib
import stat
import sys
import tempfile

target = pathlib.Path(sys.argv[1])
template = pathlib.Path(sys.argv[2])
mode = sys.argv[3]
canonical = "governed-workflow"
legacy = "governed-workers"

def validate_markers(text: str, label: str, name: str, start: str, end: str):
    """Return whole logical-line bounds; reject inline or ambiguous markers."""
    starts = []
    ends = []
    offset = 0
    for line in text.splitlines(keepends=True):
        logical = line.rstrip("\r\n")
        if start in logical:
            if logical.strip() != start:
                raise SystemExit(f"malformed inline {name} marker in {label}")
            starts.append((offset, offset + len(line)))
        if end in logical:
            if logical.strip() != end:
                raise SystemExit(f"malformed inline {name} marker in {label}")
            ends.append((offset, offset + len(line)))
        offset += len(line)
    if not starts and not ends:
        return (-1, -1)
    if len(starts) != 1 or len(ends) != 1:
        raise SystemExit(f"malformed {name} markers in {label}")
    if starts[0][0] > ends[0][0]:
        raise SystemExit(f"malformed {name} marker order in {label}")
    return starts[0][0], ends[0][1]

def marker_pairs(text: str, label: str):
    """Find exactly one marker dialect, rejecting malformed or mixed blocks."""
    definitions = (
        (canonical, "<!-- governed-workflow:start -->", "<!-- governed-workflow:end -->"),
        (legacy, "<!-- governed-workers:start -->", "<!-- governed-workers:end -->"),
    )
    pairs = []
    errors = []
    for name, start, end in definitions:
        try:
            bounds = validate_markers(text, label, name, start, end)
        except SystemExit as error:
            errors.append(str(error))
            continue
        if bounds[0] >= 0:
            pairs.append((name, bounds))
    if errors:
        raise SystemExit(errors[0])
    if len(pairs) > 1:
        raise SystemExit(
            f"ambiguous {canonical}/{legacy} markers in {label}; use one managed block"
        )
    return pairs[0] if pairs else (None, (-1, -1))

with template.open("r", encoding="utf-8", newline="") as handle:
    template_text = handle.read()
template_name, (template_start, template_end) = marker_pairs(template_text, str(template))
if template_name != canonical:
    raise SystemExit(f"managed template has no {canonical} marker pair: {template}")
if template_text[:template_start].strip() or template_text[template_end:].strip():
    raise SystemExit(f"managed template contains content outside its marker block: {template}")
block_with_eol = template_text[template_start:template_end]

if target.exists():
    if target.is_symlink() or not target.is_file():
        raise SystemExit(f"refusing non-regular AGENTS.md: {target}")
    with target.open("r", encoding="utf-8", newline="") as handle:
        original = handle.read()
else:
    original = ""

_target_name, (target_start, target_end) = marker_pairs(original, str(target))
if target_start < 0:
    if original and not original.endswith(("\n", "\r")):
        updated = original + "\n" + block_with_eol
    else:
        updated = original + block_with_eol
else:
    # Keep the target's bytes after the end marker (including its line ending)
    # so unrelated user formatting remains untouched.
    target_lines = original[target_start:target_end].splitlines(keepends=True)
    target_eol = ""
    if target_lines:
        last = target_lines[-1]
        if last.endswith("\r\n"):
            target_eol = "\r\n"
        elif last.endswith("\n"):
            target_eol = "\n"
    replacement_block = block_with_eol
    if target_eol == "\r\n":
        replacement_block = replacement_block.replace("\r\n", "\n").replace("\n", "\r\n")
    elif target_eol == "\n":
        replacement_block = replacement_block.replace("\r\n", "\n")
    elif replacement_block.endswith(("\r\n", "\n")):
        # A marker without a line ending can only be at EOF (otherwise it
        # would be an inline marker); retain that no-final-newline byte shape.
        replacement_block = replacement_block.rstrip("\r\n")
    updated = original[:target_start] + replacement_block + original[target_end:]

if updated == original:
    print(f"unchanged: {target}")
    raise SystemExit(0)
if mode == "check":
    print(f"would update: {target}")
    raise SystemExit(0)
if mode != "write":
    raise SystemExit(f"unknown write mode: {mode}")

# The parent is created only after all marker and content checks pass; this
# keeps malformed-marker rejection fully read-only.
target.parent.mkdir(parents=True, exist_ok=True)
old_mode = stat.S_IMODE(target.stat().st_mode) if target.exists() else 0o644
fd, temporary = tempfile.mkstemp(prefix=".governed-workflow-agents.", dir=str(target.parent))
try:
    with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
        handle.write(updated)
    os.chmod(temporary, old_mode)
    os.replace(temporary, target)
except BaseException:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
    raise
print(f"updated: {target}")
PY
}

if [[ $write_global_agents -eq 1 ]]; then
  if [[ $apply -eq 1 ]]; then
    check_or_write_agents write
  else
    check_or_write_agents check
  fi
fi

if [[ -n "$sol_installer" ]]; then
  if [[ $apply -eq 1 ]]; then
    # Deliberately no arguments: in particular, never escalate to --force.
    echo "running reviewed Sol installer: $sol_installer"
    bash "$sol_installer"
  else
    echo "would run reviewed Sol installer with --apply: $sol_installer"
  fi
fi

if [[ $validate_sol -eq 1 ]]; then
  if [[ -z "$sol_validator" ]]; then
    sol_validator="$codex_home/skills/sol-governed-workers/scripts/validate_setup.sh"
  fi
  if [[ ! -f "$sol_validator" ]]; then
    echo "cannot validate Sol installation; validator not found: $sol_validator" >&2
    exit 66
  fi
  # --offline is mandatory here: validation must not make model or network calls.
  echo "running offline Sol validation: $sol_validator"
  bash "$sol_validator" --offline
fi

if [[ $apply -eq 0 ]]; then
  echo "dry-run complete; no changes were made"
else
  echo "apply complete"
fi
