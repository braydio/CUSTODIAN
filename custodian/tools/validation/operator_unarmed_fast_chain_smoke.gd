extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const UNARMED := preload("res://game/actors/operator/unarmed_definition.tres")
const EXPECTED_FRAMES := [6, 6, 7, 8]
const EXPECTED_CONTACTS := [3, 3, 3, 4]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	current_scene = root
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	_assert_true(UNARMED.fast_chain_keys == PackedStringArray([
		"unarmed_fast_01", "unarmed_fast_02", "unarmed_fast_03", "unarmed_fast_04"
	]), "Fists must declare exactly four ordered links")
	_assert_true(not UNARMED.fast_chain_loops, "Fists chain must not loop to Fast 01")
	_assert_true(UNARMED.fast_chain_attack_profiles.size() == 4, "each link needs one attack profile")
	_assert_true(Array(UNARMED.fast_chain_commit_frames) == EXPECTED_CONTACTS, "commit frames must match reviewed zero-based contacts")

	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("_active_attack_profile", UNARMED)
	operator.set("_melee_active", true)
	operator.set("_melee_attack_kind", "fast")
	for direction in [Vector2.RIGHT, Vector2.LEFT]:
		operator.set("_melee_forward", direction)
		var sector := "e" if direction.x > 0.0 else "w"
		for index in range(4):
			var key: String = UNARMED.fast_chain_keys[index]
			var profile = UNARMED.fast_chain_attack_profiles[index]
			operator.set("_melee_fast_combo_step", index)
			operator.set("_melee_attack_key", key)
			operator.set("_active_melee_attack_profile", profile)
			_assert_true(bool(operator.call("_sync_modular_action_domains")), "%s %s must resolve" % [key, sector])
			var lower := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
			var upper := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
			var expected_lower := StringName("unarmed/attack/fast_%02d/%s/lower_body" % [index + 1, sector])
			var expected_upper := StringName("unarmed/attack/fast_%02d/%s/upper_body" % [index + 1, sector])
			_assert_true(lower.animation == expected_lower, "%s lower identity mismatch" % key)
			_assert_true(upper.animation == expected_upper, "%s upper identity mismatch" % key)
			_assert_true(not lower.flip_h and not upper.flip_h, "%s must not runtime-mirror" % key)
			_assert_true(lower.sprite_frames.get_frame_count(lower.animation) == EXPECTED_FRAMES[index], "%s frame contract mismatch" % key)
			_assert_true(upper.sprite_frames.get_frame_count(upper.animation) == EXPECTED_FRAMES[index], "%s upper clock mismatch" % key)
			_assert_true(is_equal_approx(lower.speed_scale, upper.speed_scale), "%s modular clocks must match" % key)

	operator.set("_melee_fast_combo_step", 0)
	_assert_true(bool(operator.call("_advance_fast_chain_step")), "01 must queue 02")
	_assert_true(bool(operator.call("_advance_fast_chain_step")), "02 must queue 03")
	_assert_true(bool(operator.call("_advance_fast_chain_step")), "03 must queue 04")
	_assert_true(not bool(operator.call("_advance_fast_chain_step")), "04 must terminate without Fast 05")
	_assert_true(int(operator.get("_melee_fast_combo_step")) == 0, "terminal recovery must reset to neutral link")

	for index in range(4):
		var frames: PackedInt32Array = UNARMED.fast_chain_attack_profiles[index].hit_window_frames
		_assert_true(frames == PackedInt32Array([EXPECTED_CONTACTS[index]]), "each link must expose one reviewed contact")

	operator.set("_melee_fast_combo_step", 0)
	operator.set("_melee_attack_key", "unarmed_fast_01")
	operator.set("_active_melee_attack_profile", UNARMED.fast_chain_attack_profiles[0])
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.call("_sync_modular_action_domains")
	await create_timer(0.18).timeout
	var playback_clock := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	_assert_true(playback_clock.frame > 0, "visible modular presentation clock must advance")

	await _validate_attack_drive(operator, root)
	await _validate_early_input_forgiveness(operator)

	operator.queue_free()
	if _failed:
		push_error("operator_unarmed_fast_chain_smoke failed")
		quit(1)
		return
	print("operator_unarmed_fast_chain_smoke passed")
	quit()


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)


