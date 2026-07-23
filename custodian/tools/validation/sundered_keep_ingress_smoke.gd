extends SceneTree

const CONTRACT_WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")
const SECTOR_SCENE := preload("res://game/actors/sector/sector.tscn")
const TEST_CAMERA_SCRIPT := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")


func _init() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)

	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)

	var contract_map := Node.new()
	contract_map.name = "ContractMap"
	world.add_child(contract_map)
	contract_map.add_user_signal("contract_generated")

	var map_instance := Node2D.new()
	map_instance.name = "GeneratedMap"
	contract_map.add_child(map_instance)

	var connected_maps := Node2D.new()
	connected_maps.name = "ConnectedMaps"
	connected_maps.add_to_group(&"world_origin_branch")
	world.add_child(connected_maps)
	var camera := TEST_CAMERA_SCRIPT.new()
	camera.name = "Camera2D"
	camera.runtime_map = map_instance
	world.add_child(camera)

	var sectors := Node2D.new()
	sectors.name = "Sectors"
	sectors.add_to_group(&"world_origin_branch")
	sectors.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(sectors)
	var origin_sector := SECTOR_SCENE.instantiate()
	origin_sector.name = "NORTH_TRANSIT"
	origin_sector.set("sector_name", "NORTH TRANSIT")
	origin_sector.set("sector_type", "TRANSIT")
	origin_sector.set("size_tiles", Vector2i(24, 16))
	origin_sector.set("door_sides", PackedStringArray(["W", "E"]))
	sectors.add_child(origin_sector)

	var loader := CONTRACT_WORLD_LOADER_SCRIPT.new()
	loader.name = "ContractWorldLoader"
	game_root.add_child(loader)
	loader.set("world_path", NodePath("/root/GameRoot/World"))
	loader.set("fallback_tile_size", 16.0)
	loader.set("place_debug_sundered_keep_gateway", false)

	var level_data := {
		"map_size": Vector2i(96, 96),
		"compound_rect": Rect2i(40, 40, 10, 10),
		"compound_ingress": [Vector2i(45, 40)],
		"player_spawn": Vector2i(12, 12),
	}

	await process_frame
	loader.call("_attach_procgen_map", map_instance)
	var runtime_container := world.get_node_or_null("ProcGenRuntime") as Node2D
	if runtime_container != null:
		runtime_container.remove_from_group(&"world_origin_branch")
		loader.call("_attach_procgen_map", map_instance)
	loader.call("_place_registered_world_ingresses", level_data, map_instance)
	await process_frame

	var errors: Array[String] = []
	if runtime_container == null:
		errors.append("ContractWorldLoader did not create ProcGenRuntime")
	elif not runtime_container.is_in_group("world_origin_branch"):
		errors.append("dynamic ProcGenRuntime missing world_origin_branch")
	await physics_frame
	if not _origin_sector_has_wall_collision(world, sectors):
		errors.append("origin sector fixture did not create its expected wall collision")
	var ingress := world.get_node_or_null("SunderedKeepIngressSite") as Area2D
	if ingress == null:
		errors.append("SunderedKeepIngressSite missing")
	else:
		if not ingress.is_in_group("world_ingress_site"):
			errors.append("SunderedKeepIngressSite missing world_ingress_site group")
		if String(ingress.get("route_id")) != "sundered_keep" or not String(ingress.get("level_id")).is_empty():
			errors.append("SunderedKeepIngressSite is not configured exclusively for the route")
		if String(ingress.get("route_profile")) != "production":
			errors.append("SunderedKeepIngressSite route profile is not production")
		if String(ingress.get("prompt_text")) == "ENTER SUNDERED KEEP":
			errors.append("SunderedKeepIngressSite still uses generic direct gate prompt")
		var actor := Node2D.new()
		actor.name = "Operator"
		actor.add_to_group("player")
		world.add_child(actor)
		ingress.call("_enter_approach", actor)
		await process_frame
		var level_loader := world.get_node_or_null("LevelLoader")
		var approach: Node = null
		if level_loader != null:
			approach = level_loader.call("get_active_level_instance") as Node
		if approach == null:
			errors.append("WorldIngressSite did not enter the registered authored route")
		elif String(level_loader.call("get_active_level_id")) != "sundered_keep_vista_approach":
			errors.append("LevelLoader active level ID is wrong")
		var route_manager := world.get_node_or_null("RouteTraversalManager")
		if route_manager == null or String(route_manager.call("get_current_node_id")) != "vista_approach":
			errors.append("production ingress did not start the Vista route node")
		if runtime_container != null and runtime_container.visible:
			errors.append("WorldIngressSite did not hide ProcGenRuntime while approach is active")
		if runtime_container != null \
		and runtime_container.process_mode != Node.PROCESS_MODE_DISABLED:
			errors.append("WorldIngressSite did not disable ProcGenRuntime processing while approach is active")
		if connected_maps.visible:
			errors.append("WorldIngressSite did not hide ConnectedMaps while approach is active")
		if connected_maps.process_mode != Node.PROCESS_MODE_DISABLED:
			errors.append("WorldIngressSite did not disable ConnectedMaps processing while approach is active")
		_assert_origin_sector_isolated(sectors, "Vista", errors)
		await physics_frame
		if _origin_sector_has_wall_collision(world, sectors):
			errors.append("origin sector wall collision remained active during Vista")
		if route_manager != null:
			_transition_and_assert(
				route_manager,
				&"continue",
				&"return_causeway",
				actor,
				sectors,
				"Vista -> Causeway",
				errors
			)
			_transition_and_assert(
				route_manager,
				&"continue",
				&"front_gate",
				actor,
				sectors,
				"Causeway -> Front Gate",
				errors
			)
			_transition_and_assert(
				route_manager,
				&"backtrack",
				&"return_causeway",
				actor,
				sectors,
				"Front Gate -> Causeway",
				errors
			)
			_transition_and_assert(
				route_manager,
				&"backtrack",
				&"vista_approach",
				actor,
				sectors,
				"Causeway -> Vista",
				errors
			)
			if not bool(route_manager.call("request_exit", &"return_world", actor)):
				errors.append("Vista route exfil to @world_origin failed")
			if not sectors.visible \
			or sectors.process_mode != Node.PROCESS_MODE_ALWAYS:
				errors.append("origin sector was not restored exactly after route exfil")
			await physics_frame
			if not _origin_sector_has_wall_collision(world, sectors):
				errors.append("origin sector wall collision was not restored after route exfil")

	if world.get_node_or_null("SunderedKeepTravelGate") != null:
		errors.append("Normal path still placed SunderedKeepTravelGate")
	if world.get_node_or_null("DebugSunderedKeepTravelGate") != null:
		errors.append("Debug Sundered Keep gate placed while debug flag is false")
	if world.get_node_or_null("ConnectedMaps/SunderedKeepMap") != null:
		errors.append("Normal path instantiated SunderedKeepMap directly")

	if errors.is_empty():
		print("[SunderedKeepIngressSmoke] PASS")
		quit(0)
	else:
		for err in errors:
			push_error("[SunderedKeepIngressSmoke] %s" % err)
		_fail("%d checks failed" % errors.size())


