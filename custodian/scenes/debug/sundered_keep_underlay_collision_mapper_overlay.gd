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
		_draw_existing(state.get("underlay_scene") as Node)
	if bool(state.get("show_draft", true)):
		_draw_draft(state.get("draft_points", []) as Array)
	_draw_crosshair(state.get("mouse_world", Vector2.ZERO) as Vector2)


func _draw_existing(underlay_scene: Node) -> void:
	if underlay_scene == null:
		return
	var boundary := underlay_scene.get_node_or_null("World/MappedUnderlayBounds/UnderlayBoundaryCollision") as StaticBody2D
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
