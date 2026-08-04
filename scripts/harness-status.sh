#!/usr/bin/env bash
set -euo pipefail

# This command intentionally performs only local existence and PATH checks. In
# particular, it never starts a client, asks for credentials, or contacts a
# service while reporting status.
if [[ -n "${CODEX_HOME:-}" ]]; then
  codex_home="$CODEX_HOME"
elif [[ -n "${HOME:-}" ]]; then
  codex_home="$HOME/.codex"
else
  codex_home=""
fi

report_command() {
  local label="$1"
  shift
  local candidate command_path
  for candidate in "$@"; do
    command_path="$(command -v "$candidate" 2>/dev/null || true)"
    if [[ -n "$command_path" ]]; then
      printf '%s: present (%s)\n' "$label" "$command_path"
      return
    fi
  done
  printf '%s: absent\n' "$label"
}

report_command "codex" codex
# Checking PATH is safe, whereas invoking `gh copilot` could load a plugin or
# make a network call.
report_command "copilot" copilot github-copilot-cli

if [[ -z "$codex_home" ]]; then
  printf 'sol-governed: unknown (HOME and CODEX_HOME are unset)\n'
  printf 'global-agents: unknown (HOME and CODEX_HOME are unset)\n'
  exit 0
fi

sol_paths=(
  "$codex_home/skills/sol-governed-workers/SKILL.md"
  "$codex_home/agents/sol-advisor.toml"
  "$codex_home/agents/terra-worker.toml"
  "$codex_home/agents/luna-worker.toml"
  "$codex_home/sol-governed.config.toml"
  "$codex_home/sol-governed-high.config.toml"
)
sol_present=0
for path in "${sol_paths[@]}"; do
  [[ -f "$path" ]] && sol_present=$((sol_present + 1))
done
if [[ $sol_present -eq ${#sol_paths[@]} ]]; then
  printf 'sol-governed: installed (%s)\n' "$codex_home"
elif [[ $sol_present -gt 0 ]]; then
  printf 'sol-governed: partial (%d/%d expected files under %s)\n' \
    "$sol_present" "${#sol_paths[@]}" "$codex_home"
else
  printf 'sol-governed: absent\n'
fi

agents_path="$codex_home/AGENTS.md"
if [[ -f "$agents_path" ]]; then
  printf 'global-agents: present (%s)\n' "$agents_path"
elif [[ -e "$agents_path" ]]; then
  printf 'global-agents: exists but is not a regular file (%s)\n' "$agents_path"
else
  printf 'global-agents: absent (%s)\n' "$agents_path"
fi
