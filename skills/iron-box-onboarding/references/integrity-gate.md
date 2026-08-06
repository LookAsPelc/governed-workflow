# Package gate reference

Use this only for the first, private package check. The only trusted locator is
the model-visible absolute path of the currently loaded skill.

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

This proves package completeness and identity, not provenance or cryptographic
integrity. Do not demand plugin metadata that the model cannot see, a cache
name, or a host-specific home directory. If any check fails, stop before
reading other references or touching user files. Give the reinstall,
refresh/restart, and retry path from the main skill. Never turn a copied skill
into an install by adding missing files.
