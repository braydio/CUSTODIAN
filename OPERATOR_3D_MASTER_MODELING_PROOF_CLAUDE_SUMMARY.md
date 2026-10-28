# Operator 3D master modeling proof - summary (exp-006 phase)

Workstream: operator-3d-master-modeling-proof-v1 (branch `agent/operator-3d-master-modeling-proof-v1`, **not merged to main**).
Return reminder: the project-root checkout `~/Projects/CUSTODIAN` is on clean `main`; this art work lives only in its worktree.
Authoring chat: not recorded in the packet.

Art source-work only. No runtime, operator.gd, selector, manifest, SpriteFrames, canonical idle or main changes. No candidate selected or approved; no best_candidate.json.

## exp-006 (capeless), frozen, visual approval pending
- Versioned generator: `model_version: 6` -> `scripts/generate_mesh_v6.py`; exp-001..005 regenerate byte-identical (SHA256 checked), frozen hashes re-verified (`scripts/verify_frozen.py`).
- Changed: no Cloak__ meshes (0 of 79 parts); forward-peaked hood shell + dark face recess, no ring/halo; three overlapping flattened plates per shoulder with rim trim; tapered arm/leg links; 12 folded tunic panels (front, front-side, back, back-side) with gold edge trim; boots with sole, heel stack, instep, toe cap, sole bottom exactly on Z=0.
- Objective (Blender-evaluated sole meshes, `walk_audit.json`): both soles at 0.0 m when planted (previous ~2 cm hover gone); 10 / 9 planted frames L / R, alternating; planted foot body-frame step constant (0.0 mm/frame deviation) - reported separately from IK reach error (0.0); F15->F01 foot delta 0.098 m equals the largest inner step, no seam jump. Heights 82-87 px; root (64,106) by camera construction (alpha-bottom is not a registration invariant). 8 cameras correct, facing E=right.
- Silhouette IoU is triage only: 8-dir mean 0.62 vs exp-005 0.68 - slightly worse by that metric.

## Remaining defects (honest)
Hood is a tall spire/cone, not the source's rounded cowl; pauldron plates still catch chrome-like highlights; arms/legs read thin next to the source's bulk; gold appears as dotted edge segments, not continuous trim; tunic panels read as flat dark sheets; no source value/highlight language. NE walk alternates and loops, but the pose is stiff.

## Evidence
Dropbox: /CUSTODIAN/visual_review/operator-3d-master/20261027T110803Z/REVIEW_MANIFEST.json (cleanup after review: command in the manifest). Local: `review_pack/`, `experiments/exp-006/`. Tooling: `TOOLING_SETUP_RECEIPT.md`. Cadence 15 fps / 67 ms GIF is provisional, not canonical.

## exp-007 (hood-only), frozen, visual approval pending
Only `Head__hood_shell` vertices differ from exp-006 (verified per part); `hood_profile_rings` override added with exp-006 default (exp-002..006 regenerate byte-identical). Rounded dome profile from TASK_007 used unadjusted. Mean IoU 0.648 vs 0.637 (triage only). Cloak__ = 0; soles 0.0 m planted; walk unchanged. Dropbox: /CUSTODIAN/visual_review/operator-3d-master/20261027T115104Z/REVIEW_MANIFEST.json (exp-006 walk GIF stays in 20261027T110803Z). Open and unchanged: chrome pauldrons, thin limbs, dotted gold trim, flat tunic, stiff walk, world-space skating not proven (zero body-frame variation only).

