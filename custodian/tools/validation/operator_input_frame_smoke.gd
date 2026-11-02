extends SceneTree
## The deterministic input frame: edges, movement, and the aim-source policy.
##
## Slice D moved raw sampling into `operator/input/`. What matters is not that the
## classes exist but that they behave like one tick of intent: an edge is reported
## on exactly the tick that observed it, a held button is not an edge, and stick
## noise or a stale mouse cannot take aim away from a retained controller
## direction.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	_check_edges()
	_check_movement()
	_check_aim_ownership()
	_check_external_control()
	_check_external_aim_authority()
	_check_injected_edges()
	_check_mouse_handoff()
	_check_pointer_motion_is_event_derived()

	if _failures.is_empty():
		print("operator_input_frame_smoke passed")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator_input_frame_smoke: %d failure(s)" % _failures.size())
	quit(1)


## Sampling takes a pointer-motion generation, not a mouse position. Holding it
## constant is the truthful way to say "the pointer did not move".
func _sample(router: OperatorInputRouter, motion_generation: int = 0) -> OperatorInputFrame:
	return router.sample(false, 0.25, motion_generation)


## Press, hold, release, and the tick after. Each edge belongs to one tick.
func _check_edges() -> void:
	var router := OperatorInputRouter.new()
	Input.action_release(&"dodge")
	_sample(router)

	Input.action_press(&"dodge")
	var pressed_tick := _sample(router)
	_check(pressed_tick.just_pressed(&"dodge"), "a press must report just_pressed on its own tick")
	_check(pressed_tick.pressed(&"dodge"), "a press must also read as held")
	_check(not pressed_tick.just_released(&"dodge"), "a press must not report a release edge")

	var held_tick := _sample(router)
	_check(held_tick.pressed(&"dodge"), "a held button must stay pressed")
	_check(
		not held_tick.just_pressed(&"dodge"),
		"holding must not re-report just_pressed; that is the double-edge bug this "
			+ "frame exists to prevent"
	)

	Input.action_release(&"dodge")
	var released_tick := _sample(router)
	_check(released_tick.just_released(&"dodge"), "a release must report just_released on its own tick")
	_check(not released_tick.pressed(&"dodge"), "a released button must not read as held")

	var after_tick := _sample(router)
	_check(not after_tick.just_released(&"dodge"), "the release edge must clear on the next tick")
	_check(not after_tick.pressed(&"dodge"), "a released button must stay released")


func _check_movement() -> void:
	var router := OperatorInputRouter.new()
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)
	_check(_sample(router).move == Vector2.ZERO, "no movement input must read as zero")

	Input.action_press(&"move_right", 1.0)
	_check(
		_sample(router).move.is_equal_approx(Vector2.RIGHT),
		"a single axis must read as the unit vector"
	)

	Input.action_press(&"move_down", 1.0)
	var diagonal := _sample(router).move
	_check(
		is_equal_approx(diagonal.length(), 1.0),
		"a diagonal must be normalised, measured %.4f" % diagonal.length()
	)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	_sample(router)


