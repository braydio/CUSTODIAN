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
	loader.call("_place_sundered_keep_connection", level_data, map_instance)
	await process_frame

	var errors: Array[String] = []
	var ingress := world.get_node_or_null("SunderedKeepIngressSite") as Area2D
	if ingress == null:
		errors.append("SunderedKeepIngressSite missing")
	else:
		if not ingress.is_in_group("world_ingress_site"):
			errors.append("SunderedKeepIngressSite missing world_ingress_site group")
		if ingress.get("approach_scene") == null:
			errors.append("SunderedKeepIngressSite has no approach_scene")
		if String(ingress.get("target_scene_path")) != "res://game/world/sundered_keep/sundered_keep_map.gd":
			errors.append("SunderedKeepIngressSite target_scene_path wrong: %s" % String(ingress.get("target_scene_path")))
		if String(ingress.get("prompt_text")) == "ENTER SUNDERED KEEP":
			errors.append("SunderedKeepIngressSite still uses generic direct gate prompt")
		var actor := Node2D.new()
		actor.name = "Operator"
		actor.add_to_group("player")
		world.add_child(actor)
		ingress.call("_enter_approach", actor)
		await process_frame
		var approach := world.get_node_or_null("sundered_keep_Approach") as Node2D
		if approach == null:
			errors.append("WorldIngressSite did not instantiate authored approach")
		elif actor.global_position.distance_to(ingress.global_position) > 0.01:
			errors.append("WorldIngressSite did not align approach entry to ingress; actor=%s ingress=%s" % [actor.global_position, ingress.global_position])

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
