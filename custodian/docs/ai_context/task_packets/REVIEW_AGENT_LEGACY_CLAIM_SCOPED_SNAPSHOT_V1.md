# Review Legacy Claim Scoped Preservation Snapshot V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-legacy-claim-scoped-snapshot-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-legacy-claim-scoped-snapshot-v1`
- Locks: `legacy-claim-scoped-snapshot`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `agent-legacy-claim-scoped-snapshot-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_LEGACY_CLAIM_SCOPED_SNAPSHOT_V1.md`
- Reviewed main: `705de22f91430f556485c134d0b085bbd9ac5b31`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently verify that scoped preservation captures every byte required to restore one exact protected claim without depending on unrelated mutable Git LFS cache contents.
- Current measured state: The implementation and its paired review are not yet claimed. The no-op review claim is still protected and must remain unchanged during this review.
- Evidence: Landed implementation diff and test reports for `custodian/tools/agent/legacy_claim_quarantine.py` and `custodian/tools/agent/test_legacy_claim_quarantine.py`; V1.1 requirements in `custodian/docs/ai_context/PAIRED_REVIEW_CLOSURE_CAMPAIGN_20261020.md`; V1 compatibility fixtures and exact snapshot/restore evidence.
- Work surface: Review-only inspection of `custodian/tools/agent/legacy_claim_quarantine.py`, `custodian/tools/agent/test_legacy_claim_quarantine.py`, and `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`. Only this review packet's lifecycle/archive metadata, canonical review receipt, managed index, and required root closing summary may be authored.
- Publication inputs: `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/docs/ai_context/PAIRED_REVIEW_CLOSURE_CAMPAIGN_20261020.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Review focus: Verify exact target-ref binding and all reachable claim-specific Git ancestry; complete tracked/dirty/untracked/ignored/symlink worktree preservation; exact runner/continuation/workflow evidence; LFS pointer discovery, materialized-byte deduplication, missing-object fail-closed behavior, and exact restoration checks; conservative storage preflight before writes; bundle prerequisite/ref identity; race detection; V1 manifest and legacy quarantine compatibility; and unchanged process/owner/CAS/dispatcher semantics. Challenge collisions, path traversal, symlink escape, duplicate target paths/OIDs, corrupt/tampered manifest entries, omitted run children, ignored-file drift, ref movement, active/unknown/cross-host owners, and false claims that a partial archive is restorable. Do not inspect by mutating the live no-op worktree or run directory, and do not apply quarantine.
- Acceptance: Findings-first independent review. PASS only if the complete archived implementation, tests, positive restore demonstration, V1 compatibility, and adversarial negative controls establish every required protected byte is independently recoverable and the source implementation does not weaken claim identity, owner verification, CAS, or review dependency truth. Any missing LFS payload or restore proof is a blocking finding. Report the actual reviewer-authored disposition; green tests alone are insufficient.
- Validation: `python3 custodian/tools/agent/test_legacy_claim_quarantine.py`; inspect the exact implementation diff and durable snapshot/restore evidence; `git diff --check`; verify the original no-op claim/worktree/run continuation stayed unchanged. No live quarantine apply and no edits to implementation sources.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Reconstruct the implementation target, exact source span, validation, and restore evidence from the landed commit and archived implementation packet.
2. Inspect scoped schema separately from historical V1 verification. Attempt real restore in a disposable temporary repository and verify all payload bytes, modes, symlink targets, refs, and LFS OIDs.
3. Re-run selected negative fixtures or add no implementation changes; report a canonical `passed`, `findings`, or `human_required` outcome bound to the review run.
4. Never alter, quarantine, or satisfy dependencies for the live no-op review in this paired review.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `none`
- Blockers or open questions: `none`
