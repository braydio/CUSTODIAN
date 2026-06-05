extends Node
class_name SunderedKeepMarineAmbush

enum State {
	IDLE,
	APPROACH,
	DASH,
	RECOVER,
}

@export var trigger_radius: float = 300.0
@export var attack_range: float = 78.0
@export var approach_speed: float = 74.0
@export var dash_speed: float = 380.0
@export var dash_duration: float = 0.30
@export var dash_hit_time: float = 0.15
@export var dash_recover_duration: float = 0.65
@export var dash_damage: float = 22.0

var marine: CharacterBody2D = null
var target: Node2D = null
var state: int = State.IDLE
var _dash_direction := Vector2.LEFT
var _dash_timer := 0.0
var _recover_timer := 0.0
var _dash_hit_applied := false


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
		state = State.APPROACH


func force_dash_for_validation() -> void:
	force_wake()
	_start_dash(_direction_to_target())


func _physics_process(delta: float) -> void:
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
		State.APPROACH:
			_update_approach(delta)
		State.DASH:
			_update_dash(delta)
		State.RECOVER:
			_update_recover(delta)


func _update_idle() -> void:
	_stop_marine()
	_set_marine_facing(Vector2.LEFT, false)
	if marine.global_position.distance_to(target.global_position) <= trigger_radius:
		state = State.APPROACH


func _update_approach(_delta: float) -> void:
	var direction := _direction_to_target()
	var distance := marine.global_position.distance_to(target.global_position)
	if distance <= attack_range:
		_start_dash(direction)
		return
	if direction.length_squared() <= 0.0001:
		_stop_marine()
		return
	marine.velocity = direction * approach_speed
	marine.move_and_slide()
	_set_marine_facing(direction, true)


func _start_dash(direction: Vector2) -> void:
	_dash_direction = direction.normalized() if direction.length_squared() > 0.0001 else Vector2.LEFT
	_dash_timer = dash_duration
	_dash_hit_applied = false
	state = State.DASH
	marine.velocity = _dash_direction * dash_speed
	_play_marine_dash(_dash_direction)


func _update_dash(delta: float) -> void:
	_dash_timer = maxf(0.0, _dash_timer - delta)
	marine.velocity = _dash_direction * dash_speed
	marine.move_and_slide()
	var elapsed := dash_duration - _dash_timer
	if not _dash_hit_applied and elapsed >= dash_hit_time:
		_dash_hit_applied = true
		_apply_dash_damage()
	if _dash_timer <= 0.0:
		marine.velocity = Vector2.ZERO
		_recover_timer = dash_recover_duration
		state = State.RECOVER


func _update_recover(delta: float) -> void:
	_recover_timer = maxf(0.0, _recover_timer - delta)
	_stop_marine()
	if _recover_timer <= 0.0:
		state = State.APPROACH


func _apply_dash_damage() -> void:
	if target == null or not is_instance_valid(target):
		return
	if marine.global_position.distance_to(target.global_position) > attack_range + 34.0:
		return
	if target.has_method("take_damage"):
		target.call("take_damage", dash_damage)


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


func _play_marine_dash(direction: Vector2) -> void:
	if marine == null or not is_instance_valid(marine):
		return
	marine.set("_last_move_direction", direction)
	if marine.has_method("_update_custom_enemy_animation"):
		marine.call("_update_custom_enemy_animation", direction, false, true)


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
		State.APPROACH:
			return "approach"
		State.DASH:
			return "dash"
		State.RECOVER:
			return "recover"
	return "unknown"
