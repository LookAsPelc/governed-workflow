# Integrity gate reference

This reference expands the gate in `SKILL.md`; read it before any target
inspection or write. The only trusted locator is the model-visible absolute
path of the currently loaded skill.

1. Check the exact suffix `skills/iron-box-onboarding/SKILL.md`.
2. Starting there, walk ancestors upward and select the nearest directory that
   contains readable regular files `iron-box-package.json` and
   `.codex-plugin/plugin.json`. Do not skip to a farther parent.
3. Parse both as JSON objects and require `name == "iron-box"` in each.
4. Parse `runtimeRequired` from the sentinel. Normalize each relative path;
   reject absolute paths, `..`, duplicates, malformed entries, symlinks,
   Windows reparse points, and non-regular files. Every required path must be
   contained by the candidate root and present. The optional payload is usable
   only if every optional path passes the same test.

This is package completeness and identity checking, not cryptographic
verification. Do not demand `plugin_id`, plugin-qualified metadata, a cache
name, or `$CODEX_HOME`. If any check fails, stop and provide the repair,
restart, refresh, and retry sequence from the main skill. Never turn a copied
skill into an install by adding missing files.

