extends SceneTree

const CARROW_MAP := preload("res://game/world/gothic_compound/gothic_compound_map.gd")
const ENVIRONMENT := preload("res://game/world/environment/world_environment_director.gd")
const OPERATIONS_LAYOUT := [
	"XXXXXXXXXXXXXXXXXXXX",
	"X..................X",
	"XCCCCCCC.....RRRRRRX",
	"XCCCCCCC.....RRRRRRX",
	"X..................X",
	"XKKK.......SSS.....X",
	"XKKK.......SSS.....X",
	"X..................X",
	"X..................X",
	"XWWWW..............X",
	"XWWWW..............X",
	"X..................X",
	"X..................X",
	"XXXXXXXXXDDDXXXXXXXX",
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := CARROW_MAP.new() as GothicCompoundMap
	root.add_child(map)
	await process_frame

	var ops := map.get_operations_house_debug_state() as Dictionary
	var west := map.get_west_draft_house_debug_state() as Dictionary
	var east := map.get_machine_house_debug_state() as Dictionary
	var ops_rect: Rect2 = ops.get("interior_rect", Rect2())
	var ops_layout: Array = ops.get("layout", [])
	var ops_root := ops.get("root") as Node2D
	var ops_site := (ops.get("structure_sites", {}) as Dictionary).get("operations_house", {}) as Dictionary
	_require(ops_rect.size == Vector2(640, 448), "Operations House footprint is not 20x14 at 32px")
	_require(ops_layout == OPERATIONS_LAYOUT, "Operations House grid differs from the accepted 20x14 layout")
	_require(int(ops.get("floor_tile_count", 0)) == 280, "Operations House does not have exactly 280 floor sprites")
	_require(int(ops.get("production_art_count", 0)) == 8, "Operations House production-art placement count mismatch")
	_require(bool(ops.get("has_entry_door", false)) and bool(ops.get("has_exit_door", false)), "Operations House doorway pair is incomplete")
	_require(ops_root != null and ops_root.is_in_group("carrow_operations_house_interior"), "Operations House room root or identity is missing")
	_require(ops_site.get("footprint", Vector2i.ZERO) == Vector2i(11, 10), "Operations House is not bound to the real 11x10 exterior site")
	if ops_root == null or ops_site.is_empty():
		quit(1)
		return
	_require((ops_rect.end.y < (west.get("interior_rect", Rect2()) as Rect2).position.y) or (ops_rect.position.y > (west.get("interior_rect", Rect2()) as Rect2).end.y), "Operations House room overlaps West Draft House")
	_require(map._interior_bounds_available(ops_rect, ops.get("camera_bounds", Rect2()), &"operations_house"), "Operations House bounds are not independently allocatable")
	_require(not map._interior_bounds_available(ops_rect, west.get("camera_bounds", Rect2())), "Operations House camera bounds overlap West Draft House")
	_require(not map._interior_bounds_available(ops_rect, east.get("camera_bounds", Rect2())), "Operations House camera bounds overlap East Machine House")
	_require(ops_root != null and ops_root.get_node_or_null("OperationsHouseLightingZone") is LightingZone2D, "Operations House lighting zone is missing")
	_require(ops_root != null and ops_root.get_node_or_null("DispatchDeskPracticalLight") is LightRig2D, "Operations House practical desk light is missing")
	_require(ops_root != null and ops_root.get_node_or_null("NorthStatusPanelLight") is LightRig2D, "Operations House status-panel light is missing")
	_require(ops_root != null and ops_root.get_node_or_null("CarrowOperationsEmergencySpares") is VaultStorage, "Operations House bounded spares cache is missing")
	if ops_root != null:
		var spares := ops_root.get_node("CarrowOperationsEmergencySpares") as VaultStorage
		var spares_art := ops_root.get_node("ProductionArt/EmergencySparesRack") as Sprite2D
		_require(spares.has_resources(), "Operations House spares cache has no bounded resources")
		_require(not (spares.get_node("Sprite2D") as Sprite2D).visible, "Operations House added a duplicate generic storage chest")
		_require(spares_art != null and spares.position == spares_art.position + Vector2(0.0, float(spares_art.texture.get_height()) * 0.5), "Operations House spares interaction is not anchored to its presented rack")
		for art_name in ["NorthControlBay", "NorthRecordsWall", "DispatchRelayBank", "DispatchWorkbench", "EmergencySparesRack", "MunicipalRecordsBoard", "WestLogisticsCabinet", "ServiceCart"]:
			var art := ops_root.get_node_or_null("ProductionArt/" + art_name) as Sprite2D
			_require(art != null and art.texture != null, "missing Operations House production art: %s" % art_name)
		var expected_blockers := 0
		var room_origin: Vector2i = ops.get("origin", Vector2i.ZERO)
		for y in range(OPERATIONS_LAYOUT.size()):
			var row: String = OPERATIONS_LAYOUT[y]
			for x in range(row.length()):
				var symbol := row.substr(x, 1)
				if symbol != "." and symbol != "D":
					expected_blockers += 1
		var blocker_count := 0
		for child in ops_root.get_children():
			if child is StaticBody2D and child.name.begins_with("Boundary"):
				blocker_count += 1
				var blocker_cell := Vector2i(roundi((child as Node2D).position.x / 32.0 - 0.5), roundi((child as Node2D).position.y / 32.0 - 0.5)) - room_origin
				_require(OPERATIONS_LAYOUT[blocker_cell.y].substr(blocker_cell.x, 1) not in [".", "D"], "collision occupies a clear or doorway grid cell")
		_require(blocker_count == expected_blockers, "symbol-grid collision count differs from the accepted layout")
		for y in range(4, 13):
			for x in [8, 9, 10]:
				var aisle_cell := Vector2i(x, y)
				_require(OPERATIONS_LAYOUT[y].substr(x, 1) == ".", "central circulation aisle is not open")
				var aisle_local := map._tile_to_local(room_origin + aisle_cell) + Vector2.ONE * 16.0
				for child in ops_root.get_children():
					if child is StaticBody2D and child.name.begins_with("Boundary"):
						_require((child as Node2D).position != aisle_local, "central circulation aisle has blocking collision")

	var expected_return := map._tile_to_local(ops_site.cell + Vector2i(int(ops_site.footprint.x / 2), ops_site.footprint.y + 2))
	_require(ops.get("exterior_return_position", Vector2.ZERO) == expected_return, "Operations House return position is not derived from its generated site")
	var ops_region := map.get_environment_region_at_global(map.to_global(ops_rect.get_center()))
	_require(StringName(ops_region.get("interior_id", &"")) == &"operations_house", "name-based region query did not resolve Operations House")
	_require(is_equal_approx(float(ops_region.get("environment_exposure", 1.0)), 0.10), "Operations House ambient exposure mismatch")
	_require(is_zero_approx(float(ops_region.get("weather_exposure", 1.0))), "Operations House indoor weather exposure is not zero")
	var operations_definition := map._interior_definition(&"operations_house")
	_require(map._is_valid_interior_definition(operations_definition), "valid Operations House definition failed validation")
	var malformed := operations_definition.duplicate(true)
	malformed.layout[2] = "XCCCCCC.....RRRRRRX"
	_require(not map._is_valid_interior_definition(malformed), "malformed Operations House row did not fail closed")
	malformed = operations_definition.duplicate(true)
	malformed.layout[13] = "XXXXXXXXXXXXXXXXXXXX"
	_require(not map._is_valid_interior_definition(malformed), "missing three-cell doorway did not fail closed")
	var missing_art := operations_definition.art as Array[Dictionary]
	missing_art[0]["path"] = "walls/missing_operations_house_fixture.png"
	_require(not map._interior_assets_available(operations_definition, missing_art), "missing Operations House texture did not fail closed")
	var children_before_missing_site := map.get_child_count()
	var entry_before_missing_site := map.get_node_or_null("EnterOperationsHouse")
	map._structure_sites.erase("operations_house")
	map._add_operations_house_interior(null)
	_require(map.get_child_count() == children_before_missing_site, "missing Operations House site created an orphan interior")
	_require(map.get_node_or_null("EnterOperationsHouse") == entry_before_missing_site, "missing Operations House site created an orphan entrance")
	map._structure_sites["operations_house"] = ops_site

	var actor := Node2D.new()
	actor.name = "Operator"
	root.add_child(actor)
	actor.add_to_group("player")
	var environment := ENVIRONMENT.new() as WorldEnvironmentDirector
	root.add_child(environment)
	environment.operator = actor
	environment.configure_from_contract({"contract_seed": 17, "map": {"map_seed": 29}, "world_profile": {"profile_seed": 41, "day_start_hour_min": 9.0, "day_start_hour_max": 9.0, "weather_weights": {"heavy_rain": 1.0}}}, null)
	environment.debug_force_weather("heavy_rain")
	environment.advance_environment(1.25)
	_require(float(environment.get_presentation_state().precipitation_alpha) > 0.9, "yard rain was not visible before room entry")
	var east_storage := (east.get("root") as Node2D).get_node("CarrowServicePartsLocker") as VaultStorage
	var west_storage := (west.get("root") as Node2D).get_node("CarrowDraftFilterCradle") as VaultStorage
	var ops_storage := ops_root.get_node("CarrowOperationsEmergencySpares") as VaultStorage
	east_storage.remove_resources(9999, 9999)
	west_storage.remove_resources(9999, 9999)
	ops_storage.remove_resources(9999, 9999)
	var original_actor_id := actor.get_instance_id()
	var weather_hold_before := float(environment.debug_get_state().weather_hold_remaining)
	var room_sequence: Array[StringName] = [&"east_machine_house", &"operations_house", &"west_draft_house", &"west_draft_house", &"operations_house", &"east_machine_house"]
	var entry_names := {&"east_machine_house": "EnterEastMachineHouse", &"operations_house": "EnterOperationsHouse", &"west_draft_house": "EnterWestDraftHouse"}
	var exit_names := {&"east_machine_house": "LeaveEastMachineHouse", &"operations_house": "LeaveOperationsHouse", &"west_draft_house": "LeaveWestDraftHouse"}
	for room_id in room_sequence:
		var entry := map.get_node(String(entry_names[room_id])) as CarrowMachineHouseDoor
		entry.interact(actor)
		_require(map.get_active_interior_id() == room_id, "%s entry did not set the named interior" % String(room_id))
		var room_camera: Rect2 = (map._interior_rooms[String(room_id)] as Dictionary).camera_bounds
		_require(map.get_camera_bounds() == Rect2(map.to_global(room_camera.position), room_camera.size), "%s entry did not select its own camera bounds" % String(room_id))
		_require(actor.get_instance_id() == original_actor_id, "Carrow room transition replaced the Operator")
		environment.advance_environment(1.25)
		var inside_state := environment.get_presentation_state()
		_require(is_equal_approx(float(inside_state.environment_exposure), 0.10), "%s daylight exposure mismatch" % String(room_id))
		_require(is_zero_approx(float(inside_state.weather_exposure)), "%s did not suppress weather" % String(room_id))
		_require(is_zero_approx(float(inside_state.precipitation_alpha)), "%s retained outdoor precipitation" % String(room_id))
		var occupied_position := actor.global_position
		map.enter_carrow_interior(&"stale_room_id", actor)
		_require(actor.global_position == occupied_position and map.get_active_interior_id() == room_id, "invalid room request changed an occupied room")
		var exit := (map._interior_rooms[String(room_id)] as Dictionary).root.get_node(String(exit_names[room_id])) as CarrowMachineHouseDoor
		exit.interact(actor)
		_require(map.get_active_interior_id() == &"", "%s exit did not clear the active room" % String(room_id))
		_require(actor.get_instance_id() == original_actor_id, "%s exit replaced the Operator" % String(room_id))
		var outside_region := map.get_environment_region_at_global(actor.global_position)
		_require(bool(outside_region.get("contains", false)) and not bool(outside_region.get("indoor", true)), "%s return point is not in the yard" % String(room_id))
		_require(map.get_camera_bounds() == Rect2(map.to_global(map._yard_camera_bounds.position), map._yard_camera_bounds.size), "%s exit did not restore yard camera bounds" % String(room_id))
		environment.advance_environment(1.25)
		_require(float(environment.get_presentation_state().precipitation_alpha) > 0.9, "%s exit did not restore outdoor rain" % String(room_id))
		var storage := {
			&"east_machine_house": east_storage,
			&"operations_house": ops_storage,
			&"west_draft_house": west_storage,
		}[room_id] as VaultStorage
		entry.interact(actor)
		_require(not storage.has_resources(), "%s storage refilled on same-runtime revisit" % String(room_id))
		exit.interact(actor)
		_require(map.get_active_interior_id() == &"", "%s revisit did not return outside" % String(room_id))
	_require(float(environment.debug_get_state().weather_hold_remaining) < weather_hold_before, "world weather clock stopped during interior visits")
	_require(int(east.floor_tile_count) == 140 and int(east.production_art_count) == 13, "Operations visits changed East Machine House content")
	_require(int(west.floor_tile_count) == 120 and int(west.production_art_count) == 8, "Operations visits changed West Draft House content")

	var alternate_map := CARROW_MAP.new() as GothicCompoundMap
	alternate_map.world_seed = 420777
	root.add_child(alternate_map)
	await process_frame
	var alternate_ops := alternate_map.get_operations_house_debug_state()
	_require((alternate_ops.get("structure_sites", {}) as Dictionary).has("operations_house"), "alternate seed omitted the Operations House site")
	_require(int(alternate_ops.get("floor_tile_count", 0)) == 280 and bool(alternate_ops.get("has_entry_door", false)) and bool(alternate_ops.get("has_exit_door", false)), "alternate seed did not bind a complete Operations House room")

	if _failed:
		quit(1)
		return
	print("carrow_operations_house_interior_smoke: PASS grid=20x14 floor=280 rooms=east,operations,west storage=persistent")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("carrow_operations_house_interior_smoke: " + message)
