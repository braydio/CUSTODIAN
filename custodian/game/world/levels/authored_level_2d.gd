class_name AuthoredLevel2D
extends Node2D

@export var camera_bounds := Rect2(-1024.0, -1024.0, 2048.0, 2048.0)
@export_range(2.0, 64.0, 1.0) var boundary_rail_radius := 10.0
@export var draw_placeholder_grid := true
@export var placeholder_canvas_size := Vector2(2048.0, 2048.0)
@export_range(16.0, 256.0, 1.0) var placeholder_grid_step := 96.0

var main_map: Node
var main_return_position := Vector2.ZERO
var presentation_profile: StringName = &"gameplay"
var lifecycle: Dictionary = {
	"cache_policy": "keep_during_route",
	"state_policy": "session",
}
var _level_loader: Node
var _origin_ingress: Node
var _source_state: Dictionary = {}


func _ready() -> void:
	add_to_group("authored_level")
	_apply_authoring_markers()
	_rebuild_boundary_collision()
	queue_redraw()


func configure_connection(p_main_map: Node, p_return_world_position: Vector2) -> void:
	main_map = p_main_map
	main_return_position = p_return_world_position


func configure_level_runtime(context: Dictionary) -> void:
	_level_loader = context.get("level_loader") as Node
	_origin_ingress = context.get("origin_ingress") as Node
	presentation_profile = StringName(str(context.get("presentation_profile", "gameplay")))
	var lifecycle_value: Variant = context.get("lifecycle", {})
	lifecycle = (lifecycle_value as Dictionary).duplicate(true) if lifecycle_value is Dictionary else {}
	var source_value: Variant = context.get("source_state", {})
	_source_state = (source_value as Dictionary).duplicate(false) if source_value is Dictionary else {}


func get_entry_position() -> Vector2:
	var schema := get_authoring_marker_schema()
	for item in schema:
		if str(item.get("kind", "")) == "spawn":
			return get_spawn_position(StringName(str(item.get("node_name", item.get("id", "")))))
	return get_spawn_position(&"Spawn_Main")


func has_spawn(spawn_id: StringName) -> bool:
	return find_child(String(spawn_id), true, false) is Node2D


func get_spawn_position(spawn_id: StringName) -> Vector2:
	var marker := find_child(String(spawn_id), true, false) as Node2D
	if marker == null:
		push_error("[AuthoredLevel2D] Missing spawn %s in %s" % [spawn_id, name])
		return global_position
	return marker.global_position


func enter_from_main(actor: Node) -> void:
	enter_from_main_at_spawn(actor, _default_spawn_id())


func enter_from_main_at_spawn(actor: Node, spawn_id: StringName) -> bool:
	if not (actor is Node2D) or not has_spawn(spawn_id):
		return false
	_set_branch_active(main_map, false)
	(actor as Node2D).global_position = get_spawn_position(spawn_id)
	_refresh_camera(self, actor)
	return true


func return_to_main(actor: Node) -> void:
	if _level_loader != null and is_instance_valid(_level_loader):
		if not _level_loader.has_method("complete_return_to_world"):
			push_error("[AuthoredLevel2D] Loader lacks return contract")
			return
		if not bool(_level_loader.call("complete_return_to_world", self, actor)):
			push_error("[AuthoredLevel2D] Loader rejected level return")
		return
	_legacy_return_without_loader(actor)


func _legacy_return_without_loader(actor: Node) -> void:
	_set_branch_active(main_map, true)
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if actor is Node2D:
		(actor as Node2D).global_position = main_return_position
	_refresh_camera(main_map, actor)
	var ui := get_node_or_null("/root/GameRoot/UI")
	if ui != null and ui.has_method("set_world_presentation_mode"):
		ui.call("set_world_presentation_mode", &"gameplay")
	if actor != null and actor.has_method("set_vista_presentation_mode"):
		actor.call("set_vista_presentation_mode", false)
	if _origin_ingress != null and is_instance_valid(_origin_ingress) \
	and _origin_ingress.has_method("reset_after_level_return"):
		_origin_ingress.call("reset_after_level_return")


func get_camera_bounds() -> Rect2:
	return Rect2(to_global(camera_bounds.position), camera_bounds.size)


