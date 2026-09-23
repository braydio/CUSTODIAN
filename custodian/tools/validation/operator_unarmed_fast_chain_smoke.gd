extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const UNARMED := preload("res://game/actors/operator/unarmed_definition.tres")
const EXPECTED_FRAMES := [6, 6, 7, 8]
const EXPECTED_CONTACTS := [3, 3, 3, 4]
const EXPECTED_HITSTOP := [0.018, 0.024, 0.032, 0.050]
const EXPECTED_SHAKE := [0.70, 1.00, 1.45, 2.20]


## Stands in for the world camera on the real confirmed-hit path.
##
## `_get_world_camera()` resolves an absolute path and the actor only requires an
## `on_attack_impact` method, so this records exactly what a landed contact asks
## the camera for: the amplitude, and whether it asked for the heavy push.
class ShakeProbe extends Node2D:
	var powers: Array[float] = []
	var heavies: Array[bool] = []

	func on_attack_impact(_direction: Vector2, is_heavy: bool = false, shake_power: float = -1.0) -> void:
		powers.append(shake_power)
		heavies.append(is_heavy)

	func clear() -> void:
		powers.clear()
		heavies.clear()

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
	await _validate_impact_progression(operator)
	await _validate_chain_drive_continuity(operator, root)

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


## C2: the per-link impact staircase must be the authored one, and it must be the
## profile that reaches the real feedback path.
##
## This is presentation hierarchy only. Damage stays 10.0 and knockback stays 56.0
## across all four links on purpose -- the links differ in how a hit *reads*, not
## in what it is worth -- so those are asserted flat here to keep a later feel
## pass from quietly becoming a balance pass.
func _validate_impact_progression(operator: Node) -> void:
	for index in range(4):
		var profile = UNARMED.fast_chain_attack_profiles[index]
		_assert_true(
			is_equal_approx(profile.hit_stop_duration, EXPECTED_HITSTOP[index]),
			"link %d hitstop is %.4f, expected %.4f"
				% [index + 1, profile.hit_stop_duration, EXPECTED_HITSTOP[index]]
		)
		_assert_true(
			is_equal_approx(profile.camera_shake_power, EXPECTED_SHAKE[index]),
			"link %d shake is %.3f, expected %.3f"
				% [index + 1, profile.camera_shake_power, EXPECTED_SHAKE[index]]
		)
		if index > 0:
			var previous = UNARMED.fast_chain_attack_profiles[index - 1]
			_assert_true(
				profile.hit_stop_duration > previous.hit_stop_duration,
				"hitstop must rise at link %d" % (index + 1)
			)
			_assert_true(
				profile.camera_shake_power > previous.camera_shake_power,
				"shake must rise at link %d" % (index + 1)
			)
		# Presentation hierarchy, not balance escalation.
		_assert_true(
			is_equal_approx(profile.damage, 10.0),
			"link %d damage changed; C2 is presentation only" % (index + 1)
		)
		_assert_true(
			is_equal_approx(profile.knockback_force, 56.0),
			"link %d knockback changed; C2 is presentation only" % (index + 1)
		)

	# Executed against the live path, not a helper. This used to drive
	# `_trigger_camera_shake()`, which read the profile correctly and which **no
	# game code ever called** -- the real confirmed hit goes through
	# `_on_melee_hit_confirmed()` to `Camera2D.on_attack_impact()`, where the
	# authored power was being flattened to a generic 1.8. The staircase was true
	# in configuration and in the test, and false on screen.
	var probe := ShakeProbe.new()
	var game_root := Node.new()
	game_root.name = "GameRoot"
	var world := Node.new()
	world.name = "World"
	probe.name = "Camera2D"
	world.add_child(probe)
	game_root.add_child(world)
	get_root().add_child(game_root)
	await process_frame
	_assert_true(
		operator.call("_get_world_camera") == probe,
		"the shake probe must be the camera the actor resolves"
	)

	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("_melee_attack_kind", "fast")
	operator.set("_active_melee_contact", {})
	for index in range(4):
		var profile = UNARMED.fast_chain_attack_profiles[index]
		operator.set("_melee_fast_combo_step", index)
		# Resolved the way the runtime resolves it, from the chain step, rather
		# than assigned by hand.
		var resolved = operator.call("_get_current_melee_attack_profile", "fast")
		_assert_true(
			resolved == profile,
			"link %d must resolve to its own attack profile" % (index + 1)
		)
		operator.set("_active_melee_attack_profile", resolved)

		probe.powers.clear()
		probe.heavies.clear()
		operator.set("_hit_stop_active", false)
		Engine.time_scale = 1.0
		operator.call("_on_melee_hit_confirmed", {})
		_assert_true(
			probe.powers.size() == 1,
			"link %d should request exactly one camera impact, saw %d"
				% [index + 1, probe.powers.size()]
		)
		if probe.powers.size() == 1:
			_assert_true(
				is_equal_approx(probe.powers[0], EXPECTED_SHAKE[index]),
				"link %d asked the camera for %.4f, but authored %.4f -- the live "
					% [index + 1, probe.powers[0], EXPECTED_SHAKE[index]]
					+ "confirmed-hit path is not carrying the profile power"
			)
			_assert_true(
				probe.powers[0] > 0.0,
				"link %d fell back to the camera's generic amplitude" % (index + 1)
			)
			_assert_true(
				not probe.heavies[0],
				"a fast link should not request the heavy camera push"
			)
		await create_timer(maxf(0.08, profile.hit_stop_duration * 2.0)).timeout
		_assert_true(
			is_equal_approx(Engine.time_scale, 1.0),
			"link %d hit stop did not restore time scale, left %.4f"
				% [index + 1, Engine.time_scale]
		)

		# The duration cannot be timed: a headless process frame is ~6 ms and the
		# links differ by 4-8 ms, so a wall-clock measurement would not tell the
		# authored staircase from a flattened one. It is read from the resolution
		# seam the apply path itself uses instead.
		var hit_stop: Dictionary = operator.call("_resolve_melee_contact_feedback", {})
		_assert_true(
			is_equal_approx(float(hit_stop["duration"]), EXPECTED_HITSTOP[index]),
			"link %d resolves a %.4f s hit stop, but authored %.4f -- the profile "
				% [index + 1, float(hit_stop["duration"]), EXPECTED_HITSTOP[index]]
				+ "is not reaching the feedback path unmodified"
		)
		_assert_true(
			is_equal_approx(float(hit_stop["scale"]), profile.hit_stop_scale),
			"link %d resolves scale %.4f, expected the authored %.4f"
				% [index + 1, float(hit_stop["scale"]), profile.hit_stop_scale]
		)

		# And the confirmed-hit path must really stop time at the authored scale.
		operator.set("_hit_stop_active", false)
		Engine.time_scale = 1.0
		operator.call("_on_melee_hit_confirmed", {})
		_assert_true(
			is_equal_approx(Engine.time_scale, profile.hit_stop_scale),
			"link %d confirmed hit set time scale to %.4f, expected the authored %.4f"
				% [index + 1, Engine.time_scale, profile.hit_stop_scale]
		)
	Engine.time_scale = 1.0
	game_root.queue_free()


