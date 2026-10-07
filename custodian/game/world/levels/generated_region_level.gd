class_name GeneratedRegionLevel
extends Node2D

const PROCGEN_MAP_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")

var _map: Node
var _spawn_positions: Dictionary = {}
var _generation_identity: Dictionary = {}


func prepare_generated_region(request: Dictionary) -> Dictionary:
	var scene_path := str(request.get("scene_path", ""))
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return _failure("generated-region scene could not be loaded: %s" % scene_path)
	var instance := scene.instantiate()
	if instance == null or not instance is PROCGEN_MAP_SCRIPT:
		if instance != null:
			instance.free()
		return _failure("generated-region scene must instantiate ProcGenTilemap")
	_map = instance
	var map := _map
	var procgen: Node = map.get("procgen_node") as Node
	if procgen == null:
		return _discard_map("generated-region map has no ProcGen owner")
	var seed_value := int(request.get("seed", 0))
	var map_size: Array = request.get("map_size", [128, 128])	
	procgen.set("auto_generate_on_ready", false)
	procgen.set("generate_seed", false)
	procgen.set("seed", seed_value)
	procgen.set("map_size", Vector2i(int(map_size[0]), int(map_size[1])))
	procgen.set("room_amount", int(request.get("room_count", 12)))
	map.set("generation_output_enabled", true)
	map.set("generation_evaluation_mode", false)
	map.call("set_seed", seed_value)
	var profile_value: Variant = request.get("profile", {})
	if profile_value is Dictionary and not (profile_value as Dictionary).is_empty():
		map.call("apply_planet_world_profile", profile_value)
	add_child(map)
	if not map.is_node_ready():
		await map.ready
	if not map.has_signal("level_data_ready"):
		return _discard_map("generated-region map has no level_data_ready signal")
	var dependency_failure := _generation_dependency_failure(map)
	if not dependency_failure.is_empty():
		return _discard_map(dependency_failure)
	var level_data: Dictionary = await _await_generation(map)
	if level_data.is_empty():
		return _discard_map("generated-region generation returned empty level data")
	var spawn_ids: Array = request.get("spawns", [])
	if spawn_ids.is_empty():
		return _discard_map("generated-region request declares no named spawns")
	var tilemap := map as Node
	var spawn_cell: Vector2i = tilemap.call("get_player_spawn")
	var component: Dictionary = tilemap.call("get_main_playable_component")
	if not component.has(spawn_cell) \
			or not bool(tilemap.call("is_valid_spawn_cell", spawn_cell)) \
			or not bool(tilemap.call("is_runtime_navigation_walkable", spawn_cell)):
		return _discard_map("generated-region primary spawn is not in the valid main playable component")
	var floor_layer: TileMapLayer = tilemap.call("get_floor_tilemap") as TileMapLayer
	if floor_layer == null:
		return _discard_map("generated-region map has no floor layer")
	var spawn_position := floor_layer.to_global(floor_layer.map_to_local(spawn_cell))
	for spawn_value: Variant in spawn_ids:
		var spawn_id := StringName(str(spawn_value))
		if spawn_id.is_empty() or _spawn_positions.has(spawn_id):
			return _discard_map("generated-region spawn IDs must be unique and non-empty")
		_spawn_positions[spawn_id] = spawn_position
	_generation_identity = {
		"profile_id": str(request.get("profile_id", "")),
		"seed": seed_value,
		"map_size": [int(map_size[0]), int(map_size[1])],
		"room_count": int(request.get("room_count", 12)),
	}
	return {"succeeded": true, "level_data": level_data, "identity": _generation_identity.duplicate(true)}


func has_spawn(spawn_id: StringName) -> bool:
	return _spawn_positions.has(spawn_id)


func get_spawn_position(spawn_id: StringName) -> Vector2:
	return _spawn_positions.get(spawn_id, global_position) as Vector2


func activate_route_node(actor: Node, spawn_id: StringName) -> bool:
	if not (actor is Node2D) or not has_spawn(spawn_id):
		return false
	(actor as Node2D).global_position = get_spawn_position(spawn_id)
	return refresh_route_camera(actor)


func refresh_route_camera(_actor: Node) -> bool:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null or not camera.has_method("set_runtime_map") or _map == null:
		return false
	camera.call("set_runtime_map", _map)
	return true


func capture_route_state() -> Dictionary:
	return {"generated_region": _generation_identity.duplicate(true)}


func can_restore_route_state(state: Dictionary) -> bool:
	var identity: Variant = state.get("generated_region", {})
	return identity is Dictionary and (identity as Dictionary) == _generation_identity


func restore_route_state(state: Dictionary) -> bool:
	return can_restore_route_state(state)


func _generation_dependency_failure(map: Node) -> String:
	if not bool(map.get("generation_output_enabled")):
		return "generated-region map has generation output disabled"
	if map.get("procgen_node") == null:
		return "generated-region map has no ProcGen owner"
	if map.call("get_floor_tilemap") == null:
		return "generated-region map has no floor TileMapLayer"
	if map.call("get_walls_tilemap") == null:
		return "generated-region map has no wall TileMapLayer"
	return ""


func _await_generation(map: Node) -> Dictionary:
	map.call_deferred("generate")
	var level_data: Dictionary = await Signal(map, "level_data_ready")
	return level_data


func _discard_map(reason: String) -> Dictionary:
	if _map != null and is_instance_valid(_map):
		_map.queue_free()
	_map = null
	_spawn_positions.clear()
	_generation_identity.clear()
	return _failure(reason)


func _failure(reason: String) -> Dictionary:
	return {"succeeded": false, "reason": reason}
