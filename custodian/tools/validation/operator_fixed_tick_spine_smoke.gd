extends SceneTree
## The fixed tick is the simulation spine; the render tick draws.
##
## Before Slice D the Operator advanced combat clocks, ran input handlers and
## changed state from `_process(delta)`, which made gameplay depend on frame rate:
## the same second of play resolved differently at 30 fps and at 240. This asserts
## the split directly -- render ticks must move nothing, fixed ticks must move
## everything -- across representative systems rather than every timer.
##
## It fails against the pre-Slice-D architecture, where `_process` drained exactly
## these clocks.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

## One clock per system the packet names, so a regression in any of them shows up
## as a named failure rather than a general one.
const CLOCKS := {
	"melee attack timeline": "melee_cooldown_remaining",
	"dodge cooldown": "_dodge_cooldown_remaining",
	"dodge iframes": "_dodge_iframe_timer",
	"ranged fire cooldown": "fire_cooldown_remaining",
}

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorFixedTickSpineRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	# Drive the ticks by hand so the engine's own scheduling cannot mask which one
	# is doing the work.
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set("unstuck_enabled", false)

	await _check_render_tick_moves_nothing(operator)
	await _check_fixed_tick_advances(operator)
	await _check_reload_is_fixed_tick_owned(operator)
	await _check_gameplay_bearing_advancers(operator)
	await _check_injected_control_can_start_an_attack(operator)
	await _check_injected_attack_uses_the_supplied_facing(operator)

	operator.queue_free()
	root.queue_free()
	await process_frame
	if _failures.is_empty():
		print("operator_fixed_tick_spine_smoke passed")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator_fixed_tick_spine_smoke: %d failure(s)" % _failures.size())
	quit(1)


func _arm_clocks(operator: Node) -> Dictionary:
	var armed := {}
	for label: String in CLOCKS:
		operator.set(CLOCKS[label], 1.0)
		armed[label] = 1.0
	return armed


## Render ticks are presentation. Ten of them must not move a single clock.
func _check_render_tick_moves_nothing(operator: Node) -> void:
	_arm_clocks(operator)
	for _i in 10:
		operator.call("_process", 0.1)
		await process_frame
	for label: String in CLOCKS:
		var value := float(operator.get(CLOCKS[label]))
		_check(
			is_equal_approx(value, 1.0),
			"%s advanced from the render tick: %s is %.4f after 1.0 s of _process"
				% [label, CLOCKS[label], value]
		)


## Fixed ticks are simulation, and they advance by exactly the delta they are given.
func _check_fixed_tick_advances(operator: Node) -> void:
	_arm_clocks(operator)
	for _i in 4:
		operator.call("_advance_simulation", 0.1)
		await process_frame
	for label: String in CLOCKS:
		var value := float(operator.get(CLOCKS[label]))
		_check(
			absf(value - 0.6) <= 0.001,
			"%s did not advance deterministically on the fixed tick: %s is %.4f, expected 0.600"
				% [label, CLOCKS[label], value]
		)

	# And the same total time in one step lands in the same place, which is what
	# "deterministic" has to mean for a clock.
	_arm_clocks(operator)
	operator.call("_advance_simulation", 0.4)
	await process_frame
	for label: String in CLOCKS:
		_check(
			absf(float(operator.get(CLOCKS[label])) - 0.6) <= 0.001,
			"%s is step-size dependent" % label
		)


## Reload is a separate subsystem with its own timer; prove it moved too.
func _check_reload_is_fixed_tick_owned(operator: Node) -> void:
	operator.set("_reload_active", true)
	operator.set("_reload_timer", 1.0)
	for _i in 5:
		operator.call("_process", 0.1)
		await process_frame
	_check(
		is_equal_approx(float(operator.get("_reload_timer")), 1.0),
		"reload advanced from the render tick, timer is %.4f" % float(operator.get("_reload_timer"))
	)
	operator.call("_advance_simulation", 0.25)
	await process_frame
	_check(
		float(operator.get("_reload_timer")) < 1.0,
		"reload did not advance on the fixed tick, timer is %.4f" % float(operator.get("_reload_timer"))
	)
	operator.set("_reload_active", false)


