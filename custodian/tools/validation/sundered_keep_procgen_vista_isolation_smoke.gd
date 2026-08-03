extends SceneTree

## Sundered Keep procgen vista isolation smoke.
##
## Production authority: the authored `sundered_keep_vista_approach` owns all
## Sundered Keep presentation (ocean/storm plate, fortress, reveal). Procgen
## owns only ordinary terrain plus a compact walkable north-edge overlook
## pocket for the registered ingress. The generated procgen frontage and its
## presentation layer are debug-only, gated behind
## `debug_spawn_sundered_keep_procgen_vista` /
## `debug_enable_sundered_keep_procgen_frontage`.
##
## This smoke runs the production configuration (both flags false) and asserts
## that no generated Sundered Keep presentation is ever layered behind the
## live procgen world or the active approach.

const CONTRACT_WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")
const SECTOR_SCENE := preload("res://game/actors/sector/sector.tscn")
const TEST_CAMERA_SCRIPT := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")
const OVERLOOK_POCKET_MAP_SCRIPT := preload("res://tools/validation/fixtures/world_overlook_pocket_map.gd")

const PRESENTATION_NODE_NAMES: Array[String] = [
	"SunderedKeepProcgenFrontagePresentation",
]
const OCEAN_OR_STORM_NAME_FRAGMENTS: Array[String] = ["Ocean", "Storm"]
const GENERATED_VISTA_GROUPS: Array[String] = [
	"generated_sundered_keep_world_vista",
	"generated_sundered_keep_procgen_frontage",
]


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

	var map_instance := OVERLOOK_POCKET_MAP_SCRIPT.new()
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
	# Production configuration: the debug procgen vista stays off, so the
	# loader must never create generated Sundered Keep presentation.
	loader.set("debug_spawn_sundered_keep_procgen_vista", false)

	# Production level data carries NO `sundered_keep_frontage` entry; the
	# authored approach supplies all Sundered Keep content.
	var level_data := {
		"map_size": Vector2i(96, 96),
		"compound_rect": Rect2i(40, 40, 10, 10),
		"compound_ingress": [Vector2i(45, 40)],
		"player_spawn": Vector2i(12, 12),
		"floor_cells": _floor_cells(),
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
	if runtime_container != null:
		if not runtime_container.visible:
			errors.append("ProcGenRuntime is not visible before route entry")
		if runtime_container.process_mode != Node.PROCESS_MODE_INHERIT:
			errors.append("ProcGenRuntime process mode is not INHERIT before route entry")
	if world.get_node_or_null("WorldLandmarks") != null:
		errors.append("production procgen world created WorldLandmarks branch")

	_assert_no_generated_sundered_keep_presentation(
		runtime_container, "ProcGenRuntime", errors
	)
	_assert_no_generated_sundered_keep_presentation(
		contract_map, "ContractMap", errors
	)

	var ingress := world.get_node_or_null("SunderedKeepIngressSite") as Area2D
	if ingress == null:
		errors.append("SunderedKeepIngressSite missing")
	else:
		if not ingress.is_in_group("world_ingress_site"):
			errors.append("SunderedKeepIngressSite missing world_ingress_site group")
		if String(ingress.get("route_id")) != "sundered_keep" \
		or not String(ingress.get("level_id")).is_empty():
			errors.append("SunderedKeepIngressSite is not configured exclusively for the route")
		if String(ingress.get("route_profile")) != "production":
			errors.append("SunderedKeepIngressSite route profile is not production")
		if String(ingress.get("prompt_text")) != "ENTER SUNDERED KEEP":
			errors.append("SunderedKeepIngressSite does not identify the real Keep ingress")
		var world_tile := _tile_of_world_position(
			ingress.global_position,
			map_instance
		)
		if not _is_north_edge_floor_cell(world_tile, level_data):
			errors.append(
				"ingress does not stand on a valid north-edge procgen floor tile"
			)
		elif (
			int(ingress.get_meta("world_ingress_edge_distance_tiles", -1))
			!= world_tile.y
		):
			errors.append("ingress edge-distance metadata does not match its floor tile")
		if int(map_instance.get("authored_pocket_count")) == 0:
			errors.append("spawner did not author the world-overlook pocket")

		var route_manager := world.get_node_or_null("RouteTraversalManager")
		if route_manager == null:
			errors.append("registered ingress did not create RouteTraversalManager")
		elif route_manager.call("has_active_route"):
			errors.append("registered ingress started a route before crossing")

		var actor := Node2D.new()
		actor.name = "Operator"
		actor.add_to_group("player")
		world.add_child(actor)
		var origin_actor_position := Vector2(176.0, 224.0)
		actor.global_position = origin_actor_position
		camera.follow_target = actor
		camera.presentation_framing = false
		camera.presentation_bounds_override = Rect2()
		var origin_connected_maps_visible := connected_maps.visible
		var origin_connected_maps_process_mode := connected_maps.process_mode
		ingress.call("_enter_approach", actor)
		await process_frame
		await physics_frame
		# The authored approach builds mapper collision through its deferred
		# physics setup after the route transaction activates the scene.
		await process_frame
		await process_frame

		var level_loader := world.get_node_or_null("LevelLoader")
		var approach: Node = null
		if level_loader != null:
			approach = level_loader.call("get_active_level_instance") as Node
		if approach == null:
			errors.append("WorldIngressSite did not enter the registered authored route")
		elif String(level_loader.call("get_active_level_id")) != "sundered_keep_vista_approach":
			errors.append("LevelLoader active level ID is wrong")
		if route_manager == null \
		or String(route_manager.call("get_current_node_id")) != "vista_approach":
			errors.append("production ingress did not start Approach and Outskirts")
		if runtime_container != null:
			if runtime_container.visible:
				errors.append("WorldIngressSite did not hide ProcGenRuntime while approach is active")
			if runtime_container.process_mode != Node.PROCESS_MODE_DISABLED:
				errors.append("WorldIngressSite did not disable ProcGenRuntime processing while approach is active")
		if connected_maps.visible:
			errors.append("WorldIngressSite did not hide ConnectedMaps while approach is active")
		if connected_maps.process_mode != Node.PROCESS_MODE_DISABLED:
			errors.append("WorldIngressSite did not disable ConnectedMaps processing while approach is active")
		if approach != null:
			if not approach.visible:
				errors.append("authored approach is not visible while active")
			if approach.process_mode == Node.PROCESS_MODE_DISABLED:
				errors.append("authored approach is not active while on route")
			if (
				not approach.has_method("get_boundary_collision_shape_count")
				or int(approach.call("get_boundary_collision_shape_count")) <= 0
			):
				errors.append(
					"authored approach boundary collision has no rails "
					+ "(segments=%d, ready=%s)"
					% [
						(approach.call("get_boundary_segments") as Array).size(),
						str(approach.call("is_visual_ready")),
					]
				)

		# While the authored approach is live, no generated presentation may
		# layer behind it either.
		_assert_no_generated_sundered_keep_presentation(
			runtime_container, "ProcGenRuntime(route)", errors
		)
		_assert_no_generated_sundered_keep_presentation(
			contract_map, "ContractMap(route)", errors
		)

		if route_manager != null:
			if not bool(route_manager.call("request_exit", &"return_world", actor)):
				errors.append("Approach return to @world_origin failed")
			await physics_frame
			await process_frame
			await process_frame
			if runtime_container != null:
				if not runtime_container.visible:
					errors.append("ProcGenRuntime not restored visible after exfil")
				if runtime_container.process_mode != Node.PROCESS_MODE_INHERIT:
					errors.append("ProcGenRuntime process mode not restored to INHERIT after exfil")
			if connected_maps.visible != origin_connected_maps_visible \
			or connected_maps.process_mode != origin_connected_maps_process_mode:
				errors.append("ConnectedMaps was not restored exactly after route exfil")
			if not actor.global_position.is_equal_approx(origin_actor_position):
				errors.append("Operator position was not restored after route exfil")
			if camera.follow_target != actor:
				errors.append("Operator-follow camera target was not restored")
			if camera.presentation_framing:
				errors.append("camera presentation framing remained active after exfil")
			if camera.presentation_bounds_override != Rect2():
				errors.append("camera presentation bounds were not cleared after exfil")

	if world.get_node_or_null("SunderedKeepTravelGate") != null:
		errors.append("Normal path still placed SunderedKeepTravelGate")
	if world.get_node_or_null("DebugSunderedKeepTravelGate") != null:
		errors.append("Debug Sundered Keep gate placed while debug flag is false")
	if world.get_node_or_null("ConnectedMaps/SunderedKeepMap") != null:
		errors.append("Normal path instantiated SunderedKeepMap directly")

	if errors.is_empty():
		print("[SunderedKeepProcgenVistaIsolationSmoke] PASS")
		quit(0)
	else:
		for err in errors:
			push_error("[SunderedKeepProcgenVistaIsolationSmoke] %s" % err)
		_fail("%d checks failed" % errors.size())


## The north-edge overlook floor: a walkable column at x=45 from the edge
## (y=2) down through the approach corridor, plus compound-area floor.
func _floor_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(2, 16):
		cells.append(Vector2i(45, y))
	for y in range(38, 44):
		cells.append(Vector2i(45, y))
	cells.append(Vector2i(44, 40))
	cells.append(Vector2i(46, 40))
	return cells


func _tile_of_world_position(position: Vector2, map_instance: Node) -> Vector2i:
	var tile_size := 16.0
	if map_instance is Node2D:
		var local := position - (map_instance as Node2D).global_position
		return Vector2i(
			int(floor(local.x / tile_size)),
			int(floor(local.y / tile_size))
		)
	return Vector2i(
		int(floor(position.x / tile_size)),
		int(floor(position.y / tile_size))
	)


func _is_north_edge_floor_cell(tile: Vector2i, level_data: Dictionary) -> bool:
	var max_edge_distance := int(level_data.get("max_edge_distance_tiles", 8))
	var floor_cells: Array = level_data.get("floor_cells", [])
	return tile.y >= 0 and tile.y <= max_edge_distance and floor_cells.has(tile)


func _assert_no_generated_sundered_keep_presentation(
	branch: Node,
	label: String,
	errors: Array[String]
) -> void:
	if branch == null:
		return
	for node in _all_descendants(branch):
		if (
			node.name in PRESENTATION_NODE_NAMES
			or _in_any_group(node, GENERATED_VISTA_GROUPS)
		):
			errors.append(
				"%s still hosts generated Sundered Keep presentation: %s"
				% [label, node.name]
			)
		if node is Sprite2D:
			var node_name := String(node.name)
			for fragment in OCEAN_OR_STORM_NAME_FRAGMENTS:
				if fragment in node_name:
					errors.append(
						"%s hosts ocean/storm sprite: %s"
						% [label, node_name]
					)
					break


func _in_any_group(node: Node, groups: Array[String]) -> bool:
	for group: String in groups:
		if node.is_in_group(group):
			return true
	return false


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		result.append(current)
		for child in current.get_children():
			pending.append(child)
	return result


func _fail(message: String) -> void:
	push_error("[SunderedKeepProcgenVistaIsolationSmoke] %s" % message)
	quit(1)
