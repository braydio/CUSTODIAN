extends Node
class_name EnemyLootCarrier

const STOLEN_RESOURCE_PICKUP_SCENE := preload("res://game/actors/items/stolen_resource_pickup.tscn")

var carried_resources: Dictionary = {}


func is_carrying_loot() -> bool:
	return not carried_resources.is_empty()


func set_payload(payload: Dictionary) -> void:
	carried_resources = _clean_payload(payload)


func clear_payload() -> void:
	carried_resources.clear()


func drop_payload(owner_enemy: Node) -> void:
	if carried_resources.is_empty() or owner_enemy == null:
		return
	var parent := owner_enemy.get_parent()
	if parent == null:
		parent = owner_enemy.get_tree().current_scene
	if parent == null:
		return
	var pickup := STOLEN_RESOURCE_PICKUP_SCENE.instantiate()
	if pickup == null:
		return
	if pickup.has_method("set_payload"):
		pickup.call("set_payload", carried_resources)
	if pickup is Node2D and owner_enemy is Node2D:
		(pickup as Node2D).global_position = (owner_enemy as Node2D).global_position
	parent.add_child(pickup)
	clear_payload()


func _clean_payload(payload: Dictionary) -> Dictionary:
	var out := {}
	for key in payload.keys():
		var amount := int(payload[key])
		if amount > 0:
			out[StringName(str(key))] = amount
	return out
