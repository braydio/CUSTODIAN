# Review Paired Review Conflict-Resolution Merge Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-conflict-resolution-merge-provenance-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-paired-review-conflict-resolution-merge-provenance-v1`
- Locks: `paired-review-conflict-merge-provenance-v1`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `agent-paired-review-conflict-resolution-merge-provenance-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1.md`
- Reviewed main: `3e68c0b1b6b19d618f18c57b97bb1c111b2b5891`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently verify that the two missing historical merge witnesses are accepted only through authenticated conflict-resolution evidence while ordinary source-span provenance remains strict.
- Completion boundary: Review the landed validator, exact real-Git and adversarial tests, lifecycle documentation, and dated status clarification. Produce an authentic findings-first outcome and canonical coordinator closeout. Do not run or apply recovery for the held host-import review.
- Current measured state: The implementation packet names a current read-only plan failure at `origin/main@3e68c0b1` and pins the two exact merges, their parent SHAs, original run trace, and later main-sync events. The review must reconstruct those independently from the landed tree and local immutable trace before judging.
- Evidence: Archived implementation packet; changed source/tests/docs; original held review packet and implementation packet; immutable local trace `20261020T200652Z-2fd156ce23d0` (original trace SHA is pinned in the implementation packet); actual read-only host-validation plan result; test and changed-file reports.
- Task-specific authority: The implementation packet's `Preserve`, `Non-goals`, `Acceptance`, and `Validation`; `AGENT_WORKSTREAM_LIFECYCLE.md`; existing source-span and reviewer-provenance contracts.
- Work surface: Read-only review of `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1_CLAUDE_SUMMARY.md`, and the exact local trace and original review metadata. Only the canonical review outcome, receipt, packet archive/index lifecycle metadata, and this review's required summary may be authored.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`.
- Review focus:
  1. Independently verify the original trace SHA and exact two `run_blocked` conflict records, original `worktree_resumed` HEAD, full trace identity, and unchanged original review evidence. Do not infer owner inactivity from elapsed time or treat the old claim as released.
  2. Recompute both exact merges' parent identities, merge trees, conflict-resolution deltas, source/test paths, regular-file modes, and archive identities from Git. Verify that every compatibility decision is keyed narrowly to the authentic target/run and does not accept arbitrary missing witnesses.
  3. Recompute the later `4b1af571...` and `6e75b57...` sync proof and event ordering. Ensure ordinary earlier merge witnesses, final-tip constraints, source follow-ups, path allowlists, and file-mode checks remain mandatory.
  4. Run positive plus forged trace, substituted SHA/parent, duplicate/reordered/missing event, unrelated merge, unexpected conflict path, changed test/source blob, mode, archive, ancestry, and missing-later-sync negatives. Run existing reset, Blender, direct-tail, and multi-merge tests.
  5. Verify that the historical root summary is preserved and the dated clarification is factual. Reject any claim that the original review passed or that its claim was released.
- Acceptance: Findings-first independent review of every implementation acceptance criterion. PASS only when no blocking finding or material evidence gap remains, exact immutable provenance is reproduced, all negative controls fail closed, and the original claim/worktree/evidence/outcome remain unchanged. Otherwise record stable evidenced findings; never infer acceptance from green implementation validation.
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; inspect exact trace and Git tree evidence from the local checkout; verify changed-file report has complete coverage and no skips; `git diff --check`; canonical review outcome parser, receipt-delta verifier, and coordinator closeout. Do not run the historical host-import plan apply or launch its reviewer.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Start from a fresh reviewer context after implementation landing and reconstruct the target using durable repository evidence.
2. Independently verify the pinned trace and Git history. Preserve the original trace and the held review unchanged.
3. Report findings with stable IDs and exact evidence, or PASS only if the full acceptance boundary is satisfied.
4. Never apply recovery to, resume, release, or declare accepted the held `review-agent-paired-review-failed-host-validation-import-recovery-v1` claim.

## Handoff

- Next workstream: `review-agent-paired-review-failed-host-validation-import-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: After a genuine correction PASS, generate a fresh read-only host-validation recovery plan for the original run and stop for separate apply authorization.
- Blockers or open questions: Original host-import review is still held and unresolved; correction review PASS alone does not authorize applying its plan.
