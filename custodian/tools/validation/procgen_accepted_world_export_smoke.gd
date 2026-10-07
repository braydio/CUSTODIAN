extends SceneTree

# Parity smoke for the accepted-world capture/export owner. The expected hashes
# were captured from ProcGenTilemap before the extraction (see
# PROCGEN_GENERATION_STATE_EXTRACTION_CLAUDE_SUMMARY.md); they must not change
# unless a versioned level-data migration is intended and explicitly tested.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEED := 3716816988
const MAP_SIZE := Vector2i(72, 64)
const EXPECTED_LEVEL_DATA_HASH := "2068075335"
const EXPECTED_FINGERPRINT_HASH := "2896026968"
const EXPECTED_LEVEL_DATA_KEY_COUNT := 69


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)
	var tilemap := map as ProcGenTilemap
	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame
	var procgen := map.get_node("ProcGen2") as ProcGen
	procgen.generate_seed = false
	procgen.seed = SEED
	procgen.map_size = MAP_SIZE
	tilemap.generation_evaluation_mode = true
	tilemap.generation_output_enabled = true
	tilemap.enable_streaming_reveal = true
	tilemap.build_runtime_wall_collision = false
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.enable_final_foliage = false
	tilemap.enable_ruin_prop_spawning = false
	tilemap.interior_prop_spawning_enabled = false
	tilemap.generate()
	for _frame in range(360):
		if bool(tilemap.get("_evaluated_candidate_ready")):
			break
		await process_frame
	if not bool(tilemap.get("_evaluated_candidate_ready")):
		_fail("timed out waiting for evaluated candidate state")
		return

	var level_data := tilemap.get_level_data()
	var fingerprint := tilemap.debug_get_runtime_authoring_fingerprint()
	# Excluded from the value hash: random_floor_tiles is RNG-sampled by design,
	# health is timing counters, foliage holds live Node references. They are
	# checked structurally below instead.
	var hashed_level_data := level_data.duplicate(true)
	hashed_level_data.erase("random_floor_tiles")
	var hashed_fingerprint := fingerprint.duplicate(true)
	hashed_fingerprint.erase("foliage")
	hashed_fingerprint.erase("health")
	var level_hash := _stable_hash(hashed_level_data)
	var fingerprint_hash := _stable_hash(hashed_fingerprint)
	if OS.get_environment("PARITY_KEYS") != "":
		for key in level_data.keys():
			print("KEY ", key, " ", _stable_hash(level_data[key]))
		for key in fingerprint.keys():
			print("FPKEY ", key, " ", _stable_hash(fingerprint[key]))
	print("PARITY level_data_hash=", level_hash, " fingerprint_hash=", fingerprint_hash, " keys=", level_data.size())

	var failures: Array[String] = []
	if EXPECTED_LEVEL_DATA_HASH == "__BASELINE__":
		print("PARITY baseline capture mode")
	else:
		if level_hash != EXPECTED_LEVEL_DATA_HASH:
			failures.append("level data hash drifted: %s" % level_hash)
		if fingerprint_hash != EXPECTED_FINGERPRINT_HASH:
			failures.append("runtime authoring fingerprint hash drifted: %s" % fingerprint_hash)
		if level_data.size() != EXPECTED_LEVEL_DATA_KEY_COUNT:
			failures.append("level data key count drifted: %d" % level_data.size())
	var floor_cells := tilemap.debug_get_generated_floor_cells()
	var random_tiles: Array = level_data.get("random_floor_tiles", [])
	if random_tiles.is_empty() or random_tiles.size() > 20:
		failures.append("random_floor_tiles size unexpected: %d" % random_tiles.size())
	for tile in random_tiles:
		if not floor_cells.has(tile):
			failures.append("random_floor_tiles contains non-floor tile %s" % str(tile))
			break
	if not fingerprint.has("health") or not fingerprint.has("foliage"):
		failures.append("runtime authoring fingerprint lost health/foliage keys")
	# Exports are detached: mutating them must not reach the runtime store.
	var exported_floor := tilemap.debug_get_generated_floor_cells()
	exported_floor.clear()
	if tilemap.debug_get_generated_floor_cells().size() != floor_cells.size():
		failures.append("debug floor export aliases the runtime generated-floor store")
	var exported_cells: Array = level_data.get("floor_cells", [])
	if exported_cells.size() != floor_cells.size():
		failures.append("level data floor_cells count != captured floor cells")
	# ProcGenTilemap must delegate capture/export to the single owner.
	var host_source := FileAccess.get_file_as_string("res://game/world/procgen/proc_gen_tilemap.gd")
	for forbidden in [
		"func _get_terrain_builder_level_data",
		"\"compound_layout_version\":",
	]:
		if host_source.contains(forbidden):
			failures.append("ProcGenTilemap still owns extracted export logic: %s" % forbidden)
	var capture_start := host_source.find("func _capture_generated_tile_state")
	var capture_body := host_source.substr(capture_start, host_source.find("\nfunc ", capture_start + 10) - capture_start)
	if not capture_body.contains("ACCEPTED_WORLD_EXPORT_SCRIPT.capture_tile_state") or capture_body.contains("get_cell_source_id"):
		failures.append("_capture_generated_tile_state does not delegate to the export owner")
	if floor_cells.is_empty():
		failures.append("accepted floor capture is empty")
	if failures.is_empty():
		print("PROCGEN_ACCEPTED_WORLD_EXPORT_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _stable_hash(value: Variant) -> String:
	return str(var_to_str(_normalize(value)).hash())


func _normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var keys := (value as Dictionary).keys()
		keys.sort_custom(func(a, b): return var_to_str(a) < var_to_str(b))
		var out: Array = []
		for key in keys:
			out.append([var_to_str(key), _normalize((value as Dictionary)[key])])
		return out
	if value is Array:
		var out_array: Array = []
		for item in value:
			out_array.append(_normalize(item))
		return out_array
	if value is Object:
		return "<object>"
	return value


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
