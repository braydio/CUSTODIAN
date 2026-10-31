# Operator 3D Source and Static Sprite Tooling Integration V1

Workstream: `operator-3d-model-to-sprite-tooling-integration-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1

## Delivered

- Added the candidate-only `custodian/tools/operator/model_to_sprite.py` CLI and `custodian.tools.operator.model_to_sprite` package with `inspect`, `render-static`, `verify`, and `publish-review` commands.
- Static GLB inspection reports geometry, materials, textures and skin identity. Static rendering fails closed on skinned inputs and points to the existing animation compiler. It independently renders eight canonical views at 128px and 512px; source geometry is not resized or modified.
- Candidate output uses same-filesystem staging, rejects collisions, checks exact input/dependency/tool/output hashes, enforces candidate-only approval state, and publishes only through the existing review publisher. Output receipt identities include rendered and review-file hashes.
- Promoted a byte-verified experimental source snapshot under `custodian/asset_drop/source_work/operator/operator_3d_master/masters/experimental_iter005_baseline_a0bdf6c1/`. The original Blender SHA-256/LFS OID is `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969`; the GLB SHA-256/LFS OID is `3968f0bbb47b9f0a9775537b669e7b69c972ad948da0ff121b216f26e5021479`. The snapshot manifest verifies all eight files, including the three extracted texture payloads and inspection records. Its state remains `experimental`.
- Extended the existing master schema additively for GLB identity, source lineage, Blender version, weights, texture metadata, and camera profile path.
- Updated the animation compiler README and 3D roadmap to distinguish static model proofs, rigged animation ownership, the accepted 128px design reference, the still-live `legacy_96` runtime generation, and historical executor state.
- Audited but did not adopt the legacy `.meshy` decoder or vendored Meshopt decoder. The source archive documents Meshopt 0.18 under MIT; standard GLB is the live supported input.

## Verification

- `test_operator_3d_model_to_sprite`: 8 tests passed, including real Blender fixture inspection/render, 16 independent PNG outputs, source immutability, collision handling, stale output identity, traversal rejection, LFS-pointer rejection, and repository-relative tool receipt paths.
- `test_operator_3d_animation_compiler`: 23 tests passed.
- Python compilation and `git diff --check` passed.
- Blender 5.2.3 CLI inspection read the actual `.blend` and GLB. The Blender armature identity/rest hashes match the master contract; the GLB reports 42 joints, 17,592 vertices and 10,367 triangles. The compiler master schema validator reported no findings.
- Synthetic render fixtures are test geometry only and are not represented as Operator animation proof. No model geometry, runtime assets, selectors, timing authority or gameplay scenes were changed.

## Handoff

The independent post-land review remains required. After it completes, the dependency-gated visual-fidelity candidate may proceed through its own packet. That packet must be refreshed to include the explicitly authorized removal of only the generated Awakening decoration `RuinFloorCrackC`; preserve its source texture, collisions and all unrelated dressing. No model or animation art approval is implied by this tooling work.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `initial static candidate receipts omitted output hashes from the content identity and resolved repository paths to the parent workspace`
- Root cause / contributing factors: `the first implementation identity covered inputs and render settings but not rendered/review files; the repository root used one extra parent level`
- Prevention / pipeline improvement: `content-address the full output set and test receipt paths for independence from ephemeral worktree names`
- Tooling / docs drift discovered: `the archived static-pipeline README referenced a missing custodian/tools/iteration/asset_pipeline.py entrypoint; the live model-to-sprite CLI is now documented`
- Follow-up: `operator-3d-visual-fidelity-candidate-v2`
- What worked: `the static and rigged responsibilities now have distinct supported owners, with real source inspection and fixture-only rendering evidence`
