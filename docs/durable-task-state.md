# Durable task state

For work that needs recovery across conversations, copy the two templates into
a project-local `.iron-box/` directory. The directory is ignored by default.
It enables a fresh root/manager to recover the task; it is not a workspace,
audit database, event log, or evidence archive. Do not create it for a tiny,
low-risk edit.

```text
.iron-box/
  task.json       # goal and protected acceptance contract
  state.json      # small mutable progress snapshot
```

## Task template

[`templates/iron-box-state/task.json`](../templates/iron-box-state/task.json)
contains only:

- `goal`: the user's goal in plain language;
- `protected_constraints`: important constraints that must survive delegation;
- `acceptance_criteria`: the conditions for completion.

The root/manager owns this contract. Workers and reviewers may identify an
ambiguity, but do not silently rewrite the goal or criteria.

## State template

[`templates/iron-box-state/state.json`](../templates/iron-box-state/state.json)
contains only:

- `remaining_todos`;
- `verified_progress`;
- `important_decisions`;
- `blockers`;
- `uncertainty`.

Use short human-readable entries. A worker report is a claim, not proof: put a
result in `verified_progress` only after deterministic checks or a proportional
fresh review supports it. Keep command names, file paths, or other compact
references when they help a new root reproduce the check, but do not build an
ID scheme, timestamp ledger, fingerprint archive, claim registry, or chat dump.

## Recovery

1. Read `task.json` to recover the goal, constraints, and criteria.
2. Read `state.json` to find remaining TODOs, verified progress, decisions,
   blockers, and uncertainty.
3. Re-check important progress when the underlying files or evidence have
   changed, then send the smallest fresh packet to Luna or Sol.

Small clear work may close with deterministic evidence. Request a fresh Luna
or optional Sol review when independent judgment adds value; Sol is never a
mandatory final gate. In every case, distinguish static checks from live
runtime/UI observations and tell the user what remains uncertain.

This deliberately small format has no daemon, database, generic event log,
background watcher, custom executor, or mandatory process. Native Codex
subagents, normal tests, and ordinary project files remain the mechanisms of
execution and observation.
