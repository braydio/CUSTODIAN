# Paired-review runner validation time budget

- Packet schema: `custodian.task_packet.v2`
- Authoring handoff: auto
- Workstream: validation-paired-review-runner-time-budget-v1
- Category: agent-ops
- Status: `ready`
- Dispatch: `auto`
- Priority: P0
- Depends on: none
- Locks: validation-paired-review-runner-time-budget
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: review-validation-paired-review-runner-time-budget-v1
- Review cycle: 0
- Max automatic review cycles: 0
- Review rationale: The canonical paired-review runner suite has a demonstrated runtime of 317.595 seconds but the shared validation manifest terminates it at 300 seconds, preventing a genuine canonical green report for the P0 consumer-enforcement implementation and subsequent independent review. A bounded timeout correction needs independent verification.
- Reviewed main: c3d1d7ca8376bfb998ec1905ffbf9f3f06de10b1
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Goal: Increase only the canonical timeout for `paired_review_runner_unit` from 300 to 480 seconds so its unchanged test command can complete and report genuine results.
- Completion boundary: Change the single `timeout_sec` value for `paired_review_runner_unit`, prove the JSON semantic delta is exactly 300 to 480 and every other manifest value is unchanged, run canonical changed-file validation with complete coverage and all selected checks green, and produce truthful closeout artifacts for canonical finish. Landing and teardown occur through the canonical lifecycle; fresh independent post-land review is a separate acceptance gate.
- Current measured state: On main `c3d1d7ca8376bfb998ec1905ffbf9f3f06de10b1`, `paired_review_runner_unit` has `timeout_sec: 300`. A real canonical committed-source run selected four checks: three passed; this suite timed out at exactly 300 seconds. An earlier complete direct execution of the same 278-test suite passed in 317.595 seconds.
- Evidence: Immutable timed-out report under private Git metadata for P0 run `20261101T114054Z-7eca064a3027`; canonical manifest entry `paired_review_runner_unit`; implementation summary/trace for P0 commit `9902044c96780e349782d491d4ed5fd608b23ff9`; live test script `custodian/tools/agent/test_paired_review_runner.py`.
- Task-specific authority: `custodian/tools/validation/validation_manifest.json`; `custodian/tools/validation/run_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: Only the `timeout_sec` value on the `paired_review_runner_unit` object in `custodian/tools/validation/validation_manifest.json`.
- Publication inputs: `custodian/tools/validation/validation_manifest.json`; `custodian/tools/validation/run_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Change:
  1. Change only that test's `timeout_sec` from 300 to 480.
  2. Preserve every other manifest value and validation behavior byte-for-byte semantically.
  3. Preserve the original timed-out report immutably and write each new report separately under private Git metadata.
- Preserve: Test command, assertions, selection, ownership, coverage and result evaluation; the existing P0 implementation claim, branch, packet, checkpoint, reports and trace; Operator host-validation recovery; Ritualant and all unrelated protected evidence.
- Non-goals: Do not modify tests or harness code, extend any other timeout, skip/disable the suite, rewrite the P0 implementation history, create a validation exception, or change any reviewer outcome.
- Acceptance:
  - Before/after JSON comparison proves the sole semantic change is `paired_review_runner_unit.timeout_sec: 300 -> 480`.
  - Canonical changed-file validation runs from the committed manifest correction, completes the paired-review suite genuinely, and has complete coverage with zero failures, timeouts, skips or infrastructure errors.
  - Report records actual runtime, result count, selected-test inventory, exact commit/tree/status identity and SHA-256.
  - Canonical `workstream.py finish` lands and safely tears down the correction workstream; if main synchronization changes the tree, its exact after-sync validation also passes.
  - A fresh independent paired review records its authentic outcome; this implementation is not described as accepted before that review.
- Validation:
  - Compare the full JSON manifest before and after, normalizing only the target timeout field.
  - `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`
  - `python3 custodian/tools/agent/check_ai_context.py --json`
  - `python3 custodian/tools/agent/validate_review_pairing.py`
  - `python3 custodian/tools/agent/task_packet_index.py`
  - `git diff --check`
  - Preserve report SHA-256 and verify source identity and full selected-test coverage.
- Task overrides: none
- Deferred: P0 consumer-enforcement finish is paused until this correction is landed and independently accepted; then resume its original claim and generate a new committed-source report using the corrected budget.

## Handoff

- Next workstream: `agent-paired-review-after-sync-consumer-enforcement-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Summary backlink: include the exact Authoring chat URL above in the durable summary and final Next Handoff
- Refresh reason: `none`
- Next action: After canonical correction finish and independent review, resume the existing P0 claim and rerun committed-source validation with the 480-second limit.
- Blockers or open questions: `none`
