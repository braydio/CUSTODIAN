# Task 015 ITER004 — ground-contact diagnosis

**Status: `RUN_MOTION_NEEDS_REPAIR`.** This iteration completed one bounded diagnostic and sensitivity cycle. No model correction was justified, so no ITER004 `.blend` or GLB derivative was written. ITER002 and ITER003 assets remain unchanged. This report makes no visual-quality judgment; human review is required.

## Ground penetration and its cause

The diagnostic evaluates all 17,578 skinned mesh vertices at each of the 21 unique 30fps frames against the canonical ground plane `z=0`. Penetration is strictly `z < -5mm`; values are mesh-space world coordinates with the armature evaluated by Blender. ITER002 has **0** observations below −5mm in all 21 frames. ITER003 has **164 vertex/frame observations** across **95 distinct vertices**; its maximum-depth sample is **−31.99mm at frame 13** (42 vertices at that frame). Other affected frames and counts are in `penetration_contact_iter003.json`.

The previous ITER003 report's “42 vertices” is the **maximum count in any one frame** (frame 13), reported by `deformation_comparison.json`; it is not the count of unique vertices over the full cycle. The 95 figure deduplicates vertex IDs across all frames. These are compatible measurement scopes, not contradictory results.

The weighted rest-pose sole geometry is at/above ground (left minimum 2.604mm; right minimum 0.000mm), while ITER002 has no >5mm penetration and the ITER003 failures arise during the animated action. The affected frame-11–14 vertices are concentrated in the animated foot/toe chain and adjacent deforming geometry. This supports **animated foot-bone rotation/deformation** as the cause; a static sole-geometry defect or global contact-height calibration error is not supported by these controls.

A temporary uniform foot-pitch sensitivity sweep tested −20° through +20° in 5° increments. The neutral result is 164 observations / −31.99mm; the best tested positive offsets still leave 56 observations / −18.77mm (20°), and no tested offset gives right-toe contact. The offsets also change contact windows and introduce further under-ground heel samples. A global character lift sufficient to clear the deepest penetration would remove most existing fixed-landmark contact windows. These controls reject a single global pitch or height adjustment as a justified repair. Solving the remaining behavior would require a phase-specific contact/IK change, beyond a correction that can be justified without altering ITER003 alignment. No speculative IK or frame offsets were applied.

## Fixed-landmark contact and reconstructed travel

The same 12 fixed vertex IDs per heel/toe centroid from ITER003 `gait_comparison.json` were reused unchanged. No per-frame lowest-vertex selection is used. Contact is centroid height `z <= 40mm`. Forward is `world up × (right hip − left hip)`, yielding approximately Operator −Y. For adjacent in-band samples, pelvis-relative landmark velocity is computed; constant forward root speed is inferred as the median of its negative signed forward component. This yields **3.539m/s** for ITER003 and **4.213m/s** for ITER002. Reconstructed position is `observed_landmark + forward_axis * inferred_speed * time`, with `time=(frame−1)/30s`.

This is an inferred cycle velocity, not source-authored locomotion. Since it is fitted from the same contact-phase windows, reconstructed residuals are descriptive, not independent proof of natural planting.

| Fixed centroid | ITER002 contact frames | ITER002 reconstructed interval displacement | ITER003 contact frames | ITER003 reconstructed interval displacement |
| --- | --- | ---: | --- | ---: |
| Left heel | 8 | isolated sample; no interval | 8–12 | net 63.8mm; path 67.7mm |
| Left toe | 13–14 | net/path 21.0mm | 13–15 | net 30.1mm; path 58.7mm |
| Right heel | 18–19 | net/path 18.7mm | 18–21 | net 50.8mm; path 51.2mm |
| Right toe | none | no interval | none | no interval |

The right-toe centroid minimum is 54.86mm in ITER003, so it never reaches the 40mm band; its selected fixed vertices' minimum is 41.79mm. During right-heel contact frames 18–21, the right toe centroid is elevated (see per-frame diagnostic). Thus the no-contact result follows from the toe staying above the band while heel contact is detected, not from changing landmark identities. The reconstructed net/path movements are substantial; contact sliding remains a technical defect flag.

## Validation and evidence

- Diagnostic run on both ITER002 and ITER003 in Blender 5.2.3 LTS, all 21 frames; full per-frame penetrating IDs, weights, landmark coordinates, and contact intervals are retained in the JSON files below.
- Uniform pitch sweep ran once, −20° to +20° in 5° steps, without saving/modifying a candidate; full summary is `pitch_sensitivity.json`.
- The existing deformation report's maximum stretch remains 2.969× with zero edges over 3×; ITER003 loop seam remains 0.00160mm. This iteration changed no rig/mesh, so these values were re-read from ITER003 evidence, not recomputed on a new asset.
- Contact evidence reuses canonical native 128px and independently rendered native 512px ITER002/003 frame sets. Green overlay is ground `z=0`; LH/LT/RH/RT labels mark the same measured fixed centroids. The 128px sheet shows frames 11–14 in eight directions; the native512 sheet focuses on those frames in N/E/S/SE. Both loops cover all 21 frames/eight directions; the 512-loop is reduced for playback, while its focused stills are native512.
- No GLB export/reimport was performed because no corrected candidate exists. Existing ITER003 clean-reimport checks remain the latest asset verification.
- Scripts: `scripts/rig_diag/diagnose_run_contact_iter004.py` and `scripts/rig_diag/build_contact_review_iter004.py`.

## Human review questions

1. In the 128px comparisons and loops, does the run still read duck-footed, and do the stance and toe directions look acceptable?
2. In the native512 contact sheet and loops, where do you see the reported frame 11–14 penetration or sliding, and are any observed separations visually objectionable?
3. Should the next bounded task authorize phase-specific contact/IK correction to address the measured penetration/sliding, while retaining ITER003's alignment, or should the task return to planning?

The coding agent does not decide whether gait, silhouettes, boots, cloth, armor, or fragments look acceptable. Stop here for human visual assessment. No candidate promotion, art approval, runtime integration, main merge, or deployment.

## Evidence artifacts

- `penetration_contact_iter002.json`
- `penetration_contact_iter003.json`
- `pitch_sensitivity.json`
- `contact_review_metadata.json`
- Native review media: `contact_128_all8_iter002_vs_iter003.png`, `contact_512_native_focused_iter002_vs_iter003.png`, `contact_loop_128_all8.gif`, `contact_loop_512_all8.gif` (published separately to Dropbox; not committed as bulk media).
- Published Dropbox manifest: `/CUSTODIAN/visual_review/operator-3d-master-modeling-proof-v1/task015-iter004-contact-review-20261028/REVIEW_MANIFEST.json`.
