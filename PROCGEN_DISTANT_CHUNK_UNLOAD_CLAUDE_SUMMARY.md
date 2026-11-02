# Procgen Distant Chunk Unload (M6) — Closing Summary

Landed main SHA: `9fe8cd4d6` (`procgen distant chunk unload, M6 ProcGenChunkResidencyPolicy authority`).

M4 gave chunk presentation a real `DORMANT`/`UNLOADED` lifecycle and M5 gave
reveal a derived payload cache, but production distant-chunk unload stayed
disabled: the old `_unload_chunk()` erased a chunk's painted Floor/Walls,
destroyed its foliage, and tore down its runtime wall collision in one
unbounded sweep, while `_sync_runtime_wall_collision_with_visible_walls()`
and `NavigationSystem` both derived authority from *painted* tiles rather
than canonical semantics. Enabling that path unchanged would have let
presentation residency silently own collision and navigation. This task's
job was to make distant-chunk unload production-safe, bounded, and
reviewable, then turn it on by default.

## What landed

`ProcGenChunkResidencyPolicy`
(`custodian/game/world/procgen/streaming/procgen_chunk_residency_policy.gd`)
is a new plain `RefCounted` that owns only an eviction-candidate coordinate
queue and telemetry counters:

- `refresh_candidates(center_chunk, dormant_chunks, protected_chunks, unload_distance)`
  -- replaces the queue with the current deterministic eligible set: DORMANT
  only (caller-filtered), Chebyshev distance strictly greater than
  `unload_distance`, excluding protected chunks, ordered farthest-first then
  coordinate-stable for ties. A previously-queued chunk that drops out of
  the new eligible set is counted cancelled.
- `take_candidates(max_count)` -- pops up to `max_count` candidates for the
  caller to revalidate and act on.
- `note_evicted()` / `note_cancelled()` -- caller-reported outcome counters.
- `get_snapshot()` -- pending/refresh/selected/evicted/cancelled/
  protected-rejected counts.

It never touches TileMap/Node/collision/foliage state and never calls into
M4's lifecycle or M5's cache directly.

### `ProcGenTilemap` wiring

- `_update_streaming_chunks()` keeps active-radius reveal + `sync_active_window()`
  first, then refreshes the residency-policy queue from the DORMANT subset
  of `_chunk_lifecycle.get_resident_chunks()` instead of unloading directly.
- A new `_drain_residency_eviction()`, called from `_process()` right after
  reveal draining (gated on `streaming_unload_distant_chunks`), takes up to
  `streaming_unload_chunks_per_frame` (new export, default `1`) candidates
  per frame and revalidates each one's live state/distance/protection
  (`_is_chunk_eviction_valid()`) immediately before calling `_unload_chunk()`
  -- the queue can go stale between refresh and drain (player returned,
  chunk left DORMANT, or it became protected), and this is the gate that
  catches it.
- `_protected_streaming_chunks()` excludes the player spawn chunk, every
  valid portal-teleporter endpoint chunk, every current compound-ingress
  chunk, and any chunk intersecting the current world-ingress
  dressing-clearance rects from eviction, so asynchronous reveal budgeting
  can never produce a blank landing. Debug/test force-unload bypasses it.
- `_effective_unload_distance()` is `max(streaming_unload_chunk_distance, streaming_active_chunk_radius + 1)`,
  so eviction can never reach into the active reveal window regardless of
  configuration.
- `_unload_chunk()` is now a pure presentation/cache residency adapter, not
  a semantic destroyer: it erases painted Floor/Walls cells, streaming-hides
  (never destroys) existing foliage, removes deterministic road/path decal
  nodes, evicts the M5 cached payload for the chunk, forces lifecycle
  `UNLOADED`, and refreshes macro visibility. It no longer calls
  `_remove_runtime_wall_body()`.

### Collision stays canonical, not painted

`_sync_runtime_wall_collision_with_visible_walls()`'s cleanup pass now
removes a wall shape only when canonical `_generated_wall_cells` no longer
contains that tile -- never merely because the wall is unpainted. Collision
for a once-revealed, now-unloaded wall survives; genuine semantic wall
destruction (which already erases the tile from `_generated_wall_cells`)
still removes it correctly, in `damage_wall_tile()`,
`_clear_procgen_wall_authority_at()`, and the hoisted-out-of-the-visibility-
guard collision removal in `_set_floor_tile_and_generated_state()`.

### Navigation stays canonical, not painted

New `ProcGenChunkLifecycle.get_unloaded_chunks()` plus two new
`ProcGenTilemap` provider methods:

- `get_runtime_navigation_floor_cells()` -- the union of currently painted
  floor cells and canonical generated-floor cells belonging to
  lifecycle-`UNLOADED` chunks (never `UNSEEN` ones).
- `is_runtime_navigation_walkable(tile)` -- delegates to the existing
  `is_runtime_walkable_after_props()` semantic/blocker authority, never
  painted visibility.

`NavigationSystem._build_navigation_graph()` and `_is_walkable()` use these
through `runtime_blocker_provider` when available and fall back to the
original TileMap-used-cells logic otherwise, so a chunk that was revealed at
least once keeps contributing navigation nodes/edges after it unloads.

### Foliage is hidden by identity, never destroyed/rerolled

