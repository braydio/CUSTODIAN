# Procgen Showcase Runtime Inspector

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-runtime-inspector`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-showcase-generation-controls, procgen-showcase-exhibit-catalog`
- Locks: `procgen-showcase-inspector`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review rationale: `Paired review retired 2026-11-12 by owner decision; focused validation is the acceptance gate.`
- Reviewed main: `074e7c9329b598056785130676fa69fae2b6a18f`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `none`
- Goal: Inspect live accepted generated-world truth through read-only terrain/route/playability/POI/asset provenance overlays without new authority.
- Completion boundary: Ship the exact PGA-5 scoped behavior through the existing gallery owners, register its focused smoke, pass affected runtime validation, and obtain owner review of the landed change; no proxy closure or speculative ownership changes.
- Current measured state: PGA-4 owns the accepted arena session and exposes lifecycle status, but it has no public accepted-world snapshot. PGA-5 needs one detached projection through that ownership chain; bounded overlays and stale-state clearing remain unimplemented.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_inspector.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_overlay.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_session.gd`, `custodian/game/world/procgen/generation/accepted_world_export.gd` (read-only consumption), `procgen_showcase_inspector_smoke.gd` (planned in `custodian/tools/validation/levels/`), `custodian/tools/validation/validation_manifest.json`.
- Change: Expose event/request-driven inspector snapshots of session state, selected seed/preset, busy/accepted/staging counts, Operator activity, accepted-host profile/map size/room count/fingerprint, and available canonical map/spawn/playability/route/site data. Render limited toggleable debug overlays using copied read-only descriptors. Query existing canonical getters; add only the narrow detached session/host projection required. Report unavailable fields honestly. No per-frame world scan, fake labels or input from overlay to gameplay authority.
- Preserve: No candidate mutation, pathfinding duplication, public debug data changing generation fingerprint, or global HUD/Operator UI takeover.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: Overlay counts/fingerprints agree with map owners; disabled costs near zero; opaque/missing fields say unavailable; teardown and seed swap cannot show stale data.
- Validation: `procgen_showcase_runtime_inspector`, `procgen_showcase_generation_controls`, `procgen_showcase_generated_arena`, `procgen_showcase_exhibit_catalog`, `procgen_candidate_semantic_model`, `procgen_accepted_world_export_parity`, and `contract_world_playable_region_spawn_validity`, plus changed-file checks. The registered playability contract currently emits an expected fixture warning when `/root/GameRoot/World/ContractMap` is absent; retain that classification as fixture context, not as a new failure or invented test ID.
- Task overrides: `none`
- Deferred: Human visual comparison deferred to PGA-7; no new semantic authority.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Realized API refresh (2026-11-14; fetched `origin/main@074e7c9329b598056785130676fa69fae2b6a18f`)

- `ProcgenArenaSession.get_session_status()` and `session_updated(status)` are the lifecycle boundary. Status includes state, selected seed/preset, generation fingerprint, busy state, accepted/staging counts and Operator activity; it intentionally does not expose host/map references. `get_presets()` returns a deep copy.
- `ProcgenArenaHost.get_arena_status()` is the accepted-host source for ready/active, seed/profile/preset/map size/room count and generation fingerprint. The host's accepted region/map remain private. `GeneratedRegionLevel.get_generated_map()` is the region's existing map ownership path.
- Add a narrow session-owned read method that delegates through the accepted host and returns a detached inspector snapshot. Do not expose host, region, or map references. Use `ProcGenTilemap.get_level_data()` / `ProcgenAcceptedWorldExport.build_level_data()` and project only present, allowlisted fields; deep-copy mutable values. Never call mutating `capture_tile_state()`.
- Available read authorities include `get_runtime_health_snapshot()`, `get_player_spawn()`, `get_main_playable_component()`, `is_valid_spawn_cell()`, `is_runtime_navigation_walkable()`, `get_floor_tilemap()`, and `get_walls_tilemap()`. `ProcgenPerformanceSnapshot.generation_snapshot()` / `fingerprint_generation()` remain the fingerprint authorities.
- The exhibit catalog's `load_report()` gives validated static provenance. Associate it with accepted map data only on exact identifier match; otherwise report unavailable/N/A. Do not infer map provenance from a catalog entry alone.
- Build/update on accepted lifecycle or fingerprint changes, or explicit refresh. Preserve the old accepted snapshot while staging; invalidate on accepted-host replacement/disposal and session/inspector teardown. Overlay rendering consumes copied descriptors only, with at most 1024 descriptors per layer, and performs no per-frame source query or full-world scan.
- Keep the Operator, camera, LevelLoader, generator, map acceptance, collision and navigation authorities unchanged.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `completed for PGA-5 API and scope`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Original program authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- This refresh records a realized-API plan; it is not a dispatcher claim, implementation result, or owner acceptance.

## Next Handoff
- Next workstream: `procgen-showcase-runtime-inspector`
- Next packet state: `ready/manual`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Next action: `Acquire through the canonical V2 dispatcher, then implement, validate, publish a feature branch and draft PR under RC-075.`
- Blockers or open questions: `None established by the realized API audit; dispatcher and live capacity checks remain mandatory.`
