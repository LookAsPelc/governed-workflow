# Durable task state

Iron Box keeps long-running task memory in small, inspectable records—not in a
root conversation. This is a protocol for a project-local `.iron-box/`
directory, not a second runtime. The directory is ignored by default. Copy
[`templates/iron-box-state/task.json`](../templates/iron-box-state/task.json)
and [`templates/iron-box-state/state.json`](../templates/iron-box-state/state.json)
when a task needs durable state; do not create it for a tiny, low-risk edit.

```text
.iron-box/
  task.json       # protected user intent; edit only after an explicit user decision
  state.json      # mutable canonical records, TODO, and evidence references
  evidence/       # optional small captured outputs or links to reproducible commands
```

## Protected intent: `task.json`

```json
{
  "schema_version": 1,
  "task_id": "2026-08-16-routing-example",
  "created_at": "2026-08-16T10:00:00Z",
  "original_goal": "Add the requested feature without changing the public API.",
  "protected_constraints": [
    {"id": "C-1", "text": "Do not change the public API.", "source": "user"}
  ],
  "acceptance_criteria": [
    {"id": "AC-1", "text": "The focused test passes.", "status": "pending"}
  ]
}
```

`original_goal`, `protected_constraints`, and acceptance-criterion text are
user-owned. A worker, verifier, or Sol advisor cannot rewrite them. Add a new
revision only after an explicit user decision and retain the replaced text plus
its reason in `state.json`.

## Mutable canonical state: `state.json`

```json
{
  "schema_version": 1,
  "task_id": "2026-08-16-routing-example",
  "updated_at": "2026-08-16T10:20:00Z",
  "records": [{"id": "R-1", "kind": "requirement", "summary": "Focused test passes.", "status": "verified", "supports": ["AC-1"], "evidence_ids": ["E-1"], "artifact_fingerprints": ["F-1"], "supersedes": [], "notes": "Verified independently; executor report was not accepted as evidence."}],
  "evidence": [{"id": "E-1", "kind": "command", "observer": "luna_verifier", "command": "pytest tests/test_feature.py -q", "result": "exit 0; 3 passed", "captured_at": "2026-08-16T10:19:00Z", "location": "evidence/E-1.txt"}],
  "fingerprints": [{"id": "F-1", "path": "src/feature.py", "sha256": "<sha256 at verification>", "observed_at": "2026-08-16T10:19:00Z"}],
  "claims": [{"id": "CL-1", "worker": "luna_worker", "summary": "Implemented feature and tests pass.", "status": "verified-by-E-1"}],
  "next_actions": [{"id": "TODO-1", "text": "Run integration check.", "status": "pending", "depends_on": ["R-1"]}],
  "blocked": [],
  "decisions": [{"id": "D-1", "decision": "Keep public API unchanged.", "source": "C-1", "status": "settled"}]
}
```

Use stable IDs and one small record per fact, requirement, artifact, decision,
claim, or action. Allowed record/action statuses are `pending`, `verified`,
`blocked`, `suspect`, `superseded`, and `rejected`. A claim is never a verified
fact merely because it is written here.

## Checkpoint protocol

1. Terra creates `task.json` from the user's goal and constraints, then creates pending records in `state.json`.
2. A bounded worker reports a claim. Record it under `claims` as `unverified` or `suspect`; do not advance a requirement record.
3. A fresh verifier inspects artifacts and runs reproducible checks. Save concise output or a reproducible reference under `evidence`; link it to each supported record.
4. Terra changes only supported records to `verified`, records remaining gaps, and fingerprints artifacts when later edits could invalidate the proof.
5. If an artifact fingerprint changes, mark affected evidence/records `suspect` until rechecked. Preserve superseded and rejected claims instead of silently overwriting history.

Before interrupting, respawning, or fanning out, inspect `state.json`, active
worker status, and the latest evidence. Keep an in-scope worker progressing;
interrupt only for requirement change, scope/safety violation, bounded retry
failure or block, or stale/contradictory evidence. Never replace an active
worker with a duplicate. Fan out only disjoint work with independent
acceptance/evidence and a justified cost/time benefit. Record a concise rationale
in `state.json` when this protocol applies, reuse stable context, and make
retries causally distinct.

Before canonical completion, record a fresh read-only independent completion
review. Its packet includes goal/protected constraints, all criteria, declared
scope, actual diff/artifacts, exact commands/results, deviations/workarounds,
and capability claims. The reviewer checks criterion coverage, out-of-scope
files or side effects, unapproved improvisation, and unsupported/unobserved
claims. PASS requires all four checks plus evidence; deterministic evidence is
decisive input but never a bypass, including for trivial work.

Evidence should be compact: command/output excerpts, test identifiers, file
paths and hashes, commit IDs, or external observation IDs. Do not paste raw
chat transcripts or private worker reasoning into canonical state.

## Fresh-root resume

A new Terra manager starts from the two JSON files, not the old chat:

1. Read `task.json` to recover the goal, protected constraints, and acceptance criteria.
2. Read `state.json` to separate verified, pending, blocked, suspect, and superseded records.
3. Locate evidence and compare stored fingerprints before relying on a verified result.
4. Read settled decisions, choose the next pending action, construct a bounded context packet, and route it to Luna or Sol proportionally.

If evidence is missing, contradictory, or stale, the fresh manager records the
limitation and re-verifies rather than reconstructing certainty from prose.

## Deliberate limits

This protocol has no daemon, database, generic event log, background watcher,
or custom executor. Git history, file hashes, normal tests, and native Codex
subagents remain the mechanisms of execution and observation.
