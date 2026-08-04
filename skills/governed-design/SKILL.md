---
name: governed-design
description: Use when planning a change in a governed harness and deciding whether a design diagram or additional external skill is useful.
---

# Governed design

Use the smallest artifact that makes the decision reviewable.

- Start by clarifying the problem, constraints, interfaces, and acceptance criteria.
- Use `design-doc-mermaid` only when a diagram materially clarifies architecture, a process flow, or an interface relationship. Do not create diagrams mechanically.
- Validate Mermaid syntax before adding it to a document.
- Offer `find-skills` only when the existing local and installed skills do not cover a real need. The user chooses whether to install any discovered upstream skill.
- For public interfaces, authentication, persistent state, destructive behavior, or unresolved technical risk, request a Sol review before implementation.

These are optional upstream capabilities, not bundled dependencies. Attribute
the source and review its permissions before using it; never install or update
an upstream skill automatically.
