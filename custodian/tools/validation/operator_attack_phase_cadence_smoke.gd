extends SceneTree
## C2a-R4.1: attack phases complete, and they do so in every direction.
##
## The C2a-R4 cutover broke two things that the existing suites could not see,
## because both suites proved a phase *starts* and never proved it *ends*:
##
##   1. Unarmed fast windup finished on a canonical identity
##      (`unarmed/attack/fast_windup_01/<sector>/lower_body`) while the completion
##      callback still matched the old compatibility prefix. The attack stranded
##      in windup with no timer to rescue it, because `is_attack_state_complete()`
##      refuses completion while `_melee_fast_windup` is set.
##
##   2. Armed heavy anticipation resolved per-sector against a family authored
##      `s`-only, so every non-south heavy skipped the anticipation phase and went
##      straight to the active phase. That is combat cadence, not just art.
##
## So this gate asserts the transitions themselves, and asserts them per
## direction. It drives the real completion signal path with the real clock
## sprite, rather than calling the phase functions directly -- calling
## `_begin_fast_attack_strike_phase()` by hand is exactly what would have kept
## bug 1 invisible.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

const CARDINALS := {
	"n": Vector2.UP,
	"e": Vector2.RIGHT,
	"s": Vector2.DOWN,
	"w": Vector2.LEFT,
}

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorAttackPhaseCadenceRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	await _check_unarmed_fast_windup_completes(operator)
	await _check_armed_heavy_anticipation_is_directional(operator)
	await _check_armed_fast_recovery_is_directional(operator)

	operator.queue_free()
	if _failures.is_empty():
		print("operator_attack_phase_cadence_smoke passed")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator_attack_phase_cadence_smoke: %d failure(s)" % _failures.size())
	quit(1)


func _make_unarmed(operator: Node) -> void:
	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")


func _check_unarmed_fast_windup_completes(operator: Node) -> void:
	for sector in CARDINALS:
		var forward: Vector2 = CARDINALS[sector]
		_make_unarmed(operator)
		operator.set("_melee_active", false)
		operator.set("_melee_recovery_active", false)
		operator.set("melee_cooldown_remaining", 0.0)
		operator.set("_melee_forward", forward)
		operator.set("_melee_attack_key", "unarmed_fast_1")

		if not bool(operator.call("_try_start_fast_attack_windup")):
			_failures.append("unarmed fast windup should start for %s" % sector)
			continue
		await process_frame
		_check(
			bool(operator.get("_melee_fast_windup")),
			"%s: windup should be active once started" % sector
		)
		_check(
			not bool(operator.get("_melee_active")),
			"%s: strike must not begin before the windup finishes" % sector
		)

		# Whichever layer owns the visible cadence is the one whose completion
		# counts. Ask the actor rather than assuming the modular pair won.
		var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
		_check(clock != null, "%s: a presentation clock should own the windup" % sector)
		if clock == null:
			continue
		var clock_animation := String(clock.animation)
		_check(
			clock_animation.contains("fast_windup_01"),
			"%s: the clock should be playing a fast-windup identity, got %s" % [sector, clock_animation]
		)

		# Drive the real signal path with the real clock and the name the real
		# code chose.
		operator.call("_on_operator_animation_finished", clock)
		await process_frame

		_check(
			not bool(operator.get("_melee_fast_windup")),
			"%s: windup should clear when the clock finishes, not strand (clock was %s)"
				% [sector, clock_animation]
		)
		_check(
			bool(operator.get("_melee_active")),
			"%s: the strike phase should begin when the windup finishes" % sector
		)
		var strike_clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
		if strike_clock != null:
			_check(
				String(strike_clock.animation).contains("fast_strike_01"),
				"%s: strike presentation should start, clock shows %s"
					% [sector, strike_clock.animation]
			)

		operator.set("_melee_active", false)
		operator.set("_melee_recovery_active", false)
		operator.set("melee_cooldown_remaining", 0.0)
		operator.call("_clear_modular_fast_attack_layers")
		await process_frame


func _equip_armed_melee(operator: Node) -> bool:
	## The armed heavy path requires a non-unarmed melee profile. Skip rather than
	## fail if this build cannot produce one, so the gate reports honestly.
	operator.set("using_unarmed", false)
	operator.set("combat_loadout_mode", "melee")
	return not bool(operator.call("_is_current_profile_unarmed"))


func _check_armed_heavy_anticipation_is_directional(operator: Node) -> void:
	if not _equip_armed_melee(operator):
		_failures.append(
			"could not establish an armed melee profile; the directional heavy "
			+ "anticipation regression did not run"
		)
		return
	for sector in CARDINALS:
		var forward: Vector2 = CARDINALS[sector]
		operator.set("_melee_forward", forward)
		var resolved: StringName = operator.call(
			"_resolve_full_body_animation", "melee_2h_heavy_anticipation", forward
		)
		# The phase exists for every facing, or the cadence is direction-dependent.
		_check(
			not String(resolved).is_empty(),
			("armed heavy anticipation must resolve for %s; an empty result skips the "
			+ "anticipation phase entirely for that facing") % sector
		)
		_check(
			String(resolved).contains("heavy_windup_01"),
			"%s: heavy anticipation should resolve a heavy-windup identity, got %s"
				% [sector, resolved]
		)
		# Completion must be recognised for whatever identity was resolved.
		_check(
			bool(operator.call("_is_heavy_windup_identity", String(resolved))),
			"%s: completion should recognise %s as heavy windup" % [sector, resolved]
		)


func _check_armed_fast_recovery_is_directional(operator: Node) -> void:
	if not _equip_armed_melee(operator):
		_failures.append(
			"could not establish an armed melee profile; the directional recovery "
			+ "regression did not run"
		)
		return
	for sector in CARDINALS:
		var forward: Vector2 = CARDINALS[sector]
		var resolved: StringName = operator.call(
			"_resolve_full_body_animation", "melee_2h_fast_recovery", forward
		)
		_check(
			not String(resolved).is_empty(),
			("armed fast recovery must resolve for %s; an empty result drops the body, "
			+ "weapon and FX presentation for that facing") % sector
		)
		_check(
			String(resolved).contains("fast_recovery_01"),
			"%s: recovery should resolve a fast-recovery identity, got %s" % [sector, resolved]
		)
