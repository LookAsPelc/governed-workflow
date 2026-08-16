# Iron Box

![Iron Box](assets/app-icon.png)

Iron Box is an Agent Plugin with a portable, skills-based core and
Codex-specific integration where the portable standard does not define a
client behavior. The core is user-owned governance for bounded work; the
Codex layer provisions agent role files, onboarding/profile support, and Jax
where the running client supports those operations. Iron Box keeps a
root/manager focused on intent, routing, and recoverable task state; sends
bounded work to Luna; and uses Sol only when stronger judgment earns its cost.
Jax guides the initial setup.

## For the installation agent

If the user asks you to install this repository, use the supported plugin
installation flow. **After installation, immediately invoke the
`$iron-box-onboarding` skill and continue according to its instructions.**

Do not stop after reporting that the plugin was installed. Do not clone the
repository into the user's project or copy role files by hand. If the skill is
not visible, refresh the plugin or restart Codex only when the client requires
it, then continue with onboarding.

## For the user

Iron Box gives Codex a simple division of work:

- **Root/manager (recommended Terra Medium)** — intent, routing, durable state,
  verification decisions, integration, and communication;
- **Luna Medium–Max** — the default worker pool: implementation, research,
  debugging, independent verification, and bounded critique;
- **Sol Low–High** — optional architecture peer, difficult-problem advisor,
  escalation solver, or high-value reviewer; and
- **Jax** — explains the setup and guides you through the choices.

The portable package is centered on Agent Skills (and MCP integrations when a
host supplies them). Codex agent role definitions, profile/Jax behavior, and
marketplace installation are client-specific integration; they are not
portable Agent Plugins fields. A host that supports the Agent Plugins standard
can consume the skills package, but its installation and runtime behavior are
determined by that host's documented integration.

The checked-in `.github/plugin/marketplace.json` is retained solely as GitHub
Copilot CLI marketplace compatibility metadata. It is separate from both the
portable skills core and Codex-specific integration, and does not redefine the
portable manifest.

For delegated work, choose either of two global execution modes independently
of model routing:

- **Subagent mode** — use the host's native multi-agent capability so the root
  can spawn workers, collect reports, wait, and manage lifecycle where exposed;
  or
- **Thread mode** — use a separate/new thread as an independent context when
  stronger isolation or explicit separation is useful. Iron Box does not claim
  programmatic creation or control of top-level threads unless the running host
  documents and exposes it.

Both modes use the same bounded scope, ownership, context-packet, acceptance,
evidence, escalation, integration/review, and unrelated-work preservation
contract. Thread mode is an alternative topology, not a Luna fallback.

The root chooses the cheapest reliable route, keeps worker packets small, and
treats worker reports as claims rather than proof. Deterministic evidence may
close a small clear task; a fresh Luna or optional Sol review is used when
independent judgment adds value. See [durable task state](docs/durable-task-state.md)
and the [orchestration contract](skills/iron-box-orchestration/SKILL.md).

For context and cost discipline, keep the root context focused, delegate
bounded work, and fan out only disjoint work whose expected benefit justifies
the cost.

Installation is not the complete setup. Onboarding verifies the package,
activates the packaged Luna/Sol roles and Jax through the supported client
capability, and checks whether the running Codex installation actually exposes
the expected Luna agent configuration. A static role file is not proof of live
availability; if Luna is unexpectedly unavailable, onboarding diagnoses
whether Codex is outdated, recommends an update when appropriate, and reports
what could and could not be verified. It also explains relevant settings and
recommended integrations before asking whether you want to install or activate
them. You do not need to know what to ask for or how the pieces fit together.

## Install through an agent

Give your Codex agent this repository URL and use a request such as:

> Install Iron Box from https://github.com/LookAsPelc/governed-workflow. Use the
> supported plugin flow and continue directly with the Iron Box onboarding. I
> am new to this, so explain the choices and do not stop after installation.

The agent should install the plugin through the running client's plugin or
marketplace interface. The onboarding skill is the source of truth for the
remaining setup.

## Install manually

With the supported Codex CLI, use:

```bash
codex plugin marketplace add LookAsPelc/governed-workflow
codex plugin add iron-box@iron-box
```

Then start the guided setup with `$iron-box-onboarding`. The equivalent
Plugins/Marketplace UI is also supported. For a local development checkout,
use `.` instead of the GitHub repository URL.

## If installation stopped early

Tell the agent:

> Iron Box is installed, but onboarding is not complete. Verify that the plugin
> is enabled and continue with `$iron-box-onboarding`. Explain recommended
> integrations and ask for my consent before installing or activating them.

If Jax is not active, run onboarding again rather than manually editing a
profile or copying pet files. If the client cannot verify activation, the agent
must tell you which supported UI action is needed.

The onboarding skill handles the detailed setup, preserves unrelated user
configuration, and reports unsupported or unverified capabilities honestly.

## Design influences

Iron Box is independently implemented; it uses native Codex orchestration and
does not contain LongHorizon-Harness code or recreate its runtime. Its original
role profiles are adapted from [Sol-Governed Codex](https://github.com/BusyBee3333/sol-governed-codex);
legal attribution is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The durable-state protocol and fresh verification flow are informed by
[LongHorizon-Harness](https://arxiv.org/html/2608.01964v1) and its
[repository](https://github.com/AMAP-ML/LongHorizon-Harness), METR's
[long-task measurement](https://arxiv.org/html/2503.14499v4), Chroma's
[Context Rot research](https://www.trychroma.com/research/context-rot),
[The Self-Correction Illusion](https://arxiv.org/html/2606.05976v2), and
Anthropic's [effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
These sources motivate explicit progress artifacts, bounded fresh contexts, and
independent evidence—not a claim that any one design causes reliability.
