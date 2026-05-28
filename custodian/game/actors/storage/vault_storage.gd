extends Area2D
class_name VaultStorage

@export var storage_id: StringName = &"vault_storage_01"
@export var display_name: String = "Vault Storage"
@export var can_be_opened_by_enemies: bool = true
@export var open_seconds: float = 1.4
@export var starts_locked: bool = false
@export var lock_difficulty: float = 0.0
@export var starting_resources: Dictionary = {
	&"ruin_scrap": 40,
	&"structural_alloy": 6,
	&"power_components": 2,
}

var resources: Dictionary = {}

signal opened_by_enemy(enemy: Node)
signal resources_removed(resources: Dictionary)
signal resources_added(resources: Dictionary)


func _ready() -> void:
	add_to_group("vault_storage")
	add_to_group("enemy_objective")
	if resources.is_empty():
		add_resources(starting_resources)
	var manager := get_node_or_null("/root/VaultManager")
	if manager != null and manager.has_method("register_storage"):
		manager.call("register_storage", self)


func _exit_tree() -> void:
	var manager := get_node_or_null("/root/VaultManager")
	if manager != null and manager.has_method("unregister_storage"):
		manager.call("unregister_storage", self)


func mark_opened_by_enemy(enemy: Node) -> void:
	opened_by_enemy.emit(enemy)


func has_resources() -> bool:
	for value in resources.values():
		if int(value) > 0:
			return true
	return false


func get_resource_score() -> int:
	var total := 0
	for value in resources.values():
		total += maxi(0, int(value))
	return total


func remove_resources(max_types: int, max_units: int) -> Dictionary:
	var available: Array[Dictionary] = []
	for key in resources.keys():
		var amount := int(resources[key])
		if amount > 0:
			available.append({"id": StringName(str(key)), "amount": amount})
	available.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("amount", 0)) > int(b.get("amount", 0))
	)

	var removed := {}
	var remaining_units := maxi(0, max_units)
	var types_taken := 0
	for entry in available:
		if remaining_units <= 0 or types_taken >= max_types:
			break
		var resource_id := StringName(str(entry["id"]))
		var take_amount: int = mini(int(entry["amount"]), remaining_units)
		if take_amount <= 0:
			continue
		removed[resource_id] = take_amount
		resources[resource_id] = int(resources.get(resource_id, 0)) - take_amount
		if int(resources[resource_id]) <= 0:
			resources.erase(resource_id)
		remaining_units -= take_amount
		types_taken += 1

	if not removed.is_empty():
		resources_removed.emit(removed.duplicate(true))
	return removed


func add_resources(payload: Dictionary) -> void:
	var added := {}
	for key in payload.keys():
		var amount := int(payload[key])
		if amount <= 0:
			continue
		var resource_id := StringName(str(key))
		resources[resource_id] = int(resources.get(resource_id, 0)) + amount
		added[resource_id] = amount
	if not added.is_empty():
		resources_added.emit(added.duplicate(true))


func get_debug_snapshot() -> Dictionary:
	return {
		"id": String(storage_id),
		"display_name": display_name,
		"resources": resources.duplicate(true),
		"position": global_position,
		"can_be_opened_by_enemies": can_be_opened_by_enemies,
	}
