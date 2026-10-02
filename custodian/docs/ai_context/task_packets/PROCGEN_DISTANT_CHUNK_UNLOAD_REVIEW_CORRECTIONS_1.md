# CORRECTION: PROCGEN DISTANT CHUNK UNLOAD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-distant-chunk-unload-review-corrections-1`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-distant-chunk-unload`
- Locks: `procgen-streaming, navigation-runtime`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-distant-chunk-unload-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `035aaafdd`
- Parent implementation: `procgen-distant-chunk-unload`, archived at `custodian/docs/ai_context/task_packets/archived/PROCGEN_DISTANT_CHUNK_UNLOAD.md`
- Parent review: `review-procgen-distant-chunk-unload`, archived at `custodian/docs/ai_context/task_packets/archived/REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD.md`
- Findings addressed: `R0-01, R0-02, R0-03, R0-04, R0-05`
- Affected acceptance: M6's Completion boundary ("without creating frame spikes"); Acceptance items 2 (protected-anchor exclusion), 7 (navigation rebuild retention), 8 (foliage identity/kind/cluster/trunk-collision/blocker parity), 15 (bounded traversal before/after evidence).
- Current defect/evidence: `R0-01` (blocking): `ProcGenTilemap._drain_residency_eviction()` calls `_flush_streaming_visual_rebuilds()` unconditionally and synchronously whenever it evicts a chunk, bypassing the `streaming_visual_rebuild_interval_sec` coalescing accumulator ordinary tile reveal already uses for the same flush (`_process_streaming_reveal_queue()`). That flush does an O(entire-resident-window) wall-collision rebuild (`_sync_runtime_wall_collision_with_visible_walls()`) and horizontal-wall-overlay rebuild (`_rebuild_horizontal_wall_overlays()`), plus navigation/shadow requests whose `_derived_rebuild_scheduler` batch id is keyed to `Engine.get_process_frames()` and so only coalesces within one frame. With the default `streaming_unload_chunks_per_frame = 1`, draining a backlog of N DORMANT-eligible candidates pays this full resident-window cost on N consecutive frames instead of the ~0.15s batched cadence reveal uses. `R0-02`-`R0-05` (evidence gaps): the focused M6 smoke (`procgen_distant_chunk_unload_smoke.gd`) proves the policy/adapter contract abstractly but does not (a) instantiate/rebuild a real `NavigationSystem` after unload, (b) populate/assert protection from real portal/compound-ingress/world-ingress-clearance data (only the spawn chunk is exercised at the integration level), (c) assert foliage `kind`/`cluster_id`/`has_collision`/runtime-blocker-registration parity beyond node identity and `.visible`, or (d) record one bounded-traversal fixture of before/after painted floor/wall cell counts together with the cache/road counts.
- Goal: Close all five cited findings without reopening the accepted M6 design: coalesce eviction-triggered presentation flushes onto the same cadence ordinary reveal uses, and extend the focused M6 smoke with the four missing proof points.
- Completion boundary: Done when (1) a multi-candidate eviction backlog no longer forces one full resident-window wall-collision/overlay/navigation/shadow resync per eviction-frame -- it batches on the existing `streaming_visual_rebuild_interval_sec` cadence exactly like reveal does; (2) the M6 smoke instantiates a real `NavigationSystem`, rebuilds it after a chunk unloads, and asserts the previously-revealed walkable cell remains reachable while an `UNSEEN` probe chunk is excluded; (3) the smoke constructs at least one real portal teleporter (or populates `_last_compound_ingress`/`_world_ingress_dressing_clearance_rects`) and asserts that chunk is never evicted even when DORMANT and far; (4) the smoke asserts the hidden/re-shown foliage node's `kind`, `cluster_id`, `has_collision`, and `has_runtime_prop_blocker_at_tile()` are unchanged across hide/show; (5) the smoke records one before/after fixture combining painted floor/wall used-cell counts, `chunk_payload_cache` cached-membership/record counts, and road-decal presence for the evicted chunk, and asserts the painted/cached counts drop while canonical generated counts stay constant.
- Current measured state: See `REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD_CLAUDE_SUMMARY.md` and the archived M6 packet's `## Independent Review` receipt for full findings detail and evidence.
- Evidence: Independent review receipt (`R0-01`..`R0-05`) on the archived M6 packet; `proc_gen_tilemap.gd` `_drain_residency_eviction()`, `_flush_streaming_visual_rebuilds()`, `_process_streaming_reveal_queue()`, `_sync_runtime_wall_collision_with_visible_walls()`, `_rebuild_horizontal_wall_overlays()`; `navigation_system.gd`; `procgen_distant_chunk_unload_smoke.gd`; `procgen_chunk_payload_cache.gd` telemetry.
- Task-specific authority: The archived M6 packet and its Independent Review receipt; `custodian/game/systems/core/systems/navigation_system.gd`; `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`.
- Work surface: `custodian/game/world/procgen/proc_gen_tilemap.gd` (`_drain_residency_eviction()` flush-coalescing only -- do not touch `_unload_chunk()`'s disposal effects or the residency-policy/lifecycle/cache seams themselves); `custodian/tools/validation/procgen_distant_chunk_unload_smoke.gd` (add the four missing proof sections only). Do not edit `procgen_chunk_residency_policy.gd`, `procgen_chunk_lifecycle.gd`, or `procgen_chunk_payload_cache.gd`'s production code -- those are not implicated by any finding.
- Required correction:
  1. `R0-01`: In `_drain_residency_eviction()`, after any `_unload_chunk()` call, do not call `_flush_streaming_visual_rebuilds()` directly. `_unload_chunk()` already sets `_streaming_visual_rebuild_pending = true`; also accumulate into `_streaming_visual_rebuild_accum` (the same timer `_process_streaming_reveal_queue()` checks against `streaming_visual_rebuild_interval_sec`) so eviction-triggered flushes batch on that existing cadence instead of firing once per eviction-frame. Preserve the current behavior that an evicted chunk's presentation is gone and its collision/foliage/road state is correct by the time the next coalesced flush runs; do not change `_unload_chunk()`'s own disposal effects.
  2. `R0-02`: Add a smoke section that builds a real `NavigationSystem` node (`set_runtime_tilemaps()` wired to the test map's `floor_tilemap`/`walls_tilemap`/`ProcGenTilemap`), calls its graph-build entrypoint before and after unloading the victim chunk, and asserts the victim floor tile remains walkable/reachable in the rebuilt graph while a genuinely `UNSEEN` probe chunk's tiles are absent.
  3. `R0-03`: Add a smoke section that adds one real `Area2D`/`Node2D` to `_portal_teleporters` (or populates `_last_compound_ingress`/`_world_ingress_dressing_clearance_rects`) positioned in a non-spawn chunk, drives that chunk DORMANT and far, and asserts it is never unloaded across repeated `_drain_residency_eviction()` calls while `debug_get_protected_streaming_chunks()` contains it.
  4. `R0-04`: Extend the existing foliage hide/show assertions to also capture and compare `kind`, `cluster_id`, `has_collision` (from the `_foliage_nodes` entry, via a new or existing debug accessor) and `has_runtime_prop_blocker_at_tile(victim_foliage_tile)` before unload, immediately after unload, and after reload.
  5. `R0-05`: Add one recorded before/after block around the existing unload step that reads `floor_tilemap.get_used_cells().size()`, `walls_tilemap.get_used_cells().size()`, `debug_get_chunk_payload_cache_snapshot()`'s cached-membership/record counts, and `debug_has_road_piece_decal()` for the victim tiles, asserting painted/cached counts strictly decrease while `debug_get_generated_floor_cells().size()`/`debug_get_generated_wall_cells().size()` stay exactly constant.
- Preserve: Every passing assertion already in `procgen_distant_chunk_unload_smoke.gd` and `procgen_chunk_payload_cache_smoke.gd`; `_unload_chunk()`'s disposal effects and ordering; the residency policy's bounded-per-frame/protected/cancellation contract; S1 determinism fingerprint `1773840677`.
- Non-goals: No redesign of `ProcGenChunkResidencyPolicy`, the M5 cache, or the M4 lifecycle. No change to `streaming_unload_chunks_per_frame`'s default or to `_effective_unload_distance()`. No new coalescing scheduler -- reuse the existing accumulator. No fix beyond the five cited findings.
- Acceptance: Each finding ID has a falsifiable result: `R0-01` -- a test or direct measurement shows a multi-candidate backlog drain no longer calls `_sync_runtime_wall_collision_with_visible_walls()`/`_rebuild_horizontal_wall_overlays()` once per eviction-frame when evictions occur faster than `streaming_visual_rebuild_interval_sec`. `R0-02` -- the new NavigationSystem section passes. `R0-03` -- the new protected-anchor section passes. `R0-04` -- the new foliage-metadata section passes. `R0-05` -- the new before/after residency-count section passes. All previously-passing assertions in both smokes remain green; S1 quick remains `determinism_ok=true` at fingerprint `1773840677`.
- Validation: Run `procgen_distant_chunk_unload` first (now extended). Then the full regression list from the parent packet's own Validation field (`procgen_chunk_payload_cache`, `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, `procgen_dressing_clusters`, `navigation_elevation_smoke.gd`, `procgen_authored_scene_authority_smoke.gd`), S1 quick, packet/review-pairing/docs/manifest checks, and `git diff --check`.
- Task overrides: `none`
- Deferred: None -- all five cited findings are addressed in this correction.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`
- What worked: `<fill at closeout>`