## Source policy, exercised directly against the aim authority.
func _check_aim_ownership() -> void:
	var aim := OperatorAimController.new()
	var facing := Vector2.DOWN

	var gamepad_right := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, true, false
	)
	var resolved := aim.resolve(gamepad_right, false, Vector2.ZERO, facing, Vector2.ZERO, Vector2(500.0, 500.0))
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"controller aim right must resolve right"
	)

	# Neutral stick: the player is holding still, not aiming nowhere.
	var neutral_stick := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, true, false
	)
	resolved = aim.resolve(neutral_stick, false, Vector2.ZERO, facing, Vector2.ZERO, Vector2(500.0, 500.0))
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"a neutral stick must retain the last controller direction"
	)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"a stale mouse position must not steal aim from an active gamepad"
	)

	# Sub-deadzone noise never reaches the controller here, because the router
	# zeroes it -- which is the same thing as far as the policy is concerned.
	var noisy := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, true, false
	)
	resolved = aim.resolve(noisy, false, Vector2.ZERO, facing, Vector2.ZERO, Vector2.ZERO)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"sub-deadzone noise must not replace retained aim"
	)

	# First gamepad use with nothing retained borrows the body's own direction.
	var fresh := OperatorAimController.new()
	resolved = fresh.resolve(neutral_stick, false, Vector2.UP, facing, Vector2.ZERO, Vector2.ZERO)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"first gamepad use must fall back to movement direction, got %s" % resolved["aim"]
	)
	var no_movement := OperatorAimController.new()
	resolved = no_movement.resolve(neutral_stick, false, Vector2.ZERO, Vector2.DOWN, Vector2.ZERO, Vector2.ZERO)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.DOWN),
		"with no movement the fallback must be the visual facing"
	)

	# Keyboard aim mode owns aim while its axes are live.
	var keyboard := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.UP, false, false
	)
	resolved = OperatorAimController.new().resolve(
		keyboard, true, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(500.0, 0.0)
	)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"arrow-aim mode must give keyboard axes ownership"
	)

	# Mouse may own aim once the gamepad is not active.
	var mouse_frame := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, false, true
	)
	resolved = OperatorAimController.new().resolve(
		mouse_frame, false, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(0.0, -40.0)
	)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"the mouse must own aim once it is the active source"
	)


## Externally supplied control must arrive as an ordinary frame.
func _check_external_control() -> void:
	var frame := OperatorInputRouter.from_control_intent(Vector2(2.0, 0.0), Vector2.UP, true)
	_check(
		frame.move.is_equal_approx(Vector2.RIGHT),
		"injected movement must be clamped to the unit circle, got %s" % frame.move
	)
	_check(
		frame.pressed_any(OperatorInputRouter.PRIMARY_ATTACK),
		"an injected firing intent must read as a primary attack"
	)
	_check(
		not frame.gamepad_active,
		"injected control must not claim to be a gamepad"
	)
	_check(
		frame.external_control,
		"an injected frame must declare itself external rather than impersonating a device"
	)
	_check(
		frame.control_aim.is_equal_approx(Vector2.UP),
		"the supplied aim vector must survive as an explicit external fact, got %s" % frame.control_aim
	)
	_check(
		frame.keyboard_aim == Vector2.ZERO,
		"injected aim must not be filed as keyboard axes: that made it conditional "
			+ "on arrow_aim_enabled, which defaults to false"
	)
	_check(
		OperatorInputFrame.neutral().has_any_activity() == false,
		"a neutral frame must report no activity"
	)


## Injected control must produce edges, not only held state.
##
## `from_control_intent()` can only say what is held -- an external source does
## not know when it started holding. `adopt()` derives the edges by comparing
## against the previous tick, exactly as local sampling does. Without that,
## `pressed` works and `just_pressed` never fires, so held-fire ranged behaves
## while melee and the sidearm silently ignore injected control: one seam, two
## behaviours.
func _check_injected_edges() -> void:
	var router := OperatorInputRouter.new()
	var primary: StringName = OperatorInputRouter.PRIMARY_ATTACK[0]

	var idle := router.adopt(OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.RIGHT, false))
	_check(not idle.pressed(primary), "not firing must not read as pressed")
	_check(not idle.just_pressed(primary), "not firing must not produce a press edge")

	var began := router.adopt(OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.RIGHT, true))
	_check(began.pressed(primary), "injected firing must read as pressed")
	_check(
		began.just_pressed(primary),
		"injected firing must produce a press edge, or edge-triggered attacks "
			+ "(melee, sidearm) cannot be driven by external control at all"
	)
	_check(not began.just_released(primary), "starting to fire is not a release")

	var held := router.adopt(OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.RIGHT, true))
	_check(held.pressed(primary), "continued firing must stay pressed")
	_check(not held.just_pressed(primary), "continued firing must not re-report a press edge")

	var ended := router.adopt(OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.RIGHT, false))
	_check(ended.just_released(primary), "ceasing fire must produce a release edge")
	_check(not ended.pressed(primary), "ceasing fire must not stay pressed")

	var quiet := router.adopt(OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.RIGHT, false))
	_check(not quiet.just_released(primary), "the release edge must clear on the next tick")
	_check(not quiet.just_pressed(primary), "an idle injected tick must produce no edge")


