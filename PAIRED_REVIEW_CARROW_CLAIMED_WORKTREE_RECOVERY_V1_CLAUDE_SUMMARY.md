# Carrow Claimed Review Worktree Recovery V1

Workstream: `paired-review-carrow-claimed-worktree-recovery-v1`

## Result

Implemented an exact, one-run host-validation recovery path for Carrow’s original review claim. It authenticates the existing claim receipt, pinned implementation and reviewed-main SHAs, seven-file original run manifest, failed report hashes, local and remote branch heads, missing destination, and absence of another worktree using the same claim branch. Recovery requires paired operator attestations, writes a continuation journal before reconstructing the checkout, and permits one fresh full validation attempt. A failed or partial attempt remains preserved and cannot be replayed. Reviewer launch remains downstream of a fresh green validation.

The host-validation tool now verifies the original report’s rename-aware direct-commit source span against the pinned implementation commit. The historical report remains byte-identical; its original failure is not reclassified as success.

## Carrow Evidence

- Original review: `review-carrow-interior-layout-authoring-v1`
- Original run: `20261018T072047Z-83514d0c54fd`
- Original branch head and reviewed main: `099c44353dfd258c233016b88cc50ba2dd502ef1`
- Reviewed implementation: `9b15c2c4aa3f5c56584cd45ac96913ea1c81d9c6`
- Original report hashes: `validation.json` `7df3a536f45999d1f5a53d258d4bd61d9fd1a547f9408b5c85cac84b8ce0f6f6`; `coordinator-validation.json` `5b870281fc110dc5654ee6c2ad804cdac9895fd0a925ab733c492c9c09c17517`.
- Full original run manifest is pinned in the recovery code and matched during the read-only plan. No original report, metadata, receipt, claim ref, or review worktree was changed.
- Historical `world_transition_handoff` failure was reproduced 13/13 times after full LFS hydration and editor import. In each reproduction, the successful result position, observed position, and exact `Spawn_SouthReach` position matched at `(-6.0, 162.0)`, with zero delta. No runtime/test source defect was established, so the assertion was left unchanged.
- Live read-only recovery plan against coordinator `main@195ae53e9d21e6affac5da4fcbd563f6c17f882d` produced SHA `51341b4fc532ee6596b39ce080aac9ed1471b5eccec3f7dab12bf198b27896ad`. No `--apply` was run.
- The missing checkout’s deleted ignored/untracked inventory cannot be recovered from Git. Applying the reviewed path remains gated on an explicit operator attestation that no active owner remains and no unique evidence was lost. The attestation request is still pending.

## Validation

- `paired_review_runner_unit`: 161 tests passed.
- Changed-file validation from claimed base `339ebc6d2c391b2391e65d1ed01192a183043149`: `agent_workflow_contract` and `paired_review_runner_unit` passed with complete coverage.
- Related `test_workstream`, `test_review_outcome`, and `test_dispatch`: 160 tests passed.
- `check_ai_context.py --json`: passed with zero findings.
- `task_packet_index.py`: passed.
- `validate_review_pairing.py`: passed, 127 auto review pairs.
- `git diff --check`: passed.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The existing planner rejected this non-import failed run when its recorded checkout was missing; current source-span resolution also differed from the immutable historical record.
- Root cause / contributing factors: Recovery only handled a pre-validation interruption and a narrow import failure; the original report recorded a rename-aware commit diff.
- Prevention / pipeline improvement: Added one exact, report-hash-pinned route with a pre-mutation journal and a verifier for the historical direct-commit span. Other reviews cannot use this route.
- Tooling / docs drift discovered: A missing-worktree continuation must retain authenticated historical source-span provenance when current archive-follow-up logic cannot reconstruct it.
- Follow-up: review-paired-review-carrow-claimed-worktree-recovery-v1
- What worked: The preserved report and its complete run manifest made it possible to build a fail-closed exact-run path without changing historical evidence.

## Next Handoff

- Next workstream: `review-paired-review-carrow-claimed-worktree-recovery-v1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Complete the fresh-context paired review. After acceptance and the two explicit operator attestations, apply the recovery plan to the original Carrow claim, run its full host validation, and resume the original independent Carrow review.
- Blockers or open questions: Operator attestation on cross-host ownership and absence of unique lost worktree evidence remains pending.
