extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEED := 824790
const MAP_SIZE := Vector2i(96, 96)
const VIEWPORT_SIZE := Vector2i(1600, 900)
const OUTPUT_DIR := "res://../reports/procgen_dressing_clusters"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var baseline := await _capture(false, "clusters_off")
	var composed := await _capture(true, "clusters_on")
	if baseline.is_empty() or composed.is_empty():
		quit(1)
		return
	var summary := {
		"seed": SEED,
		"baseline_foliage_count": baseline.foliage_count,
		"composed_total_foliage_count": composed.foliage_count,
		"residual_foliage_count": composed.residual_count,
		"cluster_count": composed.cluster_count,
		"cluster_child_count": composed.cluster_child_count,
		"counts_by_profile": composed.counts_by_profile,
		"route_audit_ok": composed.route_audit_ok,
		"promotion_fingerprint_matches": composed.promotion_fingerprint_matches,
		"candidate_foliage_absent": composed.candidate_foliage_absent,
		"biome_counts": composed.biome_counts,
		"surface_material_counts": composed.surface_material_counts,
		"captures": [baseline.capture, composed.capture],
	}
	var file := FileAccess.open(OUTPUT_DIR.path_join("seed_%d_summary.json" % SEED), FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "\t"))
	file.close()
	print("procgen_dressing_cluster_review: %s" % JSON.stringify(summary))
	quit(0 if composed.route_audit_ok and composed.promotion_fingerprint_matches and composed.candidate_foliage_absent else 1)

func _capture(enabled: bool, label: String) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node2D.new()
	viewport.add_child(world)
	var map := MAP_SCENE.instantiate() as ProcGenTilemap
	world.add_child(map)
	if not map.is_node_ready(): await map.ready
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var procgen := map.get_node("ProcGen2") as ProcGen
	map.procgen_node = procgen
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = SEED
	procgen.map_size = MAP_SIZE
	map.generation_output_enabled = true
	map.generation_evaluation_mode = false
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = true
	map.dressing_clusters_enabled = enabled
	map.apply_planet_world_profile({"biome_exposure_bias": 0.42})
	map.generate()
	for frame_index in range(600):
		if not map.debug_get_generated_floor_cells().is_empty(): break
		await process_frame
	for frame_index in range(4): await process_frame
	var direct_fingerprint := String(map.debug_get_dressing_cluster_summary().get("fingerprint", ""))
	var camera := Camera2D.new()
	camera.enabled = true
	camera.position = Vector2(MAP_SIZE) * 16.0
	camera.zoom = Vector2(0.27, 0.27)
	world.add_child(camera)
	for frame_index in range(6):
		RenderingServer.force_draw(false)
		await process_frame
	var path := OUTPUT_DIR.path_join("seed_%d_%s.png" % [SEED, label])
	var image := viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	var cluster_summary := map.debug_get_dressing_cluster_summary()
	var route := map.debug_run_route_playability_audit()
	var biome_counts: Dictionary = map._biome_summary.get("counts", {})
	var material_counts: Dictionary = {}
	for material: Variant in map._surface_material_by_cell.values(): material_counts[material] = int(material_counts.get(material, 0)) + 1
	var result := {
		"capture": path if error == OK else "",
		"foliage_count": map._foliage_nodes.size(),
		"residual_count": map._foliage_nodes.size() - int(cluster_summary.get("realized_child_count", 0)),
		"cluster_count": int(cluster_summary.get("placed_count", 0)),
		"cluster_child_count": int(cluster_summary.get("realized_child_count", 0)),
		"counts_by_profile": cluster_summary.get("counts_by_profile", {}),
		"route_audit_ok": bool(route.get("ok", false)),
		"promotion_fingerprint_matches": true,
		"candidate_foliage_absent": true,
		"biome_counts": biome_counts,
		"surface_material_counts": material_counts,
	}
	if enabled:
		map.generation_evaluation_mode = true
		map.generate()
		for frame_index in range(600):
			if map._evaluated_candidate_ready: break
			await process_frame
		var candidate_fingerprint := String(map.debug_get_dressing_cluster_summary().get("fingerprint", ""))
		result.candidate_foliage_absent = map._foliage_nodes.is_empty()
		map.promote_evaluated_candidate_to_final()
		for frame_index in range(4): await process_frame
		result.promotion_fingerprint_matches = direct_fingerprint == candidate_fingerprint and candidate_fingerprint == String(map.debug_get_dressing_cluster_summary().get("fingerprint", ""))
	viewport.queue_free()
	await process_frame
	return result
