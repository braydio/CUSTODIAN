extends SceneTree

const TerrainBallistics := preload("res://game/world/procgen/terrain/terrain_ballistics.gd")
const TerrainBuilder := preload("res://game/world/procgen/terrain/terrain_builder.gd")

var _failed := false


func _init() -> void:
	_test_tile_trace()
	_test_same_height_clear()
	_test_hard_wall()
	_test_directional_ledge()
	_test_ramp_exception()
	_test_drop_and_bridge()
	_test_supercover_diagonal()
	_test_terrain_builder_platform()

	if _failed:
		print("[TerrainBallisticsSmoke] failed")
		quit(1)
		return
	print("[TerrainBallisticsSmoke] ok")
	quit(0)


func _test_tile_trace() -> void:
	_require(TerrainBallistics.trace_tiles(Vector2i(2, 2), Vector2i(2, 2)) == [Vector2i(2, 2)], "Same-tile trace should contain one tile.")
	_require(TerrainBallistics.trace_tiles(Vector2i.ZERO, Vector2i(3, 0)).size() == 4, "Horizontal trace should include both endpoints.")
	_require(TerrainBallistics.trace_tiles(Vector2i.ZERO, Vector2i(0, 3)).size() == 4, "Vertical trace should include both endpoints.")
	_require(TerrainBallistics.trace_tiles(Vector2i.ZERO, Vector2i(3, 3)) == TerrainBallistics.trace_tiles(Vector2i.ZERO, Vector2i(3, 3)), "Tile trace should be deterministic.")


func _test_same_height_clear() -> void:
	var context := _line_context(5)
	var result := TerrainBallistics.trace_projectile_tiles(context, _center(Vector2i.ZERO), _center(Vector2i(4, 0)))
	_require(bool(result.get("allowed", false)), "Same-height clear shot should be allowed.")


func _test_hard_wall() -> void:
	var context := _line_context(5)
	context["traversal_by_cell"][Vector2i(2, 0)] = "blocked"
	context["terrain_type_by_cell"][Vector2i(2, 0)] = "mountain_wall"
	var result := TerrainBallistics.trace_projectile_tiles(context, _center(Vector2i.ZERO), _center(Vector2i(4, 0)))
	_require(not bool(result.get("allowed", true)), "Hard wall should block.")
	_require(String(result.get("blocked_by", "")) == TerrainBallistics.EDGE_WALL_HIGH, "Hard wall should report wall_high.")


func _test_directional_ledge() -> void:
	var high := Vector2i(0, 0)
	var low := Vector2i(1, 0)
	var context := {
		"height_by_cell": {high: 1, low: 0},
		"traversal_by_cell": {high: "ledge", low: "walkable"},
		"edge_profile_by_cell": {
			high: {"east": TerrainBallistics.EDGE_LEDGE_FIRE_OVER},
			low: {"west": TerrainBallistics.EDGE_LEDGE_FIRE_OVER},
		},
		"tile_size": 1,
	}
	var down_result := TerrainBallistics.trace_projectile_tiles(context, _center(high), _center(low))
	var up_result := TerrainBallistics.trace_projectile_tiles(context, _center(low), _center(high))
	_require(bool(down_result.get("allowed", false)), "High-to-low ledge shot should be allowed.")
	_require(not bool(up_result.get("allowed", true)), "Low-to-high ledge shot should be blocked.")
	_require(String(up_result.get("blocked_by", "")) == TerrainBallistics.EDGE_LEDGE_FIRE_OVER, "Low-to-high ledge should identify ledge_fire_over.")


func _test_ramp_exception() -> void:
	var low := Vector2i(0, 0)
	var high := Vector2i(1, 0)
	var context := {
		"height_by_cell": {low: 0, high: 1},
		"traversal_by_cell": {low: "walkable", high: "ramp"},
		"edge_profile_by_cell": {low: {"east": TerrainBallistics.EDGE_RAMP}},
		"tile_size": 1,
	}
	var result := TerrainBallistics.trace_projectile_tiles(context, _center(low), _center(high))
	_require(bool(result.get("allowed", false)), "Low-to-high ramp shot should be allowed.")


func _test_drop_and_bridge() -> void:
	var context := _line_context(4)
	context["traversal_by_cell"][Vector2i(2, 0)] = "drop"
	var blocked := TerrainBallistics.trace_projectile_tiles(context, _center(Vector2i.ZERO), _center(Vector2i(3, 0)))
	_require(not bool(blocked.get("allowed", true)), "Drop/chasm should block.")
	_require(String(blocked.get("blocked_by", "")) == TerrainBallistics.EDGE_DROP, "Drop should report drop.")

	context["tile_by_cell"][Vector2i(2, 0)] = "bridge_deck"
	var bridged := TerrainBallistics.trace_projectile_tiles(context, _center(Vector2i.ZERO), _center(Vector2i(3, 0)))
	_require(bool(bridged.get("allowed", false)), "Explicit bridge should make a drop boundary passable.")


