extends Node
class_name SunderedKeepMarineAmbush

enum State {
	IDLE,
	APPROACH,
	DASH,
	RECOVER,
}

@export var trigger_radius: float = 300.0
@export var attack_range: float = 132.0
@export var approach_speed: float = 74.0
@export var dash_speed: float = 830.0
@export var dash_duration: float = 0.18
@export var dash_hit_active_start_ratio: float = 0.34
@export var dash_hit_active_end_ratio: float = 0.82
@export var dash_hit_forward_reach_px: float = 24.0
@export var dash_hit_lateral_reach_px: float = 18.0
@export var dash_recover_duration: float = 0.42
@export var dash_damage: float = 28.0
@export var dash_knockback_px: float = 95.0
@export var dash_victim_hitstop: float = 0.09
@export var dash_camera_shake_strength: float = 0.45
@export var dash_camera_shake_duration: float = 0.16

var marine: CharacterBody2D = null
var target: Node2D = null
var state: int = State.IDLE
var _dash_direction := Vector2.LEFT
var _dash_timer := 0.0
var _recover_timer := 0.0
var _dash_hit_applied := false
var _dash_start_position := Vector2.ZERO


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
	_dash_start_position = marine.global_position
	state = State.DASH
	marine.velocity = _dash_direction * dash_speed
	_play_marine_dash(_dash_direction)


func _update_dash(delta: float) -> void:
	_dash_timer = maxf(0.0, _dash_timer - delta)
	marine.velocity = _dash_direction * dash_speed
	marine.move_and_slide()
	if not _dash_hit_applied and _is_dash_hit_window_active() and _target_is_in_dash_contact_window():
		_dash_hit_applied = true
		_apply_dash_damage()
	var traveled := marine.global_position.distance_to(_dash_start_position)
	if marine.get_slide_collision_count() > 0 or traveled >= dash_speed * dash_duration or _dash_timer <= 0.0:
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
	if not _target_is_in_dash_contact_window():
		return
	if target.has_method("take_damage"):
		target.call("take_damage", dash_damage)
	if target.has_method("apply_enemy_dash_impact"):
		target.call("apply_enemy_dash_impact", _dash_direction, dash_knockback_px, dash_victim_hitstop)
	var camera := marine.get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("shake"):
		camera.call("shake", dash_camera_shake_strength * 10.0, dash_camera_shake_duration)


func _is_dash_hit_window_active() -> bool:
	var progress := clampf(1.0 - (_dash_timer / maxf(0.01, dash_duration)), 0.0, 1.0)
	var active_start := clampf(dash_hit_active_start_ratio, 0.0, 1.0)
	var active_end := clampf(dash_hit_active_end_ratio, active_start, 1.0)
	return progress >= active_start and progress <= active_end


func _target_is_in_dash_contact_window() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var to_target := target.global_position - marine.global_position
	var forward_distance := to_target.dot(_dash_direction)
	if forward_distance < -4.0 or forward_distance > dash_hit_forward_reach_px:
		return false
	var lateral_distance := absf(to_target.cross(_dash_direction))
	return lateral_distance <= dash_hit_lateral_reach_px


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
