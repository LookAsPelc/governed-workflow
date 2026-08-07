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

The base thread owns scope, integration, and final communication. Luna handles
bounded mechanical work, Terra handles implementation needing local judgment,
and Sol reviews risky plans and evidence. Preserve existing user instructions,
escalate unsettled requirements, and report exact verification evidence.
