extends SceneTree

## Combat tempo + impact feedback pass: parry success presentation was
## reduced (world VFX scale ~40% down, camera impulse removed) while parry
## mechanics (window, counter window, stagger duration, stamina refund,
## critical-open) stay untouched. This smoke covers the presentation change
## directly; grunt_parry_crit_reaction_smoke.gd covers the critical-open flow.

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

## The authored parry strip, measured rather than assumed. Frame 0 is
## anticipation and frame 1 raises the guard; the guard is only fully extended
## across frames 2-3, which is where an incoming blow can be caught.
const PARRY_FPS := 12.0
const PARRY_CATCH_FIRST_FRAME := 2
const PARRY_CATCH_LAST_FRAME := 3
const PARRY_SECTOR_FRAMES := {"e": 5, "n": 5, "w": 6}

var _failed := false


class CameraImpactProbe:
	extends Node2D
	var impact_calls := 0
	var damage_calls := 0

	func on_attack_impact(_direction: Vector2, _is_heavy: bool = false) -> void:
		impact_calls += 1

	func on_damage_taken(_direction: Vector2) -> void:
		damage_calls += 1


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	get_root().add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var camera_probe := CameraImpactProbe.new()
	camera_probe.name = "Camera2D"
	world.add_child(camera_probe)

	var operator := OPERATOR_SCENE.instantiate()
	world.add_child(operator)
	await process_frame

	var attacker := Node2D.new()
	attacker.name = "DummyAttacker"
	world.add_child(attacker)
	attacker.global_position = operator.global_position + Vector2(30.0, 0.0)

	operator.set("stamina", 10.0)

	operator.call(
		"guard_apply_parry_success",
		attacker,
		Vector2.LEFT,
		{"impact_position": operator.global_position}
	)
	await process_frame

	_assert(
		camera_probe.impact_calls == 0,
		"parry success must not trigger the generic attack-impact camera impulse"
	)

	var burst_root := _find_burst_root(world)
	_assert(burst_root != null, "parry success must spawn its world VFX burst")
	if burst_root != null:
		_assert(
			burst_root.scale.is_equal_approx(Vector2(0.6, 0.6)),
			"parry success burst VFX scale must be reduced ~40%% (expected 0.6, got %s)" % burst_root.scale
		)

	_assert(
		float(operator.get("stamina")) > 10.0,
		"parry stamina refund must be unaffected by the presentation change"
	)

	# Presentation must fire exactly once per call -- a second, independent
	# call spawns exactly one more burst (no doubling within a single call).
	var bursts_after_first := _count_bursts(world)
	operator.call(
		"guard_apply_parry_success",
		attacker,
		Vector2.LEFT,
		{"impact_position": operator.global_position}
	)
	await process_frame
	var bursts_after_second := _count_bursts(world)
	_assert(
		bursts_after_second - bursts_after_first == 1,
		"each parry success call must spawn exactly one presentation burst"
	)

	await _check_window_sits_on_the_authored_catch(operator)
	await _check_direction_parity(operator)
	await _check_success_faces_the_contact(operator, world)
	await _check_failed_parry_keeps_the_attempt(operator)

	game_root.queue_free()
	await process_frame
	if _failed:
		push_error("operator_parry_presentation_smoke failed")
		quit(1)
		return
	print("[OperatorParryPresentationSmoke] PASS")
	quit(0)


func _find_burst_root(node: Node) -> Node2D:
	for child in node.get_children():
		if child.name != "DummyAttacker" and child.name != "Camera2D" and child is Node2D and child.get_script() != null and child != node:
			var script := child.get_script() as Script
			if script != null and String(script.resource_path).contains("parry_success_burst_vfx"):
				return child as Node2D
		var found := _find_burst_root(child)
		if found != null:
			return found
	return null


