extends SceneTree
## Unarmed READY/RELAXED posture is presentation, and only presentation.
##
## Two properties matter more than the artwork. Posture must never gate gameplay:
## an attack from RELAXED begins immediately, with no ready-up latency. And
## posture must never survive losing the body: anything that preempts it -- a step
## forward, an attack, a dodge, a hit, death -- retires it at once, and no
## in-flight transition may wake up afterwards and draw over the new owner.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

const RELAXED := "unarmed/posture/idle_relaxed_01"
const READY := "unarmed/posture/idle_ready_01"
const TO_READY := "unarmed/transition/relaxed_to_ready_01"
const TO_RELAXED := "unarmed/transition/ready_to_relaxed_01"
const FAST_04 := "unarmed/attack/fast_04"
const FAST_04_FRAMES := 8
const FAST_04_TARGET_SEC := 0.52

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorUnarmedPostureRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	# Every case here drives posture and presentation explicitly through
	# `_settle()`. Leaving the actor's own ticks running as well means a physics
	# tick can land inside an `await` and complete an attack the case was in the
	# middle of stepping by hand, which shows up as an intermittent failure rather
	# than a wrong answer.
	operator.set_process(false)
	operator.set_physics_process(false)

	await _check_quiet_presents_relaxed(operator)
	await _check_engagement_transitions_to_ready(operator)
	await _check_quiet_transitions_back_to_relaxed(operator)
	await _check_direction_policy(operator)
	await _check_movement_preempts(operator)
	await _check_attack_is_not_gated(operator)
	await _check_real_owners_preempt_a_transition(operator)
	await _check_guard_flags_cancel_a_transition(operator)
	await _check_selector_stays_exact_only(operator)
	await _check_terminal_settle_engaged(operator)
	await _check_terminal_settle_quiet(operator)
	await _check_terminal_settle_is_not_installed_by_interruptions(operator)
	await _check_terminal_restart_is_not_swallowed(operator)

	operator.queue_free()
	if _failures.is_empty():
		print("operator_unarmed_posture_smoke passed")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator_unarmed_posture_smoke: %d failure(s)" % _failures.size())
	quit(1)


# --- helpers -----------------------------------------------------------------

func _lower(operator: Node) -> AnimatedSprite2D:
	return operator.get("modular_lower_body_sprite") as AnimatedSprite2D


func _upper(operator: Node) -> AnimatedSprite2D:
	return operator.get("modular_upper_body_sprite") as AnimatedSprite2D


func _set_engagement(operator: Node, active: bool) -> void:
	var tracker = operator.get("_engagement_tracker")
	if tracker != null:
		tracker.set("engagement_active", active)


func _stand_still_unarmed(operator: Node, facing: Vector2 = Vector2.RIGHT) -> void:
	operator.call("_apply_unarmed_selection")
	operator.set("velocity", Vector2.ZERO)
	operator.set("visual_idle_direction", facing)
	operator.set("aim_direction", facing)
	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)
	operator.set("_dodge_active", false)
	operator.set("_dodge_recovery_active", false)
	operator.set("melee_cooldown_remaining", 0.0)


## Advance posture and presentation the way `_physics_process` does.
func _settle(operator: Node, steps: int = 4, delta: float = 0.1) -> void:
	for _i in steps:
		operator.call("_update_unarmed_presentation_posture")
		operator.call("_update_animation")
		await process_frame


## Drive the clock's completion signal, which is what ends a transition.
func _finish_transition(operator: Node) -> void:
	var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
	if clock == null:
		clock = _lower(operator)
	operator.call("_on_operator_animation_finished", clock)
	await process_frame
	await _settle(operator, 2)


# --- cases -------------------------------------------------------------------

func _check_quiet_presents_relaxed(operator: Node) -> void:
	_stand_still_unarmed(operator)
	_set_engagement(operator, false)
	await _settle(operator)
	var lower := _lower(operator)
	_check(
		lower != null and String(lower.animation).begins_with(RELAXED),
		"quiet unarmed neutral should present idle_relaxed_01, got %s"
			% ("null" if lower == null else String(lower.animation))
	)
	_check(lower == null or lower.visible, "the relaxed posture body should be visible")


