# Iron Box

![Iron Box](assets/app-icon.png)

Iron Box is a small, user-owned Codex workflow built around Luna workers,
Terra execution, Sol review, and root-owned integration. It explains what it
is about to change, preserves unrelated configuration, and leaves the key
with the user.

## What it does

Iron Box provides:

- client and capability checks that prefer the installed client's current,
  official documentation;
- explicit, reviewable approval gates for configuration and optional
  dependencies;
- portable, narrowly scoped local changes that preserve unrelated user
  instructions;
- read-only status checks and offline validation scripts for inspecting the
  harness without starting a client or calling a network service; and
- a consent-gated onboarding skill for setting up the complete plugin package.
  A copied skill is not a supported installation.

After installation, read the
[`iron-box-onboarding` skill](skills/iron-box-onboarding/SKILL.md). It is the
authoritative guide to the current onboarding conversation and client-specific
choices; the README intentionally keeps those details out of the bootstrap.

## Installation

For a normal installation, give your Codex agent this repository URL and ask it
to install Iron Box. The agent should use the plugin installation surface
provided by the running client, then continue with the onboarding skill after
the plugin is refreshed. It should not clone the repository into your project,
copy role files by hand, or drive the host application through a terminal.

For a terminal installation, use the supported Codex marketplace flow:

```bash
codex plugin marketplace add LookAsPelc/governed-workflow
codex plugin add iron-box@iron-box
```

For development from a local checkout, replace the repository argument with
`.`. The first command registers the `iron-box` marketplace; the second
installs the complete plugin package into Codex's plugin cache. The equivalent
supported Plugins/Marketplace UI is fine as well.

After installation, invoke `$iron-box-onboarding`. Refresh plugins or restart
Codex only when the skill is not visible or the client documents that it is
needed. The onboarding skill checks the loaded package before offering setup;
if the package is incomplete, it explains how to reinstall it and stops.

The installation only installs the plugin. The onboarding conversation then
walks through the available roles, global instructions, and recommended
settings one topic at a time.

## Agent instructions

When a user gives an agent the Iron Box repository, the agent should:

1. Use the running client's supported plugin installation surface for
   `LookAsPelc/governed-workflow`.
2. Confirm that Iron Box is enabled. Refresh or restart only if the client
   requires it for the skill to appear.
3. Invoke `$iron-box-onboarding` immediately and let that skill lead the user
   through the rest of setup.

Do not improvise a second installer. The onboarding skill is the source of
truth for the conversation after the package is loaded.

## Safety and privacy

Iron Box has no telemetry and does not send project content to its maintainers.
Optional integrations follow their own data policies. Configuration changes
preserve unrelated instructions.

## Verification

Maintainers can run the offline checks from the repository root:

```bash
bash scripts/validate.sh
bash tests/test-iron-box-scripts.sh
```

These checks are contributor/CI tooling, not end-user installation
requirements.

## Contributing

Keep changes narrow, preserve unrelated user configuration, and document the
evidence for client-specific claims. The onboarding skill is the authoritative
place for setup behavior; this README intentionally keeps the bootstrap small.

## License

Iron Box is distributed under the [MIT License](LICENSE).
