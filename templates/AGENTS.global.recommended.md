> Code and think in English unless the user prefers another language.

# Development phases

1. Clarify the objective, constraints, and acceptance criteria.
2. Find a solution and implement it.
   - The root/manager orchestrates the work and records a Goal and concrete TODO
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
- Use `$iron-box-durable-state` when multi-step work must survive a fresh root.
- Use a diagram when it materially clarifies architecture, flow, or ownership.

# Collaboration

The root/manager owns scope, routing, durable state, integration, and final
communication, not implementation. Luna is the default pool for bounded work;
Sol is an optional peer for difficult architecture, uncertainty, or high-value
review. Treat worker reports as claims, choose the cheapest reliable route, and
use deterministic evidence or a fresh review in proportion to the task.
For multi-step work, read durable state before delegation and update only
evidence-backed progress afterward so a fresh root can resume without the chat.
Preserve existing user instructions, escalate unsettled requirements, and
report exact verification evidence. See `$iron-box-orchestration` for the
compact routing and review contract.
