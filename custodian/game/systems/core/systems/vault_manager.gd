extends Node

const VAULT_STORAGE_SCENE := preload("res://game/actors/storage/vault_storage.tscn")

signal vault_resources_changed(total: Dictionary)
signal storage_opened(storage: Node, enemy: Node)
signal storage_damaged(storage: Node, enemy: Node, amount: int)
signal storage_destroyed(storage: Node, enemy: Node)
signal resources_stolen(enemy: Node, resources: Dictionary)
signal stolen_resources_recovered(resources: Dictionary)
signal stolen_resources_lost(enemy: Node, resources: Dictionary)

@export var create_debug_vault_if_missing: bool = true
@export var debug_vault_offset_from_operator: Vector2 = Vector2(192.0, 96.0)
@export var debug_exit_offset_from_storage: Vector2 = Vector2(320.0, 0.0)

var _storages: Array[Node] = []
var _recent_events: Array[String] = []


func _ready() -> void:
	add_to_group("vault_manager")
	call_deferred("_discover_and_ensure_vault")


func register_storage(storage: Node) -> void:
	if storage == null or _storages.has(storage):
		return
	_storages.append(storage)
	_emit_totals()


func unregister_storage(storage: Node) -> void:
	_storages.erase(storage)
	_emit_totals()


func get_total_resources() -> Dictionary:
	var total := {}
	for storage in _storages:
		if storage == null or not is_instance_valid(storage):
			continue
		var resources: Dictionary = storage.get("resources") if "resources" in storage else {}
		for key in resources.keys():
			var resource_id := StringName(str(key))
			total[resource_id] = int(total.get(resource_id, 0)) + int(resources[key])
	return total


func find_best_storage_for_enemy(enemy: Node) -> Node:
	var best: Node = null
	var best_score := -INF
	var enemy_pos := Vector2.ZERO
	if enemy is Node2D:
		enemy_pos = (enemy as Node2D).global_position
	for storage in _storages:
		if storage == null or not is_instance_valid(storage):
			continue
		if ("can_be_opened_by_enemies" in storage and not bool(storage.get("can_be_opened_by_enemies"))) or not bool(storage.call("has_resources")):
			continue
		var score := float(storage.call("get_resource_score")) - enemy_pos.distance_to((storage as Node2D).global_position) / 32.0
		if score > best_score:
			best_score = score
			best = storage
	return best


func find_best_damageable_storage_for_enemy(enemy: Node) -> Node:
	var best: Node = null
	var best_score := -INF
	var enemy_pos := Vector2.ZERO
	if enemy is Node2D:
		enemy_pos = (enemy as Node2D).global_position
	for storage in _storages:
		if storage == null or not is_instance_valid(storage):
			continue
		if "can_be_damaged_by_enemies" in storage and not bool(storage.get("can_be_damaged_by_enemies")):
			continue
		if storage.has_method("is_destroyed") and bool(storage.call("is_destroyed")):
			continue
		var resource_score := float(storage.call("get_resource_score")) if storage.has_method("get_resource_score") else 0.0
		var integrity_score := float(storage.get("integrity")) if "integrity" in storage else 100.0
		var score := resource_score + integrity_score * 0.25 - enemy_pos.distance_to((storage as Node2D).global_position) / 32.0
		if score > best_score:
			best_score = score
			best = storage
	return best


func steal_from_storage(storage: Node, max_types: int, max_units: int, enemy: Node = null) -> Dictionary:
	if storage == null or not is_instance_valid(storage):
		return {}
	if storage.has_method("mark_opened_by_enemy"):
		storage.call("mark_opened_by_enemy", enemy)
	storage_opened.emit(storage, enemy)
	var stolen: Dictionary = storage.call("remove_resources", max_types, max_units)
	if not stolen.is_empty():
		_record_event("stolen %s by %s" % [_format_resources(stolen), enemy.name if enemy != null else "enemy"])
		resources_stolen.emit(enemy, stolen.duplicate(true))
		_emit_totals()
	return stolen


