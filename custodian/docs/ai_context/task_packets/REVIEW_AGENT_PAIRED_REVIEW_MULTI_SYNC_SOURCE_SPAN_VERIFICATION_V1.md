# REVIEW: Multiple Main-Sync Source-Span Verification

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-multi-sync-source-span-verification-v1`
- Category: `agent-ops`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-multi-sync-source-span-verification-v1`
- Locks: `paired-review-multi-sync-source-span`
- Review: `none`
- Review target workstream: `agent-paired-review-multi-sync-source-span-verification-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_MULTI_SYNC_SOURCE_SPAN_VERIFICATION_V1.md`
- Reviewed main: `4693df7b1fa6184b6ea4596f5a672d0f60c123b0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Multiple-merge ancestry is a security boundary for independent review source selection; ordered lifecycle witnesses, exact Git parent/tree proofs and source coverage need fresh independent scrutiny.`
- Goal: Independently verify that the landed source-span resolver authenticates multiple sequential synchronization merges without admitting forged ancestry, foreign source paths, or incomplete validation.
- Reviewed implementation acceptance: Verify every acceptance claim in the archived implementation packet, especially exact per-merge parent and tree proofs, unique ordered lifecycle witnesses, separation of authored versus inherited paths, preservation of single-merge and follow-up contracts, adversarial rejection coverage, and unchanged protected review evidence.
- Review evidence: Reuse the implementation's real-Git fixture report and canonical changed-file validation output. Inspect the actual preserved merge commits `d66faed6ea9a267d8c227a352a42e214419e19d8` and `10d8fc2a6fe6e08d32002e012795da00361f0f4a` where the repository-tracked lifecycle evidence is available. Verify the two protected review claims and their original evidence remain untouched.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or a material evidence gap. Treat optional improvements as deferred. Do not alter existing held review claims or plans.
- Focused validation: Re-run the focused multi-merge real-Git fixtures and `python3 -m unittest custodian.tools.agent.test_paired_review_runner`; inspect exact changed-file canonical coverage and `git diff --check`. Recompute Git parent, merge-tree and trace-event binding independently for positive and negative cases.
- Review focus: Ensure the verifier does not merely remove the one-merge guard; every merge consumes exactly one valid witness set in order, later-main paths are not mislabeled as implementation-authored, overlapping paths remain covered, and old single-merge/follow-up behavior is preserved. Confirm malformed/forged traces, event reuse, conflict resolutions, source hashes, modes, packet identity, report digests, selected tests and incomplete/failing/timed-out validation remain fail-closed.
- Acceptance: Produce a findings-first independent review of the landed implementation. Record a `passed` receipt or concrete findings with cycle-scoped IDs. Blocking defects or material acceptance-proof gaps create `agent-paired-review-multi-sync-source-span-verification-v1-review-corrections-1` and its paired review. Do not edit the reviewed implementation in this workstream. Do not apply any protected coverage or Procession recovery plan; those remain gated on this review's canonical PASS and subsequent exact-run plans.
- Non-goals: Do not change the reviewed implementation, alter the two protected review claims/evidence, apply a recovery plan, release locks, add Procession-specific exemptions, or make gameplay/runtime changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation is landed and archived complete.
2. Start from a fresh reviewer context and reconstruct the task from the archived packet, code, tests, and durable evidence.
3. Inspect every authenticated merge in order, including both preserved synchronization commits if available. Independently recompute parent relationships and deterministic merge trees.
4. Verify exact lifecycle event identity, ordering, uniqueness and non-reuse for every merge. Attempt adversarial trace and Git-history mutations in disposable repositories.
5. Confirm source inventory excludes inherited unrelated main changes but retains workstream-authored and overlapping paths.
6. Recheck legacy single-merge and post-archive follow-up fixtures, canonical changed-file validation, and original protected-claim/evidence hashes.
7. Record findings first, then close through the ordinary paired-review lifecycle. Do not resume or apply either protected original recovery plan in this workstream.

## Handoff

- Next workstream: `review-agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Refresh reason: `none`
- Next action: `After this correction receives a canonical independent PASS, generate and inspect a new read-only same-run host-validation recovery plan for the exact preserved correction-review run.`
- Blockers or open questions: `The original correction review and Procession remain held; do not claim either as accepted or recovered.`
