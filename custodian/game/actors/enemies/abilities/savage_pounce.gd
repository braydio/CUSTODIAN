extends RefCounted
class_name SavagePounce

## Complete Savage pounce authority. Enemy supplies shared movement, hit,
## facing, presentation, threat-highlight, and observability services.
const EnemyHitSpatialContract = preload("res://game/systems/combat/enemy_hit_spatial_contract.gd")

var host: Enemy
var config: SavagePounceConfig
var phase: StringName = &""
var timer: float = 0.0
var cooldown_timer: float = 0.0
var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2 = Vector2.ZERO
var hit_targets: Array[int] = []


func setup(new_host: Enemy, new_config: SavagePounceConfig) -> void:
	host = new_host
	config = new_config


func is_active() -> bool:
	return not phase.is_empty()


func is_available() -> bool:
	return cooldown_timer <= 0.0


func get_debug_state() -> Dictionary:
	return {
		"phase": String(phase),
		"timer": timer,
		"cooldown_timer": cooldown_timer,
		"hit_window_active": is_hit_window_active(),
		"direction": direction,
		"start_position": start_position,
		"hit_target_count": hit_targets.size(),
	}


func is_hit_window_active() -> bool:
	if phase != &"leap":
		return false
	var leap_progress := clampf(1.0 - (timer / maxf(0.01, config.leap_time)), 0.0, 1.0)
	return leap_progress >= config.hit_active_start_ratio and leap_progress <= config.hit_active_end_ratio


func try_start() -> bool:
	if host == null or not host.savage_pounce_enabled or is_active() or not is_available():
		return false
	if host.target == null or not is_instance_valid(host.target) \
		or host.is_combat_target_destroyed(host.target) \
		or not host.target.is_in_group("player"):
		return false
	var target_node := host.target as Node2D
	if target_node == null:
		return false
	var distance := host.global_position.distance_to(target_node.global_position)
	if distance < config.launch_band_min or distance > config.launch_band_max:
		return false
	_start(host.global_position.direction_to(target_node.global_position))
	return true


func tick(delta: float) -> bool:
	cooldown_timer = maxf(0.0, cooldown_timer - delta)
	if not is_active():
		return false
	timer = maxf(0.0, timer - delta)
	match phase:
		&"windup":
			host.velocity = Vector2.ZERO
			if timer <= 0.0:
				phase = &"leap"
				timer = maxf(0.01, config.leap_time)
				start_position = host.global_position
				host.set_threat_highlight(false)
				host.log_savage_event(&"savage_pounce_leap", phase)
		&"leap":
			var leap_speed := config.distance_px / maxf(0.01, config.leap_time)
			host.velocity = direction * leap_speed
			host.move_and_slide()
			_try_apply_hit()
			var traveled := host.global_position.distance_to(start_position)
			if host.get_slide_collision_count() > 0 or traveled >= config.distance_px or timer <= 0.0:
				_start_recovery()
		&"recovery":
			host.velocity = Vector2.ZERO
			if timer <= 0.0:
				_finish()
		_:
			_finish()
	return true


func cancel() -> bool:
	if not is_active():
		return false
	phase = &""
	timer = 0.0
	hit_targets.clear()
	host.velocity = Vector2.ZERO
	host.set_threat_highlight(false)
	return true


func _start(initial_direction: Vector2) -> void:
	phase = &"windup"
	timer = maxf(0.01, config.windup_time)
	cooldown_timer = maxf(0.0, config.cooldown)
	direction = initial_direction.normalized() if initial_direction.length_squared() > 0.0001 else host.get_ability_facing().normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	start_position = host.global_position
	hit_targets.clear()
	host.set_ability_facing(direction)
	host.velocity = Vector2.ZERO
	host.clear_path()
	host.set_threat_highlight(true)
	if host.has_custom_ability_presentation():
		host.play_custom_ability_attack(direction)
	host.log_savage_event(&"savage_pounce_windup", phase)


func _try_apply_hit() -> void:
	if phase != &"leap" or host.target == null or not is_instance_valid(host.target) \
		or host.is_combat_target_destroyed(host.target):
		return
	if not is_hit_window_active():
		return
	var target_node := host.target as Node2D
	if target_node == null:
		return
	var target_id := int(target_node.get_instance_id())
	if hit_targets.has(target_id):
		return
	var spatial := EnemyHitSpatialContract.directional_lane(
		host.global_position,
		target_node.global_position,
		direction,
		5.0,
		config.hit_forward_reach_px,
		config.hit_lateral_reach_px
	)
	if not bool(spatial.get("spatial_valid", false)):
		return
	hit_targets.append(target_id)
	var hit_result := host.resolve_ability_hit(target_node, config.damage, &"savage_pounce", "", spatial)
	if bool(hit_result.get("parried", false)):
		return
	if float(hit_result.get("applied_damage", 0.0)) > 0.0 and not bool(hit_result.get("blocked", false)):
		if target_node.has_method("apply_enemy_dash_impact"):
			target_node.call("apply_enemy_dash_impact", direction, config.knockback_px, 0.04)
	host.log_savage_event(&"savage_pounce_hit", phase, hit_result)
	_start_recovery()


func _start_recovery() -> void:
	phase = &"recovery"
	timer = maxf(0.01, config.recovery_time)
	host.velocity = Vector2.ZERO
	host.log_savage_event(&"savage_pounce_recovery", phase)


func _finish() -> void:
	phase = &""
	timer = 0.0
	hit_targets.clear()
	host.velocity = Vector2.ZERO
	host.set_threat_highlight(false)
