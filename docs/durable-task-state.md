# Durable task state

When recovery from a fresh conversation is expected or useful, copy the two
templates into a project-local `.iron-box/` directory. It is a compact recovery
checkpoint, not a workspace, audit database, event log, or evidence archive.
The project decides whether to ignore `.iron-box/`.

```text
.iron-box/
  task.json       # stable task contract
  state.json      # mutable, verified progress snapshot
```

## Lifecycle

1. Before the next substantive action or delegation, read both files.
2. Give a worker the original goal, relevant durable state, and only the
   bounded context it needs—not the accumulated root conversation.
3. Treat the worker report as a claim. Check it proportionally with direct
   evidence or an independent review.
4. After material progress, a decision, a blocker, or an invalidated approach,
   update `state.json`. Only evidence-backed results belong in
   `verified_progress`; rejected work remains evidence, not progress.

A fresh root must be able to resume from the workspace and these two files
without the previous chat.

## Review input

A fresh Luna verifier may return `PASS`, `REVISE`, or `BLOCKED` with findings,
evidence, and uncertainty. That report can support a state update, but
`state.json` records verified facts and remaining work—not a review ceremony or
a task-level verdict. Small clear work may instead rely on deterministic
evidence.

## Stable task contract

[`templates/iron-box-state/task.json`](../templates/iron-box-state/task.json)
contains only:

- `goal`: the user's goal in plain language;
- `protected_constraints`: important constraints that must survive delegation;
- `acceptance_criteria`: the conditions for completion.

The root/manager owns this contract. Workers and reviewers may identify an
ambiguity, but do not silently rewrite the goal or criteria.

## Current task state

[`templates/iron-box-state/state.json`](../templates/iron-box-state/state.json)
contains only:

- `remaining_todos`;
- `verified_progress`;
- `important_decisions`;
- `blockers`;
- `uncertainty`; and
- `do_not_reuse`: rejected approaches or stale claims that a fresh root must
  not treat as progress.

Use short human-readable entries. Include a compact command, file path, or
artifact reference only when it helps a fresh root reproduce important proof.
Do not add an ID scheme, timestamp ledger, fingerprint archive, claim
registry, or chat dump.

Small clear work may close with deterministic evidence. For semantic or
non-obvious work, use a fresh independent check when it adds value. In every
case distinguish static checks from live runtime/UI observations and report
what remains uncertain.
