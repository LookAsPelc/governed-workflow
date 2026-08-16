---
name: iron-box-orchestration
description: Practical routing for bounded Codex work with a focused root manager, Luna workers, and optional Sol review.
---

# Iron Box orchestration

Iron Box is a small contract over native Codex orchestration. The root/manager
keeps its own context focused on the user goal, constraints, decisions, TODOs,
integration, and verified progress. It delegates bounded work, chooses the
role, model, and reasoning effort, and keeps fresh task packets small.

```text
Manager / orchestration proxy
├── gpt-5.6-luna (Medium → Max) — normal workers and routine reviewers/verifiers
└── gpt-5.6-sol (Low → High) — difficult reasoning, peer consultation, escalation, architecture, high-value review
```

## Choose an execution mode

Model routing and execution topology are separate decisions. For each bounded
work item, choose one of these global modes and apply the same governance
contract to it.

**Subagent mode** uses the host's supported multi-agent/subagent capability.
The root can directly spawn delegated workers, collect their reports, wait for
completion, and control their lifecycle when those operations are exposed by
the running host. This is a good fit when the root needs direct orchestration
of parallel or sequential workers.

**Thread mode** uses a separate or new thread as an independent worker context.
It is useful when stronger context isolation is desirable, explicit thread
separation fits the task, or the host/user prefers that topology.

## Route work simply

Use Luna by default for bounded implementation, research, debugging, routine
checking, and review.
Use Sol when difficult reasoning, architecture, risk,
conflicting evidence, escalation, or high-value review is worth the extra cost.
The routing choice remains
independent of whether the work runs as a subagent or in a separate thread.
Profile reasoning efforts are defaults and fallbacks, not fixed routing: choose
the least costly effort that can reliably meet the task's confidence needs.

Before every delegated worker start, visibly announce exactly:

`execution mode | role | model | reasoning effort | context being passed`

Pass only the goal, relevant constraints and decisions, exact ownership,
acceptance criteria, verified context, risks, and the requested report shape.
Do not forward the whole root conversation or private reasoning. Delegated
workers do not spawn descendants, change unrelated files, or silently widen
scope. In thread mode, the host or user creates the separate top-level thread
when supported; the root supplies the packet and later integrates the result.

The manager applies simple economics: keep work in one bounded packet when
that is enough; fan out only disjoint work where the expected time or judgment
benefit justifies the cost. Retry with a changed, causal packet after failure.
Escalate an unsettled requirement, destructive action, safety issue, or
unprovable criterion.

Keep the controller stable when feedback arrives: change the smallest possible
part of the current plan, reuse valid completed work, and steer useful active
workers instead of cancelling them by default. One worker is the default;
fan-out must justify its context, compute, and integration cost. Verify factual
corrections before agreeing or rejecting them—user authority sets goals and
preferences, not external facts. The manager may make lightweight local
inspections when that is cheaper than delegating; substantial worker work still
belongs in a bounded packet.

## Verification proportional to the task

Worker report != proof. A worker reports changed files, exact commands and
results, observations, and uncertainty; the root decides what is verified.

For a small, clear task, deterministic evidence such as focused tests, a
compiler/type check, a lint result, or a direct diff inspection may be enough
to close the task. Ask a fresh Luna verifier when independent judgment adds
value: semantic changes, non-obvious scope, conflicting evidence, or a useful
read-only check. Ask Sol only when high-judgment review is worth its cost; Sol
is optional and never a mandatory final gate.

Any Luna or Sol review packet should include the goal, constraints, criteria,
declared scope, actual diff/artifacts, exact command results, deviations, and
capability claims. The reviewer checks unmet criteria, scope creep or unrelated
edits, needless abstractions/refactors/reinvention, excessive complexity, and
unsupported claims. Reviewers are read-only and report PASS, REVISE, or
BLOCKED with concrete evidence.

## Durable state when recovery needs it

For work larger than a small self-contained edit, copy the task and state
templates into `.iron-box/`. This directory is ignored and enables a fresh
root to recover the goal and current work; it is not a workspace or audit
database. Keep only the goal, important constraints, acceptance criteria,
remaining TODOs, verified progress, important decisions, blockers, and
uncertainty. Do not turn it into an event log, evidence archive, claim store,
or transcript.

The root reviews the final diff and evidence, distinguishes static checks from
live runtime/UI proof, and tells the user what remains uncertain. Keep the
workflow small enough that the next manager can understand it without the old
conversation.
