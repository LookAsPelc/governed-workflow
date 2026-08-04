---
name: find-skills
description: Use when the current client needs an optional skill that is not covered by the installed local skills.
---

# Optional skill discovery

Treat discovery as a user-approved lookup, not as an automatic dependency
installer.

1. Check the local and already-installed skills first.
2. If a real gap remains, offer the upstream Vercel `find-skills` project and
   explain what it would add. Link to its documentation before any install.
3. Let the user choose whether to inspect, install, or skip a candidate. Do
   not copy upstream skill text into this repository or update dependencies
   automatically.
4. Review the candidate's permissions, network behavior, and maintenance
   status. Do not submit private project text or credentials during discovery.

The shared skill layout remains `skills/<name>/SKILL.md`; a client may need the
user to copy or link that directory into its own supported skills directory.
