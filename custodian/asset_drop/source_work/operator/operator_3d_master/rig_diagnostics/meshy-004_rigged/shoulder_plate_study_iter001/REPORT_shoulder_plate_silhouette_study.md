# Operator shoulder plate silhouette study — static variants

**Status:** `READY_FOR_HUMAN_VISUAL_REVIEW`
**Source:** ITER005 static rest pose, from commit `6b89c4d503bb2d73d2783443d4280f313c681bfa`.
**Scope:** Three static reversible model files; no canonical selection or animation work.

## Variants

- `BASELINE.blend`: source shoulder geometry unchanged; run action disabled and armature pose reset to the neutral rest pose.
- `VARIANT_A_MODERATE.blend`: an additional pair of thin shoulder-plate shells copied from the existing 917-face shoulder surface; offset 4cm outward per side and 1.5cm upward, with 4mm shell thickness.
- `VARIANT_B_LAYERED.blend`: matching shell pair offset 6.5cm outward and 2cm upward, with 8mm thickness.

The source body mesh is retained unchanged beneath the extra shells. The copied patches reuse its UVs and `BakedMaterial`. No source weights, attachments, materials, rest mesh, hood, torso armor, tabard, arms, or other outfit regions were edited. The same static neutral arm pose is used for all three variants.

## Objective checks

- Hashes for base-mesh vertices, topology, weights, UVs, and material names match across all three files.
- The added shells contain 3,194 vertices and 3,441 faces each after thickness.
- At 128px, the maximum alpha width in a fixed upper-body band (rows 32–56) changed versus baseline as follows: A mean across eight directions +4.1%; B +9.1%. Per-direction values are in `render_metrics.json`. This is a coarse pixel measurement, not an aesthetic score.
- A BVH surface-intersection check detected 96 triangle-pair intersections for A and 75 for B between the new shell and non-plate base surfaces. Intersections are localized to the lower shoulder/upper-arm band, approximately z=1.207–1.273m; see `geometry_validation.json`. These are objective clipping flags; visual severity remains for human review.
- Native 128px and 512px renders use one fixed scale (1.23547), 45° elevation, 50px/m at 128, fixed root registration, lighting, and background. The 512px closeup sheet shows front, three-quarter, side, back, and rear three-quarter views. An optional black silhouette sheet is included.

## Evidence

- `shoulder_128_all8_three_variants.png`
- `shoulder_512_all8_three_variants.png`
- `shoulder_512_closeups_five_views.png`
- `shoulder_128_silhouette_optional.png`
- Detailed generation, geometry, and pixel reports are in this directory.
- Dropbox review manifest: `/CUSTODIAN/visual_review/operator-3d-master-modeling-proof-v1/operator-shoulder-plate-study-20261028/REVIEW_MANIFEST.json` (eight artifacts; SHA-256 verified; retention `delete-after-review`)

**Implementation commit:** `2001befe518843bde89ef1c8cb07e813a1be95bf`.

## Exact changed files

- `custodian/asset_drop/source_work/operator/operator_3d_master/scripts/rig_diag/create_shoulder_plate_variants.py`
- `custodian/asset_drop/source_work/operator/operator_3d_master/scripts/rig_diag/render_shoulder_plate_study.py`
- `custodian/asset_drop/source_work/operator/operator_3d_master/scripts/rig_diag/validate_shoulder_plate_study.py`
- `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/shoulder_plate_study_iter001/BASELINE.blend`
- `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/shoulder_plate_study_iter001/VARIANT_A_MODERATE.blend`
- `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/shoulder_plate_study_iter001/VARIANT_B_LAYERED.blend`
- The report, generation/geometry/render JSON, and four contact/silhouette sheets named above in `shoulder_plate_study_iter001/`.
- `OPERATOR_SHOULDER_PLATE_STUDY_CLAUDE_SUMMARY.md`
**Review boundary:** The user and ChatGPT decide whether the shoulder plates still read too flush, which variant best fits the silhouette, and whether the measured underside intersections are visually acceptable. No variant is approved or selected here.
