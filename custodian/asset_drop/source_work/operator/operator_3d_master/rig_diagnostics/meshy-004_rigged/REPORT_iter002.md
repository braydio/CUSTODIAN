# meshy-004_rigged iter-002: hand/thigh deformation isolation + correction (NOT approved, NOT frozen)
Synthetic diagnostic poses only (no real run clip: `REAL_RUN_CLIP_MISSING`). Task 012 reparenting preserved. Original GLB untouched.

## 1. What actually stretched (on the Task 012 fixed derivative; `iter-002_isolation/`, per-edge records in `outlier_edges.json`)
Mesh: 17397 verts, 24272 edges, min rest edge **3.21 mm** (no zero/tiny edges), 4744 coincident-position vertex groups (UV/normal splits) with **0** weight mismatches.
| P1 outlier cause (330 edges >3x, max 12.35x) | edges |
|---|---|
| (b) tiny rest-edge ratio artifact | 0 |
| (c) endpoint carries hand-chain AND thigh/hip-cloth weights (each >0.2) | 240 |
| (c) endpoint weight mismatch across the edge | 73 |
| (a) edge bridging hand-dominant and thigh-dominant vertices | 17 |
| (d) genuine pose magnitude with clean weights | 0 |
P3: 2 edges, both mixed hand/thigh weights. 66 triangles straddle hand and thigh/hip-cloth surfaces (91.54000091552734 cm2 = 0.2720000147819519 % of surface; rest edges 8.899999618530273-50.0 mm); 86 of the 330 P1 outliers lie in them. Single-bone 30 deg: `LeftHand`/`RightHand` alone stay <=1.65x (rest>2mm); shoulder/arm rotation drives the large stretches. Cause categories are heuristic labels from dominant-bone/weight rules (reproducible by script), not a visual proof of every edge.

## 2. Correction (smallest tried; `scripts/rig_diag/repair_iter002.py`)
Ablation, P1 max / >3x edges (P3 max / >3x): detach straddling triangles only 12.35 / 253 (3.11 / 1); reweight only (per-vertex dominance) **worse**, 94.3 / 121 (26.6 / 111) because it tears the bridging triangles; **both** 3.44 / 10 (1.31 / 0).
Applied (derivative only): (1) the 66 straddling triangles are re-created on duplicated vertices (same positions, UVs, normals; no face deleted; 10,367 triangles unchanged) weighted wholly to their majority side; (2) remaining arm-chain-dominated vertices lose lower-chain weights and vice versa (spine/neck/head never touched), renormalised. Counts in `iter-002/metrics_iter002.json` (`weight_changes`). Rest pose change 0.0006 mm (limit 0.1). Skin: 0 unnormalised verts, max 4 influences.
Side effect: at rest, geometry is visually identical; under pose the hand/thigh contact seam opens (intended). Reversible: rerun from the original GLB, or `ITER002_REWEIGHT=0` for detach-only.

## 3. Before/after (fixed = Task 012, corrected = iter-002). Stretch: max / p99.9 / >1.5x / >3x
| pose | fixed | corrected | boot mean disp m | tabard mean disp m |
|---|---|---|---|---|
| P1_arms_elbows | 12.35 / 9.17 / 788 / 330 | 3.44 / 2.47 / 171 / 10 | 2.0e-07 | 2.0e-07 |
| P2_legs_knees_ankles | 2.57 / 2.09 / 190 / 0 | 2.57 / 2.09 / 179 / 0 | 2.5e-01 | 1.2e-01 |
| P3_wrists | 3.11 / 2.54 / 324 / 2 | 1.31 / 1.18 / 0 / 0 | 2.0e-07 | 2.0e-07 |
| P4_head_turn | 1.55 / 1.40 / 6 / 0 | 1.55 / 1.40 / 6 / 0 | 2.0e-07 | 2.0e-07 |
| P5_modest_20_30deg | 6.82 / 5.07 / 542 / 155 | 2.31 / 1.98 / 181 / 0 | 2.7e-01 | 9.9e-02 |

P2/P4 regression: unchanged within rounding. Remaining: P1 has 10 edges >3x (max 3.44x) at an extreme synthetic pose; a small thin spike near one hand is still visible in the P3 corrected render (`fixed_vs_corrected_contact.png`), not isolated further.

## 4. Export + re-import (no animation)
`iter-002/operator_meshy_004_rigged_iter002.glb` sha256 `488d61d2db6bbc428c6581a1f72ffa9e9e11a2e3804f402273d6d3e27942b0a3` (47,255,508 B). Clean re-import: 42 bones, reparenting survived (all 5), 10367 tris, 17509 verts, weights normalised, max 4 influences, UV `UVMap`, material `BakedMaterial` with base/MR/normal 4096 textures, 0 animations. Replay P1-P5 on the re-import matches the .blend (P1 max 3.439 vs 3.439). `.blend` sha256 `60ba37fd9d52b8666591f82a6ef8f38c69fbbfe4a47c22b385b466ebec83947b`.

## 5. Pipeline guard
`audit_gltf` now rejects skinned GLBs (skins / node.skin / JOINTS_0|WEIGHTS_0) with exit 3 before staging; meshy-003 source still accepted. The correct rigged-render fix was not attempted.
