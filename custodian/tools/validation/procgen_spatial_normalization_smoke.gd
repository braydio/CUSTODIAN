extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SPATIAL_CONTRACT := preload("res://game/world/procgen/procgen_spatial_contract.gd")
const THREADWAY_CAUSEWAY_SCRIPT := preload("res://game/world/approaches/ash_bell/ash_bell_threadway_causeway.gd")
const WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")
const TEST_SEED := 913042
const TOLERANCE := 0.01

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := await _generate_map("ProcgenSpatialNormalizationMap")

	_check_root_scale(map)
	_check_tileset(map)
	_check_runtime_contract(map)
	_check_horizontal_step(map)
	_check_vertical_step(map)
	_check_round_trip(map)
	_check_centering(map)
	_check_map_extents(map)
	_check_player_spawn(map)
	_check_wall_collision(map)
	await _check_navigation(map)
	_check_shadow_system(map)
	_check_ash_bell_threadway(map)
	_check_contract_world_loader(map)
	_check_streaming(map)
	_check_no_scale_compensation(map)

	map.queue_free()
	_finish()


func _generate_map(node_name: String) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.name = node_name
	root.add_child(map)
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = TEST_SEED
	generator.map_size = Vector2i(96, 80)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = true
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.auto_bake_nav = true
	map.generate()
	await process_frame
	await process_frame
	return map


# 1. ROOT
func _check_root_scale(map: ProcGenTilemap) -> void:
	_log("ROOT scale = %s" % str(map.scale))
	_expect(map.scale.is_equal_approx(Vector2.ONE), "ProcGenMap.scale must be Vector2.ONE, was %s" % str(map.scale))


# 2. TILESET
func _check_tileset(map: ProcGenTilemap) -> void:
	var floor_size: Vector2i = map.floor_tilemap.tile_set.tile_size
	var walls_size: Vector2i = map.walls_tilemap.tile_set.tile_size
	_log("TILESET floor.tile_size = %s, walls.tile_size = %s" % [str(floor_size), str(walls_size)])
	_expect(floor_size == SPATIAL_CONTRACT.CELL_SIZE_I, "Floor.tile_set.tile_size must be 32x32, was %s" % str(floor_size))
	_expect(walls_size == SPATIAL_CONTRACT.CELL_SIZE_I, "Walls.tile_set.tile_size must be 32x32, was %s" % str(walls_size))


# 3. RUNTIME CONTRACT
func _check_runtime_contract(map: ProcGenTilemap) -> void:
	var runtime_size := map.get_runtime_tile_size()
	_log("RUNTIME get_runtime_tile_size() = %s" % str(runtime_size))
	_expect(runtime_size.is_equal_approx(SPATIAL_CONTRACT.CELL_SIZE), "get_runtime_tile_size() must be (32,32), was %s" % str(runtime_size))


# 4. HORIZONTAL STEP
func _check_horizontal_step(map: ProcGenTilemap) -> void:
	var origin := map.tile_to_global_position(Vector2i(0, 0))
	var east := map.tile_to_global_position(Vector2i(1, 0))
	var step := east.distance_to(origin)
	_log("HORIZONTAL STEP (0,0)->(1,0) = %.4f" % step)
	_expect(is_equal_approx(step, float(SPATIAL_CONTRACT.CELL_SIZE_PX)), "horizontal neighbor step must be 32 world px, was %.4f" % step)


# 5. VERTICAL STEP
func _check_vertical_step(map: ProcGenTilemap) -> void:
	var origin := map.tile_to_global_position(Vector2i(0, 0))
	var south := map.tile_to_global_position(Vector2i(0, 1))
	var step := south.distance_to(origin)
	_log("VERTICAL STEP (0,0)->(0,1) = %.4f" % step)
	_expect(is_equal_approx(step, float(SPATIAL_CONTRACT.CELL_SIZE_PX)), "vertical neighbor step must be 32 world px, was %.4f" % step)


