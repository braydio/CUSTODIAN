extends Node
class_name PlayerController
## Routes input between operator and vehicles.
## Enables seamless enter/exit mechanics.
##
## Attach this as a child of the main game node or operator's parent.
## Requires reference to the operator node.

@export var operator_path: NodePath = @"../operator"
@export var camera_path: NodePath = @"../Camera2D"

var operator: Node = null
var current_vehicle: Node = null
var is_in_vehicle: bool = false


func _ready() -> void:
	# Get operator reference
	if operator_path:
		operator = get_node(operator_path)
	else:
		# Try default path
		operator = get_node_or_null("../Operator")
	
	if not operator:
		push_warning("PlayerController: Could not find operator node")


func _physics_process(delta: float) -> void:
	if not operator:
		return
	
	# Handle vehicle enter/exit input
	if Input.is_action_just_pressed("interact"):
		_handle_interaction()
	
	# Route input to current controller
	if is_in_vehicle and current_vehicle:
		_route_vehicle_input(delta)
	else:
		# Operator handles its own input natively
		pass  # Original operator._physics_process handles this


## Handle interaction (enter/exit vehicle).
func _handle_interaction() -> void:
	if is_in_vehicle and current_vehicle:
		exit_vehicle()
	else:
		try_enter_nearby_vehicle()


## Check for nearby vehicle and enter if possible.
func try_enter_nearby_vehicle() -> void:
	if not operator or is_in_vehicle:
		return
	
	var nearby = _find_nearby_vehicle()
	if nearby and nearby.can_be_entered():
		enter_vehicle(nearby)


## Enter the specified vehicle.
func enter_vehicle(vehicle: Node) -> void:
	if is_in_vehicle or not vehicle:
		return
	
	current_vehicle = vehicle
	is_in_vehicle = true
	
	# Hide operator
	if operator and operator.has_method("set_visible"):
		operator.set_visible(false)
	
	# Tell vehicle we've entered
	if vehicle.has_method("enter"):
		vehicle.enter(operator)
	
	print("Entered vehicle: ", vehicle.name)


## Exit the current vehicle.
func exit_vehicle() -> void:
	if not is_in_vehicle or not current_vehicle:
		return
	
	# Get exit position before exiting
	var exit_pos = Vector2.ZERO
	if current_vehicle.has_method("exit"):
		exit_pos = current_vehicle.exit()
	else:
		exit_pos = current_vehicle.global_position
	
	# Position operator at exit
	if operator:
		operator.global_position = exit_pos
		if operator.has_method("set_visible"):
			operator.set_visible(true)
	
	# Clear vehicle reference
	current_vehicle = null
	is_in_vehicle = false
	
	print("Exited vehicle")


## Route input to vehicle (called each frame when in vehicle).
func _route_vehicle_input(delta: float) -> void:
	if not current_vehicle or not current_vehicle.has_method("process_input"):
		return
	
	# Get input
	var input_dir = _get_movement_input()
	var aim_dir = _get_aim_input()
	var firing = Input.is_action_pressed("fire")
	
	# Send to vehicle
	current_vehicle.process_input(input_dir, aim_dir, firing)


## Find nearest vehicle within range.
func _find_nearby_vehicle() -> Node:
	if not operator:
		return null
	
	var range = 64.0  # Interaction range
	var nearest: Node = null
	var nearest_dist: float = range
	
	for node in get_tree().get_nodes_in_group("vehicle"):
		if not node.has_method("can_be_entered"):
			continue
		if not node.can_be_entered():
			continue
		
		var dist = operator.global_position.distance_to(node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node
	
	return nearest


## Get movement input vector.
func _get_movement_input() -> Vector2:
	var dir = Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return dir.normalized()


## Get aim direction (mouse position in world).
func _get_aim_input() -> Vector2:
	if not operator:
		return Vector2.RIGHT
	
	var mouse_pos = _get_world_mouse_position()
	return (mouse_pos - operator.global_position).normalized()


## Get mouse position in world coordinates.
func _get_world_mouse_position() -> Vector2:
	var camera = _get_camera()
	if camera:
		return camera.get_global_mouse_position()
	return get_global_mouse_position()


## Get camera node.
func _get_camera():
	if camera_path:
		return get_node(camera_path)
	return get_node_or_null("../Camera2D")


## Check if currently in vehicle.
func is_vehicle_mode() -> bool:
	return is_in_vehicle


## Get current vehicle for HUD.
func get_current_vehicle() -> Node:
	return current_vehicle


## Handle vehicle destruction while occupied.
func on_vehicle_destroyed() -> void:
	if is_in_vehicle and current_vehicle:
		# Exit at current position
		if operator:
			if operator.has_method("set_visible"):
				operator.set_visible(true)
		current_vehicle = null
		is_in_vehicle = false
		print("Vehicle destroyed - ejected")


## Show interaction prompt for nearby vehicle.
func get_interaction_prompt() -> String:
	if is_in_vehicle:
		return "Press E to exit"
	
	var nearby = _find_nearby_vehicle()
	if nearby and nearby.has_method("get_interaction_prompt"):
		return nearby.get_interaction_prompt()
	
	return ""


## Check if can show interaction prompt.
func should_show_prompt() -> bool:
	if is_in_vehicle:
		return true
	
	var nearby = _find_nearby_vehicle()
	return nearby != null