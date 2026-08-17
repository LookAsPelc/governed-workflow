---
name: iron-box-durable-state
description: Maintain a compact, recoverable task contract and verified state for multi-step work that must survive a fresh Codex conversation. Use when work will span multiple delegations, pauses, or context resets.
---

# Iron Box Durable State

For a task larger than a small self-contained edit, create project-local
`.iron-box/task.json` and `.iron-box/state.json` from the bundled templates.
This skill is independent of custom agent profiles and orchestration; use it
whenever durable recovery is useful.

## Maintain the two files

- Keep `task.json` stable: original goal, protected constraints, and acceptance
  criteria.
- Keep `state.json` current: verified progress, remaining todos, decisions,
  blockers, uncertainty, and approaches not to reuse.

## Work from evidence

Before the next substantive action or delegation, read both files. After
material progress, a decision, a blocker, or an invalidated approach, update
`state.json`. Promote only evidence-backed results to `verified_progress`.
A worker report and a reviewer verdict are useful evidence, but the state stores
what was established and what remains—not a transcript or a task-level verdict.

## Resume

Start a fresh root by reading `task.json`, then `state.json`, checking any
referenced evidence that may be stale, and selecting the smallest next action.
The workspace plus these files must be enough to resume without the prior chat.

See [durable task state](../../docs/durable-task-state.md) for the templates and
field definitions.
