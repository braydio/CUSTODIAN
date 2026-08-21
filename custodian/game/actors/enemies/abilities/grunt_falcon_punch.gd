extends RefCounted
class_name GruntFalconPunch

const HitSpatial = preload("res://game/systems/combat/enemy_hit_spatial_contract.gd")

enum Phase { IDLE, TRACKING, COMMITTED, LEAP, IMPACT_LOCK, RECOVERY }

var host: Enemy
var config: GruntFalconPunchConfig
var phase := Phase.IDLE
var phase_timer := 0.0
var cooldown_timer := 0.0
var recent_parry_timer := 0.0
var cadence_credit := 0.0
var normal_attacks_since_special := 0
var target_ref: WeakRef
var target_id := 0
var direction := Vector2.RIGHT
var committed_direction := Vector2.RIGHT
var committed_target_position := Vector2.ZERO
var launch_start := Vector2.ZERO
var current_distance := 0.0
var hit_targets: Array[int] = []
var impact_confirmed := false
var attacker_hitstop_timer := 0.0
var attack_id := ""
var result: StringName = &""
var launch_distance := -1.0
var active_start_target_distance := -1.0
var closest_approach := INF
var lateral_error := 0.0
var collision_obstructed := false
var engagement_token_request: Callable


func setup(new_host: Enemy, new_config: GruntFalconPunchConfig) -> void:
	host = new_host
	config = new_config
	engagement_token_request = Callable(host, "try_claim_ability_engagement_token")
	current_distance = config.launch_distance_px
	cadence_credit = maxf(0.0, 1.0 - config.cadence_credit_per_attack)


func tick(delta: float) -> bool:
	if host == null or config == null:
		return false
	cooldown_timer = maxf(0.0, cooldown_timer - delta)
	recent_parry_timer = maxf(0.0, recent_parry_timer - delta)
	if phase == Phase.IDLE:
		return false
	if attacker_hitstop_timer > 0.0:
		attacker_hitstop_timer = maxf(0.0, attacker_hitstop_timer - delta)
		host.velocity = Vector2.ZERO
		return true
	var prior_timer := phase_timer
	phase_timer = maxf(0.0, phase_timer - delta)
	var overflow := maxf(0.0, delta - prior_timer)
	match phase:
		Phase.TRACKING:
			_retarget_tracking()
			_move_tracking()
			if phase_timer <= 0.0:
				_attempt_commit()
				if phase == Phase.COMMITTED and overflow > 0.0:
					phase_timer = maxf(0.0, phase_timer - overflow)
					if phase_timer <= 0.0:
						start_leap()
		Phase.COMMITTED:
			_move_tracking()
			if phase_timer <= 0.0:
				start_leap()
		Phase.LEAP:
			_update_leap()
		Phase.IMPACT_LOCK:
			host.velocity = Vector2.ZERO
			if phase_timer <= 0.0:
				_start_recovery()
		Phase.RECOVERY:
			host.velocity = Vector2.ZERO
			play_current_presentation()
			if phase_timer <= 0.0:
				finish()
		_:
			finish()
	return true


func try_start(target: Node2D) -> bool:
	if is_active():
		return true
	if not can_start(target):
		return false
	start_debug(target)
	return true


