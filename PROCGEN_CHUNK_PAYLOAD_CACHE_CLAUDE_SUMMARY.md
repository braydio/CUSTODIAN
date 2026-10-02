# Procgen Chunk Payload Cache (M5) — Closing Summary

M4 replaced truthless chunk bookkeeping with a real lifecycle state machine,
but `ProcGenTilemap._get_chunk_tiles()` still rescanned a chunk's full
`streaming_chunk_size_tiles` square against `_generated_floor_cells`/
`_generated_wall_cells` on every request/re-request, and
`_build_tile_reveal_prepare_record()` re-read floor/wall source/atlas data
fresh on every PREPARE/direct reveal. This task's job was to add one
derived, invalidatable cache behind those two seams -- without moving
semantic ownership out of `ProcGenTilemap`, without touching M3's queue or
M4's lifecycle, and without enabling any M6 eviction policy.

## What landed

`ProcGenChunkPayloadCache`
(`custodian/game/world/procgen/streaming/procgen_chunk_payload_cache.gd`) is
a plain `RefCounted`, keyed by chunk coordinate, carrying its own
`generation_id` plus a per-chunk `revision` counter:

- `get_chunk_tiles(chunk_pos, builder)` -- lazy, hit/miss-counted chunk tile
  membership, always returning a duplicate so a caller's own
  `sort_custom()` can never corrupt the cached canonical copy.
- `get_tile_record(tile, chunk_pos, builder)` -- lazy, hit/miss-counted
  per-tile PREPARE record, stamped with the `generation_id`/`revision` it
  was built under.
- `invalidate_chunk(chunk_pos)` -- bumps that chunk's revision and drops its
  cached membership; the precise seam every post-cache semantic mutation
  calls.
- `reset()` -- the true generation/streaming-reset boundary: bumps
  `generation_id`, clears everything.
- `invalidate_all()` -- a full clear without a generation bump, kept as an
  explicit bulk-reset primitive but, after the fix described below, no
  longer called from the generation path.
- `is_record_stale()` / `revalidate_record_before_commit()` -- the stale-
  PREPARE-record defense: a record whose stamped generation/revision no
  longer matches current cache identity is rebuilt from canonical state
  before COMMIT applies it.
- `get_telemetry_snapshot()` -- cached chunk/record counts, hit/miss/
  invalidation/stale-refresh counts, reset count, generation id.

It owns no Node/TileMapLayer/CanvasItem/Texture/Resource/collision-body/
foliage-node/road-decal-node/gameplay Callable state, and it never becomes
semantic, queue, or lifecycle authority.

`ProcGenTilemap` only constructs it (`_ready()`), resets it at
`_prepare_streaming_reveal()`, and delegates through three narrow seams:

- `_cached_chunk_tiles(chunk_pos)` -- used by both `_queue_chunk_for_reveal()`
  and `_reveal_chunk_immediately()` in place of calling `_get_chunk_tiles()`
  directly. `_get_chunk_tiles()` itself is untouched and remains the cache's
  sole canonical membership builder; queued reveal still sorts the (possibly
  reused) membership with the live, uncached `_streaming_reveal_priority()`,
  and immediate reveal preserves `_get_chunk_tiles()`'s exact iteration order
  (no sort).
- `_build_tile_reveal_prepare_record(tile)` -- now a cache-backed wrapper;
  `_build_tile_reveal_record_raw(tile)` is the new pure, uncached builder
  (identical logic to the old `_build_tile_reveal_prepare_record` body) that
  the cache calls on a miss or a stale refresh.
- `_commit_tile_reveal_record(record)` -- revalidates `record` against
  current cache identity immediately before mutation via
  `revalidate_record_before_commit()`, covering all three paths that reach
  it: direct `_reveal_tile()` (always fresh, cheap no-op check), M3's
  prepared-queue drain (the actual stale-defense case), and M3's direct
  build+commit fallback (always fresh).

## The invalidation inventory

Every live write/erase of `_generated_floor_cells`/`_generated_wall_cells`
was grepped and traced to its owning function -- 26 call sites across the
file, all funnelling through one of a small number of shared low-level
setters. Each setter now calls `_chunk_payload_cache.invalidate_chunk()` for
its own tile unconditionally (a harmless no-op during early generation,
before the cache has anything cached yet):

- `damage_wall_tile()` and `_refresh_wall_neighbors()` (only neighbors whose
  wall record actually changed) -- runtime wall destruction.
- `_force_authored_scene_floor_authority()` and
  `_clear_procgen_wall_authority_at()` -- authored-scene/world-overlook
  claims (`claim_procgen_floor_rect_for_authored_scene_tiles` and its
  wrappers), reachable at runtime.
- `_claim_isolated_world_overlook_pocket()`'s moat-cell erase loop.
- `_set_floor_tile_and_generated_state()`, `_set_terrain_floor_visual()`,
  `_set_terrain_wall_visual()`, `_set_ascent_field_floor_authority()`,
  `_set_ascent_field_wall_authority()`, `_preserve_reserved_pre_terrain_floor_authority()`,
  and `_apply_floor_value_clusters()`'s inline write -- the generation-time
  (and, for the first three, also late-finalization-time) floor/wall
  authority setters.

`_capture_generated_tile_state()`'s full-map bulk sync loop was deliberately
left uninstrumented: every one of its three call sites runs strictly before
`_prepare_streaming_reveal()` ever resets/populates the cache, so it is
always a no-op there and adding per-tile invalidation calls to an
`O(map_size)` loop would be pure overhead.

## A design correction mid-task

