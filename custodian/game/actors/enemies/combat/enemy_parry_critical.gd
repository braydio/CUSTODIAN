extends RefCounted
class_name EnemyParryCritical

enum Phase { NONE, ENTER, HOLD, RECOVER, EXECUTING }

const VICTIM_ANIMATIONS := {
	&"s": &"critical_execution_victim_s",
	&"e": &"critical_execution_victim_e",
	&"w": &"critical_execution_victim_w",
}
const REVERSAL_ANIMATIONS := {
	&"e": &"falcon_reversal_victim_e",
	&"w": &"falcon_reversal_victim_w",
}

var host: Enemy
var config: EnemyParryCriticalConfig

var _window_timer := 0.0
var _phase := Phase.NONE
var _reserved_attacker: Node2D
var _phase_timer := 0.0
var _execution_token := 0
var _damage_consumed := false
var _execution_root := Vector2.ZERO
var _execution_direction: StringName = &"s"
var _execution_kind: StringName = &"ordinary_critical"
var _standalone_root := Vector2.ZERO
var _standalone_root_valid := false


func setup(new_host: Enemy, new_config: EnemyParryCriticalConfig) -> void:
	host = new_host
	config = new_config


func get_phase() -> int:
	return _phase


func get_phase_name() -> StringName:
	return [&"none", &"enter", &"hold", &"recover", &"executing"][clampi(_phase, 0, 4)]


func get_window_remaining() -> float:
	return _window_timer


func get_phase_remaining() -> float:
	return _phase_timer


func is_active() -> bool:
	return _phase != Phase.NONE


func is_executing() -> bool:
	return _phase == Phase.EXECUTING


func is_open() -> bool:
	return _window_timer > 0.0 and _phase in [Phase.ENTER, Phase.HOLD]


func blocks_normal_behavior() -> bool:
	return is_active()


func suppresses_normal_targeting() -> bool:
	return _phase in [Phase.ENTER, Phase.HOLD, Phase.RECOVER, Phase.EXECUTING]


func get_execution_root() -> Vector2:
	return _execution_root


func get_execution_kind() -> StringName:
	return _execution_kind


func get_execution_direction() -> StringName:
	return _execution_direction


func get_reserved_attacker() -> Node2D:
	return _reserved_attacker


func get_execution_token() -> int:
	return _execution_token


func get_debug_state() -> Dictionary:
	return {
		"phase": String(get_phase_name()),
		"window_remaining": _window_timer,
		"phase_remaining": _phase_timer,
		"reserved_attacker_id": _reserved_attacker.get_instance_id() if _reserved_attacker != null and is_instance_valid(_reserved_attacker) else 0,
		"execution_token": _execution_token,
		"damage_consumed": _damage_consumed,
		"execution_root": _execution_root,
		"execution_direction": String(_execution_direction),
		"execution_kind": String(_execution_kind),
		"standalone_root": _standalone_root,
		"standalone_root_valid": _standalone_root_valid,
	}


func open_window(duration: float) -> float:
	_window_timer = maxf(maxf(duration, config.minimum_window_sec), host.get_parry_enter_animation_duration())
	_standalone_root_valid = false
	_enter_phase(Phase.ENTER)
	return _window_timer


func force_phase(phase: int) -> void:
	if phase not in [Phase.ENTER, Phase.HOLD, Phase.RECOVER]:
		return
	if phase == Phase.RECOVER:
		_window_timer = 0.0
	_enter_phase(phase)
	if phase == Phase.HOLD:
		_enter_phase(phase)


func set_standalone_root(root: Vector2) -> void:
	_standalone_root = root
	_standalone_root_valid = true


func cancel_opportunity() -> void:
	if _phase == Phase.EXECUTING:
		return
	_window_timer = 0.0
	_phase_timer = 0.0
	_phase = Phase.NONE
	_standalone_root_valid = false


func tick(delta: float) -> bool:
	if _phase == Phase.EXECUTING:
		host.velocity = Vector2.ZERO
		host.global_position = _execution_root
		if _reserved_attacker == null or not is_instance_valid(_reserved_attacker):
			host.cancel_parry_critical_execution(null, &"owner_invalid")
		return true
	if _phase in [Phase.ENTER, Phase.HOLD]:
		_preserve_standalone_root()
		_window_timer = maxf(0.0, _window_timer - delta)
		_phase_timer = maxf(0.0, _phase_timer - delta)
		host.velocity = Vector2.ZERO
		if _window_timer <= 0.0:
			host.on_parry_critical_window_expired()
			_enter_phase(Phase.RECOVER)
		elif _phase == Phase.ENTER and _phase_timer <= 0.0:
			_enter_phase(Phase.HOLD)
		host.refresh_parry_critical_presentation()
		return true
	if _phase == Phase.RECOVER:
		_preserve_standalone_root()
		_phase_timer = maxf(0.0, _phase_timer - delta)
		host.velocity = Vector2.ZERO
		if _phase_timer <= 0.0:
			_phase = Phase.NONE
			_standalone_root_valid = false
		host.refresh_parry_critical_presentation()
		return true
	return false


func can_receive_from(attacker: Node2D) -> bool:
	if host.dead or attacker == null or not is_instance_valid(attacker):
		return false
	if not host.uses_grunt_critical_window() or not is_open() or _reserved_attacker != null:
		return false
	return host.global_position.distance_to(attacker.global_position) <= config.capture_range_px


func get_rejection_reason(attacker: Node2D) -> StringName:
	if _phase not in [Phase.ENTER, Phase.HOLD]:
		return &""
	if host.dead:
		return &"target_dead"
	if _reserved_attacker != null:
		return &"already_reserved"
	if _window_timer <= 0.0:
		return &"window_expired"
	if attacker == null or not is_instance_valid(attacker):
		return &"invalid_attacker"
	if host.global_position.distance_to(attacker.global_position) > config.capture_range_px:
		return &"out_of_capture_range"
	return &""


