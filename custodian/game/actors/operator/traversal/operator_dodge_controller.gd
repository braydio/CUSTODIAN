class_name OperatorDodgeController
extends RefCounted
## Fixed-step authority for Operator dodge charge, active traversal, recovery,
## chain/Flow state and cancellation. The chassis applies returned movement
## intent while the chassis retains physics-step ownership.

signal charge_changed(active: bool, ratio: float, ready: bool)
signal charge_released(ratio: float, direction: Vector2)
signal charge_cancelled(reason: StringName)
signal chain_started(index: int, flow: float, direction: Vector2)
signal chain_ended(count: int, flow: float, reason: StringName)
signal flow_changed(value: float, direction: Vector2)

var _active := false
var _recovery_active := false
var _active_remaining := 0.0
var _iframe_remaining := 0.0
var _recovery_remaining := 0.0
var _cooldown_remaining := 0.0
var _direction := Vector2.DOWN
var _backstep := false
var _charging := false
var _charge_elapsed := 0.0
var _pending_direction := Vector2.ZERO
var _profile: StringName = &"tap"
var _speed := 0.0
var _active_duration := 0.0
var _profile_recovery_duration := 0.0
var _recovery_elapsed := 0.0
var _fast_attack_buffered := false
var _chain_buffered := false
var _chain_direction := Vector2.ZERO
var _chain_index := 0
var _chain_last_turn_angle := 0.0
var _chain_last_retention := 1.0
var _chain_end_reason: StringName = &"opener_complete"
var _flow := 0.0
var _flow_direction := Vector2.ZERO
var _flow_decay_remaining := 0.0
var _exit_velocity := Vector2.ZERO
var _exit_remaining := 0.0


func is_active() -> bool:
	return _active


func is_recovering() -> bool:
	return _recovery_active


func is_charging() -> bool:
	return _charging


func is_busy() -> bool:
	return _charging or _active or _recovery_active


func is_iframe_active() -> bool:
	return _active and _iframe_remaining > 0.0


func get_phase() -> StringName:
	if _charging:
		return &"windup"
	if is_iframe_active():
		return &"iframe"
	if _active:
		return &"late_active"
	if _recovery_active:
		return &"recovery"
	return &"none"


func get_charge_status(ready_time: float) -> Dictionary:
	var ratio := get_charge_ratio(ready_time)
	return {
		"active": _charging,
		"ratio": ratio,
		"ready": _charging and ratio >= 1.0,
		"hold_time": _charge_elapsed,
		"ready_time": ready_time,
	}


func get_charge_ratio(ready_time: float) -> float:
	return get_charge_ratio_for_hold(_charge_elapsed, ready_time)


func get_charge_ratio_for_hold(hold_time: float, ready_time: float) -> float:
	return clampf(maxf(0.0, hold_time) / maxf(0.001, ready_time), 0.0, 1.0)


func get_profile_for_hold(hold_time: float, max_hold: float, long_min: float, committed_min: float) -> StringName:
	var safe_hold := minf(maxf(0.0, max_hold), maxf(0.0, hold_time))
	if safe_hold >= maxf(long_min, committed_min):
		return &"committed"
	if safe_hold >= maxf(0.0, long_min):
		return &"long"
	return &"tap"


func begin_charge(direction: Vector2) -> Dictionary:
	if is_busy() or _cooldown_remaining > 0.0:
		return {"started": false, "reason": &"dodge_locked"}
	_charging = true
	_charge_elapsed = 0.0
	_pending_direction = _safe_direction(direction, Vector2.DOWN)
	_fast_attack_buffered = false
	charge_changed.emit(true, 0.0, false)
	return {"started": true, "direction": _pending_direction}


func advance_charge(delta: float, max_hold: float, ready_time: float) -> Dictionary:
	if not _charging:
		return {"active": false}
	_charge_elapsed = minf(maxf(0.0, max_hold), _charge_elapsed + maxf(0.0, delta))
	var ratio := get_charge_ratio(ready_time)
	charge_changed.emit(true, ratio, ratio >= 1.0)
	return {"active": true, "ratio": ratio, "direction": _pending_direction}


