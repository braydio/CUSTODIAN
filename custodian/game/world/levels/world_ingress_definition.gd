class_name WorldIngressDefinition
extends RefCounted


var ingress_id: StringName = &""
var prompt_text: String = ""
var target_spawn_id: StringName = &""
var route_profile: StringName = &""
var site_scene_path: String = ""
var interaction_distance: float = 92.0
var placement: Dictionary = {}


func configure_from_dictionary(data: Dictionary) -> void:
	ingress_id = StringName(str(data.get("ingress_id", "")))
	prompt_text = str(data.get("prompt_text", ""))
	target_spawn_id = StringName(str(data.get("target_spawn_id", "")))
	route_profile = StringName(str(data.get("route_profile", "")))
	site_scene_path = str(data.get("site_scene_path", "")).strip_edges()
	interaction_distance = float(data.get("interaction_distance", 92.0))
	var placement_value: Variant = data.get("placement", {})
	placement = (placement_value as Dictionary).duplicate(true) if placement_value is Dictionary else {}


func validate(require_target_spawn := false) -> PackedStringArray:
	var errors := PackedStringArray()
	if ingress_id.is_empty():
		errors.append("ingress_id is required")
	if prompt_text.strip_edges().is_empty():
		errors.append("prompt_text is required")
	if require_target_spawn and target_spawn_id.is_empty():
		errors.append("target_spawn_id is required")
	if interaction_distance <= 0.0:
		errors.append("interaction_distance must be greater than zero")
	if not site_scene_path.is_empty():
		var resource: Resource = (
			ResourceLoader.load(site_scene_path)
			if ResourceLoader.exists(site_scene_path)
			else null
		)
		if not (resource is PackedScene):
			errors.append("site_scene_path must resolve to a PackedScene: %s" % site_scene_path)
	return errors
