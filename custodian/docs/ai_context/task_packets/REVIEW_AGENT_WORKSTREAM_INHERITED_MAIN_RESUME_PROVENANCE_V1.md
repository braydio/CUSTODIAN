# REVIEW: Inherited-Main Resume Provenance Correction

- Packet schema: custodian.task_packet.v2
- Authoring handoff: auto
- Workstream: review-agent-workstream-inherited-main-resume-provenance-v1
- Category: agent-ops
- Kind: review
- Status: `ready`
- Dispatch: `auto`
- Priority: P0
- Depends on: agent-workstream-inherited-main-resume-provenance-v1
- Locks: workstream-source-span-provenance
- Review: none
- Review target workstream: agent-workstream-inherited-main-resume-provenance-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md
- Reviewed main: 0e5da248e93f0395f084f0abb7feba8285132bc0
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow
- Review cycle: 0
- Max automatic review cycles: 0
- Review rationale: This work changes producer/consumer authority deciding whether a claimed implementation can land and receive an independent review; fresh source and real-Git adversarial examination is mandatory. The explicitly authorized exception covers this review only and no automatic correction cycle.
- Goal: Independently determine whether the correction accepts only cryptographically and chronologically authenticated main-inherited resume history, and whether source-span and preflight/finish checks remain fail-closed.
- Reviewed implementation acceptance: Independently reconstruct every substantive claim in archived AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md, including exact trace/claim identity, first-parent inherited prefix, no local unique source before fast-forward, source inventory post-resume, RC-119 and archive-first compatibility, strict authored-merge checkpoint and after-sync requirements, and preflight/finish parity.
- Review evidence: Archived implementation packet and canonical summary, exact main source/validation report and SHA-256, disposable bare-Git real-life fixture with 878009b2 / 0aee8bf / 38545e4 / 8bc0fe4 ancestry, guarded original protected run evidence inspected without mutation on the host, test_workstream and test_paired_review_runner suite results, current lifecycle trace and source-span host artifacts.
- Publication inputs: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/validate_review_pairing.py`; `custodian/tools/agent/check_packet_categories.py`; `custodian/tools/agent/task_packet_index.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1.md`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/docs/ai_context/reports/RETIREMENT_CAMPAIGN_CREATION_EXCEPTION_20261101.md`
- Correction threshold: Missing original-run proof, any acceptance of forged or misordered resume, any uncaptured local-unique authored source, any unwitnessed genuinely authored merge, or any acceptance without needed after-sync validation is blocking. Material proof gaps become human_required; do not synthesize witnesses or create correction packets under this one-pair exception. Max automatic review cycles is zero.
- Focused validation: Independently rerun the real-Git failing-first fixture against parent source and positive/negative cases against landed correction; both producer and consumer full suites; canonical changed-file validation with exact source identity and complete coverage; verify all relevant completion receipts and historic RC-119 positive/negative tests.
- Review focus: Verify existing remote branch and trace owner identities; clean fast-forward semantics and the first-parent provenance boundary; exclude inherited upstream files from authored source; reject arbitrary main reachability and fabricated resume/checkpoint events; validate genuine authored sync merges, after-sync identity, packet/archive/summary lineage, source-span review, and accurate read-only preflight.
- Acceptance: Produce one findings-first independent verdict on live main. PASS requires independently reproducible positive and adversarial cases with complete validation and genuine canonical implementation teardown. Otherwise record stable R0-NN findings or human_required without altering code, historical evidence, original summary-rename claim, or creating another pair. Do not infer retrospective approval of any blocked review from this verdict.
- Non-goals: Do not edit the reviewed implementation, generate correction cycle 1, restart or finish the original summary-rename claim, alter W1/Agent Wire/timeout history, modify root-dirty files or gc, release claims, or weaken source/checkpoint/after-sync guards.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

1. Claim only after agent-workstream-inherited-main-resume-provenance-v1 is genuinely landed and archived complete with its worktree canonically removed.
2. Start in a fresh context; reconstruct contract from live main, archived packet, original green reports and authentic traces. Treat implementation summary as an unverified claim.
3. Reproduce historical inherited-main merge and compare old/new producer and consumer outcomes; verify preflight blocker on unprovable history.
4. Independently mutate trace, git ancestry, branch, source, merge and after-sync identities in disposable fixtures; require every negative control to fail closed and valid cases to pass.
5. Verify full focus suites, canonical report and source identity, original incident preservation, and implementation finish receipt.
6. Record one findings-first outcome. At zero correction cycles, route blocking defects to human_required rather than starting another packet.
7. Finish only through normal review lifecycle; do not auto-resume the original protected summary-rename claim.

## Handoff

- Next workstream: agent-workstream-canonical-summary-rename-recovery-v1
- Next packet state: refresh-required
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Refresh reason: Independent PASS may make original protected claim eligible for an exact-run source-validation recheck; nonpassing outcome keeps it blocked.
- Next action: If and only if review passes, recheck original owner, remote branch, source identity, and canonical finish preflight for summary-rename under its same run. Do not create or transfer a claim.
- Blockers or open questions: Original run remains protected and cannot be resumed based on this packet's mere publication, implementation landing, or green tests.
