# Operator 3D Visual Fidelity Candidate V2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-3d-visual-fidelity-candidate-v2`
- Category: `operator-actors`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-operator-3d-model-to-sprite-tooling-integration-v1`
- Locks: `operator-3d-visual-fidelity-candidate`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-3d-visual-fidelity-candidate-v2`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: The work changes an experimental skinned character's proportions/materials and render sampling; independent inspection must verify immutable source derivation, unchanged rig compatibility, correct one-time nearest-neighbor reduction, and no false approval.
- Reviewed main: `f848228723513d21412aee0fdbd6bec6514db4e8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1`
- Visual review: `required`
- Goal: Produce one bounded, source-versioned Operator 3D visual-fidelity candidate that better matches the accepted 128px full-body artwork in neutral stance, proportions, visor/material readability, and crisp presentation.
- Completion boundary: Create a new experimental Blender derivative from the immutable ITER005 master, preserve existing rig identity/weights where possible, compare 12 unique sampled poses across four canonical directions at 128/512, verify a short temporal neighborhood, publish one compact human-review bundle, then stop. No full 2,104-frame render and no production promotion.
- Current measured state: Accepted art is `unarmed_posture_idle_relaxed_01_full_body_v1_source.png`, SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, 1920×1024 RGBA, 15×8 128px cells in N/NE/E/SE/S/SW/W/NW order; source FPS is unknown. The existing experimental candidate is version `neutral_idle_rest_frame_v2_awakening_128_v1`, receipt SHA-256 `5c237de902397e1bae1f0de6bc3951334369b95db46c9b9e9064ef38b916853b`, bound to FBX SHA `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`, source timing 264 frames at 30 FPS, duplicate terminal omitted, 263 unique frames. The corrected A/B review run is `/CUSTODIAN/visual_review/operator-3d-animation-batch-executor-v1/20261030T170942Z/REVIEW_MANIFEST.json`; no art approval has been granted.
- Evidence: Accepted 2.5D visual contract; hash-verified ITER005 source/master manifest from the dependency workstream; existing candidate receipt and QA; published corrected A/B comparison; user-provided exact local FBX source path/hash and independent 2D source hash.
- Task-specific authority: `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md` controls anatomy, palette, directions, registration and crisp resizing. Reuse the existing animation compiler and pinned retarget policy. The modeling branch's Task 015/ITER005 report is historical evidence, not permission to alter its original files. The latest visual-fidelity instructions in the linked authoring chat authorize a separate immutable derivative and bounded proof only.
- Work surface: New versioned `.blend`/master manifest under `custodian/asset_drop/source_work/operator/operator_3d_master/masters/`; task-scoped ignored/external proof output; focused model/retarget/render QA; one human visual review bundle. Existing compiler changes, if needed, remain owned and committed by `operator-3d-animation-batch-executor-v1`.
- Publication inputs: `custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json`, `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`, `custodian/tools/operator/animation_compiler/retarget_calibration.py`, `custodian/tools/operator/animation_compiler/neutral_idle_proof_contract.py`, `custodian/tools/iteration/publish_review_artifacts.py`, `custodian/tools/agent/workstream.py`, `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`, `design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md`
- Change:
  1. Verify the predecessor's LFS master, source/target armature signatures, 42-bone hierarchy, rest-pose hash, mesh/weights/material/texture hashes, and the existing retargeted motion/action hashes. Fail closed on missing textures or signature drift.
  2. Create `operator_3d_iter005_visual_fidelity_candidate_v002.blend` as a new content-addressed LFS file with parent master identity, source commit/path, delta/derivation note, exact dependencies and `approval_state=experimental`. Never edit the original ITER005 `.blend`, GLB, Task 015 files or existing candidate motion artifact.
  3. Diagnose whether stride/stagger, asymmetric foot stance, raised foot, hunched torso, visor visibility and broad lighting come from source pose, retarget mapping, rest pose, model proportions or render transform before changing the correct owner. Preserve action timing and existing source variation.
  4. Make bounded stance/proportion/material changes only in the new derivative. Preserve arm/hand correction unless evidence justifies a change. Keep dark faceless hood, directional amber visor hierarchy and distinct graphite/gold/cloth; do not add global bloom or change skeleton/rest/weights without exact invalidation evidence.
  5. Compare S, SE, SW and E at source frames 1, 132 and 263: existing baseline, pose/proportion candidate, material/visor candidate and final selected candidate. Total authored source poses: 12; no full 2,104-frame rerender.
  6. Produce native 128 and independently rendered 512 RGBA samples under the fixed 45° orthographic, 50px/m, 2.56 ortho, root `(64,106)`, fixed-scale/no-mirror contract. Compare native 128 with 512-derived 128 using the required `pixelart` alias and `--choose 1` only; never introduce Lanczos/BOX/general sharpening.
  7. Measure per-pose pelvis-relative ankle spacing, leg-length normalization, wrist/shoulder and hip relationships, knee/elbow angles, alpha bounds, contact, visor luminance by direction, root registration and candidate hashes. Include a short adjacent-frame proof around the 12 poses for foot skating, edge shimmer, visor flicker and cloth stability.
  8. Use the same camera, floor, lighting, shadow, scale and environment for A/B. Check Godot filtering only inside the dev preview; no global renderer/filter changes.
  9. Update the current 3D roadmap/source state with immutable hashes and remaining issues. Publish one compact bundle containing source lineage, 8-direction baseline/candidate views, close crops for feet/waist/visor, native-vs-derived sharpness and a concise report. Ask for human judgment and stop.
