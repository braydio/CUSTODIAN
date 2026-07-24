extends SceneTree

const PROCGEN_MAP_SCENE := preload(
	"res://game/world/procgen/proc_gen_map.tscn"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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
	procgen.seed = 824771
	procgen.map_size = Vector2i(128, 112)

	tilemap.enable_streaming_reveal = false
	tilemap.foliage_deferred_spawn_enabled = false
	tilemap.enable_final_foliage = true
	tilemap.route_playability_enabled = true
	tilemap.route_floor_cleanup_enabled = true
	tilemap.route_presentation_enabled = true
	tilemap.generate()

	for _frame in range(480):
		if not tilemap.debug_get_generated_floor_cells().is_empty():
			break
		await process_frame

	var playability := tilemap.debug_get_route_playability()
	assert(not playability.is_empty())
	assert(
		String(playability.get("schema", ""))
		== "custodian.procgen_playability.v1"
	)
	var hard: Dictionary = playability.get("hard_clearance_cells", {})
	var shoulder: Dictionary = playability.get("shoulder_cells", {})
	var sparse: Dictionary = playability.get("sparse_dressing_cells", {})
	assert(not hard.is_empty())
	assert(not shoulder.is_empty())
	assert(not sparse.is_empty())

	var level_data := tilemap.get_level_data()
	var route: Array = level_data.get("main_route_cells", [])
	var centerline: Array = level_data.get(
		"main_route_centerline_cells",
		[]
	)
	assert(not route.is_empty())
	assert(not centerline.is_empty())

	var road_tiles: Array[Vector2i] = tilemap.get_main_road_tiles()
	var road_lookup: Dictionary = {}
	for cell in road_tiles:
		road_lookup[cell] = true
	var presented_centerline := 0
	var missing_centerline: Array[Vector2i] = []
	for cell_variant in centerline:
		var cell := cell_variant as Vector2i
		if road_lookup.has(cell):
			presented_centerline += 1
		else:
			missing_centerline.append(cell)
	var audit := tilemap.debug_run_route_playability_audit()
	var presented_ratio := float(presented_centerline) / float(
		maxi(1, centerline.size())
	)
	assert(
		presented_ratio >= 0.70,
		"At least 70%% of ascent centerline must receive road presentation: "
		+ "%d/%d missing=%s audit=%s"
		% [
			presented_centerline,
			centerline.size(),
			str(missing_centerline.slice(0, 12)),
			str(audit),
		]
	)
	for cell in missing_centerline:
		assert(
			bool(tilemap.call("_should_preserve_route_role_visual", cell)),
			"Unpresented centerline cell lacks a role/elevation visual: %s"
			% str(cell)
		)

	for cell_variant in hard.keys():
		var cell := cell_variant as Vector2i
		assert(
			not tilemap.debug_can_place_foliage_at(cell),
			"Hard-clearance cell accepts foliage: %s" % str(cell)
		)

	assert(
		bool(audit.get("ok", false)),
		"Post-decoration playability audit failed: %s" % str(audit)
	)
	assert(int(audit.get("minimum_route_width", 0)) >= 7)

	print(
		"procgen_route_clearance_smoke: PASS route=%d centerline=%d hard=%d"
		% [route.size(), centerline.size(), hard.size()]
	)
	quit(0)
