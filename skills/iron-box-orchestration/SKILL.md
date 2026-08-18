---
name: iron-box-orchestration
description: Small, governed Codex routing for bounded work with optional durable recovery.
---

# Iron Box orchestration

Iron Box is a small contract over native Codex orchestration. The root/manager
owns the user goal, scope, decomposition, integration, and communication.

```text
Manager / orchestration proxy
├── Luna (Medium → Max) — normal bounded work and routine independent checks
└── Sol (Low → High) — difficult reasoning, peer consultation, escalation,
                        architecture, and high-value review
```

Choose the least costly model and reasoning effort that can reliably meet the
task's confidence needs. Roles such as researcher, debugger, implementer, or
verifier are task-scoped framing, not a required taxonomy of persistent
agents.

## Delegate bounded work

Before every delegated worker start, visibly announce exactly:

`role | model | reasoning effort | context being passed`

Give the worker only the bounded objective, relevant current facts and
constraints, the required evidence or acceptance criteria, and the requested
return. Do not forward the whole root conversation or private reasoning.

Workers do not spawn descendants, silently widen scope, change unrelated
files, or reinterpret the user goal. Their report is a claim, not proof.
Keep one bounded packet when it is enough; fan out only genuinely independent
work whose time or judgment benefit justifies the coordination cost.

Use a fresh, read-only Luna verifier when independent judgment adds value. Its
report is `PASS`, `REVISE`, or `BLOCKED`, with findings, evidence, and
uncertainty. `PASS` means the supplied evidence supports the criteria with no
material issue; `REVISE` identifies a concrete issue before acceptance; and
`BLOCKED` means the reviewer cannot reach a reliable conclusion. The manager
weighs that report with the real workspace and deterministic checks when deciding what
to accept. A small clear task may close from deterministic evidence alone. Use
Sol only when stronger judgment is worth its cost.

## Long work

For work that must survive a fresh conversation, use
`$iron-box-durable-state`. It is an optional companion skill: orchestration
does not depend on the packaged profiles or on durable state for a small,
self-contained task.

The root distinguishes static checks from live runtime/UI proof and tells the
user what remains uncertain.
