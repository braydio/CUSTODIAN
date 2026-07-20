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
		if definition.ingress == null or definition.ingress.target_spawn_id.is_empty():
			errors.append("%s has no named ingress spawn" % level_id)
			continue
		var scene := load(definition.call("get_entry_scene_path")) as PackedScene
		if scene == null:
			errors.append("%s entry scene does not load" % level_id)
			continue
		var level := scene.instantiate()
		root.add_child(level)
		await process_frame
		for method_name in ["configure_connection", "get_entry_position", "enter_from_main", "get_camera_bounds", "get_authoring_marker_state"]:
			if not level.has_method(method_name): errors.append("%s missing %s" % [level_id, method_name])
		if level.get_node_or_null("Collision/PathBoundaryCollision") == null:
			errors.append("%s missing Collision/PathBoundaryCollision" % level_id)
		if level.find_child(String(definition.ingress.target_spawn_id), true, false) == null:
			errors.append("%s missing spawn %s" % [level_id, definition.ingress.target_spawn_id])
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
