class_name OperatorGuardController
extends RefCounted

const CombatConstants = preload("res://game/systems/combat/combat_constants.gd")

enum Phase {
	NEUTRAL,
	GUARD_ENTER,
	GUARD_HOLD,
	LIGHT_RECOIL,
	HEAVY_RECOIL,
	GUARD_BREAK,
	BREAK_RECOVERY,
	GUARD_EXIT,
	PARRY,
	PARRY_SUCCESS,
	PARRY_RECOVERY,
}

enum ParryPhase { NONE, WINDUP, ACTIVE, SUCCESS, RECOVERY, EXPIRED }

var host
var config: OperatorGuardConfig
var phase := Phase.NEUTRAL
var phase_timer := 0.0
var parry_phase := ParryPhase.NONE
var parry_timer := 0.0
var parry_active := false
var parry_success_lockout := 0.0
var counter_window_timer := 0.0
var reraise_lockout_timer := 0.0
var held_timer := 0.0
var guard_requested := false
var repress_required := false
var neutral_lock_active := false


func setup(owner, guard_config: OperatorGuardConfig) -> void:
	host = owner
	config = guard_config


func tick(delta: float) -> void:
	parry_success_lockout = maxf(0.0, parry_success_lockout - delta)
	var had_counter := counter_window_timer > 0.0
	counter_window_timer = maxf(0.0, counter_window_timer - delta)
	if had_counter and counter_window_timer <= 0.0:
		neutral_lock_active = false
	reraise_lockout_timer = maxf(0.0, reraise_lockout_timer - delta)
	if phase in [Phase.LIGHT_RECOIL, Phase.HEAVY_RECOIL, Phase.GUARD_BREAK, Phase.BREAK_RECOVERY]:
		phase_timer = maxf(0.0, phase_timer - delta)
		if phase == Phase.GUARD_BREAK and phase_timer <= 0.0:
			phase = Phase.BREAK_RECOVERY
			phase_timer = config.break_recovery_time
		elif phase == Phase.BREAK_RECOVERY and phase_timer <= 0.0:
			phase = Phase.NEUTRAL
	_update_parry(delta)


func start_guard() -> bool:
	if reraise_lockout_timer > 0.0 or is_break_locked():
		return false
	phase = Phase.GUARD_ENTER
	phase_timer = config.full_activation_time
	held_timer = maxf(held_timer, config.weak_start_time)
	host.guard_play_block_animation(&"melee_2h_block_enter")
	return true


func release_guard() -> void:
	guard_requested = false
	held_timer = 0.0
	if phase in [Phase.GUARD_ENTER, Phase.GUARD_HOLD, Phase.LIGHT_RECOIL, Phase.HEAVY_RECOIL]:
		phase = Phase.GUARD_EXIT
		host.guard_play_block_animation(&"melee_2h_block_exit")


func update_animation_state(wants_guard: bool) -> String:
	match phase:
		Phase.PARRY, Phase.PARRY_SUCCESS, Phase.PARRY_RECOVERY:
			return "block" if parry_phase != ParryPhase.NONE else host.guard_desired_animation_state()
		Phase.GUARD_ENTER:
			if host.guard_is_block_animation_finished() or held_timer >= config.full_activation_time:
				phase = Phase.GUARD_HOLD
				host.guard_play_block_animation(&"melee_2h_block_hold")
			return "block"
		Phase.GUARD_HOLD:
			if not wants_guard:
				release_guard()
			return "block"
		Phase.LIGHT_RECOIL, Phase.HEAVY_RECOIL:
			if phase_timer <= 0.0 or host.guard_is_block_animation_finished():
				if wants_guard:
					phase = Phase.GUARD_HOLD
					host.guard_play_block_animation(&"melee_2h_block_hold")
				else:
					release_guard()
			return "block"
		Phase.GUARD_BREAK, Phase.BREAK_RECOVERY:
			return "block"
		Phase.GUARD_EXIT:
			if host.guard_is_block_animation_finished():
				phase = Phase.NEUTRAL
				return host.guard_desired_animation_state()
			return "block"
		_:
			if wants_guard and start_guard():
				return "block"
			return host.guard_desired_animation_state()


