# Pre-Validation Checkout Recovery — Execution Summary

## Outcome

Implementation and focused failure-class fixes are validated locally. The original protected host-import review remains untouched. The feature is not landed or independently reviewed yet.

## Work completed

- Added guarded same-claim reconstruction for a missing checkout after a verified pre-validation interruption. Planning verifies the original claim and trace, branch refs, worktree attachment, run state, process ownership, and explicit attestations. Apply journals before reconstruction, restores only the recorded path and branch at the pinned SHA, then runs canonical host validation before a reviewer can launch.
- Kept normal claim parsing strict and kept the missing-checkout path separate from the Carrow and failed-import recovery classes.
- Added real temporary-Git fixtures for read-only plans, exact reconstruction, hostile states, stale digests, attestation pairing, and replay prevention.
- Corrected the Procession tests' historical fixture assumptions. The scope-approval fixture now starts at the verified pre-archive commit `49a93aa726e26bd40220d3bdb658079ea9da3440`; source-span coverage now asserts the current validator's exact rejection of the unverified merge. The validator itself remains fail-closed.
- Isolated positive owner-check fixtures from the host `/proc` table while retaining the explicit active-owner rejection case.
- Documented the missing-checkout recovery class in `AGENT_WORKSTREAM_LIFECYCLE.md`.

## Validation

Passed:

- 5 missing pre-validation checkout tests.
- 6 Carrow missing-worktree regression tests.
- All 3 previously failing Procession tests.
- Full paired-review runner suite: 179 tests.
- AI-context check, task-packet index, review-pairing validation, Python compilation, and `git diff --check`.

The first focused run exposed that a positive process-ownership fixture consulted live `/proc` and failed on an unrelated inaccessible process. The fixture now supplies an empty isolated owner set; the hostile active-owner test still verifies fail-closed behavior.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the preserved branch was six commits behind current main; its runner suite contained three stale Procession history assumptions.
- Root cause / contributing factors: the active claimed worktree predates the verified fixture repair and current main updates.
- Prevention / pipeline improvement: make historical Git fixtures pin their intended starting commit and assert that required pre-state before mutation.
- Tooling / docs drift discovered: test fixtures that derive historical states from live main can silently become invalid when the target transition has already landed.
- Follow-up: fixed-in-scope
- What worked: the preserved recovery code passed focused real-Git hostile fixtures; full suite passed after the fixture assumptions were corrected.

## Next Handoff

- Next workstream: `review-agent-paired-review-prevalidation-checkout-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: synchronize the preserved branch through the normal workstream lifecycle, fix the read-only plan defect in the shared coordinator, rerun validation, and land for independent review.
- Blockers or open questions: `the branch is still based on edaae65a; live origin/main is a6b419e23758ba789f1c197a5c76045515b122f5. The protected review remains untouched pending accepted implementation review.`
