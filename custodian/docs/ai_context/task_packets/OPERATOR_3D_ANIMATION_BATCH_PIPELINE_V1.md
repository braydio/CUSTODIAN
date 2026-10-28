# Operator 3D Animation Batch Pipeline V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-3d-animation-batch-pipeline-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-3d-animation-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-3d-animation-batch-pipeline-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: A deterministic compiler boundary establishes source provenance, skeletal compatibility, timing and root-motion safety, immutable master identity, and output registration before any future Blender batch rendering; a fresh post-land review materially improves confidence across code and pipeline contracts.
- Reviewed main: `a358584555f91e396f7da3ac4e883aff27c143f3`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Authoring handoff: `auto`
- Goal: Establish a deterministic, headless-capable foundation for compiling Mixamo FBX clips against a replaceable Operator 3D master into future eight-direction, full-body 128px sprite candidates.
- Completion boundary: Task 001 only. Deliver versioned master and batch schemas, representative source manifest, read-only `plan`, `validate`, and `check` commands, focused tests, reuse/gap map, and a concrete proposal for a single Neutral Idle Blender proof. Stop after validation and implementation closeout. Do not render, execute a batch, publish runtime assets, or begin Task 002.
- Current measured state: `origin/main` at the Reviewed main SHA contains the Operator 2.5D ingress, timing authority, asset schema, visual contract, Workbench, and 2D Motion Foundry. The named `operator_3d_master/scripts/rig_diag/{inspect_fbx.py,retarget_run.py,render_rigged.py}` and ITER003–005 diagnostic files were not found in the fetched repository or authorized local project tree during packet authoring. Treat them as unavailable until verified in the claimed worktree; do not fabricate inspection findings or modify their owner’s files. The 2D Motion Foundry has a 120-frame bound and is not the skeletal compiler.
- Evidence: `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`; `design/02_features/animation/OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md`; `custodian/tools/operator/operator_2_5d_ingress.py`; `custodian/tools/operator/operator_2_5d_timing_authority.py`; `custodian/tools/pipelines/operator_asset_schema.py`; `custodian/tools/operator/motion_foundry/`; `custodian/tools/validation/operator_2_5d_ingress_smoke.py`; `custodian/tools/validation/operator_asset_schema_smoke.py`.
- Task-specific authority: This packet’s Task 001 architecture and acceptance; `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md` for direction, 128px registration and existing runtime boundaries; `custodian/tools/operator/operator_2_5d_ingress.py`, `operator_2_5d_timing_authority.py`, and `custodian/tools/pipelines/operator_asset_schema.py` for existing ingress, timing and schema interfaces. The 3D diagnostics listed in the user brief are inspection targets only if present in an authorized local checkout; record their exact reuse and hardcoding boundaries or their unavailability. Do not use `python-sim/` as authority.
- Work surface: New compiler implementation/schema/manifest/tests under `custodian/tools/operator/` and focused validation under `custodian/tools/validation/`; reuse analysis of the listed Operator ingress/timing/schema interfaces and any authorized `operator_3d_master` diagnostics that are actually available. Avoid edits to all existing production or experimental asset and runtime surfaces.
- Publication inputs: `custodian/tools/operator/operator_2_5d_ingress.py`, `custodian/tools/operator/operator_2_5d_timing_authority.py`, `custodian/tools/pipelines/operator_asset_schema.py`, `custodian/tools/operator/motion_foundry/`, `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`, `design/02_features/animation/OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md`
- Change:
  1. Define versioned animation-batch and immutable 3D-master contracts binding model-file hash, armature identity/rest-pose hash, mesh/material identity, texture dependencies, retarget policy, and canonical camera/registration profile.
  2. Define batch entries with animation ID and original FBX filename, source SHA-256/import metadata, semantic profile/group/action, source skeleton identity and compatibility proof, authored duration/FPS/keyframe range, loop/one-shot classification, optional character-local impact direction, root-motion preservation/extraction and optional in-place policy, foot-contact policy, retarget policy version, output sampling policy, target master identity/hash, and rendering-contract identity. Missing real inputs are explicitly unavailable; invent no hashes, paths or timestamps.
  3. Implement a small CLI: `plan` emits a deterministic read-only execution graph and dry-run estimates; `validate` checks confined paths, available source hashes, skeleton/action compatibility, master references, timing declarations, policies, duplicate semantic outputs and path collisions; `check` re-evaluates a saved plan/receipt against declared dependencies and reports staleness. Use stable machine-readable JSON errors and exit codes.
  4. Specify the target output contract: independently rendered N, NE, E, SE, S, SW, W, NW views; full-body 128x128 RGBA; fixed 45-degree elevation; 50 px/m; root pixel (64,106); master-derived fixed scale; registration consistency; no mirroring or per-frame zoom; explicit sampling and loop endpoint rules; root trajectory metadata separate from poses; optional native 512px diagnostics; exact output/dependency hashes; candidate-only status.
  5. Preserve source-authored timing separately from any explicitly authorized runtime timing; never infer runtime timing from FBX metadata. Preserve trajectory and in-place pose as separate channels with a declared Godot single-application policy. Accept long clips, including 264- and 299-frame examples, without the 2D Foundry limit.
  6. Provide the eight representative semantic entries `neutral_idle`, `breathing_idle`, `walking`, `running_slide`, `react_small_front`, `react_small_back`, `react_large_front`, `react_large_left`. A reaction impact direction is character-local metadata, separate from render viewpoints. Only hash actual files in an authorized local source directory.
  7. Include a concise Task 002 proposal to process one Neutral Idle FBX through Blender, with exact missing prerequisites, evidence and stop gates.
