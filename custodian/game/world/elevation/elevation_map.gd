extends Node
class_name ElevationMap

const DEFAULT_HEIGHT := 0
const MAX_STEP_HEIGHT := 1
const MAX_DROP_HEIGHT := 1

const KEY_HEIGHT := "height"
const KEY_TRAVERSAL_TYPE := "traversal_type"
const KEY_DIRECTION := "direction"

const TRAVERSAL_WALKABLE := "walkable"
const TRAVERSAL_BLOCKED := "blocked"
const TRAVERSAL_LEDGE := "ledge"
const TRAVERSAL_RAMP := "ramp"
const TRAVERSAL_STAIR := "stair"
const TRAVERSAL_DROP := "drop"

# Backwards-compatible aliases.
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


func set_cell(
	tile: Vector2i,
	height: int = DEFAULT_HEIGHT,
	traversal_type: String = TRAVERSAL_WALKABLE,
	direction: String = DIRECTION_NONE
) -> void:
	_cells[tile] = {
		KEY_HEIGHT: height,
		KEY_TRAVERSAL_TYPE: _sanitize_traversal_type(traversal_type),
		KEY_DIRECTION: _sanitize_direction(direction),
	}


func erase_cell(tile: Vector2i) -> void:
	_cells.erase(tile)


func has_cell(tile: Vector2i) -> bool:
	return _cells.has(tile)


func get_cell_data(tile: Vector2i) -> Dictionary:
	if not _cells.has(tile):
		return _default_missing_cell_data()

	var data: Variant = _cells.get(tile)
	if data is Dictionary:
		var dict := (data as Dictionary)
		return {
			KEY_HEIGHT: int(dict.get(KEY_HEIGHT, DEFAULT_HEIGHT)),
			KEY_TRAVERSAL_TYPE: _sanitize_traversal_type(str(dict.get(KEY_TRAVERSAL_TYPE, TRAVERSAL_WALKABLE))),
			KEY_DIRECTION: _sanitize_direction(str(dict.get(KEY_DIRECTION, DIRECTION_NONE))),
		}

	return _default_missing_cell_data()


func get_height(tile: Vector2i) -> int:
	return int(get_cell_data(tile).get(KEY_HEIGHT, DEFAULT_HEIGHT))


func get_traversal_type(tile: Vector2i) -> String:
	return str(get_cell_data(tile).get(KEY_TRAVERSAL_TYPE, TRAVERSAL_BLOCKED))


func get_direction(tile: Vector2i) -> String:
	return str(get_cell_data(tile).get(KEY_DIRECTION, DIRECTION_NONE))


func is_blocked(tile: Vector2i) -> bool:
	if not has_cell(tile):
		return true

	var traversal := get_traversal_type(tile)
	return _is_hard_blocked_traversal(traversal)


func is_valid_spawn_cell(tile: Vector2i) -> bool:
	if not has_cell(tile):
		return false

	var traversal := get_traversal_type(tile)
	return (
		traversal == TRAVERSAL_WALKABLE
		or traversal == TRAVERSAL_RAMP
		or traversal == TRAVERSAL_STAIR
	)


