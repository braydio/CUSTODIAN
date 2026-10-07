extends SceneTree

## Covers occupied disable/destruction/teardown, blocked ordinary exit,
## Operator property restoration, PlayerController/camera release, and group
## discovery de-duplication through the production lifecycle scripts.

const VEHICLE_SCRIPT := preload("res://game/vehicles/pilotable_vehicle.gd")
const CONTROLLER_SCRIPT := preload("res://game/systems/core/player_controller.gd")

var _errors: Array[String] = []


class CameraProbe:
	extends Node2D

	var follow_target: Node = null
	var follow_history: Array[Node] = []

	func set_follow_target(target: Node) -> void:
		follow_target = target
		follow_history.append(target)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_disable_releases_and_restores_pilot()
	await _test_blocked_exit_keeps_ownership_then_recovers()
	await _test_zero_health_destroys_and_releases_once()
	await _test_tree_teardown_releases_pilot()
	if not _errors.is_empty():
		push_error("VehicleRuntimeLifecycleSmoke failed (%d errors)" % _errors.size())
		quit(1)
		return
	print("[VehicleRuntimeLifecycleSmoke] PASS")
	quit(0)


func _make_fixture(label: String) -> Dictionary:
	var game_root := Node2D.new()
	game_root.name = "GameRoot_" + label
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	operator.collision_layer = 3
	operator.collision_mask = 5
	operator.set_process(false)
	operator.set_physics_process(true)
	operator.set_process_input(true)
	var operator_shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 28.0
	operator_shape.shape = capsule
	operator.add_child(operator_shape)
	world.add_child(operator)
	var camera := CameraProbe.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var vehicle := VEHICLE_SCRIPT.new() as PilotableVehicle
	vehicle.name = "LifecycleVehicle"
	vehicle.position = Vector2.ZERO
	vehicle.exit_search_radii_px = PackedFloat32Array([48.0, 72.0])
	vehicle.exit_search_direction_count = 8
	var marker := Marker2D.new()
	marker.name = "ExitMarker"
	marker.position = Vector2(56.0, 4.0)
	vehicle.add_child(marker)
	world.add_child(vehicle)
	var controller := CONTROLLER_SCRIPT.new() as PlayerController
	controller.name = "PlayerController"
	controller.operator_path = ^"../Operator"
	controller.camera_path = ^"../Camera2D"
	world.add_child(controller)
	await process_frame
	await physics_frame
	return {
		"game_root": game_root,
		"world": world,
		"operator": operator,
		"camera": camera,
		"vehicle": vehicle,
		"controller": controller,
	}


func _test_disable_releases_and_restores_pilot() -> void:
	var f := await _make_fixture("disable")
	var operator := f["operator"] as CharacterBody2D
	var vehicle := f["vehicle"] as PilotableVehicle
	var controller := f["controller"] as PlayerController
	var camera := f["camera"] as CameraProbe
	_expect(controller.enter_vehicle(vehicle), "controller should enter the nearby vehicle")
	_expect(controller._get_nearby_vehicle_candidates().size() == 1, "overlapping compatibility groups must produce one candidate")
	_expect(not operator.visible and operator.collision_layer == 0 and operator.collision_mask == 0, "entry must hide and collision-disable the Operator")
	_expect(not operator.is_physics_processing() and not operator.is_processing_input(), "entry must disable Operator processing")
	vehicle.disable_vehicle("lifecycle_test")
	_expect(vehicle.control_state == PilotableVehicle.ControlState.DISABLED, "disable must reach DISABLED state")
	_expect(vehicle.pilot == null, "disable must release the pilot")
	_expect(operator.visible and operator.collision_layer == 3 and operator.collision_mask == 5, "disable must restore visibility and collision properties")
	_expect(not operator.is_processing() and operator.is_physics_processing() and operator.is_processing_input(), "disable must restore the prior process-state snapshot")
	_expect(controller.get_current_vehicle() == null and not controller.is_vehicle_mode(), "release signal must clear canonical controller ownership")
	_expect(camera.follow_target == operator and camera.follow_history.size() == 2, "disable must return camera authority to Operator exactly once")
	_expect(not vehicle.can_enter(operator), "disabled vehicle must reject entry")
	var old_position := vehicle.global_position
	vehicle.route_vehicle_input(Vector2.RIGHT, {}, 1.0)
	_expect(vehicle.global_position == old_position and vehicle.current_speed == 0.0, "disabled vehicle must not move from routed input")
	var properties := _property_names(controller)
	_expect(not properties.has("controlled_vehicle") and not properties.has("is_in_vehicle"), "PlayerController must expose only one mutable vehicle reference")
	await _dispose_fixture(f["game_root"] as Node)


