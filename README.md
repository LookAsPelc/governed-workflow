# Iron Box

![Iron Box](assets/app-icon.png)

Iron Box is a guided workflow for Codex Desktop. It helps the user set up and
use three cooperating workers—Luna, Terra, and Sol—with Jax as the onboarding
guide.

## For the installation agent

If the user asks you to install this repository, use the supported plugin
installation flow. **After installation, immediately invoke the
`$iron-box-onboarding` skill and continue according to its instructions.**

Do not stop after reporting that the plugin was installed. Do not clone the
repository into the user's project or copy role files by hand. If the skill is
not visible, refresh the plugin or restart Codex only when the client requires
it, then continue with onboarding.

## For the user

Iron Box gives Codex a simple division of work:

- **Luna** — the economical first worker for routine, bounded tasks;
- **Terra** — implementation and local judgment when a task needs escalation;
- **Sol** — review of architecture, risk, and evidence; and
- **Jax** — explains the setup and guides you through the choices.

Installation is not the complete setup. Onboarding verifies the package,
activates the packaged roles and Jax through the supported client capability,
and tells you what was actually verified. It also explains relevant settings
and recommended integrations before asking whether you want to install or
activate them. You do not need to know what to ask for or how the pieces fit
together.

## Install through an agent

Give your Codex agent this repository URL and use a request such as:

> Install Iron Box from https://github.com/LookAsPelc/governed-workflow. Use the
> supported plugin flow and continue directly with the Iron Box onboarding. I
> am new to this, so explain the choices and do not stop after installation.

The agent should install the plugin through the running client's plugin or
marketplace interface. The onboarding skill is the source of truth for the
remaining setup.

## Install manually

With the supported Codex CLI, use:

```bash
codex plugin marketplace add LookAsPelc/governed-workflow
codex plugin add iron-box@iron-box
```

Then start the guided setup with `$iron-box-onboarding`. The equivalent
Plugins/Marketplace UI is also supported. For a local development checkout,
use `.` instead of the GitHub repository URL.

## If installation stopped early

Tell the agent:

> Iron Box is installed, but onboarding is not complete. Verify that the plugin
> is enabled and continue with `$iron-box-onboarding`. Explain recommended
> integrations and ask for my consent before installing or activating them.

If Jax is not active, run onboarding again rather than manually editing a
profile or copying pet files. If the client cannot verify activation, the agent
must tell you which supported UI action is needed.

The onboarding skill handles the detailed setup, preserves unrelated user
configuration, and reports unsupported or unverified capabilities honestly.