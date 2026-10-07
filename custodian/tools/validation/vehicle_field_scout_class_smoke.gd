extends SceneTree

const REGISTRY_SCRIPT := preload("res://game/vehicles/vehicle_registry.gd")
const EXPECTED_VEHICLE_ID := "custodian_ground_buggy_scout_light"
const EXPECTED_SCENE := "res://game/actors/vehicles/field_scout_buggy_mk1.tscn"


func _init() -> void:
	var errors: Array[String] = []
	var registry := REGISTRY_SCRIPT.new()
	registry.load_registry()
	var definition = registry.get_vehicle(EXPECTED_VEHICLE_ID)
	if definition == null:
		_fail(errors, "Field Scout registry definition did not load")
		_finish(errors)
		return
	if definition.get_display_name() != "Custodian Field Scout Buggy Mk I":
		_fail(errors, "Field Scout display name is not semantic")
	if definition.runtime_scene != EXPECTED_SCENE:
		_fail(errors, "Field Scout does not resolve to its semantic scene")
	if definition.durability_profile != "light_scout_utility":
		_fail(errors, "Field Scout durability profile is missing")
	if definition.visual_kit != "custodian_field_scout_buggy_mk1_compat_hover":
		_fail(errors, "Temporary hover art is not clearly identified as compatibility presentation")
	var schema_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/vehicles/vehicle_registry_schema.json"))
	if not (schema_data is Dictionary) or not Array((schema_data as Dictionary).get("required_vehicle_fields", [])).has("durability_profile"):
		_fail(errors, "Vehicle registry schema does not require durability_profile")
	if definition.loadout != "none":
		_fail(errors, "Field Scout gained an unintended equipment loadout")
	if definition.seat_profile.get("driver_seats") != 1 or definition.seat_profile.get("passenger_seats") != 0:
		_fail(errors, "Field Scout seat contract changed")
	var footprint_cells: Array = definition.footprint.get("cells", [])
	if footprint_cells.size() != 2 or float(footprint_cells[0]) != 2.0 or float(footprint_cells[1]) != 1.0 or definition.footprint.get("anchor") != "BOTTOM_CENTER":
		_fail(errors, "Field Scout footprint contract changed")

	var packed_scene := load(EXPECTED_SCENE) as PackedScene
	if packed_scene == null:
		_fail(errors, "Field Scout scene could not load")
		_finish(errors)
		return
	var vehicle := packed_scene.instantiate() as PilotableVehicle
	if vehicle == null:
		_fail(errors, "Field Scout scene does not use PilotableVehicle")
		_finish(errors)
		return
	vehicle.max_health = 1.0
	vehicle.current_health = 1.0
	vehicle.apply_vehicle_definition(definition)
	if vehicle.max_health != 100.0:
		_fail(errors, "Durability profile was not applied to the shared health authority")
	if vehicle.current_health != 1.0:
		_fail(errors, "Applying durability unexpectedly reset existing health")
	for node_path in ["CollisionShape2D", "DriverSeat", "ExitMarker", "Hardpoints/FrontLight", "Hardpoints/RearUtility"]:
		if vehicle.get_node_or_null(node_path) == null:
			_fail(errors, "Field Scout scene is missing %s" % node_path)
	if vehicle.get_node_or_null("HealthBar") != null:
		_fail(errors, "Field Scout scene retains an unbound constant HealthBar")
	var driver_seat := vehicle.get_node_or_null("DriverSeat") as VehicleSeat
	if driver_seat == null or driver_seat.seat_id != "driver":
		_fail(errors, "Field Scout driver seat identity is missing")
	vehicle.free()
	registry.free()

	var game_scene := load("res://scenes/game.tscn") as PackedScene
	if game_scene == null:
		_fail(errors, "Game scene could not load")
	else:
		var game := game_scene.instantiate()
		if game.get_node_or_null("World/FieldScoutBuggyMk1") == null:
			_fail(errors, "game.tscn does not instantiate FieldScoutBuggyMk1")
		game.free()
	_finish(errors)


func _fail(errors: Array[String], message: String) -> void:
	errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[VehicleFieldScoutClassSmoke] PASS")
		quit(0)
		return
	for message in errors:
		push_error("[VehicleFieldScoutClassSmoke] " + message)
	quit(1)
