---
id: DEBT-0003
title: Dispatch status shows CLAIMED without an owner
status: open
severity: P2
area: dispatch
first_seen: origin/main 7151839605; workstream operator-3d-workbench-intake-v1; no run ID recorded
reporter: operator-3d-workbench-intake-v1
owner:
---

## Symptom

`dispatch.py status` lists `operator-3d-workbench-intake-v1` under CLAIMED with no agent, run ID or checkout. `dispatch.py last-claim --json` returned a different workstream (`owner-review-exception-lane-v1`), so it cannot identify the owner of the current claim.

## Repro

1. With a workstream claimed, run `python3 custodian/tools/agent/dispatch.py status`.
2. Run `python3 custodian/tools/agent/dispatch.py last-claim --json`.
3. Neither output identifies the claiming agent or the active checkout for the claimed workstream.

## Workaround used

Found the owner indirectly: `dispatch.py audit --json` reported `attached_worktree` and `dirty` fields for the workstream, and the checkout directory name carries a turn ID.

## Proposed fix

Add `--workstream <id>` to `last-claim`, or add agent, run ID and attached checkout to the CLAIMED rows of `status`.

## Evidence

- `dispatch.py status` output, CLAIMED section.
- `dispatch.py audit --json`, `attached_worktree` for `operator-3d-workbench-intake-v1`.
