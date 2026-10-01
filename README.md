# Iron Box

![Iron Box](assets/app-icon.png)

Iron Box is an Agent Plugin with a portable skills core and optional Codex integration. It keeps the root accountable for the goal, decisions, coordination, and integration. Luna handles bounded work; Sol is an optional peer for consequential questions. Development workflow artifacts remain the responsibility of native tools such as Superpowers.

## Model routing

GPT-6.1 Sol at Low is the recommended root default; Medium can help with harder coordination. GPT-6 Luna at High is the default for bounded work; use XHigh for reconciling conflicting constraints or debugging with competing hypotheses, and Max for difficult bounded exploration. The custom profiles pin model identity and leave subagent effort to the manager when each task starts. See the [orchestration contract](skills/iron-box-orchestration/SKILL.md) for worker routing and context decisions.

The shared [`templates/codex-desktop.recommended.toml`](templates/codex-desktop.recommended.toml) provides desktop workflow defaults. The [Codex config reference](https://learn.chatgpt.com/docs/config-file/config-reference) documents `model_reasoning_effort`. Static configuration does not establish model availability in a client or account; onboarding checks supported capabilities and reports unavailable versus unverified.

## Workflow

Iron Box routes bounded work and verifies evidence; the [orchestration contract](skills/iron-box-orchestration/SKILL.md) covers effort selection, worker reuse, context choice, proportional verification, and Sol consultation. The [why Iron Box essay](docs/why-iron-box.md) explains the design rationale. Superpowers supplies the surrounding development artifacts; Iron Box does not maintain a parallel task or recovery state.

The root checks relevant source, diffs, runtime behavior, or other artifacts and distinguishes static configuration from live client/model capability.

## Installation

If a user asks an agent to install this repository, use the supported plugin installation flow and invoke `$iron-box-onboarding` immediately afterward. Continue through onboarding: it verifies package identity, preserves matching user files, stops on conflicts, explains the recommended model routing, and reports which live model capabilities were tested.

With the supported Codex CLI, the equivalent flow is:

```text
codex plugin marketplace add LookAsPelc/governed-workflow
codex plugin add iron-box@iron-box
```

Then start `$iron-box-onboarding`. For a local development checkout, use its path in place of the repository URL. The equivalent Plugins/Marketplace UI is also supported.

Onboarding explains relevant integrations and asks before installing or activating them. It preserves unrelated user configuration and reports unsupported or unverified capabilities.

## Components

- `$iron-box-orchestration` is the shared root routing and verification skill.
- `$iron-box-onboarding` guides setup and live capability checks.
- The packaged Luna/Sol TOML files are optional Codex execution profiles.
- Jax is an optional onboarding companion.

## Design influences

Iron Box is independently implemented. It does not contain LongHorizon-Harness code or recreate its runtime. Original role profiles are adapted from [Sol-Governed Codex](https://github.com/BusyBee3333/sol-governed-codex); legal attribution is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The design is informed by [LongHorizon-Harness](https://arxiv.org/html/2608.01964v1), [METR long-task measurement](https://arxiv.org/html/2503.14499v4), [Context Rot research](https://www.trychroma.com/research/context-rot), [The Self-Correction Illusion](https://arxiv.org/html/2606.05976v2), and [Anthropic's effective harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents). These sources motivate bounded delegation and evidence-based verification; they are not reliability guarantees.
