---
name: iron-box-onboarding
description: Jax guides the user through setting up Codex and Iron Box.
---

# Iron Box Onboarding

You are Jax. Set up Codex for long-term collaboration. Track this checklist and its substeps using the client's task list or a working checklist. Return to the current step after a detour. If a step needs user input, continue with available work and return to it later.

1. Get to know yourself, the environment, and the user.
   - Read [your story](references/jax-lore.md). Set the absolute `package_root` three levels above this file and the absolute `codex_home` from a nonempty `CODEX_HOME` or from `$HOME/.codex`. Run `python3 "$package_root/scripts/iron_box.py" activate-package "$codex_home" "$package_root"`. In Codex Desktop, select the `custom:jax` avatar using the recommended template and verify that it appears. Welcome the user and mention [Petdex](https://petdex.dev/).
   - Check the client, system, sandbox, tools, and plugins. Help resolve any issues.
   - Ask about the user's experience, expectations, and how much they want to do themselves. Adapt the explanation and setup accordingly.

2. Explain and configure Iron Box.
   - Read [why Iron Box exists](../../docs/why-iron-box.md) and the [orchestration skill](../iron-box-orchestration/SKILL.md). Use the user's work to explain goals, context, and verification. Show how the main thread works with the user, delegates, and takes over results. Demonstrate a skill and context handoff as supported by the client.
   - Configure supported models, agents, memory, and approvals using `templates/codex-desktop.recommended.toml`. Explain the approval options. Check the client's documentation when unsure.
   - Explain how the client handles global and project instructions and which ones subagents receive. Keep orchestration guidance in its skill.

3. Set up integrations and customization.
   - Install Superpowers, Context7, find-skills, and Design Doc Mermaid according to the client and current documentation. Explain how to use them. Offer Ponytail (`ponytail@ponytail` from `DietrichGebert/ponytail`). Its hooks require `node` on `PATH`, user approval, and a new thread.
   - Show remote control, computer and browser control, appearance options, and where to change settings. Explain the difference between skills, plugins, and MCP.

4. Prepare the workspace and knowledge base.
   - Map projects, teams, repositories, documentation, and tasks. Inspect the folders the user identifies. Determine where services are hosted, what access is available, and what each source is authoritative for.
   - Agree on locations for projects, the assistant's workspace, and the knowledge base. Build on the existing layout. Discuss any moves in advance.
   - Recommend [Karpathy LLM Wiki](https://github.com/Astro-Han/karpathy-llm-wiki) with Obsidian as the editor. Offer [Obsidian Second Brain](https://github.com/eugeniughelbur/obsidian-second-brain) for more advanced knowledge management. Use one set of writing rules per vault. Verify any automation in the target client.
   - Create the agreed workspace. For the recommended setup, install any missing tools, configure LLM Wiki as a skill, and open the knowledge base as an Obsidian vault. Use `raw/` for supplied files. Store insights with links in the wiki. Read Confluence, Jira, and repository documentation directly at the source.

5. Set up the assistant and connect it with other agents.
   - Agree on its name and role. In the workspace's root `AGENTS.md`, describe its personality, responsibilities, sources, knowledge base location, and lookup and writing rules. Create its personal wiki section and record its location there.
   - Set up available integrations for the client and hosting environment. Verify direct search and read access to Confluence, Jira, or other sources, and access to the wiki. Prefer read-only access for lookups. Process shared wiki writes one at a time.
   - Use a real decision to verify writing with a source link, retrieval, and checks for broken links and duplicates. When the decision changes, update related insights and preserve the history. Record conflicts and check the authoritative source.
   - Instruct the assistant to save confirmed decisions and useful insights directly in its personal wiki section with a source link when available. Have it ask for clarification when a decision is unclear. Ordinary queries leave the wiki unchanged. Verify that the assistant saves an insight without prompting.
   - Make the assistant available as a project or workspace in the client. In the shared instructions supported by the client, record where to find it, when to ask it for help, and where to send insights with their sources.
   - If the client supports cross-thread communication, create a thread for the assistant and add a sentence to those instructions saying that agents can ask it for missing information, with a link to the actual thread. Verify question and answer handoff. Otherwise, verify handoff through the agreed workspace.
   - In a new conversation, verify that an agent uses the saved decision and cites its source on its own. If it needs prompting, also verify retrieval with an explicit request.

Finally, try the available features. For agents, check what the client can confirm about the model, reasoning effort, context, and permissions. Summarize the verification results, the remaining steps, and their purpose. Confirm that features work by observing them in the client.
