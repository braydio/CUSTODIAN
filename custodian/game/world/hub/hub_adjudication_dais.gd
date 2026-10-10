class_name HubAdjudicationDais
extends Node2D

@export var interaction_distance: float = 88.0

var _authority: Node
var _hub_map: CanvasItem


func configure(authority: Node, hub_map: CanvasItem) -> void:
	_authority = authority
	_hub_map = hub_map


func _ready() -> void:
	add_to_group("interactable")


func can_interact(_actor: Node) -> bool:
	return is_instance_valid(_authority) \
		and is_instance_valid(_hub_map) \
		and _hub_map.is_visible_in_tree()


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func get_interaction_prompt() -> String:
	if not can_interact(null) or not _authority.has_method("get_dais_interaction_prompt"):
		return ""
	return str(_authority.call("get_dais_interaction_prompt"))


func interact(_actor: Node) -> Dictionary:
	if not can_interact(_actor) or not _authority.has_method("accept_first_contract"):
		return {"ok": false, "code": "DAIS_UNAVAILABLE"}
	return _authority.call("accept_first_contract") as Dictionary
