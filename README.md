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
  documented Copilot CLI surface.

After installation, read the
[`iron-box-onboarding` skill](skills/iron-box-onboarding/SKILL.md). It is the
authoritative guide to the current onboarding conversation and client-specific
choices; the README intentionally keeps those details out of the bootstrap.

### A small companion

Jax is an optional Iron Box companion, kept in
[`assets/pets/jax`](assets/pets/jax). Think of him as a bright little footnote
to the journey, not a hidden trick: Jax is **not** an undocumented plugin
feature. Set him up only through the currently supported client UI/flow, and
only after onboarding has verified that the client is compatible.

## Agent-first bootstrap

When an agent receives this repository URL, it should:

1. Identify the current client.
2. Consult the current official documentation and capabilities.
3. Install Iron Box through the supported flow.
4. Request a client restart.
5. Immediately invoke `$iron-box-onboarding`.

## Safety and privacy

Iron Box has no telemetry and does not send project content to its maintainers.
Optional documentation providers may receive queries and context selected by
the active client; review that boundary and skip a provider when it is not
acceptable. Upstream dependencies are never installed or updated silently.
Configuration changes require explicit user approval, preserve unrelated
instructions, and confirm exact targets before destructive work. See
[docs/privacy.md](docs/privacy.md) for the concise contract.

## Verification

The repository includes offline validation for its manifests and local
workflow scripts. Run these from the repository root after installation:

```bash
bash scripts/validate.sh
bash tests/test-iron-box-scripts.sh
```

## Requirements

- Git and Bash;
- Python 3.11 or newer for the offline validator and installer; and
- a currently supported Codex client or GitHub Copilot CLI installation.

For Copilot CLI, the documented marketplace install form is:

```bash
copilot plugin install LookAsPelc/governed-workflow
```

For Codex, use the current plugin/marketplace flow exposed by the installed
client. Once Iron Box is installed, restart the client and invoke
`$iron-box-onboarding`; that skill performs one capability preflight for the
client/version/platform and then leads the selected setup steps.
