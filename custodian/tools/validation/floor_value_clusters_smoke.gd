extends SceneTree

const PROCGEN_TILEMAP := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const TILESET_PATH := "res://content/tiles/tilesets/procgen_world_tileset.tres"
const MAP_SIZE := Vector2i(40, 32)
const BASE_SOURCE := 10

var _failed := false


func _init() -> void:
	var tileset := load(TILESET_PATH) as TileSet
	_require(tileset != null, "Could not load active procgen TileSet.")
	if tileset == null:
		quit(1)
		return

	var tilemap := PROCGEN_TILEMAP.new()
	var floor := TileMapLayer.new()
	var walls := TileMapLayer.new()
	floor.tile_set = tileset
	walls.tile_set = tileset
	tilemap.floor_tilemap = floor
	tilemap.walls_tilemap = walls
	tilemap.floor_source_id = 10
	tilemap.alternate_floor_source_ids = [9]
	tilemap.full_grid_floor_source_ids = [9, 10]
	tilemap.floor_value_cluster_variant_source_ids = [9, 10]
	tilemap.floor_value_cluster_debug = true

	var gameplay_result := {
		"height_by_cell": {},
		"traversal_by_cell": {},
		"terrain_type_by_cell": {},
		"tile_by_cell": {},
		"ramp_dir_by_cell": {},
		"edge_profile_by_cell": {},
	}
	_reset_floor(tilemap, floor, walls)
	var floor_keys_before := _sorted_cells(tilemap._generated_floor_cells)
	var wall_keys_before := _sorted_cells(tilemap._generated_wall_cells)
	var gameplay_before := gameplay_result.duplicate(true)
	tilemap._apply_floor_value_clusters(gameplay_result, 424242)
	var first_summary := tilemap.get_last_floor_value_cluster_summary()
	var first_signature := _floor_signature(floor)

	_require(int(first_summary.get("clusters", 0)) == 12, "40x32 test map should create 12 clusters.")
	_require(int(first_summary.get("cells_changed", 0)) > 0, "Valid floor variants should change clustered cells.")
	_require(_sorted_cells(tilemap._generated_floor_cells) == floor_keys_before, "Floor membership changed.")
	_require(_sorted_cells(tilemap._generated_wall_cells) == wall_keys_before, "Wall membership changed.")
	_require(gameplay_result == gameplay_before, "Gameplay terrain metadata changed.")
	_require(floor.get_cell_source_id(Vector2i(2, 2)) == BASE_SOURCE, "Road/readability cell should be skipped.")
	_require(floor.get_cell_source_id(Vector2i(3, 2)) == BASE_SOURCE, "Objective cell should be skipped.")
	for tile in _readability_region_tiles().keys():
		_require(floor.get_cell_source_id(tile) == BASE_SOURCE, "Readability region %s should be skipped." % str(tilemap.get_region_type_at_tile(tile)))

	_reset_floor(tilemap, floor, walls)
	tilemap._apply_floor_value_clusters(gameplay_result, 424242)
	_require(_floor_signature(floor) == first_signature, "Same seed should produce identical floor cluster visuals.")

	_reset_floor(tilemap, floor, walls)
	tilemap._apply_floor_value_clusters(gameplay_result, 424243)
	_require(_floor_signature(floor) != first_signature, "Different seed should produce a different cluster signature.")

	_reset_floor(tilemap, floor, walls)
	tilemap.floor_value_cluster_variant_source_ids = [10]
	tilemap._apply_floor_value_clusters(gameplay_result, 424242)
	var skip_summary := tilemap.get_last_floor_value_cluster_summary()
	_require(int(skip_summary.get("cells_changed", -1)) == 0, "Single-source registry should safely skip.")
	_require(_all_floor_sources_are(floor, BASE_SOURCE), "Skip path should leave floor visuals unchanged.")

	tilemap.free()
	floor.free()
	walls.free()
	if _failed:
		print("[FloorValueClustersSmoke] FAILED")
		quit(1)
		return
	print("[FloorValueClustersSmoke] ok")
	quit(0)


func _reset_floor(tilemap: ProcGenTilemap, floor: TileMapLayer, walls: TileMapLayer) -> void:
	floor.clear()
	walls.clear()
	tilemap._generated_floor_cells.clear()
	tilemap._generated_wall_cells.clear()
	tilemap._region_tiles.clear()
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			floor.set_cell(cell, BASE_SOURCE, Vector2i.ZERO, 0)
			tilemap._generated_floor_cells[cell] = {
				"source_id": BASE_SOURCE,
				"atlas": Vector2i.ZERO,
				"alternative": 0,
			}
	tilemap._set_region_tile(Vector2i(2, 2), "main_road", "travel")
	tilemap._set_region_tile(Vector2i(3, 2), "ascent_objective", "objective")
	for tile in _readability_region_tiles().keys():
		tilemap._set_region_tile(tile, String(_readability_region_tiles()[tile]), "readability")


func _readability_region_tiles() -> Dictionary:
	return {
		Vector2i(4, 2): "spawn_clearing",
		Vector2i(5, 2): "soft_path",
		Vector2i(6, 2): "parking_zone",
		Vector2i(7, 2): "portal_plaza",
		Vector2i(8, 2): "compound_approach",
		Vector2i(9, 2): "compound_ingress",
		Vector2i(10, 2): "compound_connector_road",
		Vector2i(11, 2): "compound_connector_ramp",
		Vector2i(12, 2): "compound_connector_elevated_road",
		Vector2i(13, 2): "terrain_elevation_access",
		Vector2i(14, 2): "terrain_rescue_floor",
		Vector2i(15, 2): "faction_camp",
		Vector2i(16, 2): "story_room_floor",
	}


func _floor_signature(floor: TileMapLayer) -> String:
	var parts: Array[String] = []
	var cells := floor.get_used_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	for cell in cells:
		parts.append("%d,%d:%d:%s:%d" % [
			cell.x,
			cell.y,
			floor.get_cell_source_id(cell),
			str(floor.get_cell_atlas_coords(cell)),
			floor.get_cell_alternative_tile(cell),
		])
	return "|".join(parts)


func _sorted_cells(values: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in values:
		if cell is Vector2i:
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return cells


func _all_floor_sources_are(floor: TileMapLayer, source_id: int) -> bool:
	for cell in floor.get_used_cells():
		if floor.get_cell_source_id(cell) != source_id:
			return false
	return true


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[FloorValueClustersSmoke] " + message)
