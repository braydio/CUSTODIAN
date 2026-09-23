class_name OperatorInputFrame
extends RefCounted
## One simulation tick's player intent, frozen.
##
## The Operator reads this instead of asking `Input` directly, which is what lets
## a replay, an AI, a possession system or a vehicle supply intent without
## pretending to be a global keyboard. A frame is built once per fixed tick and
## never mutated afterwards: there are no "consumed" flags for gameplay systems to
## clear, because a frame that has been superseded is simply replaced.
##
## Edges are properties of the frame, not of the global input state. `just_pressed`
## is true on exactly the one fixed tick that observed the press, however many
## render frames happened either side of it.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

var move: Vector2 = Vector2.ZERO
var controller_aim: Vector2 = Vector2.ZERO
var keyboard_aim: Vector2 = Vector2.ZERO
var gamepad_active: bool = false
## Whether the pointer actually moved since the previous frame. A mouse position
## exists at all times; movement is what makes the mouse an *active* aim source.
var mouse_moved: bool = false

var _pressed: Dictionary = {}
var _just_pressed: Dictionary = {}
var _just_released: Dictionary = {}


static func build(
	pressed: Dictionary,
	just_pressed: Dictionary,
	just_released: Dictionary,
	move_vector: Vector2,
	controller_aim_vector: Vector2,
	keyboard_aim_vector: Vector2,
	is_gamepad_active: bool,
	pointer_moved: bool
) -> OperatorInputFrame:
	var frame := OperatorInputFrame.new()
	frame._pressed = pressed
	frame._just_pressed = just_pressed
	frame._just_released = just_released
	frame.move = move_vector
	frame.controller_aim = controller_aim_vector
	frame.keyboard_aim = keyboard_aim_vector
	frame.gamepad_active = is_gamepad_active
	frame.mouse_moved = pointer_moved
	return frame


## An empty frame: no buttons, no movement, no aim.
##
## This is what an actor under no control reads, and it is deliberately a real
## frame rather than null so callers never branch on its absence.
static func neutral() -> OperatorInputFrame:
	return OperatorInputFrame.build({}, {}, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, false, false)


func pressed(action: StringName) -> bool:
	return bool(_pressed.get(action, false))


func just_pressed(action: StringName) -> bool:
	return bool(_just_pressed.get(action, false))


func just_released(action: StringName) -> bool:
	return bool(_just_released.get(action, false))


## The Operator binds several historical names to one intent -- `fire_primary`,
## `attack_primary`, `attack` and `melee_attack` are all "hit it". These answer
## for the whole set so callers do not re-spell the alias list at each site.
func pressed_any(actions: Array) -> bool:
	for action: Variant in actions:
		if pressed(StringName(str(action))):
			return true
	return false


func just_pressed_any(actions: Array) -> bool:
	for action: Variant in actions:
		if just_pressed(StringName(str(action))):
			return true
	return false


func just_released_any(actions: Array) -> bool:
	for action: Variant in actions:
		if just_released(StringName(str(action))):
			return true
	return false


## True when the player asked for anything at all this tick. Used by idle/AFK
## style checks that previously spelled out a long `or` chain of raw reads.
func has_any_activity() -> bool:
	if move.length_squared() > 0.0001 or controller_aim.length_squared() > 0.0001:
		return true
	for value: Variant in _pressed.values():
		if bool(value):
			return true
	return false
