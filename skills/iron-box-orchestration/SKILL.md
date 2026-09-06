---
name: iron-box-orchestration
description: Small, governed Codex routing for bounded work, verification, and escalation.
---

# Iron Box orchestration

Iron Box owns orchestration and verification around native development
workflows. The root/manager owns the user goal, scope, decomposition, routing,
integration, acceptance decisions, and communication.
The main thread does not perform routine implementation, tests, lint, or similar
execution itself. Delegate routine exploration and execution where useful; the
root performs the necessary read-only review, understands important edits and
their implications, and checks that the result serves the intent beyond merely
passing tests. Agents work in English: use English for inter-agent packets,
progress, reports, code, and comments. Write artifact prose for its intended
audience; user-facing communication follows the user's language.

```text
Manager / orchestration proxy
├── Luna (High / xhigh / max as justified) — bounded work and fresh checks
└── Sol (Low → High) — proportional architecture, security, or judgment peer
```

Superpowers owns the surrounding development process. Use its brainstorming,
specifications, implementation plans, debugging, progress artifacts, and
recovery guidance where they help.
Prefer those native artifacts to inventing parallel Iron Box state. Small tasks
stay light; Superpowers is guidance, not a ceremony for every task.

When resuming, start from project code, Git, tests, specifications, and plans
when those artifacts exist.

When the coordinator spawns a worker, it chooses `fork_turns` for the parent conversation history
passed to it: use `none` when no history is needed, `all` for full history, or a
positive number for a bounded recent slice. Pack only the context the worker
needs.

## Delegate bounded work

Before launch, announce `role | model | reasoning effort | context being
passed`. Pass a concise packet: objective, scope and constraints, current
artifact, acceptance criteria, required evidence, and escalation condition.
Workers do not spawn descendants, silently widen scope, or change unrelated
files. A worker report is a claim, not proof. Give concurrent writers disjoint
ownership and serialize overlapping changes. The manager reviews the actual
diff, runtime, or other artifact and weighs delegated evidence in proportion to
risk; it does not replace that review with test passage alone.

Keep the root context focused: use workers for routine exploration and request
concise reports of results, artifacts, checks, and issues. Open only the source,
diff, or other artifacts needed for a decision instead of collecting full files,
logs, or transcripts. Follow-ups carry the delta and the evidence needed for
the next decision.

Use Luna High for settled approaches and mechanical bounded work. Use xhigh
when interacting constraints or debugging need deeper reasoning. Use max only
for a hard, still bounded Luna-suitable question where the extra effort is
justified; do not walk every task through a High/xhigh/max ladder. Clarify
missing requirements or inspect missing environment/data before escalating.

Reuse a worker when the follow-up concerns the same module or problem and its
context is accurate. Start fresh for an independent review, unrelated scope,
stale or overloaded context, or a worker showing fixation. Send the goal,
current artifact, delta, and evidence needed for the next decision rather than
the whole conversation.

Use Sol when architectural, security, or high-value judgment is worth the
cost, when conceptual uncertainty persists, or when a well-evidenced Luna
attempt failed. Sol is a peer and escalation path, not a mandatory gate or a
step in a fixed model ladder. Use the smallest worker set that adds real
independent value.

For verification, prefer a fresh read-only Luna reviewer when independent
judgment adds value. Its result is `PASS`, `REVISE`, or `BLOCKED`, with findings,
evidence, and uncertainty. Deterministic checks may close a small clear task;
otherwise the manager weighs the reviewer report with the real workspace. If
the workspace may keep changing, review a frozen commit or artifact version.
Keep static configuration evidence distinct from live client/model capability.

Do not push, publish, deploy, change production, or make destructive external
changes without explicit user authority. The manager escalates unresolved
scope, safety, or capability questions instead of silently widening the task.