func resolve_guard_hit(
	damage: float,
	hit_direction: Vector2,
	hit_strength: int,
	stamina_cost_override := -1.0
) -> Dictionary:
	if not is_guard_active():
		return {"blocked": false, "damage": damage, "guard_broken": false}
	if not host.guard_faces_hit(hit_direction, 0.15):
		return {"blocked": false, "damage": damage, "guard_broken": false}
	var multiplier := 1.0
	match hit_strength:
		CombatConstants.HitStrength.LIGHT:
			multiplier = config.light_stamina_multiplier
		CombatConstants.HitStrength.HEAVY:
			multiplier = config.heavy_stamina_multiplier
		CombatConstants.HitStrength.INTERRUPT:
			multiplier = config.interrupt_stamina_multiplier
	var stamina_cost := stamina_cost_override if stamina_cost_override >= 0.0 else config.base_stamina_cost * multiplier
	if host.guard_has_offhand_item():
		stamina_cost *= 0.75
	host.guard_spend_stamina(stamina_cost, &"guard")
	var reduction := config.damage_reduction
	if phase == Phase.GUARD_ENTER and config.full_activation_time > 0.0:
		var activation := clampf(held_timer / config.full_activation_time, 0.0, 1.0)
		reduction *= lerpf(0.45, 1.0, activation)
	if host.guard_has_offhand_item():
		reduction = clampf(reduction + 0.12, 0.0, 0.9)
	var reduced_damage := maxf(config.minimum_chip_damage, damage * (1.0 - reduction))
	var broke: bool = float(host.guard_current_stamina()) <= config.break_threshold
	if broke:
		host.guard_set_stamina_zero()
		phase = Phase.GUARD_BREAK
		phase_timer = config.break_impact_time
		reraise_lockout_timer = config.reraise_lockout_time
		guard_requested = false
		repress_required = host.guard_secondary_pressed()
		parry_active = false
		parry_phase = ParryPhase.NONE
		host.guard_play_block_animation(&"melee_2h_block_hitreact")
		host.guard_on_break(stamina_cost, hit_strength, hit_direction)
		reduced_damage = maxf(config.minimum_chip_damage, damage * 0.65)
	else:
		phase = Phase.HEAVY_RECOIL if hit_strength != CombatConstants.HitStrength.LIGHT else Phase.LIGHT_RECOIL
		phase_timer = config.heavy_recoil_time if phase == Phase.HEAVY_RECOIL else config.light_recoil_time
		host.guard_play_block_animation(&"melee_2h_block_hitreact")
		host.guard_on_block(stamina_cost, hit_strength, reduced_damage)
	return {
		"blocked": true,
		"damage": reduced_damage,
		"guard_broken": broke,
		"stamina_cost": stamina_cost,
		"recoil": &"break" if broke else (&"heavy" if phase == Phase.HEAVY_RECOIL else &"light"),
	}


func begin_parry() -> bool:
	if reraise_lockout_timer > 0.0 or is_break_locked():
		return false
	parry_phase = ParryPhase.WINDUP
	parry_timer = config.parry_windup_time
	parry_active = false
	guard_requested = false
	phase = Phase.PARRY
	host.guard_play_parry_animation(&"unarmed_parry")
	return true


func try_parry(attacker: Node2D, hit_direction: Vector2, hit_data: Dictionary) -> bool:
	if not parry_active or not host.guard_faces_hit(hit_direction, 0.35, attacker):
		return false
	parry_active = false
	parry_phase = ParryPhase.SUCCESS
	parry_timer = config.parry_success_recovery_time
	parry_success_lockout = maxf(parry_success_lockout, parry_timer)
	counter_window_timer = maxf(counter_window_timer, config.counter_window_time)
	phase = Phase.PARRY_SUCCESS
	repress_required = host.guard_secondary_pressed()
	host.guard_apply_parry_success(attacker, hit_direction, hit_data)
	return true


func fail_parry_to_recoil() -> void:
	parry_active = false
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	guard_requested = false
	phase = Phase.HEAVY_RECOIL
	phase_timer = config.heavy_recoil_time
	host.guard_play_block_animation(&"melee_2h_block_hitreact")


func reset() -> void:
	phase = Phase.NEUTRAL
	phase_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	parry_active = false
	parry_success_lockout = 0.0
	counter_window_timer = 0.0
	reraise_lockout_timer = 0.0
	held_timer = 0.0
	guard_requested = false
	repress_required = false
	neutral_lock_active = false


func is_guard_active() -> bool:
	return phase in [Phase.GUARD_ENTER, Phase.GUARD_HOLD, Phase.LIGHT_RECOIL, Phase.HEAVY_RECOIL]


func is_guard_fully_active() -> bool:
	return phase == Phase.GUARD_HOLD


func is_state_active() -> bool:
	return phase != Phase.NEUTRAL


func is_break_locked() -> bool:
	return phase in [Phase.GUARD_BREAK, Phase.BREAK_RECOVERY]


func phase_name() -> StringName:
	return StringName(Phase.keys()[phase].to_lower())


func parry_phase_name() -> StringName:
	return &"" if parry_phase == ParryPhase.NONE else StringName(ParryPhase.keys()[parry_phase].to_lower())


func _update_parry(delta: float) -> void:
	if parry_phase == ParryPhase.NONE:
		return
	parry_timer = maxf(0.0, parry_timer - delta)
	match parry_phase:
		ParryPhase.WINDUP:
			if parry_timer <= 0.0:
				parry_phase = ParryPhase.ACTIVE
				parry_timer = config.parry_active_time
				parry_active = true
				host.guard_on_parry_active()
		ParryPhase.ACTIVE:
			if parry_timer <= 0.0:
				parry_active = false
				host.guard_on_parry_expired()
				parry_phase = ParryPhase.RECOVERY
				parry_timer = maxf(config.parry_recovery_time, host.guard_parry_animation_remaining())
				phase = Phase.PARRY_RECOVERY
		ParryPhase.SUCCESS, ParryPhase.RECOVERY:
			if parry_timer <= 0.0:
				var succeeded := parry_phase == ParryPhase.SUCCESS
				parry_phase = ParryPhase.NONE
				parry_active = false
				if succeeded:
					phase = Phase.NEUTRAL
					neutral_lock_active = true
					host.guard_enter_post_parry_neutral()
				elif host.guard_secondary_pressed():
					guard_requested = true
					start_guard()
				else:
					phase = Phase.NEUTRAL
		ParryPhase.EXPIRED:
			parry_phase = ParryPhase.RECOVERY
			parry_timer = maxf(config.parry_recovery_time, host.guard_parry_animation_remaining())
			phase = Phase.PARRY_RECOVERY