Two tiny new `ProcGenTilemap` helpers, `_hide_foliage_for_unload()` and
`_show_foliage_if_hidden()`, set an existing `_foliage_nodes` entry's
`visible` flag instead of calling `_remove_foliage()`. `_unload_chunk()`
uses the hide path exclusively; `_commit_tile_reveal_record()`'s floor
branch checks `_show_foliage_if_hidden()` first and skips new
random/authored placement when it re-shows an existing node. Deterministic
kind/cluster metadata, trunk collision, and runtime-blocker registration are
untouched by hide/show. Genuine semantic invalidation (the tile stops being
floor) still calls the real `_remove_foliage()`.

### Streaming-paint guard on the M5-inventoried mutation setters

`_is_tile_currently_visible()` -- the pre-existing M5-era helper that
already returns `true` unconditionally during initial generation
(`enable_streaming_reveal == false`) and otherwise checks live paint state
-- turned out to already be the exact guard M6 needed. It (or the
equivalent canonical-authority check) is now threaded through
`damage_wall_tile()` (recognizes canonical wall authority even when
unpainted, instead of requiring the tile to be painted),
`_set_destroyed_wall_floor_tile()`, `_refresh_wall_neighbors()` (refreshes
every canonical neighbor's record, paints only the resident ones),
`_force_authored_scene_floor_authority()`, `_clear_procgen_wall_authority_at()`,
`_set_terrain_floor_visual()`/`_set_terrain_wall_visual()`,
`_set_ascent_field_floor_authority()`/`_set_ascent_field_wall_authority()`,
and `_preserve_reserved_pre_terrain_floor_authority()`. Semantic writes
(the generated-floor/wall dictionaries, wall health, region data) always
happen; only the TileMap visual paint is deferred to reload COMMIT for a
lifecycle-`UNLOADED` tile. `_set_floor_tile_and_generated_state()` already
had this guard; its collision-removal call was hoisted out from under it
since collision removal is a semantic effect, not a presentation one.
`_apply_floor_value_clusters()`'s write path was already unload-safe by
design (explicit comment, paints only already-visible cells).

### M5 cache eviction closes MR5 `R0-01`

`ProcGenChunkPayloadCache.evict_chunk(chunk_pos)` drops a chunk's cached
membership and internally stored tile records via a new per-chunk reverse
index (`_chunk_tile_record_keys`), without bumping that chunk's revision or
the cache generation -- eviction is a pure memory-shape reduction, not a
semantic event. New `eviction_count`/`evicted_tile_record_count` telemetry.
`invalidate_chunk()` now also eagerly drops the same internal records (while
still bumping revision) so stale externally-held records remain detectable
exactly as before.

### Production default

`streaming_unload_distant_chunks` now defaults `true`. Active radius `2`
and unload distance `4` are unchanged; the runtime effective distance is
clamped to at least `active radius + 1`.

## Validation

New `custodian/tools/validation/procgen_distant_chunk_unload_smoke.gd`
(registered in `validation_manifest.json`) proves:

- the pure policy's eligibility/distance/protection/ordering/cancellation
  contract against a standalone `ProcGenChunkResidencyPolicy`;
- a live `ProcGenTilemap` round trip: stale-candidate cancellation when the
  player returns before draining; a single drain never exceeds the
  per-frame budget; the protected spawn chunk is rejected and never
  unloaded even when DORMANT and far; M5 cache eviction is recorded; wall
  collision survives visual unload; navigation floor-cell/walkability
  authority survives unload and correctly excludes `UNSEEN` chunks; a
  foliage node's identity and visibility are preserved across hide/show;
  road decals disappear/reappear in step with unload/reload; wall
  destruction and an authored-scene claim applied while `UNLOADED` mutate
  canonical truth without a premature repaint and materialize correctly on
  reload; and the new `get_runtime_health_snapshot()` telemetry fields are
  present with the correct effective unload distance.

`procgen_chunk_payload_cache_smoke.gd`'s subtest 4 was updated: unloading a
chunk now intentionally evicts (not reuses) its cached payload, so the
debug unload/re-reveal round trip now asserts an eviction + a subsequent
cache miss, not a hit, with no spurious invalidation.

Full regression, run with the new `streaming_unload_distant_chunks = true`
default live (none of these tests override the flag): `procgen_chunk_payload_cache`,
`procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`,
`procgen_walkable_boundary`, `runtime_wall_collision_compaction`,
`procgen_candidate_promotion_smoke` (`procgen_candidate_materializer_parity`),
`procgen_macro_presentation_smoke`, `procgen_road_semantics_v2_smoke`,
`procgen_dressing_clusters_smoke`, `navigation_elevation_smoke`, and
`procgen_authored_scene_authority_smoke` all PASS. S1 quick
(`procgen_performance_baseline_bench.gd`) reports `determinism_ok=true` at
fingerprint `1773840677`, unchanged from M1-M5.

## Docs touched

`design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`,
`custodian/docs/ai_context/FILE_INDEX.md`,
`design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`, and
`design/00_meta/MASTER_ROADMAP.md`.

## Next

Paired `review-procgen-distant-chunk-unload` (MR6) is ready/eligible against
this landed commit. D1-D3 remain gated on a clean/non-blocking-only MR6
pass, not merely on M6 code landing.
