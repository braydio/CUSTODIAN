class_name AuthoredNavigationProvider2D
extends Node

var grid: AuthoredBlockoutGrid2D
var navigation_revision := 0
var _astar := AStar2D.new()
var _blocked_by_id: Dictionary = {}
var _walkable: Dictionary = {}
var _dirty := true


func configure(source_grid: AuthoredBlockoutGrid2D) -> void:
	grid = source_grid
	_dirty = true
	rebuild_if_dirty()


func set_blocker(blocker_id: StringName, rect: Rect2i, blocked: bool) -> void:
	if blocked:
		if _blocked_by_id.get(blocker_id, Rect2i()) == rect:
			return
		_blocked_by_id[blocker_id] = rect
	else:
		if not _blocked_by_id.has(blocker_id):
			return
		_blocked_by_id.erase(blocker_id)
	_dirty = true
	rebuild_if_dirty()


func clear_blocker(blocker_id: StringName) -> void:
	set_blocker(blocker_id, Rect2i(), false)


func rebuild_if_dirty() -> void:
	if not _dirty or grid == null:
		return
	_astar.clear()
	_walkable = grid.get_walkable_cells()
	for rect_variant: Variant in _blocked_by_id.values():
		var rect := rect_variant as Rect2i
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_walkable.erase(Vector2i(x, y))
	for cell_variant: Variant in _walkable.keys():
		var cell := cell_variant as Vector2i
		_astar.add_point(_cell_id(cell), _cell_to_world(cell))
	for cell_variant: Variant in _walkable.keys():
		var cell := cell_variant as Vector2i
		for offset: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if _walkable.has(neighbor):
				_astar.connect_points(_cell_id(cell), _cell_id(neighbor), true)
	_dirty = false
	navigation_revision += 1


func compute_path(start_world: Vector2, target_world: Vector2) -> PackedVector2Array:
	rebuild_if_dirty()
	var start := _nearest_walkable(_world_to_cell(start_world))
	var target := _nearest_walkable(_world_to_cell(target_world))
	if not _walkable.has(start) or not _walkable.has(target):
		return PackedVector2Array()
	return _astar.get_point_path(_cell_id(start), _cell_id(target))


func is_world_position_walkable(world_position: Vector2) -> bool:
	rebuild_if_dirty()
	return _walkable.has(_world_to_cell(world_position))


func nearest_walkable_world_position(world_position: Vector2) -> Variant:
	rebuild_if_dirty()
	var cell := _nearest_walkable(_world_to_cell(world_position))
	return _cell_to_world(cell) if _walkable.has(cell) else null


func get_navigation_revision() -> int:
	return navigation_revision


func _world_to_cell(world_position: Vector2) -> Vector2i:
	var local := grid.to_local(world_position)
	return Vector2i(floor(local.x / grid.authored_cell_size), floor(local.y / grid.authored_cell_size))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return grid.to_global(grid.cell_center(cell))


func _nearest_walkable(origin: Vector2i) -> Vector2i:
	if _walkable.has(origin):
		return origin
	for radius in range(1, 33):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if absi(x) != radius and absi(y) != radius:
					continue
				var candidate := origin + Vector2i(x, y)
				if _walkable.has(candidate):
					return candidate
	return origin


func _cell_id(cell: Vector2i) -> int:
	return (int(cell.x) << 32) | (int(cell.y) & 0xffffffff)