## The three advancers that Slice D wrongly exempted as "presentation".
##
## Each was left on the render tick because its name said presentation, and each
## turned out to move state gameplay reads:
##
##   `_primary_ranged_action_timer` -> `_is_ranged_aim_ready()` -> whether you may fire
##   `AnimationStateMachine` state  -> `_is_movement_locked()`, weapon selection
##   melee posture draw grace       -> READY, and the Vigil ready-up bridge
##
## This is the case that fails if any of them goes back.
func _check_gameplay_bearing_advancers(operator: Node) -> void:
	# --- ranged action timer: it decides whether firing is allowed ---
	# "aiming" is the phase `_is_primary_ranged_aim_presentation_active()` keys on,
	# and the one `_is_ranged_aim_ready()` gates firing behind.
	operator.set("_primary_ranged_action_phase", &"aiming")
	operator.set("_primary_ranged_action_timer", 1.0)
	operator.set("_primary_ranged_action_total", 1.0)
	for _i in 10:
		operator.call("_process", 0.1)
		await process_frame
	_check(
		is_equal_approx(float(operator.get("_primary_ranged_action_timer")), 1.0),
		"ranged aim readiness advanced from the render tick: timer is %.4f. It "
			% float(operator.get("_primary_ranged_action_timer"))
			+ "feeds _is_ranged_aim_ready(), so this is whether you may fire."
	)
	operator.call("_advance_simulation", 0.25)
	await process_frame
	_check(
		float(operator.get("_primary_ranged_action_timer")) < 1.0,
		"ranged aim readiness did not advance on the fixed tick"
	)

	# --- animation state machine: its state gates movement locks ---
	var machine = operator.get("_animation_state_machine")
	_check(machine != null, "the state-machine case needs the live machine")
	if machine != null:
		var state_name: String = String(machine.current_state)
		if machine.states.has(state_name):
			var state = machine.states[state_name]
			state.elapsed = 0.0
			for _i in 10:
				operator.call("_process", 0.1)
				await process_frame
			var after_render: float = float(state.elapsed)
			_check(
				is_equal_approx(after_render, 0.0),
				"the animation state machine advanced from the render tick: "
					+ "elapsed is %.4f. Its state gates movement locks and weapon "
						% after_render
					+ "selection."
			)
			operator.call("_advance_simulation", 0.25)
			await process_frame
			var active_name: String = String(machine.current_state)
			var active = machine.states.get(active_name)
			_check(
				active != null and float(active.elapsed) > 0.0,
				"the animation state machine did not advance on the fixed tick"
			)

	# --- melee posture: draw grace decides the Vigil ready-up route ---
	var posture = operator.get("_melee_posture_state")
	_check(posture != null, "the posture case needs the live posture state")
	if posture != null:
		posture.draw_grace_remaining = 1.0
		for _i in 10:
			operator.call("_process", 0.1)
			await process_frame
		_check(
			is_equal_approx(float(posture.draw_grace_remaining), 1.0),
			"melee draw grace advanced from the render tick: %.4f. It decides "
				% float(posture.draw_grace_remaining)
				+ "whether the Vigil ready-up bridge runs before an attack."
		)
		operator.call("_advance_simulation", 0.25)
		await process_frame
		_check(
			float(posture.draw_grace_remaining) < 1.0,
			"melee draw grace did not advance on the fixed tick"
		)


## External control must be able to start an edge-triggered attack.
##
## `from_control_intent()` can only state what is held. If `adopt()` does not
## derive the edges, `pressed` works and `just_pressed` never fires -- so held
## ranged fire behaves while melee and the sidearm silently ignore injected
## control. That is the seam promising one path and delivering two.
func _check_injected_control_can_start_an_attack(operator: Node) -> void:
	operator.call("_apply_unarmed_selection")
	operator.set("stamina", 100.0)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	operator.call("_clear_attack_buffer")
	await process_frame

	# One quiet injected tick establishes the "not firing" baseline, exactly as a
	# real driver would before it decides to attack.
	operator.call("process_input", Vector2.ZERO, Vector2.RIGHT, false)
	operator.call("_sample_input_frame")
	_check(
		not bool(operator.get("_melee_active")),
		"the injected-control case must start from a non-attacking baseline"
	)

	operator.call("process_input", Vector2.ZERO, Vector2.RIGHT, true)
	operator.call("_sample_input_frame")
	var frame = operator.get("_input_frame")
	_check(
		frame != null and bool(frame.just_pressed_any(OperatorInputRouter.PRIMARY_ATTACK)),
		"an injected firing intent must arrive as a press edge, not only as held"
	)
	operator.call("_advance_simulation", 1.0 / 60.0)
	await process_frame
	_check(
		bool(operator.get("_melee_active")) or bool(operator.get("_melee_fast_windup")),
		"external control could not start a melee attack; the edge-triggered path "
			+ "is unreachable from process_input()"
	)
	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	operator.call("_clear_attack_buffer")
	await process_frame


## An injected attack must swing where the driver pointed.
##
## Starting the attack is only half the seam. `process_input()` documents
## `aim_vector` as a world-space aim direction, and before D.2 the router filed it
## as `keyboard_aim`, which `OperatorAimController` reads only while
## `arrow_aim_enabled` is true -- false by default on the Operator. So an AI, a
## vehicle or a replay could fire and would hit whatever direction the Operator
## already happened to face. The earlier case cannot see this because it injects
## the same direction the actor is already aiming.
func _check_injected_attack_uses_the_supplied_facing(operator: Node) -> void:
	operator.set("arrow_aim_enabled", false)
	operator.call("_apply_unarmed_selection")
	operator.set("stamina", 100.0)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	operator.call("_clear_attack_buffer")
	await process_frame

	# The driver points the other way from the aim that already exists.
	operator.call("process_input", Vector2.ZERO, Vector2.UP, false)
	operator.call("_sample_input_frame")
	operator.call("_advance_simulation", 1.0 / 60.0)
	await process_frame
	var aim: Vector2 = operator.get("aim_direction")
	_check(
		aim.is_equal_approx(Vector2.UP),
		"the supplied aim vector did not reach aim_direction: it is %s, not UP. "
			% aim
			+ "external control can press buttons but cannot steer."
	)

	operator.call("process_input", Vector2.ZERO, Vector2.UP, true)
	operator.call("_sample_input_frame")
	var attack_aim: Vector2 = operator.call("_get_attack_aim_direction")
	_check(
		attack_aim.is_equal_approx(Vector2.UP),
		"an injected attack used %s instead of the supplied facing UP" % attack_aim
	)
	operator.call("_advance_simulation", 1.0 / 60.0)
	await process_frame
	_check(
		bool(operator.get("_melee_active")) or bool(operator.get("_melee_fast_windup")),
		"the injected attack must still start, or the facing assertion proves nothing"
	)
	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	operator.call("_clear_attack_buffer")
	await process_frame
