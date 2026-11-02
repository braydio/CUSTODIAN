extends SceneTree

const PROCGEN_MAP_SCENE := preload(
	"res://game/world/procgen/proc_gen_map.tscn"
)
const OUTPUT_DIRECTORY := (
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines"
)
const SEEDS: Array[int] = [1, 17, 71]
const MAP_SIZE := Vector2i(176, 176)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	for seed_value in SEEDS:
		var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
		root.add_child(map)
		if not map.is_node_ready():
			await map.ready
		var duplicate := map.get_node_or_null("ProcGen")
		if duplicate != null:
			duplicate.queue_free()
			await process_frame
		var procgen := map.get_node("ProcGen2") as ProcGen
		procgen.auto_generate_on_ready = false
		procgen.generate_seed = false
		procgen.seed = seed_value
		procgen.map_size = MAP_SIZE
		map.procgen_node = procgen
		map.generation_output_enabled = true
		map.enable_streaming_reveal = false
		map.build_runtime_wall_collision = false
		map.enable_final_foliage = false
		map.generate()
		for _frame in range(3):
			await process_frame
		var output_path := ProjectSettings.globalize_path(
			OUTPUT_DIRECTORY.path_join("seed_%03d.json" % seed_value)
		)
		var error: Error = map.debug_save_sundered_keep_shoreline_fixture(
			output_path
		)
		if error != OK:
			push_error("Could not export seed %d shoreline fixture: %s" % [seed_value, error_string(error)])
			quit(1)
			return
		print("[ShorelineFixtureExport] seed=%d path=%s" % [seed_value, output_path])
		map.queue_free()
		await process_frame
	quit(0)
