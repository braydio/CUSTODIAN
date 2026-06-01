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
	_assert(map.get_node_or_null("Collision/MainPortcullisBlocker") != null, "closed portcullis blocker missing")

	var floors := _collect_walkable_floor_tiles(map)
	_assert(floors.has(Vector2i(56, 76)), "spawn tile is not walkable")
	_assert(floors.has(Vector2i(41, 58)), "return mooring center is not walkable")
	_assert(floors.has(Vector2i(73, 56)), "key/winch tile is not walkable")

	_assert(not _has_blocker_covering_tile(map, Vector2i(56, 76)), "spawn tile is blocked")
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
	_assert(map.get_node_or_null("Collision/MainPortcullisBlocker") == null, "main gate blocker remained after opening")
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


func _array_to_vector2i(value) -> Vector2i:
	if not (value is Array) or (value as Array).size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))
