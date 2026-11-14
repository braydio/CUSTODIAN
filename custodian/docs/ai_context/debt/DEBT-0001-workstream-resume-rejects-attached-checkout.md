---
id: DEBT-0001
title: workstream.py resume refuses a clean checkout that is already attached
status: triaged
severity: P1
area: lifecycle
first_seen: origin/main 7151839605; workstream operator-3d-workbench-intake-v1; no run ID recorded
reporter: operator-3d-workbench-intake-v1
owner: central-tooling-orchestration
---

## Symptom

```
turn_dispatcher_v2.DispatchError: canonical branch agent/operator-3d-workbench-intake-v1 is already attached; preserving existing checkout
```

## Repro

1. A workstream has a clean turn checkout attached to its canonical branch, e.g. `/home/braydenchaffee/Projects/.custodian-turns/turn-operator-3d-workbench-intake-v1-e3cddd4e1b96`.
2. Run `python3 custodian/tools/agent/workstream.py resume <workstream-id>`.
3. The command fails instead of returning the attached checkout.

## Workaround used

Confirmed the attached checkout was clean, on the canonical branch, and in sync with its upstream, then worked directly in it. No second checkout was created.

## Proposed fix

**Orchestration triage (2026-11-13):** Implement a distinct V2 resume operation and route only the public `workstream.py resume` CLI to it. Do not route V2 resume through legacy `_resume_impl` (which uses a different trace/mutex lifecycle), and do not make fresh `begin` silently adopt an attached checkout.

For an already attached checkout, require exactly one matching canonical branch in the managed turn pool, the same Git common directory, a non-coordination path, a clean tracked/untracked state, and exactly one matching V2 acquisition receipt. Verify the checkout HEAD descends from the original acquisition source, matches the authenticated remote branch head, and that the receipt is not retired. Preserve the original turn ID, run ID, acquisition identity and checkout. Fail closed on missing/ambiguous provenance, foreign paths, competing writers, dirty or diverged state, or remote/source mismatch. Do not reset, create another worktree, or manufacture a new acquisition.

Add focused positive/negative tests for attached-clean resume, CLI routing, unchanged acquisition identity, repeated resume, checkpoint compatibility, missing/duplicate receipts, wrong branch/common directory/pool, dirty/untracked data, remote drift and source mismatch. Host-side writer/process ownership must be checked before declaring the original Operator checkout safe to resume. The separate root-guard false positive remains DEBT-0002. No implementation checkout is claimed by this triage.

## Evidence

- `custodian/tools/agent/turn_dispatcher_v2.py:341-342` raises the refusal.
- `custodian/tools/agent/workstream.py:4401` routes `resume` to `turn_dispatcher_v2.begin`.
- `custodian/tools/agent/workstream.py:3482-3500` already handles an attached, clean checkout in the *legacy* lifecycle.
- `custodian/tools/agent/turn_dispatcher_v2.py`: `read_acquisition()` and `checkpoint()` enforce V2 provenance and same-checkout retirement.
