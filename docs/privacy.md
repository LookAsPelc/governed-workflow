# Privacy and safety

Iron Box is a public, non-telemetry workflow. It does not collect usage data,
phone home, or send project content to its maintainers.

## Local command boundaries

`scripts/iron-box-status.sh` is read-only. It inspects local Codex and Copilot
availability, configuration, capability flags, and model catalogs without
starting a client or making a network request.

`scripts/apply-iron-box.sh` is a dry-run by default. A write requires both an
explicit action and `--apply`; invoking it without an action makes no changes.
The supported actions are narrowly scoped:

- `--profile` updates only the allow-listed portable profile settings in
  `$CODEX_HOME/config.toml`.
- `--write-global-agents` updates only the managed Iron Box block in
  `$CODEX_HOME/AGENTS.md`, preserving unrelated instructions.
- `--native-luna-v2` is an explicit Luna catalog override. It updates only the
  single Luna catalog version and its derived `model_catalog_json` setting;
  `--copy-models-cache PATH` additionally copies a supplied fresh V2 cache.

The portable profile does not manage sandbox policy, approval policy, MCP
servers, credentials, arbitrary runtime paths, or project trust. Iron Box does
not install a client, run project code, or change project files. The native
Luna action is the explicit exception for its derived catalog path and does
not refresh a cache unless `--copy-models-cache` is separately selected.

Existing files changed by an approved action receive a `.bak` backup, and
updates are atomic. Malformed, duplicate, symlinked, or non-regular targets are
rejected before a write. A stale, missing, malformed, or mismatched model
catalog/cache is reported as a warning; it is not silently refreshed or
removed.

Optional documentation providers may receive queries and client-selected
context; review the provider policy and choose skip when that boundary is not
acceptable. Upstream dependencies are never installed or updated silently.
Confirm exact targets before destructive operations and preserve unrelated
user instructions.
