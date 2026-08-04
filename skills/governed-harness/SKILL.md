---
name: governed-harness
description: Use when a user wants to inspect, install, or tailor a personal Codex or Copilot CLI harness centered on Sol-Governed Codex.
---

# Governed harness

This skill guides an explicit conversation, not a silent machine-wide installer. The user owns their configuration and gets to approve each write.

## First response

1. State which harnesses are detected: Codex, Copilot CLI, both, or neither.
2. Run `scripts/harness-status.sh` in read-only mode and summarize only the detected local state.
3. Explain the recommended baseline: Sol-Governed Codex for Codex roles and quality gates, plus the managed global `AGENTS.md` block in `templates/AGENTS.global.recommended.md`.
4. Explain the exact choices and their impact, show the dry-run, and ask which (if any) choice the user approves. Never infer consent from a request to inspect.

## Available choices

- **Sol-Governed Codex:** review an explicit upstream skill directory, then use `--apply --install-sol PATH` to run its installer. Governed Workflow itself does not silently write settings. With this explicit approval, the script delegates to the reviewed upstream installer, which may add Codex skills and role/profile TOML files under `CODEX_HOME`; explain that impact before consent. This workflow does not configure Copilot TOML roles or ask for credentials.
- **Recommended global AGENTS.md:** use `--write-global-agents` for the dry-run, then `--apply --write-global-agents` after approval. It creates or updates only the `governed-workflow` marker block, preserving all other user instructions.
- **Superpowers:** offer its upstream install; do not vendor or silently update it here.
- **find-skills:** offer the upstream Vercel skill as an optional discovery helper.
- **design-doc-mermaid:** offer it only when a diagram makes architecture, flow, or interface behavior materially clearer. Validate generated Mermaid before committing it.
- **Context7:** offer the curated Codex App when it is available in the user's catalog; otherwise offer OAuth MCP, local MCP, or skip. Explain that documentation requests can leave the local machine and never write an API key into this repository or a config file.

## Apply only after explicit confirmation

`scripts/apply-harness.sh` is a dry-run unless `--apply` is present. Its supported choices are `--write-global-agents`, `--install-sol PATH`, and `--validate-sol`; it never accepts a Copilot role/profile option. After the user accepts an exact choice, call it with `--apply` and only the corresponding flag(s), read its output, then run `scripts/harness-status.sh` again. `--validate-sol` runs the reviewed validator with mandatory `--offline`; it does not perform a live probe. Do not use `--force` for the upstream Sol installer. Governed Workflow does not silently write API keys, passwords, model configuration, or integrations; an explicitly approved upstream installer may write its own Codex files as described above.

## Role routing

- Root/orchestrator: requirements, integration, verification, and user communication.
- Luna: isolated mechanical work with settled decisions.
- Terra: bounded implementation requiring local judgment.
- Sol: architecture review, public interfaces, security, persistent state, and final evidence gates.

The same concepts apply in Copilot CLI, but Sol role profiles are a Codex capability; do not claim that Copilot has installed Codex TOML profiles.
