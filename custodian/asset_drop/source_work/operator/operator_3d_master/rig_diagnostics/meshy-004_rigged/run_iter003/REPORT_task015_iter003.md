# Task 015 — iter003 running gait correction

**Status: `RUN_MOTION_NEEDS_REPAIR`.** This is a reversible experimental derivative for human review. It is not artistically approved, promoted, frozen, or integrated into runtime.

## What changed

Iter003 starts from the untouched iter002 `.blend`. A copied action applies the minimum per-frame world rotation needed to align the left/right UpLeg, Leg, Foot, and ToeBase segment axes to the corresponding Mixamo Running.fbx axes. The proximal-to-distal corrections leave segment lengths and mesh vertices unchanged. All 21 unique frames plus the loop endpoint remain at 30fps over 0.70s. The source action, blend, GLB, weights, geometry, materials, UVs, and 42-bone rig are preserved. No triangles were removed.

The right toe's animated axis error falls from 49.98° to 0° against the source; left toe error falls from 17.53° to 0°. Thigh and calf direction errors also fall from 8.49°/8.88° and 14.40°/14.40° to 0°. The *unanimated rest pose remains unchanged*, including its asymmetric right-toe axis offset; the correction acts on the run action.

## Objective measurements

| Measure | Iter002 | Iter003 | Mixamo source / notes |
| --- | ---: | ---: | ---: |
| Mean knee width / hip width | 1.393 | 0.909 | 0.853 |
| Mean ankle stance / hip width | 1.565 | 0.755 | 0.535 |
| Maximum edge stretch | 2.969× | 2.969× | — |
| Maximum p99.9 edge stretch | 2.354× | 2.320× | — |
| Distinct edges over 3× | 0 | 0 | — |
| Minimum animated mesh Z | −2.7mm | −32.0mm | Ground breach: 42 vertices exceed −5mm in at least one frame |
| Maximum loop seam vertex delta | 0.00160mm | 0.00160mm | Frame 22 against frame 1 |

Fixed heel and toe landmarks are 12 constant vertex IDs per region, chosen once from rest-pose Foot/ToeBase weights. Contact uses a 40mm height band; speed is measured both in world coordinates and relative to the pelvis.

| Landmark | Iter002 contact frames | Iter003 contact frames | Iter003 pelvis-relative horizontal speed, mean |
| --- | --- | --- | ---: |
| Left heel | 8 | 8–12 | 3.57m/s |
| Left toe | 13–14 | 13–15 | 3.84m/s |
| Right heel | 18–19 | 18–21 | 3.69m/s |
| Right toe | none | none | not measured |

The stable points confirm near-ground intervals but show rapid horizontal movement while inside the contact band. This is an objective skating/contact concern; it has not been corrected. The right toe has no contact sample in either version.

## Fragments and renders

The existing fragment method counts alpha components disconnected from the main rendered component; it does not judge whether a cloth flap is legitimate.

| Resolution | Iter002: pixels / affected views | Iter003: pixels / affected views |
| --- | ---: | ---: |
| 128px | 190 / 51 of 176 | 188 / 58 of 176 |
| 512px | 3,697 / 83 of 176 | 3,749 / 84 of 176 |

The tiny residual fragments did not materially improve. They remain intact. The candidate and baseline were independently rendered at native 128px and 512px for rest plus 21 frames, eight unmirrored directions, with the fixed 45° elevation, 50px/m orthographic camera, fixed pivot, and 1.23547 scale. Face-ID render passes had zero invalid pixels. Review contact sheets include rest and representative run frames; both looping comparisons cover all 21 unique frames and all eight directions.

## Export and preservation checks

- Clean Blender GLB reimport: 21 samples over 0.700s, maximum nearest-vertex difference 0.00228mm, loop seam 0.00186mm, 42 bones, 10,367 triangles, normalized weights, at most four influences, `UVMap`, and 4096px textures.
- GLB export explicitly includes the active corrected action only. An initial export included a retained inactive source action; that export was replaced by the verified active-action export. No source files were changed.
- Iter002 versus iter003 invariant check: same 17,578 vertices, 10,367 triangles, bone set, face topology, rest-position hash, skin-weight hash, UV layer, and materials.
- Full-clip deformation comparison resets the armature to identity rest before measuring. The maximum remains 2.969×; 0 distinct edges exceed 3×.

## Human review questions

1. Across the 128px loops and sheets, does the run still read duck-footed? In particular, assess toe direction, ankle tracking, stance width, and whether the new posture preserves the armored silhouette.
2. Do the native 512px comparisons show objectionable foot/ground penetration or loss of armor/cloth shape?
3. Are the fixed-landmark contact windows and reported sliding consistent with what you see? Should foot planting/skating be corrected next?
4. Are the remaining tiny fragments visually acceptable as authored cloth/armor separation, or do any require a geometry/weight investigation?

The coding agent makes no subjective quality decision. Stop here for human visual assessment. No candidate promotion, production integration, runtime changes, main merge, freeze, or approval.

## Evidence files

- `gait_correction_report.json`
- `gait_comparison_iter002_baseline.json`
- `gait_comparison.json`
- `deformation_comparison.json`
- `invariant_verification.json`
- `export_reimport.json`
- `operator_run_mixamo_iter003_gait_corrected.blend`
- `operator_run_mixamo_iter003_gait_corrected.glb`
- Dropbox manifest: `/CUSTODIAN/visual_review/operator-3d-master-modeling-proof-v1/task015-iter003-review-20261028/REVIEW_MANIFEST.json`.