func damage_storage(storage: Node, amount: int, enemy: Node = null) -> bool:
	if storage == null or not is_instance_valid(storage):
		return false
	if not storage.has_method("apply_enemy_damage"):
		return false
	var was_destroyed := bool(storage.call("is_destroyed")) if storage.has_method("is_destroyed") else false
	var applied := bool(storage.call("apply_enemy_damage", amount, enemy))
	if not applied:
		return false
	_record_event("damaged %s for %d by %s" % [storage.name, amount, enemy.name if enemy != null else "enemy"])
	storage_damaged.emit(storage, enemy, amount)
	var is_destroyed := bool(storage.call("is_destroyed")) if storage.has_method("is_destroyed") else false
	if is_destroyed and not was_destroyed:
		_record_event("destroyed %s by %s" % [storage.name, enemy.name if enemy != null else "enemy"])
		storage_destroyed.emit(storage, enemy)
	_emit_totals()
	return true


func recover_resources(resources: Dictionary) -> void:
	var storage: Node = _get_or_create_recovery_storage()
	if storage == null:
		return
	storage.call("add_resources", resources)
	_record_event("recovered %s" % _format_resources(resources))
	stolen_resources_recovered.emit(resources.duplicate(true))
	_emit_totals()


func commit_lost_resources(enemy: Node, resources: Dictionary) -> void:
	if resources.is_empty():
		return
	_record_event("lost %s via %s" % [_format_resources(resources), enemy.name if enemy != null else "enemy"])
	stolen_resources_lost.emit(enemy, resources.duplicate(true))
	_emit_totals()


func find_nearest_exit(from_position: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for group_name in ["enemy_exit", "vault_exit"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not (node is Node2D):
				continue
			var dist := from_position.distance_to((node as Node2D).global_position)
			if dist < best_dist:
				best_dist = dist
				best = node as Node2D
	return best


func debug_add(resource_id: StringName, amount: int) -> void:
	var storage := _get_or_create_recovery_storage()
	if storage != null:
		storage.call("add_resources", {resource_id: amount})
		_record_event("debug add %s x%d" % [String(resource_id), amount])
		_emit_totals()


func get_debug_snapshot() -> Dictionary:
	var storage_snapshots: Array[Dictionary] = []
	for storage in _storages:
		if storage != null and is_instance_valid(storage):
			storage_snapshots.append(storage.call("get_debug_snapshot"))
	return {
		"total": get_total_resources(),
		"storage_count": storage_snapshots.size(),
		"storages": storage_snapshots,
		"recent_events": _recent_events.duplicate(),
	}


func _discover_and_ensure_vault() -> void:
	for node in get_tree().get_nodes_in_group("vault_storage"):
		if node != null and node.has_method("has_resources"):
			register_storage(node)
	if create_debug_vault_if_missing and _storages.is_empty():
		_create_debug_vault()


func _get_or_create_recovery_storage() -> Node:
	for storage in _storages:
		if storage != null and is_instance_valid(storage):
			return storage
	if create_debug_vault_if_missing:
		_create_debug_vault()
	return _storages[0] if not _storages.is_empty() else null


func _create_debug_vault() -> void:
	var parent := get_node_or_null("/root/GameRoot/World")
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		return
	var storage := VAULT_STORAGE_SCENE.instantiate()
	if storage == null:
		return
	storage.name = "DebugVaultStorage"
	var operator := get_tree().get_first_node_in_group("player") as Node2D
	var base_position := operator.global_position if operator != null else Vector2(512.0, 512.0)
	(storage as Node2D).global_position = base_position + debug_vault_offset_from_operator
	parent.add_child(storage)
	register_storage(storage)
	_create_debug_exit(parent, (storage as Node2D).global_position + debug_exit_offset_from_storage)


func _create_debug_exit(parent: Node, exit_position: Vector2) -> void:
	if find_nearest_exit(exit_position) != null:
		return
	var marker := Marker2D.new()
	marker.name = "DebugEnemyExit"
	marker.global_position = exit_position
	marker.add_to_group("enemy_exit")
	parent.add_child(marker)


func _emit_totals() -> void:
	vault_resources_changed.emit(get_total_resources())


func _record_event(text: String) -> void:
	_recent_events.push_front(text)
	while _recent_events.size() > 8:
		_recent_events.pop_back()


func _format_resources(resources: Dictionary) -> String:
	var parts: Array[String] = []
	for key in resources.keys():
		parts.append("%s:%d" % [StringName(str(key)), int(resources[key])])
	parts.sort()
	return ", ".join(parts)
