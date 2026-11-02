# Review: Procgen Chunk Payload Cache (MR5) — Closing Summary

Workstream: `review-procgen-chunk-payload-cache`
Reviewed implementation: `custodian/docs/ai_context/task_packets/archived/PROCGEN_CHUNK_PAYLOAD_CACHE.md` (M5)
Reviewed on main: `e1050a54c`

## Verdict

Passed, non-blocking-only. 0 blocking defects, 0 material evidence gaps, 0
non-blocking issues, 1 optional-improvement finding (`R0-01`, routed to
deferred). No correction packet scaffolded. Full receipt is the
`## Independent Review` section appended to the archived M5 packet.

## Verification performed (not just re-reading prior claims)

- **Live-reference audit of the invalidation inventory**: independently
  grepped every `_generated_floor_cells[...]=`/`.erase()` and
  `_generated_wall_cells[...]=`/`.erase()` site in `proc_gen_tilemap.gd`
  (24 distinct statements) and traced each to its owning function, rather
  than trusting the closing summary's 26-site list. Confirmed every one of
  `_apply_floor_value_clusters`'s inline write, `_claim_isolated_world_overlook_pocket`'s
  moat-cell erase, `_force_authored_scene_floor_authority`,
  `_clear_procgen_wall_authority_at`, `_preserve_reserved_pre_terrain_floor_authority`,
  `_set_ascent_field_floor_authority`, `_set_ascent_field_wall_authority`,
  `damage_wall_tile` (covering its own call plus `_set_destroyed_wall_floor_tile`),
  `_refresh_wall_neighbors` (invalidating only neighbors whose wall record
  actually changed), `_set_terrain_floor_visual`, `_set_terrain_wall_visual`,
  and `_set_floor_tile_and_generated_state` calls
  `_chunk_payload_cache.invalidate_chunk(_tile_to_chunk(...))`
  unconditionally, immediately after the dictionary mutation.
- **Late-generation-finalization ordering**: confirmed `_enforce_route_playability_walkability()`
  and `_apply_sundered_keep_frontage_floor_visuals()` both run at
  `proc_gen_tilemap.gd:1473`/`1479`, strictly *after* `_prepare_streaming_reveal()`
  (line 1446, which `reset()`s the cache and then primes it), and that both
  route every mutation through the instrumented setters above (via
  `_set_floor_tile_and_generated_state()`/`_apply_terrain_tile_visual()`).
  Read the rest of `generate()` after line 1446 to the end of the function
  and found no other write/erase to the two generated dictionaries.
- **Early-generation bulk mutators are structurally harmless**: confirmed
  `_apply_ascent_field_authority()`'s `.clear()` pair (only call site:
  `_fill_ascent_field_substrate`, called once at line 1289) and
  `_capture_generated_tile_state()`'s full-map sync loop (three call sites,
  lines 1318/1351/1400, and zero external callers anywhere in the `.gd`
  tree) always run strictly before `_prepare_streaming_reveal()`'s `reset()`
  in the same `generate()` call, so their lack of per-site invalidation is a
  genuine no-op, not a gap.
