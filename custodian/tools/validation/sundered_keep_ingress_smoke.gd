extends SceneTree

const CONTRACT_WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")


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
	map_instance.name = "ProcGenRuntime"
	world.add_child(map_instance)

	var connected_maps := Node2D.new()
	connected_maps.name = "ConnectedMaps"
	world.add_child(connected_maps)

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
	loader.call("_place_registered_world_ingresses", level_data, map_instance)
	await process_frame

	var errors: Array[String] = []
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
		if map_instance.visible:
			errors.append("WorldIngressSite did not hide ProcGenRuntime while approach is active")
		if map_instance.process_mode != Node.PROCESS_MODE_DISABLED:
			errors.append("WorldIngressSite did not disable ProcGenRuntime processing while approach is active")
		if connected_maps.visible:
			errors.append("WorldIngressSite did not hide ConnectedMaps while approach is active")
		if connected_maps.process_mode != Node.PROCESS_MODE_DISABLED:
			errors.append("WorldIngressSite did not disable ConnectedMaps processing while approach is active")

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


func _fail(message: String) -> void:
	push_error("[SunderedKeepIngressSmoke] %s" % message)
	quit(1)
