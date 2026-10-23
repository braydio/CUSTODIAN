# Review: Paired Review Direct-Tail Provenance and Receipt Closeout V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-direct-tail-receipt-closeout-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-direct-tail-receipt-closeout-v1`
- Locks: `paired-review-source-span-provenance, paired-review-host-import-recovery`
- Review: `none`
- Review target workstream: `agent-paired-review-direct-tail-receipt-closeout-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_DIRECT_TAIL_RECEIPT_CLOSEOUT_V1.md`
- Reviewed main: `d3476a38ca457d4186c11cec718592fef7e9ffbc`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently challenge the direct-tail source-base authentication and coordinator-owned receipt formatting/recovery without weakening quarantine or reviewer judgment.
- Reviewed implementation acceptance: A1–A5 in the archived implementation packet, including the exact scoped-snapshot history, direct-tail ancestry and event negatives, canonical receipt bytes, same-run recovery guards, quarantine refusal, and unchanged historical evidence.
- Review evidence: Full implementation diff and closing summary; real Git source-span fixtures; exact historical trace and ancestry; paired-review runner, receipt-delta and workstream tests; immutable run manifests and quarantine records checked read-only.
- Correction threshold: Create correction work only for a confirmed acceptance or correctness defect, or a material evidence gap. Any finding about reviewer-authored judgment, quarantine identity, original evidence mutation, or receipt provenance is blocking. Do not convert the quarantined witness outcome.
- Focused validation: Independently rerun paired-review runner tests, workstream tests, legacy quarantine tests, exact historical resolver and adversarial real-Git fixtures, changed-file validation, packet/index checks, compilation and diff checks.
- Review focus: Verify `main_sync.main_sha` is bound to the exact source/claim base and Git ancestry, not accepted merely because it is an ancestor; challenge duplicated or cross-run events, altered archive/source trees, modes and coverage. Confirm only a parsed reviewer-authored canonical PASS can produce a receipt, the coordinator formatter emits precisely the verifier's required bytes, and all other reviewer target modifications fail. Attack recovery against quarantined identity, mutated evidence, stale ownership, wrong target/run/SHA, duplicate receipt, missing archived source and consumed launch. Confirm the recovery never launches a reviewer and never modifies the original branch/worktree/run evidence.
- Acceptance: Produce a fresh findings-first independent review against live `origin/main`. Record a genuine canonical passed receipt or concrete stable-ID findings. Green validation and reviewer summary prose alone are not acceptance. Do not use closeout recovery on any historical run during this review.
- Non-goals: Do not edit implementation code, resume or unquarantine the witness review, apply historical recovery plans, or release unrelated claims.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation is archived complete and dispatcher dependencies/locks permit this review.
2. Start a fresh reviewer context. Read root and local instructions, the archived implementation packet and summary, exact historical trace/Git history, current code, and durable test evidence.
3. Independently reconstruct the scoped-snapshot source span and verify the exact no-op witness against the claim base and ancestry.
4. Challenge the formatter, normal post-exit closeout, and recovery plan/apply boundary with positive and negative fixtures. Ensure quarantined recovery fails before any write.
5. Verify all original evidence identities remain immutable; do not treat the original quarantined review's PASS prose as accepted evidence.
6. Record findings first and close only through the normal paired-review runner and coordinator verification.
