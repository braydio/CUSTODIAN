extends RefCounted
class_name EnemyReactionController

const CombatConstants = preload("res://game/systems/combat/combat_constants.gd")

var host: Enemy
var config: EnemyReactionConfig

var _stagger_timer := 0.0
var _recoil_timer := 0.0
var _posture_current := 0.0
var _posture_recovery_delay_timer := 0.0
var _light_flinch_cooldown_timer := 0.0
var _crit_timer := 0.0
var _crit_recovery_timer := 0.0


func setup(new_host: Enemy, new_config: EnemyReactionConfig) -> void:
	host = new_host
	config = new_config


func apply_reaction(amount: float, hit_strength: int) -> void:
	if host.is_parry_critical_active():
		return
	var posture_damage := maxf(0.0, amount)
	if posture_damage > 0.0:
		_posture_current = minf(maxf(1.0, config.posture_max), _posture_current + posture_damage)
		_posture_recovery_delay_timer = maxf(0.0, config.posture_recovery_delay)
		host.observatory_accumulate(&"enemy_posture_damage_received", posture_damage)
	if _posture_current + 0.0001 >= maxf(1.0, config.posture_max):
		_posture_current = 0.0
		_posture_recovery_delay_timer = maxf(0.0, config.posture_recovery_delay)
		request_stagger(config.stagger_duration)
		host.observatory_increment(&"enemy_posture_break")
		host.observatory_increment(&"enemy_reactions_stagger", 1)
		host.observatory_log(&"enemy_posture_break", {
			"enemy_id": host.get_instance_id(),
			"posture_max": config.posture_max,
		})
		return
	if hit_strength == CombatConstants.HitStrength.INTERRUPT:
		request_stagger(config.stagger_duration)
		host.observatory_increment(&"enemy_reactions_interrupt", 1)
		return
	if hit_strength == CombatConstants.HitStrength.HEAVY:
		request_stagger(config.stagger_duration)
		host.observatory_increment(&"enemy_reactions_stagger", 1)
	elif config.resists_light_flinch:
		host.play_armor_deflect_reaction()
		host.observatory_increment(&"enemy_reactions_armor_deflect", 1)
	elif host.is_standard_enemy_melee_committed():
		host.play_light_contact_visual_reaction(amount)
		host.observatory_increment(&"enemy_light_flinch_suppressed_commit")
		host.observatory_increment(&"enemy_attack_survived_light_contact")
	elif _light_flinch_cooldown_timer > 0.0:
		host.play_light_contact_visual_reaction(amount)
		host.observatory_increment(&"enemy_light_flinch_suppressed_cooldown")
	else:
		request_recoil(config.hit_recoil_duration, amount)
		_light_flinch_cooldown_timer = maxf(0.0, config.light_flinch_cooldown)
		host.observatory_increment(&"enemy_light_flinch_applied")
		host.observatory_increment(&"enemy_reactions_flinch", 1)


func request_recoil(duration: float, applied_damage: float = 0.0) -> void:
	_recoil_timer = maxf(_recoil_timer, maxf(0.0, duration))
	host.on_reaction_recoil_requested(applied_damage)


func request_stagger(duration: float, notify_host: bool = true) -> void:
	_stagger_timer = maxf(_stagger_timer, maxf(0.0, duration))
	_recoil_timer = 0.0
	if notify_host:
		host.on_reaction_stagger_requested()


func request_critical_hit() -> void:
	_posture_current = 0.0
	_posture_recovery_delay_timer = maxf(0.0, config.posture_recovery_delay)
	_crit_timer = maxf(_crit_timer, config.crit_hit_duration)
	_crit_recovery_timer = 0.0
	_recoil_timer = 0.0
	_stagger_timer = 0.0
	host.on_reaction_critical_hit_requested()


func clear_for_parry() -> void:
	_posture_current = 0.0
	_posture_recovery_delay_timer = maxf(0.0, config.posture_recovery_delay)
	_stagger_timer = 0.0
	_recoil_timer = 0.0
	_crit_timer = 0.0
	_crit_recovery_timer = 0.0


func reset_state() -> void:
	_stagger_timer = 0.0
	_recoil_timer = 0.0
	_posture_current = 0.0
	_posture_recovery_delay_timer = 0.0
	_light_flinch_cooldown_timer = 0.0
	_crit_timer = 0.0
	_crit_recovery_timer = 0.0


func start_critical_recovery() -> void:
	_crit_timer = 0.0
	_crit_recovery_timer = maxf(_crit_recovery_timer, config.crit_recovery_duration)


func tick(delta: float) -> bool:
	advance_timers(delta)
	return tick_active_reaction(delta)


func advance_timers(delta: float) -> void:
	_light_flinch_cooldown_timer = maxf(0.0, _light_flinch_cooldown_timer - delta)
	if _posture_recovery_delay_timer > 0.0:
		_posture_recovery_delay_timer = maxf(0.0, _posture_recovery_delay_timer - delta)
	elif _posture_current > 0.0:
		_posture_current = maxf(0.0, _posture_current - maxf(0.0, config.posture_recovery_rate) * delta)


func tick_active_reaction(delta: float) -> bool:
	if _crit_timer > 0.0:
		_crit_timer = maxf(0.0, _crit_timer - delta)
		host.halt_reaction_movement()
		if _crit_timer <= 0.0:
			_crit_recovery_timer = maxf(_crit_recovery_timer, config.crit_recovery_duration)
		host.refresh_reaction_presentation()
		return true
	if _crit_recovery_timer > 0.0:
		_crit_recovery_timer = maxf(0.0, _crit_recovery_timer - delta)
		host.halt_reaction_movement()
		host.refresh_reaction_presentation()
		return true
	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		host.halt_reaction_movement()
		host.refresh_reaction_presentation()
		return true
	if _recoil_timer > 0.0:
		_recoil_timer = maxf(0.0, _recoil_timer - delta)
		host.halt_reaction_movement()
		host.refresh_reaction_presentation()
		return true
	return false


func is_staggered() -> bool:
	return _stagger_timer > 0.0


func is_recoiling() -> bool:
	return _recoil_timer > 0.0


func is_crit_reacting() -> bool:
	return _crit_timer > 0.0


func is_crit_recovering() -> bool:
	return _crit_recovery_timer > 0.0


func is_reaction_blocking_behavior() -> bool:
	return is_staggered() or is_recoiling() or is_crit_reacting() or is_crit_recovering()


func get_debug_state() -> Dictionary:
	return {
		"stagger_remaining": _stagger_timer,
		"recoil_remaining": _recoil_timer,
		"posture_current": _posture_current,
		"posture_recovery_delay_remaining": _posture_recovery_delay_timer,
		"light_flinch_cooldown_remaining": _light_flinch_cooldown_timer,
		"crit_remaining": _crit_timer,
		"crit_recovery_remaining": _crit_recovery_timer,
	}


func get_posture_status(attack_committed: bool) -> Dictionary:
	return {
		"current": _posture_current,
		"maximum": config.posture_max,
		"recovery_delay_remaining": _posture_recovery_delay_timer,
		"recovery_rate": config.posture_recovery_rate,
		"light_flinch_cooldown_remaining": _light_flinch_cooldown_timer,
		"attack_committed": attack_committed,
	}
