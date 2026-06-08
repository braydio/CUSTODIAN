extends Node
class_name SunderedKeepMarineAmbush

enum State {
	IDLE,
	ACTIVE,
}

@export var trigger_radius: float = 300.0
@export var attack_range: float = 132.0

var marine: CharacterBody2D = null
var target: Node2D = null
var state: int = State.IDLE


func configure(p_marine: CharacterBody2D, p_target: Node2D = null) -> void:
	marine = p_marine
	target = p_target
	if marine != null:
		marine.set_physics_process(false)
		marine.set_process(false)
		_set_marine_facing(Vector2.LEFT, false)


func get_debug_state() -> Dictionary:
	return {
		"exists": marine != null and is_instance_valid(marine),
		"state": _state_name(),
		"dash_ready": _has_animation("marine_dash_attack_e"),
		"dash_fx_ready": _has_fx_animation("marine_dash_attack_fx_e"),
	}


func force_wake() -> void:
	if state == State.IDLE:
		_activate_shared_marine_ai()


func force_dash_for_validation() -> void:
	force_wake()
	if marine != null and is_instance_valid(marine) and marine.has_method("_start_marine_dash_windup"):
		var distance := marine.global_position.distance_to(target.global_position) if target != null and is_instance_valid(target) else attack_range
		marine.call("_start_marine_dash_windup", _direction_to_target(), distance)


func _physics_process(_delta: float) -> void:
	if marine == null or not is_instance_valid(marine):
		return
	if marine.has_method("is_dead") and bool(marine.call("is_dead")):
		return
	if target == null or not is_instance_valid(target):
		target = _find_target()
	if target == null:
		_stop_marine()
		return

	match state:
		State.IDLE:
			_update_idle()
		State.ACTIVE:
			set_physics_process(false)


func _update_idle() -> void:
	_stop_marine()
	_set_marine_facing(Vector2.LEFT, false)
	if marine.global_position.distance_to(target.global_position) <= trigger_radius:
		_activate_shared_marine_ai()


func _activate_shared_marine_ai() -> void:
	if marine == null or not is_instance_valid(marine):
		return
	state = State.ACTIVE
	marine.set("target", target)
	marine.set("behavior_state_machine_enabled", false)
	marine.set_process(true)
	marine.set_physics_process(true)


func _stop_marine() -> void:
	marine.velocity = Vector2.ZERO


func _direction_to_target() -> Vector2:
	if target == null or not is_instance_valid(target):
		return Vector2.LEFT
	return (target.global_position - marine.global_position).normalized()


func _find_target() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Node2D:
			return node as Node2D
	return null


func _set_marine_facing(direction: Vector2, moving: bool) -> void:
	if marine == null or not is_instance_valid(marine):
		return
	marine.set("_last_move_direction", direction)
	if marine.has_method("_update_directional_animation"):
		marine.call("_update_directional_animation", direction, moving)


func _has_animation(animation_name: String) -> bool:
	if marine == null or not is_instance_valid(marine):
		return false
	var sprite := marine.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name)


func _has_fx_animation(animation_name: String) -> bool:
	if marine == null or not is_instance_valid(marine):
		return false
	var sprite := marine.get_node_or_null("CustomEnemyFxSprite") as AnimatedSprite2D
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name)


func _state_name() -> String:
	match state:
		State.IDLE:
			return "idle"
		State.ACTIVE:
			return "active"
	return "unknown"
