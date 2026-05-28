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
	queue_free()


func get_debug_snapshot() -> Dictionary:
	return {
		"payload": payload.duplicate(true),
		"position": global_position,
	}