## Task 008 camera-elevation sweep (diagnostic only; no experiment, no freeze, angle NOT chosen)
Unchanged exp-007 mesh, neutral rest, ortho, same scale/shift/lights, root projected (64,106) at every angle. Elevations are degrees ABOVE horizon. 30 deg control matches existing exp-007 renders (E: one pixel off by one colour level). Frozen exp-007 .blend hash unchanged. Sheet: `review_pack/camera_calibration_exp007.png`; metrics `..._metrics.json`; script `scripts/render_camera_elevation_sweep.py` + `build_camera_sheet.py`.
Fixed-scale result: S height 85/79/70/61 px at 30/40/50/60 (source 84); 5-dir mean IoU 0.656/0.586/0.504/0.391 - IoU falls only because steeper views shrink the body at fixed scale; not a basis for choosing. Higher elevations show hood crown, pauldron tops and boot tops more like the source but need a larger px/m to hold 84-88 px (a projection decision, not a body change).
3D anatomy (mesh, metres): height 2.075; shoulder-plate span 1.336 (0.64 of height) vs belt 0.602; hood 0.575 tall (0.28 of height); ground-to-thigh-top 1.031 (0.50). The broad shoulder read is in the mesh itself, independent of camera.

## Task 009 (projection 45° / 50 px/m + exp-008 shoulder-only)
- Working projection (provisional, not canon): 45° above horizon, 50 px/m, ortho 2.56, root (64,106). exp-007 at this projection: S 85 px, all-direction heights 79–90 (source 84–87), mean IoU 0.597 (triage only).
- Geometry gate passed: top-plane/crown visible, shoulder plates remain oversized (blue lobes in overlay).
- exp-008: `shoulder_plate_scale` 0.55 about shoulder joint (gated; exp-007 regenerates byte-identical). Plate span 1.336→1.068 m (0.644→0.515 of height). Height, belt, hood, legs unchanged; part count/QA identical except asset hash. Walk/IK/boots unchanged (planted dev 0.0, reach err 0.0). Mean IoU 0.610 at 45°.
- Open: arms/joint beads now read thin and exposed; tunic/belt/hood/gold-dotted trim/chrome highlight faults unchanged. No select-best. Return to clean `~/Projects/CUSTODIAN` on `main`.

## meshy-001 saved
- User's Meshy export saved as first imported candidate at `custodian/asset_drop/source_work/operator/operator_3d_master/meshy_candidates/meshy-001/` (compressed + decoded GLB, 8-dir 128/512 clay renders, scripts, README, SHA256SUMS). Untextured/unrigged; user is producing textures. Not approved, no runtime change. Return to clean `~/Projects/CUSTODIAN` on `main`.

## meshy-002 saved (textured)
- `model(3).meshy` reconstructed with the user's script (user confirmed Meshy permission; only copies after account deletion), decoded, imported in Blender (UVs + 3 textures), rendered 8-dir at 45°/50 px/m. Saved at `.../operator_3d_master/meshy_candidates/meshy-002_textured/`. Not approved; no runtime change. Return to clean `~/Projects/CUSTODIAN` on `main`.

## Comparison + one-command pipeline
- `scripts/asset_pipeline/run_asset.py` (uv inline deps; see its README): .meshy/GLB -> decode -> Blender ground+common scale -> 8-dir 45°/50 px/m renders -> sheet vs locked canonical. Ran on model(3): scale 1.105, heights 85–91 px, mean IoU 0.668 (exp-008 at 45°: 0.610, not the same height basis). Output kept at `meshy_candidates/meshy-002_textured/normalized_45deg_85px/`. No approval/selection. Return to clean `~/Projects/CUSTODIAN` on `main`.