func _test_supercover_diagonal() -> void:
	var context := {
		"height_by_cell": {},
		"traversal_by_cell": {Vector2i(2, 2): "blocked"},
		"terrain_type_by_cell": {Vector2i(2, 2): "hard_wall"},
		"tile_size": 1,
	}
	var result := TerrainBallistics.trace_projectile_tiles(context, _center(Vector2i.ZERO), _center(Vector2i(4, 4)))
	_require(not bool(result.get("allowed", true)), "Diagonal trace should not skip a crossed hard wall.")


func _test_terrain_builder_platform() -> void:
	var map_rect := Rect2i(Vector2i.ZERO, Vector2i(48, 36))
	var floor_cells: Array[Vector2i] = []
	for x in range(map_rect.position.x, map_rect.end.x):
		for y in range(map_rect.position.y, map_rect.end.y):
			floor_cells.append(Vector2i(x, y))
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var builder := TerrainBuilder.new()
	var result: Dictionary = builder.build_terrain(map_rect, rng, {
		"seed": 424242,
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"start_cell": Vector2i(2, 2),
		"required_cells": [Vector2i(2, 2)],
		"enable_industrial_platform": true,
		"enable_mountain_boundary": false,
	})
	var edge_profiles: Dictionary = result.get("edge_profile_by_cell", {})
	_require(not edge_profiles.is_empty(), "TerrainBuilder should export edge_profile_by_cell.")
	var boundary := _find_platform_boundary(result)
	_require(not boundary.is_empty(), "Deterministic platform should expose an elevated ledge boundary.")
	if boundary.is_empty():
		return

	var high: Vector2i = boundary["high"]
	var low: Vector2i = boundary["low"]
	_require(not builder._can_move_between_in_result(result, low, high), "Movement should still reject entering a ledge.")
	var context := {
		"height_by_cell": result.get("height_by_cell", {}),
		"traversal_by_cell": result.get("traversal_by_cell", {}),
		"terrain_type_by_cell": result.get("terrain_type_by_cell", {}),
		"tile_by_cell": result.get("tile_by_cell", {}),
		"edge_profile_by_cell": edge_profiles,
		"tile_size": 1,
	}
	var down_result := TerrainBallistics.trace_projectile_tiles(context, _center(high), _center(low))
	var up_result := TerrainBallistics.trace_projectile_tiles(context, _center(low), _center(high))
	_require(bool(down_result.get("allowed", false)), "TerrainBuilder platform should allow high-to-low fire.")
	_require(not bool(up_result.get("allowed", true)), "TerrainBuilder platform should block low-to-high fire.")
	var summary: Dictionary = result.get("debug_summary", {})
	_require(int(summary.get("ledge_fire_over_edge_count", 0)) > 0, "TerrainBuilder summary should count ledge_fire_over edges.")


func _find_platform_boundary(result: Dictionary) -> Dictionary:
	var height_by_cell: Dictionary = result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var edge_profiles: Dictionary = result.get("edge_profile_by_cell", {})
	var directions := {
		"north": Vector2i.UP,
		"south": Vector2i.DOWN,
		"east": Vector2i.RIGHT,
		"west": Vector2i.LEFT,
	}
	for high_variant in traversal_by_cell.keys():
		if not (high_variant is Vector2i):
			continue
		var high := high_variant as Vector2i
		if String(traversal_by_cell.get(high, "")) != TerrainBuilder.TRAVERSAL_LEDGE:
			continue
		for direction_name in directions:
			var low: Vector2i = high + directions[direction_name]
			if int(height_by_cell.get(high, 0)) <= int(height_by_cell.get(low, 0)):
				continue
			var profiles: Dictionary = edge_profiles.get(high, {})
			if String(profiles.get(direction_name, "")) == TerrainBallistics.EDGE_LEDGE_FIRE_OVER:
				return {"high": high, "low": low}
	return {}


func _line_context(length: int) -> Dictionary:
	var heights := {}
	var traversals := {}
	var terrain_types := {}
	var tiles := {}
	for x in range(length):
		var cell := Vector2i(x, 0)
		heights[cell] = 0
		traversals[cell] = "walkable"
		terrain_types[cell] = "ground"
	return {
		"height_by_cell": heights,
		"traversal_by_cell": traversals,
		"terrain_type_by_cell": terrain_types,
		"tile_by_cell": tiles,
		"tile_size": 1,
	}


func _center(tile: Vector2i) -> Vector2:
	return Vector2(tile) + Vector2(0.5, 0.5)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerrainBallisticsSmoke] " + message)