func _count_bursts(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		var script := child.get_script() as Script
		if script != null and String(script.resource_path).contains("parry_success_burst_vfx"):
			count += 1
		count += _count_bursts(child)
	return count


func _assert(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)


## The deterministic parry window must sit on the visible catch.
##
## Nothing here makes the animation gameplay authority -- the runtime never reads
## a frame to decide whether a parry lands. The art is evidence, and this asserts
## that the config-owned numbers were chosen from it: the whole active window has
## to fall inside the frames where the guard is actually extended.
##
## Measured from the canonical strips. FX is absent on frame 0, appears as the
## guard rises on frame 1, and the upper body reaches its widest extent across
## frames 2-3 before the follow-through:
##
##     e  5f  upper px 889 / 959 / 1198 / 1308 / 854   reach 18 / 24 / 41 / 41 / 21
##     n  5f  fx px      0 / 100 /  218 /  136 /   0
##     w  6f  identical to e for 0-4, plus one settle frame
func _check_window_sits_on_the_authored_catch(operator: Node) -> void:
	var config = operator.get("guard_config")
	if config == null:
		_assert(false, "the timing case needs the guard config")
		return
	var windup: float = config.parry_windup_time
	var active: float = config.parry_active_time
	var catch_open := float(PARRY_CATCH_FIRST_FRAME) / PARRY_FPS
	var catch_close := float(PARRY_CATCH_LAST_FRAME + 1) / PARRY_FPS

	_assert(
		windup >= catch_open - 0.001,
		"the parry window opens at %.3f s, before the guard is extended at %.3f s"
			% [windup, catch_open]
	)
	_assert(
		windup + active <= catch_close + 0.001,
		"the parry window closes at %.3f s, after the catch ends at %.3f s"
			% [windup + active, catch_close]
	)
	# The forgiveness window itself is not part of this alignment.
	_assert(
		is_equal_approx(active, 0.10),
		"C8 aligns the window, it does not resize it; active is %.3f s" % active
	)
	# Alignment is not rebalancing. These are the values the slice must not move.
	for entry in [
		["parry_success_stamina_refund", 6.0],
		["parry_enemy_stagger_time", 0.55],
		["parry_enemy_knockback", 44.0],
		["counter_window_time", 0.45],
		["parry_recovery_time", 0.16],
		["parry_success_recovery_time", 0.03],
		["minimum_guard_time", 0.04],
	]:
		_assert(
			is_equal_approx(float(config.get(entry[0])), float(entry[1])),
			"%s changed to %.3f; C8 aligns timing and facing only"
				% [entry[0], float(config.get(entry[0]))]
		)
	# The alignment rule itself, evaluated against arbitrary timing rather than
	# only against whatever is currently configured. Without this the assertions
	# above can only ever agree with the Resource they read.
	_assert(
		_window_fits_authored_catch(windup, active),
		"the configured window %.5f-%.5f s does not fit the authored catch"
			% [windup, windup + active]
	)
	_assert(
		not _window_fits_authored_catch(0.02, active),
		"the pre-C8 window 0.020-0.120 s must NOT fit the authored catch, which "
			+ "begins at 2/12 = %.5f s; this control is what makes the assertion "
				% (float(PARRY_CATCH_FIRST_FRAME) / PARRY_FPS)
			+ "above mean something"
	)
	# ...and for the right reason: it opens too early, not because it is too long.
	_assert(
		0.02 + active <= catch_close + 0.001,
		"the pre-C8 control should fail on its opening time, but it also overruns "
			+ "the catch, so it would fail for two reasons at once"
	)

	# Drive the real controller across the boundaries, and throw a real incoming
	# attack at each one. `parry_active` alone says what the controller believes;
	# only `try_parry_incoming_attack()` says what an attack actually meets.
	var guard = operator.get("_guard_controller")
	if guard == null:
		_assert(false, "the timing case needs the live guard controller")
		return
	operator.call("_apply_unarmed_selection")
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	var samples := [
		["before the window opens", windup - 0.02, false],
		["inside the window", windup + active * 0.5, true],
		["after the window closes", windup + active + 0.02, false],
	]
	for sample in samples:
		var label := String(sample[0])
		var expected: bool = bool(sample[2])
		# A fresh attempt and a fresh attacker per sample, so the successful
		# middle case cannot leave a lockout or a staggered attacker behind.
		guard.call("reset")
		operator.set("stamina", 100.0)
		var attacker := Node2D.new()
		(operator as Node2D).get_parent().add_child(attacker)
		attacker.global_position = (operator as Node2D).global_position + Vector2(40.0, 0.0)
		_assert(
			bool(guard.call("begin_parry")),
			"%s: the parry attempt must start" % label
		)
		var elapsed := 0.0
		var step := 1.0 / 240.0
		while elapsed < float(sample[1]) - step * 0.5:
			guard.call("tick", step)
			elapsed += step
		_assert(
			bool(guard.get("parry_active")) == expected,
			"%s (%.3f s): parry_active should be %s" % [label, elapsed, expected]
		)
		# Re-assert the guard facing immediately before the hit. The actor
		# recomputes `aim_direction` from live input on its own frames, and a
		# drifted guard direction would make `guard_faces_hit()` reject the attack
		# for a reason that has nothing to do with the timing under test.
		operator.set("aim_direction", Vector2.RIGHT)
		operator.set("visual_idle_direction", Vector2.RIGHT)
		_assert(
			bool(operator.call("guard_faces_hit", Vector2.LEFT, 0.35, attacker)),
			"%s: the guard must face the incoming attack, or the timing result is "
				% label
				+ "about facing instead"
		)
		# The attack travels from the attacker toward the Operator, and goes
		# through `guard_faces_hit()` exactly as an enemy swing would.
		var landed: bool = bool(operator.call(
			"try_parry_incoming_attack",
			attacker,
			Vector2.LEFT,
			{"impact_position": attacker.global_position}
		))
		_assert(
			landed == expected,
			"%s (%.3f s): a real incoming hit should be parried=%s, got %s"
				% [label, elapsed, expected, landed]
		)
		attacker.queue_free()
		await process_frame
	guard.call("reset")
	await process_frame


## The six-frame west strip must not buy a longer or later gameplay window.
func _check_direction_parity(operator: Node) -> void:
	var guard = operator.get("_guard_controller")
	var config = operator.get("guard_config")
	if guard == null or config == null:
		_assert(false, "the parity case needs the live guard controller")
		return
	_assert(
		int(PARRY_SECTOR_FRAMES["w"]) != int(PARRY_SECTOR_FRAMES["e"]),
		"the parity case is vacuous unless the sectors really differ in length"
	)
	var timings := {}
	for facing in {"e": Vector2.RIGHT, "n": Vector2.UP, "w": Vector2.LEFT}:
		guard.call("reset")
		operator.set("stamina", 100.0)
		operator.set("aim_direction", {"e": Vector2.RIGHT, "n": Vector2.UP, "w": Vector2.LEFT}[facing])
		operator.set("visual_idle_direction", operator.get("aim_direction"))
		_assert(bool(guard.call("begin_parry")), "%s parry must start" % facing)
		var elapsed := 0.0
		var step := 1.0 / 240.0
		var opened := -1.0
		var closed := -1.0
		while elapsed < 1.0:
			guard.call("tick", step)
			elapsed += step
			if opened < 0.0 and bool(guard.get("parry_active")):
				opened = elapsed
			elif opened >= 0.0 and closed < 0.0 and not bool(guard.get("parry_active")):
				closed = elapsed
				break
		timings[facing] = [opened, closed]
	guard.call("reset")
	var reference: Array = timings["e"]
	for facing in timings:
		var measured: Array = timings[facing]
		_assert(
			absf(float(measured[0]) - float(reference[0])) <= 0.01
				and absf(float(measured[1]) - float(reference[1])) <= 0.01,
			"%s opened/closed at %.3f/%.3f against east %.3f/%.3f; art length leaked into simulation"
				% [facing, measured[0], measured[1], reference[0], reference[1]]
		)
	await process_frame


## A confirmed parry answers the contact, not whatever aim reads a frame later.
func _check_success_faces_the_contact(operator: Node, world: Node) -> void:
	# The shipped scene equips the Vigil dagger, and `_play_modular_unarmed_parry()`
	# refuses a non-unarmed profile, so without this the case measures the legacy
	# fallback instead of the canonical parry sectors.
	operator.call("_apply_unarmed_selection")
	var attacker := Node2D.new()
	world.add_child(attacker)
	for label in ["east", "west"]:
		var attacker_offset := Vector2(60.0, 0.0) if label == "east" else Vector2(-60.0, 0.0)
		# Aim deliberately disagrees with the incoming attacker.
		var stale_aim := Vector2.LEFT if label == "east" else Vector2.RIGHT
		attacker.global_position = (operator as Node2D).global_position + attacker_offset
		operator.set("aim_direction", stale_aim)
		operator.set("visual_idle_direction", stale_aim)
		var hit_direction := -attacker_offset.normalized()
		var facing := operator.call(
			"_resolve_parry_contact_facing", attacker, hit_direction
		) as Vector2
		_assert(
			facing.dot(attacker_offset.normalized()) > 0.9,
			"%s: the confirmed parry should face the attacker, resolved %s" % [label, facing]
		)
		_assert(
			facing.dot(stale_aim) < 0.0,
			"%s: stale aim won the success facing" % label
		)
		# The control: what the pre-C8 rule would have drawn. Resolving the same
		# clip from aim rather than from the contact picks the opposite sector, so
		# the ownership rule is doing real work here and not merely agreeing with
		# a direction that happened to match.
		var aim_sector := String(operator.call(
			"_resolve_modular_body_animation",
			"unarmed_parry_success", &"lower_body", stale_aim
		))
		var contact_sector := String(operator.call(
			"_resolve_modular_body_animation",
			"unarmed_parry_success", &"lower_body", facing
		))
		var wrong_sector := "/w/" if label == "east" else "/e/"
		_assert(
			aim_sector.contains(wrong_sector),
			"%s: the stale-aim control should resolve %s, resolved %s"
				% [label, wrong_sector, aim_sector]
		)
		_assert(
			aim_sector != contact_sector,
			"%s: the facing control is vacuous -- aim and contact resolve the same "
				% label
				+ "sector (%s), so nothing would distinguish the old rule" % aim_sector
		)
		# And the real success path must draw that sector.
		var contact := (operator as Node2D).global_position + attacker_offset * 0.5
		var before := _collect_bursts(world)
		operator.call(
			"guard_apply_parry_success", attacker, hit_direction,
			{"impact_position": contact}
		)
		# Read before yielding: the next `_update_animation()` hands the body back
		# to whatever owns it, so the success pose is only on screen right now.
		var lower := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
		var expected_sector := "/e/" if label == "east" else "/w/"
		_assert(
			String(lower.animation).contains(expected_sector),
			"%s: success body drew %s, expected the %s sector"
				% [label, lower.animation, expected_sector]
		)
		# The world effects must still land on the real contact point. The burst
		# from this call is the one that was not there a moment ago.
		var fresh := _collect_bursts(world)
		var spawned: Node2D = null
		for node in fresh:
			if not before.has(node):
				spawned = node
				break
		_assert(spawned != null, "%s: success must spawn its own burst" % label)
		if spawned != null:
			_assert(
				spawned.global_position.distance_to(contact) <= 1.0,
				"%s: success burst moved off the contact point, %s vs %s"
					% [label, spawned.global_position, contact]
			)
		await process_frame
	attacker.queue_free()
	await process_frame


## A parry that never catches anything keeps its original attempt.
func _check_failed_parry_keeps_the_attempt(operator: Node) -> void:
	var guard = operator.get("_guard_controller")
	if guard == null:
		return
	operator.call("_apply_unarmed_selection")
	guard.call("reset")
	operator.set("stamina", 100.0)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	_assert(bool(guard.call("begin_parry")), "the failed-parry case needs an attempt")
	# Read before yielding, for the same reason as the success case.
	var lower := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var attempt := String(lower.animation)
	_assert(
		attempt.contains("defense/parry_01"),
		"the attempt should draw the authored parry strip, drew %s" % attempt
	)
	var config = operator.get("guard_config")
	var elapsed := 0.0
	while elapsed < float(config.parry_windup_time) + float(config.parry_active_time) + 0.05:
		guard.call("tick", 1.0 / 240.0)
		elapsed += 1.0 / 240.0
	_assert(
		not bool(guard.get("parry_active")),
		"an unanswered parry must close its window"
	)
	_assert(
		String(lower.animation) == attempt,
		"an unanswered parry reoriented its attempt, %s -> %s" % [attempt, lower.animation]
	)
	guard.call("reset")
	await process_frame


func _collect_bursts(node: Node) -> Array[Node2D]:
	var found: Array[Node2D] = []
	for child in node.get_children():
		var script := child.get_script() as Script
		if child is Node2D and script != null \
		and String(script.resource_path).contains("parry_success_burst_vfx"):
			found.append(child as Node2D)
		found.append_array(_collect_bursts(child))
	return found


## Does a deterministic window sit inside the frames where the guard is extended?
##
## Pure, so it can be asked about timing that is not currently configured. That is
## the whole point: an assertion that only reads the live Resource agrees with
## whatever that Resource says, and would have passed just as happily before C8.
func _window_fits_authored_catch(windup: float, active: float) -> bool:
	var catch_open := float(PARRY_CATCH_FIRST_FRAME) / PARRY_FPS
	var catch_close := float(PARRY_CATCH_LAST_FRAME + 1) / PARRY_FPS
	return windup >= catch_open - 0.001 and windup + active <= catch_close + 0.001