func _test_blocked_exit_keeps_ownership_then_recovers() -> void:
	var f := await _make_fixture("blocked_exit")
	var operator := f["operator"] as CharacterBody2D
	var vehicle := f["vehicle"] as PilotableVehicle
	var controller := f["controller"] as PlayerController
	var camera := f["camera"] as CameraProbe
	_expect(controller.enter_vehicle(vehicle), "controller should enter before blocked-exit case")
	var blocker := StaticBody2D.new()
	blocker.collision_layer = 1
	var blocker_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(900.0, 900.0)
	blocker_shape.shape = rectangle
	blocker.add_child(blocker_shape)
	(f["world"] as Node).add_child(blocker)
	await physics_frame
	_expect(not controller.exit_vehicle(), "blocked ordinary exit must fail")
	_expect(vehicle.is_piloted() and vehicle.pilot == operator, "blocked exit must preserve pilot occupancy")
	_expect(not operator.visible and operator.collision_layer == 0, "blocked exit must keep pilot safely inside")
	_expect(controller.get_current_vehicle() == vehicle and camera.follow_target == vehicle, "blocked exit must preserve controller and camera ownership")
	blocker.queue_free()
	await physics_frame
	await physics_frame
	_expect(controller.exit_vehicle(), "ordinary exit should succeed after obstruction clears")
	_expect(operator.visible and operator.collision_layer == 3 and operator.collision_mask == 5, "ordinary exit must restore original actor properties")
	_expect(not operator.is_processing() and operator.is_physics_processing() and operator.is_processing_input(), "ordinary exit must restore process state exactly")
	_expect(controller.get_current_vehicle() == null and camera.follow_target == operator and camera.follow_history.size() == 2, "normal release must return controller/camera exactly once")
	await _dispose_fixture(f["game_root"] as Node)


func _test_zero_health_destroys_and_releases_once() -> void:
	var f := await _make_fixture("destroyed")
	var operator := f["operator"] as CharacterBody2D
	var vehicle := f["vehicle"] as PilotableVehicle
	var controller := f["controller"] as PlayerController
	var camera := f["camera"] as CameraProbe
	_expect(controller.enter_vehicle(vehicle), "controller should enter before destruction case")
	vehicle.take_damage(25.0)
	_expect(vehicle.current_health == 75.0 and vehicle.is_piloted(), "nonlethal damage must preserve vehicle ownership")
	vehicle.take_damage(75.0)
	_expect(vehicle.current_health == 0.0 and vehicle.is_destroyed, "lethal damage must clamp health and mark destruction")
	_expect(vehicle.control_state == PilotableVehicle.ControlState.DISABLED and vehicle.pilot == null, "destruction must disable vehicle and release pilot")
	_expect(operator.visible and operator.collision_layer == 3 and operator.collision_mask == 5, "destruction must restore the Operator")
	_expect(controller.get_current_vehicle() == null and not controller.is_vehicle_mode(), "destruction signal must clear controller ownership")
	_expect(camera.follow_target == operator and camera.follow_history.size() == 2, "destruction must restore camera authority exactly once")
	_expect(not vehicle.can_enter(operator), "zero-health vehicle must reject entry")
	var old_position := vehicle.global_position
	vehicle.route_vehicle_input(Vector2.RIGHT, {}, 1.0)
	_expect(vehicle.global_position == old_position and vehicle.current_speed == 0.0, "zero-health vehicle must reject driving input")
	await _dispose_fixture(f["game_root"] as Node)


func _test_tree_teardown_releases_pilot() -> void:
	var f := await _make_fixture("teardown")
	var operator := f["operator"] as CharacterBody2D
	var vehicle := f["vehicle"] as PilotableVehicle
	var controller := f["controller"] as PlayerController
	var camera := f["camera"] as CameraProbe
	_expect(controller.enter_vehicle(vehicle), "controller should enter before teardown case")
	vehicle.queue_free()
	await process_frame
	_expect(not is_instance_valid(vehicle), "vehicle teardown should remove the vehicle")
	_expect(operator.visible and operator.collision_layer == 3 and operator.collision_mask == 5, "vehicle teardown must restore the Operator")
	_expect(controller.get_current_vehicle() == null and not controller.is_vehicle_mode(), "teardown release must clear controller ownership")
	_expect(camera.follow_target == operator and camera.follow_history.size() == 2, "teardown must return camera authority exactly once")
	await _dispose_fixture(f["game_root"] as Node)


func _property_names(node: Object) -> Array[StringName]:
	var names: Array[StringName] = []
	for property in node.get_property_list():
		names.append(StringName(property.get("name", "")))
	return names


func _dispose_fixture(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error("[VehicleRuntimeLifecycleSmoke] " + message)
