---
name: iron-box-orchestration
description: Small, governed Codex routing for bounded work, verification, and escalation.
---

# Iron Box orchestration

Iron Box handles delegation and verification around native development workflows. The root owns the user goal, scope, decomposition, routing, integration, acceptance decisions, and communication. The root does not perform routine implementation, tests, lint, or similar execution; delegate that work to workers and review the relevant evidence before accepting results. Agents work in English. Write inter-agent packets, reports, code, and comments in English; write artifact prose for its audience and user-facing communication in the user's language.

Route normal bounded work and routine independent checks to GPT-6 Luna at High reasoning. Use xhigh for interacting constraints or debugging that needs deeper reasoning; use max only for a difficult, still-bounded task where the extra effort is justified. Use GPT-6 Sol as an optional peer for difficult architecture, security, or high-value judgment, with effort scaled from Low toward High as needed.

Superpowers handles the surrounding development process: specifications, implementation plans, debugging, progress artifacts, and recovery when useful. Keep small tasks light and use existing project code, Git, tests, specifications, and plans when resuming work. Do not create parallel Iron Box task or recovery state.

Default `fork_turns` to `none` and make the task packet self-contained. Use a small positive slice only when recent conversation context matters and cannot be summarized in the packet; use `all` only when the complete interaction is necessary. `none` passes no parent history, a positive number passes that many recent turns, and `all` passes the full history.

## Delegate bounded work

Before dispatch, state the worker role, model, reasoning effort, and context being passed. Give it a concise packet with the objective, scope and constraints, current artifact, acceptance criteria, evidence needed, and escalation point. Keep concurrent writers on separate files or responsibilities; serialize overlapping edits. Workers do not spawn descendants or widen scope without direction.

Keep the root context focused: delegate routine exploration and execution, request concise reports of results, artifacts, checks, and issues, and inspect only the evidence needed for the next decision. Follow-ups should carry the delta and needed evidence rather than repeat the full conversation. Treat reports as claims and review the actual source, diff, runtime, or other relevant artifact.

Reuse a worker when its context still fits a follow-up on the same problem. Start fresh for an independent review, unrelated scope, stale or overloaded context, or demonstrated fixation.

After dispatch, let workers finish or report a meaningful status. Follow up or interrupt for user cancellation or reprioritization, a safety issue, or material new information that changes the outcome. Elapsed time or silence alone does not justify intervention; redirection can make Luna abandon earlier work, so treat it as a scope change.

Use Sol when architectural, security, or high-value judgment warrants it, conceptual uncertainty persists, or a well-evidenced Luna attempt failed. Sol is a peer and escalation path, not a required gate or step in a model ladder. Use the smallest worker set that adds independent value.

## Verify evidence

For independent judgment, prefer a fresh read-only Luna reviewer. Ask for `PASS`, `REVISE`, or `BLOCKED`, with findings, evidence, and uncertainty. A deterministic check may close a small, clear task; otherwise, weigh the reviewer report against the actual workspace. If the workspace may keep changing, review a frozen commit or artifact version. Keep static configuration evidence distinct from live client or model capability.

Do not push, publish, deploy, change production, or make destructive external changes without explicit user authority. Escalate unresolved scope, safety, or capability questions instead of silently widening the task.
