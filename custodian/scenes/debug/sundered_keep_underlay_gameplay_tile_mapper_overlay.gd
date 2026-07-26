extends Node2D

@export var mapper_path := NodePath("../..")

var _mapper: Node


func _ready() -> void:
	z_as_relative = false
	z_index = 150
	_mapper = get_node_or_null(mapper_path)


func _draw() -> void:
	if (
		_mapper == null
		or not _mapper.has_method("get_gameplay_tile_mapper_state")
	):
		return
	var state := (
		_mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	)
	if bool(state.get("show_grid", true)):
		_draw_underlay_grid(state)
	_draw_palette_grid(state)
	if bool(state.get("show_collision", true)):
		_draw_collision(state)
	_draw_cursor(state)


func _draw_underlay_grid(state: Dictionary) -> void:
	var map_size := state.get("map_size", Vector2.ZERO) as Vector2
	var tile_size := int(state.get("tile_size", 32))
	var columns := floori(map_size.x / tile_size)
	var rows := floori(map_size.y / tile_size)
	for x in range(columns + 1):
		var major := x % 8 == 0
		var color := (
			Color(0.35, 0.82, 1.0, 0.34)
			if major
			else Color(0.35, 0.82, 1.0, 0.13)
		)
		draw_line(
			Vector2(x * tile_size, 0.0),
			Vector2(x * tile_size, map_size.y),
			color,
			2.0 if major else 1.0
		)
	for y in range(rows + 1):
		var major := y % 8 == 0
		var color := (
			Color(0.35, 0.82, 1.0, 0.34)
			if major
			else Color(0.35, 0.82, 1.0, 0.13)
		)
		draw_line(
			Vector2(0.0, y * tile_size),
			Vector2(map_size.x, y * tile_size),
			color,
			2.0 if major else 1.0
		)


func _draw_palette_grid(state: Dictionary) -> void:
	var origin := state.get("palette_origin", Vector2.ZERO) as Vector2
	var cell_size := (
		state.get("palette_cell_size", Vector2.ONE) as Vector2
	)
	var columns := int(state.get("palette_columns", 11))
	var palette := state.get("palette", []) as Array
	var selected := int(state.get("selected_tile_number", 0))
	for index in palette.size():
		var column := index % columns
		var row := index / columns
		var rect := Rect2(
			origin + Vector2(
				column * cell_size.x,
				row * cell_size.y
			),
			cell_size
		)
		var number := index + 1
		var fill := (
			Color(0.18, 0.52, 0.72, 0.36)
			if number == selected
			else Color(0.025, 0.035, 0.055, 0.88)
		)
		draw_rect(rect, fill, true)
		draw_rect(
			rect,
			Color(0.28, 0.72, 0.94, 1.0)
			if number == selected
			else Color(0.42, 0.48, 0.58, 0.72),
			false,
			4.0 if number == selected else 1.0
		)


func _draw_collision(state: Dictionary) -> void:
	var underlay_scene := state.get("underlay_scene") as Node
	if underlay_scene == null:
		return
	var boundary := underlay_scene.get_node_or_null(
		"World/MappedUnderlayBounds/UnderlayBoundaryCollision"
	) as StaticBody2D
	if boundary == null:
		return
	for child: Node in boundary.get_children():
		var collision := child as CollisionShape2D
		if collision == null:
			continue
		var endpoints := _segment_endpoints(collision)
		if endpoints.is_empty():
			continue
		var a := endpoints[0]
		var b := endpoints[1]
		draw_line(a, b, Color(1.0, 0.16, 0.12, 0.94), 3.0)
		if collision.shape is CapsuleShape2D:
			draw_line(
				a,
				b,
				Color(1.0, 0.16, 0.12, 0.18),
				maxf(
					4.0,
					(collision.shape as CapsuleShape2D).radius * 2.0
				)
			)


func _draw_cursor(state: Dictionary) -> void:
	var point := state.get("mouse_world", Vector2.ZERO) as Vector2
	var map_size := state.get("map_size", Vector2.ZERO) as Vector2
	var tile_size := int(state.get("tile_size", 32))
	if Rect2(Vector2.ZERO, map_size).has_point(point):
		var cell := Vector2i(
			floori(point.x / tile_size),
			floori(point.y / tile_size)
		)
		draw_rect(
			Rect2(Vector2(cell * tile_size), Vector2.ONE * tile_size),
			Color(1.0, 0.88, 0.24, 0.80),
			false,
			2.0
		)
	var size := 10.0
	draw_line(
		point + Vector2(-size, 0.0),
		point + Vector2(size, 0.0),
		Color(0.96, 0.96, 1.0, 0.72),
		1.0
	)
	draw_line(
		point + Vector2(0.0, -size),
		point + Vector2(0.0, size),
		Color(0.96, 0.96, 1.0, 0.72),
		1.0
	)


func _segment_endpoints(collision: CollisionShape2D) -> Array[Vector2]:
	if (
		collision.has_meta("boundary_a")
		and collision.has_meta("boundary_b")
	):
		return [
			collision.get_meta("boundary_a") as Vector2,
			collision.get_meta("boundary_b") as Vector2,
		]
	if collision.shape is SegmentShape2D:
		var segment := collision.shape as SegmentShape2D
		return [segment.a, segment.b]
	return []
