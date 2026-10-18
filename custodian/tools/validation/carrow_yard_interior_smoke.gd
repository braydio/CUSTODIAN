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
	_require(state.layout == ["XXXXXXXXXXXXXX","X............X","XRRR......SSSX","XRRR......SSSX","XL..........CX","XW..........PX","X............X","X............X","X............X","XXXXXDDDXXXXX"], "14x10 authored layout mismatch")
	var interior_rect: Rect2 = state.interior_rect
	_require(interior_rect.size == Vector2(448, 320), "interior footprint is not 14x10 at 32 px")
	_require(bool(state.has_entry_door) and bool(state.has_exit_door), "interior doorway pair is incomplete")
	var structure_sites := state.structure_sites as Dictionary
	for site_id in ["operations_house", "west_draft_house", "machine_house", "terminal"]:
		_require(structure_sites.has(site_id), "generator omitted named structure site: %s" % site_id)
	var west_state := map.get_west_draft_house_debug_state()
	var west_rect: Rect2 = west_state.get("interior_rect", Rect2())
	var west_layout: Array = west_state.get("layout", [])
	_require(west_rect.size == Vector2(384, 320), "West Draft House is not 12x10 at 32 px")
	_require(west_layout == ["XXXXXXXXXXXX", "X..........X", "XFFFF..HHHHX", "XFFFF..HHHHX", "X..........X", "XVV.......CX", "XVV......PPX", "X..........X", "X..........X", "XXXXXDDDXXXX"], "West Draft House grid differs from the approved W1 contract")
	_require(bool(west_state.get("has_entry_door", false)) and bool(west_state.get("has_exit_door", false)), "West Draft House doorway pair is incomplete")
	_require(int(west_state.get("floor_tile_count", 0)) == 120, "West Draft House floor does not fill its 12x10 footprint")
	_require(int(west_state.get("production_art_count", 0)) == 8, "West Draft House reused-art placement count mismatch")
	var west_root := west_state.get("root") as Node2D
	_require(west_root != null, "West Draft House room root is missing")
	for art_name in ["NorthFanBay", "NorthHeatExchanger", "WestFilterVent", "EastDraftControls", "PressureSwitchgear", "FilterCradle", "EmergencyPartsRack", "AuxiliaryPowerJunction"]:
		var west_art := west_root.get_node_or_null("ProductionArt/" + art_name) as Sprite2D if west_root != null else null
		_require(west_art != null and west_art.texture != null, "missing reused West production art: %s" % art_name)
	for storage_name in ["CarrowDraftFilterCradle", "CarrowEmergencyPartsRack"]:
		var west_storage := west_root.get_node_or_null(storage_name) as VaultStorage if west_root != null else null
		_require(west_storage != null and west_storage.has_resources(), "missing West storage interaction: %s" % storage_name)
	var filter_art := west_root.get_node_or_null("ProductionArt/FilterCradle") as Sprite2D if west_root != null else null
	var filter_storage := west_root.get_node_or_null("CarrowDraftFilterCradle") as VaultStorage if west_root != null else null
	if filter_art != null and filter_art.texture != null and filter_storage != null:
		_require(filter_storage.position == filter_art.position + Vector2(0.0, float(filter_art.texture.get_height()) * 0.5), "Filter Cradle interaction is detached from its visible art anchor")
	var east_camera: Rect2 = state.get("camera_bounds", Rect2())
	var west_camera: Rect2 = west_state.get("camera_bounds", Rect2())
	_require(not east_camera.intersects(west_camera), "East and West interior camera regions overlap")
	_require(not interior_rect.intersects(west_rect), "East and West room AABBs overlap")
	for row in west_layout:
		_require(String(row).length() == 12, "West Draft House contains a malformed row width")
	var west_site := (west_state.structure_sites as Dictionary).get("west_draft_house", {}) as Dictionary
	var west_site_cell: Vector2i = west_site.get("cell", Vector2i.ZERO)
	var west_site_footprint: Vector2i = west_site.get("footprint", Vector2i.ZERO)
	var expected_west_return := Vector2(west_site_cell + Vector2i(int(west_site_footprint.x / 2), west_site_footprint.y + 2)) * 32.0
	_require(west_state.exterior_return_position == expected_west_return, "West exterior return is not derived from the generated site footprint")
	var malformed_definition := {
		"size": Vector2i(12, 10),
		"layout": west_layout.duplicate(),
		"spawn_offset": Vector2(6.5, 8.25),
		"exit_cell": Vector2i(6, 9),
	}
	malformed_definition["layout"][0] = "XXXXXXXXXXX"
	_require(not map._is_valid_interior_definition(malformed_definition), "malformed room row did not fail closed")
	malformed_definition["layout"] = west_layout.duplicate()
	malformed_definition["layout"][9] = "XXXXXXXXXXXX"
	_require(not map._is_valid_interior_definition(malformed_definition), "blocked/missing doorway did not fail closed")
	_require(not map._is_valid_structure_site({}), "missing structure site was accepted")
	_require(not map._interior_bounds_available(interior_rect, east_camera), "overlapping room/camera allocation was accepted")
	var unavailable_definition := map._interior_definition(&"west_draft_house")
	var unavailable_art := unavailable_definition.art as Array[Dictionary]
	unavailable_art[0]["path"] = "walls/missing_review_fixture.png"
	_require(not map._interior_assets_available(unavailable_definition, unavailable_art), "missing registered room texture did not fail closed")
	var west_children_before_missing_site := map.get_child_count()
	var west_entry_before_missing_site := map.get_node_or_null("EnterWestDraftHouse")
	map._structure_sites.erase("west_draft_house")
	map._add_west_draft_house_interior({})
	_require(map.get_child_count() == west_children_before_missing_site, "missing site created an orphan West interior")
	_require(map.get_node_or_null("EnterWestDraftHouse") == west_entry_before_missing_site, "missing site created an orphan West entrance")
	map._structure_sites["west_draft_house"] = west_site

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

	var west_entry := map.get_node_or_null("EnterWestDraftHouse") as CarrowMachineHouseDoor
	var west_exit := west_root.get_node_or_null("LeaveWestDraftHouse") as CarrowMachineHouseDoor if west_root != null else null
	_require(west_entry != null and west_exit != null, "West Draft House room-bound doors are missing")
	if west_entry != null and west_exit != null:
		west_entry.interact(actor)
		_require(map.get_active_interior_id() == &"west_draft_house", "West entry did not select the named interior")
		_require(west_rect.has_point(map.to_local(actor.global_position)), "West entry did not use its safe interior spawn")
		_require(map.get_camera_bounds().position == west_camera.position, "West entry did not select the West camera bounds")
		var west_environment := map.get_environment_region_at_global(map.to_global(west_rect.get_center()))
		_require(bool(west_environment.get("indoor", false)), "West room was not classified indoors")
		_require(is_zero_approx(float(west_environment.get("weather_exposure", 1.0))), "West indoor weather exposure is not zero")
		environment.advance_environment(1.25)
		_require(is_zero_approx(float(environment.get_presentation_state().precipitation_alpha)), "West room did not suppress outdoor rain")
		var selected_position := actor.global_position
		map.enter_machine_house(actor)
		map.enter_carrow_interior(&"stale_room_id", actor)
		map.leave_carrow_interior(&"east_machine_house", actor)
		_require(map.get_active_interior_id() == &"west_draft_house" and actor.global_position == selected_position, "stale or premature room switch changed the active room")
		var impostor := Node2D.new()
		root.add_child(impostor)
		map.leave_carrow_interior(&"west_draft_house", impostor)
		_require(map.get_active_interior_id() == &"west_draft_house", "a second actor stole the active interior's exit")
		impostor.queue_free()
		var west_filter_storage := west_root.get_node_or_null("CarrowDraftFilterCradle") as VaultStorage
		_require(west_filter_storage != null and west_filter_storage.has_resources(), "West Filter Cradle did not receive its bounded resources")
		if west_filter_storage != null:
			west_filter_storage.remove_resources(8, 1000)
			_require(not west_filter_storage.has_resources(), "West Filter Cradle resource depletion failed")
		west_exit.interact(actor)
		_require(map.get_active_interior_id() == &"", "West exit did not clear active_interior_id")
		_require(not west_rect.has_point(map.to_local(actor.global_position)), "West exit did not return the actor outside the room")
		var west_return_region := map.get_environment_region_at_global(actor.global_position)
		_require(bool(west_return_region.get("contains", false)) and not bool(west_return_region.get("indoor", true)), "West return point is not in the yard environment")
		west_entry.interact(actor)
		_require(not west_filter_storage.has_resources(), "West storage refilled on same-runtime revisit")
		west_exit.interact(actor)
		_require(not map.get_west_draft_house_debug_state().inside, "West same-runtime revisit did not return outside")
		var east_after_west := map.get_machine_house_debug_state()
		_require(east_after_west.interior_rect == interior_rect and east_after_west.layout == state.layout, "West visit changed East Machine House geometry or layout")
		_require(int(east_after_west.floor_tile_count) == 140 and int(east_after_west.production_art_count) == 13, "West visit changed East Machine House content counts")
		_require(map.get_active_interior_id() == &"", "Carrow retained a room selection after leaving both interiors")

	var alternate_map := CARROW_MAP.new() as GothicCompoundMap
	alternate_map.world_seed = 420777
	root.add_child(alternate_map)
	await process_frame
	var alternate_west := alternate_map.get_west_draft_house_debug_state()
	_require((alternate_west.structure_sites as Dictionary).has("west_draft_house"), "alternate seed omitted the named West structure site")
	_require(int(alternate_west.floor_tile_count) == 120 and bool(alternate_west.has_entry_door) and bool(alternate_west.has_exit_door), "alternate seed did not bind a complete West room to its generated site")

	var room := map.get_node_or_null("EastMachineHouseInterior")
	_require(room != null, "East Machine House root missing")
	_require(int(state.floor_tile_count) == 140, "Carrow floor did not fill the 14x10 room")
	_require(int(state.production_art_count) == 13, "Machine House production-art placement count mismatch")
	_require(room.get_node_or_null("MachineHouseInteriorBacking") is Polygon2D, "interior backing is missing")
	_require(room.get_node_or_null("CarrowFloorTiles/Floor_00_00") is Sprite2D, "Carrow floor sprites are missing")
	for art_name in ["NorthWallPanelled", "NorthWallConduit", "WestWall", "EastWall", "SouthDoorway", "RelayBank", "Switchgear", "Workbench", "PartsLocker", "ServiceCabinet", "ReplacementModules", "ConduitJunction", "PowerCabinet"]:
		var sprite := room.get_node_or_null("ProductionArt/" + art_name) as Sprite2D
		_require(sprite != null and sprite.texture != null, "missing production art: %s" % art_name)
	_require(room.find_children("Cell*", "Polygon2D", true, false).is_empty(), "legacy greybox cell visuals remain")
	for expected_name in ["CarrowServicePartsLocker", "CarrowStructuralSparesRack", "CarrowPowerComponentsCabinet", "MachineHouseLightingZone", "SwitchBankMaintenanceLight"]:
		_require(room.get_node_or_null(expected_name) != null, "missing interior node: %s" % expected_name)
	for storage_name in ["CarrowServicePartsLocker", "CarrowStructuralSparesRack", "CarrowPowerComponentsCabinet"]:
		var storage := room.get_node(storage_name) as VaultStorage
		_require(storage.has_resources(), "embedded storage lost its interaction resources: %s" % storage_name)
		_require(not (storage.get_node("Sprite2D") as Sprite2D).visible, "embedded storage rendered the generic vault chest: %s" % storage_name)
	var storage_art_bindings := {
		"CarrowServicePartsLocker": "PartsLocker",
		"CarrowStructuralSparesRack": "ReplacementModules",
		"CarrowPowerComponentsCabinet": "PowerCabinet",
	}
	for storage_name in storage_art_bindings:
		var storage := room.get_node(storage_name) as VaultStorage
		var art_sprite := room.get_node("ProductionArt/" + storage_art_bindings[storage_name]) as Sprite2D
		var art_floor_anchor := art_sprite.position + Vector2(0.0, float(art_sprite.texture.get_height()) * 0.5)
		_require(storage.position == art_floor_anchor, "embedded storage is not aligned with Carrow art: %s" % storage_name)
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
		var trigger := gate.get_node_or_null("AutoTravelArea") as Area2D
		var trigger_shape := trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D if trigger != null else null
		_require(trigger != null and trigger.position == Vector2(0, -48), "auto-travel trigger offset changed")
		_require(trigger_shape != null and (trigger_shape.shape as RectangleShape2D).size == Vector2(96, 64), "auto-travel trigger footprint changed")
		_require(gate.position == map._tile_to_local(map.return_gate_tile), "return Transfer Frame position changed")

	var entry_gate := GothicCompoundTravelGate.new()
	entry_gate.name = "TestMainEntryGate"
	entry_gate.configure(map, GothicCompoundTravelGate.TravelMode.ENTER_COMPOUND, "ENTER CARROW YARD")
	root.add_child(entry_gate)
	actor.add_to_group("player")
	gate.set_presentation_state(GothicCompoundTravelGate.PresentationState.ROUTE_AVAILABLE)
	_require(not map.is_travel_route_active(), "fresh route unexpectedly starts active")
	_require(entry_gate.is_in_group("interactable"), "fresh frame is not interactable")
	gate.call("_on_auto_travel_body_entered", actor)
	_require(int(gate.get_presentation_debug_state().travel_call_count) == 0, "inactive body entry triggered travel")
	entry_gate.interact(actor)
	_require(entry_gate.presentation_state == GothicCompoundTravelGate.PresentationState.ACTIVATING, "first interaction skipped boot activation")
	await create_timer(0.2).timeout
	_require(int(entry_gate.get_presentation_debug_state().travel_call_count) == 0, "travel began before boot completed")
	await create_timer(0.55).timeout
	_require(map.is_travel_route_active(), "successful boot did not activate shared route")
	_require(entry_gate.presentation_state == GothicCompoundTravelGate.PresentationState.ACTIVE, "entry frame did not reach ACTIVE before travel")
	_require(int(entry_gate.get_presentation_debug_state().last_travel_state) == GothicCompoundTravelGate.PresentationState.ACTIVE, "travel was called before ACTIVE presentation")
	_require(entry_gate.get_presentation_debug_state().travel_call_count == 1, "first activation did not travel once")
	_require(gate.presentation_state == GothicCompoundTravelGate.PresentationState.ACTIVE, "registered return endpoint did not activate")
	_require(gate.get_presentation_debug_state().production_layers.size() == 17, "route activation changed Transfer Frame art layers")
	_require(not entry_gate.is_in_group("interactable") and not gate.is_in_group("interactable"), "active route still exposes manual prompt")
	gate.call("_on_auto_travel_body_entered", actor)
	_require(int(gate.get_presentation_debug_state().travel_call_count) == 0, "arrival cooldown failed to stop immediate bounce")
	actor.global_position = map.to_global(Vector2(9999, 9999))
	await physics_frame
	for frame_index in range(26): await physics_frame
	actor.global_position = gate.global_position
	gate.call("_on_auto_travel_body_entered", actor)
	_require(int(gate.get_presentation_debug_state().travel_call_count) == 1, "active endpoint did not auto-travel after cooldown")
	_require(int(gate.get_presentation_debug_state().last_travel_state) == GothicCompoundTravelGate.PresentationState.ACTIVE, "automatic travel did not use active presentation")
	var broken_route := Node.new()
	root.add_child(broken_route)
	var failed_gate := GothicCompoundTravelGate.new()
	failed_gate.configure(broken_route, GothicCompoundTravelGate.TravelMode.ENTER_COMPOUND, "ENTER")
	root.add_child(failed_gate)
	failed_gate.interact(actor)
	_require(failed_gate.presentation_state == GothicCompoundTravelGate.PresentationState.FAILURE, "unavailable destination did not enter FAILURE")
	_require(not broken_route.has_method("is_travel_route_active"), "failed route was spuriously activated")

	if _failed:
		quit(1)
		return
	print("carrow_yard_interior_smoke: PASS interiors=east_14x10,west_12x10 provider=connected_map")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("carrow_yard_interior_smoke: " + message)
