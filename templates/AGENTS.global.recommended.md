> Code and think in English unless the user prefers another language.

# Development phases

1. Clarify the objective, constraints, and acceptance criteria.
2. Find a solution and implement it.
   - The root agent orchestrates the work and records a Goal and concrete TODO
     list before development.
   - Give each worker a bounded responsibility, acceptance criteria,
     verification command, and escalation condition.
   - Leave comments when they explain an invariant, safety boundary, or
     non-obvious decision.
3. Hand off with appropriate cleanup, tests, static checks, linting, and
   changelog work.

# Skills

- Use Superpowers judiciously; it is guidance, not law.
- TDD is most useful for bug fixes and behavior with a settled contract.
- Route governed multi-agent work through `$iron-box-orchestration`.
- Use a diagram when it materially clarifies architecture, flow, or ownership.

# Collaboration

Terra Medium is the base manager: it owns scope, routing, durable state,
integration, and final communication, not implementation. Luna is the default
pool for bounded implementation, research, debugging, verification, and review.
Sol is an optional peer for difficult architecture, uncertainty, or high-value
review—not an automatic escalation tier. Treat worker reports as claims; commit
only independently verified evidence to task state. Preserve existing user
instructions, escalate unsettled requirements, and report exact verification
evidence.

Before interrupting, respawning, or fanning out, inspect durable state, active
status, and latest evidence. Keep an in-scope worker progressing; interrupt
only for requirement change, scope or safety violation, bounded retry
failure/block, or stale/contradictory evidence. Never duplicate an active
worker. Fan out only disjoint work with independent acceptance/evidence and a
justified cost/time benefit, reuse stable context, and record a concise
rationale in durable state where applicable.

Every claimed completion, including trivial work, requires a fresh read-only
independent review. The packet includes goal/protected constraints, all
criteria, declared scope, actual diff/artifacts, exact commands/results,
deviations/workarounds, and capability claims. The reviewer checks criterion
coverage, out-of-scope side effects, unapproved improvisation, and
unsupported/unobserved claims; PASS requires all four plus evidence.
Deterministic evidence informs but never bypasses this review. Luna is the
default verifier; Sol is reserved for proportional high-judgment review.
