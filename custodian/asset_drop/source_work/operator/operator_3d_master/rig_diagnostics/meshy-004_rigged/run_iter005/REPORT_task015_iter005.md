# Task 015 ITER005 — bounded foot-contact experiment

**Status:** `RUN_MOTION_NEEDS_REPAIR`  
**Basis:** ITER004 commit `84763fc3e357585b889683f113f008b6dcc5096c`; one derivative and one validation cycle.  
**Review manifest:** `/CUSTODIAN/visual_review/operator-3d-master-modeling-proof-v1/task015-iter005-foot-contact-review-20261028/REVIEW_MANIFEST.json`

## Change

Created `operator_run_mixamo_iter005_contact_ik.blend` and matching GLB from the ITER003 gait-corrected source. A smoothly blended, non-stretching two-bone IK constraint acts only in measured contact/penetration phases, using the existing fixed heel/toe landmarks and evaluated Foot/ToeBase weighted sole vertices. The ankle target raises the lowest weighted sole point to 1mm clearance during detected penetration; Foot rotation follows the target. Right-toe contact was not forced. Only leg-chain curves were baked. Source action, pelvis/root trajectory, arms, mesh topology, skin weights, materials, 30fps timing, and 0.70s duration remain unchanged.

## Measurements

| Metric | ITER003 before | ITER005 after |
| --- | ---: | ---: |
| Vertex/frame observations below −5mm, 21 frames | 164 | 0 |
| Distinct vertices below −5mm | 95 | 0 |
| Worst single-frame penetration | −31.99mm, frame 13 (42 vertices) | none at integer frames |
| Minimum mesh Z at integer frames | −31.99mm | +0.9996mm |
| Maximum edge stretch | 2.9687× | 2.9687× |
| Loop seam max vertex delta | — | 0.00160mm |
| Max mesh delta outside measured contact windows | — | 0.00038mm |

The 21-frame contact intervals from fixed landmarks are left heel frames 8–11, left toe 13–15, right heel 18–21, and right toe none. At rest, the right foot/toe axis remains about 49.98° from the character forward axis; ITER005 did not apply an arbitrary toe yaw correction.

Compared with the Mixamo source action, maximum leg-segment direction errors are left thigh 7.59°, left calf 12.50°, right thigh 3.71°, right calf 3.78°. Foot and toe axes differ by at most 0.008°. Arm/forearm directions remain within 0.00005°. The mean normalized target stance width is 0.755 versus source 0.535; ratios are affected by differing skeleton proportions and are reported without an artistic verdict.

At one-quarter-frame samples, the derivative still has between-frame sole penetration: right sole minimum −8.82mm at frame 1.50 (also −6.72mm at 1.25 and −5.91mm at 1.75); left sole minimum −6.09mm at 12.50 (also −5.84mm at 10.50 and −5.61mm at 11.50). This invalidates a clean contact result despite integer-frame clearance. One in-memory linear-curve probe did not eliminate these dips. No second correction approach was attempted.

Reconstructed world-space heel drift uses root forward velocity inferred from this same 0.70s cycle (3.4785m/s); it is not an independently validated gameplay speed. Under that assumption, left heel net/path drift is 45.0/48.2mm, left toe 33.1/58.9mm, and right heel 57.4/57.5mm. Right toe has no 40mm-band samples. These values describe residual motion under the stated reconstruction and do not establish gameplay skating distance.

## Export and preservation checks

- Mesh topology, vertex count, bone set, UVs, materials, rest-position hash, skin-weight hash, and face-topology hash match ITER003.
- GLB clean Blender reimport: 0.700s, 21 samples, maximum nearest-vertex delta 0.00228mm, loop seam 0.00186mm, 42 bones, 10,367 triangles, normalized weights, max four influences, UVMap, and 4096px textures.
- Native 128px and independent native 512px renders used the existing camera contract (scale 1.23547, 45° elevation, 50px/m at 128). Contact comparison sheets show eight directions at 128px and focused N/E/S/SE views at 512px; loops cover all 21 unique frames with ground and fixed-landmark/sole-minimum overlays.

## Evidence and review boundary

Machine-readable evidence is beside this report: solver report, before/after penetration ledgers, gait/source comparison, asset invariants, GLB reimport report, render contract, and review metadata. The retained Dropbox bundle contains this report, the two comparison sheets, both loops, and selected diagnostic JSON files. Review whether the contact correction introduces visible leg-motion/silhouette changes and whether the remaining between-frame penetration is acceptable. This report makes no artistic assessment or approval claim. Stop for human/ChatGPT review before any next iteration.
