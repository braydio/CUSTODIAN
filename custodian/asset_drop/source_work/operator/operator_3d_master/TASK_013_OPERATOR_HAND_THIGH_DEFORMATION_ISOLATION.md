# TASK 013 — isolate and repair residual Operator hand/thigh deformation

**Input:** Task 012 commit `585f56ac638b7f8dd74a364361b85305e31faf67`. Operate ONLY in the existing Operator art worktree on `agent/operator-3d-master-modeling-proof-v1`; leave root `~/Projects/CUSTODIAN` on clean main. Minimize token burn: read `rig_diagnostics/meshy-004_rigged/{REPORT.md,metrics.json}`, `scripts/rig_diag/pose_proof.py` and directly referenced files. No repo-wide scan. Preserve original input GLB, `running.mrc1`, frozen meshy-002, meshy-003, Task 012 evidence.

## 1. Publish Task 012 evidence first
Use the existing opt-in `custodian/tools/iteration/publish_review_artifacts.py` to upload a **small, real, rendered** review pack (before_after_contact.png + representative baseline/fixed P1 hands/feet and P3 wrists + metrics summary). Reason: user/ChatGPT must visually assess residual deformation. Explicit artifact selection, dry run, within file/size caps, `--retain-after-review`, then actual upload and remote hash/size verification. Supply review manifest path + image links. Do not upload proprietary GLB/MRC1 binaries; do not modify old Dropbox runs.

## 2. Prove exactly what stretches
On the **Task 012 fixed derivative**, focus on synthetic P1 (330 edges >3x; max 12.35x) and P3 (2 edges >3x).
For each outlier edge record: edge/vertex indices, **rest edge length in mm**, posed length and ratio, rest endpoint world positions, UV seam / mesh-component identity, full skin-influence weights and bone names on both endpoints, and displacement under **single-bone** controlled perturbations. Inspect Blender mesh adjacency and connected components. Do NOT infer fused hand-to-thigh mesh solely from the dominant-bone-pair statistics: distinguish (a) actual topological bridges across body parts, (b) spatially near-zero edges inflating ratios, (c) wrong/mixed weights, (d) genuine normal deformation in an excessively large synthetic rotation. Report counts for each cause and reproducible indices. Note when evidence is ambiguous.

## 3. Smallest reversible correction
Create a `meshy-004_rigged/iter-002` **derivative** .blend and scripts; preserve Task 012 reparenting. If actual hand–thigh bridges are proven, split only demonstrably bad edges/faces without losing UV/material surface coverage or deforming the intact armor. If weights are wrong, adjust only implicated groups/vertices; maintain normalized weights and <=4 influences. If ratio is a tiny-edge artifact, fix diagnostic reporting/thresholding without pretending geometry was repaired. No wholesale retopo, no invented run animation, no arbitrary bone moves.
Render fixed vs corrected P1/P3 and modest individual joint rotations (e.g., 20–30 degrees), and baseline P2/P4 regression. Include hand, foot, tabard closeups + 3/4 full-body. Track counts >1.5x/>3x, max and p99.9 stretch, true min rest length, boot displacement and tabard drag, before/after. Preserve original mesh silhouette/texture and verify rest pose change <0.1mm; no new boot drag. If material topology cannot be safely repaired, **stop with precise blocker** rather than apply a destructive fix.

## 4. Rig export & existing pipeline safety
If corrective derivative passes geometry/skin checks, export a versioned **rigged GLB without invented animation**, reimport into a clean Blender scene, prove bone hierarchy, bind matrices, weights, UV and material survival and replay tests. Keep all products as **NOT_APPROVED / NOT_FROZEN**.
The normal `asset_pipeline.py run` currently incorrectly treats rigged input as usable (boots-only render; IoU .08). Add the **smallest clear guard** that rejects unsupported skinned/rigged GLBs before staging/returning apparent success (with unit test), unless a fully verified correct rigged-render fix can be made within the same bounded scope. Do not redesign the pipeline or touch Godot.

## 5. Tests and handoff
Run the existing 43-test suite and Blender integration, plus new targeted deformation and rigged-preflight tests. Report pass/fail, original vs repaired outliers, file paths/hashes, confirmed root cause, before/after Dropbox links, git commit and any blocked steps. Commit only to art branch; no approval, canonical selection, main merge, deployment, or motion-generation claims. `running.mrc1` remains unverified; **do not** spend this iteration reversing it.

**Stop for human visual review.** Keep final report <=15 substantive lines plus required AGENTS.md receipt.
