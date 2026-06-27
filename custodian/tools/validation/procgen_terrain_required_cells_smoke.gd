extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")

const SEEDS := [420777, 420778, 420779]
const MAP_SIZE := Vector2i(112, 92)
const MAX_REASONABLE_REQUIRED_CELLS := 96


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for seed in SEEDS:
		var summary := await _generate_candidate_summary(seed)
		var required_count := int(summary.get("required_cell_count", 0))
		var missing_count := int(summary.get("missing_required_count", -1))
		assert(String(summary.get("generation_mode", "")) == "EVAL_CANDIDATE")
		assert(required_count > 0, "Expected TerrainBuilder required cells for seed %d." % seed)
		assert(required_count <= MAX_REASONABLE_REQUIRED_CELLS, "TerrainBuilder required_cells overvalidated seed %d: %d" % [seed, required_count])
		assert(bool(summary.get("connectivity_ok", false)), "Terrain connectivity failed for seed %d: %s" % [seed, str(summary)])
		assert(not bool(summary.get("fallback_used", true)), "Terrain fallback used for seed %d: %s" % [seed, str(summary)])
		assert(missing_count == 0, "TerrainBuilder still has missing required cells for seed %d: %s" % [seed, str(summary)])

	print("[ProcgenTerrainRequiredCellsSmoke] ok seeds=%s max_required=%d" % [str(SEEDS), MAX_REASONABLE_REQUIRED_CELLS])
	quit(0)


func _generate_candidate_summary(seed: int) -> Dictionary:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)
	var tilemap := map as ProcGenTilemap
	assert(tilemap != null)

	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame

	var procgen := map.get_node("ProcGen2") as ProcGen
	assert(procgen != null)
	procgen.generate_seed = false
	procgen.seed = seed
	procgen.map_size = MAP_SIZE

	tilemap.generation_evaluation_mode = true
	tilemap.generation_output_enabled = true
	tilemap.enable_streaming_reveal = false
	tilemap.build_runtime_wall_collision = false
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.enable_final_foliage = false
	tilemap.generate()

	for _frame in range(360):
		var level_data := tilemap.get_level_data()
		var terrain_data: Dictionary = level_data.get("terrain_builder", {})
		var summary: Dictionary = terrain_data.get("summary", {})
		if not summary.is_empty():
			map.queue_free()
			await process_frame
			return summary
		await process_frame

	map.queue_free()
	await process_frame
	assert(false, "Timed out waiting for procgen terrain summary for seed %d." % seed)
	return {}
