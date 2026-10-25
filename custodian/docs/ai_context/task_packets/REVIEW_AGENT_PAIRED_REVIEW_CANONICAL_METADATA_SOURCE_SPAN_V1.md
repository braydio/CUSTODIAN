# Review Paired Review Canonical Metadata Source-Span V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-canonical-metadata-source-span-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-canonical-metadata-source-span-v1`
- Locks: `paired-review-canonical-metadata-source-span-v1`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review target workstream: `agent-paired-review-canonical-metadata-source-span-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CANONICAL_METADATA_SOURCE_SPAN_V1.md`
- Reviewed main: `bda39de1d68fa8f61f77e70ef7e696c6395d4f5d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad556b3-998c-83ea-8620-22173524205f`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently falsify the canonical paired-review metadata exception and establish that it repairs only the authenticated historical source span.
- Completion boundary: Review exact production code, the actual historical positive, real-Git adversarial controls, coordinator/prelaunch evidence and preserved-run plan result; publish only findings-first review evidence and bounded closeout artifacts.
- Current measured state: Historical archive `2e898dd...` is rejected because its associated review packet is outside implementation Work surface despite only two canonical `Authoring chat` metadata substitutions. Original run `20261023T064140Z-1a1e903471c9` is held before reviewer launch.
- Evidence: Archived implementation packet and source/test changes; actual archive and parent Git objects; exact preserved run metadata/claim/diagnostic hashes; exact `--recover-host-validation --plan` output and SHA; no plan apply and no original reviewer launch.
- Task-specific authority: Archived implementation packet; `AGENT_WORKSTREAM_LIFECYCLE.md`; `paired_review_host_validation.py`; `test_paired_review_runner.py`; preserved run evidence.
- Work surface: Read-only review of `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, archived implementation packet, root implementation summary, and exact historical Git objects. Only the canonical review receipt, this packet's archive/index metadata, its required closing summary, and bounded correction/re-review metadata may be written.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`.
- Review focus:
  1. Recompute the exact parent and regular-file tree entries for historical archive `2e898dd...`; prove the two and only two byte changes use the implementation packet's canonical authoring URL.
  2. Verify the paired review's exact derived path, workstream, target workstream and target packet identity before and after; ensure no other review Markdown is admitted.
  3. Verify the review metadata file stays outside implementation source paths and packet Work surface authority.
  4. Run real-Git negatives for unexpected field/value edits, substitute review packet, extra paths, mode changes, duplicate/malformed fields, wrong target identity, and altered trace/claim/landing provenance.
  5. Independently run the actual landing's source-span/coordinator prelaunch checks and inspect the preserved original-run plan digest; confirm no apply or reviewer launch occurred before the plan succeeded.
  6. Compare preserved run metadata, claim receipt, diagnostic ref, branch/worktree and downstream held reviews before/after.
- Acceptance: Findings-first independent assessment. PASS only if actual historical source-span and full coordinator validation succeed; every hostile fixture fails closed; no implementation path authority widens; the plan is authenticated; preserved evidence is unchanged; no reviewer verdict is inferred from green tests.
- Validation: Fresh-context review; full paired-review runner suite and canonical changed-file validation with complete coverage; actual historical host validation; Git diff/history/evidence checks; canonical review outcome, receipt and closeout checks. Do not launch or apply any held downstream review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Reconstruct the implementation from its archived packet and exact `origin/main` history in a fresh reviewer context.
2. Independently run the exact historical source-span and coordinator checks, then falsify each narrow metadata guard.
3. Preserve the original resumed-worktree review run and all downstream claims; report findings before disposition.

## Handoff

- Next workstream: `review-agent-paired-review-resumed-worktree-provenance-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad556b3-998c-83ea-8620-22173524205f`
- Refresh reason: `none`
- Next action: `After accepted correction review and a successful fresh original-run recovery plan, continue the preserved original review only through its same-run authorized recovery.`
- Blockers or open questions: `Preserved original reviewer launch and recovery-plan apply remain gated on authenticated plan success.`
