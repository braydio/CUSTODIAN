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


func _select_armed_melee(operator: Node) -> bool:
	## Select a real melee weapon through the actor's own selection path.
	##
	## Setting `using_unarmed = false` and `combat_loadout_mode = "melee"` by hand
	## is not enough and quietly tested the wrong thing: `_rebuild_armed_weapon_list()`
	## appends the primary ranged weapon before the melee one, so
	## `armed_weapon_index` stays on the carbine and
	## `get_current_combat_profile()` returns a ranged profile. The index is found
	## rather than hardcoded, because the list order is a loadout detail.
	var armed: Array = operator.get("armed_weapons")
	if armed == null:
		return false
	for index in armed.size():
		var profile = armed[index]
		if profile != null and String(profile.weapon_kind) == "melee":
			operator.call("_apply_armed_selection", index)
			return true
	return false


func _check_armed_melee_selection(operator: Node) -> bool:
	if not _select_armed_melee(operator):
		_failures.append(
			"no melee weapon in armed_weapons; the armed-melee regressions cannot run"
		)
		return false
	var profile = operator.call("get_current_combat_profile")
	_check(not bool(operator.get("using_unarmed")), "armed melee selection should clear using_unarmed")
	_check(
		bool(operator.call("_is_melee_loadout_active")),
		"armed melee selection should activate the melee loadout"
	)
	_check(
		profile != null and String(profile.weapon_kind) == "melee",
		"the current combat profile should be a melee weapon, got %s"
			% ("null" if profile == null else profile.weapon_kind)
	)
	return profile != null and String(profile.weapon_kind) == "melee"


func _reset_attack_state(operator: Node) -> void:
	operator.set("_melee_active", false)
	operator.set("_melee_heavy_anticipating", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)
	operator.set("melee_cooldown_remaining", 0.0)


func _check_armed_heavy_anticipation_is_directional(operator: Node) -> void:
	## The real lifecycle, not just the resolver.
	##
	## Before C2a-R4 the anticipation clip was a generic compatibility animation
	## with no direction. R4 resolved it per-sector against a family authored
	## `s`-only, so every non-south heavy skipped anticipation entirely and entered
	## the active phase immediately. Only driving `_start_heavy_attack()` and
	## watching the phase flags can catch that; asking the resolver cannot.
	if not _check_armed_melee_selection(operator):
		return
	for sector in CARDINALS:
		var forward: Vector2 = CARDINALS[sector]
		_reset_attack_state(operator)
		operator.set("aim_direction", forward)
		operator.set("attack_facing_dir", forward)
		operator.set("_melee_forward", forward)
		await process_frame

		operator.call("_start_heavy_attack")
		await process_frame

		if not bool(operator.get("_melee_heavy_anticipating")):
			_failures.append(
				("%s: armed heavy should enter the anticipation phase; entering the active "
				+ "phase straight away is a lost gameplay phase, not just missing art") % sector
			)
			_reset_attack_state(operator)
			continue
		_check(
			not bool(operator.get("_melee_active")),
			"%s: the active phase must not begin before anticipation completes" % sector
		)

		var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
		_check(clock != null, "%s: a presentation clock should own the anticipation" % sector)
		if clock != null:
			_check(
				String(clock.animation).contains("heavy_windup_01"),
				"%s: the clock should play a heavy-windup identity, got %s"
					% [sector, clock.animation]
			)
			operator.call("_on_operator_animation_finished", clock)
			await process_frame
			_check(
				not bool(operator.get("_melee_heavy_anticipating")),
				"%s: anticipation should clear when its clock finishes" % sector
			)
			_check(
				bool(operator.get("_melee_active")),
				"%s: the active phase should begin once anticipation completes" % sector
			)
		_reset_attack_state(operator)
		await process_frame


func _check_armed_fast_recovery_is_directional(operator: Node) -> void:
	## Recovery presentation must survive every facing. The body is canonical; the
	## weapon and FX overlays are still compatibility-owned in R4 and must keep
	## presenting rather than silently disappearing.
	if not _check_armed_melee_selection(operator):
		return
	var body := operator.get("animated_sprite") as AnimatedSprite2D
	var weapon_overlay := operator.get("melee_weapon_overlay_sprite") as AnimatedSprite2D
	var fx_overlay := operator.get("melee_fx_overlay_sprite") as AnimatedSprite2D
	for sector in CARDINALS:
		var forward: Vector2 = CARDINALS[sector]
		_reset_attack_state(operator)
		operator.set("_melee_forward", forward)
		operator.set("_active_attack_profile", operator.call("get_current_combat_profile"))
		if body != null:
			body.animation = &""
		await process_frame

		operator.call("_play_fast_attack_recovery")
		await process_frame

		var presented := body != null and String(body.animation).contains("fast_recovery_01")
		_check(
			presented,
			("%s: armed fast recovery should present a canonical recovery body, got %s")
				% [sector, "null body" if body == null else String(body.animation)]
		)
		if presented:
			_check(not body.flip_h, "%s: canonical recovery must not be mirrored" % sector)
		_check(
			weapon_overlay == null or weapon_overlay.visible
				or String(weapon_overlay.animation).is_empty() == false,
			"%s: the weapon overlay should still present during recovery" % sector
		)
		_check(
			fx_overlay == null or fx_overlay.visible
				or String(fx_overlay.animation).is_empty() == false,
			"%s: the FX overlay should still present during recovery" % sector
		)
		_reset_attack_state(operator)
		await process_frame