## Attack drive: the Fists chain must actually step forward, and the soft-target
## assist must be able to close the ring it acquires in.
##
## Before this, every unarmed link left `drive_distance_px` at its 0.0 default, so
## the whole Attack Drive system was inert for Fists and `MeleeTargetResolver`
## computed `reliable_drive = 0`. That made the C1 assist window half a promise: a
## target between `range_px` and `range_px + target_acquire_extra_px` was acquired
## and aimed at, and then punched at from too far away. Drive is what pays that off,
## so the two are asserted together.
func _validate_attack_drive(operator: Node, root: Node) -> void:
	var expected_drive := [5.0, 7.0, 9.0, 13.0]
	var previous := 0.0
	for index in range(4):
		var profile = UNARMED.fast_chain_attack_profiles[index]
		_assert_true(
			is_equal_approx(profile.drive_distance_px, expected_drive[index]),
			"link %d drive is %.2f, expected %.2f" % [index + 1, profile.drive_distance_px, expected_drive[index]]
		)
		# Distance alone does nothing: `_begin_attack_drive` bails on a zero duration.
		_assert_true(profile.drive_duration_sec > 0.0, "link %d declares distance with no duration" % (index + 1))
		_assert_true(profile.drive_distance_px > previous, "chain drive must escalate at link %d" % (index + 1))
		previous = profile.drive_distance_px
		_assert_true(
			profile.target_drive_bonus_max_px > 0.0,
			"link %d assist cannot close the ring it acquires without a drive bonus" % (index + 1)
		)

	# Executed, not merely declared. Each link is driven through the real physics
	# step and the travelled distance is measured.
	operator.set("unstuck_enabled", false)
	operator.set_physics_process(false)
	for flag in ["_melee_active", "_melee_recovery_active", "_melee_heavy_anticipating"]:
		operator.set(flag, false)
	for index in range(4):
		var profile = UNARMED.fast_chain_attack_profiles[index]
		operator.global_position = Vector2.ZERO
		operator.set("velocity", Vector2.ZERO)
		await physics_frame
		operator.call("_begin_attack_drive", profile, Vector2.RIGHT)
		# Holding backwards must not reverse a committed step.
		var opposing := operator.call("_filter_locomotion_for_attack_drive", Vector2.LEFT * 100.0) as Vector2
		_assert_true(
			opposing.dot(Vector2.RIGHT) >= -0.001,
			"opposing input reversed the link %d drive" % (index + 1)
		)
		for _step in range(40):
			operator.call("_physics_process", 1.0 / 60.0)
		var travelled: float = operator.global_position.x
		var declared: float = profile.drive_distance_px
		_assert_true(
			travelled > declared * 0.8 and travelled <= declared * 1.05 + 0.1,
			"link %d travelled %.3f px, expected about %.1f" % [index + 1, travelled, declared]
		)
		var settled: Vector2 = operator.global_position
		for _step in range(8):
			operator.call("_physics_process", 1.0 / 60.0)
		_assert_true(
			operator.global_position.distance_to(settled) <= 0.05,
			"link %d drive snapped back or drifted after completion" % (index + 1)
		)
	operator.global_position = Vector2.ZERO
	operator.set("velocity", Vector2.ZERO)

	# The assist ring now resolves extra drive instead of aim correction alone.
	var dummy := Node2D.new()
	root.add_child(dummy)
	for index in range(4):
		var profile = UNARMED.fast_chain_attack_profiles[index]
		var reach := MeleeTargetResolver.get_reach_model(profile)
		var edge := float(reach.assist_reach)
		dummy.global_position = Vector2(edge, 0.0)
		var solution := MeleeTargetResolver.resolve_attack(
			Vector2.ZERO, Vector2.RIGHT, dummy, dummy.global_position, profile
		)
		var assist := float(solution.get("assist_drive_distance", 0.0))
		var resolved := float(solution.get("resolved_drive_distance", 0.0))
		var gap := edge - float(reach.reliable_reach)
		_assert_true(
			is_equal_approx(assist, minf(gap, profile.target_drive_bonus_max_px)),
			"link %d assist drive is %.3f, expected %.3f" % [index + 1, assist, minf(gap, profile.target_drive_bonus_max_px)]
		)
		_assert_true(
			resolved > profile.drive_distance_px,
			"link %d gains no drive from a target at the edge of its own acquire ring" % (index + 1)
		)
	dummy.queue_free()


