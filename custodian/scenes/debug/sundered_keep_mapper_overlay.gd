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
		or not _mapper.has_method("get_sundered_keep_mapper_state")
	):
		return
	var state := (
		_mapper.call("get_sundered_keep_mapper_state") as Dictionary
	)
	if bool(state.get("show_grid", true)):
		_draw_underlay_grid(state)
	_draw_palette_grid(state)
	if bool(state.get("show_collision", true)):
		_draw_collision(state)
	_draw_collision_draft(state)
	_draw_markers(state)
	_draw_features(state)
	_draw_underlay_selection(state)
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
		"MappedUnderlayBounds/UnderlayBoundaryCollision"
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


func _draw_collision_draft(state: Dictionary) -> void:
	var points := state.get("draft_points", []) as Array
	for index in points.size():
		var point := points[index] as Vector2
		draw_circle(point, 6.0, Color(0.2, 0.95, 1.0, 0.95))
		if index > 0:
			draw_line(
				points[index - 1] as Vector2,
				point,
				Color(0.2, 0.95, 1.0, 0.95),
				3.0
			)


func _draw_markers(state: Dictionary) -> void:
	var document := state.get("collision_document", {}) as Dictionary
	var markers := document.get("markers", {}) as Dictionary
	var draft_markers := state.get("draft_markers", {}) as Dictionary
	var selected := str(state.get("selected_marker", ""))
	for marker_id: String in markers.keys():
		var marker := markers[marker_id] as Dictionary
		var raw_position := marker.get("position", []) as Array
		if raw_position.size() < 2:
			continue
		var point := Vector2(float(raw_position[0]), float(raw_position[1]))
		if draft_markers.has(marker_id):
			point = draft_markers[marker_id] as Vector2
		var color := (
			Color(0.35, 0.9, 1.0, 1.0)
			if marker_id == selected
			else Color(0.95, 0.78, 0.28, 0.8)
		)
		draw_circle(point, 9.0, color)
		draw_string(
			ThemeDB.fallback_font,
			point + Vector2(12.0, -8.0),
			marker_id,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			12,
			color
		)


func _draw_features(state: Dictionary) -> void:
	if str(state.get("authoring_mode", "")) != "FEATURES":
		return
	var tile_size := int(state.get("tile_size", 32))
	var entries := state.get("feature_entries", []) as Array
	var selected_index := int(state.get("selected_feature_index", -1))
	for index in entries.size():
		var feature := entries[index] as Dictionary
		var bounds := feature.get(
			"bounds",
			Rect2i(
				feature.get("anchor", Vector2i.ZERO) as Vector2i,
				Vector2i.ONE
			)
		) as Rect2i
		var rect := Rect2(
			Vector2(bounds.position * tile_size),
			Vector2(bounds.size * tile_size)
		)
		var selected := index == selected_index
		var bundle := str(feature.get("section", "")) == "bundle"
		var color := (
			Color(0.40, 1.0, 0.62, 1.0)
			if selected
			else (
				Color(1.0, 0.72, 0.20, 0.72)
				if bundle
				else Color(0.42, 0.86, 1.0, 0.52)
			)
		)
		draw_rect(
			rect,
			Color(color.r, color.g, color.b, 0.10 if selected else 0.035),
			true
		)
		draw_rect(rect, color, false, 4.0 if selected else 1.5)
		var anchor := feature.get(
			"anchor",
			bounds.position
		) as Vector2i
		var anchor_point := (
			Vector2(anchor * tile_size)
			+ Vector2.ONE * float(tile_size) * 0.5
		)
		draw_circle(
			anchor_point,
			7.0 if selected else 4.0,
			color
		)
		if selected or bundle:
			draw_string(
				ThemeDB.fallback_font,
				rect.position + Vector2(5.0, -6.0),
				str(feature.get("label", "feature")),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				14 if selected else 12,
				color
			)


func _draw_underlay_selection(state: Dictionary) -> void:
	if not bool(state.get("underlay_select_mode", false)):
		return
	var tile_size := int(state.get("tile_size", 32))
	var raw_rect := state.get("selection_rect_cells", []) as Array
	if (
		raw_rect.size() < 4
		or int(raw_rect[2]) <= 0
		or int(raw_rect[3]) <= 0
	):
		return
	var rect := Rect2(
		Vector2(
			int(raw_rect[0]) * tile_size,
			int(raw_rect[1]) * tile_size
		),
		Vector2(
			int(raw_rect[2]) * tile_size,
			int(raw_rect[3]) * tile_size
		)
	)
	draw_rect(rect, Color(1.0, 0.74, 0.18, 0.18), true)
	draw_rect(rect, Color(1.0, 0.84, 0.22, 0.95), false, 3.0)


func _draw_cursor(state: Dictionary) -> void:
	var point := state.get("mouse_world", Vector2.ZERO) as Vector2
	var map_size := state.get("map_size", Vector2.ZERO) as Vector2
	var tile_size := int(state.get("tile_size", 32))
	if Rect2(Vector2.ZERO, map_size).has_point(point):
		var cell := Vector2i(
			floori(point.x / tile_size),
			floori(point.y / tile_size)
		)
		var cursor_size := Vector2i.ONE
		if (
			str(state.get("paint_source", "PALETTE_TILE"))
			== "UNDERLAY_STAMP"
			and not bool(state.get("underlay_select_mode", false))
		):
			var stamp := (
				state.get("active_underlay_stamp", {}) as Dictionary
			)
			var raw_rect := (
				stamp.get("source_rect_cells", []) as Array
			)
			if raw_rect.size() >= 4:
				cursor_size = Vector2i(
					maxi(1, int(raw_rect[2])),
					maxi(1, int(raw_rect[3]))
				)
		draw_rect(
			Rect2(
				Vector2(cell * tile_size),
				Vector2(cursor_size * tile_size)
			),
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
