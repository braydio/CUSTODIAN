# meshy-004_rigged: rig + extremity-stretch diagnostic (iteration 1) - NOT approved, NOT frozen

**Motion status: `REAL_RUN_CLIP_MISSING`.** GLB has 0 animations. `running.mrc1`: magic `MRC1\x01\x00`, 8,274 B, byte entropy 7.98 bits/byte, no plaintext strings, no parser in repo. One bounded read-only look; not decoded, nothing brute-forced. Poses below are **synthetic diagnostic poses, not a run cycle**. Need an exported Meshy GLB with `Animation: Current`.

## Rig validity (script `scripts/rig_diag/`)
1 skin, 42 joints, 17,397 verts / 10,367 tris, 3 textures; IBMs finite and **equal to node rest world matrices (0.000 m)**; weights sum to 1.0000 on all verts, none zero, max 4 influences, joint indices valid. Hand/foot parent chains are intact (Arm>ForeArm>Hand, UpLeg>Leg>Foot>Toe).

## Cause of stretching: bad bone parenting (not weights, not topology, not bind matrices)
Meshy's extra `Bone_0xx` joints are mis-parented. They sit at world positions far from their parent and carry weights on distant geometry:
- `Bone_023/022/027` (Left) and `Bone_018/017/028` (Right) have joints at foot level (z~0.023) but are parented to `ForeArm`/`Hand`; they weight boot-sole verts (height 0-0.09 m). Moving an arm swings the boots (0.85 m lever).
- `Bone_013` is parented to `Head` but sits at hip height (z 0.554) as the end of the front tabard chain `Bone_007>Bone_006>Bone_013`; it weights 807 verts at 0.37-0.73 m, so head turns dragged the tabard.

## Fix (derivative only, reversible, `FIXES` in `pose_proof.py`)
Reparent with world rest pose preserved: `Bone_013`->`Bone_006`; `Bone_023`,`Bone_027`->`mixamorig:LeftFoot`; `Bone_018`,`Bone_028`->`mixamorig:RightFoot` (`Bone_022`/`Bone_017` follow their chains). **No weights, vertices or original GLB changed.** Rest pose change after fix: 6e-7 m.

| Pose (synthetic) | metric | baseline | fixed |
|---|---|---|---|
| P1 arms/elbows | boot mean / max displacement | 0.115 / 1.558 m | 2e-7 / 3e-7 m |
| P1 | max edge stretch / edges >3x | 23.0x / 562 | 12.3x / 330 |
| P2 legs/knees/ankles | max edge stretch / edges >3x | 10.8x / 22 | 2.6x / 0 |
| P3 wrists | max edge stretch / edges >3x | 15.5x / 96 | 3.1x / 2 |
| P4 head turn | tabard mean disp / max stretch | 0.026 m / 2.5x | 2e-7 m / 1.6x |

Evidence: `before_after_contact.png` (+ individual `baseline_*`/`fixed_*` PNGs, `metrics.json`). Hand/foot/tabard closeups show the spikes gone.

## Not fixed (remaining defects)
- P1 still has 330 edges >3x (max 12x): the worst edges join `LeftHand` and `LeftUpLeg` verts. The hand geometry touches/is welded to the thigh armor in the connected mesh, so swinging the arm stretches those edges. This is a mesh-topology issue (needs separating the hand/thigh surfaces or re-weighting), needing a decision; not attempted. Inferred from edge statistics and the renders; not isolated by an experiment.
- Poses are my own axis-aligned rotations, not real motion; the elbow/knee values are not anatomically tuned.
- Only deformation checked in Blender; glTF re-export of the derivative was not done (no animation export without a real clip).

## Pipeline limitation
`asset_pipeline.py run` accepted the rigged GLB but its 8-direction render is **invalid** (scale 2.08, 45-58 px, IoU 0.08, mesh cropped; 10,447 tris counted vs 10,367 so non-mesh geometry from the armature is likely included). Output discarded, not committed. The pipeline needs rigged-GLB handling (mesh-only measurement) before use on rigged assets; not changed here.
