# AGENT_LAND_MAIN_FAST_FORWARD_PUBLISHED_GUARD_V1 Summary

## What changed

`recover-closeout` publishes the recovery commits to the stranded claim branch before landing.
`land_main.py` then refused to land them ("already published on refs/remotes/origin/agent/...;
refusing to rewrite pushed history") even though the recovery branch already contains
`origin/main`, so landing is a pure fast-forward that rewrites nothing.

- `land_main.py`: new opt-in `--allow-published-ref REMOTE_REF` (repeatable). The listed
  remote-tracking refs are tolerated only by the first guard, which runs before the
  fast-forward decision. The guard on the rebase path is unchanged and still refuses them,
  because a rebase would rewrite the published commits. Default behaviour is unchanged.
- `paired_review_runner.py`: `_default_lander` passes the recovery branch's own
  `refs/remotes/origin/agent/*` upstream (the claim branch) as the allowed ref.

## Tests

Two new `test_land_main.py` cases: an allowed published ref lands as a fast-forward and is
refused without the flag; an allowed ref is still refused when main moved and a rebase is
needed. `test_land_main`, `test_paired_review_findings_closeout` and
`test_paired_review_runner` pass (76 tests).

## Maintenance exception

Started through the operator-authorized isolated `workstream.py start` because the
`agent-workflow` lock is held by the stranded review this change helps recover.

## Follow-ups

- Re-run `recover-closeout --apply --release-claim` on `review-agent-next-execution-boundary-v1`.
- Parallel worktree reminder: switch back to your original branch after this task.
