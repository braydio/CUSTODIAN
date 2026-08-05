extends Area2D
class_name StolenResourcePickup

@export var pickup_label: String = "Recovered Vault Resources"
var payload: Dictionary = {}


func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)


func set_payload(resources: Dictionary) -> void:
	payload.clear()
	for key in resources.keys():
		var amount := int(resources[key])
		if amount > 0:
			payload[StringName(str(key))] = amount


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var manager := get_node_or_null("/root/VaultManager")
	if manager != null and manager.has_method("recover_resources"):
		manager.call("recover_resources", payload)
	var parts: PackedStringArray = []
	var total := 0
	for resource_id in payload.keys():
		var amount := int(payload[resource_id])
		parts.append("%s ×%d" % [str(resource_id).capitalize(), amount])
		total += amount
	_show_loot_toast(&"vault_resources", "Vault Resources Recovered", total, Color(0.86, 0.72, 1.0, 1.0), null, " • ".join(parts))
	queue_free()


func _show_loot_toast(item_id: StringName, display_name: String, amount: int, accent: Color, icon: Texture2D = null, detail: String = "") -> void:
	var queue := get_tree().get_first_node_in_group("loot_toast_queue")
	if queue != null:
		queue.call("push_pickup", item_id, display_name, amount, accent, icon, detail)


func get_debug_snapshot() -> Dictionary:
	return {
		"payload": payload.duplicate(true),
		"position": global_position,
	}
