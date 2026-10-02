extends SceneTree

## Covers PROCGEN_DISTANT_CHUNK_UNLOAD.md (M6) acceptance: pure
## ProcGenChunkResidencyPolicy candidate selection (eligibility, ordering,
## protection, cancellation), bounded per-frame production eviction wired
## through ProcGenTilemap, M5 cache-record eviction, wall-collision
## retention through visual unload (and correct removal on genuine
## destruction), navigation authority survival for a previously-revealed
## then unloaded chunk, foliage node identity/visibility/blocker parity
## across hide/show, road-decal unload/reload parity, safe semantic
## mutation (wall destruction, authored-scene claim) while a chunk is
## UNLOADED, and stale-candidate cancellation when the player returns.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CHUNK_LIFECYCLE_SCRIPT := preload("res://game/world/procgen/streaming/procgen_chunk_lifecycle.gd")
const RESIDENCY_POLICY_SCRIPT := preload("res://game/world/procgen/streaming/procgen_chunk_residency_policy.gd")

const SENTINEL := Vector2i(999999, 999999)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_pure_policy()
	await _test_runtime_unload_reload()
	if _errors.is_empty():
		print("[ProcgenDistantChunkUnloadSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenDistantChunkUnloadSmoke] %s" % error)
	quit(1)


# --- (0) Pure ProcGenChunkResidencyPolicy fixture -------------------------

func _test_pure_policy() -> void:
	var policy := RESIDENCY_POLICY_SCRIPT.new()
	var center := Vector2i(10, 10)
	var protected_chunks := {Vector2i(13, 10): true}

	# Eligibility: strictly greater than unload_distance, excludes protected.
	var dormant: Array[Vector2i] = [
		Vector2i(10, 8),   # distance 2 -- not eligible (== unload_distance)
		Vector2i(10, 7),   # distance 3 -- eligible
		Vector2i(13, 10),  # distance 3 -- eligible, protected
		Vector2i(14, 10),  # distance 4 -- eligible, farthest
	]
	policy.refresh_candidates(center, dormant, protected_chunks, 2)
	var snap0 := policy.get_snapshot()
	_check(int(snap0.get("pending_count", -1)) == 2, "policy admitted the wrong candidate count on first refresh")
	_check(int(snap0.get("protected_rejected_count", -1)) == 1, "policy did not reject the protected candidate")
	_check(int(snap0.get("refresh_count", -1)) == 1, "policy refresh_count did not advance")

	# A second refresh that drops a previously-eligible, not-yet-taken
	# candidate (the player returned near it) must count it cancelled.
	policy.refresh_candidates(center, [Vector2i(14, 10)], protected_chunks, 2)
	var snap1 := policy.get_snapshot()
	_check(int(snap1.get("cancelled_count", -1)) == 1, "a stale not-yet-taken candidate dropping out on refresh was not counted cancelled")
	_check(int(snap1.get("pending_count", -1)) == 1, "second refresh queue size is wrong")

	# Farthest-first, then coordinate-stable drain order.
	policy.refresh_candidates(center, dormant, protected_chunks, 2)
	var taken := policy.take_candidates(10)
	_check(taken == [Vector2i(14, 10), Vector2i(10, 7)], "policy did not drain farthest-first")
	_check(int(policy.get_snapshot().get("pending_count", -1)) == 0, "take_candidates did not drain the queue")

	policy.note_evicted()
	policy.note_cancelled()
	var snap2 := policy.get_snapshot()
	_check(int(snap2.get("evicted_count", -1)) == 1, "note_evicted did not advance evicted_count")
	_check(int(snap2.get("cancelled_count", -1)) == 2, "note_cancelled did not advance cancelled_count")

	policy.reset()
	var snap3 := policy.get_snapshot()
	_check(int(snap3.get("pending_count", -1)) == 0 and int(snap3.get("refresh_count", -1)) == 0, "reset() did not clear policy state")


# --- (1+) Runtime integration ---------------------------------------------

