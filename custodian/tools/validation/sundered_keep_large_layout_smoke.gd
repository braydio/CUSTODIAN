extends SceneTree

const SUNDERED_KEEP_MAP := preload("res://game/world/sundered_keep/sundered_keep_map.gd")
const LEVEL_PATH := "res://content/levels/sundered_keep/sundered_keep_front_gate_large.json"
const TILE_SIZE := 32.0


func _init() -> void:
	var level_data := _load_level_data()
	_assert(not level_data.is_empty(), "large front-gate JSON did not load")
	var map_size := _array_to_vector2i(level_data.get("map_size_tiles", [0, 0]))
	_assert(map_size.x >= 96 and map_size.y >= 72, "map size is below large-layout minimum")

	var map := SUNDERED_KEEP_MAP.new()
	root.add_child(map)
	await process_frame

	var state := map.get_sundered_keep_debug_state()
	_assert(str(state["level_id"]) == "sundered_keep_front_gate_large", "map did not build the large front-gate level")
	_assert(int(state["missing_assets"]) == 0, "large layout has missing asset references")
	_assert(int(state["floor_sprites"]) > 500, "large layout placed too few floor sprites")
	_assert(int(state["wall_sprites"]) > 40, "large layout placed too few wall sprites")
	_assert(int(state["interactable_areas"]) >= 4, "expected mooring, key, gate, and Great Hall interactables")
	_assert(state["main_gate_open"] == false, "main gate must start closed")
	_assert(state["great_hall_door_open"] == false, "Great Hall door must start closed")
	_assert(state["return_mooring_created"] == true, "return mooring module was not created")
	_assert(map.get_node_or_null("ReturnMooringInteraction") != null, "return mooring interaction missing")
	_assert(map.get_node_or_null("SunderedGateKeyPickup") != null, "Sundered Gate Key pickup missing")
	_assert(map.get_node_or_null("MainGateInteraction") != null, "main gate interaction missing")
	_assert(map.get_node_or_null("Collision/PrefabGatehouseGateBlocker") != null, "closed prefab gate blocker missing")

	var floors := _collect_walkable_floor_tiles(map)
	var minimap_data: Dictionary = map.call("get_level_data")
	_assert(minimap_data.get("map_size", Vector2i.ZERO) == map_size, "Sundered Keep minimap data did not export map size")
	_assert((minimap_data.get("floor_cells", []) as Array).size() >= 500, "Sundered Keep minimap data exported too few floor cells")
	_assert((minimap_data.get("wall_cells", []) as Array).size() >= 40, "Sundered Keep minimap data exported too few wall cells")
	_assert(map.call("global_to_minimap_tile", Vector2(56.5 * TILE_SIZE, 76.5 * TILE_SIZE)) == Vector2i(56, 76), "Sundered Keep minimap global-to-tile conversion failed")
	_assert(map.call("minimap_tile_to_global", Vector2i(56, 76)) == Vector2(56.5 * TILE_SIZE, 76.5 * TILE_SIZE), "Sundered Keep minimap tile-to-global conversion failed")
	_assert(floors.has(Vector2i(56, 76)), "spawn tile is not walkable")
	_assert(floors.has(Vector2i(48, 76)), "widened west causeway edge is not walkable")
	_assert(floors.has(Vector2i(64, 76)), "widened east causeway edge is not walkable")
	_assert(floors.has(Vector2i(52, 49)), "lengthened upper causeway west edge is not walkable")
	_assert(floors.has(Vector2i(60, 49)), "lengthened upper causeway east edge is not walkable")
	_assert(floors.has(Vector2i(41, 58)), "return mooring center is not walkable")
	_assert(floors.has(Vector2i(73, 56)), "key/winch tile is not walkable")
	var raised_bridge_rect := Rect2i(Vector2i(52, 49), Vector2i(9, 21))
	_assert(int(state["elevation_cells"]) >= 300, "authored elevation regions were not loaded")
	_assert(int(state["bridge_elevation_height"]) == 1, "raised bridge debug elevation is not height 1")
	_assert(int(state["underpass_region_count"]) >= 2, "authored underpass regions were not loaded")
	_assert(int(state["shore_walk_region_count"]) >= 3, "authored lower-shore walk regions were not loaded")
	_assert(int(state["interior_occlusion_region_count"]) >= 2, "authored keep interior occlusion regions were not loaded")
	_assert(int(state["roof_occluder_count"]) >= 2, "roof occluder nodes were not created")
	_assert(map.get_elevation_at_tile(Vector2i(56, 60)) == 1, "bridge deck elevation is not height 1")
	_assert(map.get_elevation_at_tile(Vector2i(56, 76)) == 0, "lower shore/spawn elevation is not height 0")
	_assert(map.get_elevation_at_tile(Vector2i(50, 64)) == 0, "west underpass lane is not height 0")
	_assert(map.get_elevation_at_tile(Vector2i(62, 64)) == 0, "east underpass lane is not height 0")
	_assert(bool(map.call("is_tile_in_underpass_region", Vector2i(50, 64))), "west lower lane is not marked as an underpass region")
	_assert(bool(map.call("is_tile_in_underpass_region", Vector2i(62, 64))), "east lower lane is not marked as an underpass region")
	_assert(bool(map.call("is_tile_in_shore_walk_region", Vector2i(56, 76))), "spawn/lower approach is not marked as shore walk")
	_assert(map.can_traverse_elevation(Vector2i(50, 64), Vector2i(50, 65)), "west underpass lane does not allow same-height traversal")
	_assert(map.can_traverse_elevation(Vector2i(62, 64), Vector2i(62, 65)), "east underpass lane does not allow same-height traversal")
	_assert(map.can_traverse_elevation(Vector2i(56, 70), Vector2i(56, 69)), "south ramp does not bridge lower shore to raised bridge")
	_assert(map.can_traverse_elevation(Vector2i(51, 64), Vector2i(52, 64)), "west side stair does not bridge lower lane to raised bridge")
	_assert(map.can_traverse_elevation(Vector2i(61, 64), Vector2i(60, 64)), "east side stair does not bridge lower lane to raised bridge")
	_assert(not map.can_traverse_elevation(Vector2i(52, 70), Vector2i(52, 69)), "non-ramp bridge edge allows a height climb")
	_assert(_all_elevation_pockets_connected(map), "authored elevation contains isolated height pockets without a transition path")
	_assert(_stair_art_matches_elevation_transition(map), "stair art exists away from the authored ramp elevation transition")
	var causeway_surface_count := _count_sprites_with_prefix(map, "FloorDetail", "entrance_causeway_surface_")
	_assert(causeway_surface_count >= 30, "directional causeway shore/ocean edge tiles were not placed; count=%d" % causeway_surface_count)
	var raised_bridge_surface_count := _count_sprites_with_path_fragment_in_rect(map, "FloorDetail", "entrance/causeway_surfaces/", raised_bridge_rect)
	_assert(raised_bridge_surface_count == 0, "directional causeway shore/ocean edge tiles leaked onto raised bridge; count=%d" % raised_bridge_surface_count)
	var curated_causeway_floor_count := _count_sprites_with_path_fragment(map, "TerrainBase", "entrance/causeway_floors/cobblestone_")
	_assert(curated_causeway_floor_count >= 260, "curated cobblestone causeway floors were not placed; count=%d" % curated_causeway_floor_count)
	var curated_causeway_detail_count := _count_sprites_with_path_fragment(map, "FloorDetail", "entrance/causeway_floors/cobblestone_")
	_assert(curated_causeway_detail_count >= 6, "curated cobblestone causeway stair details were not placed; count=%d" % curated_causeway_detail_count)
	var curated_causeway_prop_count := _count_sprites_with_path_fragment(map, "PropsStatic", "props/sundered_keep/causeway/")
	_assert(curated_causeway_prop_count >= 4, "curated causeway props were not placed; count=%d" % curated_causeway_prop_count)
	var entrance_wall_count := _count_sprites_with_path_fragment(map, "WallsHigh", "entrance/causeway_walls/")
	entrance_wall_count += _count_sprites_with_path_fragment(map, "WallsLow", "entrance/causeway_walls/")
	_assert(entrance_wall_count >= 30, "entrance causeway wall dressing was not placed; count=%d" % entrance_wall_count)
	var placeholder_high_wall_count := _count_sprites_with_path_fragment(map, "WallsHigh", "placeholders/walls/PLACEHOLDER_sundered_keep_labyrinth_")
	var placeholder_low_wall_count := _count_sprites_with_path_fragment(map, "WallsLow", "placeholders/walls/PLACEHOLDER_sundered_keep_labyrinth_")
	_assert(placeholder_high_wall_count >= 40, "placeholder keep wall readability sprites were not placed; count=%d" % placeholder_high_wall_count)
	_assert(placeholder_low_wall_count >= 20, "placeholder void-edge readability sprites were not placed; count=%d" % placeholder_low_wall_count)
	var entrance_overlay_count := _count_sprites_with_path_fragment(map, "Overlays", "entrance/overlays/")
	_assert(entrance_overlay_count >= 4, "entrance wall overlays were not placed; count=%d" % entrance_overlay_count)
	_assert(_count_polygon_nodes_named(map, "UnderpassShadow_") >= 2, "underpass shadow overlays were not created")
	_assert(_count_sprites_with_path_fragment(map, "WallsLow", "entrance/cliffs/cliff_wall_plain_32") >= 16, "underpass cliff-face supports were not placed")
	var entrance_prop_count := _count_sprites_with_path_fragment(map, "PropsStatic", "entrance/props/")
	_assert(entrance_prop_count >= 4, "entrance-local causeway props were not placed; count=%d" % entrance_prop_count)
	var brazier_flicker_count := _count_nodes_named(map, "BrazierFlicker")
	_assert(brazier_flicker_count >= 4, "brazier flicker animations were not attached; count=%d" % brazier_flicker_count)
	var hanging_brazier_count := _count_direct_animated_children(map, "PropsStatic")
	_assert(hanging_brazier_count >= 4, "bridge hanging brazier overhang props were not placed; count=%d" % hanging_brazier_count)
	var gatehouse_prefab_count := _count_sprites_with_path_fragment(map, "WallsHigh", "entrance/prefabs/gateway_prefab_structure")
	_assert(gatehouse_prefab_count >= 1, "large prefab gatehouse was not placed")
	_assert(_count_nodes_named(map, "GatewayPrefabOpenGate") == 1, "prefab gate opening animation was not placed")
	_assert(_animated_sprite_frame_count(map, "GreatHallDoorOpenAnimation", "open") == 8, "Great Hall door prefab animation was not built as an 8-frame strip")
	_assert(_node_has_child_named(map, "GreatHallDoorOpenAnimation", "OperatorDepthSort"), "Great Hall door is missing operator-relative depth sorting")
	_assert(_count_sprites_with_path_fragment(map, "Traversal", "main_gate_portcullis_") == 0, "old small portcullis runtime sprites are still present")
	var great_hall_horizontal_carpet := _count_sprites_with_path_fragment_in_rect(map, "FloorDetail", "great_hall_carpet_runner_horizontal_01", Rect2i(Vector2i(56, 26), Vector2i(18, 2)))
	_assert(great_hall_horizontal_carpet >= 30, "Great Hall post-door carpet does not turn right into the hallway; count=%d" % great_hall_horizontal_carpet)
	_assert(_has_blocker_covering_tile(map, Vector2i(71, 25)), "Great Hall right-turn hallway north wall lacks collision")
	_assert(_has_blocker_covering_tile(map, Vector2i(71, 29)), "Great Hall right-turn hallway south wall lacks collision")
	_assert(not _has_blocker_covering_tile(map, Vector2i(71, 27)), "Great Hall right-turn hallway walking lane is blocked")
	var marine_ambush: Dictionary = state["great_hall_marine_ambush"]
	_assert(bool(marine_ambush.get("exists", false)), "Great Hall marine ambush was not spawned")
	_assert(bool(marine_ambush.get("dash_ready", false)), "Great Hall marine dash body animation is not ready")
	_assert(bool(marine_ambush.get("dash_fx_ready", false)), "Great Hall marine dash FX animation is not ready")
	var validation_operator := Node2D.new()
	validation_operator.name = "SunderedKeepValidationOperator"
	validation_operator.add_to_group("player")
	root.add_child(validation_operator)
	validation_operator.global_position = map.to_global(Vector2((56.5) * TILE_SIZE, (20.5) * TILE_SIZE))
	map.call("_update_actor_elevation")
	state = map.get_sundered_keep_debug_state()
	_assert(str(state["active_interior_region_id"]) == "great_hall", "Great Hall roof did not cut away when validation operator entered interior")
	validation_operator.global_position = map.to_global(Vector2((56.5) * TILE_SIZE, (76.5) * TILE_SIZE))
	map.call("_update_actor_elevation")
	state = map.get_sundered_keep_debug_state()
	_assert(str(state["active_interior_region_id"]).is_empty(), "Great Hall roof did not restore when validation operator left interior")
	validation_operator.queue_free()
	var ambush_node := map.get_node_or_null("GreatHallMarineAmbush")
	_assert(ambush_node != null, "GreatHallMarineAmbush node missing")
	if ambush_node != null:
		ambush_node.call("force_dash_for_validation")
		await process_frame
		var marine := map.get_node_or_null("GreatHallDashMarine")
		var marine_sprite := marine.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D if marine != null else null
		_assert(marine_sprite != null and marine_sprite.animation == "marine_dash_attack_e", "Great Hall marine did not play dash attack animation")

	_assert(not _has_blocker_covering_tile(map, Vector2i(56, 76)), "spawn tile is blocked")
	_assert(_has_blocker_covering_tile(map, Vector2i(51, 55)), "west bridge parapet wall lacks collision")
	_assert(_has_blocker_covering_tile(map, Vector2i(61, 55)), "east bridge parapet wall lacks collision")
	_assert(_has_blocker_covering_tile(map, Vector2i(45, 38)), "west labyrinth partition lacks collision")
	_assert(_has_blocker_covering_tile(map, Vector2i(67, 38)), "east labyrinth partition lacks collision")
	_assert(not _has_blocker_covering_tile(map, Vector2i(56, 43)), "central courtyard labyrinth lane is blocked")
	_assert(not _has_blocker_covering_tile(map, Vector2i(51, 64)), "west side stair opening is blocked")
	_assert(not _has_blocker_covering_tile(map, Vector2i(61, 64)), "east side stair opening is blocked")
	_assert(_reachable(map, floors, Vector2i(56, 76), Vector2i(41, 58)), "return mooring is not reachable before gate opens")
	_assert(_reachable(map, floors, Vector2i(56, 76), Vector2i(73, 56)), "key/winch is not reachable before gate opens")
	_assert(not _reachable(map, floors, Vector2i(56, 76), Vector2i(60, 39)), "courtyard is reachable before the gate opens")

	var missing_textures := _collect_missing_sprite_textures(map)
	for path in missing_textures:
		push_error("[SunderedKeepLargeLayoutSmoke] Missing Sprite2D texture: %s" % path)
	_assert(missing_textures.is_empty(), "map contains Sprite2D nodes without textures")

	map.call("_grant_sundered_gate_key")
	map.call("_try_open_main_gate")
	await process_frame
	state = map.get_sundered_keep_debug_state()
	_assert(state["main_gate_open"] == true, "main gate did not open after key acquisition")
	_assert(map.get_node_or_null("Collision/PrefabGatehouseGateBlocker") == null, "prefab gate blocker remained after opening")
	_assert(_reachable(map, floors, Vector2i(56, 76), Vector2i(60, 39)), "courtyard is not reachable after gate opens")
	_assert(state["siege_started"] == true, "opening the main gate did not start the siege state")
	_assert(str(state["siege_state"]) == "active", "siege state did not become active")
	_assert(int(state["siege_spawn_nodes"]) >= 3, "siege spawn nodes were not created")
	_assert(bool(state["siege_turret_exists"]), "gatehouse defense turret was not created")
	var objectives: Array = state["siege_objectives"]
	_assert(objectives.size() >= 2, "siege objectives were not created")
	var first_objective: Dictionary = objectives[0]
	var initial_hp := float(first_objective.get("hp", 0.0))
	map.call("_apply_siege_pressure")
	state = map.get_sundered_keep_debug_state()
	objectives = state["siege_objectives"]
	var damaged_hp := float((objectives[0] as Dictionary).get("hp", 0.0))
	_assert(damaged_hp < initial_hp, "siege pressure did not damage an objective")
	map.call("_repair_siege_objective", str((objectives[0] as Dictionary).get("id", "")))
	state = map.get_sundered_keep_debug_state()
	objectives = state["siege_objectives"]
	var repaired_hp := float((objectives[0] as Dictionary).get("hp", 0.0))
	_assert(repaired_hp > damaged_hp, "repair interaction did not restore objective state")

	_assert(_has_blocker_covering_tile(map, Vector2i(55, 30)), "Great Hall door does not start blocking its threshold")
	map.call("_try_open_great_hall_door")
	await process_frame
	state = map.get_sundered_keep_debug_state()
	_assert(state["great_hall_door_open"] == true, "Great Hall door did not open")
	_assert(not _has_blocker_covering_tile(map, Vector2i(55, 30)), "opened Great Hall door still blocks its threshold")

	var game_state := root.get_node_or_null("GameState")
	_assert(game_state != null, "GameState autoload missing for Sundered Keep game-over validation")
	if game_state != null:
		game_state.call("reset_run_state")
		map.call("_collapse_siege", "Smoke siege collapse")
		await process_frame
		state = map.get_sundered_keep_debug_state()
		_assert(str(state["siege_state"]) == "collapsed", "siege collapse did not update local siege state")
		_assert(bool(state["siege_game_over_triggered"]), "siege collapse did not mark game-over handoff")
		_assert(bool(game_state.get("game_over")), "siege collapse did not trigger global game over")
		_assert(str(game_state.get("game_over_reason")) == "Smoke siege collapse", "siege collapse did not preserve game-over reason")
		_assert(_find_node_named(root, "GameOverModal") != null, "siege collapse did not mount GameOverModal")
		game_state.call("reset_run_state")

	print("[SunderedKeepLargeLayoutSmoke] OK: large JSON layout, reachability, gate, mooring, key, and doors validated")
	quit(0)