## C5: a chained link must not leave a hole in the attack drive, and closing that
## hole must not hand out free distance.
##
## `_begin_attack_drive()` opens with `_cancel_attack_drive(true)`, which strips
## the outgoing drive's contribution immediately. The successor then sits through
## its own `drive_delay_sec` before it moves at all, so the chain read as
## drive -> nothing -> drive. The seam is bridged now, funded first from whatever
## the outgoing link had authored but not yet spent and then from the incoming
## link's own budget, so the total can never exceed the two authored contracts.
func _validate_chain_drive_continuity(operator: Node, root: Node) -> void:
	operator.set("unstuck_enabled", false)
	operator.set_physics_process(false)
	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("_melee_attack_kind", "fast")
	for flag in ["_melee_recovery_active", "_melee_heavy_anticipating"]:
		operator.set(flag, false)
	_assert_true(
		bool(operator.call("_has_authored_fast_chain")),
		"the continuity case needs the authored chain"
	)

	for seam in range(3):
		var outgoing = UNARMED.fast_chain_attack_profiles[seam]
		var incoming = UNARMED.fast_chain_attack_profiles[seam + 1]
		var seam_time := _chain_seam_time(seam)
		var measured := _drive_through_seam(operator, seam, seam_time, -1)
		var budget: float = outgoing.drive_distance_px + incoming.drive_distance_px

		_assert_true(
			int(measured["dead_frames"]) == 0,
			"seam %d->%d left %d dead attack-drive frame(s) during the incoming "
				% [seam + 1, seam + 2, int(measured["dead_frames"])]
				+ "delay; the chain still reads as drive, gap, drive"
		)
		# The invariant that matters more than the continuity: no free distance.
		_assert_true(
			float(measured["driven"]) <= budget + 0.05,
			"seam %d->%d drove %.3f px against an authored budget of %.1f px"
				% [seam + 1, seam + 2, float(measured["driven"]), budget]
		)
		_assert_true(
			float(measured["driven"]) > budget - 1.0,
			"seam %d->%d drove only %.3f px of its %.1f px budget"
				% [seam + 1, seam + 2, float(measured["driven"]), budget]
		)

	# A fresh attack must not inherit anything. Same machinery, but the successor
	# restarts the chain at step 0 instead of continuing it.
	var restart := _drive_through_seam(operator, 0, _chain_seam_time(0), 0)
	_assert_true(
		int(restart["dead_frames"]) > 0,
		"a chain restart at step 0 must not inherit the outgoing link's momentum"
	)
	_assert_true(
		not bool(operator.call("_has_attack_drive_carry")),
		"a chain restart must leave no carry installed"
	)

	# Holding backwards must not reverse a committed step mid-handoff either.
	_install_live_carry(operator)
	_assert_true(
		bool(operator.call("_has_attack_drive_carry")),
		"the opposing-input case needs a live carry"
	)
	var opposing := operator.call(
		"_filter_locomotion_for_attack_drive", Vector2.LEFT * 100.0
	) as Vector2
	_assert_true(
		opposing.dot(Vector2.RIGHT) >= -0.001,
		"opposing input reversed drive during a chain handoff"
	)
	var carried := Vector2.ZERO
	for _i in 4:
		operator.call("_physics_process", 1.0 / 60.0)
		carried += operator.get("_last_attack_drive_velocity") as Vector2
	_assert_true(
		carried.dot(Vector2.RIGHT) > 0.0,
		"carried momentum must stay committed forward, measured %.2f" % carried.x
	)
	operator.call("_cancel_attack_drive", true)

	await _validate_carry_interruptions(operator)
	await _validate_carry_collision(operator, root)


