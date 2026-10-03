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
const NAVIGATION_SYSTEM_SCRIPT := preload("res://game/systems/core/systems/navigation_system.gd")
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
	var victim_floor_pool: Array[Vector2i] = []
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
				victim_floor_pool = floor_tiles
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
	# deterministic TREE with trunk collision and a non-empty cluster id
	# directly through the real spawner path -- legitimate fixture setup, not
	# a claim about generation density -- so the M6 hide/show parity contract
	# below is asserted over true values, not only empty/false metadata.
	map.foliage_probabilistic_tree_collision = false
	map.call("_ensure_foliage_spawner")
	var spawner: Object = map.get("_foliage_spawner")
	var spawner_context: Dictionary = map.call("_build_foliage_spawner_context")
	# The victim chunk deliberately sits next to walls/spawn, where production
	# suppresses trunk collision; lift only that clearance gate so the real
	# placement + blocker-registration path still runs end to end.
	spawner_context["is_inside_tree_trunk_clearance"] = Callable(self, "_no_trunk_clearance")
	var fixture_cluster := &"m6_smoke_cluster"
	victim_foliage_tile = SENTINEL
	for candidate_tile in victim_floor_pool:
		if candidate_tile == victim_floor_tile or candidate_tile == victim_claim_tile:
			continue
		if bool(spawner.call("place_at_kind", spawner_context, candidate_tile, &"tree", fixture_cluster)):
			victim_foliage_tile = candidate_tile
			break
	_check(victim_foliage_tile != SENTINEL, "fixture tree placement failed on every victim-chunk floor tile")
	if victim_foliage_tile == SENTINEL:
		map.queue_free()
		runtime_container.queue_free()
		await process_frame
		return
	var foliage_id_before := map.debug_get_foliage_node_id(victim_foliage_tile)
	_check(foliage_id_before != 0, "fixture foliage placement failed on the victim floor tile")
	var foliage_meta_before := _foliage_parity(map, victim_foliage_tile)
	_check(String(foliage_meta_before.get("kind", "")) == "tree", "fixture foliage is not a tree")
	_check(String(foliage_meta_before.get("cluster_id", "")) == String(fixture_cluster), "fixture foliage lost its cluster id")
	_check(bool(foliage_meta_before.get("has_collision", false)), "fixture tree has no trunk collision")
	_check(bool(foliage_meta_before.get("has_runtime_blocker", false)), "fixture tree has no registered runtime prop blocker")
	var had_road_decal := map.debug_has_road_piece_decal(victim_wall_tile) \
			or map.debug_has_road_piece_decal(victim_floor_tile)
	# Guarantee a road presentation node in the evicted chunk so road removal
	# is always exercised, regardless of what generation placed there.
	if map.get("_road_piece_parent") == null or not is_instance_valid(map.get("_road_piece_parent")):
		map.set("_road_piece_parent", map.call("_find_or_create_road_piece_parent"))
	map.call("_spawn_road_piece_decal", victim_floor_tile, {"id": "m6_smoke_fixture", "res_path": "res://icon.svg"}, "road")
	_check(map.debug_has_road_piece_decal(victim_floor_tile), "fixture road decal was not created before unload")

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
	# Snapshot after the far transition (which queues/caches the far chunks)
	# and before any eviction, so the drain can only shrink these counts.
	# The victim's payload may not be resident in the M5 cache yet; populate its
	# membership and a tile record through the production lookup so the
	# eviction has real cached state to drop.
	map.call("_cached_chunk_tiles", victim_chunk)
	map.call("_build_tile_reveal_prepare_record", victim_floor_tile)
	var residency_before := _residency_counts(map, victim_wall_tile, victim_floor_tile)
	_check_coalesced_eviction_flush(map)
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
	# Captured before the R0-01 process tick below, which legitimately reveals
	# (and caches) the queued far chunks.
	var residency_after := _residency_counts(map, victim_wall_tile, victim_floor_tile)
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
	_check(int(residency_after.floor_cells) < int(residency_before.floor_cells), "painted floor cell count did not drop after unload")
	_check(int(residency_after.wall_cells) < int(residency_before.wall_cells), "painted wall cell count did not drop after unload")
	_check(int(residency_after.cached_chunks) < int(residency_before.cached_chunks), "cached chunk membership count did not drop after unload")
	_check(int(residency_after.cached_records) < int(residency_before.cached_records), "cached tile record count did not drop after unload")
	_check(int(residency_after.generated_floor) == int(residency_before.generated_floor), "canonical generated floor count changed across unload")
	_check(int(residency_after.generated_wall) == int(residency_before.generated_wall), "canonical generated wall count changed across unload")
	_check(bool(residency_before.road_decal), "the guaranteed fixture road decal was absent before unload")
	_check(not bool(residency_after.road_decal), "road decal presence did not drop after unload")
	_check(_same_parity(_foliage_parity(map, victim_foliage_tile), foliage_meta_before), "foliage kind/cluster/collision/blocker metadata changed on unload")
	_check_navigation_rebuild(map, runtime_container, victim_floor_tile, victim_wall_tile, spawn_tile)
	_check_protected_anchor(map, victim_chunk, spawn_chunk, far_chunk, far_tile)
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
	_check(_same_parity(_foliage_parity(map, victim_foliage_tile), foliage_meta_before), "foliage kind/cluster/collision/blocker metadata changed across unload/reload")
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