func _check_engagement_transitions_to_ready(operator: Node) -> void:
	_stand_still_unarmed(operator)
	_set_engagement(operator, false)
	await _settle(operator)
	_set_engagement(operator, true)

	# One advance should enter the transition rather than jumping to the ready idle.
	operator.call("_update_unarmed_presentation_posture")
	operator.call("_update_animation")
	await process_frame
	var lower := _lower(operator)
	var during := "null" if lower == null else String(lower.animation)
	_check(
		during.begins_with(TO_READY),
		"engagement should drive relaxed_to_ready_01 before idle_ready_01, got %s" % during
	)

	# Finish the transition through the real completion path rather than waiting on
	# elapsed time; the authored placeholders are one frame and the point is the
	# semantics, not the duration.
	await _finish_transition(operator)
	lower = _lower(operator)
	_check(
		lower != null and String(lower.animation).begins_with(READY),
		"after the transition the posture should settle on idle_ready_01, got %s"
			% ("null" if lower == null else String(lower.animation))
	)


func _check_quiet_transitions_back_to_relaxed(operator: Node) -> void:
	_stand_still_unarmed(operator)
	_set_engagement(operator, true)
	await _settle(operator)
	await _finish_transition(operator)
	_set_engagement(operator, false)

	operator.call("_update_unarmed_presentation_posture")
	operator.call("_update_animation")
	await process_frame
	var lower := _lower(operator)
	var during := "null" if lower == null else String(lower.animation)
	_check(
		during.begins_with(TO_RELAXED),
		"going quiet should drive ready_to_relaxed_01 before idle_relaxed_01, got %s" % during
	)

	await _finish_transition(operator)
	lower = _lower(operator)
	_check(
		lower != null and String(lower.animation).begins_with(RELAXED),
		"after the transition the posture should settle on idle_relaxed_01, got %s"
			% ("null" if lower == null else String(lower.animation))
	)


func _check_direction_policy(operator: Node) -> void:
	## East and west are separately authored, so west must use the west strip and
	## must not be an east strip mirrored. North and south have no authored posture
	## and take the caller's projection rather than inventing art.
	var expectations := {
		"east": {"facing": Vector2.RIGHT, "sector": "/e/"},
		"west": {"facing": Vector2.LEFT, "sector": "/w/"},
		"north": {"facing": Vector2.UP, "sector": "/e/"},
		"south": {"facing": Vector2.DOWN, "sector": "/e/"},
	}
	for label in expectations:
		var facing: Vector2 = expectations[label]["facing"]
		var sector: String = expectations[label]["sector"]
		_stand_still_unarmed(operator, facing)
		_set_engagement(operator, false)
		await _settle(operator)
		var lower := _lower(operator)
		var upper := _upper(operator)
		_check(
			lower != null and String(lower.animation).contains(sector),
			"%s posture should draw the %s lower body, got %s"
				% [label, sector, "null" if lower == null else String(lower.animation)]
		)
		_check(
			upper != null and String(upper.animation).contains(sector),
			"%s posture should draw the %s upper body, got %s"
				% [label, sector, "null" if upper == null else String(upper.animation)]
		)
		_check(lower == null or not lower.flip_h, "%s posture lower body must not be mirrored" % label)
		_check(upper == null or not upper.flip_h, "%s posture upper body must not be mirrored" % label)


func _check_movement_preempts(operator: Node) -> void:
	_stand_still_unarmed(operator)
	_set_engagement(operator, false)
	await _settle(operator)
	_check(
		String(_lower(operator).animation).begins_with(RELAXED),
		"posture should own the body before movement begins"
	)

	operator.set("velocity", Vector2.RIGHT * 80.0)
	operator.set("movement_direction", Vector2.RIGHT)
	await _settle(operator)
	var lower := _lower(operator)
	var moving := "null" if lower == null else String(lower.animation)
	_check(
		not moving.begins_with(RELAXED) and not moving.begins_with(READY),
		"movement should retire posture immediately, still showing %s" % moving
	)
	_check(
		moving.contains("/locomotion/"),
		"movement should present ordinary canonical unarmed locomotion, got %s" % moving
	)
	# `_update_animation` reaches locomotion before the idle branch, so posture is
	# structurally unreachable while moving. Assert the guard directly too, so a
	# direct caller cannot present a stance over a walk.
	_check(
		not bool(operator.call("_can_present_unarmed_posture")),
		"posture must refuse to present while the Operator is moving"
	)
	operator.set("velocity", Vector2.ZERO)


