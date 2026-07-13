extends Node2D

@export var mapper_path := NodePath("../..")

var _mapper: Node = null


func _ready() -> void:
	z_as_relative = false
	z_index = 500
	_mapper = get_node_or_null(mapper_path)


func _draw() -> void:
	if _mapper == null or not _mapper.has_method("get_collision_mapper_state"):
		return
	var state := _mapper.call("get_collision_mapper_state") as Dictionary
	if bool(state.get("show_existing", true)):
		_draw_existing(state.get("approach") as Node)
	if bool(state.get("show_draft", true)):
		_draw_draft(state.get("draft_points", []) as Array)
		_draw_markers(state)
	_draw_crosshair(state.get("mouse_world", Vector2.ZERO) as Vector2)


func _draw_existing(approach: Node) -> void:
	if approach == null:
		return
	var boundary := approach.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null:
		return
	for child in boundary.get_children():
		var col := child as CollisionShape2D
		if col == null:
			continue
		var endpoints := _get_segment_endpoints(col)
		if endpoints.is_empty():
			continue
		var a := endpoints[0]
		var b := endpoints[1]
		draw_line(a, b, Color(1.0, 0.15, 0.12, 0.9), 3.0)
		if col.shape is CapsuleShape2D:
			draw_line(a, b, Color(1.0, 0.15, 0.12, 0.22), maxf(4.0, (col.shape as CapsuleShape2D).radius * 2.0))
		draw_circle(a, 5.0, Color(1.0, 0.85, 0.15, 0.95))
		draw_circle(b, 5.0, Color(1.0, 0.85, 0.15, 0.95))


func _draw_draft(points: Array) -> void:
	var index := 0
	while index < points.size():
		var point := points[index] as Vector2
		draw_circle(point, 6.0, Color(0.2, 0.95, 1.0, 0.95))
		if index + 1 < points.size():
			draw_line(point, points[index + 1] as Vector2, Color(0.2, 0.95, 1.0, 0.95), 3.0)
		elif index > 0:
			draw_line(points[index - 1] as Vector2, point, Color(0.2, 0.95, 1.0, 0.45), 2.0)
		index += 1


func _draw_markers(state: Dictionary) -> void:
	var marker_points := _collect_marker_points(state)
	var draft_markers := state.get("draft_markers", {}) as Dictionary
	var selected_marker := str(state.get("selected_marker", ""))
	for marker_id: String in marker_points.keys():
		var point := marker_points[marker_id] as Vector2
		var is_draft := draft_markers.has(marker_id)
		var is_selected := marker_id == selected_marker
		var color := Color(0.55, 1.0, 0.70, 0.96) if is_draft else Color(0.95, 0.78, 0.28, 0.76)
		if is_selected:
			color = Color(0.35, 0.90, 1.0, 1.0)
		draw_circle(point, 10.0 if is_selected else 7.0, color)
		draw_line(point + Vector2(-14.0, 0.0), point + Vector2(14.0, 0.0), color, 2.0)
		draw_line(point + Vector2(0.0, -14.0), point + Vector2(0.0, 14.0), color, 2.0)
		draw_string(ThemeDB.fallback_font, point + Vector2(16.0, -8.0), marker_id, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)


func _collect_marker_points(state: Dictionary) -> Dictionary:
	var points := {}
	var approach := state.get("approach") as Node
	if approach != null and approach.has_method("get_authoring_marker_state"):
		var marker_state := approach.call("get_authoring_marker_state") as Dictionary
		for marker_id: String in marker_state.keys():
			var data := marker_state[marker_id] as Dictionary
			points[marker_id] = data.get("runtime_position", Vector2.ZERO) as Vector2
	var draft_markers := state.get("draft_markers", {}) as Dictionary
	for marker_id: String in draft_markers.keys():
		points[marker_id] = draft_markers[marker_id] as Vector2
	return points


func _draw_crosshair(point: Vector2) -> void:
	var size := 12.0
	draw_line(point + Vector2(-size, 0.0), point + Vector2(size, 0.0), Color(0.95, 0.95, 1.0, 0.65), 1.0)
	draw_line(point + Vector2(0.0, -size), point + Vector2(0.0, size), Color(0.95, 0.95, 1.0, 0.65), 1.0)


func _get_segment_endpoints(col: CollisionShape2D) -> Array[Vector2]:
	if col.has_meta("boundary_a") and col.has_meta("boundary_b"):
		return [col.get_meta("boundary_a") as Vector2, col.get_meta("boundary_b") as Vector2]
	if col.shape is SegmentShape2D:
		var segment := col.shape as SegmentShape2D
		return [segment.a, segment.b]
	return []