func can_traverse(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	if not has_cell(from_tile) or not has_cell(to_tile):
		return false

	var delta := to_tile - from_tile
	if abs(delta.x) + abs(delta.y) != 1:
		return false

	var from_type := get_traversal_type(from_tile)
	var to_type := get_traversal_type(to_tile)

	if _is_hard_blocked_traversal(from_type) or _is_hard_blocked_traversal(to_type):
		return false

	var from_height := get_height(from_tile)
	var to_height := get_height(to_tile)
	var height_delta := to_height - from_height

	# Same-height movement is normal, except you cannot step into a drop marker
	# as if it were ordinary floor.
	if height_delta == 0:
		return to_type != TRAVERSAL_DROP

	# Drops are one-way descent markers.
	if from_type == TRAVERSAL_DROP:
		return _drop_allows(from_tile, to_tile, delta, height_delta)

	# Do not climb into a drop marker.
	if to_type == TRAVERSAL_DROP:
		return false

	if abs(height_delta) > MAX_STEP_HEIGHT:
		return false

	return _transition_allows(from_tile, to_tile, delta)


func can_move_between(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	return can_traverse(from_tile, to_tile)


func stamp_flat_rect(rect: Rect2i, height: int = DEFAULT_HEIGHT) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			set_cell(Vector2i(x, y), height, TRAVERSAL_WALKABLE)


func stamp_platform(
	rect: Rect2i,
	height: int = 1,
	ramp_tile: Vector2i = Vector2i.ZERO,
	ramp_direction: String = DIRECTION_SOUTH
) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			var is_edge := (
				x == rect.position.x
				or y == rect.position.y
				or x == rect.end.x - 1
				or y == rect.end.y - 1
			)

			set_cell(
				tile,
				height,
				TRAVERSAL_LEDGE if is_edge else TRAVERSAL_WALKABLE
			)

	if rect.has_point(ramp_tile):
		var clean_ramp_direction := _sanitize_direction(ramp_direction)
		set_cell(ramp_tile, height, TRAVERSAL_RAMP, clean_ramp_direction)

		# Ramp direction means the direction you descend off the platform.
		var approach := ramp_tile + _direction_to_delta(clean_ramp_direction)
		if not rect.has_point(approach):
			set_cell(approach, height - 1, TRAVERSAL_WALKABLE)


func apply_build_result(build_result: Dictionary) -> void:
	clear()

	var height_by_cell: Dictionary = build_result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = build_result.get("traversal_by_cell", {})
	var ramp_dir_by_cell: Dictionary = build_result.get("ramp_dir_by_cell", {})

	for cell_variant in height_by_cell.keys():
		if not (cell_variant is Vector2i):
			continue

		var cell := cell_variant as Vector2i
		set_cell(
			cell,
			int(height_by_cell.get(cell, DEFAULT_HEIGHT)),
			str(traversal_by_cell.get(cell, TRAVERSAL_WALKABLE)),
			str(ramp_dir_by_cell.get(cell, DIRECTION_NONE))
		)


func get_cells() -> Dictionary:
	return _cells.duplicate(true)


func get_serialized_cells() -> Array[Dictionary]:
	var serialized: Array[Dictionary] = []

	for tile_variant in _cells.keys():
		if not (tile_variant is Vector2i):
			continue

		var tile := tile_variant as Vector2i
		var data := get_cell_data(tile)

		serialized.append({
			"tile": tile,
			KEY_HEIGHT: int(data.get(KEY_HEIGHT, DEFAULT_HEIGHT)),
			KEY_TRAVERSAL_TYPE: str(data.get(KEY_TRAVERSAL_TYPE, TRAVERSAL_WALKABLE)),
			KEY_DIRECTION: str(data.get(KEY_DIRECTION, DIRECTION_NONE)),
		})

	return serialized


func _transition_allows(from_tile: Vector2i, to_tile: Vector2i, delta: Vector2i) -> bool:
	var from_type := get_traversal_type(from_tile)
	var to_type := get_traversal_type(to_tile)

	if from_type == TRAVERSAL_STAIR or to_type == TRAVERSAL_STAIR:
		return true

	# Ramp direction points downhill/off-platform.
	if from_type == TRAVERSAL_RAMP:
		return _direction_to_delta(get_direction(from_tile)) == delta

	if to_type == TRAVERSAL_RAMP:
		return _direction_to_delta(get_direction(to_tile)) == -delta

	return false


func _drop_allows(
	from_tile: Vector2i,
	_to_tile: Vector2i,
	delta: Vector2i,
	height_delta: int
) -> bool:
	if height_delta >= 0:
		return false

	if abs(height_delta) > MAX_DROP_HEIGHT:
		return false

	return _direction_to_delta(get_direction(from_tile)) == delta


func _is_hard_blocked_traversal(traversal_type: String) -> bool:
	return (
		traversal_type == TRAVERSAL_BLOCKED
		or traversal_type == TRAVERSAL_LEDGE
		or traversal_type == TRAVERSAL_EDGE
	)


func _default_missing_cell_data() -> Dictionary:
	return {
		KEY_HEIGHT: DEFAULT_HEIGHT,
		KEY_TRAVERSAL_TYPE: TRAVERSAL_BLOCKED,
		KEY_DIRECTION: DIRECTION_NONE,
	}


func _sanitize_traversal_type(traversal_type: String) -> String:
	match traversal_type:
		TRAVERSAL_WALKABLE, TRAVERSAL_BLOCKED, TRAVERSAL_LEDGE, TRAVERSAL_RAMP, TRAVERSAL_STAIR, TRAVERSAL_DROP:
			return traversal_type
		TRAVERSAL_FLAT:
			return TRAVERSAL_WALKABLE
		TRAVERSAL_EDGE:
			return TRAVERSAL_LEDGE
		_:
			push_warning("Unknown traversal type '%s'; treating as blocked." % traversal_type)
			return TRAVERSAL_BLOCKED


func _sanitize_direction(direction: String) -> String:
	match direction:
		DIRECTION_NONE, DIRECTION_NORTH, DIRECTION_SOUTH, DIRECTION_EAST, DIRECTION_WEST:
			return direction
		_:
			push_warning("Unknown elevation direction '%s'; using none." % direction)
			return DIRECTION_NONE


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
