extends CharacterBody2D
class_name ControllableActor
## Shared interface for player operator and vehicles.
## Enables unified control handoff system.
##
## Both the Operator and VehicleBase classes should extend this interface
## to allow the PlayerController to route input seamlessly between them.
##
## Usage:
##   var current_actor: ControllableActor
##   current_actor.process_input(input_vector, aim_vector, is_firing)

# Base movement speed - override in subclasses
var move_speed: float = 150.0

# Current health - override in subclasses
var current_health: float = 100.0
var max_health: float = 100.0

# Aiming direction (world space)
var aim_direction: Vector2 = Vector2.RIGHT


## Process movement, aiming, and firing input.
## Called by PlayerController each frame.
## @param input_vector: Normalized direction from input (WASD)
## @param aim_vector: World-space direction for aiming
## @param is_firing: Whether fire button is held
func process_input(input_vector: Vector2, aim_vector: Vector2, is_firing: bool) -> void:
	# Override in subclass
	pass


## Return current health for HUD display.
func get_health() -> float:
	return current_health


## Return max health for HUD display.
func get_max_health() -> float:
	return max_health


## Check if actor is alive.
func is_alive() -> bool:
	return current_health > 0.0


## Take damage - override in subclass for custom behavior.
func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)


## Get display name for UI.
func get_display_name() -> String:
	return "Actor"


## Check if can be controlled (not stunned, dead, etc.).
func can_be_controlled() -> bool:
	return is_alive()
