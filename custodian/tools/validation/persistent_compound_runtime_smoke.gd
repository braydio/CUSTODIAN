extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = 424242
	generator.map_size = Vector2i(112, 96)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.auto_bake_nav = false
	map.generate()
	await process_frame

	var data := map.get_level_data()
	var rooms: Array = data.get("compound_rooms", [])
	var connections: Array = data.get("compound_connections", [])
	var buildings: Array = data.get("compound_buildings", [])
	var bounds: Rect2i = data.get("compound_rect", Rect2i())
	_expect(int(data.get("compound_layout_version", 0)) == 1, "semantic compound version exported")
	_expect(rooms.size() >= 10 and rooms.size() <= 13, "runtime exports 10-13 rooms")
	_expect(buildings.size() == rooms.size(), "legacy buildings mirror semantic rooms")
	_expect(connections.size() >= rooms.size() - 1, "runtime exports connected topology")
	_expect(bounds.size.x >= 64 and bounds.size.y >= 52, "runtime compound is materially larger")

	var walls := map.debug_get_generated_wall_cells()
	var floors := map.debug_get_generated_floor_cells()
	for room_variant in rooms:
		var room := room_variant as Dictionary
		var rect: Rect2i = room.get("rect", Rect2i())
		_expect(bounds.encloses(rect), "%s remains inside compound" % room.get("id", "room"))
		for door in room.get("door_cells", []):
			_expect(floors.has(door), "%s door is walkable floor" % room.get("id", "room"))
			_expect(not walls.has(door), "%s door is not a wall" % room.get("id", "room"))
	for corridor in data.get("compound_corridor_cells", []):
		if bounds.has_point(corridor):
			_expect(floors.has(corridor), "corridor cell remains floor")

	var loader := WORLD_LOADER_SCRIPT.new()
	var semantic_by_sector: Dictionary = loader.call("_compound_rooms_by_sector_id", data)
	for sector_id in ["POWER", "ARCHIVE", "DEFENSE", "STORAGE", "NORTH_TRANSIT", "SOUTH_TRANSIT"]:
		_expect(semantic_by_sector.has(sector_id), "semantic sector mapping includes %s" % sector_id)
	_expect(str(data).find("PROCGEN_SECTOR_LAYOUT") < 0, "level data contains no index semantics")

	for seed in [101, 202, 303]:
		generator.seed = seed
		var planned: Dictionary = map.call("_build_compound_layout", Vector2i(112, 96))
		_expect(bool(planned.get("valid", false)), "contract seed %d plans valid compound" % seed)
		_expect((planned.get("rooms", []) as Array).size() >= 10, "contract seed %d semantic count" % seed)

	map.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		push_error("persistent_compound_runtime_smoke failed")
		quit(1)
		return
	print("persistent_compound_runtime_smoke passed")
	quit()
