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
