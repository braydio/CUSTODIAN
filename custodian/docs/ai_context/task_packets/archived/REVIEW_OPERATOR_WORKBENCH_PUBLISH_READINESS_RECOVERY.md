# REVIEW: OPERATOR WORKBENCH PUBLISH READINESS AND RECOVERY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-publish-readiness-recovery`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-publish-readiness-recovery`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-publish-readiness-recovery`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md`
- Reviewed main: `ca51381bf8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `21ffccb775b24ed3d8c7e8d7651acdd438a18017`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Goal: Independently verify that the landed Workbench publication hardening converts the recent serial Git/LFS/manifest/import failure chain into one bounded readiness/preparation contract without weakening source authority, sparse-checkout safety, validation, or user-work preservation.
- Reviewed implementation acceptance: Review the archived implementation packet's full acceptance contract, with special emphasis on clean-behind auto preparation, unknown-dirt preservation, `LAND PENDING` resume, local-only LFS handling (shared cache first, exact verified hydrated-checkout donor second, no network), sparse validation dependency proof, stale selected-manifest rejection before mutation, exact Godot metadata preimage restoration, clean-or-`RECOVERY_REQUIRED` failure postconditions, and unchanged scoped landing/allowlist authority.
- Review evidence: Reuse the implementation's fixture-isolated readiness classifications, publish transaction journals, exact before/after hashes, LFS network-negative controls, metadata-restoration receipts, UI readiness projections, successful publication fixture, changed-file validation report, and closing summary. Gather fresh evidence only where those artifacts do not prove an acceptance criterion.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in required acceptance. In particular, any automatic reset/stash/rebase, network LFS fetch, ambiguous file restoration, silent Workbench baseline rewrite, or widening of publication allowlists/sparse scope is correction-worthy. Route optional ergonomics and non-blocking messaging improvements to next-slice/deferred.
- Focused validation: Inspect the landed readiness/classification boundary and restoration predicates; rerun `python3 custodian/tools/validation/operator_art_worktree_smoke.py`, `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`, `python3 custodian/tools/validation/operator_workbench_ui_smoke.py`, and `python3 custodian/tools/validation/operator_animation_workbench_smoke.py`. Reuse the implementation's local-LFS and import-preflight evidence unless stale/insufficient. Run the smallest changed-file validation needed to confirm findings.
- Review focus:
  - Safe preparation must be strictly narrower than destructive Git cleanup.
  - Dirt classification and recovery decisions must use structured state, not error-string parsing.
  - The exact selected source baseline must be checked before mutation without stealing FX-adoption's broader binding-set ownership.
  - LFS must remain local-only and sparse dependency additions measured rather than broad. Cache materialization is preferred; a hydrated coordination/developer checkout is an acceptable donor only when the same relative path's SHA-256 and byte size exactly match the target LFS pointer. Hydration must be path-scoped to files already present/required by the sparse validation surface; an unscoped `git lfs checkout` that expands sparse-omitted content is a blocking defect. Mismatch, donor pointer, missing donor, or dirty bytes that do not match must fail closed; no network fetch is permitted.
  - Metadata restoration must require clean pre-state + proven transaction provenance + exact preimage; wildcard cleanup is a blocking defect.
  - Failure after mutation must end clean or with a complete durable `RECOVERY_REQUIRED` journal.
  - Blocked publication state must not make OPUI itself inaccessible: verify startup remains read-only/recovery-capable across pending receipt + divergence + sparse drift.
  - Pending publication recovery must not rely solely on exact HEAD. Rewritten history may reconcile only from stable path/blob/patch evidence, and any non-equivalent history must fail closed.
  - Saved-document/frame-contract reconciliation must preserve edited Aseprite bytes and never insert/drop frames implicitly; an obsolete pending migration may be cleared only with backup + equivalence proof.
  - Transaction errors must retain the first failing stage/error even when rollback fails later.
  - `RECOVERY_REQUIRED` may clear only after journal-owned files and checkout state are verified; marker deletion without proof is blocking.
  - The already-landed stale-warning Escape/Enter/click recovery must remain green and must continue rendering the exact backend error instead of masking it.
  - Successful publication must retain current source-conflict, allowlist, commit, pending-land, and landing guarantees.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings. Give each finding a stable cycle-scoped ID (`R<cycle>-<NN>`) and the required class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects and material acceptance-proof gaps create `operator-workbench-publish-readiness-recovery-review-corrections-<n>` plus its paired review packet. Do not patch reviewed implementation code.
- Non-goals: Do not redesign the Operator Workbench publisher, add FX-layer adoption, broaden sparse checkout beyond required dependencies, change Operator art/runtime/gameplay, or implement page-3 PREVIEW refresh hardening in the review workstream.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after `operator-workbench-publish-readiness-recovery` is complete and archived on `origin/main`.
2. Read root/local AGENTS, the archived implementation packet and closing summary, `OPERATOR_ANIMATION_WORKBENCH.md`, the current sparse-worktree publication code, and the implementation's durable transaction evidence.
3. Review the implementation against the authored acceptance, not merely the fact that one publish succeeds.
4. Start with the negative controls: startup with pending+diverged+sparse-drift state, rewritten pending-receipt commit with non-equivalent bytes, obsolete pending frame migration over a saved document, primary failure plus rollback failure, premature recovery-marker clearing, unknown dirt, unavailable LFS after both cache and verified-donor lookup, donor hash/size mismatch, donor-still-pointer, stale manifest, ambiguous metadata churn, injected downstream failure, and pending-land resume. Also prove the positive exact-donor case leaves the target Git-clean.
5. Verify exact byte preservation for user/unknown inputs and exact restoration for eligible machine-generated metadata.
6. Verify the successful path still stages only the existing allowlist and lands only through the approved Operator publication handoff.
7. Record findings/receipt and scaffold bounded correction + re-review only when the correction threshold is met.
8. Complete/archive through the normal paired-review lifecycle.

## Human Decision Gate

No subjective art or visual baseline is in scope. If a policy question arises about whether an ambiguous file class may be auto-restored, treat ambiguity as fail-closed and escalate rather than inventing a broader cleanup policy.

## Handoff

- Next workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none`
- Next action: `Claim the bounded CLI publication-boundary correction after this review archives.`
- Blockers or open questions: `none`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The review exposed a documented CLI publication route that bypasses the new readiness and isolated-checkout boundary; the full-checkout LFS preflight also could not enumerate a missing local LFS object.
- Root cause / contributing factors: Review coverage exercised the UI service and fixtures but not the production CLI dispatch; this coordination clone lacks one LFS object required by `git lfs ls-files`.
- Prevention / pipeline improvement: Add CLI-level boundary and end-to-end scoped-landing coverage to the correction; use the correct sparse art checkout or durable exact-head proof for import preflight.
- Tooling / docs drift discovered: `operator anim publish` remains documented but bypasses the service-owned publication contract.
- Follow-up: `operator-workbench-publish-readiness-recovery-review-corrections-1`
- What worked: The four required Workbench smoke scripts passed and graph-guided caller tracing identified the untested CLI entrypoint.

