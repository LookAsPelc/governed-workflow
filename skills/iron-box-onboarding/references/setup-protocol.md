# Setup conversation reference

Load this when the user is ready to discuss a setup group, not during the first
reply. It keeps the conversation explanatory and incremental.

## One topic, one decision

Explain the next group in plain language, show the recommended values and why
they matter, then ask whether the user wants the recommendation, a
customization, or a skip. Do not list every group in the opening message. A
normal core batch gets one consent before writing; a personal preset, network
access, or external plugin gets its own clear decision. The agent must obtain
consent before writing and report what was applied, declined, unsupported, or
uncertain.

Check the current client/version documentation once for the session and again
only when the client or version changes or a setting is unclear. If a setting
is not documented for a **compatible Codex Desktop**, explain that and offer
the supported UI or skip it. Never claim that a generic file operation is
transactional, and never use a shell workaround.

## Core order and boundaries

Core comes first: the packaged `luna-worker.toml`, `terra-worker.toml`, and
`sol-advisor.toml` are copied to the effective Codex agents directory by the
client's native file capability. Preserve existing user role files and stop on
a conflict. The managed global `AGENTS.md` block is a separate explained
choice. Static files prove presence only; a later supported live probe proves
exposure.

For a compatible Codex Desktop client, offer the named **Iron Box Codex Desktop
recommended preset** at `templates/codex-desktop.recommended.toml`. It is a
recommendation, never an implicit default or a portable claim for another
harness. Read the profile and discuss these five groups in separate turns, in
this order:

1. orchestration: MultiAgent controls, Luna High worker default, limits, and
   the catalog compatibility bridge below;
2. root defaults: Terra root model and Auto Review;
3. interaction: memories, request-for-input, fast mode, and JS repl;
4. access: workspace network access;
5. Desktop workflow: steering, WSL terminal, remote wakefulness, context
   display, cursor preferences, themes, and the supported reasoning picker.

The already-enabled onboarding companion is never a separate public choice.

For each accepted group, show the exact values and target and ask for consent
before writing. Apply only through a documented client-permitted capability;
otherwise give guided official steps. Do not silently overwrite an existing
value, use a shell workaround to drive the host, or claim an unsupported key
applied. Jax must already be installed and visible before its selection can be
considered applied. Report applied, declined, unsupported, and uncertain keys
separately.

## Luna catalog compatibility bridge

Luna's preferred route is still a new thread. This bridge only makes Luna
selectable as a spawned subagent when the current Codex Desktop catalog declares
`gpt-5.6-luna` as MultiAgent V1. Treat it as a required compatibility outcome
of the orchestration topic, not as a reason to change the whole workflow.

Before offering it, verify the running client/version, its current documented
catalog capability, the effective `models_cache.json`, and the current Luna
entry. If Luna is already declared V2, report that and do nothing. If it is V1,
explain the global effect and ask for consent for this required compatibility
write:

1. Copy the current catalog to an absolute, dedicated path such as
   `$CODEX_HOME/model-catalogs/desktop-multi-agent.json`.
2. In that copy change only `gpt-5.6-luna.multi_agent_version` from `v1` to
   `v2`; preserve every other catalog entry and field.
3. Set `model_catalog_json` in the effective `config.toml` to that absolute
   copy, preserving unrelated configuration.
4. Request a full Codex Desktop restart, then perform a supported live probe
   that confirms Luna is selectable as a subagent. Report exactly what the
   probe proves.

This override replaces the bundled catalog; it is not an overlay. Warn the user
that it may become stale after a Codex update. After each update, first test
without the override; if native V2 support is present, remove the override and
dedicated copy. Otherwise rebuild the copy from the fresh cache and change only
the Luna version flag again. Never use a legacy installer path for this bridge,
and never claim success before the restart and live probe. If the user declines
the bridge, record orchestration as incomplete and do not report onboarding as
complete; offer to resume this specific step later.

## Suggested extras

Offer Superpowers, Context7, find-skills, and design-doc-mermaid one at a time.
Strongly recommend Superpowers and Context7, explain the benefit, and use the
supported installation or UI path for the current client. Ask separately about
network/auth where relevant and keep provider keys out of project/client
configuration. An extra is never a prerequisite for completing Iron Box core.

## Recovery and reporting

Reject symlinks, reparse points, unsafe parents, malformed config, and
conflicting managed blocks. Report unchanged, updated, rolled-back, skipped,
and uncertain targets separately. Restart or refresh only when documented and
at the smallest useful boundary; then report what the live probe actually
demonstrates.
