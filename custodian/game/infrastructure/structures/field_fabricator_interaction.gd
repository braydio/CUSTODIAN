class_name FieldFabricatorInteraction
extends Node2D

@export var interaction_distance := 88.0


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_prompt() -> String:
	var prompt := "ACCESS FIELD FABRICATOR (%s)" % _get_interact_prompt_key()
	if _get_service_output() <= 0.0:
		prompt += " // OFFLINE"
	return prompt


func get_interaction_text() -> String:
	return get_interaction_prompt()


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(_actor: Node) -> void:
	var ui := get_node_or_null("/root/GameRoot/UI")
	if ui != null and ui.has_method("open_fabricator_terminal"):
		ui.call("open_fabricator_terminal")


func _get_service_output() -> float:
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	if registry == null or not registry.has_method("get_service_output"):
		return 0.0
	return float(registry.call("get_service_output", &"FABRICATION"))


func _get_interact_prompt_key() -> String:
	if not InputMap.has_action(&"interact"):
		return "E"
	for event in InputMap.action_get_events(&"interact"):
		if event is InputEventKey:
			var key := event as InputEventKey
			return OS.get_keycode_string(
				key.physical_keycode if key.physical_keycode != 0 else key.keycode
			)
	return "E"
