extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)

	var tilemap = map as ProcGenTilemap
	assert(tilemap != null)

	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	if procgen == null:
		procgen = map.find_child("ProcGen", true, false) as ProcGen
	assert(procgen != null)

	procgen.generate_seed = false
	procgen.seed = 20260615
	procgen.map_size = Vector2i(160, 160)

	tilemap.world_shape_mode = ProcGenTilemap.WorldShapeMode.ASCENT_FIELD
	tilemap.worldgen_intent_enabled = true
	tilemap.world_progression_enabled = true
	tilemap.ascent_route_enabled = true
	tilemap.story_rooms_enabled = true
	tilemap.faction_ambient_sites_enabled = true
	tilemap.generate()

	for _i in range(120):
		await process_frame

	var data: Dictionary = tilemap.get_level_data()
	assert(String(data.get("world_shape_mode", "")) == "ascent_field")
	assert(bool(data.get("worldgen_intent_enabled", false)))
	assert(not (data.get("worldgen_intent_graph", {}) as Dictionary).is_empty())
	assert(not (data.get("ascent_field_summary", {}) as Dictionary).is_empty())
	assert((data.get("main_route_cells", []) as Array).size() > 0)
	assert((data.get("worldgen_reserved_regions", []) as Array).size() > 0)
	assert((data.get("world_progress_samples", {}) as Dictionary).size() > 0)

	print("procgen_worldgen_shape_smoke: PASS")
	quit(0)
