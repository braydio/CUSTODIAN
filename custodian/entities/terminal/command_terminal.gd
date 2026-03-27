extends Node2D
class_name CommandTerminal

@export var launch_url: String = "http://127.0.0.1:7331"
@export var prompt_text: String = "ACCESS CUSTODIAN INTERFACE (G)"
@export var interact_distance: float = 88.0

func _ready():
	add_to_group("interactable")

func get_interaction_prompt() -> String:
	return prompt_text

func get_interaction_position() -> Vector2:
	return global_position

func get_interaction_distance() -> float:
	return interact_distance

func interact(_actor: Node):
	var ui = get_node_or_null("/root/GameRoot/UI")
	if ui and ui.has_method("open_command_terminal"):
		ui.open_command_terminal(launch_url)