func _transition_and_assert(
	route_manager: Node,
	exit_id: StringName,
	expected_node_id: StringName,
	actor: Node,
	sectors: Node2D,
	label: String,
	errors: Array[String]
) -> void:
	if not bool(route_manager.call("request_exit", exit_id, actor)):
		errors.append("%s transition failed" % label)
		return
	if route_manager.call("get_current_node_id") != expected_node_id:
		errors.append("%s did not reach %s" % [label, expected_node_id])
	_assert_origin_sector_isolated(sectors, label, errors)


func _assert_origin_sector_isolated(
	sectors: Node2D,
	label: String,
	errors: Array[String]
) -> void:
	if sectors.visible:
		errors.append("origin sector became visible during %s" % label)
	if sectors.process_mode != Node.PROCESS_MODE_DISABLED:
		errors.append("origin sector became active during %s" % label)


func _origin_sector_has_wall_collision(world: Node2D, sectors: Node2D) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var probe := CircleShape2D.new()
	probe.radius = 4.0
	query.shape = probe
	query.transform = Transform2D(0.0, Vector2(0.0, -192.0))
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for hit: Dictionary in world.get_world_2d().direct_space_state.intersect_shape(query):
		var collider := hit.get("collider") as Node
		if collider != null and sectors.is_ancestor_of(collider):
			return true
	return false


func _fail(message: String) -> void:
	push_error("[SunderedKeepIngressSmoke] %s" % message)
	quit(1)
