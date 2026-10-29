# Operator Idle Retarget: Exact Historical Source-Scope Attestation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-operator-idle-retarget-source-scope-attestation-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: P0
- Depends on: `none`
- Locks: `paired-review-source-provenance`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-operator-idle-retarget-source-scope-attestation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `An exact historical source authorization gates a preserved independent review; accidental broadening would bypass source ownership validation.`
- Reviewed main: `ea1249ce7059487efe3b61aff0999f18c948ba02`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Visual review: `none`
- Authoring handoff: `auto`
- Goal: Let the preserved independent technical review validate the exact two source files omitted from the original archived Task 015 source declaration, without rewriting the landed implementation or weakening ordinary source-scope checks.
- Completion boundary: Add one immutable, post-hoc attestation for the exact original implementation archive and the two undeclared paths. The exception is usable only after this correction receives its own independently accepted PASS. Preserve the original review claim, branch, worktree, pinned implementation SHA, and evidence.
- Current measured state: Original implementation archive is `eb4de63498ef13eacc86022613bfa35f825d8b7f`. Its archived packet blob is `cddafcc0f62b33fbce66e7f9f7f84eff4189808e`. The pinned tree contains `retarget_calibration.py` at blob `44bb5ccbf0eefc6375b5f39542111262010fb240` and `mixamo_rest_frame_retarget_policy_v2.json` at blob `3d04bd271177e0fa0174f710ad4c01c899c0bbfa`, both mode `100644`. The preserved review is in `host_validation_recovery` before reviewer launch because those exact paths are absent from its target packet source declaration.
- Evidence: `.git/custodian-review-runs/review-operator-3d-neutral-idle-retarget-fix-v1/20261028T184912Z-0d006ce798f1/RECOVERY.md`; immutable source archive and tree entries above; `custodian/tools/agent/paired_review_host_validation.py` and its focused tests; existing accepted-attestation patterns for Grunt and Procession.
- Task-specific authority: This packet; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; existing exact source-scope attestation tests and examples.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, and the exact attestation record at `custodian/docs/ai_context/review_scope_attestations/operator_idle_retarget_v1.json`. No edits to the preserved implementation or review checkout.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`, `custodian/tools/agent/task_packet_contract.py`, `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json`, `custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_NEUTRAL_IDLE_RETARGET_FIX_V1.md`.
- Required correction: Admit exactly the two omitted Task 015 source paths to that preserved review only after validating their pinned archive blobs and this correction's independently accepted review proof.
- Change: Add a canonical JSON attestation binding the original workstream, archived packet path/blob, implementation archive SHA, and exactly the two source paths/blobs/modes above. Extend host validation with one exact identity branch that verifies the attestation against the immutable Git tree and current `origin/main`, verifies ancestry from the preserved reviewed-main, and verifies the correction's own archived paired review is accepted by the canonical outcome and receipt parsers. Only then may the two exact paths count as documented for the preserved source span. Keep all general undeclared-path checks unchanged. Add positive and negative historical Git tests for pre-approval rejection, accepted exact approval, wrong/missing/extra paths, packet/blob/mode mismatch, and non-passing or stale reviewer evidence.
- Preserve: All implementation commits and bytes through `eb4de63498ef13eacc86022613bfa35f825d8b7f`; the original archived packet blob; preserved review claim/run/worktree/evidence; ordinary source-scope rejection behavior; all unrelated source files and claims.
- Non-goals: No retargeting edits, animation rerendering, reviewer verdict fabrication, review claim recreation, broad source-scope exception, dispatcher-policy changes, or production/runtime changes.
- Acceptance: Before this correction's own accepted independent PASS, the exact attestation is inert and the preserved review remains blocked. After PASS, recovery planning for the original run accepts exactly the two pinned paths and rejects altered blobs, modes, packet identity, extra paths, missing approval, invalid receipt, or non-ancestor approval. The original review's `reviewed_main` and implementation identity remain unchanged.
- Validation: Add real temporary-Git history tests in `custodian/tools/agent/test_paired_review_runner.py`; run the focused new tests and `python3 -m unittest custodian.tools.agent.test_paired_review_runner`; run changed-file validation for `paired_review_runner_unit`, `git diff --check`, packet authoring/index validation, and the exact original review recovery plan after accepted correction review. Do not run or alter the preserved reviewer checkout before the correction review passes.
- Task overrides: `TASK OVERRIDE: This user-authorized exact post-hoc source-scope correction may add a single source-span attestation exception bound to the two listed blobs and the original Task 015 archive; it does not authorize changing general source-scope rules or the preserved implementation/review history.`
- Deferred: Resume the existing preserved technical review only after this correction's accepted independent PASS; then proceed to the separate animation-refinement task only after the original review releases its lock.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `no`
- Completion boundary satisfied: `no`
- Acceptance satisfied: `no`
- Evidence: `pending`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: The original source declaration omitted two files from the archived implementation source span; the preserved review is pinned to that immutable archive.
- Root cause / contributing factors: The archive packet's source declaration did not enumerate the exact new calibration module and policy JSON.
- Prevention / pipeline improvement: Bind any post-hoc admission to exact source blobs and an independently accepted correction review; preserve ordinary path checks.
- Tooling / docs drift discovered: Existing attestation support covers specific historical cases but has no exact record for this source-span omission.
- Follow-up: `review-operator-3d-neutral-idle-retarget-fix-v1`
- What worked: The host validation failed closed before reviewer launch and preserved the original claim/evidence.

## Handoff
- Next action: Implement only this exact attestation correction; after its paired PASS, plan/apply the preserved review's host-validation recovery.
- Blockers or open questions: none

## Next Handoff
- Next workstream: `review-agent-operator-idle-retarget-source-scope-attestation-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Refresh reason: none
- Next action: Complete the exact source-scope correction and its independent review, then resume the preserved Task 015 technical review.
- Blockers or open questions: none
