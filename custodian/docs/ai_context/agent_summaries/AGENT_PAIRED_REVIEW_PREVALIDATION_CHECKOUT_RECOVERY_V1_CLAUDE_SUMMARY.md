# Pre-validation Checkout Recovery — Execution Summary

## Outcome

The implementation and failure-class corrections are validated on the preserved primary workstream. They are not landed or independently reviewed yet. The protected host-import and Procession review runs have not been mutated.

## Work completed

- Added guarded same-claim reconstruction for a missing checkout after a verified pre-validation interruption. Planning verifies original claim and trace, branch refs, checkout attachment, run state, process ownership, and required attestations. Apply journals before reconstruction, restores only the recorded path and branch at the pinned SHA, then runs canonical host validation before reviewer launch.
- Kept ordinary claim parsing strict and separated this route from Carrow and failed-import recovery.
- Fixed the Procession historical test fixtures using verified pre-archive commit `49a93aa726e26bd40220d3bdb658079ea9da3440`; retained fail-closed validator behavior and isolated positive owner tests from unrelated host `/proc` entries.
- Fixed the Procession PASS planner so `--plan` authenticates authoritative remote refs without fetches or Git metadata writes. It fails closed when the cached commit is stale or unavailable.
- Added a same-claim continuation for the exact Procession `codex_exited` run. It authenticates immutable claim/session/report evidence, requires no active checkout owner, preserves the inconsistent target receipt byte-for-byte, restores the pinned target baseline, and permits only a fresh reviewer-authored findings outcome and bounded nonpassing closeout. This path has not been applied to the protected run; independent review must accept the implementation first.
- Updated the existing implementation and paired-review packets to cover the exact findings transition. Corrected the packet's validation-manifest path to `custodian/tools/validation/validation_manifest.json`.

## Validation

Passed:

- Paired-review runner suite: 185 tests.
- Canonical `paired_review_runner_unit` validation: passed.
- Changed-file validation against `origin/main`: 5 selected checks passed with complete code coverage.
- AI-context check, packet index, review-pairing check, packet-authoring preflight, Python compilation, and `git diff --check`.

The earlier three Procession failures were fixture defects: tests constructed an already-archived state from current main. They now pin the verified earlier baseline and keep the validator's rejection intact.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the preserved implementation branch was behind current main and its suite had three stale Procession history assumptions; the Procession review then exposed a real read-only planning defect and lacked a canonical findings disposition.
- Root cause / contributing factors: historical fixtures followed live main instead of pinning their intended state; planner code used mutating fetches; coordinator continuation accepted neither the authentic exited findings state nor its missing canonical disposition.
- Prevention / pipeline improvement: pin historical fixture commits, keep plan paths read-only, and route exited reviews through a bounded same-claim continuation that leaves verdict authorship to a fresh reviewer.
- Tooling / docs drift discovered: the recovery packet referenced the validation manifest under `tools/agent/`; the tracked manifest is under `tools/validation/`.
- Follow-up: fixed-in-scope
- What worked: the existing primary worktree was preserved, synced through its supported lifecycle, and both historical and hostile runner tests pass.

## Next Handoff

- Next workstream: `review-agent-paired-review-prevalidation-checkout-recovery-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: finish and land this implementation, then run its fresh-context paired review. Apply the Procession continuation only after the implementation review is accepted.
- Blockers or open questions: the implementation review and protected original continuations remain pending.
