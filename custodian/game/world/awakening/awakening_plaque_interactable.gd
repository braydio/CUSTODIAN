extends Node2D
class_name AwakeningPlaqueInteractable

## A read-only Awakening fixture: the Crèche console and the Undergate's damaged
## port readout.
##
## Interaction shows HUD text and, once, flips a progression flag. There is no
## menu and no gameplay system behind it — the Field Terminal, the Contract, and
## the Continuity Port belong to later sections.

signal acknowledged(actor: Node)

const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")

@export var title := "CONSOLE"
@export var prompt_body := ""
@export_multiline var readout := ""
@export_multiline var acknowledged_readout := ""
@export var interaction_distance: float = 72.0
@export var single_use := false

var is_acknowledged := false


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_prompt() -> String:
	return title


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func can_interact(_actor: Node) -> bool:
	return not (single_use and is_acknowledged)


func interact(actor: Node) -> void:
	var first_time := not is_acknowledged
	is_acknowledged = true
	var hud := _find_hud()
	if hud != null:
		var body := readout if first_time or acknowledged_readout.is_empty() else acknowledged_readout
		hud.call("show_interaction", title, body, _interact_key(), Catalog.ICON_OBJECTIVE)
	if first_time:
		acknowledged.emit(actor)


func _find_hud() -> Node:
	return get_node_or_null("/root/GameRoot/CustodianHUD")


func _interact_key() -> String:
	if not InputMap.has_action("interact"):
		return "G"
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			return OS.get_keycode_string(
				key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			)
	return "G"
