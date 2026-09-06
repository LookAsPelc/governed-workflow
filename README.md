# Iron Box

![Iron Box](assets/app-icon.png)

Iron Box is an Agent Plugin with a portable skills core and optional Codex
integration. It keeps a root/manager focused on intent, routing, verification,
and integration; Luna handles bounded execution; and Sol is a proportional
escalation peer. Development workflow artifacts remain the responsibility of
native tools such as Superpowers.

## Root variants

Both variants use the same orchestration contract, Luna execution and fresh
verification, and optional Sol escalation:

- **Economy:** GPT-5.6 Terra with medium reasoning for ordinary governed work.
  The shared recommendation is
  [`templates/codex-desktop.recommended.toml`](templates/codex-desktop.recommended.toml).
- **Long-horizon:** GPT-6 Astra with low reasoning for long, complex orchestration.

The shared desktop template contains the workflow settings and Economy defaults;
it does not encode the root variant. The
[Codex config reference](https://learn.chatgpt.com/docs/config-file/config-reference)
documents `model_reasoning_effort`; the [GPT-6 Astra model reference](https://developers.openai.com/api/docs/models/gpt-6-astra)
documents the model and its low effort support. A static file does not prove
that a model is available in the current client or account; onboarding probes
the selected root only where the host supports it and reports unavailable versus
unverified without silently switching roots.

## Workflow

Iron Box routes bounded work and verifies evidence; the shared rules for Luna
effort, worker reuse, fresh review, Sol escalation, and recovery are in the
[orchestration contract](skills/iron-box-orchestration/SKILL.md). The
[why Iron Box essay](docs/why-iron-box.md) explains the design rationale.
Superpowers supplies the surrounding development artifacts; Iron Box does not
maintain a parallel task or recovery state.

Worker reports are claims. The root reviews the relevant source, diff,
runtime, or other artifact and keeps static configuration evidence distinct
from live client/model capability. Do not push, publish, deploy, change production, or
make destructive external changes without explicit user authority.

## Installation

If a user asks an agent to install this repository, use the supported plugin
installation flow and invoke `$iron-box-onboarding` immediately afterward. Do
not stop after reporting installation. The onboarding skill verifies package
identity, preserves matching user files, stops on conflicts, explains the two
root variants, and reports which live model capabilities were actually tested.

With the supported Codex CLI, the equivalent flow is:

```text
codex plugin marketplace add LookAsPelc/governed-workflow
codex plugin add iron-box@iron-box
```

Then start `$iron-box-onboarding`. For a local development checkout, use the
checkout path in place of the repository URL. The equivalent Plugins/Marketplace
UI is also supported.

Onboarding also explains relevant integrations and asks before installing or
activating them. It preserves unrelated user configuration and reports any
unsupported or unverified capability honestly.

## Components

- `$iron-box-orchestration` is the shared root routing and verification skill.
- `$iron-box-onboarding` guides setup and live capability checks.
- The packaged Luna/Sol TOML files are optional Codex execution profiles.
- Jax is an optional onboarding companion.

## Design influences

Iron Box is independently implemented. It does not contain LongHorizon-Harness
code or recreate its runtime. Original role profiles are adapted from
[Sol-Governed Codex](https://github.com/BusyBee3333/sol-governed-codex); legal
attribution is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The design is informed by [LongHorizon-Harness](https://arxiv.org/html/2608.01964v1),
[METR long-task measurement](https://arxiv.org/html/2503.14499v4),
[Context Rot research](https://www.trychroma.com/research/context-rot),
[The Self-Correction Illusion](https://arxiv.org/html/2606.05976v2), and
[Anthropic's effective harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
These sources motivate bounded delegation and evidence-based verification; they
are not reliability guarantees.