func _check_attack_is_not_gated(operator: Node) -> void:
	## The point of the whole slice: ready-up is cosmetic. An attack from RELAXED
	## begins on the frame it is requested.
	_stand_still_unarmed(operator)
	_set_engagement(operator, false)
	await _settle(operator)
	_check(
		String(_lower(operator).animation).begins_with(RELAXED),
		"the attack case should start from a relaxed posture"
	)

	operator.set("_melee_forward", Vector2.RIGHT)
	operator.call("_try_melee_attack", "unarmed_fast")
	await process_frame
	var engaged_gameplay := bool(operator.get("_melee_active")) \
		or bool(operator.get("_melee_fast_windup"))
	_check(
		engaged_gameplay,
		"an unarmed attack from RELAXED must begin immediately, with no ready-up latency"
	)

	var lower := _lower(operator)
	var during := "null" if lower == null else String(lower.animation)
	_check(
		not during.begins_with(TO_READY),
		"the attack must not be preceded by a posture ready-up, got %s" % during
	)
	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)


## Put posture into a genuine, mid-flight transition and return its clip name.
func _enter_transition(operator: Node) -> String:
	_stand_still_unarmed(operator)
	_set_engagement(operator, false)
	await _settle(operator)
	_set_engagement(operator, true)
	operator.call("_update_unarmed_presentation_posture")
	operator.call("_update_animation")
	await process_frame
	var lower := _lower(operator)
	return "" if lower == null else String(lower.animation)


func _check_single_body_owner(operator: Node, context: String) -> void:
	var presenter = operator.get("_body_presenter")
	if presenter == null:
		return
	var owners: Array = presenter.call("visible_owners")
	_check(
		owners.size() <= 1,
		"%s should leave at most one visible body owner, saw %s" % [context, owners]
	)


func _check_real_owners_preempt_a_transition(operator: Node) -> void:
	## The claim worth proving is a handoff, not a flag. These drive the real
	## attack, dodge and movement paths while a posture transition is genuinely in
	## flight, and check that the body ends up owned by exactly one presenter.
	var during := await _enter_transition(operator)
	_check(
		during.begins_with(TO_READY),
		"the attack-preemption case should start from a live transition, got %s" % during
	)
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.call("_try_melee_attack", "unarmed_fast")
	await process_frame
	# Without this the preemption is never actually exercised and everything below
	# passes vacuously.
	_check(
		bool(operator.get("_melee_active")) or bool(operator.get("_melee_fast_windup")),
		"the attack-preemption case requires the attack to actually start"
	)
	await _settle(operator, 3)
	var posture = operator.get("_unarmed_posture")
	_check(
		posture != null and not bool(posture.call("is_transitioning")),
		"a real attack should drop the in-flight posture transition"
	)
	var after := String(_lower(operator).animation)
	_check(
		not after.begins_with(TO_READY),
		"an attack-preempted transition must not still be drawing, showing %s" % after
	)
	_check_single_body_owner(operator, "attack preempting a posture transition")
	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	await process_frame

	during = await _enter_transition(operator)
	_check(
		during.begins_with(TO_READY),
		"the dodge-preemption case should start from a live transition, got %s" % during
	)
	var dodge_started := bool(operator.call("_try_start_dodge"))
	_check(dodge_started, "the dodge-preemption case requires the dodge to actually start")
	await process_frame
	await _settle(operator, 3)
	posture = operator.get("_unarmed_posture")
	_check(
		posture != null and not bool(posture.call("is_transitioning")),
		"a real dodge should drop the in-flight posture transition"
	)
	_check_single_body_owner(operator, "dodge preempting a posture transition")
	operator.set("_dodge_active", false)
	operator.set("_dodge_recovery_active", false)
	await process_frame

	during = await _enter_transition(operator)
	_check(
		during.begins_with(TO_READY),
		"the movement-preemption case should start from a live transition, got %s" % during
	)
	operator.set("velocity", Vector2.RIGHT * 80.0)
	operator.set("movement_direction", Vector2.RIGHT)
	await _settle(operator, 3)
	posture = operator.get("_unarmed_posture")
	_check(
		posture != null and not bool(posture.call("is_transitioning")),
		"walking away mid-transition should drop it, not finish it later"
	)
	var moving := String(_lower(operator).animation)
	_check(
		moving.contains("/locomotion/"),
		"movement during a transition should hand the body to locomotion, got %s" % moving
	)
	_check_single_body_owner(operator, "movement preempting a posture transition")
	operator.set("velocity", Vector2.ZERO)
	await process_frame


