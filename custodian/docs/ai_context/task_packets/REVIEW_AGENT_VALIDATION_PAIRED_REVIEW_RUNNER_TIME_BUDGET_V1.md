# REVIEW: Paired-review runner validation time budget

- Packet schema: `custodian.task_packet.v2`
- Authoring handoff: auto
- Workstream: review-validation-paired-review-runner-time-budget-v1
- Category: agent-ops
- Kind: review
- Status: draft
- Dispatch: manual
- Priority: P0
- Depends on: validation-paired-review-runner-time-budget-v1
- Locks: validation-paired-review-runner-time-budget
- Review: none
- Review target workstream: validation-paired-review-runner-time-budget-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_VALIDATION_PAIRED_REVIEW_RUNNER_TIME_BUDGET_V1.md
- Reviewed main: c3d1d7ca8376bfb998ec1905ffbf9f3f06de10b1
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, workflow
- Review cycle: 0
- Max automatic review cycles: 0
- Review rationale: The shared timeout controls whether canonical validation can complete and provide acceptance evidence for the paired-review host validator. Independently verify the single-value scope and genuine completion of the unchanged suite.
- Goal: Independently determine whether the landed timeout correction changes only the target budget and enables the unchanged canonical test suite to complete without weakening validation.
- Reviewed implementation acceptance: Verify the archived implementation packet's sole-value JSON delta, unchanged manifest semantics outside that value, complete changed-file coverage, zero failures/timeouts/skips/infra errors, exact report source identity and canonical finish evidence.
- Review evidence: Reconstruct from the archived implementation packet, exact Git diff, before/after manifest JSON, canonical report, selected-test inventory, test output and workstream trace. Treat the implementation summary as a claim, not proof.
- Correction threshold: Create correction work only for a confirmed scope violation, altered validation semantics, incomplete coverage or non-genuine result that prevents acceptance. Escalate material evidence ambiguity; do not patch implementation code.
- Focused validation: Independently compare all manifest values except the target timeout; inspect and rerun `paired_review_runner_unit` through canonical changed-file validation; verify source commit/tree/status, full coverage and report digest.
- Review focus: Ensure the timeout adjustment is exactly 300 to 480 seconds, no test or selection changes are hidden, the suite genuinely runs to completion, and canonical finish/after-sync evidence is authentic.
- Acceptance: Record a findings-first independent outcome. Accept only the exact manifest change with genuine complete green validation and canonical finish; otherwise report concrete findings or `human_required` if exact proof is unavailable. Preserve original P0 and Operator claims/reports. Do not edit reviewed implementation.
- Non-goals: Do not alter tests, harness logic, other timeout values, the P0 implementation/history, Operator recovery, Ritualant, or unrelated workstreams. Do not infer PASS from the prior timeout or direct noncanonical test execution.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the correction implementation lands and archives complete.
2. Start in a fresh reviewer context and reconstruct exact scope from archived packet and live main.
3. Verify the one-field JSON semantic delta and unchanged test definition.
4. Independently run canonical changed-file validation and inspect every selected result, coverage, warning, timeout and source identity.
5. Verify the complete validation report SHA-256 and canonical landing/teardown trace.
6. Record authentic `passed`, `findings` or `human_required`; automatic review cycles remain 0.
7. Finish through the normal paired-review lifecycle.

## Handoff

- Next workstream: `agent-paired-review-after-sync-consumer-enforcement-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Refresh reason: `none`
- Next action: After independent acceptance, resume the preserved P0 workstream and regenerate its committed-source report.
- Blockers or open questions: `none`
