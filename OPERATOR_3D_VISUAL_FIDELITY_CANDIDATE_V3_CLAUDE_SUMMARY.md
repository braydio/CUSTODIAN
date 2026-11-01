# Operator 3D Visual Fidelity Candidate V003 Summary

Workstream: `operator-3d-visual-fidelity-candidate-v3`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1

## Result

Created an experimental, unapproved V003 derivative from the pinned V002 candidate. The V002 file, Task 017 source, ITER005 master, source GLB/FBX, and runtime artwork were not modified. No production workstream was claimed and no full animation cohort was rendered.

Candidate: `custodian/asset_drop/source_work/operator/operator_3d_master/masters/operator_3d_iter005_visual_fidelity_candidate_v003/operator_3d_iter005_visual_fidelity_candidate_v003.blend`

SHA-256: `b0686b23acb583d3eb8ae50d82a8cc713d8449627727927f7c42cd76ba42a6a0` (94,257,829 bytes).

## Corrections and measurements

- **Lower body / stance — preserved from V002.** V002 ankle spacing was 0.320000 m at frame 1, 0.319507 m at frame 132, and 0.319993 m at frame 263. Legs, boots, tabard, kilt, lower cloak, camera/root/direction/scale contract, and neutral-idle timing were carried forward.
- **Hood, visor, materials — preserved with scoped shoulder additions.** Hood and visor geometry/materials remain V002. New shoulder armor uses graphite PBR (metallic 0.48, roughness 0.37) and muted-gold trim (metallic 0.72, roughness 0.34); existing body materials were not altered.
- **Chest posture — partially implemented.** Added -2 degrees of pose-space pitch to Spine, Spine1, and Spine2 for the V003 neutral-idle action (frames 1–264). This is on top of the V002 overlay, for a net -3 degrees per segment from the original source. Rest pose is unchanged. Visual adequacy requires human review.
- **Shoulders — partially implemented; clearance remains unresolved.** Removed only the two V002 donor islands (868 vertices / 912 faces), preserving 17,578 underlying body vertices and 10,367 body polygons. Added fitted angular left/right patches with 122/139 vertices and 71/78 faces, plus one muted-gold edge face per side. Shell surface offsets are 0.058 m outward, 0.018 m up, and 0.040 m forward. Shell weights retain the body's blend with a measured 10–32% shoulder-to-upper-arm transfer (mean 12.37% left, 11.72% right). The prior donor shells registered 145 left and 163 right triangle overlap pairs. V003 left shell has zero measured overlap pairs across tested rest, idle, and running samples. V003 right shell retains two overlap pairs in rest and each of the three neutral-idle samples; running samples also retain two pairs at frames 1, 6, 16, and 22 (zero at frame 13). The no-intersection acceptance is therefore **not met**.
- **Rig — preserved.** 42 bones; identity `36ed6d35469faf5e6f03802371df345321147e1624be35d079fd5140de36d597`; rest-pose signature `62b18ce51ea85907f7270855608be0cdc804ec7e1c17fff5d6da97bf543e55eb`; skeleton signature `abcadb2f29bb273b25d8db278b5e33af27597a8a68a1c90550a92e2b7da7bbd2`. Rest pose and source running action were preserved.
- **Permanent reference comparison — implemented.** The reusable helper validates and includes the approved 128px 8-direction × 15-frame idle and design lock, and separately identifies the live runtime's five-frame 96px `unarmed/posture/idle_relaxed_01` lower/upper compositions with its actual E/W-authored and projected directions. It also labels the separate locomotion idle family rather than substituting it. No frame-level timing correspondence between the 15-frame art and experimental 263-frame idle is claimed.
- **Render/sharpness proof — implemented for bounded samples.** Native 128px: 24 images (eight directions, frames 1/132/263). Independent 512px then one approved `pixelart --pixel-source --size 128 --choose 1` reduction: 12 paired images (S/SE/SW/E, frames 1/132/263). Across those 12 comparisons, mean absolute RGBA channel error is 13.04826; native images average 711.67 partial-alpha pixels and reduced images 0. This records the detail trade-off without selecting either path as final.

## Proof and validation

External proof root: `/home/braydenchaffee/Projects/.operator-3d-animation-proof/operator_3d_visual_fidelity_v3/`

The `human_review_handoff/` folder contains the unchanged 120-cell accepted idle, design-lock reference, actual-runtime contact sheet, eight-direction reference comparison, S/SE/SW/E pose comparisons at frames 1/132/263, upper-body detail, native/reduced sharpness comparison, and adjacent-frame motion QA. `comparison_manifest.v1.json` records reference hashes, runtime projection semantics, version hashes, render settings, samples, and output hashes. `v003_sharpness_metrics.json` reports the alpha/error comparison.

The `custodian.operator_3d_master.v1` master manifest validates against the repository schema. Blend, master manifest, lineage manifest, and correction report agree on the candidate SHA. Python authoring helpers pass `py_compile`. Machine checks confirm unchanged 42-bone rig/rest signatures and preserved motion source. The shoulder overlap residual is intentionally reported rather than waived. No visual approval is claimed.

Human reviewer questions:

1. Against the approved 128px reference and separate live runtime presentation, does the upper-body silhouette read closer to the intended hood/collar/chest/shoulder relationship while keeping V002's lower half intact?
2. Are the fitted angular shoulder shells an acceptable direction, and are the two measured right-side overlap pairs visually or technically unacceptable before V004?
3. Which sharpness path should guide a later review: native 128px or the one-time `pixelart --choose 1` 512px reduction, given the reduced path's loss of partial alpha?

## External review handoff

Published the human-review package with the repository visual-review publisher. The current workstream `LATEST.json` points to:

`/CUSTODIAN/visual_review/operator-3d-visual-fidelity-candidate-v3/20261101T053400Z/REVIEW_MANIFEST.json`

The handoff uses `delete-after-review`. After the review is recorded, run:

`python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/operator-3d-visual-fidelity-candidate-v3/20261101T053400Z/REVIEW_MANIFEST.json --reviewed-by chatgpt-user`

The exact reviewer questions are: (1) Does the upper-body silhouette improve the hood/collar/chest/shoulder relationship against the approved reference and separately labeled runtime while preserving V002's lower half? (2) Are the fitted angular pauldrons acceptable, and must the two right-side overlaps be resolved before V004? (3) Which sharpness path should guide later iteration, given reduced output has no partial-alpha pixels?

An initial smaller upload at `/CUSTODIAN/visual_review/operator-3d-visual-fidelity-candidate-v3/20261101T053200Z/REVIEW_MANIFEST.json` was superseded by the complete `LATEST.json` handoff above; it remains governed by the same delete-after-review policy.

Implementation commit: `0545e5e3a237366e6c1a7ba5945294e675a9cdb5` on `manual/operator-3d-visual-fidelity-candidate-v3`.
