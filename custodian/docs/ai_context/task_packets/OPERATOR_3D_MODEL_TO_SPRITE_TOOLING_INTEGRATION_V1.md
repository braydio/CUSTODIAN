# Operator 3D Source and Static Sprite Tooling Integration V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-3d-model-to-sprite-tooling-integration-v1`
- Category: `assets-art`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-3d-model-to-sprite-tooling`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-3d-model-to-sprite-tooling-integration-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: Static model ingestion combines untrusted binary validation, LFS hydration, immutable provenance, Blender rendering and review publication; independent review checks safe paths and that static and rigged responsibilities remain separate.
- Reviewed main: `f848228723513d21412aee0fdbd6bec6514db4e8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1`
- Visual review: `none`
- Goal: Promote the exact experimental ITER005 source master into the versioned Operator source-work area and extract the existing Meshy/GLB static proof utilities into one supported live model-to-sprite owner.
- Completion boundary: Deliver a content-addressed experimental `.blend`/GLB master with complete source/rig/material/texture/camera lineage; a documented, tested `inspect`, `render-static`, `verify`, and `publish-review` CLI; and updated active README/roadmap ownership. No model correction or runtime publication occurs here.
- Current measured state: The source branch `agent/operator-3d-master-modeling-proof-v1-iter005` at `6b89c4d503bb2d73d2783443d4280f313c681bfa` tracks the 47,225,804-byte ITER005 `.blend` (SHA-256/LFS OID `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969`) and 47,298,084-byte GLB (SHA-256/LFS OID `3968f0bbb47b9f0a9775537b669e7b69c972ad948da0ff121b216f26e5021479`). The branch source and scripts were verified locally. `custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json` is the existing identity contract. The original static pipeline rejects rigged GLBs; `scripts/rig_diag/render_rigged.py` and the live animation compiler own rigged inspection/rendering.
- Evidence: Original branch/path and exact content hashes above; `custodian/docs/ai_context/task_packets/implementation_inputs/operator_3d_static_pipeline_source_6b89c4d.zip` plus its hash manifest; accepted `OPERATOR_2_5D_VISUAL_CONTRACT.md`; current compiler and master schema.
- Task-specific authority: `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`, `design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md`, `custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json`, and existing Operator 2.5D ingress/runtime promotion contracts. Keep output candidate-only and route downstream animation through the existing compiler.
- Work surface: New `custodian/tools/operator/model_to_sprite/` and thin `custodian/tools/operator/model_to_sprite.py`; versioned master under `custodian/asset_drop/source_work/operator/operator_3d_master/masters/`; focused fixtures/tests; compiler README and current 3D roadmap.
- Publication inputs: `custodian/docs/ai_context/task_packets/implementation_inputs/operator_3d_static_pipeline_source_6b89c4d.zip`, `custodian/docs/ai_context/task_packets/implementation_inputs/operator_3d_static_pipeline_source_6b89c4d.manifest.json`, `custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json`, `custodian/tools/operator/animation_compiler/cli.py`, `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`, `custodian/tools/operator/animation_compiler/README.md`, `custodian/tools/iteration/publish_review_artifacts.py`, `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`, `design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md`
- Change:
  1. Verify remote branch/commit, LFS pointer OIDs, hydrated bytes, original source files and dependencies. Copy the unchanged `.blend` and GLB into a stable `masters/` snapshot with provenance; never modify the ITER005 paths.
  2. Emit one `custodian.operator_3d_master.v1` identity with `approval_state=experimental`, exact Blender/GLB hashes, source branch/commit/path/LFS OIDs, 42-bone identity/rest/signature, mesh and weight identity, materials/textures, retarget policy, camera/registration profile, and derivation/parent identity. If the existing schema cannot express required provenance, make only a backward-compatible, tested extension; do not create another registry.
  3. Extract and adapt the source `asset_pipeline_lib.py`, `blender_render.py`, `evidence_render.py`, `build_evidence.py`, and `run_asset.py` capabilities into the live model-to-sprite tool. Keep atomic staging, strict path/hash/dependency validation, independent native 128px and 512px renders, eight independent directions, fixed projection/root, and immutable verify/freeze semantics.
  4. Static rendering must continue to reject skinned GLBs with an actionable route to the existing rig-aware animation compiler. Add rig-aware `inspect` metadata without implementing a second retargeter or renderer.
  5. Audit the vendored meshoptimizer decoder provenance/version/license before any reuse and carry required notices if adopted. Keep the unauthenticated legacy `.meshy` decoder out of the live default path; standard authorized GLB is the supported format.
  6. Add focused tests for real-master provenance, LFS pointer/corrupt/missing files, static-versus-rigged routing, unsafe paths, duplicate output names, dependency staleness, atomic failure, all eight views, native 128/512 outputs, hash verification, and no input mutation. Fixtures are test fixtures, never real animation proof.
  7. Expose bounded CLI commands `inspect`, `render-static`, `verify`, and `publish-review`; use the existing visual-review publisher and preserve `candidate_unapproved`.
  8. Correct the stale README entrypoint and update the production roadmap's current source/tooling state. Keep 2D Motion Foundry and runtime owners unchanged.
- Preserve: Original ITER005 source and branch, experimental source status, all source hashes, 2.5D accepted art/runtime boundaries, Blender animation compiler ownership, existing 96px runtime, timing authority, and Asset Pipeline V2 ingress.
- Non-goals: No retarget policy, animation scheduler, full animation rendering, model geometry/material edits, `.meshy` reverse engineering or decoding, production asset publication, runtime selector/timing changes, or artistic approval.
- Acceptance:
  1. Exact upstream `.blend`/GLB LFS identities and full provenance are verified; original bytes remain identical and new paths are immutable/content-addressed.
  2. Clean-checkout CLI inspection reports mesh/material/texture and rig identities; no LFS pointer is treated as a model.
  3. Static GLB fixture renders all eight directions at native 128px and independently rendered native 512px; no direction mirroring or per-direction/per-frame scaling occurs.
  4. Rigged GLB input fails static render explicitly but exposes a correct route to the current animation compiler.
  5. `verify` detects stale/missing/corrupt dependencies and incomplete output; `publish-review` uses the existing publisher and does not grant approval.
  6. Focused tests prove atomic staging, source immutability, hash provenance, unsafe-path rejection and reproducible reports. No production/runtime paths receive outputs.
  7. Active README and roadmap name one live static tool owner and distinguish it from the existing rigged animation compiler and historical branch tooling.
- Validation: Focused model-to-sprite tests, existing compiler test suite and master compatibility checks; Blender background import/inspect of the exact LFS master; bounded static-fixture eight-direction render; verify source hashes before/after; packet/category checks, README command smoke and `git diff --check`. Avoid broad renders and broad Godot sweeps.
- Task overrides:
  - `TASK OVERRIDE: The ITER005 master remains experimental; source promotion to source_work does not approve artwork or runtime use.`
  - `TASK OVERRIDE: Do not modify the existing source branch or its master files. New snapshots/derivatives use new immutable paths.`
- Deferred: Model visual-fidelity correction is owned by the dependent `operator-3d-visual-fidelity-candidate-v2` packet. Full animation processing, runtime publication, asset cohort promotion and production approval remain deferred.

## Context Pack

- Repomix: `recommended`
- Include: `custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json,custodian/tools/operator/animation_compiler/cli.py,custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py,custodian/tools/operator/animation_compiler/README.md,custodian/tools/iteration/publish_review_artifacts.py,design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md,design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md`
- Purpose: Keep source-master identity, existing compiler ownership, render contract and review boundary explicit while extracting only static model proof tooling.

## Next Handoff

- Next workstream: `operator-3d-visual-fidelity-candidate-v2`
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1
- Refresh reason: The versioned experimental base master and reviewed static source tooling must land before a new visual-fidelity derivative is created.
- Next action: Claim the dependent visual-fidelity packet only after this workstream and its paired review archive complete.
- Blockers or open questions: Source review does not grant model/art approval; final model appearance remains human-owned.
