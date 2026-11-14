---
id: DEBT-0007
title: Coordination-root guard judges Git commands by the shell's persisted cwd, not the command's target worktree
status: open
severity: P2
area: guard
first_seen: origin/main 1dc8db2be; workstream agent-ops-readonly-observer-pilot-20261114; no run ID recorded
reporter: agent-ops-readonly-observer-pilot-20261114
owner:
---

## Symptom

```
PreToolUse:Bash hook error: [python3 "$CLAUDE_PROJECT_DIR/custodian/tools/agent/coordination_root_guard.py" --hook]: CUSTODIAN: coordination root is main-only and not an implementation checkout. Use dispatch.py claim/start and run Git mutation inside the returned temporary worktree. No branch switch or commit here.
```

A Git commit that targets a task worktree is refused when the Bash shell's persisted working directory is the coordination root. The same commit, written as `git -C <worktree> commit`, is allowed.

## Repro

1. Leave the Bash shell's working directory at `~/Projects/CUSTODIAN` (the coordination root).
2. Run `(cd ~/Projects/.custodian-worktrees/<task> && git add <file> && git commit -m "...")`. The guard refuses it, because it checks the persisted root, not the subshell's directory.
3. Run `git -C ~/Projects/.custodian-worktrees/<task> commit -m "..."`. The guard allows it.

## Workaround used

Used `git -C <worktree>` for every Git mutation made on a task branch. Read-only commands from the root were not blocked.

## Proposed fix

The guard should decide from the command's effective target directory: the `-C` argument, or a `cd` inside the same command, or the Git common directory of the target path. A mutation is blocked only when that target resolves to the coordination root. Add regression tests for `git -C <worktree> commit`, a subshell `cd <worktree> && git commit`, and a direct mutation at the root. Related: DEBT-0002 (guard false positive on `merge-base`) concerns the same guard.

## Evidence

- `custodian/tools/agent/coordination_root_guard.py`, hook message above.
- `.claude/settings.json`, `PreToolUse` hook, `--hook` mode.
- Reproduced 2026-11-14 in the `agent-ops-readonly-observer-pilot-20261114` session.
