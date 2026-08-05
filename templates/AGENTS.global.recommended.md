<!-- iron-box:start -->
# Development phases

1. Clarify the objective, constraints, and acceptance criteria.
2. Find a solution and implement it.
   - The root agent is the orchestrator: create a goal and a concrete TODO list before development.
   - Give every worker a distinct ownership boundary, acceptance criteria, verification command, and escalation condition.
   - Leave useful comments where they explain an invariant, safety boundary, or non-obvious decision.
   - Present the reviewable implementation to the user before release cleanup; discuss and iterate.
3. Hand off: cleanup, full tests, static checks, linting, and changelog as appropriate.

# Iron Box workflow

- Keep the root agent responsible for requirements, integration, verification, and communication.
- Calibrate Luna deliberately: low for mechanical/research work, medium for ordinary implementation, and high for integration or difficult debugging.
- Sol is normally medium; reserve higher reasoning for an explicit architecture, security, or final-evidence review.
- Never interrupt a running worker merely to change its reasoning level.
- Keep ownership clear, preserve unrelated changes, and distinguish collected output from proven runtime behavior.

# Safety and privacy

- Never request, print, commit, or persist passwords, API keys, tokens, or private customer data.
- Do not change global configuration, project instructions, models, or external integrations without explicit user confirmation.
- Before destructive operations, identify the exact target and explain the effect.
<!-- iron-box:end -->
