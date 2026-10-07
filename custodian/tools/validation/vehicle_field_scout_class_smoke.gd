extends SceneTree

const REGISTRY_SCRIPT := preload("res://game/vehicles/vehicle_registry.gd")
const SPAWN_RESOLVER_SCRIPT := preload("res://game/vehicles/vehicle_spawn_resolver.gd")
const GAME_SCENE := preload("res://scenes/game.tscn")
const VEHICLE_ID := "custodian_ground_buggy_scout_light"
const SCENE_PATH := "res://game/actors/vehicles/field_scout_buggy_mk1.tscn"
const EXPECTED_MOVEMENT := {
	"max_speed": 175.0,
	"acceleration": 420.0,
	"deceleration": 520.0,
	"turn_response": 10.0,
	"reverse_multiplier": 0.45,
	"road_speed_multiplier_enabled": true,
	"offroad_speed_multiplier": 0.78,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var world := Node2D.new()
	world.name = "VehicleFieldScoutSmokeWorld"
	get_root().add_child(world)

	var registry = REGISTRY_SCRIPT.new()
	registry.load_registry()
	var definition = registry.get_vehicle(VEHICLE_ID)
	if definition == null:
		_fail(errors, "Field Scout registry definition did not load")
		await _finish(errors, world, registry)
		return
	_validate_definition(definition, errors)

	var game := GAME_SCENE.instantiate()
	var authored_world := game.get_node_or_null("World")
	var authored_vehicle := game.get_node_or_null("World/FieldScoutBuggyMk1")
	if authored_world == null or authored_vehicle == null:
		_fail(errors, "game.tscn does not author the semantic Field Scout scene under World")
	else:
		authored_world.remove_child(authored_vehicle)
		authored_vehicle.owner = null
		world.add_child(authored_vehicle)
		await process_frame
		_validate_wreck(authored_vehicle, "authored game scene", errors)
		_exercise_recovery(authored_vehicle, world, errors)
	game.free()

	var resolver = SPAWN_RESOLVER_SCRIPT.new()
	world.add_child(resolver)
	await process_frame
	var resolved_vehicle = resolver.spawn_vehicle(VEHICLE_ID, world, Vector2(400.0, 0.0))
	if resolved_vehicle == null:
		_fail(errors, "registry resolver did not spawn the Field Scout")
	else:
		await process_frame
		_validate_wreck(resolved_vehicle, "registry resolver", errors)
		_exercise_recovery(resolved_vehicle, world, errors)

	var ledger := get_root().get_node_or_null("ResourceLedger")
	if ledger != null:
		ledger.call("clear")
	await _finish(errors, world, registry)


func _validate_definition(definition, errors: Array[String]) -> void:
	if definition.get_display_name() != "Custodian Field Scout Buggy Mk I":
		_fail(errors, "Field Scout display name is not semantic")
	if definition.runtime_scene != SCENE_PATH:
		_fail(errors, "Field Scout does not resolve to its semantic scene")
	if definition.durability_profile != "light_scout_utility":
		_fail(errors, "Field Scout durability profile identity changed")
	if float(definition.durability_profile_data.get("max_health", 0.0)) != 100.0:
		_fail(errors, "durability profile does not own 100 maximum HP")
	if definition.restoration_profile != "field_scout_recovery_light":
		_fail(errors, "Field Scout restoration profile identity changed")
	var restoration: Dictionary = definition.restoration_profile_data
	if restoration.get("initial_state") != "WRECKAGE":
		_fail(errors, "Field Scout restoration profile does not start in WRECKAGE")
	var cost: Dictionary = restoration.get("cost", {})
	if int(cost.get("ruin_scrap", 0)) != 12 \
	or int(cost.get("structural_alloy", 0)) != 6 \
	or int(cost.get("power_components", 0)) != 1 \
	or cost.size() != 3:
		_fail(errors, "Field Scout restoration material cost changed")
	if float(restoration.get("hold_duration", 0.0)) != 4.0 or float(restoration.get("restored_health_fraction", 0.0)) != 0.4:
		_fail(errors, "Field Scout restoration duration or health fraction changed")
	if definition.visual_kit != "custodian_field_scout_buggy_mk1_compat_hover":
		_fail(errors, "temporary hover presentation is not identified as compatibility art")
	if definition.loadout != "none":
		_fail(errors, "Field Scout gained an unintended equipment loadout")
	if definition.seat_profile.get("driver_seats") != 1 or definition.seat_profile.get("passenger_seats") != 0:
		_fail(errors, "Field Scout seat count changed")
	if int(definition.seat_profile.get("entry_radius", 0)) != 64:
		_fail(errors, "Field Scout entry radius is not 64 px")
	var cells: Array = definition.footprint.get("cells", [])
	if cells.size() != 2 or int(cells[0]) != 2 or int(cells[1]) != 1 or definition.footprint.get("anchor") != "BOTTOM_CENTER":
		_fail(errors, "Field Scout footprint is not 2x1 bottom-center")
	var movement_root: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/vehicles/vehicle_movement_profiles.json"))
	var profiles := Dictionary(Dictionary(movement_root).get("profiles", {})) if movement_root is Dictionary else {}
	var movement := Dictionary(profiles.get(definition.movement_profile, {}))
	for key in EXPECTED_MOVEMENT:
		if movement.get(key) != EXPECTED_MOVEMENT[key]:
			_fail(errors, "Field Scout movement %s changed" % key)


func _validate_wreck(vehicle: Node, route: String, errors: Array[String]) -> void:
	if not vehicle.has_method("is_wreckage") or not bool(vehicle.call("is_wreckage")):
		_fail(errors, "%s vehicle did not start as WRECKAGE" % route)
	if float(vehicle.get("current_health")) != 0.0 or not bool(vehicle.get("is_destroyed")):
		_fail(errors, "%s wreck does not have zero health and destroyed lifecycle state" % route)
	if vehicle.is_in_group("pilotable_vehicles") or vehicle.is_in_group("interactable"):
		_fail(errors, "%s wreck is exposed as an operational vehicle" % route)
	if vehicle.get("control_state") != 4:
		_fail(errors, "%s wreck is not DISABLED" % route)
	if vehicle.get_node_or_null("FieldRepairInteraction") == null:
		_fail(errors, "%s scene is missing FieldRepairInteraction" % route)
	elif vehicle.get_node("FieldRepairInteraction").is_in_group("interactable"):
		_fail(errors, "%s wreck exposes field repair before restoration" % route)
	for node_path in ["CollisionShape2D", "DriverSeat", "ExitMarker", "Hardpoints/FrontLight", "Hardpoints/RearUtility"]:
		if vehicle.get_node_or_null(node_path) == null:
			_fail(errors, "%s scene is missing %s" % [route, node_path])
	var driver_seat := vehicle.get_node_or_null("DriverSeat")
	if driver_seat == null or driver_seat.get("seat_id") != "driver":
		_fail(errors, "%s scene has no canonical driver seat" % route)
	if vehicle.get_node_or_null("HealthBar") != null:
		_fail(errors, "%s scene retains an unbound constant health bar" % route)
	if float(vehicle.get("max_health")) != 100.0 or float(vehicle.get("interaction_range")) != 64.0:
		_fail(errors, "%s runtime did not apply durability or entry radius profiles" % route)


func _exercise_recovery(vehicle: Node2D, world: Node2D, errors: Array[String]) -> void:
	if not bool(vehicle.call("restore_from_wreck", 0.4)):
		_fail(errors, "vehicle lifecycle rejected the configured 40% restore")
		return
	if float(vehicle.get("current_health")) != 40.0 or bool(vehicle.get("is_destroyed")):
		_fail(errors, "restoration did not produce the same operational vehicle at 40 HP")
	var repair_interaction := vehicle.get_node_or_null("FieldRepairInteraction")
	if repair_interaction == null or not repair_interaction.is_in_group("interactable"):
		_fail(errors, "field repair did not become available after restoration")
		return
	var ledger := get_root().get_node_or_null("ResourceLedger")
	if ledger == null:
		_fail(errors, "ResourceLedger autoload is unavailable for field-repair validation")
		return
	ledger.call("clear")
	ledger.call("debug_grant", {"ruin_scrap": 4})
	var actor := Node2D.new()
	actor.global_position = vehicle.global_position
	world.add_child(actor)
	repair_interaction.call("interact", actor)
	repair_interaction.call("_physics_process", float(repair_interaction.get("hold_duration")) + 0.01)
	if float(vehicle.get("current_health")) <= 40.0:
		_fail(errors, "existing FieldRepairInteraction could not repair the restored Scout")
	if not bool(vehicle.call("can_enter", actor)) or not bool(vehicle.call("enter_vehicle", actor)):
		_fail(errors, "restored Field Scout could not be entered")
	if vehicle.get("pilot") != actor:
		_fail(errors, "restored Field Scout did not retain the entering driver")
	actor.queue_free()


func _fail(errors: Array[String], message: String) -> void:
	errors.append(message)


func _finish(errors: Array[String], world: Node, registry: Node) -> void:
	if registry.get_parent() == null:
		registry.free()
	if is_instance_valid(world):
		world.queue_free()
	await process_frame
	if errors.is_empty():
		print("[VehicleFieldScoutClassSmoke] PASS")
		quit(0)
		return
	for message in errors:
		push_error("[VehicleFieldScoutClassSmoke] " + message)
	quit(1)
