extends Area2D
class_name WorldIngressSite

@export var ingress_id: StringName
@export var level_id: StringName = &""
@export var approach_scene: PackedScene
@export var target_scene_path: String = ""
@export var target_spawn_id: StringName = &""
@export var prompt_text: String = "APPROACH"
@export_range(32.0, 192.0, 1.0) var interaction_distance: float = 92.0
@export var allow_legacy_registered_fallback := false

var _triggered := false
var _approach_enter_deferred := false
var _sprite: Sprite2D = null
var _main_map: Node = null
var _entry_snapshot: Dictionary = {}


func _ready() -> void:
	add_to_group("world_ingress_site")
	body_entered.connect(_on_body_entered)
	_ensure_collision()
	_ensure_visual()


func configure(
	p_ingress_id: StringName,
	p_approach_scene: PackedScene,
	p_target_scene_path: String,
	p_target_spawn_id: StringName = &""
) -> void:
	ingress_id = p_ingress_id
	approach_scene = p_approach_scene
	target_scene_path = p_target_scene_path
	target_spawn_id = p_target_spawn_id


func configure_level(p_level_id: StringName, p_main_map: Node = null) -> void:
	level_id = p_level_id
	_main_map = p_main_map


func apply_ingress_definition(definition: RefCounted) -> void:
	if definition == null:
		return
	ingress_id = definition.ingress_id
	prompt_text = definition.prompt_text
	target_spawn_id = definition.target_spawn_id
	interaction_distance = definition.interaction_distance


func get_interaction_prompt() -> String:
	return prompt_text


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if _approach_enter_deferred:
		return
	if body == null:
		return
	if not _is_player_body(body):
		return
	_approach_enter_deferred = true
	call_deferred("_enter_approach_deferred", body)


func _enter_approach_deferred(body: Node) -> void:
	_approach_enter_deferred = false
	if _triggered:
		return
	if not is_instance_valid(body):
		return
	if not _is_player_body(body):
		return
	_triggered = true
	_enter_approach(body)


func _enter_approach(actor: Node) -> void:
	var world := get_node_or_null("/root/GameRoot/World") as Node2D
	if world == null:
		var candidate := get_tree().current_scene
		world = candidate as Node2D
	if world == null:
		push_error("[WorldIngressSite] Missing world root for %s" % ingress_id)
		reset_after_level_return()
		return

	if not level_id.is_empty():
		var level_loader := _find_level_loader()
		if level_loader == null:
			push_error("[WorldIngressSite] Missing LevelLoader for registered destination %s" % level_id)
			if not allow_legacy_registered_fallback:
				reset_after_level_return()
				return
		else:
			var definition: RefCounted = level_loader.call("get_definition", level_id) as RefCounted
			var presentation_profile := &"gameplay"
			if definition != null and definition.has_method("get_presentation_profile"):
				presentation_profile = definition.call("get_presentation_profile") as StringName
			_entry_snapshot = _capture_origin_state(actor)
			_set_procgen_world_visible(false)
			_set_world_presentation_profile(actor, presentation_profile)
		if level_loader != null:
			var instance: Node = level_loader.call("enter_level", level_id, actor, {
				"parent": world,
				"main_map": _main_map,
				"return_world_position": global_position,
				"target_spawn_id": target_spawn_id,
				"origin_ingress": self,
				"source_state": _entry_snapshot,
			}) as Node
			if instance != null:
				_observe(&"level_ingress_entered", {"level_id": String(level_id), "ingress_id": String(ingress_id)})
				return
		_observe(&"level_ingress_spawn_resolution_failed", {"level_id": String(level_id), "ingress_id": String(ingress_id)})
		if not allow_legacy_registered_fallback:
			push_error("[WorldIngressSite] Registered level entry failed authoritatively: %s" % level_id)
			_restore_failed_approach_entry(actor)
			return
		push_warning("[WorldIngressSite] LevelLoader could not enter %s; explicit legacy fallback enabled" % level_id)

	if _entry_snapshot.is_empty():
		_entry_snapshot = _capture_origin_state(actor)
		_set_procgen_world_visible(false)
		_set_world_presentation_profile(actor, &"vista_approach")

	if approach_scene == null:
		push_error("[WorldIngressSite] Missing approach_scene for %s" % ingress_id)
		_restore_failed_approach_entry(actor)
		return

	var existing := world.get_node_or_null("%s_Approach" % String(ingress_id))
	var approach := existing
	if approach == null:
		approach = approach_scene.instantiate()
		if approach == null:
			push_error("[WorldIngressSite] Could not instantiate approach scene for %s" % ingress_id)
			_restore_failed_approach_entry(actor)
			return
		approach.name = "%s_Approach" % String(ingress_id)
		world.add_child(approach)
		_align_approach_entry_to_ingress(approach)
	if approach.has_method("configure_ingress"):
		approach.call("configure_ingress", {
			"target_scene_path": target_scene_path,
			"target_spawn_id": target_spawn_id,
			"return_world_position": global_position,
		})

	if actor is Node2D and approach.has_method("get_entry_position"):
		(actor as Node2D).global_position = approach.call("get_entry_position")


