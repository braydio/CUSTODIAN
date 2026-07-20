class_name LevelLoader
extends Node

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")

signal level_entered(level_id: StringName, instance: Node)
signal level_entry_failed(level_id: StringName, reason: String)
signal level_returned(level_id: StringName)
signal level_return_failed(level_id: StringName, reason: String, details: Dictionary)

@export_file("*.json") var registry_index_path: String = LEVEL_REGISTRY_SCRIPT.DEFAULT_INDEX_PATH

var _registry: RefCounted
var _active_level_id: StringName = &""
var _active_level_instance: Node
var _active_level_context: Dictionary = {}


func _ready() -> void:
	add_to_group("level_loader")
	ensure_registry()


func ensure_registry() -> bool:
	if _registry != null:
		return true
	_registry = LEVEL_REGISTRY_SCRIPT.new()
	if _registry.load_index(registry_index_path):
		return true
	var reason := "; ".join(_registry.get_errors())
	push_error("[LevelLoader] registry load failed: %s" % reason)
	return false


func get_definition(level_id: StringName) -> RefCounted:
	if not ensure_registry():
		return null
	return _registry.get_level(level_id)


func enter_level(level_id: StringName, actor: Node, context: Dictionary = {}) -> Node:
	if get_active_level_instance() != null:
		return _fail(level_id, "another level is already active: %s" % _active_level_id)
	var definition := get_definition(level_id)
	if definition == null:
		return _fail(level_id, "level is not registered")
	var entry_path: String = definition.call("get_entry_scene_path")
	var entry_scene := load(entry_path) as PackedScene
	if entry_scene == null:
		return _fail(level_id, "entry scene could not be loaded: %s" % entry_path)
	var instance := entry_scene.instantiate()
	if instance == null:
		return _fail(level_id, "entry scene could not be instantiated: %s" % entry_path)
	var parent: Node = context.get("parent") as Node
	if parent == null:
		parent = get_parent()
	if parent == null:
		instance.queue_free()
		return _fail(level_id, "no parent is available for the level entry scene")
	parent.add_child(instance)
	var entry_position: Variant = context.get("entry_world_position", context.get("return_world_position"))
	if instance is Node2D and entry_position is Vector2:
		(instance as Node2D).global_position = entry_position
	var main_map: Node = context.get("main_map") as Node
	var return_position: Vector2 = context.get("return_world_position", Vector2.ZERO)
	if instance.has_method("configure_connection"):
		instance.call("configure_connection", main_map, return_position)
	var runtime_context := context.duplicate(false)
	runtime_context["level_id"] = level_id
	runtime_context["level_loader"] = self
	runtime_context["presentation_profile"] = definition.call("get_presentation_profile")
	runtime_context["lifecycle"] = definition.call("get_lifecycle")
	if instance.has_method("configure_level_runtime"):
		instance.call("configure_level_runtime", runtime_context)
	var target_spawn_id := _resolve_target_spawn_id(definition, context)
	var actor_position := Vector2.ZERO
	var actor_had_position := actor is Node2D
	if actor_had_position:
		actor_position = (actor as Node2D).global_position
	if not _enter_actor_at_spawn(instance, actor, target_spawn_id):
		_deactivate_instance_immediately(instance)
		if actor_had_position and is_instance_valid(actor):
			(actor as Node2D).global_position = actor_position
		instance.queue_free()
		return _fail(
			level_id,
			"target spawn could not be resolved: %s" % String(target_spawn_id)
		)
	_active_level_id = level_id
	_active_level_instance = instance
	_active_level_context = runtime_context
	level_entered.emit(level_id, instance)
	return instance


func get_active_level_id() -> StringName:
	get_active_level_instance()
	return _active_level_id


func get_active_level_instance() -> Node:
	if is_instance_valid(_active_level_instance):
		return _active_level_instance
	if _active_level_instance != null or not _active_level_id.is_empty():
		clear_active_level()
	return null


func adopt_active_level(level_id: StringName, instance: Node) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	_active_level_id = level_id
	_active_level_instance = instance
	_active_level_context = {}
	level_entered.emit(level_id, instance)


func get_active_level_context() -> Dictionary:
	return _active_level_context.duplicate(false)


func complete_return_to_world(instance: Node, actor: Node) -> bool:
	if instance == null or instance != get_active_level_instance():
		push_error("[LevelLoader] return rejected for a non-active level instance")
		return false
	var completed_level_id := _active_level_id
	var context := _active_level_context.duplicate(false)
	var activation_state := _capture_instance_activation_state(instance)
	_deactivate_instance_immediately(instance)
	var origin_ingress: Node = context.get("origin_ingress") as Node
	var source_state: Dictionary = context.get("source_state", {}) as Dictionary
	var restore_result: Dictionary
	if origin_ingress != null and is_instance_valid(origin_ingress) \
	and origin_ingress.has_method("restore_world_origin"):
		var result_variant: Variant = origin_ingress.call("restore_world_origin", actor, source_state)
		if result_variant is Dictionary:
			restore_result = result_variant as Dictionary
		else:
			restore_result = _restore_failure("origin ingress returned no restoration result")
	else:
		restore_result = _restore_origin_without_ingress(actor, context, source_state)
	if not bool(restore_result.get("succeeded", false)):
		_reactivate_instance(instance, activation_state)
		var reason := str(restore_result.get("reason", "world origin restoration failed"))
		push_error("[LevelLoader] return failed for %s: %s" % [completed_level_id, reason])
		level_return_failed.emit(completed_level_id, reason, restore_result.duplicate(true))
		return false
	if origin_ingress != null and is_instance_valid(origin_ingress) \
	and origin_ingress.has_method("reset_after_level_return"):
		origin_ingress.call("reset_after_level_return")
	clear_active_level(instance)
	_release_level_instance(instance, context.get("lifecycle", {}) as Dictionary, true)
	level_returned.emit(completed_level_id)
	return true


func clear_active_level(expected_instance: Node = null) -> bool:
	if expected_instance != null and expected_instance != _active_level_instance:
		return false
	_active_level_id = &""
	_active_level_instance = null
	_active_level_context.clear()
	return true


func release_level_instance(instance: Node, lifecycle: Dictionary, route_ending := false) -> void:
	_release_level_instance(instance, lifecycle, route_ending)


func _release_level_instance(instance: Node, lifecycle: Dictionary, route_ending: bool) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	var cache_policy := StringName(str(lifecycle.get("cache_policy", "destroy_on_exit")))
	if cache_policy == &"keep_during_route" and not route_ending:
		if instance is CanvasItem:
			(instance as CanvasItem).visible = false
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		return
	instance.queue_free()


func _capture_instance_activation_state(instance: Node) -> Dictionary:
	return {
		"visible": (instance as CanvasItem).visible if instance is CanvasItem else true,
		"process_mode": instance.process_mode,
	}


func _deactivate_instance_immediately(instance: Node) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	if instance is CanvasItem:
		(instance as CanvasItem).visible = false
	instance.process_mode = Node.PROCESS_MODE_DISABLED


func _reactivate_instance(instance: Node, activation_state: Dictionary) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	if instance is CanvasItem:
		(instance as CanvasItem).visible = bool(activation_state.get("visible", true))
	instance.process_mode = int(activation_state.get("process_mode", Node.PROCESS_MODE_INHERIT))


func _restore_origin_without_ingress(actor: Node, context: Dictionary, source_state: Dictionary) -> Dictionary:
	var missing_branches: Array[String] = []
	for branch_state: Variant in source_state.get("branches", []):
		if not (branch_state is Dictionary):
			continue
		var branch_value: Variant = (branch_state as Dictionary).get("node")
		if branch_value == null or not is_instance_valid(branch_value):
			missing_branches.append(str((branch_state as Dictionary).get("path", "unknown_branch")))
	var main_map_value: Variant = context.get("main_map")
	var main_map: Node = main_map_value as Node if main_map_value != null and is_instance_valid(main_map_value) else null
	if main_map == null:
		return _restore_failure("main map is unavailable", missing_branches)
	if not missing_branches.is_empty():
		return _restore_failure("one or more origin branches are unavailable", missing_branches)
	if not (actor is Node2D) or not source_state.has("actor_position"):
		return _restore_failure("actor return position is unavailable")
	var camera_value: Variant = source_state.get("camera")
	var camera: Node = camera_value as Node if camera_value != null and is_instance_valid(camera_value) else null
	if camera == null:
		camera = get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null or not is_instance_valid(camera) or not camera.has_method("set_runtime_map"):
		return _restore_failure("camera runtime-map binding is unavailable")
	var runtime_map_value: Variant = source_state.get("camera_runtime_map")
	var runtime_map: Node = runtime_map_value as Node if runtime_map_value != null and is_instance_valid(runtime_map_value) else null
	if runtime_map == null:
		runtime_map = main_map
	if runtime_map == null or not is_instance_valid(runtime_map):
		return _restore_failure("camera origin map is unavailable")
	for branch_state: Variant in source_state.get("branches", []):
		if not (branch_state is Dictionary):
			continue
		var branch: Node = (branch_state as Dictionary).get("node") as Node
		if branch == null or not is_instance_valid(branch):
			continue
		if branch is CanvasItem:
			(branch as CanvasItem).visible = bool((branch_state as Dictionary).get("visible", true))
		branch.process_mode = int((branch_state as Dictionary).get("process_mode", Node.PROCESS_MODE_INHERIT))
	if source_state.is_empty() and main_map != null:
		if main_map is CanvasItem:
			(main_map as CanvasItem).visible = true
		main_map.process_mode = Node.PROCESS_MODE_INHERIT
	(actor as Node2D).global_position = source_state.get(
		"actor_position",
		context.get("return_world_position", Vector2.ZERO)
	) as Vector2
	if camera != null and camera.has_method("set_presentation_framing"):
		camera.call("set_presentation_framing", false)
	camera.call("set_runtime_map", runtime_map)
	if camera is Node2D and source_state.has("camera_position"):
		(camera as Node2D).global_position = source_state.get("camera_position") as Vector2
	if camera is Camera2D and source_state.has("camera_zoom"):
		(camera as Camera2D).zoom = source_state.get("camera_zoom") as Vector2
	if source_state.has("camera_target_zoom") and "target_zoom" in camera:
		camera.set("target_zoom", source_state.get("camera_target_zoom"))
	var ui := get_node_or_null("/root/GameRoot/UI")
	if ui != null and ui.has_method("set_world_presentation_mode"):
		ui.call("set_world_presentation_mode", source_state.get("ui_mode", &"gameplay"))
	if actor != null and actor.has_method("set_vista_presentation_mode"):
		actor.call("set_vista_presentation_mode", source_state.get("ui_mode", &"gameplay") != &"gameplay")
	return {
		"succeeded": true,
		"reason": "",
		"restored_branches": (source_state.get("branches", []) as Array).size(),
		"missing_branches": [],
		"camera_bound": true,
		"actor_placed": true,
	}


func _restore_failure(reason: String, missing_branches: Array[String] = []) -> Dictionary:
	return {
		"succeeded": false,
		"reason": reason,
		"restored_branches": 0,
		"missing_branches": missing_branches,
		"camera_bound": false,
		"actor_placed": false,
	}


func _resolve_target_spawn_id(definition: RefCounted, context: Dictionary) -> StringName:
	var requested := StringName(str(context.get("target_spawn_id", "")))
	if not requested.is_empty():
		return requested
	var ingress: Variant = definition.get("ingress")
	if ingress != null:
		return ingress.target_spawn_id
	return &""


func _enter_actor_at_spawn(instance: Node, actor: Node, spawn_id: StringName) -> bool:
	if actor == null:
		return true
	if not spawn_id.is_empty() and instance.has_method("enter_from_main_at_spawn"):
		return bool(instance.call("enter_from_main_at_spawn", actor, spawn_id))
	var spawn: Node2D = null
	if not spawn_id.is_empty():
		if instance.has_method("has_spawn") and not bool(instance.call("has_spawn", spawn_id)):
			return false
		spawn = instance.find_child(String(spawn_id), true, false) as Node2D
		if spawn == null or not (actor is Node2D):
			return false
	if instance.has_method("enter_from_main"):
		instance.call("enter_from_main", actor)
	if spawn != null:
		(actor as Node2D).global_position = spawn.global_position
	return spawn_id.is_empty() or spawn != null


func _fail(level_id: StringName, reason: String) -> Node:
	push_error("[LevelLoader] unable to enter %s: %s" % [level_id, reason])
	level_entry_failed.emit(level_id, reason)
	return null
