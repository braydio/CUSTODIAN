extends Area2D
class_name VaultStorage

@export var storage_id: StringName = &"vault_storage_01"
@export var display_name: String = "Vault Storage"
@export var can_be_opened_by_enemies: bool = true
@export var can_be_damaged_by_enemies: bool = true
@export var open_seconds: float = 1.4
@export var starts_locked: bool = false
@export var lock_difficulty: float = 0.0
@export var max_integrity: int = 100
@export var damaged_integrity_ratio: float = 0.5
@export_file("*.png") var empty_texture_path: String = "res://content/sprites/environment/props/vault_storage/runtime/vault_storage__chest_small__empty__1f__160x128.png"
@export_file("*.png") var stored_texture_path: String = "res://content/sprites/environment/props/vault_storage/runtime/vault_storage__chest_small__stored__1f__160x128.png"
@export_file("*.png") var open_texture_path: String = "res://content/sprites/environment/props/vault_storage/runtime/vault_storage__chest_small__open__1f__160x128.png"
@export_file("*.png") var damaged_texture_path: String = "res://content/sprites/environment/props/vault_storage/runtime/vault_storage__chest_small__damaged__1f__160x128.png"
@export var starting_resources: Dictionary = {
	&"ruin_scrap": 40,
	&"structural_alloy": 6,
	&"power_components": 2,
}

var resources: Dictionary = {}
var integrity: int = 100
var opened: bool = false

signal opened_by_enemy(enemy: Node)
signal resources_removed(resources: Dictionary)
signal resources_added(resources: Dictionary)
signal damaged(amount: int, source: Node)
signal destroyed(source: Node)


func _ready() -> void:
	add_to_group("vault_storage")
	add_to_group("enemy_objective")
	integrity = max_integrity
	if resources.is_empty():
		add_resources(starting_resources)
	var manager := get_node_or_null("/root/VaultManager")
	if manager != null and manager.has_method("register_storage"):
		manager.call("register_storage", self)
	_update_visual_state()


func _exit_tree() -> void:
	var manager := get_node_or_null("/root/VaultManager")
	if manager != null and manager.has_method("unregister_storage"):
		manager.call("unregister_storage", self)


func mark_opened_by_enemy(enemy: Node) -> void:
	opened = true
	opened_by_enemy.emit(enemy)
	_update_visual_state()


func has_resources() -> bool:
	for value in resources.values():
		if int(value) > 0:
			return true
	return false


func is_destroyed() -> bool:
	return integrity <= 0


func get_resource_score() -> int:
	var total := 0
	for value in resources.values():
		total += maxi(0, int(value))
	return total


func remove_resources(max_types: int, max_units: int) -> Dictionary:
	if is_destroyed():
		return {}
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
	_update_visual_state()
	return removed


func add_resources(payload: Dictionary) -> void:
	if is_destroyed():
		return
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
	_update_visual_state()


func apply_enemy_damage(amount: int, source: Node = null) -> bool:
	if not can_be_damaged_by_enemies or is_destroyed():
		return false
	var applied: int = maxi(0, amount)
	if applied <= 0:
		return false
	integrity = maxi(0, integrity - applied)
	damaged.emit(applied, source)
	if integrity <= 0:
		resources.clear()
		destroyed.emit(source)
	_update_visual_state()
	return true


func get_debug_snapshot() -> Dictionary:
	return {
		"id": String(storage_id),
		"display_name": display_name,
		"resources": resources.duplicate(true),
		"position": global_position,
		"can_be_opened_by_enemies": can_be_opened_by_enemies,
		"can_be_damaged_by_enemies": can_be_damaged_by_enemies,
		"integrity": integrity,
		"max_integrity": max_integrity,
		"opened": opened,
		"destroyed": is_destroyed(),
	}


func _update_visual_state() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var texture_path := _get_visual_texture_path()
	if texture_path.is_empty():
		return
	var texture := load(texture_path) as Texture2D
	if texture != null:
		sprite.texture = texture


func _get_visual_texture_path() -> String:
	if is_destroyed() or integrity <= int(round(float(max_integrity) * damaged_integrity_ratio)):
		return damaged_texture_path
	if opened:
		return open_texture_path
	if has_resources():
		return stored_texture_path
	return empty_texture_path
