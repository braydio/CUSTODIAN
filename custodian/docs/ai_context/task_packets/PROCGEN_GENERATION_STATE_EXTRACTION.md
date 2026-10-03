# PROCGEN GENERATION STATE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-generation-state-extraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, review-procgen-distant-chunk-unload-review-corrections-1`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `cdf5a2d4a1259df11d27605208a01401a7d80627`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Extract accepted-world generation snapshot/level-data export ownership from ProcGenTilemap into a focused generation-state authority.
- Completion boundary: REFRESH-GATED on reviewed M6 / cycle-1 re-review. Before execution, re-audit the post-cycle-1 M6 review accepted-world/export surface and rewrite this packet in place. The eventual slice closes when immutable/base accepted-world generated-state capture, level-data assembly/serialization, deterministic fingerprints, and terrain/result export live behind one focused owner in the existing `custodian/game/world/procgen/generation/` package, with runtime mutation overlays represented separately and `ProcGenTilemap` delegating.
- Current measured state: `custodian/game/world/procgen/generation/README.md` already contains `candidate_evaluator.gd`, `candidate_semantic_adapter.gd`, and `procgen_candidate_materializer.gd`; it explicitly still names `ProcGenTilemap` as runtime topology/final-realization authority. `ProcGenTilemap` currently owns `_capture_generated_tile_state`, `get_level_data`, `_get_terrain_builder_level_data`, generated floor/wall debug/fingerprint accessors, terrain/result export, and numerous exported semantic dictionaries. Rejected candidates still construct live TileMap-backed state, so this D3 extraction must preserve the exact G2/G4/G5 contracts that feed the later GenerationGrid audit.
- Evidence: `custodian/game/world/procgen/generation/README.md`; `candidate_evaluator.gd`; `candidate_semantic_adapter.gd`; `procgen_candidate_materializer.gd`; current `proc_gen_tilemap.gd` capture/export functions; `custodian/tools/validation/procgen_candidate_promotion_smoke.gd`; `procgen_candidate_semantic_model_smoke.gd`; `procgen_spatial_normalization_smoke.gd`; `world_contract_prewarm_smoke.gd`; S1 fingerprint schema.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; S1 benchmark schema; current level-data consumers.
- Work surface: Intentionally refresh-gated. The eventual accepted-world state/export owner belongs in the existing `custodian/game/world/procgen/generation/` package beside, but not merged with, the evaluator/semantic-adapter/materializer owners. Reuse their schemas/contracts; do not create a second candidate snapshot authority. `ProcGenTilemap` remains a façade/runtime host until the later GenerationGrid migration and D4 contraction.
- Change: None while blocked. After M6, re-derive which state is immutable accepted-world data versus runtime mutation overlay, then extract capture/export/serialization as one coherent owner. Preserve externally consumed level-data keys unless a versioned migration is unavoidable and explicitly tested.
- Preserve: Fingerprints, level-data keys, terrain/road/region/intent data, ContractWorldLoader consumers, minimap/debug consumers.
- Non-goals: No save-system work, no loader placement extraction here, no semantic model redesign.
- Acceptance: Not implementation-ready until refreshed post-cycle-1 M6 review. Final acceptance must prove fixed fingerprints/level-data parity, one accepted-world capture/export owner, explicit separation from mutable runtime overlays, no duplicate candidate snapshot/evaluator authority, and `ProcGenTilemap` delegation for migrated export/capture paths.
- Validation: Refresh after the cycle-1 M6 re-review. Expected focused suite: `res://tools/validation/procgen_candidate_promotion_smoke.gd`, `res://tools/validation/procgen_candidate_semantic_model_smoke.gd`, `res://tools/validation/procgen_spatial_normalization_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, S1 quick, and changed-file closeout.
- Task overrides: `none`
- Deferred: Facade contraction follows all ProcGenTilemap extraction siblings. The post-D1/D2/D3 GenerationGrid audit/migration initiative now sits before D4.


## Temporary Archive Resolve Refresh Guard — REMOVE DURING THIS PACKET'S REQUIRED REFRESH

Archive Resolve is now a locked presentation program under
`design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`, with pre-authored
AR1/AR2/AR3 packets under this task-packet directory.

Before implementing this procgen rewrite slice, the agent must confirm that the
Archive Resolve packet set has been refreshed against the reviewed post-cycle-1 M6 review live
streaming surface. If Archive Resolve has already landed, re-audit and preserve
its request/commit/unload/reacquisition observation seams as presentation-only
consumers; do not absorb its state into road, claim, generation, or façade
authority. If the AR packets are still pre-refresh or the ordering is unclear,
stop and leave this packet blocked rather than moving the seam out from under
them.

When this packet is refreshed from live main and made implementation-ready,
replace this temporary guidance with the exact live preservation/ownership
contract and **delete this entire Temporary Archive Resolve Refresh Guard
section**. Its continued presence means this packet is not ready to implement.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.


## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh instruction: Bring the landed predecessor implementation/review summary and any new live-state evidence back to this ChatGPT conversation. Re-derive this packet here with the user against current `main` before changing it to `ready/auto`. Do not let the execution agent silently reinterpret architecture, scope, sequencing, visual direction, or acceptance during the refresh.

## Handoff

- Next action: Finish normally. Once D1+D2+D3 are all complete, `procgen-generation-data-model-audit` becomes eligible. D4 no longer follows these siblings directly; it is blocked behind the measured GenerationGrid migration initiative.
- Best starting files: _capture_generated_tile_state, get_level_data, debug fingerprint helpers, generation/ semantic types.
- Blockers or open questions: None known at authoring time.