func release_charge(max_hold: float, long_min: float, committed_min: float, ready_time: float) -> Dictionary:
	if not _charging:
		return {"released": false}
	var hold_time := minf(maxf(0.0, max_hold), _charge_elapsed)
	var ratio := get_charge_ratio(ready_time)
	var direction := _pending_direction
	var profile := get_profile_for_hold(hold_time, max_hold, long_min, committed_min)
	_charging = false
	_charge_elapsed = 0.0
	_pending_direction = Vector2.ZERO
	charge_changed.emit(false, ratio, ratio >= 1.0)
	return {"released": true, "hold_time": hold_time, "ratio": ratio, "direction": direction, "profile": profile}


func confirm_charge_release(ratio: float, direction: Vector2) -> void:
	charge_released.emit(ratio, direction)


func notify_charge_cancelled(reason: StringName) -> void:
	charge_cancelled.emit(reason)


func cancel_charge(reason: StringName, ready_time: float) -> Dictionary:
	if not _charging:
		return {"cancelled": false}
	var hold_time := _charge_elapsed
	_charging = false
	_charge_elapsed = 0.0
	_pending_direction = Vector2.ZERO
	charge_changed.emit(false, get_charge_ratio_for_hold(hold_time, ready_time), false)
	charge_cancelled.emit(reason)
	return {"cancelled": true, "hold_time": hold_time}


func get_profile_config(profile: StringName, tuning: Dictionary) -> Dictionary:
	match profile:
		&"long":
			return {
				"profile": &"long",
				"speed_multiplier": maxf(1.0, float(tuning.long_distance_multiplier)),
				"recovery_multiplier": maxf(1.0, float(tuning.long_recovery_multiplier)),
				"stamina_cost": maxf(float(tuning.stamina_cost), float(tuning.long_stamina_cost)),
			}
		&"committed":
			return {
				"profile": &"committed",
				"speed_multiplier": maxf(1.0, float(tuning.committed_distance_multiplier)),
				"recovery_multiplier": maxf(1.0, float(tuning.committed_recovery_multiplier)),
				"stamina_cost": maxf(float(tuning.stamina_cost), float(tuning.committed_stamina_cost)),
			}
		_:
			return {"profile": &"tap", "speed_multiplier": 1.0, "recovery_multiplier": 1.0, "stamina_cost": float(tuning.stamina_cost)}


func start_dodge(direction: Vector2, profile: StringName, charge_ratio: float, combat_pressure: bool, available_stamina: float, backstep: bool, tuning: Dictionary) -> Dictionary:
	if is_busy() or _cooldown_remaining > 0.0:
		return {"started": false, "reason": &"dodge_locked"}
	var config := get_profile_config(profile, tuning)
	var stamina_cost := float(config.stamina_cost)
	if not combat_pressure:
		stamina_cost = 0.0
	if available_stamina < stamina_cost:
		return {"started": false, "reason": &"insufficient_stamina", "stamina_cost": stamina_cost}
	_chain_buffered = false
	_chain_direction = Vector2.ZERO
	_chain_index = 0
	_chain_last_turn_angle = 0.0
	_chain_last_retention = 1.0
	_chain_end_reason = &"opener_complete"
	_recovery_elapsed = 0.0
	_exit_remaining = 0.0
	_exit_velocity = Vector2.ZERO
	_profile = StringName(config.profile)
	_speed = float(tuning.speed) * float(config.speed_multiplier)
	_active_duration = maxf(0.05, float(tuning.duration))
	_profile_recovery_duration = maxf(0.0, float(tuning.recovery_duration) * float(config.recovery_multiplier))
	_direction = _safe_direction(direction, Vector2.DOWN)
	_backstep = backstep
	_active = true
	_recovery_active = false
	_active_remaining = _active_duration
	_iframe_remaining = minf(maxf(0.0, float(tuning.iframe_duration)), _active_remaining)
	_recovery_remaining = 0.0
	_cooldown_remaining = 0.0
	_establish_flow(_profile, charge_ratio, _direction, tuning)
	return {"started": true, "profile": _profile, "direction": _direction, "speed": _speed, "duration": _active_duration, "iframe_duration": _iframe_remaining, "recovery_duration": _profile_recovery_duration, "stamina_cost": stamina_cost, "flow": _flow, "backstep": _backstep}


func buffer_chain(direction: Vector2, source: StringName, enabled: bool) -> Dictionary:
	if not enabled or (not _active and not _recovery_active):
		return {"buffered": false}
	_chain_buffered = true
	_chain_direction = _safe_direction(direction, _direction)
	return {"buffered": true, "source": source, "next_index": _chain_index + 1, "flow": _flow, "direction": _chain_direction, "active_remaining": _active_remaining, "recovery_elapsed": _recovery_elapsed}


