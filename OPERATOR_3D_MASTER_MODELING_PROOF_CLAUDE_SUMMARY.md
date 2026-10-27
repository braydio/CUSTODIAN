# Operator 3D master modeling proof - summary

Workstream: operator-3d-master-modeling-proof-v1 (branch `agent/operator-3d-master-modeling-proof-v1`, **not landed on main**)
Return reminder: the project-root checkout `~/Projects/CUSTODIAN` is on `main` (clean); this work lives only in its own worktree.

Art source-work only. No operator.gd, sprite selector, manifest, SpriteFrames, promotion or runtime change. No art approval claimed.

## Verified
- Both LFS source hashes matched from real bytes (design lock `41782240...`, idle `d4a6a5f5...`).
- Blender 5.2.3 LTS ran the builder; real .blend + renders exist for every experiment.

## What happened
- exp-001 (unmodified builder): ran, exit 0, **unusable**: character lying down (Z-up mesh written as Y-up glTF), vertex colours lost, off-contract framing, E/W cameras mirrored. Frozen and kept as REJECTED.
- Builder fixed (`scripts/create_blend.py`; old one kept as `create_blend_v1_exp001.py`): upright guard, colour shaders, facing-correct camera azimuths, native 128 frame root (64,106), camera-following lights, bone-local hip keys, level-locked boots, neutral renders without IK.
- exp-002 baseline (v001 shape, pipeline fixed), exp-003 reference-driven reshape, exp-004 stocky contrast, exp-005 = exp-003 + stronger walk + hood ring. All frozen; see `CANDIDATES.md` for hashes.

## Honest evaluation (exp-005 vs source idle)
Better: silhouette (mean IoU 0.52 -> 0.68), height ~85px, near-black palette, gold accents, E/W facing and near/far projection plausible, 15 alternating NE steps with zero IK reach error, boots level.
Still wrong: hood reads as a helmet/shell, not a soft peaked hood; hood-opening ring looks like a halo from behind; pauldrons are glossy spheres, limbs beaded segments; cloak a flat grey sheet vs the reference tunic with gold-edged panels; gold is thin rings, not edge-trim along panels; boots blocky and ~2cm above ground; no value/highlight language of the source. Foot-skating check is crude (stance mask includes transition frames; right-side speed spread 0.02-0.03 m/frame) - not proven skate-free.
exp-004 overshoots width; exp-002 is reference only.

## Next bounded iteration (if go)
Reshape hood as a peaked cowl; replace ring trims with panel-edge trim on tabard/pauldron; flatten pauldrons; shorten cloak to a mantle; cel/outline shading pass for the source's value language; then re-run the walk with a stricter stance-contact metric.
FPS (15 frames, 15 fps / 67 ms GIF) is provisional preview cadence only.
