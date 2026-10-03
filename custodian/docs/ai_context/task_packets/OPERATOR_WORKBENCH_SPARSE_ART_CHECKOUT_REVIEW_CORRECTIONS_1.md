# CORRECTION: OPERATOR WORKBENCH SPARSE ART CHECKOUT REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-workbench-sparse-art-checkout`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-workbench-sparse-art-checkout-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `dfaf9e269`
- Parent implementation: `operator-workbench-sparse-art-checkout` — `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md`
- Parent review: `review-operator-workbench-sparse-art-checkout` — `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md`
- Findings addressed: `R0-01`
- Affected acceptance: The sparse profile must support Workbench publication's mandatory Godot modular-layer validation, and missing-resource failures block acceptance.
- Current defect/evidence: The tracked east and west `block_hold_01` FX `.import` sidecars contain `valid=false` and no remap `path`/`dest_files`. Both source PNGs exist and are valid, but Godot fails to load them from the sparse profile; `operator_modular_layers_smoke.gd` then fails while loading the Operator actor.
- Goal: Restore valid Godot import metadata for the two published `block_hold_01` FX textures so the mandatory Workbench validation succeeds from a fresh sparse checkout.
- Completion boundary: Repair only the two affected import records and any directly required import-generation step. Do not change the PNG art, sparse path profile, publication allowlist, or unrelated generated imports.
- Current measured state: Real sparse checkout has 9,665 of 37,307 tracked paths materialized before Godot cache generation. The required modular-layer smoke fails on the two tracked FX texture references; Python Workbench, UI, mirror-publication, compatibility, and contract-report checks pass.
- Evidence: Parent review finding `R0-01`; `custodian/content/sprites/operator/runtime/animations/unarmed/defense/block_hold_01/operator__fx__unarmed__defense__block_hold_01__e__5f__96.png.import`; corresponding west-facing sidecar; `operator_runtime_frames.tres`; `operator_modular_layers_smoke.gd`.
- Task-specific authority: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; Godot import metadata and the existing Operator Workbench publication validation contract.
- Work surface: The two named `.import` sidecars, the minimal source/import command needed to produce them, and focused sparse-worktree validation.
- Required correction: Regenerate or repair both import records so they contain valid Godot remap data and resolve to imported textures. Verify that a fresh sparse worktree can import the project and complete `operator_modular_layers_smoke.gd` without missing-resource or Operator script-parse errors.
- Preserve: PNG bytes, canonical source/runtime naming, all other import metadata, worktree-local sparse configuration, exact publish allowlist, safe FF-only synchronization, ignored `.ai` state, and the no-network LFS policy.
- Non-goals: Do not widen sparse patterns to mask invalid import metadata, weaken or skip the modular-layer smoke, edit unrelated `.import`/`.uid` files, or change Operator art/runtime code.
- Acceptance:
  1. Both tracked `.import` sidecars have valid remap metadata and no `valid=false` marker.
  2. On a fresh sparse profile with locally cached required LFS objects, Godot import succeeds and `operator_modular_layers_smoke.gd` exits successfully without missing-resource or Operator script-parse errors.
  3. `operator_art_worktree_smoke.py`, `operator_workbench_ui_smoke.py`, `operator_animation_workbench_smoke.py`, and `operator_workbench_mirror_publish_smoke.py` remain green; no unrelated tracked file is changed by the correction.
- Validation: Run the two focused Operator FX import/actor checks first, then the four named Workbench smokes, compatibility-resource `--check`, animation-contract report, and `git diff --check`. Use only local LFS objects; do not broaden validation into an actor sweep.
- Task overrides: `none`
- Deferred: Re-run fresh sparse-profile acceptance with the required locally available LFS resources. Correct the stale UI smoke message assertion in its owning Workbench task. Any unrelated Godot import metadata drift remains out of scope.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `no`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Both tracked FX `.import` files on current `main` contain valid remap paths and `dest_files`, with no `valid=false`; the source PNG bytes are unchanged; `operator_modular_layers_smoke.gd` passes from the full checkout. Acceptance remains open because the sparse-profile smoke could not complete with the locally available LFS set, and `operator_workbench_ui_smoke.py` has a stale publish-block-reason assertion.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: Godot 4.7 import in the persistent sparse art checkout rewrote 1,561 tracked `.import` sidecars; those edits were restored. Sparse smoke validation then stopped on missing LFS-backed world resources. The UI smoke exposed a stale expected message.
- Root cause / contributing factors: The sparse checkout did not have every LFS object needed by the project's autoload dependency graph, and the UI smoke still asserts wording superseded by current checkout-block behavior.
- Prevention / pipeline improvement: Run Godot import validation in a disposable, version-matched checkout with required local LFS objects materialized; update the UI smoke assertion in its owning Workbench scope.
- Tooling / docs drift discovered: The existing sparse art checkout is behind `origin/main` and lacks required cached LFS content; the UI smoke's expected message differs from `WorkbenchService.publish_preview()`.
- Follow-up: `manual-follow-up`
- What worked: Full-checkout modular-layer and the non-UI Workbench regressions passed.
