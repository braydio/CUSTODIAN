extends SceneTree

## Covers PROCGEN_CHUNK_PAYLOAD_CACHE.md (M5) acceptance: lazy chunk-payload
## population, miss->hit reuse for both chunk tile membership and per-tile
## PREPARE records, live (uncached) reveal-priority ordering over reused
## membership, a debug unload/re-reveal round trip serving a cache hit,
## precise wall-destruction and authored-scene-claim invalidation, stale
## PREPARE-record detection/refresh immediately before COMMIT, and
## generation-scoped reset separating cache state across regenerations.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CHUNK_LIFECYCLE_SCRIPT := preload("res://game/world/procgen/streaming/procgen_chunk_lifecycle.gd")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_cache_behavior()
	if _errors.is_empty():
		print("[ProcgenChunkPayloadCacheSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenChunkPayloadCacheSmoke] %s" % error)
	quit(1)


func _test_cache_behavior() -> void:
	var runtime_container := Node2D.new()
	runtime_container.name = "ProcGenRuntime"
	root.add_child(runtime_container)
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	runtime_container.add_child(map)
	await process_frame
	var legacy := map.get_node_or_null("ProcGen")
	if legacy != null:
		legacy.queue_free()
		await process_frame
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	procgen.generate_seed = false
	procgen.seed = 20261002
	procgen.map_size = Vector2i(24, 24)
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = true
	map.streaming_chunk_size_tiles = 6
	map.streaming_immediate_chunk_radius = 1
	map.streaming_active_chunk_radius = 2
	map.streaming_reveal_tiles_per_frame = 4
	map.build_runtime_wall_collision = true

	var state := CHUNK_LIFECYCLE_SCRIPT.State

	# Lazy population: nothing is cached before a single chunk is ever
	# touched.
	var pre_gen_snapshot := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(pre_gen_snapshot.get("cached_chunk_count", -1)) == 0, "cache has entries before any generation/access")

	map.generate()

	var spawn_tile := map.get_player_spawn()
	var spawn_chunk := map.call("_tile_to_chunk", spawn_tile) as Vector2i

	var snapshot_after_gen := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(snapshot_after_gen.get("miss_count", 0)) > 0, "generation priming never built any cache entries")
	_check(int(snapshot_after_gen.get("generation_id", 0)) > 0, "cache generation id was not advanced by streaming priming")
	_check(int(snapshot_after_gen.get("reset_count", 0)) == 1, "generation did not record exactly one cache reset")

	# Find an outer (queued, not-yet-drained) chunk -- its membership was
	# already primed into the cache, but no frame has committed/prepared its
	# tiles yet.
	var queued_chunk := Vector2i(999999, 999999)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var candidate := spawn_chunk + Vector2i(dx, dy)
			if int(map.debug_get_chunk_lifecycle_state(candidate)) == state.QUEUED:
				queued_chunk = candidate
				break
		if queued_chunk != Vector2i(999999, 999999):
			break
	_check(queued_chunk != Vector2i(999999, 999999), "no outer chunk was left QUEUED immediately after generation")

	# --- (1) Lazy population + miss->hit reuse: chunk tile membership ---
	var untouched_chunk := Vector2i(500000, 500000)
	var counts0 := map.debug_get_chunk_payload_cache_snapshot()
	map.call("_cached_chunk_tiles", untouched_chunk)
	var counts1 := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(counts1.get("miss_count", 0)) == int(counts0.get("miss_count", 0)) + 1, "first access to an untouched chunk was not a miss")
	_check(int(counts1.get("hit_count", 0)) == int(counts0.get("hit_count", 0)), "first access to an untouched chunk was incorrectly a hit")
	_check(int(counts1.get("cached_chunk_count", 0)) == int(counts0.get("cached_chunk_count", 0)) + 1, "first access did not populate exactly one cache entry")
	map.call("_cached_chunk_tiles", untouched_chunk)
	var counts2 := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(counts2.get("hit_count", 0)) == int(counts1.get("hit_count", 0)) + 1, "repeated access to the same chunk did not hit the cache")
	_check(int(counts2.get("miss_count", 0)) == int(counts1.get("miss_count", 0)), "repeated access to the same chunk rebuilt instead of reusing")
	_check(int(counts2.get("cached_chunk_count", 0)) == int(counts1.get("cached_chunk_count", 0)), "repeated access changed the cached chunk count")

	# A queued (outer) chunk's membership may or may not already be cached
	# from priming -- later generation-time finalization (route-playability
	# repair, Sundered Keep frontage visuals) can legitimately touch any
	# chunk's tiles and precisely invalidate it before this test ever runs.
	# What must always hold regardless of that history is: once accessed
	# once here, a second identical access is a pure hit.
	var queued_tiles: Array[Vector2i] = map.call("_cached_chunk_tiles", queued_chunk)
	_check(not queued_tiles.is_empty(), "the chosen queued chunk has no generated tiles")
	var mid_q := map.debug_get_chunk_payload_cache_snapshot()
	var queued_tiles_again: Array[Vector2i] = map.call("_cached_chunk_tiles", queued_chunk)
	var after_q := map.debug_get_chunk_payload_cache_snapshot()
	_check(queued_tiles == queued_tiles_again, "repeated membership access for the same chunk returned a different tile set")
	_check(int(after_q.get("hit_count", 0)) == int(mid_q.get("hit_count", 0)) + 1, "a second identical chunk membership access did not hit the cache")
	_check(int(after_q.get("miss_count", 0)) == int(mid_q.get("miss_count", 0)), "a second identical chunk membership access rebuilt instead of reusing")

	# --- (2) Miss->hit reuse: per-tile PREPARE records ---
	var probe_tile: Vector2i = queued_tiles[0]
	var rec_counts0 := map.debug_get_chunk_payload_cache_snapshot()
	map.call("_build_tile_reveal_prepare_record", probe_tile)
	var rec_counts1 := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(rec_counts1.get("miss_count", 0)) == int(rec_counts0.get("miss_count", 0)) + 1, "first PREPARE-record build for an unvisited tile was not a miss")
	_check(int(rec_counts1.get("cached_tile_record_count", 0)) == int(rec_counts0.get("cached_tile_record_count", 0)) + 1, "first PREPARE-record build did not populate one record")
	map.call("_build_tile_reveal_prepare_record", probe_tile)
	var rec_counts2 := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(rec_counts2.get("hit_count", 0)) == int(rec_counts1.get("hit_count", 0)) + 1, "repeated PREPARE-record build for an unchanged tile did not hit the cache")
	_check(int(rec_counts2.get("cached_tile_record_count", 0)) == int(rec_counts1.get("cached_tile_record_count", 0)), "repeated PREPARE-record build changed the cached record count")

	# --- (3) Dynamic reveal order is never frozen into the cache ---
	var near_order: Array[Vector2i] = queued_tiles.duplicate()
	near_order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return float(map.call("_streaming_reveal_priority", a, spawn_tile)) < float(map.call("_streaming_reveal_priority", b, spawn_tile))
	)
	var far_center := spawn_tile + Vector2i(5000, 5000)
	var far_order: Array[Vector2i] = queued_tiles.duplicate()
	far_order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return float(map.call("_streaming_reveal_priority", a, far_center)) < float(map.call("_streaming_reveal_priority", b, far_center))
	)
	_check(near_order != far_order, "reveal order did not change for a different live center_tile despite reused cached membership")

	# --- (4) Debug unload / re-reveal round trip serves a cache hit ---
	# Warm the cache for spawn_chunk deliberately first so this round trip's
	# hit/miss delta is unambiguous regardless of what generation-time
	# finalization may or may not have already touched in this chunk.
	var warm_tiles: Array[Vector2i] = map.call("_cached_chunk_tiles", spawn_chunk)
	for warm_tile in warm_tiles:
		map.call("_build_tile_reveal_prepare_record", warm_tile)

	var before_reload := map.debug_get_chunk_payload_cache_snapshot()
	map.debug_force_unload_chunk(spawn_chunk)
	map.call("_reveal_chunk_immediately", spawn_chunk)
	var after_reload := map.debug_get_chunk_payload_cache_snapshot()
	_check(
		int(after_reload.get("miss_count", 0)) == int(before_reload.get("miss_count", 0)),
		"unload/re-reveal with no semantic mutation rebuilt cache entries instead of reusing them"
	)
	_check(
		int(after_reload.get("hit_count", 0)) > int(before_reload.get("hit_count", 0)),
		"unload/re-reveal with no semantic mutation produced no cache hits"
	)

	# --- (5) Wall-destruction invalidation ---
	# Search every currently-committed (visible) wall tile anywhere in the
	# primed active window, not just the spawn chunk itself -- the exact
	# spawn tile's own chunk is frequently a deliberately wall-free clearing.
	var wall_cells: Dictionary = map.debug_get_generated_wall_cells()
	var destroy_tile := Vector2i(999999, 999999)
	var stale_wall_tile := Vector2i(999999, 999999)
	for key in wall_cells.keys():
		var t := key as Vector2i
		if not bool(map.call("_is_tile_currently_visible", t)):
			continue
		if destroy_tile == Vector2i(999999, 999999):
			destroy_tile = t
		elif stale_wall_tile == Vector2i(999999, 999999) and t != destroy_tile:
			stale_wall_tile = t
			break
	_check(destroy_tile != Vector2i(999999, 999999), "no committed wall tile found anywhere in the primed active window to damage")
	_check(stale_wall_tile != Vector2i(999999, 999999), "fewer than two committed wall tiles in the primed active window; cannot isolate the stale-record test")

	var destroy_chunk := map.call("_tile_to_chunk", destroy_tile) as Vector2i
	map.call("_build_tile_reveal_prepare_record", destroy_tile)
	var inv_before := int(map.debug_get_chunk_payload_cache_snapshot().get("invalidation_count", 0))
	map.damage_wall_tile(destroy_tile, 999999.0)
	var inv_after := int(map.debug_get_chunk_payload_cache_snapshot().get("invalidation_count", 0))
	_check(inv_after > inv_before, "damage_wall_tile did not invalidate the payload cache")
	_check(map.walls_tilemap.get_cell_source_id(destroy_tile) == -1, "damage_wall_tile did not clear the wall tile")

	map.debug_force_unload_chunk(destroy_chunk)
	map.call("_reveal_chunk_immediately", destroy_chunk)
	_check(map.walls_tilemap.get_cell_source_id(destroy_tile) == -1, "wall resurrected after destroy + unload/re-reveal")
	_check(map.floor_tilemap.get_cell_source_id(destroy_tile) != -1, "destroyed-wall floor did not restore after unload/re-reveal")

	# --- (6) Authored-scene/world-overlook claim invalidation ---
	var claim_counts_before := map.debug_get_chunk_payload_cache_snapshot()
	map.call("_build_tile_reveal_prepare_record", spawn_tile)
	var inv_before_claim := int(map.debug_get_chunk_payload_cache_snapshot().get("invalidation_count", 0))
	map.claim_procgen_floor_rect_for_authored_scene_tiles(
		spawn_tile, Vector2i(1, 1), "m5_cache_smoke_region", "m5_cache_smoke_zone", 0, true
	)
	var inv_after_claim := int(map.debug_get_chunk_payload_cache_snapshot().get("invalidation_count", 0))
	_check(inv_after_claim > inv_before_claim, "authored-scene floor claim did not invalidate the payload cache")
	_check(claim_counts_before.size() > 0, "claim invalidation baseline snapshot unexpectedly empty")

	map.debug_force_unload_chunk(spawn_chunk)
	map.call("_reveal_chunk_immediately", spawn_chunk)
	_check(
		String(map.get_region_type_at_tile(spawn_tile)) == "m5_cache_smoke_region",
		"authored-claim region truth was not reflected after unload/re-reveal"
	)

	# --- (7) Stale PREPARE-record refresh before COMMIT ---
	var pre_invalidation_record: Dictionary = map.call("_build_tile_reveal_prepare_record", stale_wall_tile)
	_check(pre_invalidation_record.has("wall_data"), "pre-invalidation record for a wall tile has no wall_data")
	_check(not pre_invalidation_record.has("floor_data"), "pre-invalidation wall record unexpectedly already has floor_data")

	# Destroying the wall invalidates the cache entry, but this Dictionary
	# (already captured above) is untouched -- exactly like a Dictionary
	# already sitting in M3's `_prepared` queue across a resume frame.
	map.damage_wall_tile(stale_wall_tile, 999999.0)
	_check(map.walls_tilemap.get_cell_source_id(stale_wall_tile) == -1, "damage_wall_tile did not clear the stale-test wall tile")

	var stale_before := int(map.debug_get_chunk_payload_cache_snapshot().get("stale_refresh_count", 0))
	map.call("_commit_tile_reveal_record", pre_invalidation_record)
	var stale_after := int(map.debug_get_chunk_payload_cache_snapshot().get("stale_refresh_count", 0))
	_check(stale_after == stale_before + 1, "committing a pre-invalidation record did not trigger exactly one stale refresh")
	_check(
		map.walls_tilemap.get_cell_source_id(stale_wall_tile) == -1,
		"a stale PREPARE record resurrected a destroyed wall tile at COMMIT"
	)
	_check(
		map.floor_tilemap.get_cell_source_id(stale_wall_tile) != -1,
		"a stale PREPARE record prevented the destroyed-wall floor from being painted at COMMIT"
	)

	# --- (8) Presentation-only access never spuriously invalidates ---
	var presentation_before := int(map.debug_get_chunk_payload_cache_snapshot().get("invalidation_count", 0))
	map.call("_is_tile_currently_visible", spawn_tile)
	map.get_runtime_health_snapshot()
	var presentation_after := int(map.debug_get_chunk_payload_cache_snapshot().get("invalidation_count", 0))
	_check(presentation_after == presentation_before, "read-only presentation/telemetry access spuriously invalidated the cache")

	# --- (9) Reset/generation separation across regeneration ---
	var gen_id_before := int(map.debug_get_chunk_payload_cache_snapshot().get("generation_id", -1))
	var reset_count_before := int(map.debug_get_chunk_payload_cache_snapshot().get("reset_count", -1))
	map.generate()
	var post_regen := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(post_regen.get("generation_id", -1)) == gen_id_before + 1, "regenerating did not bump the cache generation id exactly once")
	_check(int(post_regen.get("reset_count", -1)) == reset_count_before + 1, "regenerating did not record exactly one cache reset")

	map.queue_free()
	runtime_container.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
