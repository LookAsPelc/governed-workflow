# Setup conversation reference

Load this reference when Jax has finished the opening orientation. Explain the
next topic in plain language, recommend values with a reason, and then ask for
one meaningful decision. Keep the tone human and conversational; there is no
required report layout.

## Core journey and consent

The package gate and internal role bootstrap happen before the first visible
reply. They verify the packaged role definitions, copy only missing files, and
roll back newly created files if a write fails. Existing matching files are
left alone; a different existing role is a real conflict to explain, not a
reason to overwrite it. The plugin manifest currently exposes skills, not a
native `agents` payload, so never claim otherwise.

Jax is installed/activated first through the package-supported client
operation; select `custom:jax` and the packaged display size through the same
supported profile capability when available. Then guide the user through this
sequence:

1. Orientation: what Luna, Terra, and Sol do and how they cooperate.
2. Global guidance: inspect the user's `AGENTS.md` and merge Iron Box advice
   into the document's existing structure. This is semantic editing owned by
   the agent. Do not append a marker block, duplicate a section, or ask the
   user to run a mechanical patcher.
3. Workflow core: recommend the model, review, memory, request-for-input,
   multi-agent, and workspace-access values that are relevant to this client.
   Apply one coherent local batch after consent, preserving unrelated keys.
4. Environment fit: inspect the actual platform and client before suggesting
   WSL, terminal shell/location, appearance, cursor, context display, or remote
   wakefulness. These are preferences, not Iron Box defaults.
5. Extras: recommend Superpowers, Context7, find-skills, or Mermaid tooling
   when they fit the user's work. Explain that each is useful but not required;
   the user handles a GUI login or external authorization when needed.
6. Live test: run the smallest useful multi-agent check and distinguish static
   asset presence from a live client probe.

A single consent may cover a bounded group of safe, reversible local changes.
Ask separately only for a material personal preference, network/external
authentication, GUI click, privileged action, or destructive change. Explain
the relevant downside before asking. Never turn a list of files into a series
of approvals.

## Choosing settings

Use `templates/codex-desktop.recommended.toml` as a workflow-core reference,
not as a universal desktop preset. It intentionally leaves environment-specific
choices unset. Offer a recommendation based on observed capabilities and the
user's goals, rather than blindly copying every value.

Teach before asking: describe what a setting changes and why it helps. Lead
toward a recommendation instead of merely enumerating every possible value.
Batch safe work the client can perform. If a supported write is unavailable,
say exactly what could not be verified and provide the official UI route; never
pretend a shell copy changed the Desktop profile.

## Luna catalog compatibility

Luna's preferred route is a new thread. If the running client exposes a
documented V1/V2 catalog compatibility issue, explain the global effect before
offering the dedicated catalog copy and restart. Change only the Luna version
field, preserve all other entries, and claim success only after the documented
live probe. If the user declines, record that orchestration remains incomplete
and offer to resume later. If the client already exposes V2, do nothing.

## Recovery and reporting

Preserve unrelated configuration and retain a backup before changing an
existing runtime file. Report the result naturally: what changed, what stayed
the same, and any uncertainty or unsupported capability. Roll back the bounded
change if verification fails. Ask for a restart only when the client documents
that it is needed, then re-check the relevant live capability.