- **Reveal-order and COMMIT-time guarantees**: read `_queue_chunk_for_reveal()`,
  `_reveal_chunk_immediately()`, `_streaming_reveal_priority()`,
  `_get_chunk_tiles()`, `_cached_chunk_tiles()`,
  `_build_tile_reveal_prepare_record()`/`_build_tile_reveal_record_raw()`,
  and `_commit_tile_reveal_record()` directly. Confirmed queued reveal
  always re-sorts the (possibly cache-reused) membership against the live
  `_streaming_reveal_priority(tile, center_tile)` at request time; immediate
  reveal never re-sorts (preserving `_get_chunk_tiles()`'s own order);
  `_commit_tile_reveal_record()` calls `revalidate_record_before_commit()`
  immediately before applying `floor_data`/`wall_data`, covering all three
  paths that reach it (direct `_reveal_tile()`, M3's prepared-queue FIFO
  drain in `ProcGenPauseAwareStreaming.drain_commit()`, and M3's direct
  build+commit fallback). Confirmed `_is_tile_currently_visible()` and
  `get_runtime_health_snapshot()` never call `invalidate_chunk`/`invalidate_all`/`reset`.
- **Architecture**: read `procgen_chunk_payload_cache.gd` in full (189
  lines); confirmed it is a plain `RefCounted` with no
  Node/TileMapLayer/CanvasItem/Texture/Resource/collision-body/foliage-node/
  road-decal-node/gameplay-Callable field, never mutates M3's queue or M4's
  lifecycle state, and that `ProcGenPauseAwareStreaming.configure()` is
  wired with the cache-backed `_build_tile_reveal_prepare_record`/
  `_commit_tile_reveal_record` as its `build_record`/`commit_record`
  Callables (`proc_gen_tilemap.gd:838`). Confirmed `streaming_unload_distant_chunks`
  still defaults `false` and `invalidate_all()` is retained but not called
  from any generation/runtime path -- no M6 eviction/hysteresis/LRU policy
  exists anywhere under `custodian/game/world/procgen/`.
- **Fresh runtime re-execution** (Godot 4.7.2.stable.arch_linux, headless;
  `godot --headless --import --quit` run first; not reused from the
  implementation's own prior claims): the implementation-created
  `procgen_chunk_payload_cache_smoke.gd` (manifest id
  `procgen_chunk_payload_cache`) PASS; manifest-backed
  `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`,
  `procgen_runtime_health`, `procgen_walkable_boundary`,
  `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`,
  `procgen_macro_presentation`, and `procgen_road_semantics_v2` all PASS via
  `run_validation.py --test <id> --json`; `procgen_authored_scene_authority_smoke.gd`
  PASS via direct `godot --headless --path . --script` invocation (still
  unregistered in `validation_manifest.json`, a pre-existing gap this review
  did not introduce or touch). `procgen_performance_baseline_bench.gd` (S1
  quick) re-run fresh: `determinism_ok=true`, 48x48 seed-420777 fingerprint
  `1773840677`, identical to the M1-M5 documented baseline, confirming no
  deterministic-output regression. `git diff --check` clean. No environment
  gap: Godot was available and every named focused-validation target
  actually executed, not merely re-read from prior evidence.

All 14 M5 acceptance items were independently reconfirmed true by the above
code trace and fresh runtime evidence. MR4's `R0-01` corrected `UNLOADED`-
reload prose in `STREAMING_PROCGEN_REVEAL.md` remains intact (only appended
to), and `procgen_walkable_boundary_smoke.gd`/`runtime_wall_collision_compaction_smoke.gd`
remain manifest-selectable.

## Finding

One optional-improvement finding, `R0-01` (see the archived M5 packet's
`## Independent Review` receipt for the full record):
`ProcGenChunkPayloadCache._tile_records` is keyed only by `tile`, not by
`(tile, chunk_pos)`, and `invalidate_chunk()` does not proactively sweep a
chunk's own stale tile-record entries out of that dictionary -- they are
only ever overwritten lazily on next access. Correctness is unaffected
(`get_tile_record()`/`is_record_stale()` both re-check stamped
`generation_id`/chunk `revision` before ever returning a cached record as a
hit, confirmed by direct code reading and by the smoke's own stale-record
assertions), and growth is bounded by total distinct generated tile count,
not unbounded over time. Disposition: `deferred` -- a correctness-neutral
memory-shape optimization, not required for this packet's acceptance.

No other findings. All 14 M5 acceptance items hold.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: Nothing blocking the review itself. Running
  `python3 custodian/tools/agent/validate_review_pairing.py` on unmodified
  `origin/main` (before this workstream's own edits) reports `FAIL` for
  several unrelated already-landed packets (`contract-world-*-placement-extraction`,
  `operator-art-registration-profile`, `procgen-render-attribution-v1`) whose
  declared validation script paths are missing the `custodian/` prefix the
  checker now expects. Separately, `python3 custodian/tools/agent/task_packet_index.py`
  fails because `docs/ai_context/task_packets/README.md` has never been
  initialized with the `<!-- task_packet_index:managed:start/end -->` marker
  block that tool expects. Neither failure names
  `procgen-chunk-payload-cache` or `review-procgen-chunk-payload-cache`.
- Root cause / contributing factors: the `review_pairing_contract`
  path-prefix drift is pre-existing and was already independently discovered
  and documented as a follow-up in M5's own Execution Feedback (confirmed
  here by reproducing the identical failure set on unmodified main). The
  `task_packet_index.py` managed-marker gap appears to predate this tool's
  current expectations and was not previously flagged in this series.
- Prevention / pipeline improvement: no fix attempted here -- this review's
  bounded task override does not authorize editing unrelated packets or
  running `task_packet_index.py --write` against `README.md` outside this
  workstream's own two index-bullet edits.
- Tooling / docs drift discovered: see above; both are pipeline/tooling
  drift, not M5 implementation findings.
- Follow-up: `manual-follow-up` on both the pre-existing `review_pairing_contract`
  path-prefix drift (already named in M5's own packet) and the
  never-initialized `task_packet_index.py` managed-marker block (newly
  noted here).
- What worked: Re-deriving the full `_generated_floor_cells`/`_generated_wall_cells`
  write-site inventory directly from `grep`/function tracing (rather than
  trusting the implementation's prose list) is what let this review confirm
  the late-generation-finalization invalidation claim precisely, including
  the exact line numbers where `_prepare_streaming_reveal()`'s cache
  `reset()` sits relative to the two finalization passes that run after it.
