# PROCGEN ROAD AUTHORITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-road-authority-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, review-procgen-distant-chunk-unload-review-corrections-1`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-road-authority-extraction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial architecture extraction: road authority/state migration inside the ProcGenTilemap decomplexification lane`
- Reviewed main: `baa4a7e98fdfc843afaa2985d6ef46ad3e1409f8`
- Goal: Extract generated road/parking/path authority state plus road graph/repair/pruning logic from `ProcGenTilemap` into one focused owner under `custodian/game/world/procgen/roads/`, while preserving Road Semantics V2, presentation, traversal, streaming, and deterministic world output.
- Completion boundary: Done when one `ProcgenRoadAuthority`-equivalent stateful owner under `procgen/roads/` owns the generated road/path/parking authority currently stored directly on `ProcGenTilemap`; road connectivity/component/repair/pruning decisions operate through that owner; `ProcGenTilemap` remains the realization/facade adapter for floor/wall/region mutation and presentation; the already-extracted Road Semantics V2 resolver and surface-material resolver remain separate pure/semantic owners; presentation-only road/path decal state remains outside the road authority; and no duplicate canonical road state survives in `ProcGenTilemap`.
- Current measured state: On `main@baa4a7e9`, `proc_gen_tilemap.gd` is 11,876 lines / 615 functions. It directly declares `_main_road_tiles`, `_road_centerline_tiles`, `_path_centerline_tiles`, `_compound_connector_centerline_tiles`, `_parking_zone_tiles`, `_ruined_road_cells`, `_service_hardstand_cells`, `_road_semantics_summary`, and `_parking_zone_center`. It also embeds archived-wide-road construction/repair/component/pruning methods such as `_carve_main_roads()`, `_repair_road_connectivity()`, `_repair_road_surface_components()`, `_collect_road_surface_components()`, `_collect_connected_road_tiles()`, `_prune_small_edge_road_components()`, `_prune_small_disconnected_road_components()`, parking-anchor/footprint selection, and `_clear_procgen_road_authority_at()`. Production wide-road carving remains disabled by default through `intent_main_roads_enabled=false`; its debug path is still covered by `procgen_road_surface_roles_smoke.gd`. Active Road Semantics V2 already lives in `surfaces/road_semantics_resolver.gd`, returns ruined-road/service-hardstand/parking masks, and is consumed by `ProcGenTilemap._resolve_road_semantics()`. Presentation-only `_road_visual_tiles`, `_path_visual_tiles`, `_compound_connector_visual_candidates`, decal definitions/nodes, and filled-surface role rendering still live in the façade/presentation surface. M6 unload/reveal removes/recreates road decals but does not own road semantics. MR6R1 is complete/passed, so this packet's old refresh gate is satisfied. AR1 is refreshed/ready and its request/commit/unload presentation seam must not be absorbed by this extraction.
- Evidence: `custodian/game/world/procgen/proc_gen_tilemap.gd` road state and methods; `custodian/game/world/procgen/roads/README.md`; `custodian/game/world/procgen/surfaces/road_semantics_resolver.gd`; `custodian/game/world/procgen/surfaces/surface_material_resolver.gd`; `custodian/tools/validation/procgen_road_semantics_v2_smoke.gd`; `procgen_road_surface_roles_smoke.gd`; `procgen_placeholder_roads_smoke.gd`; `compound_road_wall_smoke.gd`; `procgen_authored_scene_authority_smoke.gd`; passed MR6R1 receipt on the archived M6 correction packet.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; `custodian/game/world/procgen/roads/README.md`; live Road Semantics V2 and surface-material resolver contracts; reviewed M6 residency semantics; Archive Resolve remains presentation-only under `STREAMING_REVEAL_PRESENTATION_V1.md`.
- Work surface: Primary new owner: `custodian/game/world/procgen/roads/procgen_road_authority.gd` (or one equivalently focused owner if live code proves a better name). Integration: narrow initialization/reset/delegation in `proc_gen_tilemap.gd`; `roads/README.md`; validation ownership/manifest for the new owner; only directly affected docs/indexes. Preserve `surfaces/road_semantics_resolver.gd`, `surface_material_resolver.gd`, and road/path decal realization as separate owners.
- Change: Add one stateful road authority object that owns canonical generated road/path/parking state: archived wide-road mask, road centerline, path centerline, compound-connector centerline, parking mask/center, active ruined-road mask, service-hardstand mask, and Road Semantics summary. The owner exposes reset, mutation/query, deterministic snapshot/getter, and graph/component operations through a narrow API. Do not pass the entire `ProcGenTilemap` into the owner or let it reach arbitrary private façade state.
- Change: Move deterministic road graph/component/repair/pruning decisions into the road authority. Where a decision needs world mutation, have the owner return a deterministic plan/cell set/repair pair and let `ProcGenTilemap` apply existing floor/wall/region/elevation mutations through its current authoritative helpers. The owner may consume narrow immutable/query context, but it must not become floor/wall/collision/navigation authority.
- Change: Route archived wide-road construction through the owner for all canonical road-state writes. `ProcGenTilemap` may retain orchestration and physical stamping callbacks, but direct writes to the migrated canonical road dictionaries must disappear. Production `intent_main_roads_enabled=false` remains unchanged.
- Change: Keep `ProcgenRoadSemanticsResolver` pure and separate. `_resolve_road_semantics()` continues to build the resolver input in the façade, then publishes the resolver's ruined-road/service-hardstand/parking result into the road authority. Do not duplicate or move its classification algorithm into `procgen/roads/`.
- Change: Convert façade/public/debug consumers to delegate through the road authority: `is_road_surface_tile()`, `is_parking_zone_tile()`, `get_main_road_tiles()`, `get_parking_zone_tiles()`, `get_ruined_road_tiles()`, `get_service_hardstand_tiles()`, road-semantic summary, required-route/pre-terrain road protection, material input assembly, foliage exclusion, macro-presentation claims, authored-scene road clearing, and road debug probes. Internal presentation code may consume read-only owner snapshots but must not become canonical road state.
- Change: Leave presentation-only state and realization outside the road authority: `_road_visual_tiles`, `_path_visual_tiles`, `_compound_connector_visual_candidates`, decal parent/definitions/nodes, `_classify_filled_surface_role()`, texture selection, reveal/unload decal realization, and z/material presentation remain with the façade/presentation path. Streaming unload/reveal must reconstruct from canonical owner snapshots exactly as before.
- Change: Update `roads/README.md` from scaffold status to the real ownership contract and update FILE_INDEX/validation ownership so future edits to the new owner select the focused road tests.
- Preserve: Fixed-seed floor/wall/route/elevation output; Road Semantics V2 fingerprints/masks; production wide-road disabled default; archived opt-in wide-road debug behavior; soft-path natural-material semantics and existing movement multiplier compatibility; parking/service-apron exports; foliage road/parking exclusion; macro-presentation claims; authored-scene road-authority clearing; M3-M6 streaming/lifecycle/cache/unload behavior; AR1 request/commit/unload observation seam; road/path/ruined-road decal keys and deterministic roles.
- Non-goals: No road redesign or new road art. Do not enable archived wide roads. Do not move Road Semantics V2 or surface-material classification into the new owner. Do not extract general region/authored-claim/generation-state authority here. Do not move road decal rendering or Archive Resolve. Do not change navigation/collision/movement tuning. Do not broaden into D2/D3 or GenerationGrid.
- Acceptance: (1) `ProcGenTilemap` no longer declares canonical backing dictionaries/center state for main-road, road-centerline, path-centerline, compound-connector-centerline, parking, ruined-road, service-hardstand, Road Semantics summary, or parking-center state; one road authority owns them. (2) No second mutable road snapshot/mirror is introduced outside explicitly presentation-only visual masks. (3) Public/debug/facade getters return the same sorted/set-equivalent results as before through delegation. (4) Fixed seed `824790` with production defaults preserves exact generated floor/wall, route-playability, elevation, Road Semantics fingerprint, ruined-road cells, service-hardstand/parking cells, macro claims, materials, and movement-surface behavior. (5) Fixed seed `420777` with `intent_main_roads_enabled=true` preserves one connected archived wide-road component, road/parking membership, filled-surface roles, one decal per road cell, and unload/reveal role parity. (6) Authored-scene road clearing removes canonical road/parking authority through the new owner and cannot leave stale state in façade consumers. (7) Pre-terrain/route protection and foliage exclusion consume the owner without changing protected-cell sets. (8) M6 unload/reveal removes and recreates road presentation without mutating canonical owner state. (9) Road Semantics V2 and SurfaceMaterialResolver source files remain algorithmically separate; the extraction does not create a second classification path. (10) Production default remains `intent_main_roads_enabled=false`. (11) S1 quick remains `determinism_ok=true` at the current accepted fingerprint unless an independently justified baseline change lands first.
- Validation: Create one focused road-authority extraction smoke during implementation and register it after the path exists. It should directly compare reset/mutation/query/component behavior and prove façade delegation has no duplicate state. Run it first. Then run `res://tools/validation/procgen_road_semantics_v2_smoke.gd`, `res://tools/validation/procgen_road_surface_roles_smoke.gd`, `res://tools/validation/procgen_placeholder_roads_smoke.gd`, `res://tools/validation/compound_road_wall_smoke.gd`, `res://tools/validation/procgen_authored_scene_authority_smoke.gd`, M6 `procgen_distant_chunk_unload`, candidate materializer parity via manifest id `procgen_candidate_materializer_parity`, S1 quick, changed-file validation, packet/review-pairing checks, and `git diff --check`.
- Task overrides: `none`
- Deferred: D2 authored-claim registry extraction and D3 generation-state extraction remain sibling workstreams. X1 Generation Data Model Audit starts only after D1+D2+D3 are reviewed/landed per the program DAG.