- Preserve: Exact original ITER005 model/GLB and all ancestor revisions; armature hierarchy/rest/weights/material/source action unless separately proven and re-versioned; existing neutral idle motion/receipt/frame set; approved 2.5D source pixels; runtime assets/selectors/timing; Task 017 shoulder work; all other production assets.
- Non-goals: No full animation render, bulk clip processing, new retarget policy, model approval, runtime timing/cohort, Asset V2 publication, canonical sprite change, arbitrary repaint/warping, Godot runtime-selector changes, or unrelated geometry work.
- Acceptance:
  1. Original master/GLB, source FBX, motion artifact and previous candidate receipt hashes remain unchanged; the v002 `.blend` is a distinct LFS-backed content-addressed derivative with full lineage and no missing dependencies.
  2. Mapping/rest signature and weight compatibility are reported; any changed rig identity invalidates retarget motion and is not silently reused.
  3. The 12 pose matrix includes all four requested directions and three source frames for each specified candidate variant, with actual native 128 and independently generated native 512 outputs; no hidden scale/filter/mirror differences.
  4. Registered root/camera/fixed scale, directional visor behavior, full-body crop/alpha, material identities and model immutability checks pass or are explicitly reported as failed.
  5. Pose/contact and short-neighborhood QA identify measured improvements/regressions without optimizing for a numerical score at the expense of appearance.
  6. The review bundle is published through the existing publisher with exact source/candidate hashes and human questions. Candidate stays `candidate_unapproved`; implementation stops for visual review.
- Validation: Compare SHA-256/LFS and Blender armature/rest/mesh/material/texture signatures before/after; run source/motion integrity and existing compiler tests; run exact 12-pose render/mask/registration/visor metrics and a short temporal-neighbor check; run the preview smoke at actual Awakening scale; verify one-time `pixelart --choose 1` derivative and inputs; check bundle hashes; `git diff --check`. Do not run full animation batch or broad Godot sweep.
- Task overrides:
  - `TASK OVERRIDE: Candidate remains experimental and unapproved regardless of technical QA or source-work publication.`
  - `TASK OVERRIDE: Do not mutate the original ITER005 branch/worktree or any existing candidate/receipt/motion artifact; all changes use new immutable paths.`
  - `TASK OVERRIDE: Stop after the compact proof and published review handoff. Human visual assessment is the next gate; do not render the full candidate or begin bulk processing.`
- Deferred: Full 263×8 candidate rerender is only considered after visual review; production cohort/timing and runtime publication are separate human/Asset V2 decisions.

## Host-local proof inputs

- Original FBX: `/home/braydenchaffee/Downloads/Neutral Idle.fbx`, expected SHA-256 `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`; verify exact bytes at claim and leave it unmodified.
- Existing proof root: `/home/braydenchaffee/Projects/.operator-3d-animation-proof/neutral-idle/`; use the pinned v2 receipt and motion/retarget artifacts, not the withdrawn 96px comparison or the older v1 receipt.
- These local files are implementation inputs, not Git publication inputs. They were verified for this task; if missing or hashes differ at claim, stop and report the precise failure rather than fabricating/reconstructing them.

## Context Pack

- Repomix: `recommended`
- Include: `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py,custodian/tools/operator/animation_compiler/retarget_calibration.py,custodian/tools/operator/animation_compiler/neutral_idle_proof_contract.py,custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json,design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md,design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md`
- Purpose: Bind candidate changes to the real compiler, master identity, accepted pixel contract and current source truth.

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1
- Refresh reason: Model/stance/visor/sampling are subjective; human visual judgment of the compact proof is required.
- Next action: Review the exact published Dropbox manifest and decide which specific refinements, if any, are desired before any full render.
- Blockers or open questions: Does the candidate's silhouette, visor, stance, foot contact, cloak stability and 128px sharpness better match accepted art?