func get_boundary_segments() -> Array:
	return []


func get_authoring_markers() -> Dictionary:
	return {}


func get_authoring_marker_schema() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for marker_id: Variant in get_authoring_markers().keys():
		var data := (get_authoring_markers()[marker_id] as Dictionary).duplicate(true)
		data["id"] = str(marker_id)
		data["node_name"] = str(data.get("node_name", str(marker_id).to_pascal_case()))
		result.append(data)
	return result


func get_authoring_marker_state() -> Dictionary:
	var result := {}
	for marker_id: Variant in get_authoring_markers().keys():
		var data := get_authoring_markers()[marker_id] as Dictionary
		var source_position := data.get("position", Vector2.ZERO) as Vector2
		result[str(marker_id)] = {
			"kind": str(data.get("kind", marker_id)),
			"label": str(data.get("label", marker_id)),
			"node_name": str(data.get("node_name", str(marker_id).to_pascal_case())),
			"source_position": source_position,
			"runtime_position": authoring_to_runtime_point(source_position),
		}
	return result


func authoring_to_runtime_point(point: Vector2) -> Vector2:
	return point


func runtime_to_authoring_point(point: Vector2) -> Vector2:
	return point


func _default_spawn_id() -> StringName:
	for item in get_authoring_marker_schema():
		if str(item.get("kind", "")) == "spawn":
			return StringName(str(item.get("node_name", item.get("id", "Spawn_Main"))))
	return &"Spawn_Main"


func _apply_authoring_markers() -> void:
	for marker_id: Variant in get_authoring_markers().keys():
		var data := get_authoring_markers()[marker_id] as Dictionary
		var node_name := str(data.get("node_name", str(marker_id).to_pascal_case()))
		var marker := find_child(node_name, true, false) as Node2D
		if marker == null:
			continue
		marker.position = authoring_to_runtime_point(data.get("position", Vector2.ZERO) as Vector2)
		marker.set_meta("marker_id", str(marker_id))
		marker.set_meta("marker_kind", str(data.get("kind", marker_id)))


func _rebuild_boundary_collision() -> void:
	var body := get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if body == null:
		push_error("[AuthoredLevel2D] Missing Collision/PathBoundaryCollision in %s" % name)
		return
	for child in body.get_children():
		child.queue_free()
	var index := 1
	for raw_segment: Variant in get_boundary_segments():
		if not (raw_segment is Array) or (raw_segment as Array).size() < 2:
			continue
		var segment := raw_segment as Array
		_add_boundary_segment(
			body,
			"BoundarySegment_%03d" % index,
			authoring_to_runtime_point(segment[0] as Vector2),
			authoring_to_runtime_point(segment[1] as Vector2)
		)
		index += 1


func _add_boundary_segment(parent: StaticBody2D, node_name: String, a: Vector2, b: Vector2) -> void:
	var direction := b - a
	var shape := CapsuleShape2D.new()
	shape.radius = boundary_rail_radius
	shape.height = maxf(direction.length() + boundary_rail_radius * 2.0, boundary_rail_radius * 2.0)
	var collision := CollisionShape2D.new()
	collision.name = node_name
	collision.shape = shape
	collision.position = (a + b) * 0.5
	if direction.length_squared() > 0.001:
		collision.rotation = direction.angle() - PI * 0.5
	collision.set_meta("boundary_a", a)
	collision.set_meta("boundary_b", b)
	parent.add_child(collision)


func _set_branch_active(branch: Node, active: bool) -> void:
	if branch == null:
		return
	if branch is CanvasItem:
		(branch as CanvasItem).visible = active
	branch.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _refresh_camera(map_instance: Node, actor: Node) -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	elif camera is Node2D and actor is Node2D:
		(camera as Node2D).global_position = (actor as Node2D).global_position


func _draw() -> void:
	if not draw_placeholder_grid:
		return
	var half := placeholder_canvas_size * 0.5
	var color := Color(0.18, 0.36, 0.42, 0.22)
	var x := -half.x
	while x <= half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), color, 1.0)
		x += placeholder_grid_step
	var y := -half.y
	while y <= half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), color, 1.0)
		y += placeholder_grid_step