func _find_level_loader() -> Node:
	var candidates := get_tree().get_nodes_in_group("level_loader")
	if not candidates.is_empty():
		return candidates[0] as Node
	return null


func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("operator") or String(body.name) == "Operator"


func _align_approach_entry_to_ingress(approach: Node) -> void:
	if not (approach is Node2D) or not approach.has_method("get_entry_position"):
		return
	var approach_2d := approach as Node2D
	var entry_position: Vector2 = approach.call("get_entry_position")
	approach_2d.global_position += global_position - entry_position


func _set_procgen_world_visible(value: bool) -> void:
	_set_world_branch_visible(get_node_or_null("/root/GameRoot/World/ProcGenRuntime"), value)
	_set_world_branch_visible(get_node_or_null("/root/GameRoot/World/ConnectedMaps"), value)


func _restore_failed_approach_entry(actor: Node) -> void:
	var result := restore_world_origin(actor, _entry_snapshot)
	if not bool(result.get("succeeded", false)):
		push_error("[WorldIngressSite] Failed to restore world origin after entry failure: %s" % result.get("reason", "unknown failure"))
		return
	reset_after_level_return()


func _set_world_presentation_profile(actor: Node, profile: StringName) -> void:
	var ui := get_node_or_null("/root/GameRoot/UI")
	if ui != null and ui.has_method("set_world_presentation_mode"):
		ui.call("set_world_presentation_mode", profile)
	if actor != null and actor.has_method("set_vista_presentation_mode"):
		actor.call("set_vista_presentation_mode", profile != &"gameplay")


func restore_world_origin(actor: Node, source_state: Dictionary = {}) -> Dictionary:
	var snapshot := source_state if not source_state.is_empty() else _entry_snapshot
	if snapshot.is_empty():
		return _restore_failure("origin snapshot is empty")
	var missing_branches: Array[String] = []
	for branch_state: Variant in snapshot.get("branches", []):
		if not (branch_state is Dictionary):
			continue
		var branch_value: Variant = (branch_state as Dictionary).get("node")
		if branch_value == null or not is_instance_valid(branch_value):
			missing_branches.append(str((branch_state as Dictionary).get("path", "unknown_branch")))
	if not missing_branches.is_empty():
		return _restore_failure("one or more origin branches are unavailable", missing_branches)
	if not (actor is Node2D) or not snapshot.has("actor_position"):
		return _restore_failure("actor return position is unavailable")
	var camera_value: Variant = snapshot.get("camera")
	var camera: Node = camera_value as Node if camera_value != null and is_instance_valid(camera_value) else null
	if camera == null:
		camera = get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null or not is_instance_valid(camera) or not camera.has_method("set_runtime_map"):
		return _restore_failure("camera runtime-map binding is unavailable")
	var runtime_map_value: Variant = snapshot.get("camera_runtime_map")
	var runtime_map: Node = runtime_map_value as Node if runtime_map_value != null and is_instance_valid(runtime_map_value) else null
	if runtime_map == null:
		var main_map_value: Variant = snapshot.get("main_map", _main_map)
		runtime_map = main_map_value as Node if main_map_value != null and is_instance_valid(main_map_value) else null
	if runtime_map == null or not is_instance_valid(runtime_map):
		return _restore_failure("camera origin map is unavailable")
	for branch_state: Variant in snapshot.get("branches", []):
		if not (branch_state is Dictionary):
			continue
		_restore_branch_state(branch_state as Dictionary)
	var ui_mode := StringName(str(snapshot.get("ui_mode", "gameplay")))
	_set_world_presentation_profile(actor, ui_mode)
	(actor as Node2D).global_position = snapshot.get("actor_position") as Vector2
	if camera != null and camera.has_method("set_presentation_framing"):
		camera.call(
			"set_presentation_framing",
			bool(snapshot.get("camera_presentation_framing", false)),
			snapshot.get("camera_presentation_offset", Vector2.ZERO),
			snapshot.get("camera_presentation_zoom", Vector2.ONE)
		)
	camera.call("set_runtime_map", runtime_map)
	if camera is Node2D and snapshot.has("camera_position"):
		(camera as Node2D).global_position = snapshot.get("camera_position") as Vector2
	if camera is Camera2D and snapshot.has("camera_zoom"):
		(camera as Camera2D).zoom = snapshot.get("camera_zoom") as Vector2
	if camera != null and snapshot.has("camera_target_zoom") and "target_zoom" in camera:
		camera.set("target_zoom", snapshot.get("camera_target_zoom"))
	return {
		"succeeded": true,
		"reason": "",
		"restored_branches": (snapshot.get("branches", []) as Array).size(),
		"missing_branches": [],
		"camera_bound": true,
		"actor_placed": true,
	}


