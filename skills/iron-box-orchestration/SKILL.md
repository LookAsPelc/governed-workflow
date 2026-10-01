---
name: iron-box-orchestration
description: Small, governed Codex routing for bounded work, verification, and escalation.
---

# Iron Box orchestration

The root is accountable for the user's goal, scope, decisions, integration, and communication. It chooses how to do the work and whether delegation adds value across the remaining task, including dispatch and handoff costs. Handle small, obvious actions directly when delegation would cost more. Give progress and problems plainly; involve the user when intent or scope needs their decision.

Inter-agent assignments, reports, code, and comments are in English. Write artifacts for their intended audience and communicate with the user in the user's language. Use Superpowers and the project's existing code, tests, specifications, and plans when they help; do not maintain parallel Iron Box task or recovery state.

## Route the work

Choose Luna or Sol and set reasoning effort for the task. The role profile supplies the model; override it only when routing calls for a different model.

- Use the latest Luna profile at High for normal bounded work, XHigh for reconciling conflicting constraints or debugging with competing hypotheses, and Max for difficult but bounded exploration.
- Use the latest Sol profile for a narrow, evidence-backed consultation at Low, to compare alternatives and consequences at Medium, or for difficult architecture and consequential uncertain judgment at High.

Set effort when a worker is started; follow-ups keep it. Consider the remaining work and value of a fresh context before starting another worker just to change effort. Choose `fork_turns` to preserve the context the worker needs: `none`, a recent slice (which may retain useful details lost in a summary), or `all`. Count rediscovery and rework as well as prompt length.

Delegate bounded work when it saves meaningful effort across the task. Keep concurrent writers on separate files or responsibilities and serialize overlapping edits. Batch related work; avoid dispatching tiny isolated steps. Reuse the same worker for related follow-ups while its context remains useful. Start a fresh worker for unrelated work, independent review, stale context, or when the current worker is stuck.

Keep assignments and handoffs proportional to the task. Give the worker enough goal, constraints, ownership, and acceptance context to proceed, then add only relevant deltas in follow-ups.

## Coordinate and verify

Let workers finish and report actual blockers; silence or elapsed time alone is not a reason to prompt or interrupt. Intervene when new information materially changes direction or the user changes priorities.

Scale verification to the work. Check the actual artifact and relevant evidence before accepting it. A separate read-only review can add value when independent judgment may find a meaningful issue; routine completion may need only a deterministic check. The root remains responsible for understanding the accepted result. Distinguish static configuration from demonstrated live capability.
