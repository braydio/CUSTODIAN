# PROCGEN ROAD AUTHORITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-road-authority-extraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, review-procgen-distant-chunk-unload-review-corrections-1`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `cdf5a2d4a1259df11d27605208a01401a7d80627`
- Goal: Extract the road/parking topology, repair/pruning, and road-authority state still embedded in `ProcGenTilemap` into the existing `custodian/game/world/procgen/roads/` package **without** duplicating the already-extracted Road Semantics V2 resolver in `custodian/game/world/procgen/surfaces/road_semantics_resolver.gd`.
- Completion boundary: REFRESH-GATED on reviewed M6 / cycle-1 re-review. Before this packet returns to `ready`, re-audit the post-cycle-1 M6 review `ProcGenTilemap` road inventory. The eventual slice closes when the state/algorithms named by `custodian/game/world/procgen/roads/README.md` (road/parking graph building, repair, pruning, road authority helpers, connected-road/path metrics) have one stateful owner under `procgen/roads/`; `ProcgenRoadSemanticsResolver` and `ProcgenSurfaceMaterialResolver` remain in `procgen/surfaces/`; presentation-only road decal realization is left with its actual presentation owner unless the post-cycle-1 M6 review audit proves it inseparable.
- Current measured state: `custodian/game/world/procgen/roads/README.md` is scaffold-only and names `ProcGenTilemap` as current road source of truth. `ProcGenTilemap` is currently 11,441 lines / 588 functions and still contains `_carve_main_roads`, connectivity repair/pruning/component analysis, parking anchor/stamping, `_clear_procgen_road_authority_at`, connected-road queries, and road walkability/authority helpers. Separately, active Road Semantics V2 is already extracted to `custodian/game/world/procgen/surfaces/road_semantics_resolver.gd`, with material classification in `surface_material_resolver.gd`; those existing owners must not be reabsorbed or cloned. Wide-road carving remains production-disabled.
- Evidence: `custodian/game/world/procgen/roads/README.md`; current `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/surfaces/road_semantics_resolver.gd`; `custodian/game/world/procgen/surfaces/surface_material_resolver.gd`; `custodian/tools/validation/procgen_road_semantics_v2_smoke.gd`; `custodian/tools/validation/procgen_road_surface_roles_smoke.gd`; `custodian/tools/validation/procgen_placeholder_roads_smoke.gd`; `custodian/tools/validation/compound_road_wall_smoke.gd`; G5 and eventual M6 summaries.
- Task-specific authority: `custodian/game/world/procgen/roads/README.md`; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; live Road Semantics V2 owner at `custodian/game/world/procgen/surfaces/road_semantics_resolver.gd`; current surface-material contract.
- Work surface: Intentionally refresh-gated. Expected owner package is the existing `custodian/game/world/procgen/roads/` scaffold, with narrow delegation from `custodian/game/world/procgen/proc_gen_tilemap.gd`. Preserve `custodian/game/world/procgen/surfaces/road_semantics_resolver.gd` and `surface_material_resolver.gd` as separate already-extracted semantic/material owners. Update `roads/README.md`, FILE_INDEX, and validation ownership when the owner becomes real.
- Change: None while blocked. After M6, refresh this packet from the live function/state inventory. The implementation should move only coherent road/parking topology and authority state, preserving disabled archived wide-road generation and active route-backed ruined-road/service-apron semantics. Do not move presentation/surface classification merely to maximize line reduction.
- Preserve: All road topology/fingerprints, walkability, parking/service apron behavior, decals/material roles, streaming visibility.
- Non-goals: No road redesign, no enabling archived wide roads, no art changes, no claim/export extraction in this packet.
- Acceptance: Not implementation-ready until the post-cycle-1 M6 review inventory is refreshed. Final acceptance must prove one owner for the road/parking topology/repair/authority state selected by that audit; no duplicate migrated state in `ProcGenTilemap`; Road Semantics V2/material resolver ownership unchanged; fixed-seed road/parking fingerprints, walkability and relevant presentation outputs unchanged.
- Validation: Refresh after the cycle-1 M6 re-review. Expected focused suite: `res://tools/validation/procgen_road_semantics_v2_smoke.gd`, `res://tools/validation/procgen_road_surface_roles_smoke.gd`, `res://tools/validation/procgen_placeholder_roads_smoke.gd`, `res://tools/validation/compound_road_wall_smoke.gd`, S1 quick, and changed-file closeout.
- Task overrides: `none`
- Deferred: Authored claims and generation-state extraction proceed as sibling dependents; façade contraction waits on all.


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

## Handoff

- Next action: Finish normally. Once D1+D2+D3 are all complete, `procgen-generation-data-model-audit` becomes eligible. D4 no longer follows these siblings directly; it is blocked behind the measured GenerationGrid migration initiative.
- Best starting files: ProcGenTilemap road methods; procgen/surfaces road resolvers; road smokes.
- Blockers or open questions: None known at authoring time.