func _check_guard_flags_cancel_a_transition(operator: Node) -> void:
	## Hit reaction and death are checked as guard/cancellation only. These set the
	## flag directly rather than driving the real damage or death presentation, so
	## they prove posture stands down and refuses to present again -- not a full
	## owner transfer. The attack, dodge and movement cases above cover that.
	var cases := {
		"hit reaction": "_modular_damage_reaction_active",
		"death": "_is_dead",
	}
	for label in cases:
		var during := await _enter_transition(operator)
		_check(
			during.begins_with(TO_READY),
			"the %s case should start from a live transition, got %s" % [label, during]
		)
		operator.set(cases[label], true)
		operator.call("_update_unarmed_presentation_posture")
		await process_frame
		await _settle(operator, 4)

		var posture = operator.get("_unarmed_posture")
		_check(
			posture != null and not bool(posture.call("is_transitioning")),
			"%s should cancel the posture transition, not leave it in flight" % label
		)
		_check(
			not bool(operator.call("_can_present_unarmed_posture")),
			"%s should stop posture from presenting at all" % label
		)
		_check(
			not bool(operator.call("_sync_unarmed_posture", Vector2.RIGHT)),
			"%s-preempted posture must refuse to present when asked again" % label
		)
		operator.set(cases[label], false)
		await process_frame


func _check_selector_stays_exact_only(operator: Node) -> void:
	## Posture projects north and south onto an authored sector in the caller. The
	## selector itself must still report the unauthored sectors as absent.
	var selector = operator.call("_get_operator_animation_selector")
	for sector in [&"n", &"s", &"ne", &"nw", &"se", &"sw"]:
		_check(
			not selector.has_sector_identity("unarmed", "posture", "idle_relaxed_01", sector, &"lower_body"),
			"selector should report posture %s as absent rather than substituting" % sector
		)
	for sector in [&"e", &"w"]:
		_check(
			selector.has_sector_identity("unarmed", "posture", "idle_relaxed_01", sector, &"lower_body"),
			"selector should resolve the authored posture sector %s" % sector
		)


# --- C6: terminal Fast 04 posture settle -------------------------------------

## Drive the terminal Fists link to natural completion and report what was drawn.
##
## The link is entered at the terminal step and then left entirely alone: the
## attack ends because `_update_melee_attack` says it has, not because the test
## stopped it. Velocity is pinned to zero each tick only because the finisher
## drives 13 px forward and a coasting actor is not standing still, which would
## hand the body to locomotion for reasons that have nothing to do with posture.
func _drive_terminal_fast_04(operator: Node, engaged: bool) -> Dictionary:
	_stand_still_unarmed(operator)
	_set_engagement(operator, engaged)
	await _settle(operator, 4)
	operator.set("stamina", 100.0)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.call("_clear_attack_buffer")
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.set("_melee_fast_combo_step", 3)
	operator.call("_start_fast_attack")
	await process_frame
	operator.call("_update_animation")
	await process_frame

	var lower := _lower(operator)
	var clip := String(lower.animation)
	var frames := 0
	var visible_sec := 0.0
	if lower.sprite_frames != null and lower.sprite_frames.has_animation(lower.animation):
		frames = lower.sprite_frames.get_frame_count(lower.animation)
		var fps := lower.sprite_frames.get_animation_speed(lower.animation)
		visible_sec = float(frames) / maxf(fps * lower.speed_scale, 0.0001)
	var gameplay_sec := float(operator.get("_melee_duration"))

	var during: Array[String] = []
	var posture_free_during_attack := true
	var settle_armed := false
	var guard := 0
	while bool(operator.get("_melee_active")) and guard < 200:
		operator.set("velocity", Vector2.ZERO)
		operator.call("_update_melee_attack", 1.0 / 60.0)
		if not bool(operator.get("_melee_active")):
			# Read before `_update_animation()`, which is what consumes it.
			settle_armed = bool(operator.get("_unarmed_terminal_settle_pending"))
		else:
			if bool(operator.call("_can_present_unarmed_posture")):
				posture_free_during_attack = false
			_record(during, String(lower.animation))
		operator.call("_update_animation")
		await process_frame
		guard += 1

	# Resolution is driven by the clock's completion signal rather than by waiting
	# out real-time playback: a headless frame is worth several milliseconds on an
	# idle machine and rather more on a loaded one, and a fixed-iteration wait here
	# is exactly the kind of test that passes alone and fails inside a tier run.
	var after: Array[String] = []
	var posture = operator.get("_unarmed_posture")
	for _i in 8:
		operator.set("velocity", Vector2.ZERO)
		operator.call("_update_unarmed_presentation_posture")
		operator.call("_update_animation")
		_record(after, String(lower.animation))
		await process_frame
		if posture != null and bool(posture.call("is_transitioning")):
			await _finish_transition(operator)
			_record(after, String(lower.animation))
	return {
		"clip": clip,
		"frames": frames,
		"visible_sec": visible_sec,
		"gameplay_sec": gameplay_sec,
		"settle_armed": settle_armed,
		"during": during,
		"posture_free_during_attack": posture_free_during_attack,
		"after": after,
		"ready": posture != null and bool(posture.call("is_ready")),
	}


