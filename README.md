# Iron Box

![Iron Box](assets/app-icon.png)

Iron Box is a small, user-owned governance harness for Codex and GitHub
Copilot CLI. It gives an agent a steady place to stand before it starts
changing things: inspect the client that is actually running, check the
current documentation, explain the proposed action, and wait for your
consent.

The name is a metaphor, not a promise of invincibility. An iron box is a
sturdy container for useful tools and bright ideas: it keeps the workflow
together while leaving the key in your hands. The project borrows a little
wonder from moonlit stories. Project prose and implementation are original
except for the adapted third-party profiles documented in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The public repository is
<https://github.com/LookAsPelc/governed-workflow> on the `main` branch. The
product and plugin identity are **Iron Box** (`iron-box`).

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
- a consent-gated onboarding skill for adapting the workflow to Codex or the
  documented Copilot CLI surface. Onboarding is supplied by the complete
  plugin package; a copied skill is not a supported installation.

After installation, read the
[`iron-box-onboarding` skill](skills/iron-box-onboarding/SKILL.md). It is the
authoritative guide to the current onboarding conversation and client-specific
choices; the README intentionally keeps those details out of the bootstrap.

## Installation

For a normal installation, use the supported plugin or marketplace flow for
the client you are running. With the Codex CLI, run the following from the
root of the checkout:

```bash
codex plugin marketplace add .
codex plugin list --marketplace iron-box --available
codex plugin add iron-box@iron-box
```

The first command registers this local Git checkout as the `iron-box`
marketplace. The second is an optional check that the plugin is discoverable;
the third installs the complete plugin package into Codex's plugin cache. Use
the equivalent supported Plugins/Marketplace UI when working in Codex Desktop.

After installation, restart Codex and use its documented `Refresh`/`Reload
plugins` action when available. Then invoke `$iron-box-onboarding` in the same
thread. The onboarding skill checks the plugin's identity and its
`iron-box-package.json` runtime payload before it offers any write. If that
package is incomplete, it explains how to repair the plugin and stops without
a skill-only fallback.

The commands above install the plugin itself. They do not silently install
roles, modify `config.toml`, or enable optional integrations; those are
separate, consent-gated onboarding choices.

## Optional Jax companion

Jax is an optional Iron Box companion, kept in
[`assets/pets/jax`](assets/pets/jax). Think of him as a bright little footnote
to the journey, not a hidden trick: Jax is **not** an undocumented plugin
feature. Set him up only through the currently supported client UI/flow, and
only after onboarding has verified that the client is compatible.

## Agent bootstrap

When a user gives an agent the Iron Box repository, the agent should:

1. Install the Iron Box plugin through the client's supported plugin or
   marketplace flow.
2. Restart the client and use its documented Refresh/Reload plugins action,
   when available.
3. Immediately invoke `$iron-box-onboarding` in the same thread. Start a new
   chat only if the skill is absent after the refresh.

The onboarding skill performs the client/version and package-integrity checks;
the bootstrap does not guess paths or run shell workarounds.

## Client support

Codex is the primary client for the packaged governance profile and role
assets. GitHub Copilot CLI remains documented as a supported client for the
surfaces it currently exposes, but Iron Box does not claim Codex TOML roles,
Codex MultiAgent behavior, custom pets, or automatic-install parity for
Copilot without current evidence from both the client and its official
documentation. Unsupported or unclear capabilities are skipped or offered as
user-guided instructions.

## Safety and privacy

Iron Box has no telemetry and does not send project content to its maintainers.
Optional documentation providers may receive queries and context selected by
the active client; review that boundary and skip a provider when it is not
acceptable. Upstream dependencies are never installed or updated silently.
Configuration changes require explicit user approval, preserve unrelated
instructions, and confirm exact targets before destructive work. See
[docs/privacy.md](docs/privacy.md) for the concise contract.

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