## Task 011 (freeze meshy-002 evidence; harden asset workflow)
- Verified meshy-002 bytes (LFS materialised; decoded sha256 b9c2f68d…; container e418978c…; canonical idle d4a6a5f5… OK — the task text's canonical sha had missing characters, real locked bytes verify).
- Published textured evidence (11 images/reports, retained) to Dropbox run `meshy002-textured-20261027T224145Z`; re-downloaded sha256 match 11/11. Material graph verified (sRGB base colour, Non-Color MR + normal, KHR_texture_transform → Mapping nodes); AgX default view transform noted. Mesh watertight (0 boundary edges, 27 non-manifold edges, 12 degenerate tris).
- Frozen: `locks/meshy-002_textured/FROZEN_CANDIDATE_MANIFEST.json` (`FROZEN_FOR_REVIEW_NOT_APPROVED`, 54 files), `verify` OK; no select-best, no approval.
- Workflow hardened (`run → verify → freeze → publish-review`), entrypoint `custodian/tools/iteration/asset_pipeline.py`, 43 unit tests (+1 Blender integration), path-filtered CI. Smoke on new candidate id reproduced the frozen figures exactly (scale 1.10542, 85–91 px, IoU 0.668; renders pixel-identical).
- Return to clean `~/Projects/CUSTODIAN` on `main`. No PR opened (needs a focused tooling-only branch).

## meshy-003_reduced_poly ingest (reduced-poly Meshy export)
- Source preserved (LFS) at `custodian/asset_drop/source_work/operator/operator_3d_master/source_inputs/meshy-003_reduced_poly/`; sha256 `656337c6…14238`.
- Pipeline run + verify OK; 10,367 tris (-99.17% vs meshy-002). Comparison in `meshy_candidates/meshy-003_reduced_poly/COMPARISON_VS_meshy-002.md`.
- Fixed hardcoded "1.25M-tri" geometry-proof caption. Tests: 43 OK (1 skipped), Blender integration OK; publisher test import error is pre-existing.
- Not approved, not selected, not uploaded to Dropbox. Return to clean `~/Projects/CUSTODIAN` on `main`.

## Task 012 — rigged Operator diagnostic (meshy-004_rigged)
- Inputs preserved (LFS, hashes match task) in `source_inputs/meshy-004_rigged/`. Motion: `REAL_RUN_CLIP_MISSING` (0 animations; MRC1 not decodable, high entropy, no parser).
- Cause of extremity stretch: mis-parented `Bone_0xx` joints (foot-level bones under hands/forearms; tabard bone under Head). Derivative reparent fixes boot/tabard leak (1.56 m -> 3e-7 m); residual hand-to-thigh edge stretch (topology) remains.
- Pipeline `run` is not valid for rigged GLBs (output discarded). Report: `rig_diagnostics/meshy-004_rigged/REPORT.md`.
- Tests: 43 OK (1 skipped), Blender integration OK. Not approved, not uploaded. Return to clean `~/Projects/CUSTODIAN` on `main`.

## Task 013 — hand/thigh deformation isolation + repair (meshy-004 iter-002)
- Task 012 evidence published (retained): `/CUSTODIAN/visual_review/operator-3d-master/meshy004-rig-iter1-20261027T2200Z/REVIEW_MANIFEST.json` (9 files, remote bytes verified).
- Cause: mixed hand/thigh weights (313 of 330 P1 outliers) plus 66 straddling hand/thigh triangles; no tiny-edge artifacts. Fix: detach the 66 triangles on duplicated verts + remove cross-chain weights. P1 max stretch 12.35x -> 3.44x, P3 3.11x -> 1.31x; P2/P4 unchanged; rest change 0.0006 mm.
- Exported rigged GLB (no animation) re-imported and replayed; matches. Pipeline now rejects skinned GLBs (exit 3). Tests: 45 OK (1 skipped), Blender integration OK.
- Report: `rig_diagnostics/meshy-004_rigged/REPORT_iter002.md`. Not approved/frozen. Return to clean `~/Projects/CUSTODIAN` on `main`.

## Task 014 Phase A — Running.fbx retarget proof (`RUN_MOTION_NEEDS_REPAIR`)
- Real clip ingested (22 frames @30fps, in-place, loop seam 0.0 deg; sha256 `ff821e18…e7e939`, LFS). Retargeted onto iter-003 rig (iter-002 + arm/torso contact fix); arms by joint-direction matching, constant +35.8 mm ground offset, cloth-chain follow 0.5.
- Whole-clip deformation: max stretch 6.4x, up to 11 edges >3x in a frame (17 of 22 frames), floating dark fragments visible near hips/hands (cause unconfirmed). Not promotable.
- Rig-aware 8-dir renderer (128/512, one scale, no root edits), GLB export/reimport replay 0.0016 mm. Tests: 45 OK (1 skipped), Blender integration OK. No Godot/runtime/main change; Phase B not started.
- Report: `rig_diagnostics/meshy-004_rigged/REPORT_run_iter001.md`. Return to clean `~/Projects/CUSTODIAN` on `main`.
