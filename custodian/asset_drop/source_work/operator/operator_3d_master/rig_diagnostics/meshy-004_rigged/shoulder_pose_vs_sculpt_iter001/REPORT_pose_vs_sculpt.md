# Operator Shoulder Pose-versus-Sculpt Diagnostic

**Status:** `READY_FOR_HUMAN_VISUAL_REVIEW`
**Scope:** diagnostic only; no mesh, rest-bone, production action, GLB, or runtime changes.
**Source:** ITER005 original blend, SHA-256 `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969`.
**Source integrity:** mesh coordinates/topology, vertex-group weights, armature rest matrices, and source action hashes match before/after the in-memory evaluation.

## Measured rest-pose correction

All coordinates are armature-local meters; mirror plane is X = +0.002385772765 m.

- Original right head: `(-49.400, +34.276, +1338.690) mm`.
- Mirrored left target head: `(-49.400, -9.531, +1338.690) mm`.
- Signed head delta: `(+0.000, -43.807, +0.000) mm`.
- Shortest-arc correction: `(+0.997759044, +0.000000056, +0.000000286, +0.066909902)` quaternion `[w,x,y,z]`; axis `(+0.00000084, +0.00000427, +1.00000501)`; angle **+7.673004°** about armature-local +Z.
- Bone lengths preserved: left 205.143 mm; right 213.587 mm; right is 8.444 mm longer.
- With both corrections, evaluated right head matches the mirrored target. Preserving the right bone length leaves its tip at `(-8.428, +0.517, -0.000)` mm relative to the mirrored target tip; per-camera projected head and tip displacements are in `shoulder_pose_correction.json`.

## Objective comparison

Bilateral measure is silhouette IoU between equal 37×37 px joint-centered patches after reflecting the anatomical-left patch horizontally. Higher IoU means closer binary silhouettes; it is a geometric comparison, not an artistic score.

| Neutral view | ORIGINAL | ROTATION_ONLY | POSITION_AND_ROTATION |
|---|---:|---:|---:|
| S / front | 0.7973 | 0.8069 | 0.8520 |
| N / rear | 0.7626 | 0.7718 | 0.8531 |

In camera S, image-left is anatomical **RightShoulder**, the target. `POSITION_AND_ROTATION` reduces reflected-patch XOR from 225→159 px in S and 259→155 px in N. Rotation alone changes those IoUs only modestly. Native 128 px whole-silhouette and fixed-ROI differences are also in the JSON.

## Running-action probes

Original ITER005 action was re-evaluated independently at frames 6, 13, and 16 before each pose correction. Corrections were not accumulated. Below: maximum absolute edge-length change versus the unchanged original pose, p95 absolute edge change, and affected edges over 20%. These are measured deltas, not an established pass/fail threshold.

| Condition | Frame | Max edge change | p95 | Edges >20% |
|---|---:|---:|---:|---:|
| ROTATION_ONLY | 6 | 30.3% | 4.5% | 14 / 6090 |
| ROTATION_ONLY | 13 | 27.1% | 5.1% | 5 / 6090 |
| ROTATION_ONLY | 16 | 23.5% | 5.1% | 3 / 6090 |
| POSITION_AND_ROTATION | 6 | 91.6% | 10.1% | 50 / 6090 |
| POSITION_AND_ROTATION | 13 | 66.2% | 11.0% | 49 / 6090 |
| POSITION_AND_ROTATION | 16 | 68.0% | 11.8% | 57 / 6090 |

The right shoulder/arm chain affects 13,392 vertices; those outside that chain remain at 0 mm displacement in these probes. Of 479 vertices with `Spine2` weights, 264 also carry right-chain weights and move with that blended chain; the other 215 remain at 0 mm. Maximum displacement among the shared subset is reported per frame in JSON.

## Diagnostic recommendation

**OUTCOME 4 — mixed evidence.** Bone placement and orientation contribute to the neutral bilateral discrepancy: position-plus-rotation improves the measured front/rear patch similarity more than rotation alone. However, the same pose-space change produces larger running edge changes (up to 91.6% maximum; p95 up to 11.8%) and leaves a measurable residual contour difference. The residual is not enough to attribute uniquely to sculpt versus blended weights from this test. Do not apply this correction directly to the retargeting pipeline based on this diagnostic alone.

No artistic judgment is made here. The 128 px and 512 px renders and frame 6/13/16 comparisons are for user/ChatGPT review. No further shoulder correction was attempted.

## Evidence

- `neutral_128_all8_three_conditions.png` — three rows, eight directions; note identifies anatomical right.
- `neutral_512_shoulder_closeups.png` — native-512 render crops, S/N/NE/NW.
- `motion_frame_6_128_four_directions.png`, `motion_frame_13_128_four_directions.png`, `motion_frame_16_128_four_directions.png` — ORIGINAL, ROT ONLY, POS + ROT; S/N/NE/NW.
- `shoulder_pose_correction.json` — source coordinates, signed corrections, matrices, projections, render/motion measurements and source-preservation hashes.
- Per-condition native PNG renders are retained under `renders/` and `motion/`.

## Human review questions

1. Does rotation-only visibly improve the target shoulder in the neutral S/N/three-quarter views?
2. Does position-plus-rotation visibly improve bilateral shoulder alignment enough to outweigh the changed running shoulder/arm behavior?
3. Does the remaining mismatch look like sculpt/weight asymmetry, or does it read as acceptable authored asymmetry?

**Authoring chat:** not-recorded
