# Setup conversation reference

Load this reference when Jax has finished the opening orientation. Explain the
next topic in plain language, recommend values with a reason, and then ask for
one meaningful decision. Keep the tone human and conversational; there is no
required report layout.

## Core journey and consent

The package gate and internal profile bootstrap happen before the first visible
reply. They verify the packaged optional profiles, copy only missing files, and
roll back newly created files if a write fails. Existing matching files are
left alone; a different existing role is a real conflict to explain, not a
reason to overwrite it. The portable manifest packages the skills-based core.
Codex-specific profile provisioning is a separate integration layer, so never
present those profiles as a portable Agent Plugins field.

Jax is installed/activated first through the package-supported client
operation; select `custom:jax` and the packaged display size through the same
supported profile capability when available. Then guide the user through this
sequence:

1. Orientation: choose the root/manager variant before applying settings.
   Economy uses GPT-5.6 Terra with medium reasoning for ordinary governed work;
   Long-horizon uses GPT-6 Astra with low reasoning for long, complex
   orchestration. Luna performs normal bounded work and routine independent
   checks; Sol is a proportional peer for difficult architecture, uncertainty,
   escalation, and high-value review. The packaged profiles are optional
   conveniences, not a mandatory role taxonomy.
2. Global guidance: inspect the user's `AGENTS.md` and merge only shared
   guidance every root/worker may inherit into the document's existing structure. Keep root-only orchestration in its skill; do not paste it into globally inherited `AGENTS.md`. This is semantic editing owned by the agent.
   Do not append a marker block, duplicate a section, or ask the user to run a mechanical patcher.
3. Workflow core: recommend the selected root model and reasoning effort,
   review, memory, request-for-input,
   multi-agent, and workspace-access values that are relevant to this client.
   Apply one coherent local batch after consent, preserving unrelated keys.
4. Environment fit: inspect the actual platform and client before suggesting
   WSL, terminal shell/location, appearance, cursor, context display, or remote
   wakefulness. These are preferences, not Iron Box defaults.
5. Recommended integrations: inspect whether Superpowers, Context7,
   find-skills, or Design Doc Mermaid fit the user's work and whether each is
   already available. For every relevant recommendation, explain what it does,
   how it is used, when it helps, and what it adds beyond Codex. Then ask the
   user explicitly whether they agree to install or activate it. One consent
   may cover safe local changes; GUI login or external authorization remains a
   direct user action.
6. Live test: run the smallest useful multi-agent check and distinguish static
   asset presence from a live client probe. Confirm that the running Codex
   installation exposes the expected Luna agent configuration when the host
   supports model-selectable subagents, and probe the selected root when the
   host supports it. Probe Astra only after Long-horizon is selected. If a
   capability is unavailable or unverified, report that state plainly, diagnose
   whether the installation is outdated when likely, and never silently switch
   roots or mutate internal model-selection state.

A single consent may cover a bounded group of safe, reversible local changes
and recommended integrations that use that same local installation path. Ask
separately only for a material personal preference, network/external
authentication, GUI click, privileged action, or destructive change. Explain
the relevant downside before asking. Never turn a list of files into a series
of approvals, but never install a recommended integration without the user's
consent either.

## Choosing settings

Use `templates/codex-desktop.recommended.toml` as the single shared
workflow-core reference. It keeps the Economy recommendation of GPT-5.6 Terra
with medium reasoning; Long-horizon selects GPT-6 Astra with low reasoning in
the supported client UI. The template intentionally leaves environment-specific
choices unset. Merge only supported keys through the client's documented path,
preserve unrelated values, and offer a recommendation based on observed
capabilities and the user's goals rather than blindly copying every value. A
static template does not prove live model availability: report the selected
root as unavailable versus unverified when the supported probe cannot establish
it, and never silently fall back. The config reference documents the
`model_reasoning_effort` key; the GPT-6 Astra model reference documents its low
effort support.

Teach before asking: describe what a setting changes and why it helps. Lead
toward a recommendation instead of merely enumerating every possible value.
Batch safe work the client can perform. If a supported write is unavailable,
say exactly what could not be verified and provide the official UI route; never
pretend a shell copy changed the Desktop profile.

## Recovery and reporting

Preserve unrelated configuration and retain a backup before changing an
existing runtime file. Report the result naturally: what changed, what stayed
the same, and any uncertainty or unsupported capability. Roll back the bounded
change if verification fails. Ask for a restart only when the client documents
that it is needed, then re-check the relevant live capability.
