# Iron Box

![Iron Box](assets/app-icon.png)

Iron Box is an Agent Plugin with a portable skills core and optional Codex integration. It keeps a root/manager focused on intent, routing, verification, and integration; Luna handles bounded execution; and Sol is a proportional escalation peer. Development workflow artifacts remain the responsibility of native tools such as Superpowers.

## Model routing

GPT-6 Sol at Low reasoning is an intentional default for the thin root/manager: it focuses on intent, routing, and evidence review, and can raise effort to Medium when coordination needs it. Luna handles normal bounded work and routine independent checks with GPT-6 Luna at High reasoning; use xhigh or max when task difficulty justifies it. The custom profiles pin their model identity but leave reasoning effort to the manager when each task is launched. Sol is one optional peer for difficult architecture, risk, or judgment, with effort scaled from Low toward High as needed.

The shared [`templates/codex-desktop.recommended.toml`](templates/codex-desktop.recommended.toml) provides desktop workflow defaults. The [Codex config reference](https://learn.chatgpt.com/docs/config-file/config-reference) documents `model_reasoning_effort`. Static configuration does not establish model availability in a client or account; onboarding checks supported capabilities and reports unavailable versus unverified.

## Workflow

Iron Box routes bounded work and verifies evidence; the [orchestration contract](skills/iron-box-orchestration/SKILL.md) covers Luna effort, worker reuse, fresh review, Sol escalation, and recovery. The [why Iron Box essay](docs/why-iron-box.md) explains the design rationale. Superpowers supplies the surrounding development artifacts; Iron Box does not maintain a parallel task or recovery state.

The root reviews relevant source, diffs, runtime behavior, or other artifacts and distinguishes static configuration from live client/model capability. Pushing, publishing, deployment, production changes, and destructive external changes require explicit user authority.

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
