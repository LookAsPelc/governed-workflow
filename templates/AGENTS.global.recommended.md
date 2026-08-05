<!-- iron-box:start -->
>Code and think in English.
Communicate in Czech only with the developer.

# Development phases

1. Clarify the objective, constraints, and acceptance criteria.
2. Find a solution and implement it.
   - The root agent is the orchestrator: create a Goal and a concrete TODO list before development.
   - Give every worker a distinct ownership boundary, acceptance criteria, verification command, and escalation condition.
   - Leave useful comments where they explain an invariant, safety boundary, or non-obvious decision.
   - Present the reviewable implementation to the user before release cleanup; discuss and iterate.
3. Hand off: cleanup, full tests, static checks, linting, and changelog as appropriate.

# Skills
- Superpowers are great skills, but they are not law—use them judiciously.
- TDD is suitable for bug fixing, not for developing new features.
- Route governed multi-agent work primarily through `$iron-box-orchestration` or `$subagente-Driven Development`.
- Explain things graphically using Mermaid.

Base thread
├── Luna worker — research and mechanical tasks in a new thread (preferred)
├── Terra executor — more difficult work
└── Sol consultant — architecture, difficult problems, and critical review (optional)
<!-- iron-box:end -->