func is_chain_buffered() -> bool:
	return _chain_buffered


func get_chain_buffer_window(tap_window: float, late_grace: float) -> Dictionary:
	return {
		"active_elapsed": maxf(0.0, _active_duration - _active_remaining),
		"active_open": _active and maxf(0.0, _active_duration - _active_remaining) >= maxf(0.0, tap_window),
		"recovery_elapsed": _recovery_elapsed,
		"recovery_open": _recovery_active and _recovery_elapsed <= maxf(0.0, late_grace),
	}


func launch_buffered_chain(context: Dictionary, tuning: Dictionary) -> Dictionary:
	if not _chain_buffered:
		return {"started": false, "reason": &"not_buffered"}
	var next_direction := _safe_direction(_chain_direction, _direction)
	_chain_buffered = false
	_chain_direction = Vector2.ZERO
	if bool(context.get("runtime_locked", false)):
		_chain_end_reason = &"runtime_lock"
		return {"started": false, "reason": _chain_end_reason}
	var next_index := _chain_index + 1
	var stamina_cost := _chain_stamina_cost(next_index, bool(context.get("combat_pressure", false)), tuning)
	if float(context.get("available_stamina", 0.0)) < stamina_cost:
		_chain_end_reason = &"insufficient_stamina"
		return {"started": false, "reason": _chain_end_reason, "stamina_cost": stamina_cost}
	var previous_direction := _safe_direction(_flow_direction, _direction)
	var turn_angle := absf(rad_to_deg(previous_direction.angle_to(next_direction)))
	var retention := _flow_retention_for_turn(previous_direction, next_direction)
	_set_flow(clampf(_flow * retention, 0.0, 1.0), next_direction)
	_chain_last_turn_angle = turn_angle
	_chain_last_retention = retention
	_chain_index = next_index
	_chain_end_reason = &"input_released"
	_profile = &"chain"
	_speed = float(tuning.speed) * lerpf(1.0, 1.0 + maxf(0.0, float(tuning.flow_speed_bonus)), _flow)
	_active_duration = maxf(0.05, float(tuning.duration))
	_profile_recovery_duration = _resolve_recovery_duration(bool(context.get("combat_pressure", false)), tuning)
	_direction = next_direction
	_backstep = bool(context.get("backstep", false))
	_active = true
	_recovery_active = false
	_active_remaining = _active_duration
	_iframe_remaining = minf(maxf(0.0, _chain_iframe_duration(next_index, bool(context.get("combat_pressure", false)), tuning)), _active_remaining)
	_recovery_remaining = 0.0
	_recovery_elapsed = 0.0
	_cooldown_remaining = 0.0
	_fast_attack_buffered = false
	chain_started.emit(_chain_index, _flow, _direction)
	return {"started": true, "index": _chain_index, "flow": _flow, "direction": _direction, "turn_angle": turn_angle, "retention": retention, "speed": _speed, "duration": _active_duration, "recovery_duration": _profile_recovery_duration, "iframe_duration": _iframe_remaining, "stamina_cost": stamina_cost, "animation_start_frame": _chain_animation_start_frame(turn_angle)}


func advance_active(delta: float, tuning: Dictionary) -> Dictionary:
	if not _active:
		return {"active": false}
	_active_remaining = maxf(0.0, _active_remaining - maxf(0.0, delta))
	var end_speed_factor := _flow_end_speed_factor(_flow, tuning) if _profile == &"chain" else 0.45
	var speed_now := _speed * lerpf(end_speed_factor, 1.0, _active_remaining / maxf(0.05, _active_duration))
	var result := {"active": _active_remaining > 0.0, "velocity": _direction * speed_now, "remaining": _active_remaining}
	if _active_remaining <= 0.0:
		_active = false
		_iframe_remaining = 0.0
		result["ended"] = true
	return result


func begin_recovery(cooldown: float) -> Dictionary:
	_iframe_remaining = 0.0
	_recovery_remaining = maxf(0.0, _profile_recovery_duration)
	_recovery_elapsed = 0.0
	_cooldown_remaining = maxf(cooldown, _recovery_remaining)
	_recovery_active = _recovery_remaining > 0.0
	return {"active": _recovery_active, "duration": _recovery_remaining, "profile": _profile}


func set_recovery_active(active: bool) -> void:
	_recovery_active = active