## Independent Review

- Status: `findings`
- Review workstream: `review-operator-workbench-publish-readiness-recovery`
- Reviewed on main: `21ffccb775b24ed3d8c7e8d7651acdd438a18017`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Blocking defects: `1`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_CLAUDE_SUMMARY.md`
- Follow-up workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1`

### Findings

- **R0-01** (`blocking correctness`, publication boundary/workflow; affected acceptance: publication is permitted only from the dedicated `workbench/operator-art` checkout, uses the structured readiness/preparation gate, and lands only through the existing scoped publication authority): the documented CLI entry point bypasses that boundary. `custodian/tools/operator/operator_cli.py:58` calls `animation_workbench.publish(...)` directly. That function has no checkout-identity or readiness/preparation guard and replaces canonical source paths at `custodian/tools/operator/animation_workbench.py:463-476`; unlike `WorkbenchService.publish`, the CLI does not route through `operator_art_worktree.publish_to_main` (`custodian/tools/operator/ui/service.py:680-705`). A clean coordination-main invocation can therefore mutate canonical files without the dedicated art checkout, dependency readiness, scoped staging, or approved landing handoff. Correction required; reviewed implementation code was not changed.

### Verification Performed

- `python3 custodian/tools/validation/operator_art_worktree_smoke.py` — PASS.
- `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` — PASS.
- `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` — PASS; optional Textual pilot skipped because Textual is not installed.
- `python3 custodian/tools/validation/operator_animation_workbench_smoke.py` — PASS.
- `python3 custodian/tools/pipelines/godot_import_preflight.py --project-dir custodian` — could not complete in this full coordination checkout: Git LFS reported missing object `df9378d1c7b5ada8dc967939c275f6f2cb5abe94`. The implementation closing summary records preflight passing after verified local materialization; this review did not treat the environmental failure as a product finding.
- `git diff --check` — PASS after review-artifact authoring.
