extends Node2D
class_name CarrowMachineHouseDoor

enum TravelMode { ENTER_MACHINE_HOUSE, LEAVE_MACHINE_HOUSE }

@export var travel_mode: TravelMode = TravelMode.ENTER_MACHINE_HOUSE
@export var prompt_text := "ENTER EAST MACHINE HOUSE"
@export_range(32.0, 192.0, 1.0) var interaction_distance := 72.0

var carrow_map: Node = null


func _ready() -> void:
	add_to_group("interactable")


func configure(map: Node, mode: TravelMode, prompt: String) -> void:
	carrow_map = map
	travel_mode = mode
	prompt_text = prompt


func get_interaction_prompt() -> String:
	return "%s (%s)" % [prompt_text, _get_interact_prompt_key()]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	if carrow_map == null or not is_instance_valid(carrow_map):
		return
	if travel_mode == TravelMode.ENTER_MACHINE_HOUSE:
		carrow_map.call("enter_machine_house", actor)
	else:
		carrow_map.call("leave_machine_house", actor)


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return "INTERACT"
