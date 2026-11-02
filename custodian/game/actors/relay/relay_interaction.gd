extends Area2D
class_name ARRNRelayInteraction

@export var relay_path: NodePath = NodePath("..")


func get_relay() -> Node:
	return get_node_or_null(relay_path)


func get_interaction_prompt() -> String:
	var relay := get_relay()
	if relay != null and relay.has_method("get_interaction_prompt"):
		return String(relay.call("get_interaction_prompt"))
	return ""


func interact(actor: Node) -> void:
	var relay := get_relay()
	if relay != null and relay.has_method("interact"):
		relay.call("interact", actor)
