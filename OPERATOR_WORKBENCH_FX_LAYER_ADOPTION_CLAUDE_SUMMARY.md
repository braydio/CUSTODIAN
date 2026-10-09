# Operator Workbench FX Layer Adoption — Implementation Summary

## Result

Implemented the bounded human authoring path for adding or replacing semantic FX on an existing Operator animation. A saved top-level Aseprite layer named `vfx` or `fx` is discoverable but remains unbound until explicitly adopted. Adoption preserves the editor layer name and creates a schema-derived direct CREATE or REPLACE contract. Workbench UI and CLI use the same backend; unsaved live-only candidates remain visible but cannot be adopted. Publish review snapshots the selected targets, mirror promotion defaults off, and opted-in counterpart changes join the same transaction/rollback. Clean workbenches detect canonical binding-set drift and safely refresh; edited workbenches retain their pixels.

## Evidence

- `operator_animation_workbench_smoke.py`: real Aseprite fixture saved a `vfx` layer, explicitly adopted it, then verified exact RGBA preview pixels and transparent frames before publication.
- `operator_workbench_mirror_publish_smoke.py`: CREATE/REPLACE, successful normalization to real file/pixel hashes, direct-only default, explicit mirrored CREATE/REPLACE, downstream rollback, CREATE collision, and changed-REPLACE-source refusal.
- `operator_workbench_ui_smoke.py`: service projection and Textual pilot including unsaved candidate refusal and explicit F-key adoption.
- `operator_art_worktree_smoke.py`: PASS; its fixture remote briefly advanced during landing and the harness retried successfully.
- `godot_import_preflight_smoke.py`, `operator_runtime_spriteframes_import_smoke.py`: PASS; SpriteFrames fixture imported 588 textures.
- `operator_modular_defense_ranged_smoke.gd`: exit 0 and printed PASS, with existing missing imported-resource/animation diagnostics in its output.
- Final `run_validation.py --changed --json`: PASS, 24 selected, 24 passed, 0 failed, 0 timed out, 0 skipped, 0 infrastructure errors (`/tmp/custodian-fx-validation.json`).
- `git diff --check` and Python parse checks: PASS.

## Changes

The backend now inspects saved Aseprite layer metadata without making it publication authority, validates explicit adoption against the selected animation context and schema, supports CREATE and REPLACE source contracts, protects against changed targets, atomically creates outputs without overwriting concurrent files, and normalizes the manifest only after successful publication. UI shows unbound saved layers and unsaved live-only state, exposes explicit adoption, and reviews exact target state before publish. CLI adds `operator anim layer adopt` and defaults counterpart promotion off. Focused fixture and UI smokes cover the new route. The Workbench and Art Agent specs plus current-state documentation state that this is FX adoption for existing animations only; it does not enable general semantic animation creation or autonomous Art Agent layer creation.

## Negative controls and deferred work

Unknown and reference layers remain non-adoptable. Unsaved live-only layers cannot be adopted. CREATE target collisions and changed REPLACE sources fail closed. Existing semantic animation identity, timing, frame/canvas contracts, and gameplay behavior remain authoritative. General head/cape/weapon adoption, new semantic animation creation, and autonomous Art Agent `create_layer` remain deferred.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The focused modular-defense smoke emitted existing missing-resource/animation diagnostics despite returning exit 0 and its pass marker; the art worktree fixture remote advanced during one landing attempt and its built-in retry recovered.
- Root cause / contributing factors: The focused fixture loads adjacent content with unresolved import artifacts; the art smoke deliberately exercises landing races in its isolated fixture.
- Prevention / pipeline improvement: Preserve both diagnostic caveats in the evidence record; no unrelated runtime/resource changes were made.
- Tooling / docs drift discovered: None.
- Follow-up: review-operator-workbench-fx-layer-adoption
- What worked: Schema-derived contracts and explicit adoption marker allowed UI/CLI to share the publish authority while preserving existing Workbench review and rollback.

## Next Handoff
- Next workstream: review-operator-workbench-fx-layer-adoption
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Start the paired post-land review in a fresh reviewer context.
- Blockers or open questions: none
