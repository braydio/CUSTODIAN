# REVIEW: Paired Review Claim Base Ancestry Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-claim-base-ancestry-provenance-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-claim-base-ancestry-provenance-v1`
- Locks: `paired-review-claim-base-ancestry-provenance-review`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-paired-review-claim-base-ancestry-provenance-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CLAIM_BASE_ANCESTRY_PROVENANCE_V1.md`
- Reviewed main: `9cbbfef899957f2e3fff3306b74accf28cd846dc`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently verify that the ancestry correction accepts only an authentic earlier failed claim for the same published checkout and does not widen the validation source span.`
- Reviewed implementation acceptance: `Verify implementation packet A1–A7, with particular attention to canonical claim identity, unambiguous traces, Git ancestry direction, unchanged selected source base, protected held review artifacts, and no unauthorized reviewer launch.`
- Review evidence: `Fresh-context inspection of landed source/tests, real historical resolver output, exact source range, positive and negative temporary Git fixtures, focused validation, commit separation, and before/after manifests for the three held review runs.`
- Correction threshold: `Open a correction only for a demonstrated provenance acceptance/rejection defect, widened source span, broken existing compatibility case, protected artifact mutation, or incomplete required validation. Preserve all original held runs on uncertain evidence.`
- Focused validation: `Run the paired-review host-validation test suite and exercise exact historical source-bearing resolution. Confirm returned base equals 8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8 and excludes all intervening commits. Verify positive ancestry, equality, identity mismatch, duplicate/ambiguous, unrelated, and reversed-ancestry cases. Recompute protected run manifests and compare byte-for-byte.`
- Review focus: `Claim event identity and run binding; full commit resolution and parent/subject binding; strict ancestor direction; source_base remains selected published claim base; no ambiguity accepted; existing queue/archive-only/main-sync/W1/6519 controls; implementation versus archive-closeout commit separation; held run preservation.`
- Acceptance: `Issue findings-first independent receipt. PASS only if all listed positive and negative cases are demonstrated, source span remains exactly pinned, existing held claims/evidence remain unchanged, required tests pass, and no recovery reviewer was launched. Otherwise record precise findings and keep the original source-bearing review unlaunched.`
- Non-goals: `Do not edit implementation code or tests; do not modify/release/replace/resume any of the three held review claims; do not apply a recovery plan, launch the source-bearing review, or continue W1.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `review-agent-paired-review-source-bearing-archive-gate-v1`
- Next packet state: `host_validation_recovery; read-only plan only for preserved run 20261019T024516Z-fcfcefa2d521 after PASS`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Refresh reason: `none`
- Next action: `After PASS, create the read-only recovery plan for the exact preserved source-bearing review run and stop. Do not apply the plan, launch its reviewer, replace any held review, or continue W1.`
- Blockers or open questions: `All three existing held review claims and evidence remain protected.`
