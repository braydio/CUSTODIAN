class_name AuthoredBlockoutGrid2D
extends Node2D

@export var authored_cell_size := 32.0
@export var map_size_cells := Vector2i(64, 64)
@export var floor_color := Color("343b40")
@export var grid_color := Color(0.58, 0.66, 0.68, 0.10)

var _walkable_cells: Dictionary = {}
var _walkable_regions: Array[Rect2i] = []
var _visual_regions: Array[Dictionary] = []
var _boundary_segments: Array = []


func configure(
	cell_size: float,
	map_size: Vector2i,
	walkable_regions: Array[Rect2i],
	visual_regions: Array[Dictionary] = []
) -> void:
	authored_cell_size = cell_size
	map_size_cells = map_size
	_walkable_regions = walkable_regions.duplicate()
	_visual_regions = visual_regions.duplicate(true)
	_rebuild_walkable_union()
	_boundary_segments = _build_merged_boundary_segments()
	queue_redraw()


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * authored_cell_size


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * authored_cell_size, Vector2.ONE * authored_cell_size)


func is_walkable_cell(cell: Vector2i) -> bool:
	return _walkable_cells.has(cell)


func get_walkable_cells() -> Dictionary:
	return _walkable_cells.duplicate()


func get_boundary_segments() -> Array:
	return _boundary_segments.duplicate(true)


func get_visual_regions() -> Array[Dictionary]:
	return _visual_regions.duplicate(true)


func _rebuild_walkable_union() -> void:
	_walkable_cells.clear()
	for rect in _walkable_regions:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if Rect2i(Vector2i.ZERO, map_size_cells).has_point(cell):
					_walkable_cells[cell] = true


func _build_merged_boundary_segments() -> Array:
	var horizontal: Dictionary = {}
	var vertical: Dictionary = {}
	var cardinals := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for cell_variant: Variant in _walkable_cells.keys():
		var cell := cell_variant as Vector2i
		for direction in cardinals:
			if _walkable_cells.has(cell + direction):
				continue
			if direction == Vector2i.UP or direction == Vector2i.DOWN:
				var y := cell.y + (1 if direction == Vector2i.DOWN else 0)
				if not horizontal.has(y):
					horizontal[y] = []
				(horizontal[y] as Array).append(cell.x)
			else:
				var x := cell.x + (1 if direction == Vector2i.RIGHT else 0)
				if not vertical.has(x):
					vertical[x] = []
				(vertical[x] as Array).append(cell.y)
	var result: Array = []
	for y_variant: Variant in horizontal.keys():
		_append_merged_runs(result, horizontal[y_variant] as Array, int(y_variant), true)
	for x_variant: Variant in vertical.keys():
		_append_merged_runs(result, vertical[x_variant] as Array, int(x_variant), false)
	return result


func _append_merged_runs(
	result: Array,
	values: Array,
	fixed: int,
	horizontal: bool
) -> void:
	values.sort()
	if values.is_empty():
		return
	var start := int(values[0])
	var previous := start
	for index in range(1, values.size() + 1):
		var contiguous := index < values.size() and int(values[index]) == previous + 1
		if contiguous:
			previous = int(values[index])
			continue
		var a := Vector2(start, fixed) if horizontal else Vector2(fixed, start)
		var b := Vector2(previous + 1, fixed) if horizontal else Vector2(fixed, previous + 1)
		result.append([a * authored_cell_size + position, b * authored_cell_size + position])
		if index < values.size():
			start = int(values[index])
			previous = start


func _draw() -> void:
	# First-pass static blockout: rectangle fills preserve authored topology
	# without introducing raster-map or gameplay authority.
	for rect in _walkable_regions:
		var world_rect := Rect2(
			Vector2(rect.position) * authored_cell_size,
			Vector2(rect.size) * authored_cell_size
		)
		draw_rect(world_rect, floor_color, true)
		draw_rect(world_rect, grid_color, false, 2.0)
	for region in _visual_regions:
		var rect := region.get("rect", Rect2i()) as Rect2i
		var color := region.get("color", Color.WHITE) as Color
		draw_rect(
			Rect2(Vector2(rect.position) * authored_cell_size, Vector2(rect.size) * authored_cell_size),
			color,
			true
		)