My first pass paired the precise per-site `invalidate_chunk()` calls above
with an *additional* blanket `_chunk_payload_cache.invalidate_all()` call
placed right after `generate()`'s two late-generation-finalization passes
(`_enforce_route_playability_walkability`, `_apply_sundered_keep_frontage_floor_visuals`),
reasoning this was the "simpler, behavior-preserving" full-reset option the
packet explicitly allows at a bulk finalization boundary. In practice this
wiped every chunk-membership/tile-record entry the same generation's own
streaming-priming pass (`_prepare_streaming_reveal()`) had just built,
moments earlier in the same `generate()` call -- so the new smoke's
"already-primed chunk access is a hit" and "debug unload/re-reveal round
trip is a hit" assertions failed, not because invalidation was incorrect,
but because nothing useful was left cached to reuse by the time anything
observed it.

The fix: remove the blanket `invalidate_all()` call entirely and instead add
one precise `invalidate_chunk()` call to each of the remaining shared
low-level setters those two finalization passes already route through
(`_set_floor_tile_and_generated_state`, `_set_terrain_floor_visual`,
`_set_terrain_wall_visual`, plus the ascent-field/pre-terrain/floor-value-
cluster setters for completeness). This covers the same 26-site inventory
precisely regardless of *when* in generation a given setter runs, so a
chunk that late finalization never touches keeps its primed cache entries,
while a chunk it does touch is invalidated exactly as before.
`ProcGenChunkPayloadCache.invalidate_all()` itself is kept in the class as
an explicit, tested bulk-reset primitive for any future need, just no
longer wired into the generation path.

## Validation

All run from `custodian/` after a headless `--import` pass against this
fresh ephemeral worktree (Godot 4.7.2.stable.arch_linux, headless):

- `procgen_chunk_payload_cache_smoke.gd` (new, manifest id
  `procgen_chunk_payload_cache`) -- PASS. Proves: zero cache entries before
  any generation/access; miss->hit reuse for chunk membership and for
  per-tile PREPARE records with exact counter deltas; live
  `_streaming_reveal_priority()` producing a different sort order for a
  different `center_tile` over identical reused cached membership; a debug
  unload/re-reveal round trip producing pure hits with zero rebuilds when
  nothing semantic changed; `damage_wall_tile()` invalidating the cache, and
  the destroyed floor surviving a subsequent unload/re-reveal without the
  wall resurrecting; an authored-scene floor claim invalidating the cache
  and its new region truth surviving unload/re-reveal; a PREPARE record
  captured for a wall tile *before* that wall was destroyed (simulating a
  Dictionary still sitting in M3's `_prepared` queue across a resume frame)
  being detected as stale and rebuilt immediately before COMMIT -- the
  destroyed wall is never resurrected, its floor is correctly painted, and
  exactly one `stale_refresh_count` increment is recorded; presentation/
  telemetry-only reads never bumping `invalidation_count`; and a regenerate
  bumping `generation_id`/`reset_count` by exactly one.
- `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`,
  `procgen_runtime_health`, `procgen_walkable_boundary`,
  `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`,
  `procgen_macro_presentation`, `procgen_road_semantics_v2`, and
  `procgen_dressing_clusters` -- all PASS via `run_validation.py --test <id> --json`.
- `procgen_authored_scene_authority_smoke.gd` -- PASS via direct
  `godot --headless --script` invocation (still unregistered in the
  manifest; a pre-existing gap this packet did not touch).
- S1 quick (`procgen_performance_baseline_quick`) -- `determinism_ok=true`,
  48x48 seed-420777 fingerprint `1773840677`, identical to M1-M4. No
  deterministic-output regression.
- `run_validation.py --changed --json` -- 25 tests selected by file
  ownership, all 25 pass.
- `git diff --check` -- clean.

MR4's corrected `UNLOADED`-reload prose in `STREAMING_PROCGEN_REVEAL.md` was
only appended to (a new M5 paragraph), never altered. `procgen_walkable_boundary_smoke.gd`
and `runtime_wall_collision_compaction_smoke.gd` remain registered in
`validation_manifest.json`; only one new entry (`procgen_chunk_payload_cache`)
was inserted, via a targeted text edit rather than a full JSON
re-serialization, to avoid reformatting unrelated entries.

Moment Forge was not run: this is a non-visual derived-cache/telemetry slice
with no new or altered animation/VFX/camera/audio timing, and the smoke
suite above (including live `ProcGenTilemap` integration with real
commit/paint/collision checks) already exercises the correctness-sensitive
paths.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: see "A design correction mid-task" above -- an initial
  blanket post-finalization `invalidate_all()` call defeated the cache's own
  reuse for the common case, caught by the new smoke's own assertions before
  any reviewer needed to find it.
- Root cause / contributing factors: conflated "a full reset is an allowed
  simplification at a bulk finalization boundary" with "a full reset is the
  best choice here," without first checking whether the same small number of
  shared low-level setters those finalization passes already call could each
  carry one precise per-tile invalidation call instead -- they could.
- Prevention / pipeline improvement: fixed in scope, described above.
- Tooling / docs drift discovered: none beyond what MR4 already recorded.
- Follow-up: none.
- What worked: writing the cache smoke's hit/miss assertions against the
  actual post-generation state (rather than assuming priming-time caching
  survives untouched to test time) surfaced the invalidate-everything design
  flaw immediately and concretely. Editing `validation_manifest.json` with a
  targeted text insertion instead of `json.dump`-based re-serialization kept
  the diff to exactly the new entry instead of reformatting ~200 unrelated
  test records.