# 6. ROUND TRIP
func _check_round_trip(map: ProcGenTilemap) -> void:
	var cells := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(10, 10), Vector2i(31, 17)]
	for cell in cells:
		var global_pos: Vector2 = map.tile_to_global_position(cell)
		var round_tripped: Vector2i = map.call("_global_to_tile", global_pos)
		_log("ROUND TRIP %s -> %s -> %s" % [str(cell), str(global_pos), str(round_tripped)])
		_expect(round_tripped == cell, "round trip for %s produced %s" % [str(cell), str(round_tripped)])


# 7. CENTERING
func _check_centering(map: ProcGenTilemap) -> void:
	var local_center: Vector2 = map.floor_tilemap.map_to_local(Vector2i.ZERO)
	_log("CENTERING map_to_local(0,0) local = %s (expected half-cell %s)" % [str(local_center), str(SPATIAL_CONTRACT.HALF_CELL)])
	_expect(
		local_center.is_equal_approx(SPATIAL_CONTRACT.HALF_CELL),
		"cell (0,0) must center at the half-cell offset %s, was %s" % [str(SPATIAL_CONTRACT.HALF_CELL), str(local_center)]
	)
	var east_local: Vector2 = map.floor_tilemap.map_to_local(Vector2i(1, 0))
	var expected_east := SPATIAL_CONTRACT.HALF_CELL + Vector2(SPATIAL_CONTRACT.CELL_SIZE_PX, 0.0)
	_expect(
		east_local.is_equal_approx(expected_east),
		"cell (1,0) must center at %s, was %s" % [str(expected_east), str(east_local)]
	)


# 8. MAP EXTENTS
func _check_map_extents(map: ProcGenTilemap) -> void:
	var level_data := map.get_level_data()
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var measured_width := map.tile_to_global_position(Vector2i(map_size.x - 1, 0)).distance_to(map.tile_to_global_position(Vector2i.ZERO))
	var measured_height := map.tile_to_global_position(Vector2i(0, map_size.y - 1)).distance_to(map.tile_to_global_position(Vector2i.ZERO))
	var expected_width := float(map_size.x - 1) * SPATIAL_CONTRACT.CELL_SIZE_PX
	var expected_height := float(map_size.y - 1) * SPATIAL_CONTRACT.CELL_SIZE_PX
	_log(
		"MAP EXTENTS map_size=%s measured_width=%.2f expected_width=%.2f measured_height=%.2f expected_height=%.2f"
		% [str(map_size), measured_width, expected_width, measured_height, expected_height]
	)
	_expect(is_equal_approx(measured_width, expected_width), "map world width mismatch: %.2f != %.2f" % [measured_width, expected_width])
	_expect(is_equal_approx(measured_height, expected_height), "map world height mismatch: %.2f != %.2f" % [measured_height, expected_height])


# 9. PLAYER SPAWN
func _check_player_spawn(map: ProcGenTilemap) -> void:
	var spawn_tile: Vector2i = map.get_player_spawn()
	var spawn_global: Vector2 = map.tile_to_global_position(spawn_tile)
	var expected_global: Vector2 = map.floor_tilemap.to_global(map.floor_tilemap.map_to_local(spawn_tile))
	_log("PLAYER SPAWN tile=%s global=%s" % [str(spawn_tile), str(spawn_global)])
	_expect(
		spawn_global.is_equal_approx(expected_global),
		"player spawn tile %s must resolve to the canonical transform, got %s expected %s" % [str(spawn_tile), str(spawn_global), str(expected_global)]
	)