func _chain_seam_time(seam: int) -> float:
	return (
		float(UNARMED.fast_chain_commit_frames[seam])
		/ float(EXPECTED_FRAMES[seam])
		* float(UNARMED.fast_chain_presentation_durations[seam])
	)


## Run the outgoing link to the seam, advance the chain, and measure the incoming
## delay. `successor_step` of -1 means the genuine next link.
func _drive_through_seam(
	operator: Node,
	seam: int,
	seam_time: float,
	successor_step: int
) -> Dictionary:
	var outgoing = UNARMED.fast_chain_attack_profiles[seam]
	var incoming = UNARMED.fast_chain_attack_profiles[seam + 1]
	operator.set("velocity", Vector2.ZERO)
	operator.call("_cancel_attack_drive", true)
	operator.set("_melee_fast_combo_step", seam)
	operator.call("_begin_attack_drive", outgoing, Vector2.RIGHT)
	var driven := 0.0
	for _i in int(round(seam_time * 60.0)):
		operator.call("_physics_process", 1.0 / 60.0)
		driven += (operator.get("_last_attack_drive_velocity") as Vector2).length() / 60.0

	operator.set(
		"_melee_fast_combo_step",
		seam + 1 if successor_step < 0 else successor_step
	)
	operator.call("_begin_attack_drive", incoming, Vector2.RIGHT)
	var dead_frames := 0
	for _i in int(ceil(incoming.drive_delay_sec * 60.0)):
		operator.call("_physics_process", 1.0 / 60.0)
		var speed: float = (operator.get("_last_attack_drive_velocity") as Vector2).length()
		driven += speed / 60.0
		if speed <= 0.001:
			dead_frames += 1
	for _i in 60:
		operator.call("_physics_process", 1.0 / 60.0)
		driven += (operator.get("_last_attack_drive_velocity") as Vector2).length() / 60.0
	return {"driven": driven, "dead_frames": dead_frames}


