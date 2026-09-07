extends SceneTree

const CARROW_MAP := preload("res://game/world/gothic_compound/gothic_compound_map.gd")
const ENVIRONMENT := preload("res://game/world/environment/world_environment_director.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := CARROW_MAP.new() as GothicCompoundMap
	root.add_child(map)
	await process_frame

	_require(map.is_in_group("carrow_yard_map"), "map is missing carrow_yard_map identity")
	_require(map.is_in_group("environment_region_provider"), "map is not an environment-region provider")
	var state := map.get_machine_house_debug_state()
	_require(String(state.canonical_id) == "carrow_yard", "canonical ID mismatch")
	_require(state.layout == ["XXXXXXXXXXXX","XRRR....SSSX","XRRR....SSSX","X..........X","X..GGGGGG..X","X..........X","XLL......BBX","XXXXXDDXXXXX"], "12x8 authored layout mismatch")
	var interior_rect: Rect2 = state.interior_rect
	_require(interior_rect.size == Vector2(384, 256), "interior footprint is not 12x8 at 32 px")
	_require(bool(state.has_entry_door) and bool(state.has_exit_door), "interior doorway pair is incomplete")
	var structure_sites := state.structure_sites as Dictionary
	for site_id in ["operations_house", "west_draft_house", "machine_house", "terminal"]:
		_require(structure_sites.has(site_id), "generator omitted named structure site: %s" % site_id)

	var interior_region := map.get_environment_region_at_global(map.to_global(interior_rect.get_center()))
	_require(bool(interior_region.get("indoor", false)), "interior was not classified indoors")
	_require(is_equal_approx(float(interior_region.get("environment_exposure", 1.0)), 0.10), "interior daylight exposure mismatch")
	_require(is_zero_approx(float(interior_region.get("weather_exposure", 1.0))), "interior weather exposure was not zero")
	var yard_region := map.get_environment_region_at_global(map.to_global(Vector2(64, 64)))
	_require(bool(yard_region.get("contains", false)) and not bool(yard_region.get("indoor", true)), "yard exterior classification mismatch")

	var actor := Node2D.new()
	root.add_child(actor)
	actor.global_position = map.to_global(Vector2(64, 64))
	var environment := ENVIRONMENT.new() as WorldEnvironmentDirector
	root.add_child(environment)
	environment.operator = actor
	environment.configure_from_contract({"contract_seed":17,"map":{"map_seed":29},"world_profile":{"profile_seed":41,"day_start_hour_min":9.0,"day_start_hour_max":9.0,"weather_weights":{"heavy_rain":1.0}}}, null)
	environment.debug_force_weather("heavy_rain")
	environment.advance_environment(1.25)
	_require(float(environment.get_presentation_state().precipitation_alpha) > 0.9, "yard rain was not visible")
	var weather_hold_before_entry := float(environment.debug_get_state().weather_hold_remaining)
	map.enter_machine_house(actor)
	_require(interior_rect.has_point(map.to_local(actor.global_position)), "entry did not move actor into Machine House")
	_require(map.get_machine_house_debug_state().inside, "entry did not switch interior camera state")
	environment.advance_environment(1.25)
	var indoor_state := environment.get_presentation_state()
	_require(is_equal_approx(float(indoor_state.environment_exposure), 0.10), "director did not apply Machine House daylight exposure")
	_require(is_zero_approx(float(indoor_state.weather_exposure)), "director did not suppress Machine House weather")
	_require(is_zero_approx(float(indoor_state.precipitation_alpha)), "precipitation remained visible indoors")
	_require(float(environment.debug_get_state().weather_hold_remaining) < weather_hold_before_entry, "weather stopped ticking indoors")
	map.leave_machine_house(actor)
	_require(not map.get_machine_house_debug_state().inside, "exit did not restore yard camera state")
	environment.advance_environment(1.25)
	_require(float(environment.get_presentation_state().precipitation_alpha) > 0.9, "yard rain did not resume after exit")

	var room := map.get_node_or_null("EastMachineHouseInterior")
	_require(room != null, "East Machine House root missing")
	_require(int(state.floor_tile_count) == 96, "Carrow floor did not fill the 12x8 room")
	_require(int(state.production_art_count) == 13, "Machine House production-art placement count mismatch")
	_require(room.get_node_or_null("CarrowFloorTiles/Floor_00_00") is Sprite2D, "Carrow floor sprites are missing")
	_require(room.get_node_or_null("ProductionArt/Entry") is Sprite2D, "Machine House entry art is missing")
	for art_name in ["NorthWallPanelled", "NorthWallConduit", "RelayBank", "Switchgear", "Workbench", "PartsLocker", "ServiceCabinet", "ConduitJunction"]:
		var sprite := room.get_node_or_null("ProductionArt/" + art_name) as Sprite2D
		_require(sprite != null and sprite.texture != null, "missing production art: %s" % art_name)
	_require(room.find_children("Cell*", "Polygon2D", true, false).is_empty(), "legacy greybox cell visuals remain")
	for expected_name in ["CarrowServicePartsLocker", "CarrowStructuralSparesRack", "CarrowPowerComponentsCabinet", "MachineHouseLightingZone", "SwitchBankMaintenanceLight"]:
		_require(room.get_node_or_null(expected_name) != null, "missing interior node: %s" % expected_name)
	var lighting_zone := room.get_node_or_null("MachineHouseLightingZone") as LightingZone2D
	_require(lighting_zone != null and lighting_zone.profile != null, "interior lighting profile is not wired")
	if lighting_zone != null and lighting_zone.profile != null:
		_require(is_equal_approx(lighting_zone.profile.environment_influence, 0.10), "lighting profile environment influence mismatch")
		_require(is_equal_approx(lighting_zone.profile.weather_influence, 0.03), "lighting profile weather influence mismatch")

	var gate := map.get_node_or_null("ReturnToMainMapGate") as GothicCompoundTravelGate
	_require(gate != null, "Carrow return Transfer Frame is missing")
	if gate != null:
		var gate_state := gate.get_presentation_debug_state()
		_require(int(gate_state.state) == GothicCompoundTravelGate.PresentationState.ROUTE_AVAILABLE, "Transfer Frame did not initialize route-available")
		_require((gate_state.production_layers as Array).size() == 17, "Transfer Frame production layer count mismatch")
		_require(gate_state.scale == Vector2.ONE, "Transfer Frame art was scaled")
		gate.set_presentation_state(GothicCompoundTravelGate.PresentationState.ACTIVE)
		gate_state = gate.get_presentation_debug_state()
		_require(int(gate_state.interaction_frames) == 8, "aperture loop is not eight frames")
		gate.set_presentation_state(GothicCompoundTravelGate.PresentationState.ACTIVATING)
		gate_state = gate.get_presentation_debug_state()
		_require(int(gate_state.interaction_frames) == 6, "boot strip is not six frames")

	if _failed:
		quit(1)
		return
	print("carrow_yard_interior_smoke: PASS interior=12x8 provider=connected_map")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("carrow_yard_interior_smoke: " + message)
