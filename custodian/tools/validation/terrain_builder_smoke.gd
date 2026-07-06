extends SceneTree

const TerrainBuilderScript := preload("res://game/world/procgen/terrain/terrain_builder.gd")
const ElevationMapScript := preload("res://game/world/elevation/elevation_map.gd")
const TILESET_PATH := "res://content/tiles/tilesets/procgen_world_tileset.tres"
const REQUIRED_TERRAIN_SOURCE_IDS := {
	32: "ground_flat_32",
	33: "elevated_floor_32",
	34: "elevation_edge_north_32",
	35: "elevation_edge_south_32",
	36: "elevation_edge_east_32",
	37: "elevation_edge_west_32",
	38: "ramp_north_32",
	39: "ramp_south_32",
	40: "ramp_east_32",
	41: "ramp_west_32",
	42: "cliff_shadow_32",
	43: "stair_metal_32",
	44: "rock_ground_flat_32",
	45: "rock_plateau_raised_32",
	46: "cliff_edge_north_32",
	47: "cliff_edge_south_32",
	48: "cliff_edge_east_32",
	49: "cliff_edge_west_32",
	50: "cliff_outer_nw_32",
	51: "cliff_outer_ne_32",
	52: "cliff_outer_sw_32",
	53: "cliff_outer_se_32",
	54: "cliff_inner_nw_32",
	55: "cliff_inner_ne_32",
	56: "cliff_inner_sw_32",
	57: "cliff_inner_se_32",
	58: "cliff_chasm_drop_32",
	59: "mountain_wall_impassable_32",
}

var _failed := false


func _init() -> void:
	var map_rect := Rect2i(Vector2i.ZERO, Vector2i(48, 36))
	var floor_cells: Array[Vector2i] = []
	for x in range(map_rect.position.x, map_rect.end.x):
		for y in range(map_rect.position.y, map_rect.end.y):
			floor_cells.append(Vector2i(x, y))

	var required_cells: Array[Vector2i] = [
		Vector2i(8, 8),
		Vector2i(40, 28),
		Vector2i(24, 18),
	]
	var context := {
		"seed": 424242,
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"start_cell": required_cells[0],
		"required_cells": required_cells,
		"enable_industrial_platform": true,
		"enable_mountain_boundary": true,
	}

	var first := _build_with_seed(map_rect, 424242, context)
	var second := _build_with_seed(map_rect, 424242, context)
	_require(_signature(first) == _signature(second), "TerrainBuilder should be deterministic for the same seed and context.")
	_require(bool(first.get("connectivity", {}).get("ok", false)), "Primary terrain result should be connected.")
	var summary: Dictionary = first.get("debug_summary", {})
	_require(int(summary.get("required_cell_count", 0)) == required_cells.size(), "Required-cell count should match smoke input.")
	_require(int(summary.get("missing_required_count", -1)) == 0, "No required cells should be missing in the primary terrain result.")
	_require(String(summary.get("generation_mode", "")) == "FINAL_VISUAL", "TerrainBuilder smoke should run final visual mode.")
	_require(_has_accessible_platform(first), "Elevated terrain should remain accessible when generated.")
	_require(_no_invalid_spawn_cells(first), "Blocked/drop/ledge terrain cells should not be valid spawn cells.")
	_assert_baseline_visual_noop()
	_assert_disconnected_baseline_is_rescued_before_features()
	_test_directional_ramp_validation()

	var elevation_map := ElevationMapScript.new()
	elevation_map.apply_build_result(first)
	for cell in first.get("blocked_cells", {}).keys():
		_require(not elevation_map.is_valid_spawn_cell(cell), "ElevationMap should reject blocked spawn cell %s." % [str(cell)])
	_assert_tileset_sources()

	if _failed:
		print("[TerrainBuilderSmoke] failed")
		quit(1)
		return

	print("[TerrainBuilderSmoke] ok signature_hash=%s summary=%s" % [str(_signature(first).hash()), str(first.get("debug_summary", {}))])
	quit(0)


