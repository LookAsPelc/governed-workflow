<!-- governed-workflow:start -->
# Development phases

1. Clarify the objective, constraints, and acceptance criteria.
2. Find a solution and implement it.
   - For development, first create a goal and a concrete TODO list.
   - Leave useful comments where they explain an invariant, a safety boundary, or a non-obvious decision.
   - Present the reviewable implementation to the user before release cleanup; discuss and iterate.
3. Hand off: cleanup, full tests, static checks, linting, and changelog as appropriate.

# Workflow

- Build development workflow around `sol-governed-workers` when it is available.
- The root agent owns requirements, integration, verification, and communication.
- Prefer a Luna worker for settled mechanical work; use Terra for bounded implementation requiring judgment; use Sol only for architecture, risky decisions, and final evidence gates.
- Keep subagents at depth one. Give each one an owned area, acceptance criteria, and an escalation condition.
- Use Superpowers selectively: TDD is a good fit for bug fixes, not a mandatory ritual for every new feature.
- Preserve unrelated changes. Validate actual diffs and relevant commands before claiming success.

# Safety and privacy

- Never request, print, commit, or persist passwords, API keys, tokens, or private customer data.
- Do not change global configuration, project instructions, models, or external integrations without explicit user confirmation.
- Before destructive operations, identify the exact target and explain the effect.
<!-- governed-workflow:end -->