# 10. WALL COLLISION
func _check_wall_collision(map: ProcGenTilemap) -> void:
	var wall_cells := map.debug_get_generated_wall_cells()
	if wall_cells.is_empty():
		_failures.append("no generated wall cells to validate collision against")
		return
	var sample_tile: Vector2i = wall_cells.keys()[0]
	var collision_root := map.walls_tilemap.get_node_or_null("RuntimeWallCollision")
	_expect(collision_root != null, "RuntimeWallCollision root missing")
	if collision_root == null:
		return
	var found_shape := false
	for body in collision_root.get_children():
		if not body.has_method("get_wall_tiles"):
			continue
		var tiles: Array = body.call("get_wall_tiles")
		if not tiles.has(sample_tile):
			continue
		for shape_owner_id in (body as CollisionObject2D).get_shape_owners():
			var shape_owner := body as CollisionObject2D
			for shape_index in shape_owner.shape_owner_get_shape_count(shape_owner_id):
				var shape := shape_owner.shape_owner_get_shape(shape_owner_id, shape_index)
				if shape is RectangleShape2D:
					found_shape = true
					var extents: Vector2 = (shape as RectangleShape2D).size
					_log("WALL COLLISION sample_tile=%s shape_size=%s" % [str(sample_tile), str(extents)])
					_expect(
						is_equal_approx(extents.x, float(SPATIAL_CONTRACT.CELL_SIZE_PX)) or extents.x >= SPATIAL_CONTRACT.CELL_SIZE_PX - TOLERANCE,
						"wall collision shape width should align to the 32px cell grid, was %s" % str(extents)
					)
		break
	_expect(found_shape, "could not find a RectangleShape2D collision shape for sample wall tile %s" % str(sample_tile))
	var body_global := map.minimap_tile_to_global(sample_tile)
	var expected_body_global := map.tile_to_global_position(sample_tile)
	_expect(
		body_global.is_equal_approx(expected_body_global),
		"wall collision anchor position must match the canonical tile transform"
	)


# 11. NAVIGATION
# Gameplay (enemy_behavior_state_machine.gd's patrol targeting) does not use
# Godot's NavigationServer2D/baked NavigationPolygon at all -- it resolves
# reachable neighbors via ProcGenTilemap.project_runtime_walkable_global(),
# a tile-grid walkability projection. That is the real navigation contract
# this migration must keep aligned to the 32px grid.
func _check_navigation(map: ProcGenTilemap) -> void:
	var spawn_tile: Vector2i = map.get_player_spawn()
	var floor_cells := map.debug_get_generated_floor_cells()
	var neighbor := Vector2i.ZERO
	var found_neighbor := false
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for offset in offsets:
		var candidate: Vector2i = spawn_tile + offset
		if floor_cells.has(candidate):
			neighbor = candidate
			found_neighbor = true
			break
	if not found_neighbor:
		_failures.append("could not find a walkable neighbor of the spawn tile to test navigation")
		return
	var neighbor_global := map.tile_to_global_position(neighbor)
	var projected: Variant = map.project_runtime_walkable_global(neighbor_global, 3)
	_log("NAVIGATION spawn=%s neighbor=%s neighbor_global=%s projected=%s" % [str(spawn_tile), str(neighbor), str(neighbor_global), str(projected)])
	_expect(projected is Vector2 and projected != Vector2.INF, "walkable projection for neighbor %s did not resolve" % str(neighbor))
	if projected is Vector2:
		_expect(
			(projected as Vector2).is_equal_approx(neighbor_global),
			"walkable projection for an already-walkable neighbor must return its own canonical position, got %s expected %s" % [str(projected), str(neighbor_global)]
		)


# 12. SHADOW
func _check_shadow_system(map: ProcGenTilemap) -> void:
	var shadow_overlay := map.nav_region.get_node_or_null("ShadowOverlay")
	_expect(shadow_overlay != null, "ShadowOverlay node missing")
	if shadow_overlay == null:
		return
	shadow_overlay.call("_update_tile_size")
	var tile_size: Vector2 = shadow_overlay.get("_tile_size")
	_log("SHADOW _tile_size = %s" % str(tile_size))
	_expect(tile_size.is_equal_approx(SPATIAL_CONTRACT.CELL_SIZE), "ShadowSystem must resolve a 32px local tile size, was %s" % str(tile_size))


