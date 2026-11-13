---
id: DEBT-0001
title: workstream.py resume refuses a clean checkout that is already attached
status: open
severity: P1
area: lifecycle
first_seen: origin/main 7151839605; workstream operator-3d-workbench-intake-v1; no run ID recorded
reporter: operator-3d-workbench-intake-v1
owner:
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

Make the public resume path return the attached checkout when it is clean and belongs to the same workstream. `workstream.py` already implements that case in `_resume_impl` (around line 3482), but the public command routes through `turn_dispatcher_v2.begin`, which only refuses. Either route `resume` to `_resume_impl` or make `begin` adopt the attached checkout.

## Evidence

- `custodian/tools/agent/turn_dispatcher_v2.py:341-342` raises the refusal.
- `custodian/tools/agent/workstream.py:4401` routes `resume` to `turn_dispatcher_v2.begin`.
- `custodian/tools/agent/workstream.py:3482-3500` already handles an attached, clean checkout.
