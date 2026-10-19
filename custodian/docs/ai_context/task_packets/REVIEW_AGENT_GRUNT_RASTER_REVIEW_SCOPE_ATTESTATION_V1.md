# Review Grunt Raster Source-Scope Attestation V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-grunt-raster-review-scope-attestation-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-grunt-raster-review-scope-attestation-v1`
- Locks: `paired-review-source-scope`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `agent-grunt-raster-review-scope-attestation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md`
- Reviewed main: `217f41093802b8c74cf88f986076e4e26acc8e77`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently falsify the bounded historical Grunt Markdown exception, particularly forged attestation, pre-approval bypass, mutable provenance, source-span/coverage drift and unintended new .md acceptance.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json`.
- Publication inputs: `custodian/docs/ai_context/task_packets/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`.
- Review evidence: Implementation accepted A1-A7, attestation bytes/digest/review approval authority, original archive blob `73dc3112`, source-bearing e298 historical replay, actual bounded three paths, comparison of original protected Grunt run file/hash manifest before versus after THIS workstream.
- Review focus: Try unauthorized post-hoc attestation without independent accepted verdict, modifications after acceptance, wrong SHA/blobs/modes, forged receipt and directory/glob .md variants. Repeat untouched negative fixtures that reject undeclared Markdown even if mentioned in packet body. Confirm the implementation did not make the Grunt review's current run "passed" or erase its claim without a reviewer.
- Acceptance: Findings-first fresh-context verdict; no pass on weak test-only approval checks or hard-coded override without meaningful independent attestation authority. If actual accepted independent verification cannot be established, report `findings` and a bounded correction, not a fake green run. The original Grunt reviewer remains pending and protected.
- Validation: Rerun targeted `paired_review_runner_unit` including e298 replay, wrong-path/blobs/approval negatives; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `git diff --check`; verify source-only implementation commit then archive-only closeout. One small evidence report, no screenshots or visual review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
## Procedure
1. Claim only after exact implementation archives complete. Reconstruct immutable inputs and verify that e298 failed originally due to the three undeclared docs.
2. Independently run acceptance and negative tests, ensure attestation not consumed as sole proof of authorization and existing reviewer claim/run unchanged.
3. Publish truthful verdict and follow normal paired-review lifecycle. On nonpass, preserve evidence and route bounded correction.
## Handoff
- Next workstream: `none`
- After independent PASS, authorize read-only Grunt host-recovery plan on its SAME run; do not launch original reviewer from this packet.
