# Setup conversation reference

Load this reference when Jax has finished the opening orientation. Explain the next topic in plain language, recommend values with a reason, and then ask for one meaningful decision. Keep the tone human and conversational; there is no required report layout.

## Core journey and consent

The package gate and internal profile bootstrap happen before the first visible reply. They verify the packaged optional profiles and run the profile bootstrap. If it reports conflicts, preserve the user's files and explain the conflict. The portable manifest packages the skills-based core. Codex-specific profile provisioning is a separate integration layer, so never present those profiles as a portable Agent Plugins field.

Jax is installed/activated first through the package-supported client operation; select `custom:jax` and the packaged display size through the same supported profile capability when available. Then guide the user through this sequence:

1. Global guidance: inspect the user's `AGENTS.md` and merge only shared guidance every root/worker may inherit into the document's existing structure. Keep root-only orchestration in its skill. Preserve sound intent, explain conflicts, and edit the existing document semantically. Do not append marker blocks, duplicate sections, or ask the user to run a mechanical patcher.
2. Workflow core: discuss relevant review, memory, request-for-input, multi-agent, and workspace-access settings, then apply one coherent local batch after consent while preserving unrelated keys.
3. Environment fit: inspect the actual platform and client before suggesting WSL, terminal shell/location, appearance, cursor, context display, or remote wakefulness. These are preferences, not Iron Box defaults.
4. Recommended integrations: inspect whether Superpowers, Context7, find-skills, Design Doc Mermaid, and Ponytail fit the user's work and are already available. Explain what each relevant integration does, how it is used, when it helps, and what it adds beyond Codex. Ask for consent before installing or activating it.
5. Live test: run the smallest useful multi-agent check and distinguish static asset presence from a live client probe. Confirm that the running Codex installation exposes the expected Luna agent configuration when the host supports model-selectable subagents, and probe GPT-6 Sol as the root when the host supports it. If a capability is unavailable or unverified, report that state plainly, diagnose whether the installation is outdated when likely, and do not silently alter model selection.

A single consent may cover a bounded group of safe, reversible local changes and recommended integrations that use the same local installation path. Ask separately only for a material personal preference, network/external authentication, GUI click, privileged action, or destructive change. Explain the relevant downside before asking. Do not install a recommended integration without the user's consent.

Ponytail is an optional upstream Codex plugin for a user who wants the agent to look for the least complex adequate solution after it understands the relevant code. It is not part of Iron Box and must remain separately installed. Its Codex lifecycle hooks require `node` on `PATH`. Before any marketplace action, explain and ask consent for:

```bash
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
```

After installation, have the user review and explicitly trust Ponytail's two lifecycle hooks through Codex's hooks view, then start a new thread. Listing these commands is documentation, not evidence that Ponytail is installed or working. Report installation and hook review only after a live check.

## Choosing settings

Use `templates/codex-desktop.recommended.toml` as the single shared workflow-core reference. It sets GPT-6 Sol with Low reasoning by default and GPT-6 Luna as the default subagent model, while leaving subagent reasoning effort unset. Choose and pass effort explicitly on every dispatch: recommend High for normal Luna work, use xhigh or max for unusually difficult bounded work when justified, and scale Sol effort to the question. Recommend Medium for harder root orchestration. The template intentionally leaves environment-specific choices unset. Merge only supported keys through the client's documented path, preserve unrelated values, and offer a recommendation based on observed capabilities and the user's goals rather than blindly copying every value. A static template does not prove live model availability: report GPT-6 Sol as unavailable versus unverified when the supported probe cannot establish it. The config reference documents the `model_reasoning_effort` key.

Teach before asking: describe what a setting changes and why it helps. Lead toward a recommendation instead of merely enumerating every possible value. Batch safe work the client can perform. If a supported write is unavailable, say exactly what could not be verified and provide the official UI route; never pretend a shell copy changed the Desktop profile.

## Recovery and reporting

For user configuration changes outside the packaged profile bootstrap, preserve unrelated configuration and retain a backup before changing an existing runtime file. Report the result naturally: what changed, what stayed the same, and any uncertainty or unsupported capability. Roll back the bounded user-configuration change if verification fails. Ask for a restart only when the client documents that it is needed, then re-check the relevant live capability.
