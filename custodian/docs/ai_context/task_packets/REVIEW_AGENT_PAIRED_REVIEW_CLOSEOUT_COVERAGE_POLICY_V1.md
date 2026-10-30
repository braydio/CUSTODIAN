# REVIEW: Paired-review closeout coverage policy

- Packet schema: `custodian.task_packet.v2`
- Workstream: review-agent-paired-review-closeout-coverage-policy-v1
- Category: `agent-ops`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: agent-paired-review-closeout-coverage-policy-v1
- Locks: `agent-paired-review-closeout-coverage-policy`
- Review: `none`
- Review target workstream: agent-paired-review-closeout-coverage-policy-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CLOSEOUT_COVERAGE_POLICY_V1.md
- Reviewed main: `0100d8a2af1c0378006a4f01fd6801a4104b41f2`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that coordinator closeout authenticates excluded-file coverage using the immutable reviewed-main manifest without weakening any other evidence gate.
- Reviewed implementation acceptance: `_verify_host_validation_at_commit()` uses the canonical manifest pinned to `reviewed_main`; valid canonical exclusions pass; unavailable or mismatched policy and forged evidence fail closed; source hashes, report/provenance digests, source-span identity, and complete selected-test coverage remain enforced; preserved historical evidence is unchanged.
- Review evidence: Landed implementation diff and focused tests; `paired_review_host_validation.py` `_pinned_coverage_manifest()`, `_validate_report()`, and `verify_coordinator_validation()`; canonical `validation_manifest.json`; durable implementation validation evidence. The protected prior review run is not an input to mutate or rerun.
- Correction threshold: Any acceptance of exclusions not authorized by the exact pinned manifest, any trust in the working tree or report JSON for policy, any weakened hash/digest/source-span/test-ownership check, or any change to the protected prior review evidence is a blocking defect. Treat missing proof for required acceptance as a blocking evidence gap.
- Focused validation: Independently inspect the exact landed diff and tests. Falsify canonical positive, missing/malformed policy, wrong baseline, fabricated/extra/duplicate/overlapping exclusions, changed source/manifest/report/provenance hashes, incomplete test ownership, and failed/timed-out report behavior. Verify `_verify_host_validation_at_commit()` itself is covered.
- Review focus: Confirm the manifest provenance is immutable `reviewed_main`, that `HostValidationError` preserves fail-closed behavior, and that the fix makes the existing valid report acceptable without rewriting it. Verify the separate protected recovery claim, reviewer PASS, continuation, and historical evidence remain untouched.
- Acceptance: Produce a findings-first fresh independent verdict on the landed implementation. Record a canonical `passed` receipt only when all required acceptance claims and focused evidence are verified; otherwise record concrete findings with stable cycle-scoped IDs. Do not treat the old preserved reviewer PASS as acceptance of this correction.
- Non-goals: Do not patch the reviewed implementation; do not run or close out the separate protected review; do not edit historical report bytes, release locks, broaden coverage exclusions, or redesign the paired-review system.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

1. Claim only after the implementation dependency archives complete on `origin/main` and dispatcher eligibility is confirmed.
2. Start a fresh independent reviewer context and reconstruct the target from the archived implementation packet, exact landed diff, tests, and validation evidence.
3. Verify the full implementation acceptance contract, including the source of the pinned manifest and fail-closed handling for missing policy.
4. Check the positive and adversarial coverage cases listed above; separate implementation defects from evidence gaps.
5. Record the canonical independent outcome and complete/archive this review through the normal paired-review lifecycle. Do not modify implementation code.

## Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Summary backlink: include the exact Authoring chat URL in every durable summary and final Next Handoff
- Refresh reason: none
- Next action: Report the accepted correction review and await coordinator authorization before resuming the protected prior closeout.
- Blockers or open questions: This review cannot be claimed until its implementation dependency completes and the dispatcher confirms eligibility.
