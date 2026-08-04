# Privacy and safety

Governed Workflow is a public, non-telemetry workflow. It does not collect
usage data, phone home, or send project content to its maintainers.

The status and validation commands are local checks. The harness apply script
changes only the user-approved managed `AGENTS.md` block unless the user also
explicitly supplies `--apply --install-sol PATH`. That option delegates to a
reviewed upstream Sol installer, which may write its Codex skills and
role/profile TOML files under `CODEX_HOME`; show that impact before consent.
Governed Workflow itself does not silently write settings or credentials and
does not configure Copilot TOML roles. Context7 and other optional providers
may receive queries and client-selected context; review the provider policy
and choose skip when that boundary is not acceptable.

No upstream dependency is installed or updated automatically. Review optional
upstream components, their permissions, and their release provenance before
choosing to install them. Confirm exact targets before destructive operations
and preserve unrelated user instructions.
