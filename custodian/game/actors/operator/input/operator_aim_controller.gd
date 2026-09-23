class_name OperatorAimController
extends RefCounted
## Which direction the player's input means, and which source gets to say so.
##
## This owns the retained controller direction, which is the part that used to
## live in `operator.gd` as `_last_controller_aim_direction`. The retention rule
## is the whole reason this is a state machine rather than a function: a stick
## that returns to neutral is not a request to aim nowhere, and it is not a
## request to hand aim back to the mouse either. It is the player holding still.
##
## Source priority, highest first:
##
##     gamepad active   -> retained controller direction
##     arrow aim mode   -> keyboard axes while nonzero
##     otherwise        -> mouse, and only while the mouse is a live source
##
## The mouse cannot steal aim from an active gamepad, because a mouse position
## exists whether or not anyone is touching the mouse. Actual pointer movement is
## what hands ownership back.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

enum Source { NONE, GAMEPAD, KEYBOARD, MOUSE }

var last_controller_aim: Vector2 = Vector2.ZERO
var source: Source = Source.NONE


## Resolve aim for one tick.
##
## Returns `aim`, and `facing` plus `facing_changed` for the sources that also
## own the body's resting direction. The mouse deliberately does not turn the
## idle facing, which is the behaviour the actor already had.
func resolve(
	frame: OperatorInputFrame,
	arrow_aim_enabled: bool,
	movement_direction: Vector2,
	visual_idle_direction: Vector2,
	current_aim: Vector2,
	mouse_vector: Vector2
) -> Dictionary:
	if frame.gamepad_active:
		source = Source.GAMEPAD
		if frame.controller_aim != Vector2.ZERO:
			last_controller_aim = frame.controller_aim
		if last_controller_aim == Vector2.ZERO:
			# First gamepad use with nothing retained: borrow the body's own
			# direction rather than snapping to an arbitrary axis.
			last_controller_aim = (
				movement_direction.normalized()
				if movement_direction.length_squared() > 0.0001
				else visual_idle_direction.normalized()
			)
		if last_controller_aim == Vector2.ZERO:
			last_controller_aim = Vector2.RIGHT
		return {
			"aim": last_controller_aim,
			"facing": last_controller_aim,
			"facing_changed": true,
		}

	if arrow_aim_enabled:
		if frame.keyboard_aim != Vector2.ZERO:
			source = Source.KEYBOARD
			return {
				"aim": frame.keyboard_aim,
				"facing": frame.keyboard_aim,
				"facing_changed": true,
			}
		return {"aim": current_aim, "facing": visual_idle_direction, "facing_changed": false}

	if mouse_vector.length_squared() > 0.0001:
		source = Source.MOUSE
		return {
			"aim": mouse_vector.normalized(),
			"facing": visual_idle_direction,
			"facing_changed": false,
		}
	return {"aim": current_aim, "facing": visual_idle_direction, "facing_changed": false}


## Forget the retained controller direction, for a possession or loadout change
## that should not inherit the previous controller's stick.
func reset() -> void:
	last_controller_aim = Vector2.ZERO
	source = Source.NONE