func _build_with_seed(map_rect: Rect2i, seed: int, context: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var builder := TerrainBuilderScript.new()
	return builder.build_terrain(map_rect, rng, context)


func _assert_baseline_visual_noop() -> void:
	var map_rect := Rect2i(Vector2i.ZERO, Vector2i(4, 4))
	var floor_cell := Vector2i(1, 1)
	var blocked_cell := Vector2i(2, 2)
	var result := _build_with_seed(map_rect, 101, {
		"seed": 101,
		"floor_cells": [floor_cell],
		"blocked_cells": [blocked_cell],
		"start_cell": floor_cell,
		"required_cells": [floor_cell],
		"enable_industrial_platform": false,
		"enable_mountain_boundary": false,
	})
	var tile_by_cell: Dictionary = result.get("tile_by_cell", {})
	_require(String(tile_by_cell.get(floor_cell, "__missing__")) == TerrainBuilderScript.NO_VISUAL_TILE, "Baseline floor should not receive a visual terrain tile.")
	_require(String(tile_by_cell.get(blocked_cell, "__missing__")) == TerrainBuilderScript.NO_VISUAL_TILE, "Baseline blocked cell should not receive a visual terrain tile.")
	_require(String(result.get("traversal_by_cell", {}).get(floor_cell, "")) == TerrainBuilderScript.TRAVERSAL_WALKABLE, "Baseline floor traversal should stay walkable.")
	_require(String(result.get("traversal_by_cell", {}).get(blocked_cell, "")) == TerrainBuilderScript.TRAVERSAL_BLOCKED, "Baseline blocked traversal should stay blocked.")


func _assert_disconnected_baseline_is_rescued_before_features() -> void:
	var map_rect := Rect2i(Vector2i.ZERO, Vector2i(36, 20))
	var floor_cells: Array[Vector2i] = []
	for x in range(2, 11):
		for y in range(2, 11):
			floor_cells.append(Vector2i(x, y))
	for x in range(24, 33):
		for y in range(2, 11):
			floor_cells.append(Vector2i(x, y))
	var required_cells: Array[Vector2i] = [
		Vector2i(4, 4),
		Vector2i(28, 4),
	]
	var result := _build_with_seed(map_rect, 303, {
		"seed": 303,
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"start_cell": required_cells[0],
		"required_cells": required_cells,
		"worldgen_reserved_regions": [
			{
				"rect": Rect2i(Vector2i(5, 5), Vector2i(3, 3)),
				"runtime_height": TerrainBuilderScript.HEIGHT_ELEVATED,
				"kind": "test_reserved_region",
			},
		],
		"enable_industrial_platform": false,
		"enable_mountain_boundary": false,
	})
	var summary: Dictionary = result.get("debug_summary", {})
	_require(bool(summary.get("connectivity_ok", false)), "Disconnected baseline should be rescued before terrain features.")
	_require(int(summary.get("baseline_rescue_carved_cells", 0)) > 0, "Expected baseline rescue to be counted separately.")
	_require(int(summary.get("rescue_carved_cells", 0)) >= int(summary.get("baseline_rescue_carved_cells", 0)), "Total rescue should include baseline rescue.")
	_require(int(summary.get("regions", 0)) > 0, "Feature regions should survive after baseline connectivity rescue.")


func _test_directional_ramp_validation() -> void:
	var builder := TerrainBuilderScript.new()
	var ground := Vector2i(0, 0)
	var ramp := Vector2i(1, 0)
	var valid_result := {
		"height_by_cell": {
			ground: TerrainBuilderScript.HEIGHT_GROUND,
			ramp: TerrainBuilderScript.HEIGHT_ELEVATED,
		},
		"traversal_by_cell": {
			ground: TerrainBuilderScript.TRAVERSAL_WALKABLE,
			ramp: TerrainBuilderScript.TRAVERSAL_RAMP,
		},
		"ramp_dir_by_cell": {
			ramp: TerrainBuilderScript.DIRECTION_WEST,
		},
	}

	_require(builder._can_move_between_in_result(valid_result, ground, ramp), "Destination ramp should allow approach from its ramp-facing side.")

	var invalid_result := valid_result.duplicate(true)
	invalid_result["ramp_dir_by_cell"] = {
		ramp: TerrainBuilderScript.DIRECTION_EAST,
	}
	_require(not builder._can_move_between_in_result(invalid_result, ground, ramp), "Destination ramp should reject approach from the wrong side.")

	var stair_result := valid_result.duplicate(true)
	stair_result["traversal_by_cell"] = {
		ground: TerrainBuilderScript.TRAVERSAL_WALKABLE,
		ramp: TerrainBuilderScript.TRAVERSAL_STAIR,
	}
	stair_result["ramp_dir_by_cell"] = {}
	_require(builder._can_move_between_in_result(stair_result, ground, ramp), "Stair should allow one-level transition without directional ramp rule.")


func _signature(result: Dictionary) -> String:
	var parts: Array[String] = []
	var height_by_cell: Dictionary = result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var tile_by_cell: Dictionary = result.get("tile_by_cell", {})
	var cells: Array[Vector2i] = []
	for cell in height_by_cell.keys():
		if cell is Vector2i:
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)
	for cell in cells:
		parts.append("%s,%s:%s:%s:%s" % [
			cell.x,
			cell.y,
			str(height_by_cell.get(cell, 0)),
			str(traversal_by_cell.get(cell, "")),
			str(tile_by_cell.get(cell, "")),
		])
	return "|".join(parts)


