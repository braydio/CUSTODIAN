# AGENT_PAIRED_REVIEW_CLOSEOUT_TRUNCATED_CLAIM_V1 Summary

## What changed

`recover-closeout` (paired_review_runner.py) could not recover a stranded review whose run
directory stored `claim.stdout` truncated at 1200 bytes: the JSON claim receipt was cut off
mid-string and `parse_claim_receipt` failed closed.

`_claim_identity` now tries the structured receipt first. Only when parsing fails with the
"malformed" or "exactly one structured claim receipt" errors does it fall back to the plain
`CLAIMED` header lines, and only if all four fields (workstream, branch, worktree, packet)
equal `metadata.json` exactly and Git verifies the worktree, branch, common dir and packet
path. A receipt that parses but does not verify never falls back.

## Tests

Three new tests in `test_paired_review_findings_closeout.py`: truncated receipt recovers via
the verified header; any disagreement still fails closed; a parseable-but-unverified receipt
never falls back to the header. 50 closeout/outcome tests pass.

## Maintenance exception

Started via an operator-authorized isolated `workstream.py start` because the `agent-workflow`
lock is held by the stranded review this change exists to recover. The stranded claim,
worktree and `.uid` sidecars were not touched.

## Follow-ups

- Run `recover-closeout --plan/--apply` on `review-agent-next-execution-boundary-v1`
  (run `20261011T233501Z-61ac2d68e601`) as `findings`, retaining R0-01.
- Formal paired review of this and the prior closeout change once the lock is free.
- Parallel worktree reminder: switch back to your original branch after this task.
