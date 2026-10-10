class_name HubContinuityPortInteraction
extends Node2D

@export var interaction_distance: float = 96.0

var _authority: Node
var _hub_map: CanvasItem

func configure(authority: Node, hub_map: CanvasItem) -> void:
	_authority = authority
	_hub_map = hub_map

func _ready() -> void:
	add_to_group("interactable")

func can_interact(_actor: Node) -> bool:
	return is_instance_valid(_authority) and is_instance_valid(_hub_map) and _hub_map.is_visible_in_tree()

func get_interaction_position() -> Vector2:
	return global_position

func get_interaction_distance() -> float:
	return interaction_distance

func get_interaction_prompt() -> String:
	if not can_interact(null) or not _authority.has_method("get_preparation_state"):
		return ""
	match str(_authority.call("get_preparation_state")):
		"GENERATING": return "CONTRACT PREPARING • HOLD POSITION"
		"FAILED": return "RETRY CONTRACT PREPARATION"
		"READY": return "DEPLOY THROUGH CONTINUITY PORT"
		"CLAIMED": return "CONTRACT DEPLOYMENT IN PROGRESS"
		_: return "CONTRACT UNAVAILABLE"

func interact(_actor: Node) -> Dictionary:
	if not can_interact(null):
		return {"ok": false, "code": "CONTINUITY_PORT_UNAVAILABLE"}
	match str(_authority.call("get_preparation_state")):
		"GENERATING":
			var bootstrap := get_node_or_null("/root/WorldContractBootstrap")
			if bootstrap != null and bootstrap.has_method("mark_deployment_requested"):
				bootstrap.call("mark_deployment_requested")
			return {"ok": true, "code": "PREPARATION_PENDING"}
		"FAILED": return _authority.call("retry_failed_preparation") as Dictionary
		"READY": return _authority.call("request_campaign_deployment") as Dictionary
	return {"ok": false, "code": "PREPARATION_NOT_DEPLOYABLE", "state": str(_authority.call("get_preparation_state"))}
