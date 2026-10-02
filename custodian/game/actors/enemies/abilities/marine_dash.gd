extends RefCounted
class_name MarineDash

## Complete tactical dash authority. Enemy supplies shared actor/combat services.
## Target queries intentionally follow host.target, preserving the existing retarget policy.
const EnemyHitSpatialContract = preload("res://game/systems/combat/enemy_hit_spatial_contract.gd")

var host: Enemy
var config: MarineDashConfig
var cadence_timer := 0.0
var phase: StringName = &""
var timer: float = 0.0
var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2 = Vector2.ZERO
var hit_targets: Array[int] = []
var warning_line: Line2D = null
var attacker_hitstop_timer: float = 0.0
var charge_ratio: float = 0.0
var distance_share: float = 0.5
var current_distance: float = 150.0
var current_damage: float = 28.0
var target_lock_done: bool = false
var last_attack_hit: bool = false
var reset_timer: float = 0.0
var reset_direction: Vector2 = Vector2.UP
var reset_side: float = 1.0
var attack_id := ""
var terminal_emitted := false
var closest_approach := INF
var last_spatial_context: Dictionary = {}


func setup(new_host: Enemy, new_config: MarineDashConfig, initial_cadence: float) -> void:
	host = new_host
	config = new_config
	cadence_timer = initial_cadence


func is_active() -> bool:
	return not phase.is_empty()


func try_start(delta: float) -> void:
	if not phase.is_empty():
		return
	if host.target == null or not is_instance_valid(host.target) or host.is_combat_target_destroyed(host.target):
		return
	var target_node := host.target as Node2D
	if target_node == null:
		return
	var distance := host.global_position.distance_to(target_node.global_position)
	if distance < config.launch_band_min:
		start_reset(true)
		return
	cadence_timer += delta
	if cadence_timer < config.cooldown:
		return
	cadence_timer = 0.0
	var direction := (target_node.global_position - host.global_position).normalized() if target_node != null else host.get_ability_facing()
	request_start(direction, distance)


func request_start(initial_direction: Vector2, target_distance: float = -1.0) -> void:
	configure_charge(target_distance)
	attack_id = host.next_ability_attack_id(&"marine_dash")
	terminal_emitted = false
	closest_approach = host.global_position.distance_to((host.target as Node2D).global_position) if host.target is Node2D and is_instance_valid(host.target) else INF
	last_spatial_context.clear()
	phase = &"windup"
	_log_event(&"marine_dash_windup")
	timer = maxf(0.01, config.windup_time + config.charge_extra_windup * charge_ratio)
	direction = initial_direction.normalized() if initial_direction.length_squared() > 0.0001 else host.get_ability_facing().normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	start_position = host.global_position
	hit_targets.clear()
	target_lock_done = false
	last_attack_hit = false
	host.set_ability_facing(direction)
	host.velocity = Vector2.ZERO
	host.clear_path()
	_show_telegraph(true)
	if host.has_custom_ability_presentation():
		host.play_custom_ability_attack(direction)
		_set_animation_speed(maxf(0.45, config.windup_time / maxf(config.windup_time, timer)))


func configure_charge(target_distance: float) -> void:
	var resolved_distance := target_distance
	if resolved_distance < 0.0 and host.target is Node2D:
		resolved_distance = host.global_position.distance_to((host.target as Node2D).global_position)
	if resolved_distance < 0.0:
		resolved_distance = config.distance_px
	var distance_need := clampf((resolved_distance - config.distance_px * 0.66) / maxf(1.0, config.launch_band_max - config.distance_px * 0.66), 0.0, 1.0)
	var target_velocity := _target_velocity()
	var approach_direction := ((host.target as Node2D).global_position - host.global_position).normalized() if host.target is Node2D else host.get_ability_facing()
	var retreat_factor := clampf(target_velocity.dot(approach_direction) / 180.0, 0.0, 1.0)
	charge_ratio = clampf(maxf(distance_need, 0.52 if not last_attack_hit else 0.0), 0.0, 1.0)
	distance_share = clampf(0.28 + distance_need * 0.42 + retreat_factor * 0.22, 0.25, 0.82)
	var damage_share := 1.0 - distance_share
	current_distance = config.distance_px * (1.0 + config.charge_distance_bonus * charge_ratio * distance_share)
	current_damage = config.damage * (1.0 + config.charge_damage_bonus * charge_ratio * damage_share)


func _target_velocity() -> Vector2:
	if host.target is CharacterBody2D:
		return (host.target as CharacterBody2D).velocity
	if host.target != null and "velocity" in host.target:
		var target_velocity: Variant = host.target.get("velocity")
		if target_velocity is Vector2:
			return target_velocity as Vector2
	return Vector2.ZERO


