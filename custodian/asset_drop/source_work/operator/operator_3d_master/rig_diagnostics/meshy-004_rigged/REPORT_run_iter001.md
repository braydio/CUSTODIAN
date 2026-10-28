# Operator run proof (Task 014 Phase A): `operator_run_mixamo_iter001` - **EXPERIMENTAL_UNAPPROVED, status `RUN_MOTION_NEEDS_REPAIR`**
Not approved, not selected, not frozen, no runtime/Godot change. FPS is provisional (source 30 fps).

## Motion (real, not synthetic)
`Running.fbx` (sha256 `ff821e18...e7e939`): 22 keyed frames @30 fps, 65 Mixamo bones, **in-place**, loop seam 0.0 deg (frame 22 == 1, so loop = frames 1-21, 0.70 s). All 25 target `mixamorig:` bones matched by name; 40 FBX-only bones (fingers etc.) ignored; 17 Meshy-only bones have no counterpart.
Retarget (`scripts/rig_diag/retarget_run.py`): world-space delta for spine/legs/head; **arms by joint-direction matching** (the clip is T-pose, our rig A-pose: a plain world-delta first run overshot and raised the arms); wrist keeps the rest relation to the forearm (no wrist motion transferred); hips translation x0.9193; one constant hips-height offset +0.0358 m (planted foot otherwise 3.6 cm under ground); Meshy-only cloth chains (`Bone_004-013`) follow their reference bone at 50% (heuristic, not from the clip). Rig used: iter-002 plus new **iter-003** (arm<->torso contact detach+reweight below z=1.25 m: 60 triangles detached, 1162 vertices reweighted, 0 mm rest change, 10,367 triangles).
Baked 6468 keys / 294 fcurves on action `operator_run_mixamo_iter001`.

## Whole-clip deformation (21 frames sampled; rest edge lengths vs posed)
| | iter-002 rig | iter-003 rig (current) |
|---|---|---|
| max edge stretch | 4.88x | 6.44x (frame 16) |
| max p99.9 | 3.19x | 2.56x |
| max edges >1.5x in a frame | 408 | 282 |
| max edges >3x in a frame | 35 | 11 |
Frames with any >3x edge: 17 of 22 (arm-swing phases, frames 2-9 and 12-20). Only ~40 distinct edges ever exceed 3x; they sit at waist height where arm bones and Hips/Spine/belt-cloth bones share weight (e.g. edge rest 24 mm, weights Hips .71 vs RightArm .46).
Other checks: loop seam vertex displacement 0.0016 mm; ground: clip min z -2.7 mm (rest 0), max z 1.71 m; hand region spread 0.38-0.52 m (rest 0.39); hand penetration into non-arm body: 0 vertices at the 5 sampled frames (coarse test: hand region vs non-arm faces within 2 cm); foot skating **not conclusive** (right foot stance speed 3.9 m/s over 2 frame pairs, left foot no usable stance pair); tabard/head independence not separately quantified beyond edge stretch; heel/toe/sole behaviour and shoulder/hip geometry were not checked individually.

## Defects blocking promotion
1. Visible **small floating dark fragments** near hips/hands in several frames (see `run_4dir_512_contact.png`, e.g. S/N frame 13, SE frames 1 and 21). Cause **not confirmed**; most likely the detached former contact patches from iter-002/003 (hidden inside hand/thigh and arm/torso contact at rest, exposed once limbs separate). A ray test to check this was inconclusive (my island definition matched 1,860 triangles).
2. ~10 persistent >3x edges (max 6.4x) during arm swings.
3. Cloth-chain follow factor 0.5 is a guess; retarget is not twist-accurate at the wrist.
Next repair step (not done): tag and remove or re-attach the detached patches only if a rest-pose visibility test shows they are hidden; reweight arm/belt boundary vertices.

## Rig-aware render (separate from static `asset_pipeline.py`, which rejects skins)
`scripts/rig_diag/render_rigged.py` + `build_run_evidence.py`: 45 deg, 50 px/m ortho, root (64,106), 8 unmirrored directions, ONE scale x1.23547 fitted from the REST-pose S view to 85 px (rest height 1.7 m; this rig is shorter than meshy-003's 1.90 m raw), grounding/centring fixed from rest (no per-frame root edits or zoom). Native 128 px and independently rendered 512 px; AgX view transform. S-view silhouette height over the clip 65-90 px (crouch/airborne). No idle IoU is used for moving poses.

## Export / re-import
`run_iter001/operator_run_mixamo_iter001.glb` sha256 `8f2dab9bbb60a036ade0a1125619050f84e7cdc15e24ba3ddabd3328abdc7b03` (47,296,956 B): action `operator_run_mixamo_iter001`, 42 bones, 10367 tris, UV, 4096 textures; clean re-import replay at a mid-clip frame differs from the .blend by 0.0016 mm max. (The glTF importer sets 24 fps; timing 22 frames = 0.70 s is preserved in seconds.) `.blend` sha256 in `SHA256SUMS`.
