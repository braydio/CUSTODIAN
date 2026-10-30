# Operator 3D Directional Atlas Packaging V1

- Packet schema: custodian.task_packet.v2
- Workstream: operator-3d-directional-atlas-packaging-v1
- Status: draft
- Dispatch: manual
- Priority: P2
- Depends on: review-operator-3d-animation-batch-executor-v1
- Locks: operator-3d-animation-atlas-packaging
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, asset-pipeline, workflow
- Paired review workstream: review-operator-3d-directional-atlas-packaging-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: Atlas index integrity and per-cell pixel preservation must be independently proved for full-length multi-page animation.
- Reviewed main: 4e3e88df4512f5bc8e4088d087b7bee3b974d3fe
- Authoring chat: not-recorded
- Visual review: none
- Goal: Convert verified eight-direction 3D-derived animation candidates into reproducible content-addressed, candidate-only atlases with exact source-frame mapping.
- Completion boundary: Add a separable atlas exporter/index/round-trip validator for already-verified candidate frames; no retargeting, Blender rendering, runtime import or asset approval.
- Current measured state: Task 001 on main has eight-direction 128x128 RGBA candidate receipts. The current executor workstream branch at 16e6b0b3 has a corrected 2,104-frame Awakening preview and still owns Slices B–D including PACKAGE. No distinct general atlas exporter was verified on main. Corrected Blender repeat reports only 19 of 24 exact decoded-RGBA samples; atlas reproducibility must be measured against fixed input hashes rather than assume Blender determinism.
- Evidence: custodian/docs/ai_context/task_packets/OPERATOR_3D_ANIMATION_BATCH_EXECUTOR_V1.md; Task 001 archived packet and review; custodian/tools/operator/animation_compiler/README.md; design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md.
- Task-specific authority: Existing candidate receipt, full_body_8dir_128 rendering contract, canonical 128px root and direction policy; the reviewed executor PACKAGE and existing Operator ingress retain their own responsibilities.
- Work surface: Focused candidate pack/verify helper under custodian/tools/operator/animation_compiler/, optional candidate atlas manifest schema, focused unit tests under custodian/tools/validation/, and compiler README.
- Publication inputs: custodian/tools/operator/animation_compiler/cli.py, custodian/tools/operator/animation_compiler/schemas/candidate_receipt.v1.schema.json, custodian/tools/operator/animation_compiler/contracts/full_body_8dir_128_v1.json, custodian/tools/operator/animation_compiler/README.md, design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md, design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md
- Change: First inspect the independently reviewed executor; if it already emits equivalent safe atlases, stop and report duplicate scope instead of adding a competing packer. Accept only an exact verified candidate receipt and original ordered RGBA frames with hashes. Pack N/NE/E/SE/S/SW/W/NW independently in 128px row-major cells on pages at most 2048x2048. A 263-frame direction uses 256 plus 7 on a second page; a 250-frame direction fits one. Record source-frame index, cell x/y, page, decoded source hash, atlas/page hashes, authored FPS preview-only and root trajectory sidecar identity. Test exact decoded RGBA including transparent RGB. Reject path escapes, missing/duplicate/reordered frames, wrong alpha, stale hashes and partial outputs. Atomically publish only ignored/external candidate packages and leave production authority false.
- Preserve: Task 001 planner/receipts, executor stages and cache owner, source/master hashes, fixed 45-degree projection, 50px/m, root (64,106), no mirroring, legacy runtime and selector.
- Non-goals: No re-rendering or correcting Southwest image boundaries, no new runtime spritesheet loader, no Asset V2 ingest, no art or timing approval and no modification of current executor claim.
- Acceptance: (A) Eight-direction 263-frame and 250-frame fixture packages have exact frame-to-atlas round-trip RGBA equality and no duplicate/omitted frames. (B) All page bounds and cells are valid and independently indexable. (C) Identical fixed input bytes produce identical atlas/index hashes. (D) Invalid paths/hashes/directions and stale receipts fail before output publication. (E) All outputs remain candidate_unapproved and runtime/asset files unchanged.
- Validation: New packer-focused unit and negative tests; python3 -m unittest custodian.tools.validation.test_operator_3d_animation_compiler; git diff --check; exact changed-path and output-hash audit; no routine full-motion capture.
- Task overrides: TASK OVERRIDE: Do not alter or bypass the original executor's claimed PACKAGE stage, independent review, timing authority, original sources or Asset V2 approval; stop if overlapping scope is discovered.
- Deferred: Model/runtime promotion, Workbench intake, art and clock choice.

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: not-recorded
- Refresh instruction: Wait for the executor's completed independent review, inspect its actual PACKAGE implementation and cancel or narrow this packet if atlas output already exists. Do not mark ready until the boundary is proven distinct.
- Claim state: draft/manual. Publication is not claim authorization.

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Summary backlink: n/a
- Refresh reason: Choose if and when a verified candidate atlas may participate in a human-approved coherent release cohort.
- Next action: Return exact atlas receipt, independent review result and remaining Asset V2/runtime gate.
- Blockers or open questions: No production art/timing approval is granted by a passing atlas exporter.
