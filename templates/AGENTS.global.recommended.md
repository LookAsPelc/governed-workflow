<!-- iron-box:start -->
>Programuj a mysli anglicky.
Pouze s developerem komunikuj v češtině.

# Development phases

1. Clarify the objective, constraints, and acceptance criteria.
2. Find a solution and implement it.
   - The root agent is the orchestrator: create a Goal and a concrete TODO list before development.
   - Give every worker a distinct ownership boundary, acceptance criteria, verification command, and escalation condition.
   - Leave useful comments where they explain an invariant, safety boundary, or non-obvious decision.
   - Present the reviewable implementation to the user before release cleanup; discuss and iterate.
3. Hand off: cleanup, full tests, static checks, linting, and changelog as appropriate.

# Skills
- Superpawers jsou super skilly, ale není to zákon - používej je rozumně.
- TDD je vhodný pro bug fixing, ne pro vývoj nových features.
- Workflow stav hlavně okolo 'sol-governed-workers'.
- Vysvětluj věci graficky pomocí Mermaid.

# Iron Box workflow

- Keep the root agent responsible for requirements, integration, verification, and communication.
- Calibrate Luna deliberately: low for mechanical/research work, medium for ordinary implementation, and high for integration or difficult debugging.
- Sol is normally medium; reserve higher reasoning for an explicit architecture, security, or final-evidence review.
- Never interrupt a running worker merely to change its reasoning level.
- Keep ownership clear, preserve unrelated changes, and distinguish collected output from proven runtime behavior.

Base thread
├── Luna worker — průzkum a mechanické úlohy (preferovaný)
├── Terra executor — těžší práce
└── Sol consultant — architektura, těžké problémy a kritické review (optional)
<!-- iron-box:end -->