func reserve(attacker: Node2D, kind: StringName, direction: StringName) -> Dictionary:
	if attacker == null or not is_instance_valid(attacker) or host.dead:
		return {}
	_execution_token += 1
	_reserved_attacker = attacker
	_damage_consumed = false
	_window_timer = 0.0
	_phase = Phase.EXECUTING
	_phase_timer = 0.0
	_standalone_root_valid = false
	_execution_direction = direction
	_execution_kind = kind
	_execution_root = host.get_parry_critical_execution_anchor()
	host.global_position = _execution_root
	host.on_parry_critical_reserved(kind, _execution_token)
	return {
		"token": _execution_token,
		"anchor": _execution_root,
		"operator_offset": config.operator_offset,
		"facing": get_facing(),
		"direction": _execution_direction,
		"execution_kind": _execution_kind,
	}


func begin_execution(attacker: Node2D, token: int) -> bool:
	if not is_valid_owner(attacker, token):
		return false
	host.velocity = Vector2.ZERO
	host.global_position = _execution_root
	return host.begin_parry_execution_presentation(get_execution_animation())


func set_execution_frame(attacker: Node2D, token: int, frame_index: int) -> bool:
	if not is_valid_owner(attacker, token):
		return false
	host.global_position = _execution_root
	host.velocity = Vector2.ZERO
	return host.set_parry_execution_presentation_frame(get_execution_animation(), frame_index)


func try_consume_damage(attacker: Node2D, token: int) -> bool:
	if not is_valid_owner(attacker, token) or _damage_consumed:
		return false
	_damage_consumed = true
	return true


func finish_execution(attacker: Node2D, token: int) -> bool:
	if not is_valid_owner(attacker, token):
		return false
	_release_execution_owner()
	if host.dead:
		return true
	_phase = Phase.NONE
	host.start_parry_critical_recovery()
	host.refresh_parry_critical_presentation()
	return true


func cancel_execution(attacker: Node2D, reason: StringName) -> bool:
	if _phase != Phase.EXECUTING:
		return false
	if attacker != null and is_instance_valid(attacker) and attacker != _reserved_attacker:
		return false
	_release_execution_owner()
	if host.dead:
		return true
	_phase = Phase.NONE
	host.start_parry_critical_recovery()
	host.observatory_log(&"enemy_parry_execution_cancelled", {"enemy_id": host.get_instance_id(), "reason": String(reason)})
	host.refresh_parry_critical_presentation()
	return true


func reset_for_death() -> void:
	_release_execution_owner()
	_phase = Phase.NONE
	_standalone_root_valid = false


func get_facing() -> Vector2:
	match _execution_direction:
		&"e": return Vector2.RIGHT
		&"w": return Vector2.LEFT
		_: return Vector2.DOWN


func resolve_direction(attacker: Node2D) -> StringName:
	if attacker == null or not is_instance_valid(attacker):
		return &"s"
	var approach := attacker.global_position.direction_to(host.global_position)
	if absf(approach.x) > absf(approach.y):
		return &"e" if approach.x > 0.0 else &"w"
	return &"s"


func resolve_falcon_direction(incoming_direction: Vector2) -> StringName:
	if incoming_direction.x > 0.0001:
		return &"w"
	if incoming_direction.x < -0.0001:
		return &"e"
	return &""


func can_use_falcon_reversal(attacker: Node2D, incoming_direction: Vector2) -> bool:
	if host.dead or not host.is_grunt() or not host.falcon_can_receive_reversal(attacker):
		return false
	if _reserved_attacker != null or _phase == Phase.EXECUTING:
		return false
	var direction := resolve_falcon_direction(incoming_direction)
	return not direction.is_empty() and host.has_parry_execution_animation(REVERSAL_ANIMATIONS.get(direction, &""))


func get_execution_animation() -> StringName:
	if _execution_kind == &"falcon_reversal":
		return REVERSAL_ANIMATIONS.get(_execution_direction, &"")
	return VICTIM_ANIMATIONS.get(_execution_direction, VICTIM_ANIMATIONS[&"s"])


func is_valid_owner(attacker: Node2D, token: int) -> bool:
	return _phase == Phase.EXECUTING and not host.dead \
		and attacker != null and is_instance_valid(attacker) \
		and attacker == _reserved_attacker and token == _execution_token


func _enter_phase(phase: int) -> void:
	_phase = phase
	host.velocity = Vector2.ZERO
	var animation_name: StringName = [&"", &"critical_open_enter_s", &"critical_open_hold_s", &"critical_open_recover_s", &""][clampi(phase, 0, 4)]
	if phase in [Phase.ENTER, Phase.HOLD, Phase.RECOVER]:
		_phase_timer = host.get_enemy_animation_duration(animation_name)
	else:
		_phase_timer = 0.0
	host.play_enemy_animation(animation_name)


func _preserve_standalone_root() -> void:
	if not _standalone_root_valid:
		_standalone_root = host.global_position
		_standalone_root_valid = true
	if OS.is_debug_build():
		assert(host.global_position.is_equal_approx(_standalone_root), "Critical-open standalone state changed the enemy world root.")
	host.global_position = _standalone_root
	host.velocity = Vector2.ZERO


func _release_execution_owner() -> void:
	host.restore_parry_execution_presentation()
	_reserved_attacker = null
	_phase_timer = 0.0
	_window_timer = 0.0
	_damage_consumed = false
	_execution_direction = &"s"
	_execution_kind = &"ordinary_critical"
	host.on_parry_critical_released()