func set_chain_end_reason(reason: StringName) -> void:
	_chain_end_reason = reason


func complete_recovery() -> StringName:
	var completed_profile := _profile
	_recovery_active = false
	_backstep = false
	_profile = &"tap"
	return completed_profile


func advance_recovery(delta: float) -> Dictionary:
	if not _recovery_active:
		return {"active": false}
	_recovery_elapsed += maxf(0.0, delta)
	_recovery_remaining = maxf(0.0, _recovery_remaining - maxf(0.0, delta))
	var ended := _recovery_remaining <= 0.0
	if ended:
		_recovery_active = false
		_backstep = false
		var completed_profile := complete_recovery()
		return {"active": false, "ended": true, "remaining": _recovery_remaining, "profile": completed_profile}
	return {"active": true, "ended": false, "remaining": _recovery_remaining}


func set_fast_attack_buffered(buffered: bool) -> void:
	_fast_attack_buffered = buffered


func consume_fast_attack_buffered() -> bool:
	var buffered := _fast_attack_buffered
	_fast_attack_buffered = false
	return buffered


func cancel_recovery_for_fast_attack(combat_pressure: bool, tuning: Dictionary) -> Dictionary:
	_active = false
	_recovery_active = false
	_active_remaining = 0.0
	_iframe_remaining = 0.0
	_recovery_remaining = 0.0
	_backstep = false
	_profile = &"tap"
	return {"reason": &"attack_cancel"}


func cancel(reason: StringName, combat_pressure: bool, tuning: Dictionary) -> Dictionary:
	var had_sequence := _flow > 0.0 or _chain_index > 0
	cancel_charge(reason, float(tuning.get("committed_min_hold", 0.30)))
	_active = false
	_recovery_active = false
	_active_remaining = 0.0
	_iframe_remaining = 0.0
	_recovery_remaining = 0.0
	_backstep = false
	_fast_attack_buffered = false
	_profile = &"tap"
	_speed = 0.0
	_active_duration = 0.0
	_profile_recovery_duration = 0.0
	if had_sequence:
		finish_flow_sequence(reason, false, combat_pressure, tuning)
	_set_flow(0.0, Vector2.ZERO)
	return {"had_sequence": had_sequence}


func is_invulnerable(is_dead: bool) -> bool:
	return is_iframe_active() and not is_dead


func get_direction() -> Vector2:
	return _direction


func get_profile() -> StringName:
	return _profile


func get_backstep() -> bool:
	return _backstep


func get_active_remaining() -> float:
	return _active_remaining


func get_iframe_remaining() -> float:
	return _iframe_remaining


func get_recovery_remaining() -> float:
	return _recovery_remaining


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func get_charge_hold_time() -> float:
	return _charge_elapsed


func get_pending_direction() -> Vector2:
	return _pending_direction


func get_speed() -> float:
	return _speed


func get_active_duration() -> float:
	return _active_duration


func get_profile_recovery_duration() -> float:
	return _profile_recovery_duration


func has_fast_attack_buffered() -> bool:
	return _fast_attack_buffered


func get_recovery_elapsed() -> float:
	return _recovery_elapsed


func advance_clocks(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - maxf(0.0, delta))
	_iframe_remaining = maxf(0.0, _iframe_remaining - maxf(0.0, delta))


func set_exit_carry_target(current_target: Vector2, moving: bool, delta: float, tuning: Dictionary) -> Vector2:
	if _exit_remaining <= 0.0:
		return current_target
	var ratio := clampf(_exit_remaining / maxf(0.001, float(tuning.exit_carry_duration)), 0.0, 1.0)
	var carry_target := _exit_velocity * ratio
	var target := carry_target.lerp(current_target, 1.0 - ratio) if moving else carry_target
	_exit_remaining = maxf(0.0, _exit_remaining - maxf(0.0, delta))
	if _exit_remaining <= 0.0:
		_exit_velocity = Vector2.ZERO
	return target


func update_flow_decay(delta: float, move_direction: Vector2, sprinting: bool, tuning: Dictionary, combat_pressure: bool) -> void:
	if _flow <= 0.0:
		return
	if _charging or _active or _recovery_active or _exit_remaining > 0.0:
		_flow_decay_remaining = maxf(0.0, float(tuning.flow_decay_delay))
		return
	if _flow_decay_remaining > 0.0:
		_flow_decay_remaining = maxf(0.0, _flow_decay_remaining - maxf(0.0, delta))
		return
	var decay_rate := maxf(0.0, float(tuning.flow_decay_per_second))
	if sprinting and move_direction.length_squared() > 0.01 and move_direction.normalized().dot(_flow_direction) >= 0.70:
		decay_rate *= 0.45
	var next_flow := maxf(0.0, _flow - decay_rate * maxf(0.0, delta))
	_set_flow(next_flow, _flow_direction if next_flow > 0.0 else Vector2.ZERO)


