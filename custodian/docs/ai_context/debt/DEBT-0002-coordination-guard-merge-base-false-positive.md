---
id: DEBT-0002
title: Coordination-root guard blocks read-only git merge-base
status: open
severity: P2
area: guard
first_seen: origin/main 7151839605; workstream operator-3d-workbench-intake-v1; no run ID recorded
reporter: operator-3d-workbench-intake-v1
owner:
---

## Symptom

```
PreToolUse:Bash hook error: [python3 custodian/tools/agent/coordination_root_guard.py --hook]: CUSTODIAN: coordination root is main-only and not an implementation checkout. ...
```

## Repro

1. From the coordination root, run a read-only command that includes `git merge-base --is-ancestor <a> <b>`, for example in a chained command with `git -C <worktree> log`.
2. The Bash guard denies the whole command.

## Workaround used

Moved read-only ancestry checks into the isolated checkout, or used plumbing (`git rev-list`, `git cat-file`) and avoided `merge-base` from the root.

## Proposed fix

`ROOT_MUTATION` in `coordination_root_guard.py` matches `merge` followed by a hyphen, so `merge-base` counts as a mutation. Require a word boundary that excludes `-`, for example `merge(?![\w-])`, and add a regression test with `merge-base`, `merge-tree` and a real `git merge`. The same check should be reviewed for `rebase-*`, `checkout-index` and `switch-*`.

## Evidence

- `custodian/tools/agent/coordination_root_guard.py` (`ROOT_MUTATION`).
