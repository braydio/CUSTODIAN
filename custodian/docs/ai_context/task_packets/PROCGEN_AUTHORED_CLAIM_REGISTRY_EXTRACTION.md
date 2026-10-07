# PROCGEN AUTHORED CLAIM REGISTRY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-authored-claim-registry-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, review-procgen-distant-chunk-unload-review-corrections-1, review-procgen-road-authority-extraction`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-authored-claim-registry-extraction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial single-owner extraction inside ProcGenTilemap; claim persistence must remain correct across runtime mutation, M6 unload/reload, authored ingress placement, and D1 road-authority delegation`
- Reviewed main: `bff2d89496c68f73072fb69caa7eb3d68abf6aca`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Summary backlink: Every durable implementation/review/recovery/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4` exactly.
- Goal: Extract durable authored-world claim metadata and membership from `ProcGenTilemap` into one canonical registry under `custodian/game/world/procgen/authored_claims/`, while leaving physical floor/wall/elevation realization, road authority, runtime blockers, worldgen intent reservations, route/encounter clearances, terrain diagnostics, and presentation-derived masks with their existing owners.
- Completion boundary: Done when one `ProcgenAuthoredClaimRegistry`-equivalent owner canonically stores authored floor-footprint claims, committed world-overlook claims, and world-ingress dressing-clearance claims; all public façade claim/query APIs delegate their durable claim state to that owner; `ProcGenTilemap` applies the existing floor/wall/elevation/foliage/prop/navigation realization effects from registry-produced claim geometry without keeping duplicate claim stores; M6 unloaded-tile mutation/reload semantics remain exact; and a deterministic registry snapshot proves single-owner state while intentionally excluded reservation/clearance families remain unchanged.
- Current measured state: `review-procgen-distant-chunk-unload-review-corrections-1` is complete/passed and S7 is closed. D1 `procgen-road-authority-extraction` is landed and its fresh paired review passed on main with 0 blocking defects / 0 material gaps; the two D1 findings are explicitly non-blocking and do not change the authored-floor road-clear façade contract that D2 depends on. D3 `procgen-generation-state-extraction` is also landed: `ProcgenAcceptedWorldExport` now owns accepted-world capture/69-key level-data/fingerprint export while mutable generated floor/wall stores remain in `ProcGenTilemap`. The reviewed spawn-residency correction also separates canonical spawn authority from presentation residency and leaves authored-claim ownership untouched. Therefore every declared D2 dependency is satisfied and the previous D1 review gate is closed. Live durable authored-claim scope remains authored floor-footprint claims, committed world-overlook claims, and world-ingress dressing-clearance claims; worldgen reservations, encounter/route clearances, presentation masks, runtime blockers, terrain-required state, D1 road state, and D3 generation/export state remain explicitly outside D2.`
- Evidence: passed MR6R1 receipt and `REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`; landed D1 packet/summary and live `procgen_road_authority.gd`; `custodian/game/world/procgen/authored_claims/README.md`; live `proc_gen_tilemap.gd` claim APIs/state; `intent/region_footprint_reserver.gd`; `diagnostics/procgen_required_cell_classifier.gd`; `special_rooms/special_room_runtime_inserter.gd`; story/faction geometry stampers; `world_ingress_spawner.gd`; M5/M6 claim mutation coverage; authored-scene/Threadway/Sundered Keep/terrain-required validation.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; reviewed M6 residency contract; landed D1 road-authority contract; current authored-scene/overlook/ingress APIs; Archive Resolve remains a presentation-only observer.
- Work surface: Primary new owner: `custodian/game/world/procgen/authored_claims/procgen_authored_claim_registry.gd` (or equivalently focused name). Integration: narrow registry initialization/reset/delegation in `proc_gen_tilemap.gd`; update `authored_claims/README.md`; focused validation/manifest ownership; only directly stale docs/indexes. Existing callers keep using the current `ProcGenTilemap` façade APIs unless a direct in-package caller benefits from the owner without bypassing physical realization.
- Change: Add one stateful authored-claim registry with no scene-tree dependency and no broad `ProcGenTilemap` reference. It owns normalized durable records for: (a) authored floor-footprint claims, including footprint/claim rect, region type, zone, margin and base-floor-visual intent; (b) committed world-overlook footprint identity/metadata; and (c) world-ingress dressing-clearance tile rects. It exposes reset, claim insertion, category clear where current behavior requires it, cell/rect membership queries, deterministic ordered snapshots, and claim-cell projection. Preserve duplicate-call behavior exactly; do not silently deduplicate calls if live behavior currently applies them more than once.
- Change: Keep the public façade names `claim_procgen_floor_rect_for_authored_scene_world`, `claim_procgen_floor_rect_for_authored_scene_tiles`, `claim_world_overlook_pocket`, `plan_world_overlook_pocket`, `commit_world_overlook_pocket_plan`, `claim_world_ingress_dressing_clearance`, `is_inside_world_ingress_dressing_clearance`, and `clear_world_ingress_dressing_clearances`. Their durable claim metadata/membership must delegate to the registry. Existing external callers such as Ash Bell, special rooms, story rooms, faction sites and world ingress placement must not be forced onto a second API.
- Change: Separate **claim ownership** from **world realization**. The registry computes/returns deterministic claim geometry and records durable claim state; `ProcGenTilemap` remains responsible for applying generated floor/wall/elevation/region mutations, chunk-payload invalidation, road-authority clearing, foliage/prop clearing, runtime wall collision, shadows and navigation through the existing helpers. The registry must never paint TileMap cells, rebuild navigation/collision, clear roads, or know streaming visibility.
- Change: Preserve overlook-pocket behavior without broadening registry authority. Durable committed overlook footprint metadata belongs in the registry. Topology-dependent planning/realization that reads generated floor/wall state, terrain-required cells, Sundered Keep protection, virtual connector floor/wall maps, moat erasure, RuntimeWalkableBoundary rebuilds, and navigation remains in the façade/current owners unless a small pure geometry helper can move without importing those authorities. Do not move generated floor/wall dictionaries into the registry just to make `plan_world_overlook_pocket()` look “fully extracted.”
- Change: Move `_world_ingress_dressing_clearance_rects` out of `ProcGenTilemap` completely. `claim_world_ingress_dressing_clearance()` converts the world rect through the canonical spatial seam, records the resulting tile rect in the registry, then keeps the current foliage/prop-clearing side effects in the façade. `is_inside_world_ingress_dressing_clearance()`, clear, M6 protected-chunk calculation, macro-presentation protected/ingress inputs, spawn exclusion, and any other consumers must read registry state/snapshots rather than a façade mirror.
- Change: Route authored floor claim registration through the registry before realization. The existing physical mutation loop remains semantically identical: clear canonical road authority through the D1 owner/facade seam, force authored floor authority, invalidate M5 chunk payload state, preserve M6 “canonical mutation while UNLOADED, no premature repaint” behavior, update elevation/region state, and perform the same bounded collision/overlay/shadow/navigation refresh after the batch. Registry state must not become a replacement for `_generated_floor_cells`/`_generated_wall_cells`.
- Change: Keep worldgen-intent reservations outside D2. `RegionFootprintReserver.build_reservations()` remains owner of `floor_cells` + `reserved_regions`; `_worldgen_reserved_regions` remains generation-planning state for D3/GenerationGrid work. Do not copy it into the registry. Story/faction stampers may consume those reservations and then create authored floor claims through the façade, at which point the resulting authored claim is registered normally.
- Change: Keep all other look-alike stores outside D2: `_encounter_reserved_cells`, route-playability hard clearance, macro-presentation dressing clearance, derived `_surface_claim_cells`, nonwalkable-surface `surface_claims`, runtime prop blockers, portal/compound-ingress locations, terrain-required classifier entries, and D1 road state. They may be consumers/conflict inputs but must not be migrated or mirrored.
- Change: Add a deterministic read-only debug snapshot on the façade delegating to the registry. At minimum report schema/version, ordered claim records by category, category counts, ingress-clearance rects, and a stable claim fingerprint derived only from registry-owned state. The snapshot is validation/diagnostic only; gameplay must not branch on it.
- Change: Update `authored_claims/README.md` from scaffold-only to the precise ownership boundary above. Update validation ownership so changes to the registry select its focused smoke plus the authored-scene, ingress/Threadway and M6 claim-mutation regressions.
- Preserve: Exact authored floor/overlook extents; region/zone metadata; D1 road clearing semantics; ingress dressing-clearance dimensions and clearing effects; required-ingress placement; Threadway isolation/connector behavior; Sundered Keep frontage/protection; special/story/faction room geometry; terrain required-cell sets; route playability; runtime blockers; M5 payload invalidation; M6 unload/reload; AR request/commit/unload/reacquisition presentation observation; fixed-seed floor/wall/elevation/level-data output; S1 determinism.
- Non-goals: No worldgen-intent reservation extraction; no generation-state/export extraction; no runtime blocker migration; no encounter/route clearance migration; no presentation claim migration; no new claim kinds merely to unify names; no road redesign; no topology repair; no claim-based gameplay redesign; no GenerationGrid work; no façade contraction beyond direct claim delegation.
- Acceptance: (1) one registry is the only durable owner of authored floor-claim records, committed overlook-claim records, and world-ingress dressing-clearance rects; `ProcGenTilemap` has no duplicate backing claim/clearance store. (2) Existing public façade claim/query methods and all current external callers remain behavior-compatible. (3) Registry has no scene-tree/TileMap/navigation/collision/road-authority dependency and receives only data needed to normalize/store/query claims. (4) Authored floor claims preserve exact floor/wall/elevation/region output and D1 road-authority clearing; no stale road state remains after a claim. (5) A claim against an M6-UNLOADED tile updates canonical generated state and registry state without painting the tile; reload paints the updated canonical payload and registry fingerprint/state does not change merely because residency changed. (6) World-ingress dressing clearance preserves exact membership, foliage/prop clearing, spawn exclusion, macro-presentation exclusion and protected-streaming-chunk behavior through registry delegation. (7) Overlook pocket planning/commit preserves existing isolated/non-isolated geometry, moat conflict rules, connector preflight, required-cell/Sundered Keep protection and immediate physical boundary behavior; committed footprints appear in the registry without moving generated topology ownership there. (8) Story/faction/special-room/Ash-Bell callers all produce the same claimed extents and deterministic registry records. (9) `_worldgen_reserved_regions`, encounter reservations, route hard clearances, macro dressing clearance, derived surface-claim masks, runtime blockers, terrain required-cell classifier and D1 road state remain with their existing owners and are not mirrored into the registry. (10) Registry reset/clear semantics prevent claims leaking between map generations or ingress-placement reruns. (11) Deterministic registry snapshot/fingerprint is stable across repeated identical fixed-seed runs and invariant under M6 unload/reload presentation churn. (12) Archive Resolve code/state and its observation seams are untouched by this extraction. (13) S1 quick remains `determinism_ok=true` at the accepted fingerprint unless an independently justified mainline baseline change lands first.
- Validation: Create/register a focused authored-claim-registry smoke first. It must directly exercise reset/record/membership/snapshot determinism without a map, then exercise façade delegation on a real `ProcGenTilemap`. Run `procgen_authored_scene_authority_smoke.gd`, `ash_bell_threadway_generation_contract_smoke.gd`, `ash_bell_threadway_causeway_smoke.gd`, `sundered_keep_ingress_smoke.gd`, `world_ingress_spawner` validation, `procgen_terrain_required_cells_smoke.gd`, `procgen_runtime_health_smoke.gd`, `procgen_chunk_payload_cache_smoke.gd`, M6 `procgen_distant_chunk_unload`, D1 road-authority/road-semantics regressions, candidate materializer parity via its manifest id, and S1 quick. Add a focused assertion that an authored claim applied to an unloaded tile does not repaint until re-request/reload while registry state remains stable. Run changed-file validation, packet/review-pairing checks and `git diff --check`.
- Task overrides: `none`
- Deferred: D3 generation-state extraction remains the sibling owner of accepted-world snapshot/export. X1 Generation Data Model Audit starts only after D1+D2+D3 are reviewed/landed. Any future desire to unify worldgen reservations with authored claims must be justified by the post-D audit rather than by naming similarity.

