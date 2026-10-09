extends RefCounted
class_name SavageChain

## The Savage-specific two-hit lifecycle. Generic cadence and contact tuning
## remain host-owned so later ordinary-melee work can compare the real seams.
var host: Enemy
var config: SavageChainConfig
var phase: StringName = &""
var timer: float = 0.0
var direction: Vector2 = Vector2.RIGHT


func setup(new_host: Enemy, new_config: SavageChainConfig) -> void:
	host = new_host
	config = new_config


func is_active() -> bool:
	return not phase.is_empty()


func get_debug_state() -> Dictionary:
	return {
		"phase": String(phase),
		"timer": timer,
		"direction": direction,
	}


func start() -> bool:
	if host == null or config == null or not host.savage_chain_enabled or is_active():
		return false
	phase = &"windup_1"
	timer = maxf(0.01, host.attack_windup_duration)
	direction = host.global_position.direction_to(
		(host.target as Node2D).global_position
	) if host.target is Node2D else host.get_ability_facing()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	host.set_ability_facing(direction)
	host.velocity = Vector2.ZERO
	host.clear_path()
	if host.has_custom_ability_presentation():
		host.play_custom_ability_attack(direction)
	host.log_savage_event(&"savage_chain_windup_1", &"")
	return true


func tick(delta: float) -> bool:
	if not is_active():
		return false
	timer = maxf(0.0, timer - delta)
	host.velocity = Vector2.ZERO
	if timer > 0.0:
		return true
	match phase:
		&"windup_1":
			_resolve_hit(host.damage, &"savage_chain_1", config.first_guard_stamina_damage)
			if phase != &"windup_1":
				return true
			phase = &"gap"
			timer = maxf(0.01, config.gap_time)
		&"gap":
			phase = &"windup_2"
			timer = maxf(0.01, config.second_windup_time)
			host.log_savage_event(&"savage_chain_windup_2", &"")
		&"windup_2":
			_resolve_hit(config.second_damage, &"savage_chain_2", config.second_guard_stamina_damage)
			if phase != &"windup_2":
				return true
			phase = &"recovery"
			timer = maxf(0.01, config.recovery_time)
			host.log_savage_event(&"savage_chain_recovery", &"")
		&"recovery":
			_finish()
		_:
			_finish()
	return true


func cancel() -> bool:
	if not is_active():
		return false
	phase = &""
	timer = 0.0
	host.velocity = Vector2.ZERO
	return true


func _resolve_hit(hit_damage: float, hit_kind: StringName, guard_stamina_damage: float) -> void:
	var target := host.target as Node2D
	if target == null or not is_instance_valid(target) or host.is_combat_target_destroyed(target):
		host.log_savage_event(&"savage_chain_whiff", &"")
		return
	var spatial := host.get_ability_melee_spatial_context(target, direction)
	if not bool(spatial.get("spatial_valid", false)):
		host.log_savage_event(&"savage_chain_whiff", &"")
		return
	var result := host.resolve_ability_hit(
		target, hit_damage, hit_kind, "", spatial, guard_stamina_damage
	)
	host.log_savage_event(&"savage_chain_hit", &"", result)


func _finish() -> void:
	phase = &""
	timer = 0.0
	host.velocity = Vector2.ZERO