func tick(delta: float) -> bool:
	if phase.is_empty():
		return _update_reset(delta)
	if attacker_hitstop_timer > 0.0:
		attacker_hitstop_timer = maxf(0.0, attacker_hitstop_timer - delta)
		host.velocity = Vector2.ZERO
		return true
	timer = maxf(0.0, timer - delta)
	match phase:
		&"windup":
			host.velocity = Vector2.ZERO
			_update_target_lock()
			_update_telegraph()
			if timer <= 0.0:
				start_travel()
		&"dash":
			_update_travel(delta)
		&"impact_lock":
			host.velocity = Vector2.ZERO
			if timer <= 0.0:
				_start_recovery()
		&"recovery":
			host.velocity = Vector2.ZERO
			if timer <= 0.0:
				finish()
				start_reset(false)
		_:
			finish()
	return true


func start_travel() -> void:
	phase = &"dash"
	_log_event(&"marine_dash_travel")
	timer = maxf(0.01, config.travel_time)
	start_position = host.global_position
	_show_telegraph(false)
	_set_animation_speed(1.0)
	if host.has_custom_ability_presentation():
		host.play_custom_ability_attack(direction)


func _update_travel(delta: float) -> void:
	var dash_speed := current_distance / maxf(0.01, config.travel_time)
	host.velocity = direction * dash_speed
	host.move_and_slide()
	try_apply_hit()
	var traveled := host.global_position.distance_to(start_position)
	if host.get_slide_collision_count() > 0 or traveled >= current_distance or timer <= 0.0:
		_start_impact_lock()


func _start_impact_lock() -> void:
	phase = &"impact_lock"
	_log_event(&"marine_dash_impact_lock")
	timer = maxf(0.01, config.impact_lock_time)
	host.velocity = Vector2.ZERO


func _start_recovery() -> void:
	phase = &"recovery"
	_log_event(&"marine_dash_recovery")
	timer = maxf(0.01, config.recovery_time)
	host.velocity = Vector2.ZERO


func finish() -> void:
	if not attack_id.is_empty() and not terminal_emitted:
		var whiff := get_debug_state()
		whiff.merge(last_spatial_context, true)
		whiff.merge({"attack_id": attack_id, "attacker_id": host.get_instance_id(), "target_id": host.target.get_instance_id() if host.target != null and is_instance_valid(host.target) else 0, "enemy": host.enemy_name, "attack_type": "marine_dash", "result": "whiffed", "closest_approach_px": closest_approach, "attacker_position": host.global_position, "target_position": (host.target as Node2D).global_position if host.target is Node2D and is_instance_valid(host.target) else Vector2.ZERO}, true)
		host.observatory_log(&"marine_dash_whiff", whiff)
		terminal_emitted = true
	_log_event(&"marine_dash_finished")
	phase = &""
	timer = 0.0
	attacker_hitstop_timer = 0.0
	hit_targets.clear()
	charge_ratio = 0.0
	distance_share = 0.5
	current_distance = config.distance_px
	current_damage = config.damage
	target_lock_done = false
	attack_id = ""
	last_spatial_context.clear()
	_show_telegraph(false)
	_set_animation_speed(1.0)
	host.velocity = Vector2.ZERO
	host.refresh_enemy_directional_animation()


func try_apply_hit() -> void:
	if not is_hit_window_active():
		return
	if host.target == null or not is_instance_valid(host.target) or host.is_combat_target_destroyed(host.target):
		return
	var target_node := host.target as Node2D
	if target_node == null:
		return
	var target_id := int(target_node.get_instance_id())
	if hit_targets.has(target_id):
		return
	var charge_multiplier := 1.0 + 0.22 * charge_ratio
	var allowed_forward := config.hit_forward_reach_px * charge_multiplier
	var allowed_lateral := config.hit_lateral_reach_px * (1.0 + 0.15 * charge_ratio)
	var spatial := EnemyHitSpatialContract.directional_lane(host.global_position, target_node.global_position, direction, 4.0, allowed_forward, allowed_lateral)
	closest_approach = minf(closest_approach, float(spatial.separation_px))
	last_spatial_context = spatial.duplicate(true)
	if not bool(spatial.spatial_valid):
		return
	hit_targets.append(target_id)
	_apply_hit(target_node, spatial)


func is_hit_window_active() -> bool:
	if phase != &"dash":
		return false
	var dash_time := maxf(0.01, config.travel_time)
	var progress := clampf(1.0 - (timer / dash_time), 0.0, 1.0)
	var active_start := clampf(config.hit_active_start_ratio, 0.0, 1.0)
	var active_end := clampf(config.hit_active_end_ratio, active_start, 1.0)
	return progress >= active_start and progress <= active_end


