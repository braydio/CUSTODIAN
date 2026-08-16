class_name InteractableLevelExit2D
extends LevelExit2D

@export var interaction_distance := 56.0
@export var boarding_authority_path: NodePath
@export var departure_controller_path: NodePath


func _ready() -> void:
	trigger_on_body_entered = false
	super._ready()
	add_to_group("interactable")


func get_interaction_prompt() -> String:
	return prompt_text if _route_enabled and not _transition_locked else ""


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func can_interact(actor: Node = null) -> bool:
	if not _route_enabled or _transition_locked or is_actor_arrival_guarded(actor):
		return false
	var boarding_authority := get_node_or_null(boarding_authority_path)
	return (
		boarding_authority == null
		or (
			actor is Node2D
			and boarding_authority.has_method("is_actor_boarded")
			and bool(boarding_authority.call("is_actor_boarded", actor))
		)
	)


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	var controller := get_node_or_null(departure_controller_path)
	if controller != null and controller.has_method("begin_lift_departure"):
		controller.call("begin_lift_departure", actor, self)
		return
	request_transition(actor)
