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
	await _check_fast_recovery_paths(operator)

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


func _check_fast_recovery_paths(operator: Node) -> void:
	## Recovery, tested along the path each loadout actually takes.
	##
	## `_start_fast_attack_recovery()` runs only when the fast-chain weapon is null
	## or lacks `fast_chain_has_integrated_recovery`. Both shipped melee weapons set
	## it true, so an armed fast chain never reaches the generic recovery helper.
	## Calling `_play_fast_attack_recovery()` directly after selecting Sword-Cleaver
	## proved the helper can render something; it did not prove anything the game
	## does. Worse, it asserted weapon and FX overlays that a Sword-Cleaver does not
	## even publish -- its resources carry the fast-chain animations instead.
	##
	## So: the unarmed path, which genuinely uses the helper, is exercised
	## end-to-end. Armed weapons are checked against the contract that skips it. If
	## an armed weapon ever ships without integrated recovery, the else-branch below
	## starts requiring the generic presentation for it, rather than this test
	## silently continuing to pass.
	_check_unarmed_fast_recovery_presents(operator)
	_check_integrated_recovery_weapons_skip_generic(operator)


func _check_unarmed_fast_recovery_presents(operator: Node) -> void:
	operator.call("_apply_unarmed_selection")
	await process_frame
	_check(
		bool(operator.get("using_unarmed")),
		"unarmed selection should engage for the recovery check"
	)
	var body := operator.get("animated_sprite") as AnimatedSprite2D
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

		var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
		var presented := clock != null and String(clock.animation).contains("fast_recovery_01")
		_check(
			presented,
			"%s: unarmed fast recovery should present a canonical recovery, clock shows %s"
				% [sector, "null" if clock == null else String(clock.animation)]
		)
		if presented:
			_check(not clock.flip_h, "%s: canonical recovery must not be mirrored" % sector)
		_reset_attack_state(operator)
		await process_frame


func _check_integrated_recovery_weapons_skip_generic(operator: Node) -> void:
	var armed: Array = operator.get("armed_weapons")
	if armed == null:
		_failures.append("armed_weapons should exist")
		return
	var melee_seen := 0
	for index in armed.size():
		var profile = armed[index]
		if profile == null or String(profile.weapon_kind) != "melee":
			continue
		melee_seen += 1
		operator.call("_apply_armed_selection", index)
		await process_frame
		_reset_attack_state(operator)
		operator.set("_melee_attack_kind", "fast")
		operator.set("_buffered_attack_kind", "")

		if bool(profile.fast_chain_has_integrated_recovery):
			# Its own chain art carries the recovery, so the generic helper must not
			# run. Drive a real fast attack to completion and watch the flag that
			# `_start_fast_attack_recovery()` would have set.
			operator.set("_melee_forward", Vector2.RIGHT)
			operator.call("_try_melee_attack", "melee_fast")
			await process_frame
			# Without this the loop below can never run and the assertions pass
			# vacuously, which is the same shape of hole this rewrite exists to fix.
			_check(
				bool(operator.get("_melee_active")),
				"%s fast attack should actually start before recovery is judged"
					% profile.weapon_id
			)
			var guard := 0
			while bool(operator.get("_melee_active")) and guard < 240:
				operator.call("_update_melee_attack", 0.05)
				guard += 1
			_check(
				guard < 240,
				"%s fast attack should complete within the guard window" % profile.weapon_id
			)
			_check(
				not bool(operator.get("_melee_recovery_active")),
				("%s integrates its own fast-chain recovery, so the generic recovery path "
				+ "must not run for it") % profile.weapon_id
			)
		else:
			# A weapon that does not integrate recovery must actually get one.
			operator.set("_melee_forward", Vector2.RIGHT)
			operator.set("_active_attack_profile", profile)
			var body := operator.get("animated_sprite") as AnimatedSprite2D
			if body != null:
				body.animation = &""
			operator.call("_play_fast_attack_recovery")
			await process_frame
			_check(
				body != null and String(body.animation).contains("fast_recovery_01"),
				"%s has no integrated recovery, so the generic recovery must present"
					% profile.weapon_id
			)
		_reset_attack_state(operator)
		await process_frame
	_check(melee_seen > 0, "at least one melee weapon should be available to check")
