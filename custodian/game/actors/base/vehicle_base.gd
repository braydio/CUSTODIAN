extends ControllableActor
class_name VehicleBase
## Base class for all vehicles.
## Extends ControllableActor for unified control with Operator.
##
## Usage:
##   extends VehicleBase
##   func _ready():
##       setup_vehicle()

# Vehicle properties
@export var max_speed: float = 300.0
@export var acceleration: float = 0.0  # 0 = instant (v1 default)
@export var friction: float = 0.0     # 0 = instant stop (v1 default)

# Health system
@export var vehicle_health: float = 100.0
@export var vehicle_max_health: float = 100.0

# Weapon integration
var weapon: Node = null
@export var weapon_scene: PackedScene = null

# Occupancy
var is_occupied: bool = false
var occupant: Node = null  # Reference to Operator when occupied

# State
var is_destroyed: bool = false
var destruction_effect_scene: PackedScene = null

# Interaction
@export var interaction_prompt: String = "Press E to enter"
@export var interaction_range: float = 64.0

# Forward-only fire (v1 constraint)
@export var forward_fire_only: bool = true


func _ready() -> void:
	_setup_vehicle()


func _setup_vehicle() -> void:
	# Override health from export
	current_health = vehicle_health
	max_health = vehicle_max_health
	
	# Add to groups for interaction system
	add_to_group("vehicle")
	add_to_group("interactable")
	
	# Setup weapon if configured
	if weapon_scene:
		weapon = weapon_scene.instantiate()
		if weapon and has_node("WeaponSocket"):
			$WeaponSocket.add_child(weapon)


## Process input - direct velocity mapping (v1, no physics)
func process_input(input_vector: Vector2, aim_vector: Vector2, is_firing: bool) -> void:
	if is_destroyed or not is_occupied:
		return
	
	# Apply movement (direct velocity for v1)
	velocity = input_vector * max_speed
	move_and_slide()
	
	# Fire weapon if triggered
	if is_firing and weapon:
		_fire_weapon(aim_vector)


## Fire weapon in aim direction.
## For v1: forward-only if configured.
func _fire_weapon(aim_direction: Vector2) -> void:
	if not weapon or not weapon.has_method("fire"):
		return
	
	var fire_direction: Vector2
	if forward_fire_only:
		# Always fire in vehicle's facing direction
		fire_direction = transform.x
	else:
		fire_direction = aim_direction
	
	weapon.fire(global_position, fire_direction)


## Take damage and check for destruction.
func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	if current_health <= 0 and not is_destroyed:
		destroy()


## Destroy the vehicle.
func destroy() -> void:
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Spawn destruction effects
	if destruction_effect_scene:
		var effect = destruction_effect_scene.instantiate()
		effect.global_position = global_position
		get_parent().add_child(effect)
	
	# Handle occupant if present
	if is_occupied and occupant:
		# Signal player controller to handle exit
		# (handled by player controller checking vehicle state)
		pass
	
	# Remove from scene
	queue_free()


## Check if can be entered.
func can_be_entered() -> bool:
	return not is_destroyed and not is_occupied


## Enter the vehicle as operator.
func enter(operator: Node) -> void:
	if not can_be_entered():
		return
	
	is_occupied = true
	occupant = operator


## Exit the vehicle.
func exit() -> Vector2:
	if not is_occupied:
		return global_position
	
	var exit_position = global_position
	is_occupied = false
	occupant = null
	return exit_position


## Get display name for UI.
override func get_display_name() -> String:
	return "Vehicle"


## Override can_be_controlled to check occupancy.
override func can_be_controlled() -> bool:
	return super.can_be_controlled() and is_occupied


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event: InputEventKey = event
			var key_text := key_event.as_text_key_label().strip_edges().to_upper()
			if not key_text.is_empty():
				return key_text
	return "INTERACT"


## Get interaction prompt for UI.
func get_interaction_prompt() -> String:
	if is_occupied:
		return "PRESS %s TO EXIT" % _get_interact_prompt_key()
	if is_destroyed:
		return "Destroyed"
	return interaction_prompt