- Preserve: Keep `custodian/tools/operator/motion_foundry/` and its 2D `custodian.motion_foundry.*` authority unchanged. Keep live modular presentation, runtime timing, Workbench assets and canonical source/runtime art unchanged. Treat ITER005 as experimental if referenced; do not assume approval. Preserve all unrelated dirty work and source ownership.
- Non-goals: No full Blender renderer or batch executor; no FBX download; no model or shoulder geometry work; no running IK; no animation sprite generation; no Asset V2/canonical asset publication; no Workbench mutation; no Godot integration or runtime-policy change; no edits to Task 017 or its worktree, original Claude worktree, ITER005 assets/motion corrections, or canonical Operator source assets.
- Acceptance:
  1. Versioned schemas and representative manifests are machine-validated; unknown fields/policies, malformed hashes, unsafe/traversing paths, duplicate outputs and missing timing authority fail with stable errors.
  2. Model and dependency hashes are content-addressed. Real FBX hashing occurs only when the file exists inside the explicitly authorized source root; missing files are reported unavailable, never assigned invented hashes.
  3. `plan` is deterministic for identical declared inputs, read-only, includes stable job IDs and graph/dependency ordering, and estimates sampled frames, direction renders, output dimensions and workload without decoding full-resolution images or mutating production data.
  4. `validate` detects missing/changed FBX and master hashes, invalid/incompatible skeletons, action mismatches, duplicate semantic output identities and path collisions, invalid policies, unsafe input/output paths, and absent approved runtime timing without importing or changing source/model files.
  5. `check` detects changed or missing declared inputs and contract/plan drift without modifying source, master, manifests or outputs.
  6. Long source ranges including 264 and 299 frames remain valid and their planned estimates are correct; no 120-frame ceiling is inherited.
  7. Root-motion metadata separates preserved source trajectory from local in-place pose and declares a single Godot application route; no policy permits double application.
  8. No candidate passes technical QA into implicit production approval. The implementation has no renderer/executor command.
  9. Focused tests cover valid manifests, missing files, changed hashes, duplicate identities, skeleton failures, master changes, unknown root-motion policy, long clips, deterministic IDs, missing timing authority, path collisions/traversal and dry-run immutability.
  10. The reuse map identifies safe reusable interfaces and explicitly marks unavailable or hardcoded Blender routines without rewriting functional utilities.
  11. Task 002 proposal is limited to one Neutral Idle Blender proof and names the source/master authorization, retarget checks, evidence and explicit human approval boundary.
- Validation: Run focused compiler CLI tests (including mutation/read-only negative controls); run Python syntax/compile checks for new modules; validate all example JSON/schema documents and deterministic `plan` output; run `git diff --check`; run applicable changed-file/AI-context validation. Do not launch Godot broad sweeps or Blender renders because neither is needed for this contract-only foundation. Record exact commands/results in the closing summary.
- Task overrides: `none`
- Deferred: Task 002’s single Neutral Idle Blender proof; bulk FBX processing; eight-direction sprite rendering; subjective art approval; final-master selection; runtime ingress/promotion; any design decision changing live modular presentation.

## Next Handoff
- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `not-recorded`
- Refresh reason: Human approval of compiler interfaces and source contracts is required before Task 002.
- Next action: Stop after Task 001 closeout and present the interface/source-contract evidence for human approval.
- Blockers or open questions: The named `operator_3d_master` diagnostic scripts and ITER003–005 diagnostics were absent during packet authoring; confirm authorized source availability before any follow-on Blender proof.
