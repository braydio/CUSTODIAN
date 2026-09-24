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
##     external control -> the driver's supplied direction
##     gamepad active   -> retained controller direction
##     arrow aim mode   -> keyboard axes while nonzero
##     otherwise        -> mouse, and only while the mouse is a live source
##
## External control outranks every local source and is conditional on none of
## them: a driver that supplies an aim vector gets that aim whatever
## `arrow_aim_enabled`, the device family, the retained stick or the mouse happen
## to say. Anything less means the seam accepts a direction and may ignore it,
## which is worse than not accepting one.
##
## The mouse cannot steal aim from an active gamepad, because a mouse position
## exists whether or not anyone is touching the mouse. Actual pointer movement is
## what hands ownership back.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

enum Source { NONE, GAMEPAD, KEYBOARD, MOUSE, EXTERNAL }

var last_controller_aim: Vector2 = Vector2.ZERO
var source: Source = Source.NONE
## Whether the pointer has moved since the gamepad last held aim.
##
## A mouse position exists at all times, and `InputPromptService` switches the
## device family to keyboard_mouse on *any* keyboard press -- a movement key, not
## just the mouse. Without this latch, tapping W after using a controller would
## hand aim to wherever the cursor happened to be sitting. The latch stays set
## once the pointer really moves, so the player does not have to keep jiggling the
## mouse to keep aiming with it.
var _mouse_is_live: bool = false


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
	if frame.mouse_moved:
		_mouse_is_live = true

	if frame.external_control:
		if frame.control_aim.length_squared() > 0.0001:
			source = Source.EXTERNAL
			# The driver owns aim, so the mouse must earn it back by moving, the
			# same rule the gamepad gets. Otherwise handing control back would
			# snap aim to wherever the cursor was parked during the possession.
			_mouse_is_live = false
			var control_aim := frame.control_aim.normalized()
			return {
				"aim": control_aim,
				"facing": control_aim,
				"facing_changed": true,
			}
		# A driver with no opinion about aim holds the current direction rather
		# than falling through to local devices, which are not driving.
		return {"aim": current_aim, "facing": visual_idle_direction, "facing_changed": false}

	if frame.gamepad_active:
		source = Source.GAMEPAD
		# The gamepad has aim; the mouse must earn it back by actually moving.
		_mouse_is_live = false
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

	if _mouse_is_live and mouse_vector.length_squared() > 0.0001:
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
	_mouse_is_live = false
