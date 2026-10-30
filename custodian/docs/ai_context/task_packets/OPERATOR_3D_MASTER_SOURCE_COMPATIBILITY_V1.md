# Operator 3D Master Source Compatibility V1

- Packet schema: custodian.task_packet.v2
- Workstream: operator-3d-master-source-compatibility-v1
- Category: `assets-art`
- Status: draft
- Dispatch: manual
- Priority: P2
- Depends on: none
- Locks: operator-3d-master-source-compatibility
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-3d-master-source-compatibility-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: An incorrect rig/master compatibility decision can silently reuse stale retargeted motion or reuse pixels with changed material/camera dependencies.
- Reviewed main: 3dbbdc450d62c052c954ec8e999e8988a9e266ff
- Authoring chat: not-recorded
- Visual review: conditional
- Goal: Establish a trustworthy candidate-only validation contract for substituting an authorized 3D Operator model master without unsafe motion reuse.
- Completion boundary: Add focused read-only master/skeleton/texture compatibility inspection and cache-invalidation report reusing existing Task 001 schema. Does not create, repair, choose, approve or release any model.
- Current measured state: Main owns custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json and contracts. The 42-bone ITER005 experimental master and .meshy legacy decoder remain on model branches rather than canonical approved main. The source-master acceptance decision is not recorded. The active executor consumes pinned source/master identities and owns its own cache stages; this work may only supply compatibility evidence, not replace those stages.
- Evidence: Main custodian/tools/operator/animation_compiler/README.md, cli.py and schemas/master.v1.schema.json; archived Task 001 and review; model branches agent/operator-3d-master-modeling-proof-v1 and -iter005; design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md.
- Task-specific authority: Task 001 master.v1 schema, rig rest/signature and explicit retarget policy, hash-bound render/camera profile; Asset Pipeline V2 owns all subsequent source ingress and review, not the compatibility report.
- Work surface: Focused inspector under custodian/tools/operator/animation_compiler/ or existing master-inspection owner, small GLB/Blender fixtures, unit tests and README.
- Publication inputs: custodian/tools/operator/animation_compiler/schemas/master.v1.schema.json, custodian/tools/operator/animation_compiler/cli.py, custodian/tools/operator/animation_compiler/README.md, design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md, design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md
- Change: (1) Reconcile existing model workstream and source-inspection tooling first; stop if an equivalent validator already exists. (2) Accept explicitly authorized, read-only standard GLB/Blender sources and exact pinned hashes, with bounded import parameters/version; never silently use an arbitrary host path. (3) Inspect mesh, topology, UV, normalized weights, armature/rest/skeleton mapping, material and texture dependencies and exact render policy. Report missing or unverifiable evidence as UNKNOWN/INCOMPATIBLE, not compatible. (4) Compare an exact baseline to another candidate: identical rest signature and retarget contracts permit motion reuse; changed rest/signature or mapping invalidates retarget; changed material/mesh/texture/camera invalidates render and descendants, not validated prior motion. (5) Emit canonical JSON with stable dependency hashes, model-selection status candidate_unapproved and explicit invalidation reasons. (6) Test same-rig/different-texture, changed-rest, missing texture, symlink/path escape, altered export version and corrupt source. (7) Provide a read-only adapter to the executor's existing master dependency identity; do not create a second master registry. A gated legacy .meshy decoder is not a prerequisite or a substitute for a standard authorized export.
- Preserve: Existing master.v1 schema and compiler, experimental modeling branch/WIP artifacts, source/texture bytes, 128px eight-view fixed camera/root, independent art approval and current runtime selector/timing.
- Non-goals: No new 3D model, sculpt/weight/rig edit, source download, .meshy reverse engineering, source-to-runtime ingestion, camera redesign, production character art or timing approval.
- Acceptance: (A) Identical verified sources produce byte-identical reports. (B) Same-rest/new-texture case preserves motion compatibility and invalidates render only. (C) Different rest/mapping refuses reuse of old retarget motion. (D) Missing/unsafe inputs fail closed. (E) All model/source hashes stay unchanged and no source/runtime/Asset V2 directory receives outputs or approval.
- Validation: Focused master inspector unit and negative tests, bounded Blender clean import integration using verified fixtures, existing Task 001 compiler tests, original source before/after hashes and git diff --check; no full model render unless a genuinely material visual review is required.
- Task overrides: TASK OVERRIDE: Do not claim this work while the experimental modeling owner remains unresolved; no master approval, direct asset inbox write, alternate registry or runtime switch.
- Deferred: Future model choice, Meshy decode migration if separately required, actual Asset V2 source approval and coherent runtime cohort release.

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: not-recorded
- Refresh instruction: Reconcile exact active modeling/Task 015 ownership, identify an authorized standard GLB/.blend proof input and inspect existing master validator before promoting. If source model approval is unresolved, compatibility validation may be specified but no art admission may occur.
- Claim state: draft/manual pending targeted authoring preflight and dispatcher eligibility.

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Summary backlink: n/a
- Refresh reason: A compatible model is not an approved model; require explicit human visual/model-family choice for future source adoption.
- Next action: Report exact source compatibility matrix and whether any further model candidate is needed.
- Blockers or open questions: No selected/approved canonical 3D master.
