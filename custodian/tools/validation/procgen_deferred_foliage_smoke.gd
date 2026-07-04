extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEED := 420779
const MAP_SIZE := Vector2i(96, 80)


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
	procgen.seed = SEED
	procgen.map_size = MAP_SIZE

	tilemap.generation_evaluation_mode = false
	tilemap.generation_output_enabled = true
	tilemap.enable_streaming_reveal = false
	tilemap.build_runtime_wall_collision = false
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.enable_final_foliage = true
	tilemap.foliage_deferred_spawn_enabled = true
	tilemap.foliage_spawn_batch_size = 64
	tilemap.generate()

	for _frame in range(180):
		var pending: Array = tilemap.get("_pending_foliage_tiles")
		var nodes: Dictionary = tilemap.get("_foliage_nodes")
		if pending.is_empty() and not nodes.is_empty():
			print("[ProcgenDeferredFoliageSmoke] ok placed=%d batch_size=%d" % [nodes.size(), tilemap.foliage_spawn_batch_size])
			map.queue_free()
			await process_frame
			quit(0)
			return
		await process_frame

	map.queue_free()
	await process_frame
	assert(false, "Timed out waiting for deferred foliage batches to complete.")
	quit(1)
