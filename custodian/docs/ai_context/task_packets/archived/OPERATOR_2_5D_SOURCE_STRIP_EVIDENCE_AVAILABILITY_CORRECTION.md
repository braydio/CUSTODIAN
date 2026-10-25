# OPERATOR 2.5D SOURCE-STRIP EVIDENCE AVAILABILITY CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-source-strip-evidence-availability-correction-v1`
- Authoring handoff: auto
- Status: `complete`
- Dispatch: `auto`
- Priority: P1
- Depends on: operator-2-5d-cohort-dependency-closure-review-corrections-1
- Locks: none
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: review-operator-2-5d-source-strip-evidence-availability-correction-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial validation-contract correction; paired review must prove missing evidence cannot be mistaken for verified evidence.
- Reviewed main: `482cd88edc5490c83f34f1793dea39ccfb0f3977`
- Authoring chat: not-recorded
- Visual review: none
- Goal: Make the 2.5D closure diagnostic accurately distinguish verified, mismatched, and unavailable historical source-strip evidence.
- Completion boundary: Correct the source-strip evidence projection and focused smoke only. Missing physical historical strips are reported as unavailable and do not fail the diagnostic; present incorrect bytes still fail; unavailable evidence never counts as verified or release-eligible.
- Current measured state: On `origin/main@482cd88edc5490c83f34f1793dea39ccfb0f3977`, the report producer emits `UNAVAILABLE` when a referenced source strip is missing, but the smoke unconditionally requires all eight strips to match and fails at line 42 when those files are absent.
- Evidence: `custodian/tools/validation/operator_2_5d_cohort_dependency_closure.py::_workspace_evidence`; `custodian/tools/validation/operator_2_5d_cohort_dependency_closure_smoke.py`; validation id `operator_2_5d_cohort_dependency_closure` in `custodian/tools/validation/validation_manifest.json`.
- Task-specific authority: Archived `operator-2-5d-cohort-dependency-closure-review-corrections-1` packet and its paired review; current producer/report schema and its registered smoke.
- Work surface: `custodian/tools/validation/operator_2_5d_cohort_dependency_closure.py`, `custodian/tools/validation/operator_2_5d_cohort_dependency_closure_smoke.py`.
- Publication inputs: `custodian/tools/validation/operator_2_5d_cohort_dependency_closure.py`, `custodian/tools/validation/operator_2_5d_cohort_dependency_closure_smoke.py`, `custodian/tools/validation/validation_manifest.json`.
- Change: Preserve explicit `PRESENT`, `UNAVAILABLE`, and `UNRECORDED` source states. A present source strip with the recorded hash is verified; a present source with a mismatched hash is a smoke failure; unavailable/unrecorded files remain unverified and are reported as such. Add deterministic positive and negative controls for those cases.
- Preserve: Seven candidate families, 56 direction slots, zero verified/reviewed/published directions, null timing approval, all conservative edge classifications, and overall `NOT_RELEASE_ELIGIBLE`. Do not change source art, runtime assets, review receipts, or production policy.
- Non-goals: Recover or regenerate missing 128px source strips; alter Operator animation behavior; promote any 2.5D cohort; modify F3 or Alpine worktrees; weaken unrelated validation.
- Acceptance: The focused smoke passes with the configured workspace present and its historical strips unavailable; exact/matching bytes are distinguished from tampered bytes; unavailable evidence is visibly `UNAVAILABLE`, never counted as verified, and cannot change `NOT_RELEASE_ELIGIBLE`; the seven-family/56-slot and timing invariants remain intact.
- Validation: Run the focused smoke directly and through `run_validation.py --test operator_2_5d_cohort_dependency_closure --json`; verify deterministic output and report invariants; run targeted packet/context/changed-file checks for owned paths and `git diff --check`.
- Task overrides: none
- Deferred: Physical recovery of historical source strips and any 2.5D cohort planning remain outside this correction.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Evidence: The producer now reports source-strip evidence as `VERIFIED`, `HASH_MISMATCH`, `UNAVAILABLE`, or `UNRECORDED`, with hash-match status remaining false unless the file bytes match the recorded correction hash. The live configured authoring workspace is readable and reports eight unavailable historical strips, zero verified strips, zero effective review receipts, seven candidate families / 56 directions, no timing authority, and `NOT_RELEASE_ELIGIBLE`. The focused smoke passes and exercises matching, tampered, missing, and unrecorded inputs.
- Validation: Direct `operator_2_5d_cohort_dependency_closure_smoke.py` passed; `run_validation.py --test operator_2_5d_cohort_dependency_closure --json` passed 1/1; canonical `run_validation.py --changed --base origin/main --json` passed 1/1 with complete ownership coverage (2/2 changed files, zero uncovered, skipped, or failed tests); Python compilation and `git diff --check` passed.
- Protected surfaces: No source strips were restored or generated. Runtime assets, timing authority, review receipts, candidate scope, release policy, and F3/Alpine worktrees were unchanged.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The prior smoke treated missing physical source files as hash failures despite the producer explicitly reporting them unavailable.
- Root cause / contributing factors: Smoke asserted every historical source-strip hash matched without branching on the producer's availability state.
- Prevention / pipeline improvement: The report now exposes a four-state source evidence classification; regression controls distinguish matching bytes, tampering, unavailable files, and unrecorded paths.
- Tooling / docs drift discovered: none
- Follow-up: review-operator-2-5d-source-strip-evidence-availability-correction-v1
- What worked: Canonical changed-file validation selected only the registered closure smoke and covered both changed paths completely.

## Independent Review

- Status: pending
- Review workstream: `review-operator-2-5d-source-strip-evidence-availability-correction-v1`
- Review packet: `custodian/docs/ai_context/task_packets/REVIEW_OPERATOR_2_5D_SOURCE_STRIP_EVIDENCE_AVAILABILITY_CORRECTION.md`

## Next Handoff

- Next workstream: review-operator-2-5d-source-strip-evidence-availability-correction-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the fresh-context paired review after this implementation is archived complete.
- Blockers or open questions: none
