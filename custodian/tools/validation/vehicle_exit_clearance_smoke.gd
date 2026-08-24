extends SceneTree
const VEHICLE := preload("res://game/vehicles/pilotable_vehicle.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var vehicle := VEHICLE.new() as PilotableVehicle; root.add_child(vehicle)
	vehicle.movement_profile = {"max_speed": 100.0, "acceleration": 1000.0, "turn_response": 1.0, "reverse_multiplier": 0.45}
	var pilot := CharacterBody2D.new(); var pilot_shape := CollisionShape2D.new(); pilot_shape.name = "CollisionShape2D"
	var capsule := CapsuleShape2D.new(); capsule.radius = 11.0; capsule.height = 24.0; pilot_shape.shape = capsule; pilot.add_child(pilot_shape); root.add_child(pilot)
	vehicle.pilot = pilot; vehicle.control_state = PilotableVehicle.ControlState.PILOTED; vehicle._pilot_collision_mask = 1
	var blocker := StaticBody2D.new(); blocker.collision_layer = 1; blocker.position = Vector2(56, 0)
	var blocker_shape := CollisionShape2D.new(); var box := RectangleShape2D.new(); box.size = Vector2(30, 30); blocker_shape.shape = box; blocker.add_child(blocker_shape); root.add_child(blocker)
	await physics_frame
	assert(not vehicle.call("_is_exit_position_clear", Vector2(56, 0))); assert(vehicle.call("_is_exit_position_clear", Vector2(-56, 0)))
	assert((vehicle.call("_find_exit_position") as Vector2).is_equal_approx(Vector2(-56, 0)))
	vehicle.velocity = Vector2.DOWN * 30.0; vehicle.facing_direction = Vector2.DOWN; vehicle.call("_apply_movement", Vector2.RIGHT, false, 0.016); var slow_turn_x := vehicle.velocity.x
	vehicle.velocity = Vector2.DOWN * 30.0; vehicle.movement_profile["turn_response"] = 30.0; vehicle.call("_apply_movement", Vector2.RIGHT, false, 0.016)
	assert(vehicle.velocity.x > slow_turn_x)
	box.size = Vector2(400, 400); blocker.position = Vector2.ZERO
	await physics_frame
	assert(not vehicle.exit_vehicle()); assert(vehicle.control_state == PilotableVehicle.ControlState.PILOTED); assert(vehicle.pilot == pilot)
	print("vehicle_exit_clearance_smoke: PASS"); quit(0)
