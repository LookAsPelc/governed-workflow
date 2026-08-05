# Setup protocol reference

Use this reference for the preflight and all setup choices.

## Evidence and consent

Record client/version/platform and official capability evidence for the current
session. Before each write, show exact target paths, ownership, current state,
managed-block conflicts, proposed backup locations, complete staged changes,
and rollback behavior. Obtain separate natural-language consent per target.
Use the client's deterministic runtime installer only when that client exposes
it; offer `dry-run`, `apply`, and `status` as supported modes. If execution or
prerequisites are unavailable, give exact current official-doc steps and report
that no write was performed. Do not claim transactionality without observed
native staging/atomic replacement/rollback.

## Core order and boundaries

Core comes first: packaged standalone Codex role files discovered in
`$CODEX_HOME/agents/` and the managed global `AGENTS.md`. Existing user
registrations are optional and remain untouched. Preserve every existing user
line and exact role settings/comments. Static files prove presence only; a
later supported live probe proves exposure.

For a compatible Codex Desktop client, then offer the named **Iron Box Codex
Desktop recommended preset** at `templates/codex-desktop.recommended.toml`.
It is a recommendation, never an implicit default and never a portable claim
for another harness. Read the profile and discuss these separate choices:

- core defaults: Terra root model, Auto Review, memories, input mode, and
  fast/JS-repl choices;
- orchestration: MultiAgent controls, Luna High worker default, and limits;
- access: workspace network access;
- Desktop workflow: steering, WSL terminal, remote wakefulness, display, and
  cursor preferences;
- appearance and Jax: themes, supported reasoning picker, and Jax selection.

For each accepted group, verify the current client/version documents every
key, show the exact values and target, and ask for consent before writing.
Apply only through a documented client-permitted capability; otherwise give
guided official steps. Do not silently overwrite an existing value, use a
shell workaround to drive the host, or claim an unsupported key applied.
Offer the Jax selection only after the pet itself is installed and visible to
that client. Report applied, declined, unsupported, and uncertain keys
separately.

Optional order is Superpowers, Context7, find-skills, design-doc-mermaid.
Recommend GUI installation of Superpowers/Context7; prefer Code's documented
command line for find-skills, which may then install design-doc-mermaid. Ask
separately, explain permissions/network/auth, and keep provider keys out of
project/client config. Copilot receives only documented Copilot equivalents.

## Recovery and reporting

Reject symlinks, reparse points, unsafe parents, malformed config, and
conflicting managed blocks. Report unchanged, updated, rolled-back, skipped,
and uncertain targets separately. Restart/refresh only when documented and
only after package/setup completion; then report what the live probe actually
demonstrates.