## D1 Review Gate

D2 has now been fully refreshed against passed MR6R1, landed D1 implementation, and the live post-M6 claim surface. The obsolete M6/Archive Resolve manual-refresh guard is removed.

The D1 review gate is satisfied. `review-procgen-road-authority-extraction` passed with 0 blocking defects / 0 material gaps. Its two findings are non-blocking and do not change the road-clear façade contract. D2 is therefore ready/auto on current main with no further planning refresh required. Preserve the D1 findings as later road/GenerationGrid proof-hardening only; do not absorb them into D2.

## Recommended Implementation Order

1. Add the registry owner, README contract and owner-level deterministic smoke; migrate only registry reset/state/query APIs first.
2. Move ingress-clearance backing state/query/clear into the registry and convert all façade consumers.
3. Register authored floor claims and committed overlook claims while keeping physical realization in `ProcGenTilemap`; remove duplicate façade claim stores.
4. Validate M5/M6 unloaded claim mutation and D1 road-clearing parity.
5. Convert remaining claim consumers/debug probes, add deterministic snapshot/fingerprint, update validation ownership/docs, and run the full focused/changed-file closeout.

## Agent Search Budget

Start with: `proc_gen_tilemap.gd` claim methods at the authored-floor/overlook/ingress blocks; `_world_ingress_dressing_clearance_rects` and every direct consumer; `_force_authored_scene_floor_authority`; D1 `ProcgenRoadAuthority` clearing seam; `authored_claims/README.md`; `world_ingress_spawner.gd`; story/faction/special-room callers; M5/M6 claim mutation tests; authored-scene/Threadway/Sundered Keep focused tests. Expand only from a direct caller or failing test. Do not survey unrelated combat, biome, generation-grid, Operator, or presentation implementation.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `<fill at closeout>`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `none | fixed-in-scope | manual-follow-up`

## Handoff

- Next workstream: `review-procgen-authored-claim-registry-extraction`
- Next packet state: `dependency-gated until D2 lands`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none after D1 review passes without a road-clear ownership correction`
- Next action: Complete the D1 paired review. If it passes without changing the authored-scene road-clear contract, D2 may auto-claim directly from this refreshed packet.
- Blockers or open questions: D1 paired review is still ready/unrun on current main.
