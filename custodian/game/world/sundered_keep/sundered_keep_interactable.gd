extends Node2D
class_name SunderedKeepInteractable

@export var interaction_kind: StringName = &""
@export var prompt_text: String = "INTERACT"
@export_range(24.0, 192.0, 1.0) var interaction_distance: float = 84.0

var connected_map: Node = null


func _ready() -> void:
	add_to_group("interactable")


func configure(map: Node, kind: StringName, prompt: String, distance := 84.0) -> void:
	connected_map = map
	interaction_kind = kind
	prompt_text = prompt
	interaction_distance = distance


func get_interaction_prompt() -> String:
	return "%s (%s)" % [prompt_text, _get_interact_prompt_key()]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	if connected_map != null and connected_map.has_method("_handle_sundered_interaction"):
		connected_map.call("_handle_sundered_interaction", interaction_kind, actor)


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return "INTERACT"
