---
name: iron-box-orchestration
description: Use for Codex-first, evidence-driven delegation with a safe Copilot adapter and explicit user review gates.
---

# Iron-box orchestration

This is a Codex-first workflow for bounded parallel work. It is a workflow
contract, not a claim that every client has the same tools or role model.

## Root ownership and development gate

The root agent owns the requirement, scope, integration, verification, and
all user communication. Before development it records a goal and a TODO list;
the TODO names acceptance criteria and the evidence needed to close them. The
root does not delegate an unresolved product decision or hand off final
integration.

Start by reading the current client's documentation and discovering its
available capabilities (including thread/background delegation, health probes,
and result collection). Record what was actually discovered. Do not infer a
capability from a role name, an old config file, or a prompt example.

## Probe before fan-out

Before launching parallel work, run one small, real health probe through the
preferred delegation path. The probe must do useful, bounded work (for
example, inspect one named file and return a checksum or a finding), and the
root must verify the returned result and scope. A timeout, missing result,
wrong file, or unsupported capability is a failed probe; stop fan-out and
report the onboarding/status repair route.

Prefer the client's native “delegate new thread” or background-thread
mechanism for worthwhile independent work. Use native subagents only as a
fallback when the client explicitly documents that Luna is V2-compatible and
the capability discovery and health probe succeeded. If Luna V2 compatibility
is not established, do not pretend native spawning works: route the user to
onboarding/status repair or continue serially with root-owned work.

The spawn narration is part of the evidence. For every worker, state the task
name, model, reasoning level, and a short purpose before spawning it. Reasoning
calibration is deliberate: Luna low for mechanical/research work, medium for
ordinary implementation, and high for integration; max is reserved for
difficult debugging. Sol is normally medium, not high by default. Never
interrupt a running agent merely to change its reasoning level.

## Worker contract

Each worker receives all of the following in its task message:

- a distinct, bounded scope and exact file ownership;
- acceptance criteria and the expected verification command or observation;
- an explicit statement that other agents are editing the shared workspace;
- escalation conditions for ambiguity, capability failure, destructive action,
  or an acceptance criterion it cannot prove; and
- a prohibition on spawning descendants.

Workers preserve unrelated edits and do not widen scope. They report changed
files, exact commands and results, and remaining uncertainty. The root reviews
the report and the diff before integrating it.

## Sol review and evidence

Sol is optional and read-only. Request a Sol review for architecture, public
interfaces, authentication/security, persistent state, destructive operations,
or a final evidence gate. Sol advises and does not implement. A review is not
evidence of a passing test: distinguish static inspection, collected output,
and a live runtime probe. If a required external dependency (network,
credentials, database, or authorization) is unavailable, record the exact
limitation rather than claiming completion.

After workers return, the root integrates the smallest change, runs the
acceptance checks, and preserves the worker evidence. Before delivery, show
the user the result and unresolved uncertainty for review. Only after that
review does the root perform final cleanup or claim the task complete.

## Copilot adapter boundary

The accompanying `iron-box-reviewer.agent.md` is a Copilot custom-agent
adapter. It carries the same safety and review contract but cannot install
Codex TOML roles, claim Sol/Luna/Terra runtime profiles, or claim V2
compatibility. The actual root is invoked through this orchestration skill; it
is not exposed as a Copilot custom agent. In Copilot, delegation is guidance
unless the current client documents a matching feature; otherwise use a single
bounded conversation and say so. Keep the review adapter frontmatter intact
when copying it into a supported Copilot agents directory.
