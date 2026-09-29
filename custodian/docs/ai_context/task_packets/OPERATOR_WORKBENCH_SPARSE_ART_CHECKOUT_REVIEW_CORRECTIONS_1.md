# CORRECTION: OPERATOR WORKBENCH SPARSE ART CHECKOUT REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Status: `ready`
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
- Deferred: Any unrelated Godot import metadata drift discovered during validation.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `none`
- What went wrong: `pending`
- Root cause / contributing factors: `pending`
- Prevention / pipeline improvement: `pending`
- Tooling / docs drift discovered: `pending`
- Follow-up: `pending`
- What worked: `pending`
