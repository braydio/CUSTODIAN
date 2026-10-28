# TASK 017 — clean pauldron geometry and rigging proof

**Workstream:** `operator-shoulder-symmetry-and-rigging-v1`
**Starting checkpoint:** `285cff6f99a4dac4cb49267db76f46697d8df455`
**Motion source:** ITER005 `6b89c4d503bb2d73d2783443d4280f313c681bfa`
**Status:** `MODEL_SHOULDER_REPAIR_REQUIRED`

## Result

One new symmetric shell pair was authored and attached to the existing rig. The derivative passes closed-topology, weight, source-preservation, upper-arm clearance, and loop checks. It fails the added-shell integration requirement: the shells intersect existing body surfaces outside a confined hidden attachment region, and the intersected source faces are disconnected. No body faces were removed, no second modeling technique or revision was attempted, and no GLB was exported because geometry integrity did not pass.

## Construction and exact changes

Source: `run_iter005/operator_run_mixamo_iter005_contact_ik.blend`.

Candidate: `task017_clean_pauldrons/operator_iter005_clean_pauldrons_task017.blend` (retained in the experiment worktree; not included in Dropbox).

Two independent objects were added:

- `PAULDRON_Left_TASK017`: 434 vertices, 456 faces, 864 triangles.
- `PAULDRON_Right_TASK017`: 434 vertices, 456 faces, 864 triangles.

Each shell is a closed 4 mm hard-surface cap with explicit lower rim, dimensions 234 × 290 × 145 mm, and a single normalized weight of 1.0 to its matching `mixamorig:{Left,Right}Shoulder` bone. Each has an Armature modifier targeting `SmartRigArmature`, `BakedMaterial`, and a `UVMap` projected by nearest source-surface triangle interpolation. No bones were added. No source body vertices, faces, UVs, materials, groups, weights, or animation curves were modified.

The original body mesh hash is `0f149425308298e0dae638723d0a8c17d0ab98e2ec2fdfefc25cdd665272dd47`; the ITER005 action hash is `b5ad1b31185f0790e3c06cbedfca22562f3101358a70dfd4899d6ec201d6f0b3`. Direct source-to-derivative checks report identical body mesh, action curves, bone names, rest transforms, animation timing (30 fps, frames 1–22), body material assignments, and body modifiers.

## Measurements

- Mirror plane from the mean `LeftShoulder` / `RightShoulder` bone-head x position: +2.386 mm.
- Paired geometry: 434 corresponding vertices per side; maximum mirrored vertex deviation 0.000030 mm. Both sides have identical 864-triangle topology.
- Target outer projection: 295 mm from the mean shoulder-joint reference (about 40 mm beyond the 255 mm mean baseline envelope); top ridge is 166 mm above the mean shoulder bone head.
- Each shell has 0 nonmanifold edges, 0 unweighted/wrong-group vertices, one influence per vertex, and normalized weights.
- Full ITER005 sample: 21 unique frames plus endpoint 22. Body endpoint maximum vertex delta 0.00160 mm; left/right shell endpoint deltas 0.00096 / 0.00036 mm.
- Upper-arm intersections: 0 face-pair overlaps across sampled frames and raised-arm probes. Minimum upper-arm vertex clearance during the run is 33.95 mm Left and 11.74 mm Right; at the temporary 75° lateral probes the minima are 8.4 mm Left and 10.5 mm Right.
- Shell/body intersections: 86–131 face-pair overlaps Left and 119–148 Right across frames 1–22. The cycle union touches 98 source body faces on Left and 113 on Right (52 / 65 shell faces).
- These source-face sets are not a continuous attachment perimeter: Left comprises 44 connected components with 186 boundary edges; Right comprises 43 components with 195 boundary edges. Largest components contain 11 and 16 faces. Exact source face IDs and bounds are in `overlap_region_analysis.json` and `geometry_validation.json`.
- Fixed orthographic camera-ray checks find 50 distinct Left and 53 distinct Right intersecting source-face centers appearing as the first body surface in at least one of eight directions over frames 1–22. This means the overlap cannot be classified as entirely hidden attachment overlap. The ray ledger is `overlap_visibility.json`.
- All 192 required static and candidate-loop 128px renders have zero nontransparent pixels touching the image boundary.

The intersection-face union is the smallest source region established by this one candidate and validation cycle; it is not a proven minimum repair surface. Its many disconnected components and open boundaries mean deleting those faces would leave unsupported body openings. No deletion is authorized or performed. A different shell clearance or a dedicated body-surface retopology/cover plan would need a separately authorized task.

## Render evidence

All renders use the existing fixed camera contract: uniform scale 1.23547, 45° elevation, 50 px/m at 128px, fixed root pixel (64,106), eight unmirrored directions, and common registration.

- `static_128_all8_three_way.png` — BASELINE, original VARIANT_A_MODERATE, and this derivative.
- `static_512_all8_three_way.png` — same three-way comparison at native 512px.
- `static_512_shoulder_closeups.png` — front, rear, side, and four three-quarter shoulder crops.
- `static_128_silhouette_three_way.png` — objective silhouette comparison.
- `iter005_clean_pauldrons_loop_128_all8.gif` — 21-frame, eight-direction loop.
- `iter005_running_arm_swing_before_after_128.png` — unchanged ITER005 versus candidate at frames 6, 16, and 13.
- `pauldron_geometry_attachment_intersections_512.png` — cyan shell, orange rim, red cycle-intersection shell faces, magenta intersected source-body faces, and green shoulder-joint anchors.

These renders are evidence for user/ChatGPT review; they do not express a subjective judgment about the shoulder design.

## Validation and stop reason

The added-shell candidate intersects body surfaces and exposes a portion of the intersected source-face regions in fixed camera rays. Because the exact affected body region is itself dozens of disconnected islands, the candidate does not satisfy the requirement to keep overlaps confined to a deliberate, verified hidden attachment zone. This is the bounded stop condition.

- GLB export/reimport: not run; source-surface integration failed geometry integrity.
- Body geometry / weight / action / rest transforms: verified unchanged against ITER005.
- No production integration, promotion, merge, runtime change, or model freeze.
- A retained Dropbox review handoff is being prepared from the report, compact comparison renders, and objective diagnostics. The model file remains local to the experiment worktree. The exact Dropbox manifest path is recorded in the durable closeout summary.

## Evidence files

- `task017_geometry_build.json`
- `geometry_validation.json`
- `overlap_visibility.json`
- `overlap_region_analysis.json`
- `render_metadata.json`
- `evidence_sha256.json`