func _no_trunk_clearance(_tile: Vector2i) -> bool:
	return false


## Foliage metadata plus the runtime-blocker cells registered for this exact
## node. A tree's trunk blocker is derived from its collision geometry, so it
## is read from the node's own registered source rather than assumed to sit on
## the foliage tile itself.
func _foliage_parity(map: ProcGenTilemap, tile: Vector2i) -> Dictionary:
	var meta: Dictionary = map.debug_get_foliage_entry_metadata(tile)
	var node_id := map.debug_get_foliage_node_id(tile)
	var sources: Dictionary = map.get("_runtime_prop_blocker_sources")
	var cells: Array = (sources.get(str(node_id), {}) as Dictionary).get("cells", [])
	var cell_strings: Array[String] = []
	var all_registered := not cells.is_empty()
	for cell in cells:
		cell_strings.append(str(cell))
		if not map.has_runtime_prop_blocker_at_tile(cell as Vector2i):
			all_registered = false
	cell_strings.sort()
	meta["has_runtime_blocker"] = all_registered
	meta["blocker_cells"] = ",".join(cell_strings)
	return meta


func _same_parity(a: Dictionary, b: Dictionary) -> bool:
	for key in ["kind", "cluster_id", "has_collision", "has_runtime_blocker", "blocker_cells"]:
		if a.get(key) != b.get(key):
			return false
	return true


func _residency_counts(map: ProcGenTilemap, wall_tile: Vector2i, floor_tile: Vector2i) -> Dictionary:
	var cache := map.debug_get_chunk_payload_cache_snapshot()
	return {
		"floor_cells": map.floor_tilemap.get_used_cells().size(),
		"wall_cells": map.walls_tilemap.get_used_cells().size(),
		"cached_chunks": int(cache.get("cached_chunk_count", -1)),
		"cached_records": int(cache.get("cached_tile_record_count", -1)),
		"generated_floor": map.debug_get_generated_floor_cells().size(),
		"generated_wall": map.debug_get_generated_wall_cells().size(),
		"road_decal": map.debug_has_road_piece_decal(wall_tile) or map.debug_has_road_piece_decal(floor_tile),
	}


