# Operator V003 Mesh Object Split Summary

Workstream: `manual/operator-3d-visual-fidelity-candidate-v3-mesh-separation`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1

## Result

Created a separate experimental V003 derivative from the existing V003 candidate. The prior V003 blend and branch remain unchanged. The derivative keeps the authenticated body surface as `output_unwrapped` and stores the two new pauldrons as separate armature-skinned objects:

- `Operator_Pauldron_Left_V003`
- `Operator_Pauldron_Right_V003`

Both source Icosphere objects remain in the derivative. `Icosphere.001` was unlinked in V002, so it is retained in a hidden, non-rendering helper collection.

Output: `custodian/asset_drop/source_work/operator/operator_3d_master/masters/operator_3d_iter005_visual_fidelity_candidate_v003_mesh_split/operator_3d_iter005_visual_fidelity_candidate_v003_mesh_split.blend`

SHA-256: `17c3cc57ce58aff1e400636d8b5f1db5bc97058d7028d6de587803514a131589` (47,975,211 bytes).

## Source boundary and preservation

The supplied V002 preflight passed against the exact source hash `2c4c097039b25727c0ce51f22251d33462b6f020ad4f8863d23913b4efe7dc23`: 434 vertices per original donor group, disjoint groups, and zero mixed body/donor faces.

The existing V003 donor replacement is separately isolated: 122 left and 139 right vertices, 71 left and 78 right faces, disjoint groups, and zero mixed body/pauldron faces. The split conserves all 17,839 vertices and 10,516 faces across the body and two shells. The body now has 17,578 vertices and 10,367 faces.

Exact before/after multiset comparisons passed for vertex coordinates and weights, face geometry, UVs, smooth flags, and material assignments. The 42-bone armature, rest pose, active V003 idle, and preserved running action remain intact. All mesh vertices have normalized bone weights; the pauldron source geometry has up to five bone influences per vertex, unchanged from the existing V003 candidate.

V002 source SHA-256 remains `2c4c097039b25727c0ce51f22251d33462b6f020ad4f8863d23913b4efe7dc23`. Existing V003 source SHA-256 remains `b0686b23acb583d3eb8ae50d82a8cc713d8449627727927f7c42cd76ba42a6a0`.

## Evidence and limits

The new directory includes `master.v1.json`, `source_lineage.v1.json`, `mesh_split_validation.v1.json`, and `snapshot_manifest.v1.json`. The master manifest validates against the repository's `master.v1.schema.json`.

The existing V003 render/contact-sheet bundle remains visually representative because this derivative preserves exact geometry, UVs, material assignment, weights, and animation. Its Dropbox manifest is `/CUSTODIAN/visual_review/operator-3d-visual-fidelity-candidate-v3/20261101T053400Z/REVIEW_MANIFEST.json`; that manifest pins the prior V003 blend, not this structure-only derivative.

The known two right-pauldron overlap pairs from the existing V003 candidate remain. This derivative does not resolve them or change the visual candidate. Status remains `candidate_unapproved`; human visual approval is still required.

## Validation

- V002 group-boundary preflight: passed.
- V003 group-boundary preflight: passed.
- Blender 5.2 save/reopen and object/armature/action checks: passed.
- Vertex/weight/face/UV/material conservation comparisons: passed.
- Master schema validation: passed.
- No runtime, production, or main-branch changes.
