extends Area2D
class_name VehicleInteraction
## Handles vehicle enter/exit interaction prompts.
##
## Attach as a child of VehicleBase scene.
## Requires collision shape covering interaction range.

signal interaction_ready(vehicle: Node, prompt: String)
signal interaction_pressed(vehicle: Node)

@export var vehicle_path: NodePath = ^".."
@export var interaction_range: float = 64.0

var vehicle: Node = null
var nearby_player: Node = null


func _ready() -> void:
	# Get parent vehicle
	if vehicle_path:
		vehicle = get_node(vehicle_path)
	else:
		vehicle = get_parent()
	
	# Setup collision shape if needed
	if not has_node("CollisionShape2D"):
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = interaction_range
		add_child(shape)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	# Update interaction state
	if nearby_player and vehicle:
		var prompt = ""
		if vehicle.has_method("get_interaction_prompt"):
			prompt = vehicle.get_interaction_prompt()
		interaction_ready.emit(vehicle, prompt)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		nearby_player = body
		# Try to find player controller
		var controller = body.get_parent()
		if controller and controller.has_method("should_show_prompt"):
			# Player controller owns prompt display.
			pass


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		nearby_player = null


## Handle interaction input when player is nearby.
func try_interact() -> bool:
	if not nearby_player:
		return false
	
	# Find player controller and trigger interaction
	var controller = _find_player_controller()
	if controller and controller.has_method("try_enter_nearby_vehicle"):
		controller.try_enter_nearby_vehicle()
		interaction_pressed.emit(vehicle)
		return true
	
	return false


## Find player controller in scene tree.
func _find_player_controller() -> Node:
	var root = get_tree().root
	if root.has_node("GameRoot/World/PlayerController"):
		return root.get_node("GameRoot/World/PlayerController")
	
	# Try alternative paths
	for node in root.get_children():
		if node.has_method("try_enter_nearby_vehicle"):
			return node
	
	return null