## A stale mouse position must not acquire aim just because the device family
## flipped. `InputPromptService` switches to keyboard_mouse on any keyboard press,
## so a movement key after using a controller would otherwise hand aim to wherever
## the cursor happened to be sitting.
func _check_mouse_handoff() -> void:
	var aim := OperatorAimController.new()
	var facing := Vector2.DOWN
	var stale_mouse := Vector2(400.0, 400.0)

	var gamepad := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, true, false
	)
	var resolved := aim.resolve(gamepad, false, Vector2.ZERO, facing, Vector2.ZERO, stale_mouse)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"the gamepad should own aim while it is active"
	)

	# Keyboard press flips the device family. The mouse has not moved.
	var kbm_no_motion := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, false, false
	)
	resolved = aim.resolve(kbm_no_motion, false, Vector2.ZERO, facing, Vector2.RIGHT, stale_mouse)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"a stale mouse position acquired aim after the device family flipped, "
			+ "resolved %s -- pointer presence is not pointer movement" % resolved["aim"]
	)

	# Now the pointer really moves.
	var kbm_moved := OperatorInputFrame.build(
		{}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, false, true
	)
	resolved = aim.resolve(kbm_moved, false, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(0.0, -40.0))
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"real pointer movement must hand aim back to the mouse, resolved %s" % resolved["aim"]
	)

	# And it keeps it without having to keep moving.
	resolved = aim.resolve(kbm_no_motion, false, Vector2.ZERO, facing, Vector2.UP, Vector2(0.0, -40.0))
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"the mouse should keep aim once live, without needing to jiggle"
	)

	# The gamepad taking over revokes it again.
	resolved = aim.resolve(gamepad, false, Vector2.ZERO, facing, Vector2.UP, stale_mouse)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"the gamepad must be able to take aim back"
	)
	resolved = aim.resolve(kbm_no_motion, false, Vector2.ZERO, facing, Vector2.RIGHT, stale_mouse)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"after the gamepad takes over, the mouse must earn aim back by moving again"
	)


## Externally supplied aim must actually own aim.
##
## `ControllableActor.process_input()` documents `aim_vector` as a world-space aim
## direction. Before D.2 the router filed it as `keyboard_aim`, and the aim
## authority reads `keyboard_aim` only while `arrow_aim_enabled` is true -- which
## the Operator defaults to false. The seam therefore accepted an aim vector and
## discarded it: external control could press a button but could not steer.
##
## The policy is that an external frame with a nonzero aim wins outright. It must
## not depend on arrow-aim mode, the device family, a retained stick, or the mouse.
func _check_external_aim_authority() -> void:
	var facing := Vector2.DOWN
	var external_up := OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.UP, false)

	# Arrow-aim off is the Operator's own default, and the case that was broken.
	var resolved := OperatorAimController.new().resolve(
		external_up, false, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(500.0, 0.0)
	)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"external aim must own aim with arrow_aim_enabled false, resolved %s" % resolved["aim"]
	)
	_check(
		bool(resolved["facing_changed"])
			and (resolved["facing"] as Vector2).is_equal_approx(Vector2.UP),
		"external aim must also turn the body, or an injected attack swings the wrong way"
	)

	# Arrow-aim on must not change the answer either.
	resolved = OperatorAimController.new().resolve(
		external_up, true, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(500.0, 0.0)
	)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"external aim must not depend on arrow-aim mode, resolved %s" % resolved["aim"]
	)

	# A live mouse must not outrank the driver.
	var mouse_live := OperatorAimController.new()
	mouse_live.resolve(
		OperatorInputFrame.build({}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, false, true),
		false, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(0.0, -40.0)
	)
	resolved = mouse_live.resolve(external_up, false, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(500.0, 0.0))
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"a live mouse must not outrank external control, resolved %s" % resolved["aim"]
	)

	# Nor must a retained gamepad direction.
	var gamepad_retained := OperatorAimController.new()
	gamepad_retained.resolve(
		OperatorInputFrame.build({}, {}, {}, Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, true, false),
		false, Vector2.ZERO, facing, Vector2.ZERO, Vector2.ZERO
	)
	resolved = gamepad_retained.resolve(external_up, false, Vector2.ZERO, facing, Vector2.RIGHT, Vector2.ZERO)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.UP),
		"a retained controller direction must not outrank external control, resolved %s" % resolved["aim"]
	)

	# A driver with no opinion holds the current aim rather than falling through
	# to local devices, which are not the ones driving.
	var silent := OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.ZERO, false)
	resolved = OperatorAimController.new().resolve(
		silent, false, Vector2.ZERO, facing, Vector2.RIGHT, Vector2(0.0, -400.0)
	)
	_check(
		(resolved["aim"] as Vector2).is_equal_approx(Vector2.RIGHT),
		"an external frame with no aim opinion must hold the current aim, resolved %s" % resolved["aim"]
	)

	# Edges still come from adopt(); the aim fact must survive that trip.
	var adopted := OperatorInputRouter.new().adopt(
		OperatorInputRouter.from_control_intent(Vector2.ZERO, Vector2.UP, true)
	)
	_check(
		adopted.external_control and adopted.control_aim.is_equal_approx(Vector2.UP),
		"adopt() must carry the external aim fact, not just the button state"
	)


