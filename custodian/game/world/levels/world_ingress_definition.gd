class_name WorldIngressDefinition
extends RefCounted


var ingress_id: StringName = &""
var prompt_text: String = ""
var target_spawn_id: StringName = &""
var interaction_distance: float = 92.0
var placement: Dictionary = {}


func configure_from_dictionary(data: Dictionary) -> void:
	ingress_id = StringName(str(data.get("ingress_id", "")))
	prompt_text = str(data.get("prompt_text", ""))
	target_spawn_id = StringName(str(data.get("target_spawn_id", "")))
	interaction_distance = float(data.get("interaction_distance", 92.0))
	var placement_value: Variant = data.get("placement", {})
	placement = (placement_value as Dictionary).duplicate(true) if placement_value is Dictionary else {}


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if ingress_id.is_empty():
		errors.append("ingress_id is required")
	if prompt_text.strip_edges().is_empty():
		errors.append("prompt_text is required")
	if target_spawn_id.is_empty():
		errors.append("target_spawn_id is required")
	if interaction_distance <= 0.0:
		errors.append("interaction_distance must be greater than zero")
	return errors
