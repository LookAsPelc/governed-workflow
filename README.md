# Governed Workflow

Governed Workflow is a small, user-owned workflow layer for Sol-Governed Codex
and GitHub Copilot CLI. It keeps the shared skills flat and portable while
making configuration changes conversational, reviewable, and opt-in.

This is a pre-release identity correction: the public repository and plugin
identifier is `governed-workflow`. If a GitHub remote is created in the future,
it must use `governed-workflow`; this repository does not claim that a remote
already exists.

## Install for the client you use

For Codex, install this repository using the Codex plugin flow. The
`.codex-plugin/plugin.json` exposes the shared Codex skills under `skills/`;
the `agents/*.agent.md` files are GitHub Copilot custom-agent definitions and
are not loaded by that Codex manifest as role profiles. If you are installing skills manually, copy each
`skills/<name>/` directory to `$CODEX_HOME/skills/<name>/` (normally
`~/.codex/skills/<name>/`); the shared skill source remains
`skills/<name>/SKILL.md`. To inspect the local harness, run:

```bash
bash scripts/harness-status.sh
```

To propose the managed global instructions, run a dry-run first:

```bash
bash scripts/apply-harness.sh --write-global-agents
```

Only after reviewing that output should a user choose
`--apply --write-global-agents`. A reviewed Sol installer can be run only with
an explicit `--apply --install-sol PATH`; after that confirmation it delegates
to the reviewed upstream installer, which may write its Sol skill and
role/profile TOML files under `CODEX_HOME`. Offline validation is opt-in with
`--validate-sol`.

For Copilot CLI, copy or link the individual `skills/<name>/` directories into
the repository `.github/skills/` directory or `~/.copilot/skills/<name>/`.
Copy the two `agents/*.agent.md` files into `.github/agents/` or
`~/.copilot/agents/` when you want those Copilot agents. Keep the `.agent.md`
frontmatter intact. Copilot does not load
Codex plugin manifests, Sol role profiles, or Codex TOML configuration; the
Sol/Luna/Terra routing is guidance for the conversation, not a Copilot role
installation.

## Optional upstream components

Nothing in this public repository installs or updates upstream dependencies
automatically. When useful, review and opt into the upstream projects instead:

- [Superpowers](https://github.com/obra/superpowers) for optional development
  workflows. Use it selectively; TDD is especially useful for bug fixes, not a
  mandatory ritual for every feature.
- [Vercel skills and `find-skills`](https://github.com/vercel-labs/skills) for
  optional discovery when local skills do not cover a real need.
- `design-doc-mermaid` only when a Mermaid diagram materially clarifies a
  decision; validate the Mermaid before committing it.
- Context7 through a currently available curated Codex App when possible. If
  that App is unavailable, offer remote OAuth MCP, local MCP, or skip; offer
  the same three alternatives for Copilot. Never put an API key in this
  repository or a client config file.

The `--install-sol PATH` option invokes a reviewed upstream Sol-Governed Codex
installer; it does not vendor that project here. Review what that installer
will change before approving it.

## Verification

All checks below are offline and do not contact a provider:

```bash
bash scripts/validate.sh
bash tests/test-harness-scripts.sh
```

The first command validates JSON and skill/agent frontmatter. The second
exercises dry-run, explicit apply, marker preservation, and installer safety.

## Privacy

This project has no telemetry and does not send project content to its
maintainers. Optional documentation providers may receive queries and context
selected by the active client; review that boundary and choose skip when it is
not acceptable. See [docs/privacy.md](docs/privacy.md) for the concise privacy
and destructive-operation contract.

Upstream dependencies are never installed or updated silently. Preserve
unrelated user instructions and confirm exact targets before destructive work.
