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
	if bool(state.get("show_existing", true)):
		_draw_existing(state.get("target_level") as Node)
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