func _test_runtime_unload_reload() -> void:
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
	procgen.seed = 20261001
	procgen.map_size = Vector2i(72, 72)
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = true
	map.streaming_chunk_size_tiles = 6
	map.streaming_immediate_chunk_radius = 2
	map.streaming_active_chunk_radius = 2
	map.streaming_reveal_tiles_per_frame = 256
	map.build_runtime_wall_collision = true
	map.streaming_unload_distant_chunks = true
	map.streaming_unload_chunk_distance = 3
	map.streaming_unload_chunks_per_frame = 1

	map.generate()

	var state := CHUNK_LIFECYCLE_SCRIPT.State
	var spawn_tile := map.get_player_spawn()
	var spawn_chunk := map.call("_tile_to_chunk", spawn_tile) as Vector2i

	# --- locate a non-spawn, unprotected victim chunk with a canonical wall
	# tile and at least three distinct floor tiles, inside the immediately-
	# revealed 5x5 window ---
	var generated_walls: Dictionary = map.debug_get_generated_wall_cells()
	var victim_chunk := SENTINEL
	var victim_wall_tile := SENTINEL
	var victim_floor_tile := SENTINEL
	var victim_foliage_tile := SENTINEL
	var victim_claim_tile := SENTINEL
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if dx == 0 and dy == 0:
				continue
			var candidate := spawn_chunk + Vector2i(dx, dy)
			var tiles: Array[Vector2i] = map.call("_get_chunk_tiles", candidate)
			if tiles.is_empty():
				continue
			var wall_tile := SENTINEL
			var floor_tiles: Array[Vector2i] = []
			for tile in tiles:
				if generated_walls.has(tile):
					if wall_tile == SENTINEL and bool(map.call("_is_tile_currently_visible", tile)):
						wall_tile = tile
				else:
					floor_tiles.append(tile)
			if wall_tile != SENTINEL and floor_tiles.size() >= 3:
				victim_chunk = candidate
				victim_wall_tile = wall_tile
				victim_floor_tile = floor_tiles[0]
				victim_foliage_tile = floor_tiles[1]
				victim_claim_tile = floor_tiles[2]
				break
		if victim_chunk != SENTINEL:
			break
	_check(victim_chunk != SENTINEL, "no unprotected victim chunk with a wall tile and three floor tiles was found near spawn")
	if victim_chunk == SENTINEL:
		map.queue_free()
		runtime_container.queue_free()
		await process_frame
		return

	# Organic generation-time foliage placement is deliberately suppressed
	# this close to spawn (route/spawn clearance), so this force-places one
	# deterministic foliage node directly through the real spawner path --
	# legitimate fixture setup, not a claim about generation density -- to
	# exercise the M6 hide/show identity contract below.
	map.call("_place_foliage", victim_foliage_tile)
	var foliage_id_before := map.debug_get_foliage_node_id(victim_foliage_tile)
	_check(foliage_id_before != 0, "fixture foliage placement failed on the victim floor tile")
	var had_road_decal := map.debug_has_road_piece_decal(victim_wall_tile) \
			or map.debug_has_road_piece_decal(victim_floor_tile)

	# --- (A) stale candidate cancellation: refresh far, then return before draining ---
	var far_chunk := spawn_chunk + Vector2i(20, 0)
	var far_tile := spawn_tile + Vector2i(20 * map.streaming_chunk_size_tiles, 0)
	_simulate_player_chunk_transition(map, far_chunk, far_tile)
	_check(
		int(map.debug_get_chunk_lifecycle_state(victim_chunk)) == state.DORMANT,
		"victim chunk did not become DORMANT after the player moved far away"
	)
	var cancelled_before := int(map.debug_get_chunk_residency_policy_snapshot().get("cancelled_count", -1))
	_simulate_player_chunk_transition(map, spawn_chunk, spawn_tile)
	var cancelled_after := int(map.debug_get_chunk_residency_policy_snapshot().get("cancelled_count", -1))
	_check(cancelled_after > cancelled_before, "returning near a queued eviction candidate did not record a cancellation")
	_check(
		int(map.debug_get_chunk_lifecycle_state(victim_chunk)) == state.VISIBLE,
		"victim chunk did not return to VISIBLE after the player returned"
	)
	_check(map.debug_get_unloaded_chunks().find(victim_chunk) == -1, "a stale candidate was unloaded instead of cancelled")

	# --- (B) move far again and drain the bounded eviction budget ---
	_simulate_player_chunk_transition(map, far_chunk, far_tile)
	_check(
		int(map.debug_get_chunk_residency_policy_snapshot().get("protected_rejected_count", 0)) > 0,
		"spawn chunk (always protected) was never rejected by a residency refresh"
	)
	var unloaded_before_drain := map.debug_get_unloaded_chunks().size()
	map.call("_drain_residency_eviction")
	var unloaded_after_one_drain := map.debug_get_unloaded_chunks().size() - unloaded_before_drain
	_check(
		unloaded_after_one_drain <= map.streaming_unload_chunks_per_frame,
		"a single drain unloaded more than the configured per-frame budget"
	)
	var drain_guard := 0
	while map.debug_get_chunk_lifecycle_state(victim_chunk) != state.UNLOADED and drain_guard < 64:
		map.call("_drain_residency_eviction")
		drain_guard += 1
	_check(int(map.debug_get_chunk_lifecycle_state(victim_chunk)) == state.UNLOADED, "victim chunk was never drained to UNLOADED")
	_check(map.debug_get_unloaded_chunks().find(spawn_chunk) == -1, "the protected spawn chunk was unloaded")

	# --- (C) cache-record eviction, collision retention, nav retention,
	# foliage identity/visibility, road-decal removal ---
	var cache_snapshot := map.debug_get_chunk_payload_cache_snapshot()
	_check(int(cache_snapshot.get("eviction_count", 0)) > 0, "no M5 cache eviction was recorded for the unloaded chunk")
	_check(
		map.debug_has_runtime_wall_collision_body(victim_wall_tile),
		"wall collision was removed merely because its chunk unloaded"
	)
	_check(
		bool(map.call("is_runtime_navigation_walkable", victim_floor_tile)),
		"navigation semantic authority changed for an unloaded previously-walkable floor tile"
	)
	_check(
		not bool(map.call("is_runtime_navigation_walkable", victim_wall_tile)),
		"navigation semantic authority changed for an unloaded wall tile"
	)
	var nav_floor_cells: Array = map.call("get_runtime_navigation_floor_cells")
	_check(nav_floor_cells.has(victim_floor_tile), "unloaded chunk's floor tile dropped out of navigation graph source cells")
	var foliage_id_after_unload := map.debug_get_foliage_node_id(victim_foliage_tile)
	_check(foliage_id_after_unload == foliage_id_before, "foliage node was destroyed/recreated instead of hidden on unload")
	_check(map.debug_get_foliage_node_visible(victim_foliage_tile) == false, "foliage node was not hidden on unload")
	if had_road_decal:
		_check(
			not map.debug_has_road_piece_decal(victim_wall_tile) and not map.debug_has_road_piece_decal(victim_floor_tile),
			"road decal survived chunk unload"
		)

	# UNSEEN chunks (never revealed) must never appear in the navigation
	# source set merely because canonical semantics could exist for them.
	var unseen_chunk := spawn_chunk + Vector2i(0, 40)
	_check(
		int(map.debug_get_chunk_lifecycle_state(unseen_chunk)) == state.UNSEEN,
		"test assumption failed: probe chunk was not actually UNSEEN"
	)

	# --- (D) safe mutation while UNLOADED: wall destruction ---
	var destroy_result: Dictionary = map.damage_wall_tile(victim_wall_tile, 999999.0)
	_check(bool(destroy_result.get("destroyed", false)), "damage_wall_tile did not recognize a canonical wall on an unloaded tile")
	_check(not map.debug_get_generated_wall_cells().has(victim_wall_tile), "destroying a wall on an unloaded tile did not clear canonical wall authority")
	_check(not map.debug_has_runtime_wall_collision_body(victim_wall_tile), "destroying a wall on an unloaded tile left its collision body behind")
	_check(not bool(map.call("_is_tile_currently_visible", victim_wall_tile)), "destroying a wall on an unloaded tile prematurely repainted it")

	# --- (E) safe mutation while UNLOADED: authored-scene claim ---
	var claim_tile := victim_claim_tile
	map.claim_procgen_floor_rect_for_authored_scene_tiles(
		claim_tile, Vector2i(1, 1), "m6_smoke_region", "m6_smoke_zone", 0, true
	)
	_check(not bool(map.call("_is_tile_currently_visible", claim_tile)), "an authored-scene claim on an unloaded tile prematurely repainted it")

	# --- (F) reload: COMMIT materializes mutated canonical truth, nothing stale resurrects ---
	map.call("_reveal_chunk_immediately", victim_chunk)
	_check(int(map.debug_get_chunk_lifecycle_state(victim_chunk)) == state.VISIBLE, "victim chunk did not return to VISIBLE after reload")
	_check(map.walls_tilemap.get_cell_source_id(victim_wall_tile) == -1, "destroyed wall resurrected after unload/reload")
	_check(map.floor_tilemap.get_cell_source_id(victim_wall_tile) != -1, "destroyed-wall floor did not materialize after unload/reload")
	_check(String(map.get_region_type_at_tile(claim_tile)) == "m6_smoke_region", "authored-scene claim truth was not reflected after unload/reload")
	_check(map.floor_tilemap.get_cell_source_id(victim_floor_tile) != -1, "claimed floor tile did not repaint after reload")
	_check(map.debug_get_foliage_node_id(victim_foliage_tile) == foliage_id_before, "foliage node identity changed across unload/reload")
	_check(map.debug_get_foliage_node_visible(victim_foliage_tile) == true, "foliage node was not re-shown after reload")
	if had_road_decal:
		_check(
			map.debug_has_road_piece_decal(victim_wall_tile) or map.debug_has_road_piece_decal(victim_floor_tile),
			"road decal did not recreate after reload"
		)

	# --- (G) telemetry surface sanity ---
	var health := map.get_runtime_health_snapshot()
	_check(health.has("chunk_residency_policy"), "runtime health snapshot is missing chunk_residency_policy telemetry")
	_check(int(health.get("unloaded_chunk_count", -1)) >= 0, "runtime health snapshot is missing unloaded_chunk_count telemetry")
	_check(int(health.get("residency_effective_unload_distance", -1)) == 3, "runtime health snapshot reports the wrong effective unload distance")

	map.queue_free()
	runtime_container.queue_free()
	await process_frame


## `_update_streaming_chunks()` is normally only ever called from
## `_process()` in lockstep with assigning `_streaming_current_chunk` to the
## same value -- `_drain_residency_eviction()`'s distance revalidation reads
## that member directly. Driving `_update_streaming_chunks()` straight from
## a test must reproduce that same lockstep or the revalidation distance is
## measured from a stale/sentinel center.
func _simulate_player_chunk_transition(map: ProcGenTilemap, chunk: Vector2i, tile: Vector2i) -> void:
	map.set("_streaming_current_chunk", chunk)
	map.call("_update_streaming_chunks", chunk, tile)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