func _apply_hit(hit_node: Node2D, spatial: Dictionary) -> void:
	var hit_result := host.resolve_ability_hit(hit_node, current_damage, &"dash", attack_id, spatial)
	var terminal := get_debug_state()
	terminal.merge(spatial, true)
	terminal.merge({"attack_id": attack_id, "attacker_id": host.get_instance_id(), "target_id": hit_node.get_instance_id(), "enemy": host.enemy_name, "attack_type": "marine_dash", "damage_attempted": current_damage, "applied_damage": float(hit_result.get("applied_damage", 0.0)), "closest_approach": closest_approach, "result": String(hit_result.get("result", ""))}, true)
	host.observatory_log(&"marine_dash_hit_resolved", terminal)
	terminal_emitted = true

	if bool(hit_result.get("dodged", false)) or bool(hit_result.get("parried", false)) or bool(hit_result.get("block_hitreact", false)):
		last_attack_hit = false
		return

	last_attack_hit = true

	var knockback_direction := direction.normalized()
	if hit_node.has_method("apply_enemy_dash_impact"):
		hit_node.call("apply_enemy_dash_impact", knockback_direction, config.knockback_px, config.victim_hitstop)
	host.trigger_ability_camera_feedback(direction, config.camera_shake_strength, config.camera_shake_duration)
	host.apply_ability_hitstop(maxf(config.victim_hitstop, config.attacker_hitstop))
	attacker_hitstop_timer = maxf(attacker_hitstop_timer, config.attacker_hitstop)
	_start_impact_lock()


func _show_telegraph(p_visible: bool) -> void:
	if not p_visible:
		if warning_line != null:
			warning_line.visible = false
		if host.animated_sprite != null:
			host.animated_sprite.modulate = Color.WHITE
		return
	if warning_line == null:
		warning_line = Line2D.new()
		warning_line.name = "MarineDashWarningLine"
		warning_line.width = 2.0
		warning_line.default_color = Color(1.0, 0.55, 0.12, 0.42)
		warning_line.z_index = 20
		host.add_child(warning_line)
	warning_line.visible = true
	warning_line.width = 2.0
	warning_line.default_color = Color(1.0, 0.55, 0.12, 0.42)
	_update_telegraph()
	if host.animated_sprite != null:
		host.animated_sprite.modulate = Color(1.0, 0.64, 0.28, 1.0)


func _update_telegraph() -> void:
	if warning_line == null:
		return
	warning_line.clear_points()
	warning_line.add_point(Vector2.ZERO)
	warning_line.add_point(direction * current_distance)


func _update_target_lock() -> void:
	if target_lock_done or host.target == null or not is_instance_valid(host.target) or not (host.target is Node2D):
		return
	var total_windup := maxf(0.01, config.windup_time + config.charge_extra_windup * charge_ratio)
	var progress := clampf(1.0 - (timer / total_windup), 0.0, 1.0)
	if progress < 0.62:
		return
	var target_node := host.target as Node2D
	var predicted_position := target_node.global_position + _target_velocity() * (config.prediction_time + 0.14 * charge_ratio)
	var predicted_direction := (predicted_position - host.global_position).normalized()
	if predicted_direction.length_squared() > 0.0001:
		direction = predicted_direction
		host.set_ability_facing(predicted_direction)
		target_lock_done = true
		if warning_line != null:
			warning_line.width = 3.0
			warning_line.default_color = Color(1.0, 0.32, 0.08, 0.78)


func start_reset(back_away: bool) -> void:
	if host.target == null or not is_instance_valid(host.target) or not (host.target is Node2D):
		return
	var to_target := ((host.target as Node2D).global_position - host.global_position).normalized()
	if to_target.length_squared() <= 0.0001:
		to_target = host.get_ability_facing().normalized()
	reset_side *= -1.0
	var lateral := Vector2(-to_target.y, to_target.x) * reset_side
	reset_direction = (lateral * 0.82 - to_target * (0.58 if back_away else 0.18)).normalized()
	reset_timer = maxf(reset_timer, config.reset_time * (0.75 if back_away else 1.0))


func _update_reset(delta: float) -> bool:
	if reset_timer <= 0.0 or host.is_ability_reset_interrupted():
		return false
	reset_timer = maxf(0.0, reset_timer - delta)
	host.velocity = reset_direction * config.reset_speed
	host.move_and_slide()
	host.set_ability_facing(reset_direction)
	host.play_ability_movement(host.get_ability_facing())
	return true


func _set_animation_speed(speed_scale: float) -> void:
	if host.animated_sprite != null:
		host.animated_sprite.speed_scale = speed_scale
	if host.custom_enemy_fx_sprite != null:
		host.custom_enemy_fx_sprite.speed_scale = speed_scale


func get_debug_state() -> Dictionary:
	return {
		"attack_id": attack_id,
		"phase": String(phase),
		"charge_ratio": charge_ratio,
		"distance_share": distance_share,
		"damage_share": 1.0 - distance_share,
		"distance": current_distance,
		"damage": current_damage,
		"target_locked": target_lock_done,
		"reset_timer": reset_timer,
		"closest_approach": closest_approach,
	}


func _log_event(event_name: StringName) -> void:
	var data := get_debug_state()
	data["enemy"] = host.enemy_name
	data["position"] = host.global_position
	data["target"] = host.target.name if host.target != null and is_instance_valid(host.target) else ""
	if host.target is Node2D:
		data["target_position"] = (host.target as Node2D).global_position
	host.observatory_log(event_name, data)

