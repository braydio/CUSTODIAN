extends Node2D

@export var mapper_path := NodePath("../..")
var _mapper: Node


func _ready() -> void:
	z_as_relative = false
	z_index = 500
	_mapper = get_node_or_null(mapper_path)


func _draw() -> void:
	if _mapper == null or not _mapper.has_method("get_collision_mapper_state"):
		return
	var state := _mapper.call("get_collision_mapper_state") as Dictionary
	if bool(state.get("show_grid", true)):
		_draw_grid(state)
	if bool(state.get("show_existing", true)):
		_draw_existing(state.get("target_level") as Node)
	_draw_semantic_geometry(state)
	if bool(state.get("show_draft", true)):
		_draw_draft(state.get("draft_points", []) as Array)
		_draw_markers(state)
	_draw_crosshair(state.get("mouse_world", Vector2.ZERO) as Vector2)


func _draw_existing(level: Node) -> void:
	if level == null:
		return
	var boundary := level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null:
		return
	for child in boundary.get_children():
		var collision := child as CollisionShape2D
		if collision == null or not collision.has_meta("boundary_a") or not collision.has_meta("boundary_b"):
			continue
		var a := collision.get_meta("boundary_a") as Vector2
		var b := collision.get_meta("boundary_b") as Vector2
		draw_line(a, b, Color(1.0, 0.15, 0.12, 0.9), 3.0)
		draw_circle(a, 5.0, Color(1.0, 0.85, 0.15, 0.95))
		draw_circle(b, 5.0, Color(1.0, 0.85, 0.15, 0.95))


func _draw_grid(state: Dictionary) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var viewport_size := get_viewport_rect().size / camera.zoom
	var rect := Rect2(camera.get_screen_center_position() - viewport_size * 0.5, viewport_size)
	var start_x := floorf(rect.position.x / 32.0) * 32.0
	var start_y := floorf(rect.position.y / 32.0) * 32.0
	var x := start_x
	while x <= rect.end.x:
		var major := is_equal_approx(fposmod(x, 256.0), 0.0)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.35, 0.68, 0.9, 0.20 if major else 0.08), 1.5 if major else 1.0)
		x += 32.0
	var y := start_y
	while y <= rect.end.y:
		var major := is_equal_approx(fposmod(y, 256.0), 0.0)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.35, 0.68, 0.9, 0.20 if major else 0.08), 1.5 if major else 1.0)
		y += 32.0


func _draw_semantic_geometry(state: Dictionary) -> void:
	var groups := state.get("semantic_groups", {}) as Dictionary
	var show_labels := bool(state.get("show_semantic_labels", true))
	for record: Dictionary in state.get("semantic_geometry", []):
		var group := str(record.get("group", ""))
		if not bool(groups.get(group, true)):
			continue
		var color := _semantic_color(group)
		var anchor := Vector2.ZERO
		match str(record.get("shape", "")):
			"rect", "band":
				var rect := record.get("rect", Rect2()) as Rect2
				draw_rect(rect, Color(color.r, color.g, color.b, 0.10), true)
				draw_rect(rect, color, false, 2.0)
				anchor = rect.position
			"sprite_rect":
				var rect := record.get("rect", Rect2()) as Rect2
				_draw_dashed_rect(rect, color)
				anchor = rect.position
			"circle":
				var center := record.get("center", Vector2.ZERO) as Vector2
				var radius := float(record.get("radius", 0.0))
				draw_circle(center, radius, Color(color.r, color.g, color.b, 0.10))
				draw_arc(center, radius, 0.0, TAU, 48, color, 2.0)
				anchor = center + Vector2(-radius, -radius)
			"point":
				anchor = record.get("point", Vector2.ZERO) as Vector2
				draw_circle(anchor, 7.0, color)
			"polygon":
				var polygon := record.get("polygon", PackedVector2Array()) as PackedVector2Array
				if polygon.size() >= 3:
					draw_colored_polygon(polygon, Color(color.r, color.g, color.b, 0.06))
					for index in polygon.size():
						draw_line(polygon[index], polygon[(index + 1) % polygon.size()], color, 2.0)
					anchor = polygon[0]
		if show_labels and not anchor.is_zero_approx():
			var suffix := ""
			if record.has("texture_size"):
				var size := record.get("texture_size") as Vector2
				suffix = "  %dx%d" % [int(size.x), int(size.y)]
			draw_string(ThemeDB.fallback_font, anchor + Vector2(5.0, -5.0), "%s%s" % [str(record.get("label", record.get("id", ""))), suffix], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var points := [rect.position, rect.position + Vector2(rect.size.x, 0.0), rect.end, rect.position + Vector2(0.0, rect.size.y)]
	for index in 4:
		var a: Vector2 = points[index]
		var b: Vector2 = points[(index + 1) % 4]
		var length := a.distance_to(b)
		var cursor := 0.0
		while cursor < length:
			var next := minf(cursor + 10.0, length)
			draw_line(a.lerp(b, cursor / length), a.lerp(b, next / length), color, 1.5)
			cursor += 18.0


func _semantic_color(group: String) -> Color:
	return {
		"boundary": Color(1.0, 0.25, 0.18, 0.92),
		"encounter": Color(1.0, 0.55, 0.12, 0.92),
		"hazard": Color(1.0, 0.12, 0.42, 0.94),
		"interaction": Color(0.25, 1.0, 0.62, 0.94),
		"camera": Color(0.38, 0.72, 1.0, 0.80),
		"transition": Color(0.72, 0.42, 1.0, 0.82),
		"art": Color(0.94, 0.88, 0.34, 0.72),
		"traversal": Color(0.25, 0.92, 1.0, 0.88),
	}.get(group, Color.WHITE) as Color


func _draw_draft(points: Array) -> void:
	for index in range(points.size()):
		var point := points[index] as Vector2
		draw_circle(point, 6.0, Color(0.2, 0.95, 1.0, 0.95))
		if index + 1 < points.size():
			draw_line(point, points[index + 1] as Vector2, Color(0.2, 0.95, 1.0, 0.95), 3.0)


func _draw_markers(state: Dictionary) -> void:
	var points := {}
	var level := state.get("target_level") as Node
	if level != null and level.has_method("get_authoring_marker_state"):
		for marker_id: Variant in (level.call("get_authoring_marker_state") as Dictionary).keys():
			var data := (level.call("get_authoring_marker_state") as Dictionary)[marker_id] as Dictionary
			points[str(marker_id)] = data.get("runtime_position", Vector2.ZERO)
	for marker_id: Variant in (state.get("draft_markers", {}) as Dictionary).keys():
		points[str(marker_id)] = (state.get("draft_markers", {}) as Dictionary)[marker_id]
	for marker_id: String in points.keys():
		var point := points[marker_id] as Vector2
		var color := Color(0.35, 0.90, 1.0, 1.0) if marker_id == str(state.get("selected_marker", "")) else Color(0.95, 0.78, 0.28, 0.8)
		draw_circle(point, 8.0, color)
		draw_string(ThemeDB.fallback_font, point + Vector2(14.0, -6.0), marker_id, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)


func _draw_crosshair(point: Vector2) -> void:
	draw_line(point + Vector2(-12.0, 0.0), point + Vector2(12.0, 0.0), Color(0.95, 0.95, 1.0, 0.65), 1.0)
	draw_line(point + Vector2(0.0, -12.0), point + Vector2(0.0, 12.0), Color(0.95, 0.95, 1.0, 0.65), 1.0)
