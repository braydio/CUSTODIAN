extends Node
class_name ElevationMap

const DEFAULT_HEIGHT := 0

const TRAVERSAL_WALKABLE := "walkable"
const TRAVERSAL_BLOCKED := "blocked"
const TRAVERSAL_LEDGE := "ledge"
const TRAVERSAL_RAMP := "ramp"
const TRAVERSAL_STAIR := "stair"
const TRAVERSAL_DROP := "drop"
const TRAVERSAL_FLAT := TRAVERSAL_WALKABLE
const TRAVERSAL_EDGE := TRAVERSAL_LEDGE

const DIRECTION_NONE := "none"
const DIRECTION_NORTH := "north"
const DIRECTION_SOUTH := "south"
const DIRECTION_EAST := "east"
const DIRECTION_WEST := "west"

var _cells: Dictionary = {}


func clear() -> void:
	_cells.clear()


func set_cell(tile: Vector2i, height: int = DEFAULT_HEIGHT, traversal_type: String = TRAVERSAL_WALKABLE, direction: String = DIRECTION_NONE) -> void:
	_cells[tile] = {
		"height": height,
		"traversal_type": traversal_type,
		"direction": direction,
	}


func erase_cell(tile: Vector2i) -> void:
	_cells.erase(tile)


func has_cell(tile: Vector2i) -> bool:
	return _cells.has(tile)


func get_cell_data(tile: Vector2i) -> Dictionary:
	var data: Variant = _cells.get(tile, {})
	if data is Dictionary:
		return (data as Dictionary).duplicate(true)
	return {
		"height": DEFAULT_HEIGHT,
		"traversal_type": TRAVERSAL_WALKABLE,
		"direction": DIRECTION_NONE,
	}


func get_height(tile: Vector2i) -> int:
	return int(get_cell_data(tile).get("height", DEFAULT_HEIGHT))


func get_traversal_type(tile: Vector2i) -> String:
	return String(get_cell_data(tile).get("traversal_type", TRAVERSAL_WALKABLE))


func get_direction(tile: Vector2i) -> String:
	return String(get_cell_data(tile).get("direction", DIRECTION_NONE))


func is_blocked(tile: Vector2i) -> bool:
	var traversal := get_traversal_type(tile)
	return traversal == TRAVERSAL_LEDGE or traversal == TRAVERSAL_EDGE or traversal == TRAVERSAL_BLOCKED or traversal == TRAVERSAL_DROP


func is_valid_spawn_cell(tile: Vector2i) -> bool:
	var traversal := get_traversal_type(tile)
	return traversal == TRAVERSAL_WALKABLE or traversal == TRAVERSAL_FLAT or traversal == TRAVERSAL_RAMP or traversal == TRAVERSAL_STAIR


func can_traverse(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	var delta := to_tile - from_tile
	if abs(delta.x) + abs(delta.y) != 1:
		return false
	if is_blocked(from_tile) or is_blocked(to_tile):
		return false
	var from_height := get_height(from_tile)
	var to_height := get_height(to_tile)
	var height_delta := to_height - from_height
	if height_delta == 0:
		return true
	if abs(height_delta) > 1:
		return false
	return _transition_allows(from_tile, to_tile, delta)


func can_move_between(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	return can_traverse(from_tile, to_tile)


func stamp_flat_rect(rect: Rect2i, height: int = DEFAULT_HEIGHT) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			set_cell(Vector2i(x, y), height, TRAVERSAL_WALKABLE)


func stamp_platform(rect: Rect2i, height: int = 1, ramp_tile: Vector2i = Vector2i.ZERO, ramp_direction: String = DIRECTION_SOUTH) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			var is_edge := x == rect.position.x or y == rect.position.y or x == rect.end.x - 1 or y == rect.end.y - 1
			set_cell(tile, height, TRAVERSAL_LEDGE if is_edge else TRAVERSAL_WALKABLE)
	if rect.has_point(ramp_tile):
		set_cell(ramp_tile, height, TRAVERSAL_RAMP, ramp_direction)
		var approach := ramp_tile + _direction_to_delta(ramp_direction)
		if not rect.has_point(approach):
			set_cell(approach, height - 1, TRAVERSAL_WALKABLE)


func apply_build_result(build_result: Dictionary) -> void:
	clear()
	var height_by_cell: Dictionary = build_result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = build_result.get("traversal_by_cell", {})
	var ramp_dir_by_cell: Dictionary = build_result.get("ramp_dir_by_cell", {})
	for cell_variant in height_by_cell.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		set_cell(
			cell,
			int(height_by_cell.get(cell, DEFAULT_HEIGHT)),
			String(traversal_by_cell.get(cell, TRAVERSAL_WALKABLE)),
			String(ramp_dir_by_cell.get(cell, DIRECTION_NONE))
		)


func get_cells() -> Dictionary:
	return _cells.duplicate(true)


func get_serialized_cells() -> Array[Dictionary]:
	var serialized: Array[Dictionary] = []
	for tile in _cells.keys():
		if not tile is Vector2i:
			continue
		var data := get_cell_data(tile)
		serialized.append({
			"tile": tile,
			"height": int(data.get("height", DEFAULT_HEIGHT)),
			"traversal_type": String(data.get("traversal_type", TRAVERSAL_FLAT)),
			"direction": String(data.get("direction", DIRECTION_NONE)),
		})
	return serialized


func _transition_allows(from_tile: Vector2i, to_tile: Vector2i, delta: Vector2i) -> bool:
	var from_type := get_traversal_type(from_tile)
	var to_type := get_traversal_type(to_tile)
	if from_type == TRAVERSAL_STAIR or to_type == TRAVERSAL_STAIR:
		return true
	if from_type == TRAVERSAL_RAMP and _direction_to_delta(get_direction(from_tile)) == delta:
		return true
	if to_type == TRAVERSAL_RAMP and _direction_to_delta(get_direction(to_tile)) == -delta:
		return true
	return false


func _direction_to_delta(direction: String) -> Vector2i:
	match direction:
		DIRECTION_NORTH:
			return Vector2i.UP
		DIRECTION_SOUTH:
			return Vector2i.DOWN
		DIRECTION_EAST:
			return Vector2i.RIGHT
		DIRECTION_WEST:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO
