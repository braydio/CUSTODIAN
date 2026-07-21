extends SceneTree

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var registry: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
	if not registry.call("load_index"):
		for message in registry.call("get_errors"): errors.append(str(message))
		_finish(errors)
		return
	for level_id: StringName in registry.call("get_level_ids"):
		var definition: RefCounted = registry.call("get_level", level_id)
		if definition.call("get_presentation_profile") not in [&"gameplay", &"vista_approach", &"cinematic"]:
			errors.append("%s has an invalid presentation profile" % level_id)
		var lifecycle: Dictionary = definition.call("get_lifecycle")
		if str(lifecycle.get("cache_policy", "")).is_empty() or str(lifecycle.get("state_policy", "")).is_empty():
			errors.append("%s has an incomplete lifecycle policy" % level_id)
		if definition.has_tag(&"world_ingress") and (definition.ingress == null or definition.ingress.target_spawn_id.is_empty()):
			errors.append("%s world ingress has no named spawn" % level_id)
			continue
		if not definition.has_tag(&"world_ingress") and definition.spawns.is_empty():
			errors.append("%s route node has no declared spawn" % level_id)
			continue
		var scene := load(definition.call("get_entry_scene_path")) as PackedScene
		if scene == null:
			errors.append("%s entry scene does not load" % level_id)
			continue
		var level := scene.instantiate()
		root.add_child(level)
		await process_frame
		for method_name in ["get_entry_position", "get_camera_bounds", "activate_route_node", "capture_route_state", "restore_route_state"]:
			if not level.has_method(method_name): errors.append("%s missing %s" % [level_id, method_name])
		var expected_spawn: StringName = definition.ingress.target_spawn_id if definition.ingress != null else definition.spawns[0]
		if level.find_child(String(expected_spawn), true, false) == null:
			errors.append("%s missing spawn %s" % [level_id, expected_spawn])
		level.queue_free()
		await process_frame
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelRegistryContractSmoke] PASS")
		quit(0)
		return
	for error in errors: push_error("[LevelRegistryContractSmoke] %s" % error)
	quit(1)