## R0-02/N1-02: a real NavigationSystem rebuilt after the unload yields a real
## A* connectivity/path result for the previously-revealed floor tile, and a
## genuinely UNSEEN chunk (one that has canonical tiles) stays excluded.
func _check_navigation_rebuild(
	map: ProcGenTilemap, container: Node, floor_tile: Vector2i, wall_tile: Vector2i, spawn_tile: Vector2i
) -> void:
	var state := CHUNK_LIFECYCLE_SCRIPT.State
	var navigation: Node = NAVIGATION_SYSTEM_SCRIPT.new()
	container.add_child(navigation)
	navigation.call("set_runtime_tilemaps", map.floor_tilemap, map.walls_tilemap, map)
	navigation.call("rebuild")
	var walkable: Dictionary = navigation.get("_walkable_tiles")
	var astar: AStar2D = navigation.get("astar")
	_check(walkable.has(floor_tile), "rebuilt NavigationSystem dropped the unloaded chunk's previously-revealed floor tile")
	_check(not walkable.has(wall_tile), "rebuilt NavigationSystem treated an unloaded wall tile as walkable")
	var floor_id := int(navigation.call("_cell_to_id", floor_tile))
	_check(astar.has_point(floor_id), "rebuilt A* graph has no point for the unloaded floor tile")
	var neighbor_found := false
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = floor_tile + offset
		if walkable.has(neighbor):
			neighbor_found = true
			var path_ids := astar.get_id_path(floor_id, int(navigation.call("_cell_to_id", neighbor)))
			_check(path_ids.size() >= 2, "no A* path between the unloaded floor tile and its walkable neighbor")
			break
	_check(neighbor_found, "unloaded floor tile has no walkable neighbor in the rebuilt graph")
	if walkable.has(spawn_tile):
		var spawn_path := astar.get_id_path(floor_id, int(navigation.call("_cell_to_id", spawn_tile)))
		_check(spawn_path.size() >= 2, "no A* path from the unloaded floor tile to the spawn tile")
		var world_path: PackedVector2Array = navigation.call(
			"compute_path_immediate",
			map.floor_tilemap.to_global(map.floor_tilemap.map_to_local(floor_tile)),
			map.floor_tilemap.to_global(map.floor_tilemap.map_to_local(spawn_tile))
		)
		_check(world_path.size() >= 2, "compute_path_immediate returned no path for the unloaded floor tile")
	else:
		_check(false, "spawn tile is absent from the rebuilt navigation graph")
	var size := int(map.streaming_chunk_size_tiles)
	var unseen_checked := 0
	for cx in range(0, int(ceil(float(map.procgen_node.map_size.x) / size))):
		for cy in range(0, int(ceil(float(map.procgen_node.map_size.y) / size))):
			var chunk := Vector2i(cx, cy)
			if int(map.debug_get_chunk_lifecycle_state(chunk)) != state.UNSEEN:
				continue
			var chunk_tiles: Array[Vector2i] = map.call("_get_chunk_tiles", chunk)
			if chunk_tiles.is_empty():
				continue
			unseen_checked += 1
			for tile in chunk_tiles:
				if walkable.has(tile):
					_check(false, "rebuilt NavigationSystem included a tile from UNSEEN chunk %s" % str(chunk))
					navigation.queue_free()
					return
	_check(unseen_checked > 0, "no genuinely UNSEEN chunk with canonical tiles existed to prove exclusion")
	navigation.queue_free()