func start_debug(target: Node2D, initial_direction := Vector2.ZERO) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	target_ref = weakref(target)
	target_id = target.get_instance_id()
	attack_id = host.next_falcon_attack_id()
	result = &"pending"
	impact_confirmed = false
	launch_distance = host.global_position.distance_to(target.global_position)
	active_start_target_distance = -1.0
	closest_approach = launch_distance
	lateral_error = 0.0
	collision_obstructed = false
	phase = Phase.TRACKING
	phase_timer = maxf(0.01, config.tracking_time)
	cooldown_timer = maxf(0.0, config.cooldown)
	normal_attacks_since_special = 0
	cadence_credit = 0.0
	direction = initial_direction.normalized()
	if direction.length_squared() <= 0.0001:
		direction = host.global_position.direction_to(target.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	committed_direction = direction
	committed_target_position = target.global_position
	launch_start = host.global_position
	hit_targets.clear()
	host.set_ability_facing(direction)
	host.clear_path()
	play_current_presentation()
	host.observatory_increment(&"falcon_punch_attempts")
	_log(&"grunt_falcon_punch_windup")
	_audit_presentation()
	return true


func on_normal_attack_started() -> void:
	normal_attacks_since_special += 1
	cadence_credit = minf(2.0, cadence_credit + config.cadence_credit_per_attack)


func on_parried() -> void:
	var active := is_active()
	cancel(&"parried")
	if active:
		recent_parry_timer = maxf(recent_parry_timer, config.recent_parry_lockout_sec)


func cancel(reason: StringName = &"interrupted") -> void:
	if is_active():
		finish(reason)


func is_active() -> bool:
	return phase != Phase.IDLE


func is_committed_leap() -> bool:
	return phase == Phase.LEAP


func can_receive_reversal_from(attacker: Node2D) -> bool:
	return is_committed_leap() and attacker != null and is_instance_valid(attacker) \
		and attacker.get_instance_id() == target_id


func finish_for_reversal() -> void:
	recent_parry_timer = maxf(recent_parry_timer, config.recent_parry_lockout_sec)
	finish(&"parried_reversal")


func can_start(target: Node2D) -> bool:
	if host == null or config == null or not host.is_grunt_falcon_enabled():
		return false
	if target == null or not is_instance_valid(target) or not target.is_in_group("player"):
		return false
	if host.is_combat_target_destroyed(target):
		return false
	var distance := host.global_position.distance_to(target.global_position)
	if distance < config.launch_band.x or distance > config.launch_band.y:
		return false
	if cooldown_timer > 0.0 or recent_parry_timer > 0.0:
		return false
	if normal_attacks_since_special < maxi(0, config.normal_attacks_required):
		return false
	if config.cadence_credit_per_attack <= 0.0 or cadence_credit < 1.0:
		return false
	return not config.requires_clear_lane or is_lane_clear(target)


func is_lane_clear(target: Node2D) -> bool:
	var to_target := target.global_position - host.global_position
	var lane_length := maxf(0.0, to_target.length() - config.stop_short_px)
	if lane_length <= 0.0:
		return false
	var lane_direction := to_target.normalized()
	for candidate in host.get_tree().get_nodes_in_group("enemy"):
		if candidate == host or not (candidate is Node2D):
			continue
		var other := candidate as Node2D
		if host.is_combat_target_destroyed(other):
			continue
		var offset := other.global_position - host.global_position
		var forward := offset.dot(lane_direction)
		if forward > 0.0 and forward < lane_length \
				and absf(offset.cross(lane_direction)) < config.ally_lane_radius_px:
			return false
	return true


func get_phase_name() -> StringName:
	match phase:
		Phase.TRACKING: return &"tracking"
		Phase.COMMITTED: return &"committed"
		Phase.LEAP: return &"leap"
		Phase.IMPACT_LOCK: return &"impact_lock"
		Phase.RECOVERY: return &"recovery"
	return &"idle"


func get_attack_range_for(target: Node2D) -> float:
	return config.launch_band.y if can_start(target) else 0.0


func play_current_presentation() -> void:
	var action := get_semantic_action()
	if not action.is_empty():
		host.play_enemy_action(action, direction)


func get_semantic_action() -> StringName:
	match phase:
		Phase.TRACKING, Phase.COMMITTED: return &"combat.falcon.windup"
		Phase.LEAP, Phase.IMPACT_LOCK: return &"combat.falcon.inflight"
		Phase.RECOVERY: return &"combat.falcon.recovery"
	return &""


func start_leap() -> void:
	if phase == Phase.TRACKING:
		committed_direction = direction
		var target := _target()
		if target != null:
			committed_target_position = target.global_position
	direction = committed_direction
	phase = Phase.LEAP
	phase_timer = maxf(0.01, config.leap_time)
	launch_start = host.global_position
	var desired_contact := committed_target_position - direction * config.stop_short_px
	current_distance = minf(
		config.launch_distance_px,
		maxf(0.0, (desired_contact - host.global_position).dot(direction))
	)
	play_current_presentation()
	_log(&"grunt_falcon_punch_leap")
	_audit_presentation()


func try_apply_hit(force_contact_check := false) -> void:
	if not force_contact_check and not _hit_window_active():
		return
	var target := _target()
	if target == null or host.is_combat_target_destroyed(target) or hit_targets.has(target_id):
		return
	var spatial := HitSpatial.directional_lane(
		host.global_position, target.global_position, direction, 6.0,
		config.hit_forward_reach_px, config.hit_lateral_reach_px
	)
	if not bool(spatial.get("spatial_valid", false)):
		return
	hit_targets.append(target_id)
	var hit_result := host.resolve_ability_hit(
		target, host.damage * config.damage_multiplier, &"falcon_punch", attack_id, spatial
	)
	result = StringName(str(hit_result.get("result", &"unknown")))
	host.record_falcon_hit_result(result)
	var event := get_telemetry()
	event.merge({
		"target_position": target.global_position,
		"result": String(hit_result.get("result", "")),
		"applied_damage": float(hit_result.get("applied_damage", 0.0)),
		"dodged": bool(hit_result.get("dodged", false)),
		"blocked": bool(hit_result.get("blocked", false)),
		"parried": bool(hit_result.get("parried", false)),
	}, true)
	event.merge(spatial, true)
	host.observatory_log(&"grunt_falcon_punch_hit_resolved", event)
	if bool(hit_result.get("parried", false)):
		host.observatory_increment(&"falcon_punch_parried")
		host.observatory_increment(&"enemy_attack_interrupted_by_parry")
		if target.has_method("try_start_falcon_reversal_from_parry") \
				and bool(target.call("try_start_falcon_reversal_from_parry", host, direction)):
			result = &"parried_reversal"
			return
		host.separate_ability_from_target(target, direction)
		if recent_parry_timer <= 0.0:
			host.apply_parry_stagger(-direction, host.stagger_duration, 70.0)
		return
	if not bool(hit_result.get("dodged", false)) \
			and not bool(hit_result.get("blocked", false)) \
			and float(hit_result.get("applied_damage", 0.0)) > 0.0:
		impact_confirmed = true
		result = &"damaged"
		host.observatory_increment(&"falcon_punch_hits")
		if target.has_method("apply_enemy_falcon_punch_impact"):
			target.call("apply_enemy_falcon_punch_impact", direction, config.knockback_px, config.victim_hitstop_sec)
		host.trigger_falcon_camera_feedback(direction, config)
		host.apply_ability_hitstop(maxf(config.victim_hitstop_sec, config.attacker_hitstop_sec))
		attacker_hitstop_timer = maxf(attacker_hitstop_timer, config.attacker_hitstop_sec)
		host.separate_ability_from_target(target, direction)
		_start_impact_lock()
		return
	host.separate_ability_from_target(target, direction)
	_start_recovery()


func resolve_whiff(reason: StringName) -> void:
	if phase != Phase.LEAP:
		return
	result = reason
	host.record_falcon_whiff(reason)
	var event := get_telemetry()
	event.merge({"result": "whiffed", "reason": String(reason)}, true)
	host.observatory_log(&"grunt_falcon_punch_hit_resolved", event)
	_start_recovery()


func finish(result_override: StringName = &"") -> void:
	if not is_active():
		return
	if not result_override.is_empty():
		result = result_override
	if result == &"pending":
		result = &"interrupted"
		host.observatory_increment(&"falcon_punch_cancelled")
	_log(&"grunt_falcon_punch_finished")
	phase = Phase.IDLE
	phase_timer = 0.0
	attacker_hitstop_timer = 0.0
	hit_targets.clear()
	current_distance = config.launch_distance_px
	attack_id = ""
	impact_confirmed = false
	target_ref = null
	target_id = 0
	committed_direction = Vector2.RIGHT
	committed_target_position = Vector2.ZERO
	host.release_ability_engagement_token()
	host.velocity = Vector2.ZERO
	host.refresh_enemy_directional_animation()


func get_telemetry() -> Dictionary:
	var target := _target()
	var expected_action := get_semantic_action()
	var actual_action := host.get_enemy_presentation_action()
	var dodge_phase := "unknown"
	if target != null and target.has_method("get_dodge_telemetry_phase"):
		dodge_phase = String(target.call("get_dodge_telemetry_phase"))
	return {
		"attack_id": attack_id,
		"attacker_id": host.get_instance_id(),
		"target_id": target_id,
		"attack_type": "falcon_punch",
		"enemy": host.enemy_name,
		"phase": String(get_phase_name()),
		"result": String(result),
		"position": host.global_position,
		"direction": direction,
		"target": target.name if target != null else "",
		"damage": host.damage * config.damage_multiplier,
		"launch_distance": launch_distance,
		"target_distance_at_active_start": active_start_target_distance,
		"closest_approach": closest_approach if is_finite(closest_approach) else -1.0,
		"lateral_error": lateral_error,
		"player_dodge_phase": dodge_phase,
		"collision_obstructed": collision_obstructed,
		"stop_short_distance": config.stop_short_px,
		"windup_duration": config.total_windup_time(),
		"windup_progress": _windup_progress(),
		"phase_timer_remaining": phase_timer,
		"tracking_lock_sec": config.committed_time,
		"tracking_locked": phase in [Phase.COMMITTED, Phase.LEAP, Phase.IMPACT_LOCK],
		"locked_direction": committed_direction,
		"lock_target_position": committed_target_position,
		"presentation_action": String(actual_action),
		"expected_action": String(expected_action),
		"presentation_animation": host.get_enemy_presentation_animation(),
		"presentation_frame": host.get_enemy_presentation_frame(),
		"presentation_playing": host.is_enemy_presentation_playing(),
		"expected_animation": host.resolve_enemy_action_animation(expected_action, direction),
		"presentation_matches_phase": expected_action.is_empty() or actual_action == expected_action,
	}


func _windup_progress() -> float:
	var total := config.total_windup_time()
	if total <= 0.0:
		return 1.0
	match phase:
		Phase.TRACKING:
			return clampf((config.tracking_time - phase_timer) / total, 0.0, 1.0)
		Phase.COMMITTED:
			var elapsed := config.tracking_time + config.committed_time - phase_timer
			return clampf(elapsed / total, 0.0, 1.0)
		Phase.IDLE:
			return 0.0
		_:
			return 1.0


func _attempt_commit() -> void:
	var hold := config.committed_time + config.leap_time + config.impact_lock_time + config.recovery_time
	if not bool(engagement_token_request.call(_target(), hold)):
		result = &"token_unavailable"
		host.observatory_increment(&"falcon_punch_token_rejected")
		_start_recovery()
		return
	committed_direction = direction
	var target := _target()
	if target != null:
		committed_target_position = target.global_position
	phase = Phase.COMMITTED
	phase_timer = maxf(0.01, config.committed_time)
	host.observatory_increment(&"falcon_punch_tracking_locks")
	_log(&"grunt_falcon_punch_tracking_locked")
	_audit_presentation()


func _move_tracking() -> void:
	host.velocity = direction * host.speed * config.tracking_speed_multiplier
	host.move_and_slide()
	host.set_ability_facing(direction)
	play_current_presentation()


func _retarget_tracking() -> void:
	var target := _target()
	if target == null or host.is_combat_target_destroyed(target):
		return
	var to_target := target.global_position - host.global_position
	if to_target.length_squared() > 0.0001:
		direction = to_target.normalized()


func _update_leap() -> void:
	var travel_time := maxf(0.01, config.leap_time * clampf(config.hit_active_ratio.y, 0.01, 1.0))
	host.velocity = direction * (current_distance / travel_time)
	host.move_and_slide()
	var target := _target()
	if target != null:
		var to_target := target.global_position - host.global_position
		closest_approach = minf(closest_approach, to_target.length())
		lateral_error = absf(to_target.cross(direction))
		if active_start_target_distance < 0.0 and _hit_window_active():
			active_start_target_distance = to_target.length()
	var collisions := host.get_slide_collision_count()
	var traveled := host.global_position.distance_to(launch_start)
	collision_obstructed = collision_obstructed or collisions > 0
	try_apply_hit(traveled >= current_distance or collisions > 0)
	if phase == Phase.LEAP and (collisions > 0 or traveled >= current_distance or phase_timer <= 0.0):
		resolve_whiff(&"blocked_by_collision" if collisions > 0 else _miss_reason())


func _start_impact_lock() -> void:
	phase = Phase.IMPACT_LOCK
	phase_timer = maxf(0.01, config.impact_lock_time)
	host.velocity = Vector2.ZERO
	play_current_presentation()
	_log(&"grunt_falcon_punch_impact_lock")
	_audit_presentation()


func _start_recovery() -> void:
	phase = Phase.RECOVERY
	phase_timer = maxf(0.01, config.recovery_time)
	host.velocity = Vector2.ZERO
	host.separate_ability_from_target(_target(), direction)
	play_current_presentation()
	_log(&"grunt_falcon_punch_recovery")
	_audit_presentation()


func _hit_window_active() -> bool:
	if phase != Phase.LEAP:
		return false
	var progress := clampf(1.0 - phase_timer / maxf(0.01, config.leap_time), 0.0, 1.0)
	return progress >= config.hit_active_ratio.x and progress <= config.hit_active_ratio.y


func _miss_reason() -> StringName:
	var target := _target()
	if target == null or host.is_combat_target_destroyed(target):
		return &"target_out_of_range"
	return &"target_out_of_arc" if absf((target.global_position - host.global_position).cross(direction)) > config.hit_lateral_reach_px else &"target_out_of_range"


func _target() -> Node2D:
	if target_ref == null:
		return null
	var value: Variant = target_ref.get_ref()
	return value as Node2D if value is Node2D and is_instance_valid(value) else null


func _log(event_name: StringName) -> void:
	host.observatory_log(event_name, get_telemetry())


func _audit_presentation() -> void:
	var data := get_telemetry()
	if not bool(data.get("presentation_matches_phase", true)):
		host.observatory_increment(&"falcon_punch_presentation_desync")
		host.observatory_log(&"grunt_falcon_punch_presentation_desync", data)
