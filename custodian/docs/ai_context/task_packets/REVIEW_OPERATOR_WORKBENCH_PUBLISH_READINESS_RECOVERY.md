# REVIEW: OPERATOR WORKBENCH PUBLISH READINESS AND RECOVERY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-publish-readiness-recovery`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-publish-readiness-recovery`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-publish-readiness-recovery`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md`
- Reviewed main: `4df3611c`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed Workbench publication hardening converts the recent serial Git/LFS/manifest/import failure chain into one bounded readiness/preparation contract without weakening source authority, sparse-checkout safety, validation, or user-work preservation.
- Reviewed implementation acceptance: Review the archived implementation packet's full acceptance contract, with special emphasis on clean-behind auto preparation, unknown-dirt preservation, `LAND PENDING` resume, local-cache-only LFS handling, sparse validation dependency proof, stale selected-manifest rejection before mutation, exact Godot metadata preimage restoration, clean-or-`RECOVERY_REQUIRED` failure postconditions, and unchanged scoped landing/allowlist authority.
- Review evidence: Reuse the implementation's fixture-isolated readiness classifications, publish transaction journals, exact before/after hashes, LFS network-negative controls, metadata-restoration receipts, UI readiness projections, successful publication fixture, changed-file validation report, and closing summary. Gather fresh evidence only where those artifacts do not prove an acceptance criterion.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in required acceptance. In particular, any automatic reset/stash/rebase, network LFS fetch, ambiguous file restoration, silent Workbench baseline rewrite, or widening of publication allowlists/sparse scope is correction-worthy. Route optional ergonomics and non-blocking messaging improvements to next-slice/deferred.
- Focused validation: Inspect the landed readiness/classification boundary and restoration predicates; rerun `python3 custodian/tools/validation/operator_art_worktree_smoke.py`, `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`, `python3 custodian/tools/validation/operator_workbench_ui_smoke.py`, and `python3 custodian/tools/validation/operator_animation_workbench_smoke.py`. Reuse the implementation's local-LFS and import-preflight evidence unless stale/insufficient. Run the smallest changed-file validation needed to confirm findings.
- Review focus:
  - Safe preparation must be strictly narrower than destructive Git cleanup.
  - Dirt classification and recovery decisions must use structured state, not error-string parsing.
  - The exact selected source baseline must be checked before mutation without stealing FX-adoption's broader binding-set ownership.
  - LFS must remain local-cache-only and sparse dependency additions must be measured rather than broad.
  - Metadata restoration must require clean pre-state + proven transaction provenance + exact preimage; wildcard cleanup is a blocking defect.
  - Failure after mutation must end clean or with a complete durable `RECOVERY_REQUIRED` journal.
  - Successful publication must retain current source-conflict, allowlist, commit, pending-land, and landing guarantees.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings. Give each finding a stable cycle-scoped ID (`R<cycle>-<NN>`) and the required class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects and material acceptance-proof gaps create `operator-workbench-publish-readiness-recovery-review-corrections-<n>` plus its paired review packet. Do not patch reviewed implementation code.
- Non-goals: Do not redesign the Operator Workbench publisher, add FX-layer adoption, broaden sparse checkout beyond required dependencies, change Operator art/runtime/gameplay, or implement page-3 PREVIEW refresh hardening in the review workstream.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after `operator-workbench-publish-readiness-recovery` is complete and archived on `origin/main`.
2. Read root/local AGENTS, the archived implementation packet and closing summary, `OPERATOR_ANIMATION_WORKBENCH.md`, the current sparse-worktree publication code, and the implementation's durable transaction evidence.
3. Review the implementation against the authored acceptance, not merely the fact that one publish succeeds.
4. Start with the negative controls: unknown dirt, uncached LFS, stale manifest, ambiguous metadata churn, injected downstream failure, and pending-land resume.
5. Verify exact byte preservation for user/unknown inputs and exact restoration for eligible machine-generated metadata.
6. Verify the successful path still stages only the existing allowlist and lands only through the approved Operator publication handoff.
7. Record findings/receipt and scaffold bounded correction + re-review only when the correction threshold is met.
8. Complete/archive through the normal paired-review lifecycle.

## Human Decision Gate

No subjective art or visual baseline is in scope. If a policy question arises about whether an ambiguous file class may be auto-restored, treat ambiguity as fail-closed and escalate rather than inventing a broader cleanup policy.

## Handoff

- Next action: Claim after the implementation dependency completes.
- Blockers or open questions: None.