func _load_level_data() -> Dictionary:
	var file := FileAccess.open(LEVEL_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[SunderedKeepLargeLayoutSmoke] %s" % message)
	quit(1)


func _collect_walkable_floor_tiles(map: Node) -> Dictionary:
	var floors := {}
	for layer_name in ["TerrainBase", "FloorDetail"]:
		var layer := map.get_node_or_null(layer_name)
		if layer == null:
			continue
		for child in layer.get_children():
			if not (child is Sprite2D):
				continue
			if child.name.begins_with("ocean_") or child.name == "ocean_void_01":
				continue
			var tile := Vector2i(floor((child as Sprite2D).position.x / TILE_SIZE), floor((child as Sprite2D).position.y / TILE_SIZE))
			floors[tile] = true
	return floors


func _reachable(map: Node, floors: Dictionary, start: Vector2i, goal: Vector2i) -> bool:
	var queue: Array[Vector2i] = [start]
	var seen := {start: true}
	var directions := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	while not queue.is_empty():
		var current := queue.pop_front() as Vector2i
		if current == goal:
			return true
		for direction in directions:
			var next_tile: Vector2i = current + direction
			if seen.has(next_tile) or not floors.has(next_tile) or _has_blocker_covering_tile(map, next_tile):
				continue
			seen[next_tile] = true
			queue.append(next_tile)
	return false


func _collect_missing_sprite_textures(node: Node, path := "") -> Array[String]:
	var current_path := path
	if current_path.is_empty():
		current_path = node.name
	else:
		current_path = "%s/%s" % [current_path, node.name]

	var missing: Array[String] = []
	if node is Sprite2D and (node as Sprite2D).texture == null:
		missing.append(current_path)
	for child in node.get_children():
		missing.append_array(_collect_missing_sprite_textures(child, current_path))
	return missing


func _count_sprites_with_prefix(map: Node, layer_name: String, prefix: String) -> int:
	var layer := map.get_node_or_null(layer_name)
	if layer == null:
		return 0
	var count := 0
	for child in layer.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		if sprite.name.contains(prefix):
			count += 1
			continue
		if sprite.texture != null and sprite.texture.resource_path.contains(prefix):
			count += 1
	return count


func _count_sprites_with_path_fragment(map: Node, layer_name: String, fragment: String) -> int:
	var layer := map.get_node_or_null(layer_name)
	if layer == null:
		return 0
	var count := 0
	for child in layer.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		if sprite.texture != null and sprite.texture.resource_path.contains(fragment):
			count += 1
	return count


func _count_sprites_with_path_fragment_in_rect(map: Node, layer_name: String, fragment: String, rect: Rect2i) -> int:
	var layer := map.get_node_or_null(layer_name)
	if layer == null:
		return 0
	var count := 0
	for child in layer.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		if sprite.texture == null or not sprite.texture.resource_path.contains(fragment):
			continue
		var tile := Vector2i(floor(sprite.position.x / TILE_SIZE), floor(sprite.position.y / TILE_SIZE))
		if rect.has_point(tile):
			count += 1
	return count


func _count_nodes_named(node: Node, node_name: String) -> int:
	var count := 0
	if node.name == node_name:
		count += 1
	for child in node.get_children():
		count += _count_nodes_named(child, node_name)
	return count


func _count_nodes_with_name_prefix(node: Node, prefix: String) -> int:
	var count := 0
	if node.name.contains(prefix):
		count += 1
	for child in node.get_children():
		count += _count_nodes_with_name_prefix(child, prefix)
	return count


func _count_polygon_nodes_named(node: Node, prefix: String) -> int:
	var count := 0
	if node is Polygon2D and node.name.begins_with(prefix):
		count += 1
	for child in node.get_children():
		count += _count_polygon_nodes_named(child, prefix)
	return count


func _animated_sprite_frame_count(node: Node, node_name: String, animation_name: StringName) -> int:
	if node.name == node_name and node is AnimatedSprite2D:
		var frames := (node as AnimatedSprite2D).sprite_frames
		if frames == null or not frames.has_animation(animation_name):
			return 0
		return frames.get_frame_count(animation_name)
	for child in node.get_children():
		var count := _animated_sprite_frame_count(child, node_name, animation_name)
		if count > 0:
			return count
	return 0


func _node_has_child_named(node: Node, node_name: String, child_name: String) -> bool:
	if node.name == node_name:
		return node.get_node_or_null(child_name) != null
	for child in node.get_children():
		if _node_has_child_named(child, node_name, child_name):
			return true
	return false


func _count_direct_animated_children(map: Node, layer_name: String) -> int:
	var layer := map.get_node_or_null(layer_name)
	if layer == null:
		return 0
	var count := 0
	for child in layer.get_children():
		if child is AnimatedSprite2D:
			count += 1
	return count


func _all_elevation_pockets_connected(map: Node) -> bool:
	var elevation_map: Node = map.get_elevation_map()
	if elevation_map == null:
		return false
	var cells: Dictionary = elevation_map.call("get_cells")
	var walkable_cells: Dictionary = {}
	for cell_value in cells.keys():
		if not (cell_value is Vector2i):
			continue
		var cell := cell_value as Vector2i
		if not bool(elevation_map.call("is_blocked", cell)):
			walkable_cells[cell] = true
	if walkable_cells.is_empty():
		return true
	var start := walkable_cells.keys()[0] as Vector2i
	var queue: Array[Vector2i] = [start]
	var seen := {start: true}
	var directions := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	while not queue.is_empty():
		var current := queue.pop_front() as Vector2i
		for direction in directions:
			var next_tile: Vector2i = current + direction
			if seen.has(next_tile) or not walkable_cells.has(next_tile):
				continue
			if not bool(elevation_map.call("can_traverse", current, next_tile)):
				continue
			seen[next_tile] = true
			queue.append(next_tile)
	return seen.size() == walkable_cells.size()


func _stair_art_matches_elevation_transition(map: Node) -> bool:
	var allowed_tiles := {
		Vector2i(54, 69): true,
		Vector2i(55, 69): true,
		Vector2i(56, 69): true,
		Vector2i(57, 69): true,
		Vector2i(58, 69): true,
		Vector2i(52, 63): true,
		Vector2i(52, 64): true,
		Vector2i(52, 65): true,
		Vector2i(60, 63): true,
		Vector2i(60, 64): true,
		Vector2i(60, 65): true,
		Vector2i(54, 70): true,
		Vector2i(55, 70): true,
		Vector2i(57, 70): true,
		Vector2i(58, 70): true,
	}
	for layer_name in ["TerrainBase", "FloorDetail"]:
		var layer := map.get_node_or_null(layer_name)
		if layer == null:
			continue
		for child in layer.get_children():
			if not (child is Sprite2D):
				continue
			var sprite := child as Sprite2D
			if not sprite.name.begins_with("cobblestone_stairs"):
				continue
			var tile := Vector2i(floor(sprite.position.x / TILE_SIZE), floor(sprite.position.y / TILE_SIZE))
			if not allowed_tiles.has(tile):
				return false
	return true


func _has_blocker_covering_tile(map: Node, tile: Vector2i) -> bool:
	var collision := map.get_node_or_null("Collision")
	if collision == null:
		return false
	var point := Vector2((float(tile.x) + 0.5) * TILE_SIZE, (float(tile.y) + 0.5) * TILE_SIZE)
	for child in collision.get_children():
		if not (child is StaticBody2D):
			continue
		var body := child as StaticBody2D
		for shape_node in body.get_children():
			if not (shape_node is CollisionShape2D):
				continue
			var collision_shape := shape_node as CollisionShape2D
			if not (collision_shape.shape is RectangleShape2D):
				continue
			var rect_shape := collision_shape.shape as RectangleShape2D
			var center := body.position + collision_shape.position
			var rect := Rect2(center - rect_shape.size * 0.5, rect_shape.size)
			if rect.has_point(point):
				return true
	return false


func _find_node_named(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_named(child, target_name)
		if found != null:
			return found
	return null


func _array_to_vector2i(value) -> Vector2i:
	if not (value is Array) or (value as Array).size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))