func _has_accessible_platform(result: Dictionary) -> bool:
	var height_by_cell: Dictionary = result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var elevated_count := 0
	var ramp_count := 0
	for cell in height_by_cell.keys():
		if int(height_by_cell.get(cell, 0)) > 0:
			elevated_count += 1
		var traversal := String(traversal_by_cell.get(cell, ""))
		if traversal == TerrainBuilderScript.TRAVERSAL_RAMP or traversal == TerrainBuilderScript.TRAVERSAL_STAIR:
			ramp_count += 1
	return elevated_count == 0 or ramp_count > 0


func _no_invalid_spawn_cells(result: Dictionary) -> bool:
	var builder := TerrainBuilderScript.new()
	builder._last_result = result
	for cell in result.get("height_by_cell", {}).keys():
		var traversal := builder.get_traversal(cell)
		if traversal == TerrainBuilderScript.TRAVERSAL_BLOCKED or traversal == TerrainBuilderScript.TRAVERSAL_LEDGE or traversal == TerrainBuilderScript.TRAVERSAL_DROP:
			if builder.is_valid_spawn_cell(cell):
				return false
	return true


func _assert_tileset_sources() -> void:
	var tileset := load(TILESET_PATH) as TileSet
	_require(tileset != null, "Could not load active procgen TileSet at %s." % [TILESET_PATH])
	if tileset == null:
		return
	for source_id in REQUIRED_TERRAIN_SOURCE_IDS.keys():
		var label := String(REQUIRED_TERRAIN_SOURCE_IDS[source_id])
		if not tileset.has_source(int(source_id)):
			_require(false, "Missing terrain TileSet source id %d for %s." % [int(source_id), label])
			continue
		var source := tileset.get_source(int(source_id)) as TileSetAtlasSource
		_require(source != null, "Terrain TileSet source id %d for %s is not an atlas source." % [int(source_id), label])
		if source == null:
			continue
		_require(source.has_tile(Vector2i.ZERO), "Terrain TileSet source id %d for %s has no tile at (0, 0)." % [int(source_id), label])
		_require(source.texture != null, "Terrain TileSet source id %d for %s has no texture." % [int(source_id), label])


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerrainBuilderSmoke] " + message)