## R0-03/N1-04: a hermetic protected-anchor proof. The anchor is a DORMANT,
## non-spawn chunk with NO pre-existing protection source; one injected portal
## is the sole reason it becomes protected and survives repeated eviction
## drains; removing that portal makes the same chunk evictable again.
func _check_protected_anchor(
	map: ProcGenTilemap, victim_chunk: Vector2i, spawn_chunk: Vector2i, far_chunk: Vector2i, far_tile: Vector2i
) -> void:
	var state := CHUNK_LIFECYCLE_SCRIPT.State
	var protected_now: Dictionary = map.debug_get_protected_streaming_chunks()
	var anchor_chunk := SENTINEL
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var candidate := spawn_chunk + Vector2i(dx, dy)
			if candidate == spawn_chunk or candidate == victim_chunk or protected_now.has(candidate):
				continue
			if int(map.debug_get_chunk_lifecycle_state(candidate)) == state.DORMANT:
				anchor_chunk = candidate
				break
		if anchor_chunk != SENTINEL:
			break
	_check(anchor_chunk != SENTINEL, "no DORMANT, unprotected, non-spawn chunk remained to exercise the protected-anchor check")
	if anchor_chunk == SENTINEL:
		return
	_check(not map.debug_get_protected_streaming_chunks().has(anchor_chunk), "anchor chunk was already protected before the portal was injected")
	var size := int(map.streaming_chunk_size_tiles)
	var anchor_tile := anchor_chunk * size + Vector2i(size / 2, size / 2)
	var portal := Area2D.new()
	map.add_child(portal)
	portal.global_position = map.floor_tilemap.to_global(map.floor_tilemap.map_to_local(anchor_tile))
	var portals: Array = map.get("_portal_teleporters")
	portals.append(portal)
	_check(map.debug_get_protected_streaming_chunks().has(anchor_chunk), "the injected portal did not protect its chunk")
	for i in 48:
		_simulate_player_chunk_transition(map, far_chunk, far_tile)
		map.call("_drain_residency_eviction")
	_check(map.debug_get_unloaded_chunks().find(anchor_chunk) == -1, "a portal-protected DORMANT far chunk was evicted")
	# Mutation: remove the sole protection source; the same chunk must now be
	# protected no longer and become evictable.
	portals.erase(portal)
	portal.queue_free()
	_check(not map.debug_get_protected_streaming_chunks().has(anchor_chunk), "chunk stayed protected after its only portal was removed")
	var guard := 0
	while map.debug_get_unloaded_chunks().find(anchor_chunk) == -1 and guard < 128:
		_simulate_player_chunk_transition(map, far_chunk, far_tile)
		map.call("_drain_residency_eviction")
		guard += 1
	_check(map.debug_get_unloaded_chunks().find(anchor_chunk) != -1, "removing the injected portal did not make the anchor chunk evictable")


## R0-01/N1-01: with an empty reveal queue and a multi-candidate backlog,
## consecutive one-chunk-per-frame evictions inside one rebuild interval must
## trigger ZERO full visual-rebuild flushes, then exactly one once the
## interval elapses.
func _check_coalesced_eviction_flush(map: ProcGenTilemap) -> void:
	(map.get("_streaming_reveal_queue") as Array).clear()
	var pause_aware: Object = map.get("_pause_aware_streaming")
	if pause_aware != null:
		pause_aware.call("reset")
	var interval := float(map.streaming_visual_rebuild_interval_sec)
	map.call("_process_streaming_reveal_queue", interval)
	var backlog := int(map.debug_get_chunk_residency_policy_snapshot().get("pending_count", 0))
	_check(backlog >= 3, "test fixture has fewer than three eligible eviction candidates (%d)" % backlog)
	var flushes_before := map.debug_get_streaming_visual_flush_count()
	var evicted_before := int(map.debug_get_chunk_residency_policy_snapshot().get("evicted_count", 0))
	var frames := 0
	var simulated := 0.0
	while int(map.debug_get_chunk_residency_policy_snapshot().get("evicted_count", 0)) - evicted_before < 3 and frames < 6:
		map.call("_drain_residency_eviction")
		map.call("_process_streaming_reveal_queue", interval * 0.1)
		simulated += interval * 0.1
		frames += 1
	var evicted := int(map.debug_get_chunk_residency_policy_snapshot().get("evicted_count", 0)) - evicted_before
	_check(evicted >= 3 and frames >= 3, "fewer than three consecutive eviction frames were driven (%d evictions / %d frames)" % [evicted, frames])
	_check(simulated < interval, "fixture frames did not stay inside one rebuild interval")
	_check(
		map.debug_get_streaming_visual_flush_count() == flushes_before,
		"%d eviction frames inside one interval performed %d full visual flushes instead of none" % [
			frames, map.debug_get_streaming_visual_flush_count() - flushes_before
		]
	)
	_check(bool(map.get("_streaming_visual_rebuild_pending")), "eviction left no pending visual rebuild to coalesce")
	map.call("_process_streaming_reveal_queue", interval)
	_check(
		map.debug_get_streaming_visual_flush_count() == flushes_before + 1,
		"the coalesced interval flush did not occur exactly once"
	)


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
