# REVIEW: OPERATOR WORKBENCH PUBLISH READINESS CLI CORRECTION 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-publish-readiness-recovery-review-corrections-1`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-publish-readiness-recovery-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_REVIEW_CORRECTIONS_1.md`
- Review modes: `code, architecture, workflow`
- Reviewed main: `21ffccb775b24ed3d8c7e8d7651acdd438a18017`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include this exact Authoring chat URL in the review summary and final handoff.
- Reviewer context: `fresh`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify that correction 1 closes parent finding `R0-01` so no documented CLI invocation can mutate canonical Operator art outside the reviewed readiness, dedicated-checkout, and scoped landing contract.
- Reviewed implementation acceptance: Verify correction-packet Acceptance items 1–5 and report `R0-01` as `fixed`, `unresolved`, or `regressed`. Review the live CLI entrypoint, shared publication authority, dry-run semantics, stale-source override boundaries, and exact staged/landed paths.
- Review evidence: Correction packet and summary; CLI-level adversarial regression receipts; current `operator_art_worktree.py` readiness/allowlist/landing path; existing four focused Workbench smokes; current canonical source/runtime hashes for blocked cases.
- Correction threshold: Keep `R0-01` open if any CLI path can mutate canonical assets from coordination main, arbitrary/detached checkout, or readiness-blocked art checkout, or can bypass allowlist/scoped landing. Create another correction only for a confirmed defect or material acceptance-proof gap.
- Focused validation: Run the new CLI publication regression and four existing focused Workbench smoke scripts. Recheck `git diff --check` and confirm reviewed implementation code was not modified after its correction commit. Reuse current-head local-LFS/import evidence unless the correction changes that surface.
- Review focus: No mutation before identity/readiness checks; exact immediate pre-mutation revalidation; dry-run is canonical-write-free; stale override remains narrow; UI and CLI share the same transaction/staging/landing authority; no broader Operator scope.
- Acceptance: Produce a findings-first fresh-context review of live `main`, retaining `R0-01` and reporting its disposition plus any new cycle-scoped findings. Do not patch reviewed implementation code. If fixed with no further blockers, mark the parent Workbench readiness review lineage complete and surface the existing next packet; otherwise create a bounded correction/re-review pair.
- Non-goals: Do not edit reviewed implementation code, change art/gameplay, redesign the Workbench, widen sparse/LFS scope, or add new CLI features beyond the correction boundary.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `operator-workbench-publish-readiness-recovery-review-corrections-2`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none`
- Next action: `Implement cycle-2 correction to bind publication paths to the selected animation and reject tampered or changed Workbench manifests before canonical mutation.`
- Blockers or open questions: `R0-01 remains unresolved pending the cycle-2 correction and paired review.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `partial`
- Evidence: The direct CLI publisher bypass is removed. The new CLI smoke and four focused Workbench smokes pass. Review found that the shared publisher trusts mutable Workbench binding paths to construct both candidate writes and the publication allowlist, so an eligible art checkout can retarget a selected animation to another Operator source asset. The final revalidation reloads readiness but does not compare binding paths to the selected animation snapshot. R0-01 remains unresolved; bounded cycle-2 correction and review packets are created.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `low`
- What went wrong: The required regression covers checkout identity, dirt, dry-run, and normal scoped landing, but omits manifest path tampering.
- Root cause / contributing factors: Candidate paths and allowlist are both derived from mutable binding paths; readiness revalidation does not bind them to the selected animation.
- Prevention / pipeline improvement: Add a negative control that tampers with source/publish paths before invocation and during the pre-mutation window; validate exact selected-path ownership before mutation.
- Tooling / docs drift discovered: none
- Follow-up: `operator-workbench-publish-readiness-recovery-review-corrections-2`
- What worked: Fixture-backed CLI and four focused Workbench smokes provide broad evidence for the original checkout/readiness boundary.

## Independent Review

- Status: `findings`
- Review workstream: `review-operator-workbench-publish-readiness-recovery-review-corrections-1`
- Reviewed on main: `094be7ed98e492e1d0b68ec4dcd33e7fd1e5b967`
- Review modes: `code, architecture, workflow`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Blocking defects: `1`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `operator-workbench-publish-readiness-recovery-review-corrections-2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`

### Findings

- **R0-01** (`unresolved`, blocking correctness): the correction routes CLI publish through the shared service and closes direct invocation from coordination main, arbitrary/detached checkouts, and dirty art checkout. However, the shared service derives canonical targets and allowlist from mutable manifest binding paths, and final readiness revalidation does not bind those paths to the selected animation. A modified Workbench manifest can authorize publication of another Operator source asset. See the archived correction packet for source locations and the bounded evidence chain.