func _record(log: Array[String], value: String) -> void:
	if log.is_empty() or log[log.size() - 1] != value:
		log.append(value)


## The finisher's own authored recovery must survive the settle.
##
## Rather than counting frames across two clocks that do not agree in a headless
## run, this asserts the two facts that make truncation impossible: the clip is
## the authored eight frames playing for exactly its authored target, and the
## gameplay phase outlives that. If the attack ended before 0.52 s the guarded
## ending would be cut, and it does not.
func _check_fast_04_recovery_is_whole(result: Dictionary, context: String) -> void:
	_check(
		String(result["clip"]).begins_with(FAST_04),
		"%s: the terminal link should present %s, got %s" % [context, FAST_04, result["clip"]]
	)
	_check(
		int(result["frames"]) == FAST_04_FRAMES,
		"%s: Fast 04 should keep its %d authored frames, has %d"
			% [context, FAST_04_FRAMES, int(result["frames"])]
	)
	_check(
		absf(float(result["visible_sec"]) - FAST_04_TARGET_SEC) <= 0.01,
		"%s: Fast 04 should play for its authored %.2f s, plays for %.3f s"
			% [context, FAST_04_TARGET_SEC, float(result["visible_sec"])]
	)
	_check(
		bool(result["posture_free_during_attack"]),
		"%s: posture became presentable while the finisher was still active" % context
	)
	for drawn in result["during"]:
		_check(
			not String(drawn).begins_with("unarmed/posture/")
				and not String(drawn).begins_with("unarmed/transition/"),
			"%s: posture drew %s while the finisher was still running" % [context, drawn]
		)


func _check_terminal_settle_engaged(operator: Node) -> void:
	var result := await _drive_terminal_fast_04(operator, true)
	_check_fast_04_recovery_is_whole(result, "engaged terminal settle")
	_check(
		bool(result["settle_armed"]),
		"a naturally completed terminal Fast 04 should arm the posture settle"
	)
	_check(
		bool(result["ready"]),
		"posture should be READY after a finisher that ends guarded, not RELAXED"
	)
	var after: Array = result["after"]
	for drawn in after:
		_check(
			not String(drawn).begins_with(TO_READY),
			"an engaged terminal settle must not insert %s; Fast 04 already "
				% TO_READY
				+ "delivered the body to the guarded anchor (drew %s)" % str(after)
		)
	_check(
		after.has(READY + "/e/lower_body") or _last(after).begins_with(READY),
		"an engaged terminal settle should land on %s, drew %s" % [READY, str(after)]
	)
	_check_single_body_owner(operator, "engaged terminal settle")


func _check_terminal_settle_quiet(operator: Node) -> void:
	var result := await _drive_terminal_fast_04(operator, false)
	_check_fast_04_recovery_is_whole(result, "quiet terminal settle")
	_check(
		bool(result["settle_armed"]),
		"a quiet terminal Fast 04 should still arm the posture settle"
	)
	var after: Array = result["after"]
	var to_relaxed := -1
	var relaxed := -1
	for index in after.size():
		var drawn := String(after[index])
		if to_relaxed < 0 and drawn.begins_with(TO_RELAXED):
			to_relaxed = index
		if relaxed < 0 and drawn.begins_with(RELAXED):
			relaxed = index
	_check(
		to_relaxed >= 0,
		"a quiet terminal settle should exhale through %s, drew %s" % [TO_RELAXED, str(after)]
	)
	_check(
		relaxed >= 0,
		"a quiet terminal settle should end on %s, drew %s" % [RELAXED, str(after)]
	)
	# The pop this closes: guarded finisher straight into relaxed idle.
	_check(
		to_relaxed >= 0 and (relaxed < 0 or to_relaxed < relaxed),
		"a quiet terminal settle popped from the guarded finisher straight to %s "
			% RELAXED
			+ "without the READY -> RELAXED transition, drew %s" % str(after)
	)
	_check_single_body_owner(operator, "quiet terminal settle")


