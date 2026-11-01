# Operator V004 shoulder collision reconciliation

Workstream: `manual/operator-3d-visual-fidelity-candidate-v4`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1

## Result

Status: `candidate_unapproved`. V004 is a reversible derivative of the V003 split-mesh source. It moves only right-pauldron vertices 134, 135, and 136 by 6 mm along the inward direction of the implicated body-face normal. The body mesh, left pauldron, rig rest pose, weights, materials, and animation actions remain unchanged.

The collision count discrepancy is reconciled. Before V003's zero-thickness Solidify modifier was dropped during mesh joining, its evaluated right shell contained source face 31 plus a coincident reverse-wound duplicate face 109. The original BVH reported two triangle pairs for one physical crossing. The split-mesh derivative has no Solidify modifier and reports one pair. Explicitly triangulated world-space checks with triangle-to-source-polygon maps confirm the crossing: body polygon 1455 against right-shell polygon 31, with a 6.001 mm crossing segment at rest and approximately 6.0–6.85 mm during sampled idle poses. Running frame 16 crosses body polygon 1577 with an approximately 1.505 mm segment; running frame 13 is clear. The full record includes transforms, modifier/armature state, both duplicate triangles, coordinates, normals, and local skin-weight influences.

The crossing exists in rest pose, so local shell curvature/fit is the primary cause; differing body and shell influences affect animation but are not the root cause. After the local fit, reopened Blender checks find zero BVH pairs and zero confirmed triangle crossings at rest, across all 264 idle frames, and running frames 1, 6, 13, 16, and 22. The smallest sampled shell-vertex-to-body-surface distance is 0.488 mm at idle frame 96; this is a point-to-surface sample, not a signed volume depth or global continuous-surface minimum.

Save/reopen checks confirm unchanged body and left-pauldron signatures, right-pauldron topology/UV/material/weights, 42-bone rest signature, and animation action data. All 128px direction samples have at least 6 transparent pixels of margin. Candidate SHA-256: `654b8b819f3e703d1fec10a69b3aa522e4e35b39a2e4c6d40929bf0f5106877d`.

## Review package

The compact bundle compares approved 128px artwork, actual legacy runtime, V003/V004, right-shoulder contact poses, and native 128 versus independent 512 reduced once using `pixelart --choose 1`. It uses the locked 45° camera, 50 px/m and fixed scale 1.2287417600. Review images and source/report hashes are in the Dropbox handoff.

Current Dropbox manifest: `/CUSTODIAN/visual_review/operator-3d-visual-fidelity-candidate-v4/20261101T180158Z/REVIEW_MANIFEST.json` (10 files, `delete-after-review`). It supersedes the earlier upload at `20261101T175916Z`, which did not include the complete collision rows. The current manifest was read back from Dropbox and its artifact hashes verified.

Human review questions:

1. Does the localized right-pauldron underside refit preserve the intended silhouette and layer boundary?
2. Do the shoulder/body surfaces appear clean in the idle and running contact views?

Codex has not approved the candidate's artistic quality. No production integration or Asset Pipeline V2 promotion was performed.