# 13. THREADWAY
func _check_ash_bell_threadway(map: ProcGenTilemap) -> void:
	var source_tile_size: Vector2 = THREADWAY_CAUSEWAY_SCRIPT.SOURCE_TILE_SIZE
	var runtime_tile_size := map.get_runtime_tile_size()
	_log("THREADWAY source_tile_size=%s runtime_tile_size=%s" % [str(source_tile_size), str(runtime_tile_size)])
	_expect(source_tile_size.is_equal_approx(SPATIAL_CONTRACT.CELL_SIZE), "Threadway SOURCE_TILE_SIZE must be 32x32")
	_expect(runtime_tile_size.is_equal_approx(SPATIAL_CONTRACT.CELL_SIZE), "Threadway must observe a 32x32 runtime tile size")

	var causeway := THREADWAY_CAUSEWAY_SCRIPT.new()
	root.add_child(causeway)
	var floor_cells := map.debug_get_generated_floor_cells()
	if floor_cells.is_empty():
		_failures.append("no floor cells available to validate Threadway floor sprite scale")
		causeway.queue_free()
		return
	var sample_tile: Vector2i = floor_cells.keys()[0]
	causeway.configure(map, {"cells": [sample_tile], "tile_variants": {}}, false)
	var sprite := causeway.get_node_or_null("ThreadwayFloor_%d_%d" % [sample_tile.x, sample_tile.y])
	_expect(sprite != null, "Threadway did not create the expected persistent floor sprite")
	if sprite != null:
		_log("THREADWAY floor sprite scale = %s" % str(sprite.scale))
		_expect(sprite.scale.is_equal_approx(Vector2.ONE), "Threadway 32px floor sprite scale must be Vector2.ONE, was %s" % str(sprite.scale))
	causeway.queue_free()


# 14. CONTRACT WORLD LOADER
func _check_contract_world_loader(map: ProcGenTilemap) -> void:
	var loader := WORLD_LOADER_SCRIPT.new()
	var sample_tile := Vector2i(5, 5)
	var loader_world: Vector2 = loader.call("_tile_to_world", map, sample_tile)
	var canonical_world: Vector2 = map.tile_to_global_position(sample_tile)
	_log("CONTRACT_WORLD_LOADER tile=%s loader_world=%s canonical=%s" % [str(sample_tile), str(loader_world), str(canonical_world)])
	_expect(
		loader_world.is_equal_approx(canonical_world),
		"ContractWorldLoader tile-to-world must agree with the canonical 32px transform"
	)


# 15. STREAMING
func _check_streaming(map: ProcGenTilemap) -> void:
	var chunk_tiles := map.streaming_chunk_size_tiles
	_expect(chunk_tiles == 16, "streaming_chunk_size_tiles must remain 16 tiles, was %d" % chunk_tiles)
	var span := map.tile_to_global_position(Vector2i(chunk_tiles, 0)).distance_to(map.tile_to_global_position(Vector2i.ZERO))
	_log("STREAMING chunk_tiles=%d world_span=%.2f" % [chunk_tiles, span])
	_expect(is_equal_approx(span, 512.0), "one 16-tile streaming chunk must span 512 world px, was %.2f" % span)


# 16. NO SCALE COMPENSATION
func _check_no_scale_compensation(map: ProcGenTilemap) -> void:
	var offenders: Array[String] = []
	_walk_for_scale_compensation(map, offenders)
	_log("NO SCALE COMPENSATION offenders=%s" % str(offenders))
	_expect(offenders.is_empty(), "structural nodes still carry a compensatory 2x scale: %s" % str(offenders))


func _walk_for_scale_compensation(node: Node, offenders: Array[String]) -> void:
	if node is Node2D:
		var candidate := node as Node2D
		var is_structural := candidate is TileMapLayer or candidate is NavigationRegion2D or candidate.get_parent() == null or candidate.name in [
			"ProcGenMap", "MacroPresentationBack", "MacroPresentationGround", "MacroPresentationFront",
			"DepthBackdrop", "VoidCliffFace", "FoliageLayer", "PropLayer", "ShadowOverlay",
		]
		if is_structural and candidate.scale.is_equal_approx(Vector2(2.0, 2.0)):
			offenders.append("%s (%s)" % [candidate.get_path(), candidate.get_class()])
	for child in node.get_children():
		_walk_for_scale_compensation(child, offenders)


func _log(message: String) -> void:
	print("[procgen_spatial_normalization_smoke] %s" % message)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("procgen_spatial_normalization_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("procgen_spatial_normalization_smoke: FAIL (%d failures)" % _failures.size())
		quit(1)
