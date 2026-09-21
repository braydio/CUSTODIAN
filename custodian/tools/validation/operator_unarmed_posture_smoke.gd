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

	await _check_quiet_presents_relaxed(operator)
	await _check_engagement_transitions_to_ready(operator)
	await _check_quiet_transitions_back_to_relaxed(operator)
	await _check_direction_policy(operator)
	await _check_movement_preempts(operator)
	await _check_attack_is_not_gated(operator)
	await _check_real_owners_preempt_a_transition(operator)
	await _check_guard_flags_cancel_a_transition(operator)
	await _check_selector_stays_exact_only(operator)

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