## Every existing interruption must still take the carry with it.
func _validate_carry_interruptions(operator: Node) -> void:
	for case in ["dodge", "damage", "block"]:
		_install_live_carry(operator)
		_assert_true(
			bool(operator.call("_has_attack_drive_carry")),
			"the %s interruption case needs a live carry to interrupt" % case
		)
		match case:
			"dodge":
				# A dodge refuses to start from an active attack, so the actor is
				# put in the state a dodge is genuinely allowed from. What is
				# under test is that the dodge takes the carry with it.
				for lock in [
					"_melee_active", "_melee_fast_windup", "_melee_recovery_active",
					"_melee_heavy_anticipating", "_dodge_charge_active",
					"_dodge_active", "_dodge_recovery_active", "_field_patch_active",
				]:
					operator.set(lock, false)
				operator.set("_dodge_cooldown_remaining", 0.0)
				operator.set("_enemy_impact_lock_timer", 0.0)
				operator.set("stamina", 100.0)
				var reason := String(operator.call("_get_dodge_start_rejection_reason", -1.0))
				var started: bool = bool(operator.call(
					"_try_start_dodge_with_profile", Vector2.RIGHT, &"tap", -1.0
				))
				_assert_true(
					started,
					"the dodge interruption case needs the dodge to start, refused with %s"
						% ("no reason" if reason.is_empty() else reason)
				)
			"damage":
				operator.call("_interrupt_active_combat_for_damage_reaction")
			"block":
				operator.call("_request_block_state")
		_assert_true(
			not bool(operator.call("_has_attack_drive_carry")),
			"a %s must clear carried chain momentum" % case
		)
		operator.set("_dodge_active", false)
		operator.set("_dodge_recovery_active", false)
		operator.call("_cancel_attack_drive", true)
	await process_frame


## Blocking geometry must still truncate the contribution, carry included.
##
## Run twice from the same staged handoff, once unobstructed and once into a
## wall, and compare. Asserting only that the drive ended would pass vacuously --
## it ends on its own after its authored duration either way -- so what is
## measured is that the wall ends it sooner and shorter.
func _validate_carry_collision(operator: Node, root: Node) -> void:
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32.0, 256.0)
	shape.shape = rect
	wall.add_child(shape)
	root.add_child(wall)

	var clear_run := await _run_handoff_against_wall(operator, wall, false)
	var blocked_run := await _run_handoff_against_wall(operator, wall, true)

	_assert_true(
		int(blocked_run["end_frame"]) >= 0 and int(clear_run["end_frame"]) >= 0,
		"both collision runs must terminate their drive within the sample window"
	)
	_assert_true(
		int(blocked_run["end_frame"]) < int(clear_run["end_frame"]),
		"blocking geometry must end the drive sooner than its authored duration, "
			+ "blocked ended on frame %d and clear on frame %d"
				% [int(blocked_run["end_frame"]), int(clear_run["end_frame"])]
	)
	_assert_true(
		float(blocked_run["travelled"]) < float(clear_run["travelled"]) - 1.0,
		"blocking geometry must truncate the distance, blocked %.2f px vs clear %.2f px"
			% [float(blocked_run["travelled"]), float(clear_run["travelled"])]
	)
	wall.queue_free()
	operator.global_position = Vector2.ZERO
	operator.set("velocity", Vector2.ZERO)
	operator.call("_cancel_attack_drive", true)
	await process_frame


func _run_handoff_against_wall(
	operator: Node,
	wall: StaticBody2D,
	obstruct: bool
) -> Dictionary:
	# Parked far away while the handoff is staged, because staging drives forward
	# and would otherwise hit the wall before the carry exists.
	wall.global_position = Vector2(100000.0, 0.0)
	await physics_frame
	_install_live_carry(operator)
	_assert_true(
		bool(operator.call("_has_attack_drive_carry")),
		"the collision case needs a live carry to truncate"
	)
	var start_x: float = operator.global_position.x
	if obstruct:
		wall.global_position = Vector2(start_x + 26.0, 0.0)
	await physics_frame
	var end_frame := -1
	for frame in range(30):
		operator.call("_physics_process", 1.0 / 60.0)
		if end_frame < 0 \
		and (operator.get("_attack_drive_direction") as Vector2) == Vector2.ZERO:
			end_frame = frame
	return {
		"end_frame": end_frame,
		"travelled": operator.global_position.x - start_x,
	}


## Put the actor mid-handoff, with carry installed and still unspent.
func _install_live_carry(operator: Node) -> void:
	operator.global_position = Vector2.ZERO
	operator.set("velocity", Vector2.ZERO)
	operator.set("_melee_attack_kind", "fast")
	operator.call("_cancel_attack_drive", true)
	operator.set("_melee_fast_combo_step", 0)
	operator.call(
		"_begin_attack_drive", UNARMED.fast_chain_attack_profiles[0], Vector2.RIGHT
	)
	for _i in int(round(_chain_seam_time(0) * 60.0)):
		operator.call("_physics_process", 1.0 / 60.0)
	operator.set("_melee_fast_combo_step", 1)
	operator.call(
		"_begin_attack_drive", UNARMED.fast_chain_attack_profiles[1], Vector2.RIGHT
	)
