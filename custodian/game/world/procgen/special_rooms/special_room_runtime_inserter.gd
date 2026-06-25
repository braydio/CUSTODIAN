extends RefCounted
class_name SpecialRoomRuntimeInserter

const DEFAULT_DEFINITIONS_PATH := "res://content/procgen/special_rooms"


func insert_special_rooms(context: Dictionary) -> Array[Dictionary]:
	var map_instance: Node = context.get("map_instance", null)
	var parent: Node = context.get("parent", map_instance)
	if map_instance == null or parent == null:
		return []
	if not map_instance.has_method("claim_procgen_floor_rect_for_authored_scene_tiles"):
		return []

	var definitions_path := String(context.get("definitions_path", DEFAULT_DEFINITIONS_PATH))
	var definitions := _load_definitions(definitions_path)
	if definitions.is_empty():
		return []

	var level_data: Dictionary = context.get("level_data", {})
	var seed := int(context.get("seed", 0))
	var max_rooms := maxi(0, int(context.get("max_rooms", 4)))
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var floor_cells := _normalize_cell_array(level_data.get("floor_cells", []))
	if map_size == Vector2i.ZERO or floor_cells.is_empty():
		return []

	var inserted: Array[Dictionary] = []
	var occupied_rects: Array[Rect2i] = []
	var blocked_lookup := _build_blocked_lookup(level_data)
	for definition in definitions:
		if inserted.size() >= max_rooms:
			break
		if not _definition_is_eligible(definition):
			continue
		var instances := maxi(1, int(definition.get("max_instances_per_run", 1)))
		for instance_index in range(instances):
			if inserted.size() >= max_rooms:
				break
			var center := _pick_room_center(
				map_instance,
				definition,
				floor_cells,
				blocked_lookup,
				occupied_rects,
				map_size,
				seed + instance_index * 101
			)
			if center == Vector2i(-999999, -999999):
				continue
			var site := _instantiate_room(map_instance, parent, definition, center)
			if site.is_empty():
				continue
			inserted.append(site)
			occupied_rects.append(site.get("claimed_rect", Rect2i()))
			if map_instance.has_method("register_special_room_site"):
				map_instance.call("register_special_room_site", site)
	return inserted