## Recommended Implementation Order

1. Add the road authority owner and focused owner-level smoke; migrate reset/state/query APIs first without changing road algorithms.
2. Move connected-component, connectivity/repair/prune decision logic onto owner state; keep physical floor/wall/region mutation in `ProcGenTilemap` through narrow returned plans/callback boundaries.
3. Route archived-wide-road orchestration and active Road Semantics V2 result publication through the owner.
4. Convert all façade consumers and remove the migrated backing dictionaries from `ProcGenTilemap`.
5. Verify presentation-only road/path masks and decal reconstruction remain outside the authority, then update `roads/README.md`, validation ownership, FILE_INDEX/current-state docs that changed.

## Agent Search Budget

Start with `proc_gen_tilemap.gd` road state declarations and the road blocks around archived construction/repair/pruning, `_clear_procgen_road_authority_at`, road getters/queries, `_resolve_road_semantics`, material/macro/pre-terrain consumers, `roads/README.md`, the two surface resolvers, and the named focused road smokes. Expand only from a direct caller/test failure. Do not survey unrelated biome, combat, authored-level, or Archive Resolve implementation code.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `removed`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`

## Handoff

- Next action: Auto-claim now when the `procgen-runtime` lock is free. After D1's paired review passes, continue the sibling D2/D3 refresh/execution sequence; X1 waits for all three.
- Best starting files: `proc_gen_tilemap.gd` road state/graph methods; `roads/README.md`; Road Semantics V2 resolver; road smokes.
- Blockers or open questions: None. MR6R1 is complete/passed and Archive Resolve's post-M6 seam is already refreshed.