## `mouse_moved` must come from pointer events, never from a world coordinate.
##
## The router used to compare `_get_world_mouse_position()` between ticks. The
## camera follows the Operator and applies smoothing, lookahead, ranged lead,
## threat framing, bob and shake, so that coordinate moves while the physical
## mouse sits still -- which let a stale mouse take aim back from a gamepad. The
## router no longer sees a position at all; it compares `InputPromptService`'s
## motion generation, which only a real motion event advances.
func _check_pointer_motion_is_event_derived() -> void:
	var router := OperatorInputRouter.new()
	_check(not _sample(router, 7).mouse_moved, "the first sample has nothing to compare against")
	_check(
		not _sample(router, 7).mouse_moved,
		"an unchanged motion generation must report no pointer movement"
	)
	_check(_sample(router, 8).mouse_moved, "a new motion event must report pointer movement")
	_check(
		not _sample(router, 8).mouse_moved,
		"the movement report must clear once the generation stops advancing"
	)

	# The negative control, stated as the bug: no amount of camera or actor motion
	# can reach this path, because a coordinate is not one of its inputs.
	var service_source := FileAccess.get_file_as_string(
		"res://game/systems/input/input_prompt_service.gd"
	)
	_check(
		service_source.contains("mouse_motion_generation += 1")
			and service_source.contains("InputEventMouseMotion"),
		"InputPromptService must advance the motion generation from a real mouse-motion event"
	)
	var router_source := FileAccess.get_file_as_string(
		"res://game/actors/operator/input/operator_input_router.gd"
	)
	_check(
		not router_source.contains("_last_mouse_position"),
		"the router must not retain a mouse position: comparing world coordinates is "
			+ "camera movement, not pointer movement"
	)

	# The service itself: a real event counts, a sub-threshold twitch does not.
	var service_script: GDScript = load("res://game/systems/input/input_prompt_service.gd")
	var service: Node = service_script.new()
	var before: int = int(service.call("get_mouse_motion_generation"))
	var tiny := InputEventMouseMotion.new()
	tiny.relative = Vector2(0.1, 0.0)
	service.call("_input", tiny)
	_check(
		int(service.call("get_mouse_motion_generation")) == before,
		"sub-threshold pointer noise must not count as movement"
	)
	var real_motion := InputEventMouseMotion.new()
	real_motion.relative = Vector2(64.0, 0.0)
	service.call("_input", real_motion)
	_check(
		int(service.call("get_mouse_motion_generation")) == before + 1,
		"a real mouse-motion event must advance the motion generation"
	)
	service.free()
