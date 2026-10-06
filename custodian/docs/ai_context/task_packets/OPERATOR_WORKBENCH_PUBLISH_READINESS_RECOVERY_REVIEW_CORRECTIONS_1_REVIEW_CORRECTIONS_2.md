# CORRECTION: OPERATOR WORKBENCH PUBLISH READINESS — CYCLE 2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1-review-corrections-2`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-operator-workbench-publish-readiness-recovery-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-workbench-publish-readiness-recovery-review-corrections-1-review-corrections-2`
- Review cycle: `2`
- Max automatic review cycles: `2`
- Reviewed main: `094be7ed98e492e1d0b68ec4dcd33e7fd1e5b967`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include this exact Authoring chat URL in the correction and paired-review summaries and final handoff.
- Parent implementation: `operator-workbench-publish-readiness-recovery`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md`
- Parent correction: `operator-workbench-publish-readiness-recovery-review-corrections-1`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_REVIEW_CORRECTIONS_1.md`
- Parent review: `review-operator-workbench-publish-readiness-recovery-review-corrections-1`; `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_REVIEW_CORRECTIONS_1.md`
- Findings addressed: `R0-01`
- Affected acceptance: A CLI publication can mutate and land only the exact canonical assets for its selected animation, through the dedicated checkout, readiness, allowlist, and approved landing path.
- Goal: Close the remaining manifest-path retargeting path in R0-01 before any unrelated Operator source can be mutated or landed by a selected Workbench publication.
- Completion boundary: Bind every publication target to the selected Workbench identity and its trusted source index before mutation. Revalidate the same binding immediately before mutation. Reject malformed, substituted, or changed source/publish paths before the backend changes canonical files. Preserve the cycle-1 checkout, readiness, dry-run, and stale-source boundaries.
- Current measured state: Cycle 1 routes non-dry-run CLI publication through `WorkbenchService.publish(..., prepare=True)` and `publish_to_main`. However, `ui/service.py` builds `canonical_paths` from mutable `workbench.json` binding paths and derives `allowlist` from those same values. `animation_workbench.publish()` writes to those paths. Final revalidation reloads readiness but does not compare the current binding path set with the selected animation's trusted plan/source index. `publication_allowlist()` adds provided paths and sidecars without independently validating their selection ownership. The cycle-1 fixture does not tamper with the manifest paths.
- Evidence: `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`; archived correction review receipt; `custodian/tools/operator/ui/service.py`; `custodian/tools/operator/animation_workbench.py`; `custodian/tools/operator/operator_art_worktree.py`; `custodian/tools/validation/operator_cli_publish_boundary_smoke.py`.
- Task-specific authority: The parent implementation and review packets; the cycle-1 correction packet and review receipt; `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; the current source-index, Workbench plan, and publication allowlist contracts.
- Work surface: `custodian/tools/operator/ui/service.py`; narrow Workbench model/backend validation if needed; `custodian/tools/operator/operator_art_worktree.py` only if path-scope validation belongs there; focused CLI publication regression coverage and validation manifest only if needed.
- Change: Derive an expected per-binding path set from trusted selected-animation planning/source-index authority. Validate source and publish contract paths against it before readiness preparation and again immediately before source mutation. Ensure changed manifest identity/path state cannot change the paths that are authorized for publication. Keep generated runtime/catalog outputs limited to the existing narrowly defined derived outputs. Do not rely on a post-mutation unexpected-path check as the first point of rejection.
- Preserve: Cycle-1 coordination-main/arbitrary-checkout rejection; readiness and safe preparation; exact selected-path upstream conflict checks; transaction rollback and `RECOVERY_REQUIRED`; pending-land retry; stale-source override limited to freshness only; dry-run; current approved `land_main.py` authority; UI publication behavior; no user-worktree mutation beyond safe preparation.
- Non-goals: No art or gameplay changes, new CLI features, Workbench redesign, expanded Operator scope, general allowlist redesign, or changes to sparse/LFS policy.
- Required correction:
  1. Reject a Workbench binding whose source/publish path does not match the selected animation's trusted planned canonical path before any canonical mutation.
  2. Revalidate manifest selection identity and the exact source/publish path set immediately before the backend mutation; a changed manifest must fail closed before `animation_workbench.publish()` runs.
  3. Add CLI-level negative controls for a manifest rebound to another valid Operator source path with internally consistent freshness metadata, and for path substitution between initial selection/readiness and the final pre-mutation check. Assert no publish call, unchanged source/runtime hashes, HEAD, and Git status. Keep the normal eligible selected-path publication positive control.
- Acceptance:
  1. A valid dedicated art checkout cannot use a tampered Workbench manifest to mutate or land a different animation's Operator source/runtime assets.
  2. A manifest path change after initial selection but before the immediate pre-mutation boundary is rejected before the canonical-mutating backend runs.
  3. The trusted path set and allowlist represent the selected animation, not merely paths read from the manifest; changed staged paths remain an additional fail-closed check.
  4. Cycle-1 controls for coordination main, detached/arbitrary checkout, dirty art checkout, dry-run, stale override, normal selected publication, and four focused Workbench smokes remain green.
  5. No canonical art/gameplay changes are part of the correction.
- Validation: Run `operator_cli_publish_boundary_smoke.py` first with the two new tampered-manifest controls, then `operator_art_worktree_smoke.py`, `operator_workbench_mirror_publish_smoke.py`, `operator_workbench_ui_smoke.py`, `operator_animation_workbench_smoke.py`, and `git diff --check`. Use fixture remotes only; never publish test data to the real project remote.
- Task overrides: `none`.
- Deferred: Any unresolved correction-worthy defect after paired cycle-2 review requires `human_required`; do not create an automatic cycle 3.

## Handoff

- Next action: Complete the paired cycle-2 review on fresh main after correction 2 lands.
- Best starting files: `custodian/tools/operator/ui/service.py`; `custodian/tools/operator/animation_workbench_model.py`; `custodian/tools/operator/animation_workbench.py`; `custodian/tools/validation/operator_cli_publish_boundary_smoke.py`.
- Blockers or open questions: None beyond the acceptance and validation above.
