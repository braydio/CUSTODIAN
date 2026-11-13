---
id: DEBT-0005
title: Landing script exports GIT_DIR and GIT_INDEX_FILE into the root pull
status: open
severity: P2
area: docs
first_seen: origin/main 7151839605 (script built on it); orchestration session; no run ID recorded
reporter: operator-3d-workbench-intake-v1 (orchestration session, 2026-11-13)
owner:
---

## Symptom

```
error: cannot pull with rebase: You have unstaged changes.
error: additionally, your index contains uncommitted changes.
error: Please commit or stash them.
```

The root pull that follows a successful push fails, even though the root is clean.

## Repro

1. Run a plumbing-based docs landing script that exports `GIT_DIR` and `GIT_INDEX_FILE` and does not unset them.
2. The push to `origin/main` succeeds.
3. The script's final `git -C <root> pull --ff-only origin main` reads the temporary index, not the root index, and fails.

## Workaround used

Confirmed the root was clean with `git status`, then ran `env -u GIT_INDEX_FILE -u GIT_DIR git pull --ff-only origin main`. The root fast-forwarded to `04c58b017`.

## Proposed fix

Scope the variables to the plumbing commands, for example with a subshell, or unset them before any root-facing command. Add a check that fails when the root is dirty before the pull.

## Evidence

- `scratchpad/land_policy_docs.sh`: exports at the top, final `git pull` at the bottom.
- Landed docs commit `04c58b017` on `origin/main`.
- Related: DEBT-0004 (no documented landing path for docs on `main`).