func reset_after_level_return() -> void:
	_triggered = false
	_approach_enter_deferred = false
	_entry_snapshot.clear()
	monitoring = true
	monitorable = true


func is_triggered() -> bool:
	return _triggered


func _capture_origin_state(actor: Node) -> Dictionary:
	var branches: Array[Dictionary] = []
	for branch_path in [
		"/root/GameRoot/World/ProcGenRuntime",
		"/root/GameRoot/World/ConnectedMaps",
	]:
		var branch := get_node_or_null(branch_path)
		if branch == null:
			continue
		branches.append({
			"node": branch,
			"path": branch_path,
			"visible": (branch as CanvasItem).visible if branch is CanvasItem else true,
			"process_mode": branch.process_mode,
		})
	var ui := get_node_or_null("/root/GameRoot/UI")
	var ui_mode: StringName = &"gameplay"
	if ui != null and ui.has_method("get_world_presentation_mode"):
		ui_mode = ui.call("get_world_presentation_mode") as StringName
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	var snapshot := {
		"branches": branches,
		"ui_mode": ui_mode,
		"main_map": _main_map,
		"camera": camera,
	}
	if actor is Node2D:
		snapshot["actor_position"] = (actor as Node2D).global_position
	if camera is Node2D:
		snapshot["camera_position"] = (camera as Node2D).global_position
	if camera is Camera2D:
		snapshot["camera_zoom"] = (camera as Camera2D).zoom
	if camera != null and camera.has_method("has_presentation_framing"):
		snapshot["camera_presentation_framing"] = bool(camera.call("has_presentation_framing"))
	if camera != null and "_presentation_offset" in camera:
		snapshot["camera_presentation_offset"] = camera.get("_presentation_offset")
	if camera != null and "_presentation_zoom" in camera:
		snapshot["camera_presentation_zoom"] = camera.get("_presentation_zoom")
	if camera != null and camera.has_method("get_runtime_map"):
		snapshot["camera_runtime_map"] = camera.call("get_runtime_map")
	if camera != null and "target_zoom" in camera:
		snapshot["camera_target_zoom"] = camera.get("target_zoom")
	return snapshot


func _restore_branch_state(branch_state: Dictionary) -> void:
	var branch: Node = branch_state.get("node") as Node
	if branch == null or not is_instance_valid(branch):
		return
	if branch is CanvasItem:
		(branch as CanvasItem).visible = bool(branch_state.get("visible", true))
	branch.process_mode = int(branch_state.get("process_mode", Node.PROCESS_MODE_INHERIT))


func _restore_failure(reason: String, missing_branches: Array[String] = []) -> Dictionary:
	return {
		"succeeded": false,
		"reason": reason,
		"restored_branches": 0,
		"missing_branches": missing_branches,
		"camera_bound": false,
		"actor_placed": false,
	}


func _set_world_branch_visible(branch: Node, value: bool) -> void:
	if branch == null:
		return
	if branch is CanvasItem:
		(branch as CanvasItem).visible = value
	branch.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED


func _ensure_collision() -> void:
	if get_node_or_null("CollisionShape2D") != null:
		return
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = interaction_distance
	shape.shape = circle
	add_child(shape)


func _ensure_visual() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "IngressMarker"
	_sprite.centered = true
	_sprite.modulate = Color(0.48, 0.70, 0.86, 0.42)
	add_child(_sprite)

	var marker := Polygon2D.new()
	marker.name = "IngressMarkerDiamond"
	marker.color = Color(0.48, 0.70, 0.86, 0.28)
	marker.polygon = PackedVector2Array([
		Vector2(-28, 0),
		Vector2(0, -16),
		Vector2(28, 0),
		Vector2(0, 16),
	])
	add_child(marker)


func _observe(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