func _load_definitions(definitions_path: String) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	var dir := DirAccess.open(definitions_path)
	if dir == null:
		push_warning("[SpecialRoomRuntimeInserter] Missing definitions folder: %s" % definitions_path)
		return definitions

	var files := dir.get_files()
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".json"):
			continue
		var path := definitions_path.path_join(file_name)
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_warning("[SpecialRoomRuntimeInserter] Could not read definition: %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary):
			push_warning("[SpecialRoomRuntimeInserter] Invalid JSON definition: %s" % path)
			continue
		var definition: Dictionary = (parsed as Dictionary).duplicate(true)
		definition["definition_path"] = path
		definitions.append(definition)
	return definitions


func _definition_is_eligible(definition: Dictionary) -> bool:
	var scene_path := String(definition.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("[SpecialRoomRuntimeInserter] Missing special-room scene: %s" % scene_path)
		return false
	return true


func _build_blocked_lookup(level_data: Dictionary) -> Dictionary:
	var blocked := {}
	for key in ["wall_cells", "main_route_cells", "compound_ingress", "parking_zone_tiles", "main_road_tiles"]:
		for cell in _normalize_cell_array(level_data.get(key, [])):
			blocked[cell] = true
	var region_tiles: Dictionary = level_data.get("region_tiles", {})
	for tile_variant in region_tiles.keys():
		if not (tile_variant is Vector2i):
			continue
		var region_data: Variant = region_tiles[tile_variant]
		if not (region_data is Dictionary):
			continue
		var region_type := String((region_data as Dictionary).get("region_type", ""))
		var zone := String((region_data as Dictionary).get("zone", ""))
		if region_type.begins_with("compound") \
				or region_type.begins_with("interior") \
				or region_type.contains("story_room") \
				or region_type.contains("faction") \
				or region_type.contains("special_room") \
				or zone == "story_room" \
				or zone == "faction_activity" \
				or zone == "special_room" \
				or zone == "vehicle_staging":
			blocked[tile_variant] = true
	return blocked


func _pick_room_center(
	map_instance: Node,
	definition: Dictionary,
	floor_cells: Array[Vector2i],
	blocked_lookup: Dictionary,
	occupied_rects: Array[Rect2i],
	map_size: Vector2i,
	seed: int
) -> Vector2i:
	var size_tiles := _definition_size_tiles(definition)
	var spawn_tile := Vector2i.ZERO
	if map_instance.has_method("get_player_spawn"):
		spawn_tile = map_instance.call("get_player_spawn") as Vector2i
	var min_spawn_distance_sq := maxi(64, int(min(map_size.x, map_size.y) * 0.24))
	min_spawn_distance_sq *= min_spawn_distance_sq

	var candidates: Array[Vector2i] = []
	for cell in floor_cells:
		if cell.distance_squared_to(spawn_tile) < min_spawn_distance_sq:
			continue
		if not _candidate_rect_is_clear(map_instance, cell, size_tiles, blocked_lookup, occupied_rects, map_size):
			continue
		candidates.append(cell)

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var score_a := _candidate_score(definition, a, seed, spawn_tile)
		var score_b := _candidate_score(definition, b, seed, spawn_tile)
		if is_equal_approx(score_a, score_b):
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		return score_a > score_b
	)
	if candidates.is_empty():
		return Vector2i(-999999, -999999)
	return candidates[0]


func _candidate_rect_is_clear(
	map_instance: Node,
	center: Vector2i,
	size_tiles: Vector2i,
	blocked_lookup: Dictionary,
	occupied_rects: Array[Rect2i],
	map_size: Vector2i
) -> bool:
	var rect := _centered_rect(center, size_tiles)
	var padded := rect.grow(2)
	if padded.position.x < 2 or padded.position.y < 2 or padded.end.x >= map_size.x - 2 or padded.end.y >= map_size.y - 2:
		return false
	for occupied in occupied_rects:
		if padded.intersects(occupied.grow(4)):
			return false
	if blocked_lookup.has(center):
		return false
	if map_instance.has_method("is_valid_spawn_cell") and not bool(map_instance.call("is_valid_spawn_cell", center)):
		return false
	return true


func _candidate_score(definition: Dictionary, cell: Vector2i, seed: int, spawn_tile: Vector2i) -> float:
	var id := String(definition.get("id", "special_room"))
	var hash_value: int = abs(("%d:%s:%d:%d" % [seed, id, cell.x, cell.y]).hash())
	var noise := float(hash_value % 100000) / 100000.0
	var distance_score := sqrt(float(cell.distance_squared_to(spawn_tile))) * 0.001
	return noise + distance_score


func _instantiate_room(map_instance: Node, parent: Node, definition: Dictionary, center: Vector2i) -> Dictionary:
	var scene_path := String(definition.get("scene_path", ""))
	var scene_resource := load(scene_path)
	if not (scene_resource is PackedScene):
		push_warning("[SpecialRoomRuntimeInserter] Scene is not a PackedScene: %s" % scene_path)
		return {}
	var size_tiles := _definition_size_tiles(definition)
	var region_type := String(definition.get("id", "special_room"))
	var claimed: Rect2i = map_instance.call(
		"claim_procgen_floor_rect_for_authored_scene_tiles",
		center,
		size_tiles,
		region_type,
		"special_room",
		1
	)
	var instance := (scene_resource as PackedScene).instantiate() as Node2D
	if instance == null:
		push_warning("[SpecialRoomRuntimeInserter] Special room scene root is not Node2D: %s" % scene_path)
		return {}
	parent.add_child(instance)
	if map_instance.has_method("minimap_tile_to_global"):
		instance.global_position = map_instance.call("minimap_tile_to_global", center) as Vector2
	else:
		instance.global_position = Vector2(center * 16)
	instance.name = "SpecialRoom_%s" % String(definition.get("id", "room")).to_pascal_case()
	var site := {
		"id": String(definition.get("id", "special_room")),
		"display_name": String(definition.get("display_name", definition.get("id", "special_room"))),
		"scene_path": scene_path,
		"center_tile": center,
		"global_position": instance.global_position,
		"size_tiles": size_tiles,
		"claimed_rect": claimed,
		"tags": (definition.get("tags", []) as Array).duplicate(),
		"rarity": String(definition.get("rarity", "unclassified")),
		"instance_path": str(instance.get_path()),
	}
	print("[SpecialRoomRuntimeInserter] Inserted %s at tile %s" % [site["id"], str(center)])
	return site


func _definition_size_tiles(definition: Dictionary) -> Vector2i:
	var raw: Variant = definition.get("size_tiles", [16, 16])
	if raw is Vector2i:
		return (raw as Vector2i).maxi(1)
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2i(maxi(1, int((raw as Array)[0])), maxi(1, int((raw as Array)[1])))
	return Vector2i(16, 16)


func _centered_rect(center: Vector2i, size_tiles: Vector2i) -> Rect2i:
	var half_extents := Vector2i(
		int(floor(float(size_tiles.x) * 0.5)),
		int(floor(float(size_tiles.y) * 0.5))
	)
	return Rect2i(center - half_extents, size_tiles)


func _normalize_cell_array(value: Variant) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if key is Vector2i:
				cells.append(key)
	elif value is Array:
		for item in value:
			if item is Vector2i:
				cells.append(item)
	return cells
