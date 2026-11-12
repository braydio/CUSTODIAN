# Review: Authenticate attested manifest changes during paired-review continuation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`
- Locks: `paired-review-pinned-manifest-continuation-correction`
- Review: `none`
- Review target workstream: `agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_EXCLUDED_COVERAGE_EVIDENCE_RECOVERY_V1_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `28a887ce55628c3516a52af24c7084e156f9be1a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the correction's immutable policy provenance, attestation binding, selection/ownership accounting and fail-closed report closeout.
- Reviewed implementation acceptance: OWNER-01 and OWNER-02 plus all six acceptance claims in the archived correction packet; preserve the historical PASS and both protected review claims.
- Review evidence: Durable correction summary; adversarial test fixtures/results; exact Git blob/mode/ancestry and manifest hashes; canonical changed-file report; original run metadata/report digests verified read-only.
- Correction threshold: Any policy read from a mutable checkout/report, acceptance of changed global exclusions without authorization, inconsistent report-path policy, incomplete accounting, false PASS, or mutation of a protected historical claim/evidence byte is blocking.
- Focused validation: Independently run `test_paired_review_runner.py` (including the host-validation fixtures), inspect exact source and fixture provenance, verify all path/test-owner/exclusion accounting and changed-file validation, then verify the original claims and evidence are unchanged.
- Review focus: The test-definition change is legitimate only when authenticated from its exact attested Git revision and selected against unchanged `reviewed_main` policy. A fresh run must establish that successful and failed report paths cannot classify exclusions differently.
- Acceptance: Record a findings-first canonical `passed` receipt or concrete findings in a fresh reviewer context. Do not edit the reviewed implementation or apply either preserved recovery plan.
- Non-goals: No review-plan application, original-run recovery, lock release outside normal closeout, policy broadening, implementation edits, or Procession runtime changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f`
- Blockers or open questions: The independent review must not claim historical R0 findings; the preserved parent PASS and OWNER-01/OWNER-02 task attribution remain distinct.