func finish_flow_sequence(reason: StringName, allow_exit_carry: bool, combat_pressure: bool, tuning: Dictionary) -> Dictionary:
	var final_flow := _flow
	var chain_count := _chain_index
	if allow_exit_carry and _flow > 0.0 and _flow_direction.length_squared() > 0.0001:
		var carry_speed_mult := float(tuning.combat_exit_carry_speed_mult) if combat_pressure else 1.45
		var carry_duration := float(tuning.combat_exit_carry_duration) if combat_pressure else float(tuning.exit_carry_duration)
		_exit_velocity = _flow_direction * float(tuning.base_speed) * lerpf(1.0, carry_speed_mult, _flow)
		_exit_remaining = maxf(0.0, carry_duration)
	else:
		_exit_velocity = Vector2.ZERO
		_exit_remaining = 0.0
	if chain_count > 0:
		chain_ended.emit(chain_count, final_flow, reason)
	_chain_buffered = false
	_chain_direction = Vector2.ZERO
	_chain_index = 0
	_flow_decay_remaining = maxf(0.0, float(tuning.flow_decay_delay))
	return {"count": chain_count, "flow": final_flow, "direction": _flow_direction, "reason": reason, "exit_velocity": _exit_velocity, "exit_duration": _exit_remaining}


func clear_flow() -> void:
	_set_flow(0.0, Vector2.ZERO)


func set_flow(value: float, direction: Vector2) -> void:
	_set_flow(value, direction)


func get_exit_velocity() -> Vector2:
	return _exit_velocity


func get_exit_remaining() -> float:
	return _exit_remaining


func get_chain_index() -> int:
	return _chain_index


func get_flow_value() -> float:
	return _flow


func get_flow_direction() -> Vector2:
	return _flow_direction


func get_chain_end_reason() -> StringName:
	return _chain_end_reason


func get_chain_buffer_direction() -> Vector2:
	return _chain_direction


func get_presentation_turn_data() -> Dictionary:
	return {"turn_angle": _chain_last_turn_angle, "retention": _chain_last_retention}


func flow_retention_for_turn(old_direction: Vector2, new_direction: Vector2) -> float:
	if old_direction.length_squared() <= 0.0001 or new_direction.length_squared() <= 0.0001:
		return 0.0
	return _flow_retention_for_turn(old_direction.normalized(), new_direction.normalized())


func get_chain_animation_start_frame(turn_angle: float) -> int:
	return _chain_animation_start_frame(turn_angle)


func get_chain_stamina_cost(index: int, combat_pressure: bool, tuning: Dictionary) -> float:
	return _chain_stamina_cost(index, combat_pressure, tuning)


func get_chain_iframe_duration(index: int, combat_pressure: bool, tuning: Dictionary) -> float:
	return _chain_iframe_duration(index, combat_pressure, tuning)


func resolve_recovery_duration(combat_pressure: bool, tuning: Dictionary) -> float:
	return _resolve_recovery_duration(combat_pressure, tuning)


func get_flow_end_speed_factor(flow: float, tuning: Dictionary) -> float:
	return _flow_end_speed_factor(flow, tuning)


func get_flow_status(presentation: Dictionary = {}) -> Dictionary:
	var status := {
		"flow": _flow,
		"direction": _flow_direction,
		"chain_index": _chain_index,
		"chain_buffered": _chain_buffered,
		"chain_direction": _chain_direction,
		"turn_angle": _chain_last_turn_angle,
		"retention": _chain_last_retention,
		"exit_velocity": _exit_velocity,
		"exit_time_remaining": _exit_remaining,
	}
	status.merge(presentation, true)
	return status


