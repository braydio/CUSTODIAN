# Operator 3D Workbench Intake V1 — Claude summary

Workstream: `operator-3d-workbench-intake-v1` · Branch: `agent/operator-3d-workbench-intake-v1`
Base: `origin/main@a16fb3ece74f` (the brief's reviewed base)

## Result

- Walking (`unarmed/locomotion/walk_01`, 25f, pivot 50,107) and Running (`unarmed/locomotion/run_01`, 15f, pivot 62,108) are registered as read-only `operator_3d_80` candidate sessions: 2 imported animations, 16 directional sessions, 320 validated RGBA 160×160 frames.
- The Workbench browser shows all 16 directional rows (`CANDIDATE_READY`). Preview loads the staged pixels for each direction and plays them. Validation is read-only. Edit, migration, FX, polish, copy, timeline, motion, comparison, transition and publish are disabled in the UI and refused in the service layer.
- Runtime assets, canonical art, and Godot gameplay files are unchanged. Staged frames and candidate sessions live only in gitignored paths.

## Changed files

- `custodian/tools/character3d/` — imported from `agent/character3d-pipeline-reproducibility-v1` (commits `973bd353e`, `3623c9fb3` only). Stager gained `--actions`, `--skip-50ppm`, and a per-run receipt.
- `custodian/tools/operator/operator_3d_candidate_intake.py` — new. Plan, apply (transactional, idempotent), verify.
- `custodian/tools/operator/ui/service.py`, `ui/app.py`, `ui/state.py`, `animation_preview.py`, `animation_workbench.py` — 3D projection, session, preview, guards.
- `custodian/tools/operator/operator_art_worktree.py` — `custodian/tools/character3d` added to the sparse profile.
- `custodian/tools/validation/test_operator_3d_candidate_intake.py` — new, 45 tests.
- `custodian/tools/validation/test_character3d_tools.py` and `validation_manifest.json` — character3d unit tests registered.
- `custodian/tools/validation/operator_workbench_ui_smoke.py` — 3D placeholder rows excluded from legacy filter counts, and asserted separately.
- Docs: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`, `custodian/tools/operator/README.md`, `custodian/docs/ai_context/FILE_INDEX.md`.

## Verification

- `test_operator_3d_candidate_intake.py`: 45 tests OK.
- `test_character3d_tools.py`: OK (1 skipped, pre-existing).
- Regression smokes all pass: `operator_workbench_ui_smoke` (including its Textual pilot), `operator_animation_targets_smoke`, `operator_animation_workbench_smoke`, `operator_workbench_mirror_publish_smoke`, `operator_animation_plan_smoke`, `operator_workbench_production_queue_smoke`, `operator_animation_preview_timeline_smoke`, `operator_animation_transition_smoke`, `asset_workbench_ui_smoke`, `operator_animation_contract_report_smoke`, `operator_animation_timing_smoke`, `operator_art_worktree_smoke`.
- Live acceptance against the real staged frames in `~/Projects/CUSTODIAN-operator-art`: the headless Textual pilot opens the 3D walk session in preview, plays it (frame 0 → 15), refuses edit and publish, and locks the source. A contact sheet of all eight directions for walk and run was checked visually.
- Intake commands from the brief were run as written: plan, apply (16 written), re-apply (0 written, all UNCHANGED), verify (ok, 16 VERIFIED).

## Decisions and deviations

- Branch base: the implementation commit sits directly on `origin/main@a16fb3e` (rebased from local `main`). Local `main` has four unpushed commits and had diverged, so they are not on this branch.
- Character3d tooling was copied from the stale branch, not merged. Only its two tooling commits came over. Landing it on `main` still needs its normal review and publication path.
- Sparse profile: `custodian/tools/character3d` was added in this branch, not after landing as the brief specified. The art checkout needs it to run the stager from the checkout.
- Browser: unregistered 3D directions appear as `MISSING` placeholders (16 rows, always). This is what the brief requires. It means legacy filter counts that match `locomotion` or `run_01` now include them, so the smoke asserts legacy rows separately.
- Transitions exclude `operator_3d_80` candidates.
- Discovery checks each candidate's registration, its stage metadata hash, and frame file presence. Per-frame SHA-256 is verified on preview load and by `--verify`, not on every browser refresh.
- `dependency_status` is GREEN only when the registration and stage metadata checks pass.

## Not done

- OPUI launch from the art checkout (`operator ui`): the art checkout is on `workbench/operator-art` and does not yet contain this UI code. It needs landing and an art-checkout sync first. The acceptance demo was run headlessly from this branch against the art checkout's staged data.
- Root marker overlay on the preview: optional in the brief, not implemented.
- Idle (`unarmed/posture/idle_relaxed_01`) authoring and the Blender source: not started. This is the next phase.
- Landing to `main`, review, and any runtime or Godot integration.
- Clarification: the `Dropbox` review publish and handoff steps were not needed for this slice.

## Open decisions

- Whether `[skip render]` is the right tag for this commit (no render or Godot output changes).
- Whether the candidate registration check should also verify frame hashes on each refresh. The current choice trades completeness against browser-refresh cost.
