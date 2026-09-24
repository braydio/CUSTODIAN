class_name OperatorInputRouter
extends RefCounted
## The only place Operator code samples raw player input.
##
## It answers exactly one question -- "what did the player do this tick?" -- and
## deliberately no others. Whether an action is *legal* right now belongs to the
## gameplay authorities; whether a direction means something belongs to
## `OperatorAimController`. Keeping those apart is what makes the same downstream
## path usable by a replay or an AI, which have intent but no keyboard.
##
## Sampling happens once per fixed tick. Before this existed the actor read
## `Input` from the render tick, so an edge could be observed twice when two
## render frames fell inside one physics tick, or missed when none did.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

## Every action the Operator actually consumes, inventoried from its call sites
## rather than from a design list. Actions absent from the project's InputMap are
## skipped rather than warned about: several are optional bindings.
const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"aim_left", &"aim_right", &"aim_up", &"aim_down",
	&"fire_primary", &"attack_primary", &"attack", &"melee_attack",
	&"attack_secondary", &"aim_hold", &"heavy_attack",
	&"dodge", &"block", &"sprint", &"sneak",
	&"reload_weapon", &"reload",
	&"interact", &"build", &"repair",
	&"field_patch", &"field_patch_interrupt", &"use_field_patch",
	&"toggle_unarmed", &"cycle_next_weapon", &"cycle_prev_weapon",
	&"toggle_aim_input_mode",
	&"drone_issue_guard_order",
]

## Alias sets, so callers ask for an intent instead of re-spelling history.
const PRIMARY_ATTACK := [&"fire_primary", &"attack_primary", &"attack", &"melee_attack"]
const SECONDARY_HOLD := [&"aim_hold", &"attack_secondary"]
const SECONDARY_PRESS := [&"aim_hold", &"attack_secondary", &"heavy_attack"]
const RELOAD := [&"reload_weapon", &"reload"]

var _available: Array[StringName] = []
var _previous_pressed: Dictionary = {}
var _last_mouse_position: Vector2 = Vector2.ZERO
var _has_mouse_sample: bool = false


func _init() -> void:
	for action: StringName in ACTIONS:
		if InputMap.has_action(action):
			_available.append(action)


## Sample one fixed tick.
##
## Edges come from Godot's own physics-relative `just_pressed`/`just_released`,
## which is correct when called from `_physics_process`, OR'd with a comparison
## against the previous sampled tick. The OR is not belt and braces: the engine
## answer alone loses an edge if a tick is skipped entirely, and the comparison
## alone loses a press that begins and ends between two ticks. Both are "since the
## last physics frame", so combining them cannot report an edge twice.
func sample(
	gamepad_active: bool,
	controller_deadzone: float,
	mouse_position: Vector2
) -> OperatorInputFrame:
	var pressed: Dictionary = {}
	var just_pressed: Dictionary = {}
	var just_released: Dictionary = {}
	for action: StringName in _available:
		var is_down := Input.is_action_pressed(action)
		var was_down := bool(_previous_pressed.get(action, false))
		pressed[action] = is_down
		if Input.is_action_just_pressed(action) or (is_down and not was_down):
			just_pressed[action] = true
		if Input.is_action_just_released(action) or (was_down and not is_down):
			just_released[action] = true
	_previous_pressed = pressed.duplicate()

	var pointer_moved := false
	if _has_mouse_sample:
		pointer_moved = _last_mouse_position.distance_squared_to(mouse_position) > 0.01
	_last_mouse_position = mouse_position
	_has_mouse_sample = true

	return OperatorInputFrame.build(
		pressed,
		just_pressed,
		just_released,
		_read_move_vector(),
		_read_controller_aim(controller_deadzone),
		_read_keyboard_aim(),
		gamepad_active,
		pointer_moved
	)


## Adopt an externally supplied frame -- replay, AI, possession, a vehicle.
##
## The external source states what is *held*; it does not know when it started
## holding it. The router derives the edges the same way it does for a keyboard,
## by comparing against the previously sampled tick, and returns a frame carrying
## them. Without this an injected frame has `pressed` but never `just_pressed`,
## and every edge-triggered action -- melee, the sidearm -- silently ignores it
## while held-fire ranged happens to work. That is two behaviours from one seam,
## which is the thing this seam exists to prevent.
##
## Comparing against the previous tick also means handing control back and forth
## cannot manufacture a spurious edge from stale state.
func adopt(frame: OperatorInputFrame) -> OperatorInputFrame:
	var pressed: Dictionary = {}
	var just_pressed: Dictionary = {}
	var just_released: Dictionary = {}
	for action: StringName in _available:
		var is_down := frame.pressed(action)
		var was_down := bool(_previous_pressed.get(action, false))
		pressed[action] = is_down
		if is_down and not was_down:
			just_pressed[action] = true
		if was_down and not is_down:
			just_released[action] = true
	_previous_pressed = pressed.duplicate()
	return OperatorInputFrame.build(
		pressed,
		just_pressed,
		just_released,
		frame.move,
		frame.controller_aim,
		frame.keyboard_aim,
		frame.gamepad_active,
		frame.mouse_moved
	)


## Build a frame from an external intent triple, as `ControllableActor` supplies.
static func from_control_intent(
	input_vector: Vector2,
	aim_vector: Vector2,
	is_firing: bool
) -> OperatorInputFrame:
	var pressed: Dictionary = {}
	if is_firing:
		for action: StringName in PRIMARY_ATTACK:
			pressed[action] = true
	return OperatorInputFrame.build(
		pressed,
		{},
		{},
		input_vector.limit_length(1.0),
		Vector2.ZERO,
		aim_vector.normalized() if aim_vector.length_squared() > 0.0001 else Vector2.ZERO,
		false,
		false
	)


## Debug hotkeys are still player state, so they are sampled here rather than
## giving `operator.gd` a second reason to talk to `Input` directly.
static func debug_key_pressed(keycode: int) -> bool:
	return Input.is_key_pressed(keycode)


func _read_move_vector() -> Vector2:
	if not InputMap.has_action(&"move_right"):
		return Vector2.ZERO
	var move_input := Vector2(
		Input.get_action_strength(&"move_right") - Input.get_action_strength(&"move_left"),
		Input.get_action_strength(&"move_down") - Input.get_action_strength(&"move_up")
	)
	if move_input.length_squared() <= 0.0001:
		return Vector2.ZERO
	if move_input.length() > 1.0:
		return move_input.normalized()
	return move_input


func _read_aim_axes() -> Vector2:
	if not InputMap.has_action(&"aim_right"):
		return Vector2.ZERO
	return Vector2(
		Input.get_action_strength(&"aim_right") - Input.get_action_strength(&"aim_left"),
		Input.get_action_strength(&"aim_down") - Input.get_action_strength(&"aim_up")
	)


## Stick noise below the deadzone is not an aim request, and must not be able to
## take aim away from the retained controller direction.
func _read_controller_aim(controller_deadzone: float) -> Vector2:
	var aim_input := _read_aim_axes()
	if aim_input.length() < controller_deadzone:
		return Vector2.ZERO
	return aim_input.normalized()


func _read_keyboard_aim() -> Vector2:
	var aim_input := _read_aim_axes()
	if aim_input.length_squared() <= 0.0001:
		return Vector2.ZERO
	return aim_input.normalized()