func get_runtime_status() -> Dictionary:
	return {
		"active": _active,
		"recovery_active": _recovery_active,
		"charging": _charging,
		"phase": get_phase(),
		"active_remaining": _active_remaining,
		"active_duration": _active_duration,
		"iframe_remaining": _iframe_remaining,
		"recovery_remaining": _recovery_remaining,
		"recovery_duration": _profile_recovery_duration,
		"cooldown_remaining": _cooldown_remaining,
		"direction": _direction,
		"backstep": _backstep,
		"profile": _profile,
		"speed": _speed,
		"pending_direction": _pending_direction,
		"hold_time": _charge_elapsed,
		"recovery_elapsed": _recovery_elapsed,
		"fast_attack_buffered": _fast_attack_buffered,
		"chain_buffered": _chain_buffered,
		"chain_direction": _chain_direction,
		"chain_index": _chain_index,
		"turn_angle": _chain_last_turn_angle,
		"retention": _chain_last_retention,
		"chain_end_reason": _chain_end_reason,
		"flow": _flow,
		"flow_direction": _flow_direction,
		"flow_decay_remaining": _flow_decay_remaining,
		"exit_velocity": _exit_velocity,
		"exit_time_remaining": _exit_remaining,
	}


func _establish_flow(profile: StringName, charge_ratio: float, direction: Vector2, tuning: Dictionary) -> void:
	var initial_flow := 0.35
	if charge_ratio >= 0.0:
		initial_flow = lerpf(0.35, 1.0, clampf(charge_ratio, 0.0, 1.0))
	else:
		match profile:
			&"long": initial_flow = 0.65
			&"committed": initial_flow = 1.0
	_set_flow(initial_flow, direction)
	_flow_decay_remaining = maxf(0.0, float(tuning.flow_decay_delay))


func _set_flow(value: float, direction: Vector2) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	var normalized := direction.normalized()
	var changed := not is_equal_approx(clamped, _flow) or (normalized != Vector2.ZERO and not normalized.is_equal_approx(_flow_direction))
	_flow = clamped
	if normalized != Vector2.ZERO:
		_flow_direction = normalized
	if _flow <= 0.0 and normalized == Vector2.ZERO:
		_flow_direction = Vector2.ZERO
	if changed:
		flow_changed.emit(_flow, _flow_direction)


func _resolve_recovery_duration(combat_pressure: bool, tuning: Dictionary) -> float:
	var base := float(tuning.recovery_duration)
	if combat_pressure:
		return maxf(0.0, lerpf(base, float(tuning.combat_recovery_ceiling), _flow))
	return maxf(0.0, base * lerpf(1.0, maxf(0.0, 1.0 - float(tuning.flow_recovery_reduction)), _flow))


func _chain_stamina_cost(index: int, combat_pressure: bool, tuning: Dictionary) -> float:
	var costs: PackedFloat32Array = tuning.combat_chain_stamina_costs
	if not combat_pressure or costs.is_empty():
		return float(tuning.stamina_cost)
	return costs[mini(maxi(index, 0), costs.size() - 1)]


func _chain_iframe_duration(index: int, combat_pressure: bool, tuning: Dictionary) -> float:
	var durations: PackedFloat32Array = tuning.combat_chain_iframe_durations
	if not combat_pressure or durations.is_empty():
		return float(tuning.iframe_duration)
	return durations[mini(maxi(index, 0), durations.size() - 1)]


func _flow_retention_for_turn(old_direction: Vector2, new_direction: Vector2) -> float:
	var angle := absf(rad_to_deg(old_direction.angle_to(new_direction)))
	if angle <= 45.001: return 1.0
	if angle <= 90.001: return 0.75
	if angle <= 135.001: return 0.40
	return 0.0


func _chain_animation_start_frame(turn_angle: float) -> int:
	if turn_angle <= 45.001: return 2
	if turn_angle <= 90.001: return 1
	return 0


func _flow_end_speed_factor(flow: float, tuning: Dictionary) -> float:
	var safe_flow := clampf(flow, 0.0, 1.0)
	var peak_multiplier := lerpf(1.0, 1.0 + maxf(0.0, float(tuning.get("flow_speed_bonus", 0.12))), safe_flow)
	var distance_multiplier := lerpf(1.0, 1.0 + maxf(0.0, float(tuning.get("flow_distance_bonus", 0.18))), safe_flow)
	var base_average := (1.0 + 0.45) * 0.5
	var desired_average := base_average * distance_multiplier / maxf(0.001, peak_multiplier)
	return clampf(desired_average * 2.0 - 1.0, 0.45, 1.0)


func _safe_direction(direction: Vector2, fallback: Vector2) -> Vector2:
	return direction.normalized() if direction.length_squared() > 0.0001 else fallback.normalized()
