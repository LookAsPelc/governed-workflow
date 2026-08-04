---
name: context7-setup
description: Use when a user asks to configure Context7 documentation lookup in Codex or Copilot CLI.
---

# Context7 setup

Context7 is optional. First explain the data boundary: a provider may receive documentation queries and the surrounding context selected by the active client. Respect organisation policy and do not send proprietary text merely to test setup.

1. Detect the client and ask the user which integration they want.
2. In Codex, prefer a currently available curated Context7 App from the Codex catalog.
3. If that curated App is unavailable, or when the client is Copilot CLI, offer
   remote OAuth MCP, local MCP, or skip. Explain the privacy and network trade-off
   of the selected option before setup.
4. Do not request, print, write, or commit an API key. Complete OAuth only
   through the client/provider's interactive flow.
5. Verify only that the client lists the selected integration; do not send
   proprietary project text merely to test it.
