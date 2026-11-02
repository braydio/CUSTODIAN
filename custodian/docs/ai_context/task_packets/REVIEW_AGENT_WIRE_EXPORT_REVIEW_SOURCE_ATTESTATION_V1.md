# REVIEW: EXACT WIRE EXPORT REVIEW SOURCE ATTESTATION V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-wire-export-review-source-attestation-v1
- Category: agent-ops
- Kind: review
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P1
- Depends on: agent-wire-export-review-source-attestation-v1
- Locks: paired-review-source-provenance, paired-review-host-validation
- Review: none
- Review target workstream: agent-wire-export-review-source-attestation-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_WIRE_EXPORT_REVIEW_SOURCE_ATTESTATION_V1.md
- Reviewed main: 8bc0fe40184dec741ccc5a92997052f96e0deb43
- Authoring chat: not-recorded
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify that the one-case source attestation cannot authorize another source, manifest, review, or unaccepted outcome, and safely unblocks only the preserved exporter review after correction acceptance.
- Reviewed implementation acceptance: Exact source base/head/commit, source files/modes/blobs, packet/archive/merge identity, old/new manifest blobs and test-definition delta, exporter claim/trace, preserved review run/claim identity, and correction review outcome/receipt/ancestry are all authenticated. No acceptance exists before genuine independent PASS; original review evidence remains unchanged.
- Review evidence: Archived correction packet and summary; exact landed correction diff and attestation JSON; failing-first real-Git regressions against the original exporter history; wrong-source/blob/manifest/review/outcome/workstream negative cases; canonical changed-file validation; original preserved run evidence and before/after hashes; exact recovery-plan result after acceptance if available.
- Correction threshold: Create correction work only for a confirmed fail-open defect or material evidence gap. Do not patch reviewed code in this review workstream. An unavailable correction-review PASS is a blocker and cannot be inferred from fixture tests.
- Focused validation: Independently run exact historical source-span and real-Git mutation regressions, canonical accepted-review receipt tests, paired-review runner tests, and changed-file validation. Verify the attestation stays inert without a genuine accepted correction PASS and that the original claim/run/worktree/lock remains untouched.
- Review focus: Source/revision/blob/mode/path exactness; full tree and manifest-change identity; run/claim/review target binding; accepted correction-review PASS and receipt ancestry; no unrelated workstream acceptance; fail-closed behavior for absent, altered, stale, forged, or conflicting evidence; preservation of original evidence; and no duplicate reviewer launch.
- Acceptance: Produce a findings-first independent review of live main. Record a passed receipt or concrete findings with stable IDs (R0-NN), class, domain, affected acceptance, evidence, disposition, and rationale. A PASS requires every exact and negative case to behave as specified and the exception to remain inert absent genuine acceptance. Blocking defects create the bounded correction cycle plus paired review. Do not modify the reviewed implementation.
- Non-goals: Do not apply recovery, launch/relaunch the exporter reviewer, alter its original claim or evidence, release current owners' locks, broaden manifest policy, or change telemetry transport/public WIRE/hourly automation.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

1. Claim only after the correction implementation lands complete and archived; start a fresh reviewer context.
2. Read applicable AGENTS instructions, this packet, the archived correction packet, its summary, exact host-validation change, attestation JSON, real-Git tests, and the preserved exporter identity evidence.
3. Independently reconstruct the original source span and confirm the test reproduces the pre-correction missing-attestation rejection.
4. Verify exact source/revision/blob/mode/tree/manifest bindings and every review identity field.
5. Prove absent, fabricated, unaccepted, mismatched, non-PASS, stale, or unrelated correction-review evidence cannot activate the exception.
6. Prove a genuine canonical correction-review PASS is necessary and sufficient for the exact preserved exporter review source case, without making an exporter review verdict.
7. Compare original host-run/claim/worktree evidence before and after; require unchanged bytes and ownership. Do not apply the original recovery plan or launch its reviewer.
8. Record findings first and complete/archive through the normal independent-review lifecycle.
