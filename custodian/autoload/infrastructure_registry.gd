extends Node

signal structure_registered(structure_id: StringName, instance: Node)
signal structure_unregistered(structure_id: StringName, instance: Node)
signal service_output_changed(service_id: StringName, output: float)
signal infrastructure_snapshot_changed(snapshot: Array[Dictionary])

const SAVE_SCHEMA := "custodian.infrastructure_state.v1"

var _structures: Dictionary = {}
var _next_instance_index: int = 1


func register_structure(structure: Node) -> StringName:
	if structure == null or not is_instance_valid(structure):
		return &""
	var instance_id := StringName(str(structure.get("infrastructure_instance_id")))
	if instance_id.is_empty():
		instance_id = _allocate_instance_id(structure)
		structure.set("infrastructure_instance_id", instance_id)
	var key := String(instance_id)
	var existing: Node = _structures.get(key)
	if existing != null and is_instance_valid(existing) and existing != structure:
		push_error("[InfrastructureRegistry] Duplicate instance id: %s" % key)
		return &""
	_structures[key] = structure
	structure_registered.emit(instance_id, structure)
	_emit_snapshot_changed()
	return instance_id


func unregister_structure(structure: Node) -> void:
	if structure == null:
		return
	var instance_id := StringName(str(structure.get("infrastructure_instance_id")))
	if instance_id.is_empty():
		return
	var key := String(instance_id)
	if _structures.get(key) != structure:
		return
	_structures.erase(key)
	structure_unregistered.emit(instance_id, structure)
	_emit_snapshot_changed()


func get_structure(instance_id: StringName) -> Node:
	_prune_invalid()
	return _structures.get(String(instance_id))


func get_structure_snapshot() -> Array[Dictionary]:
	_prune_invalid()
	var snapshot: Array[Dictionary] = []
	for key in _structures.keys():
		var structure: Node = _structures[key]
		if structure.has_method("capture_infrastructure_state"):
			snapshot.append(structure.call("capture_infrastructure_state"))
	snapshot.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("instance_id", "")) < String(b.get("instance_id", ""))
	)
	return snapshot


func has_service(service_id: StringName) -> bool:
	_prune_invalid()
	for structure in _structures.values():
		if structure.has_method("has_infrastructure_service") \
		and bool(structure.call("has_infrastructure_service", service_id)):
			return true
	return false


func get_service_output(service_id: StringName) -> float:
	_prune_invalid()
	var output := 0.0
	for structure in _structures.values():
		if structure.has_method("get_infrastructure_service_output"):
			output += float(structure.call("get_infrastructure_service_output", service_id))
	return output


func notify_structure_changed(service_ids: Array = []) -> void:
	for service_id_variant in service_ids:
		var service_id := StringName(str(service_id_variant))
		service_output_changed.emit(service_id, get_service_output(service_id))
	_emit_snapshot_changed()


func capture_state() -> Dictionary:
	var state := {
		"schema": SAVE_SCHEMA,
		"next_instance_index": _next_instance_index,
		"structures": get_structure_snapshot(),
	}
	var power_grid := get_node_or_null("/root/GameRoot/Power")
	if power_grid != null and power_grid.has_method("capture_grid_state"):
		state["power_grid"] = power_grid.call("capture_grid_state")
	return state


func restore_state(state: Dictionary, parent: Node, clear_existing: bool = true) -> Dictionary:
	var result := {"restored": 0, "errors": PackedStringArray()}
	if str(state.get("schema", "")) != SAVE_SCHEMA:
		result.errors.append("unsupported_schema")
		return result
	if parent == null:
		result.errors.append("missing_parent")
		return result
	if clear_existing:
		for structure in _structures.values().duplicate():
			if is_instance_valid(structure) and bool(structure.get("registry_persistent")):
				var owner: Node = structure.get_parent()
				if owner != null:
					owner.remove_child(structure)
				structure.queue_free()
		_structures.clear()
	_next_instance_index = maxi(1, int(state.get("next_instance_index", 1)))
	var structures: Array = state.get("structures", []) if state.get("structures", []) is Array else []
	for structure_variant in structures:
		if not (structure_variant is Dictionary):
			continue
		var structure_state: Dictionary = structure_variant
		var scene_path := str(structure_state.get("scene_path", ""))
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
			result.errors.append("missing_scene:%s" % scene_path)
			continue
		var scene := load(scene_path) as PackedScene
		var instance := scene.instantiate()
		if instance == null or not instance.has_method("prepare_infrastructure_restore"):
			if instance != null:
				instance.free()
			result.errors.append("invalid_scene:%s" % scene_path)
			continue
		instance.call("prepare_infrastructure_restore", structure_state)
		parent.add_child(instance)
		if instance.has_method("complete_infrastructure_restore"):
			instance.call("complete_infrastructure_restore")
		result.restored = int(result.restored) + 1
	var power_grid_state: Dictionary = state.get("power_grid", {}) if state.get("power_grid", {}) is Dictionary else {}
	var power_grid := get_node_or_null("/root/GameRoot/Power")
	if power_grid != null and power_grid.has_method("restore_grid_state") and not power_grid_state.is_empty():
		power_grid.call("restore_grid_state", power_grid_state)
	_emit_snapshot_changed()
	return result


func clear_runtime_state() -> void:
	_structures.clear()
	_next_instance_index = 1
	_emit_snapshot_changed()


func _allocate_instance_id(structure: Node) -> StringName:
	var structure_id := "structure"
	if structure.has_method("get_structure_id"):
		structure_id = String(structure.call("get_structure_id"))
	while true:
		var candidate := "%s_%03d" % [structure_id, _next_instance_index]
		_next_instance_index += 1
		if not _structures.has(candidate):
			return StringName(candidate)
	return &""


func _prune_invalid() -> void:
	for key in _structures.keys():
		var structure: Node = _structures[key]
		if structure == null or not is_instance_valid(structure):
			_structures.erase(key)


func _emit_snapshot_changed() -> void:
	var snapshot := get_structure_snapshot()
	infrastructure_snapshot_changed.emit(snapshot)
	var under_construction := 0
	for entry in snapshot:
		if String(entry.get("construction_state", "")) in ["foundation", "under_construction", "commissioning"]:
			under_construction += 1
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("set_gauge"):
		observatory.call("set_gauge", &"infrastructure_structure_count", snapshot.size())
		observatory.call("set_gauge", &"infrastructure_under_construction_count", under_construction)