func _last(values: Array) -> String:
	return "" if values.is_empty() else String(values[values.size() - 1])


## An attack that exits through another owner must not hand posture anything.
func _check_terminal_settle_is_not_installed_by_interruptions(operator: Node) -> void:
	for case in ["dodge", "damage"]:
		_stand_still_unarmed(operator)
		_set_engagement(operator, true)
		await _settle(operator, 2)
		operator.set("stamina", 100.0)
		operator.set("melee_cooldown_remaining", 0.0)
		operator.call("_clear_attack_buffer")
		operator.set("_melee_forward", Vector2.RIGHT)
		operator.set("_melee_fast_combo_step", 3)
		operator.call("_start_fast_attack")
		await process_frame
		_check(
			bool(operator.get("_melee_active")),
			"the %s interruption case needs the finisher to actually start" % case
		)
		for _i in 4:
			operator.call("_update_melee_attack", 1.0 / 60.0)
			await process_frame
		match case:
			"dodge":
				operator.set("_melee_active", false)
				operator.set("_dodge_cooldown_remaining", 0.0)
				var started: bool = bool(operator.call(
					"_try_start_dodge_with_profile", Vector2.RIGHT, &"tap", -1.0
				))
				_check(started, "the dodge interruption case needs the dodge to start")
			"damage":
				operator.call("_interrupt_active_combat_for_damage_reaction")
		await process_frame
		operator.call("_update_unarmed_presentation_posture")
		_check(
			not bool(operator.get("_unarmed_terminal_settle_pending")),
			"a finisher interrupted by %s must not install the terminal settle" % case
		)
		operator.set("_dodge_active", false)
		operator.set("_dodge_recovery_active", false)
		operator.set("_modular_damage_reaction_active", false)
		operator.set("_melee_active", false)
	await process_frame


## A buffered press at the terminal link still owns the exit, not posture.
##
## The Fists chain does not route its terminal restart through
## `_fast_chain_commits_on_animation_finished()`, which is a Vigil path, so the
## buffered press is spent at the commit frame instead. Either way the settle
## branch is unreachable while anything is buffered, and this proves it against
## the real consumption rather than against the flag that Fists never sets.
func _check_terminal_restart_is_not_swallowed(operator: Node) -> void:
	_stand_still_unarmed(operator)
	_set_engagement(operator, true)
	await _settle(operator, 2)
	operator.set("stamina", 100.0)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.call("_clear_attack_buffer")
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.set("_melee_fast_combo_step", 3)
	operator.set("_unarmed_terminal_settle_pending", false)
	operator.call("_start_fast_attack")
	await process_frame
	operator.call("_update_animation")
	await process_frame
	operator.call("_try_melee_attack", "unarmed_fast")
	_check(
		String(operator.get("_buffered_attack_kind")) == "fast",
		"the restart case needs a buffered fast press at the terminal link"
	)
	var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
	if clock != null:
		clock.frame = int(operator.call("_get_fast_chain_commit_frame"))
	var guard := 0
	while bool(operator.get("_melee_active")) and guard < 200:
		operator.set("velocity", Vector2.ZERO)
		operator.call("_update_melee_attack", 1.0 / 60.0)
		guard += 1
		await process_frame
	_check(
		not bool(operator.get("_unarmed_terminal_settle_pending")),
		"a buffered press at the terminal link must not arm the posture settle"
	)
	# Posture must not add latency to what comes next. A transition may legitimately
	# be running here -- the actor is engaged and posture is resuming -- so what is
	# asserted is that it cannot delay the attack, which is the contract that matters.
	operator.call("_clear_attack_buffer")
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("stamina", 100.0)
	operator.call("_try_melee_attack", "unarmed_fast")
	await process_frame
	_check(
		bool(operator.get("_melee_active")) or bool(operator.get("_melee_fast_windup")),
		"a restart after the terminal link must begin immediately, with no posture latency"
	)
	operator.call("_clear_attack_buffer")
	operator.set("_melee_active", false)
	operator.set("_terminal_fast_restart_buffered", false)
	operator.set("_fast_chain_terminal_restart_grace_remaining", 0.0)
	await process_frame