## Early input forgiveness: pressing slightly before the rhythm window opens must
## be heard, while pressing after it closes must still cost the link.
##
## Before this, `_try_melee_attack` discarded any fast press made outside the
## queue window outright -- it never reached `_buffer_attack()`. On Fast 01 the
## window opens at frame 2 of 6, so roughly the first third of the link silently
## ate the player's input and they had to press again. Late presses are a
## different mistake and are still refused, otherwise the rhythm gate means
## nothing.
func _validate_early_input_forgiveness(operator: Node) -> void:
	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("velocity", Vector2.ZERO)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("_melee_fast_combo_step", 0)
	operator.call("_clear_attack_buffer")
	operator.call("_try_melee_attack", "unarmed_fast")
	await process_frame
	# Let the attack take the body, so the clock below is the link being drawn
	# rather than whatever the previous case left on screen.
	operator.call("_update_animation")
	await process_frame

	# Anti-vacuous: every assertion below is meaningless unless a real authored
	# link is actually running and visibly drawn with a readable clock.
	_assert_true(bool(operator.get("_melee_active")), "forgiveness case needs a real attack to start")
	_assert_true(bool(operator.call("_has_authored_fast_chain")), "forgiveness case needs the authored chain")
	var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
	_assert_true(clock != null, "forgiveness case needs a readable presentation clock")
	if clock == null or not bool(operator.get("_melee_active")):
		return
	_assert_true(
		String(clock.animation).contains("attack/fast_01"),
		"the rhythm clock must be the link being drawn, got %s" % String(clock.animation)
	)

	var weapon = operator.call("_get_fast_chain_weapon")
	var step: int = int(operator.get("_melee_fast_combo_step"))
	var open_frame: int = int(weapon.fast_chain_queue_open_frames[step])
	var close_frame: int = int(weapon.fast_chain_queue_close_frames[step])
	var commit_frame: int = int(weapon.fast_chain_commit_frames[step])
	_assert_true(open_frame > 0, "the early region must exist for this test to mean anything")

	# Early: refused before, buffered now.
	clock.frame = 0
	_assert_true(
		String(operator.call("_fast_chain_queue_window_state")) == "early",
		"frame 0 should classify as early, got %s" % operator.call("_fast_chain_queue_window_state")
	)
	operator.call("_clear_attack_buffer")
	operator.call("_try_melee_attack", "unarmed_fast")
	_assert_true(
		String(operator.get("_buffered_attack_kind")) == "fast",
		"a press before the window opens must be buffered, not discarded"
	)

	# Inside the window: unchanged behaviour.
	clock.frame = open_frame
	_assert_true(
		String(operator.call("_fast_chain_queue_window_state")) == "open",
		"the open frame should classify as open"
	)
	operator.call("_clear_attack_buffer")
	operator.call("_try_melee_attack", "unarmed_fast")
	_assert_true(
		String(operator.get("_buffered_attack_kind")) == "fast",
		"a press inside the window must still be buffered"
	)

	# Late: still refused, so the rhythm gate keeps its teeth.
	var frame_count: int = clock.sprite_frames.get_frame_count(clock.animation)
	_assert_true(
		frame_count == EXPECTED_FRAMES[step],
		"the rhythm clock should carry link %d's authored frame count, got %d"
			% [step + 1, frame_count]
	)
	if close_frame + 1 < frame_count:
		clock.frame = close_frame + 1
		_assert_true(
			String(operator.call("_fast_chain_queue_window_state")) == "late",
			"a frame past the close frame should classify as late"
		)
		operator.call("_clear_attack_buffer")
		operator.call("_try_melee_attack", "unarmed_fast")
		_assert_true(
			String(operator.get("_buffered_attack_kind")).is_empty(),
			"a press after the window closes must still be refused"
		)
	else:
		_assert_true(false, "link %d has no frame past its close frame to test lateness" % (step + 1))

	# The forgiven press must actually buy the next link, not merely sit in a
	# variable. Latch early, then run the link to its commit frame.
	clock.frame = 0
	operator.call("_clear_attack_buffer")
	operator.call("_try_melee_attack", "unarmed_fast")
	_assert_true(
		String(operator.get("_buffered_attack_kind")) == "fast",
		"the advance case needs the early press latched"
	)
	# Frozen for the duration of an authored chain, so it must survive the wait.
	for _i in range(12):
		operator.call("_update_attack_buffer", 1.0 / 60.0)
	_assert_true(
		String(operator.get("_buffered_attack_kind")) == "fast",
		"an early press must not decay while the authored link is still running"
	)
	clock.frame = commit_frame
	operator.call("_update_melee_attack", 1.0 / 60.0)
	await process_frame
	_assert_true(
		int(operator.get("_melee_fast_combo_step")) == step + 1,
		"an early press must advance the chain at the commit frame, step is %d"
			% int(operator.get("_melee_fast_combo_step"))
	)

