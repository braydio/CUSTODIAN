# Operator 3D to 2.5D Production Roadmap V1

Status: planned; candidate-only; no production approval
Reviewed main: 4e3e88df4512f5bc8e4088d087b7bee3b974d3fe
Authoring chat: not-recorded
Date: 2026-10-30

## Purpose

Build a repeatable offline Operator 3D/FBX -> verified local rig motion -> eight independent 128x128 RGBA views -> candidate package / atlases -> Godot preview -> human review -> established Operator Workbench/Asset Pipeline V2 release process. This does not revive live 3D gameplay or create an alternate runtime selector.

## Current source and tool ownership (2026-10-31)

- The exact experimental ITER005 Blender master and GLB were Git-LFS objects on
  `agent/operator-3d-master-modeling-proof-v1-iter005` at
  `6b89c4d503bb2d73d2783443d4280f313c681bfa`. The source/tooling integration
  workstream has prepared a byte-verified snapshot under
  `custodian/asset_drop/source_work/operator/operator_3d_master/masters/`;
  this lineage does not make the model production-approved.
- Static, unrigged GLB inspection and static eight-direction proofs belong to
  `custodian/tools/operator/model_to_sprite.py`. The historical static
  Meshy/GLB pipeline is an inspected source archive; its old README reference
  to `custodian/tools/iteration/asset_pipeline.py` is stale. The live command is
  the model-to-sprite entrypoint. Rigged GLBs remain outside this static path.
- FBX action inspection, retargeting, reusable motion, animated renders, motion
  QA and animation candidate receipts remain owned by
  `custodian/tools/operator/animation_compiler/`. The old static renderer is not
  an animation renderer. Neither path publishes runtime assets or grants art
  approval.
- The accepted 128px full-body 2.5D source is the visual-design authority, but
  its complete animation cohort is not runtime-promoted. The runtime-promotion
  record still identifies `legacy_96` as live. This distinction does not change
  runtime selection or timing authority.
- The Neutral Idle proof and executor review cited below are historical
  evidence snapshots. The candidate remains artistically unapproved; their old
  workstream heads and review paths are not current branch-state claims.

## Already-owned workstreams

- Historical executor snapshot (recorded 2026-10-30): branch `agent/operator-3d-animation-batch-executor-v1` at `16e6b0b353d00731541721818e98fc8cf343974b`; corrected Neutral Idle receipt `5c237de902397e1bae1f0de6bc3951334369b95db46c9b9e9064ef38b916853b`; Awakening preview manifest `/CUSTODIAN/visual_review/operator-3d-animation-batch-executor-v1/20261030T032053Z/REVIEW_MANIFEST.json`. This records that snapshot only. Check the dispatcher and workstream lifecycle for current ownership; the candidate remains artistically unapproved.
- The existing executor packet already owns Slices B–D: INSPECT, RETARGET, RENDER, QA, PACKAGE, deterministic cache/resume, real multi-FBX first batch and downstream handoff DEFINITION. Do not create duplicate executor/batch packets. Finish and independently review this scope first.
- Running Task 015 ITER005 remains experimental on agent/operator-3d-master-modeling-proof-v1-iter005; the last evidence commit is 6b89c4d503bb2d73d2783443d4280f313c681bfa. Run cycle: 21 frames / 30fps / 0.70s. Integer-frame penetration was cleared, but subframes retain right -8.82mm and left -6.09mm examples. RUN_MOTION_NEEDS_REPAIR and existing owner preservation remain.
- The 42-bone ITER005 master and gated legacy .meshy tooling belong to experimental model branches; an exact compatible rig is not itself an approved character model.
- Production Operator timing, verified art, single selector/catalog and coherent generation-cohort promotion remain governed by design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md and existing draft/manual operator-2-5d-runtime-promotion (WB25-6). Do not mint a competing 3D runtime promotion packet.

## Newly authored successor packet pairs

| Workstream | Intended new boundary | Initial state | Refresh |
| --- | --- | --- | --- |
| operator-3d-directional-atlas-packaging-v1 | Candidate-only multi-page, deterministic 8-way RGBA atlas index and round-trip QA, not executor PACKAGE or runtime ingest | draft/manual | After review-operator-3d-animation-batch-executor-v1, inspect actual PACKAGE first; cancel this task if already equivalent |
| operator-3d-running-contact-followup-v1 | One reversible experimental contact derivative, not the preserved Task 015 claim | draft/manual | Reconcile original owner and human gait review; resume old Task 015 if still active |
| operator-3d-master-source-compatibility-v1 | Read-only source/master compatibility proof for future authorized GLB/Blender masters | draft/manual | Reconcile model branches/validator and authorized source; no model approval |

Each pair has its own fresh-context post-land review. Draft/manual means explicitly NOT claimable. For promotion, first resolve the recorded gate, run targeted validate_task_packet_authoring.py on both packet files, regenerate the Ready/Auto index ONLY with task_packet_index.py --write, verify publication inputs at main, and run dispatch.py audit.

## Gates

1. Human visual refresh: Decide whether the corrected Neutral Idle hands, stance, Southwest last-row contact (152/263 frames) and subtle motion are acceptable. Preview mechanism acceptance does not imply art approval. Candidate-only executor development may be authorized separately.
2. Execution-agent technical refresh: After the original executor and its independent review land, inspect cache identity, PACKAGE behavior and observed repeat-render nondeterminism (19/24 decoded RGBA repeats, 0/24 PNG byte repeats). Do not rebrand failed repeatability as deterministic; escalate new material design decisions.
3. Human/model refresh: Running ITER005 gait and subframe contact verdict, old model workstream claim and source provenance before any new derivative or master admission.
4. Human production refresh: Choose real complete animation cohort and frame projection/loop/FPS policy. The 128px canonical frame root (64,106), direction order N/NE/E/SE/S/SW/W/NW, fixed scale and no mirroring are already locked. Source FBX FPS is preview-only. WB25-6 controls actual release, not this roadmap.

## Candidate outputs and Asset V2 boundary

Verified Neutral Idle: 8 x 263 x 128x128 RGBA at 30 authored preview FPS. A separate verified Idle source targets 250 unique frames per direction if its duplicate endpoint proof remains valid. One atlas page may hold 16x16 128px cells (2048x2048), with a second partial page for a 263-frame direction. Preserve per-cell frame mapping and exact decoded RGBA, including RGB beneath zero alpha. All candidate-only renders/atlases remain in ignored custodian/.ai or an external proof root. Do not invent asset_drop/inbox family IDs or production runtime filenames. Once a real family/state is chosen and approved, derive its custodian/asset_drop/inbox/<registered-family>/<registered-state>.png path and family schema from the current registered Asset Pipeline V2/Operator contract.

Do not modify original FBX/.blend masters, release claims/locks, delete visual reviews, or claim production timing. The compiler example batch intentionally records unavailable repository inputs; host-only files must be separately verified, not silently assigned fabricated hashes.

## Next

Historical next step recorded 2026-10-30: resolve the executor's human visual gate before resuming that executor. For current source/tooling and model work, use the live dispatcher and the dependency-gated packet states; this roadmap's older branch and claim snapshots do not establish current ownership.
