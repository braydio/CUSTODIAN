extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEEDS := [3, 17, 41, 71, 113, 137, 181, 233]
const MAP_SIZE := Vector2i(72, 64)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var total_face_cells := 0
	var total_wall_cells := 0
	var total_wall_lip_frontiers := 0
	for seed: int in SEEDS:
		var map := MAP_SCENE.instantiate()
		root.add_child(map)
		var tilemap := map as ProcGenTilemap
		var duplicate_tilemap := map.get_node_or_null("ProcGen")
		if duplicate_tilemap != null:
			duplicate_tilemap.queue_free()
			await process_frame
		var procgen := map.get_node("ProcGen2") as ProcGen
		procgen.generate_seed = false
		procgen.seed = seed
		procgen.map_size = MAP_SIZE
		tilemap.generation_evaluation_mode = true
		tilemap.generation_output_enabled = true
		tilemap.enable_streaming_reveal = false
		tilemap.build_runtime_wall_collision = false
		tilemap.enable_final_foliage = false
		tilemap.enable_ruin_prop_spawning = false
		tilemap.interior_prop_spawning_enabled = false
		tilemap.generate()
		for _frame in range(480):
			if not tilemap.debug_get_chasm_cells().is_empty():
				break
			await process_frame

		var walls := tilemap.debug_get_generated_wall_cells()
		var chasm := tilemap.debug_get_chasm_cells()
		var face := map.get_node_or_null("VoidCliffFace") as ProcgenVoidCliffFace
		if face == null:
			_fail("Seed %d has no VoidCliffFace" % seed)
		else:
			var face_cells := face.get_used_cells()
			var debug_state := face.get_debug_state()
			total_face_cells += face_cells.size()
			total_wall_cells += walls.size()
			total_wall_lip_frontiers += int(debug_state["wall_lip_frontier_count"])
			if face_cells.is_empty():
				_fail("Seed %d produced no void fascia" % seed)
			if walls.is_empty():
				_fail("Seed %d produced no generated walls" % seed)
			if chasm.is_empty():
				_fail("Seed %d produced no chasm semantics" % seed)
			for cell: Vector2i in face_cells:
				if walls.has(cell):
					_fail("Seed %d fascia overlaps generated wall at %s" % [seed, cell])
		map.free()
		await process_frame

	if total_wall_lip_frontiers <= 0:
		_fail("Eight production seeds exercised no wall-backed fascia frontier")
	if not _errors.is_empty():
		for error: String in _errors:
			push_error("[ProcgenVoidCliffWallIntegrationSmoke] %s" % error)
		quit(1)
		return
	print(
		"procgen_void_cliff_wall_integration_smoke: PASS seeds=%d fascia=%d walls=%d wall_lips=%d"
		% [SEEDS.size(), total_face_cells, total_wall_cells, total_wall_lip_frontiers]
	)
	quit(0)


func _fail(message: String) -> void:
	_errors.append(message)
