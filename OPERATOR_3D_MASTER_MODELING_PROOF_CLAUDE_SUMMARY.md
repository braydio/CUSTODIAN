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
