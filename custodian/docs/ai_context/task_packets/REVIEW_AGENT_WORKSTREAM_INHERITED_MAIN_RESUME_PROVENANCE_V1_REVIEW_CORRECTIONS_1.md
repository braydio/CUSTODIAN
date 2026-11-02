# REVIEW: R0-01 Consumer Inherited-Main Real-Git Proof Correction

- Packet schema: custodian.task_packet.v2
- Authoring handoff: auto
- Workstream: review-agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1
- Category: agent-ops
- Kind: review
- Status: draft
- Dispatch: manual
- Priority: P0
- Depends on: agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1
- Locks: workstream-source-span-provenance
- Review: none
- Review target workstream: agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_REVIEW_CORRECTIONS_1.md
- Reviewed main: 9c9fb5c29c97c84d142184af7dfa6d2f41b52df7
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow
- Review cycle: 1
- Max automatic review cycles: 1
- Review rationale: The parent independent review recorded material acceptance-proof gap R0-01. This one human-authorized paired re-review must independently prove the inherited-main consumer trust boundary from immutable current Git and fresh falsification, without altering the earlier review.
- Parent finding: R0-01, custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; outcome findings, NOT accepted.
- Goal: Independently determine whether the correction has closed R0-01 with precise positive and adversarial consumer real-Git evidence, while preserving the original implementation's production behavior and source-authentication guards.
- Reviewed implementation acceptance: Verify the new consumer tests directly exercise inherited-main merge classification and inherited path exclusion, authenticate claimed resume/main ancestry, reject forged or out-of-boundary history, and retain legacy checkpoint/resume/RC-119/no-source-mutation invariants. The new review may approve the correction; it must never rewrite the prior nonpassing reviewer verdict or falsely claim retrospective acceptance.
- Review evidence: custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; post-land archived correction packet and closing summary; tracked test diff and source identities; original R0-01 finding and exact host-private validated trace/report only as read-only evidence; fresh independent disposable Git history.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_CORRECTION_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md`; `AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_CLAUDE_SUMMARY.md`; `REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_CLAUDE_SUMMARY.md`; `custodian/docs/ai_context/reports/RETIREMENT_CAMPAIGN_CREATION_EXCEPTION_20261101.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/check_packet_categories.py`; `custodian/tools/agent/validate_review_pairing.py`; `custodian/tools/agent/task_packet_index.py`
- Correction threshold: Treat missing positive or material negative proof, acceptance of forged ancestry/source, weak assertion masking a bypass, regression of canonical checkpoint/resume, or unproved production change as blocking. If found, report cycle 1 R1-NN findings and human_required at this one authorized cycle cap; do not author correction-2.
- Focused validation: Independently recreate or falsify the positive inherited-main classification, owned-path inventory, and each negative identity/history/tree/source case in disposable Git; run newly added focused consumer tests and full pre-existing consumer/producer suites; confirm exact canonical report and source/test coverage. Treat the correction author's own tests as claims until independently challenged.
- Review focus: Compare archived parent findings R0-01 verbatim with correction fixture matrix; specifically inspect consumer provenance.inherited_main_merges, exact resume event identities, first-parent membership, deterministic tree proof, exclusion of upstream-only paths, authored-path preservation, checkpoint history exclusion, and error-path specificity. Prove that the newly added tests would catch a meaningful regression to this branch. Inspect any conditional production diff for failing-first reproduction and minimality.
- Acceptance: Findings-first independent review on live post-land main with one canonical Review Outcome, original R0-01 status explicitly fixed/unresolved/regressed and actual proof. PASS requires independently reproduced positive/adversarial cases, complete source-bound validation, exact landed correction identity, and normal canonical workstream teardown. Any material gap/defect at cycle 1 is nonpassing/human_required; no further automatic correction or reviewer launch is authorized.
- Non-goals: No implementation edits, production bug fixing by reviewer, revision of old review R0-01, synthetic acceptance receipt, new correction workstream, automatic review loop expansion, original summary-rename finish, branch reset/claim release outside lifecycle, or alteration of external agent/root state.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

1. Claim only after agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1 truly lands on origin/main, is archived complete, and its checkout is canonically removed.
2. Start one fresh context distinct from the correction implementer. Reconstruct contract from immutable R0-01 review, source, correction packet, tested diff, and current Git. Do not use the previous reviewer transcript as an acceptance verdict.
3. Run independent real-Git positive and adversarial cases directly against the current consumer. Compare exact returned authored path inventory and inherited merge provenance to expected Git objects, not just to test assertions or broad CI success.
4. Test false acceptance of forged/resorted/duplicate resume, invalid branch/run/worktree, main first-parent mismatch, tampered merge tree, concealed local authorship, tainted checkpoint and invalid source/after-sync status. Check legitimate checkpoint/resume histories still pass.
5. Independently validate exact source/test diff, report SHA256, source identity, full producer/consumer regressions and the correction's own normal finish/teardown receipts. Reject missing evidence as human_required.
6. Record one findings-first review outcome. If PASS, explicitly document R0-01 as fixed in THIS review's new evidence without modifying the original archived findings. If blocked, report cycle-1 finding IDs and human_required; do not create correction-2.
7. Finish through the canonical review lifecycle only. A later owner may reassess the protected original summary-rename workstream under its same claim only after an authentic independent PASS and separate gate recheck.

## Handoff

- Next workstream: agent-workstream-canonical-summary-rename-recovery-v1
- Next packet state: refresh-required
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Refresh reason: This new independent review is the final user-authorized evidence gate for R0-01; an authentic PASS permits a later same-run readiness reassessment, while findings/human_required keep original summary-rename finish blocked.
- Next action: After genuinely accepted review, verify original protected claim/run/source, branch, preflight, and source-bound finish evidence before deciding whether to resume. Do not create or replace the original claim.
- Blockers or open questions: No automatic correction-2 or additional reviewer is authorized. Original summary-rename remains blocked unless a new independent PASS establishes the missing consumer proof.
