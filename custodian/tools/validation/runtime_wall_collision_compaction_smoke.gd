extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")


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
	procgen.generate_seed = false
	procgen.seed = 771923
	procgen.map_size = Vector2i(96, 80)
	tilemap.enable_streaming_reveal = false
	tilemap.build_runtime_wall_collision = true
	tilemap.destructible_runtime_walls = true
	tilemap.compact_runtime_wall_bodies = true
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.generate()
	for _frame in range(360):
		if not tilemap.debug_get_generated_wall_cells().is_empty():
			break
		await process_frame

	var collision_root := tilemap.walls_tilemap.get_node_or_null("RuntimeWallCollision")
	assert(collision_root != null, "Runtime wall collision root missing.")
	var body_count := collision_root.get_child_count()
	var shape_count := 0
	var target_chunk: Node = null
	for body in collision_root.get_children():
		if body.has_method("get_wall_shape_count"):
			var count := int(body.call("get_wall_shape_count"))
			shape_count += count
			if target_chunk == null and count >= 2:
				target_chunk = body
	assert(shape_count > 0, "Compacted wall collision created no shapes.")
	assert(body_count < shape_count, "Chunk compaction did not reduce wall body count below shape count.")
	assert(target_chunk != null, "Could not find a multi-tile runtime wall chunk.")
	var chunk_tiles: Array = target_chunk.call("get_wall_tiles")
	var victim := chunk_tiles[0] as Vector2i
	var neighbor := chunk_tiles[1] as Vector2i
	assert(tilemap.debug_runtime_wall_body_exists(victim))
	assert(tilemap.debug_runtime_wall_body_exists(neighbor))
	var result: Dictionary = target_chunk.call(
		"receive_projectile_hit",
		tilemap.wall_tile_max_health + 1.0,
		"player",
		tilemap.minimap_tile_to_global(victim)
	)
	assert(bool(result.get("destroyed", false)), "Chunk impact did not destroy the contacted wall tile.")
	assert(not tilemap.debug_has_wall_authority_at(victim), "Destroyed contacted tile retained wall authority.")
	assert(tilemap.debug_has_wall_authority_at(neighbor), "Chunk impact destroyed an adjacent wall tile.")
	assert(tilemap.debug_runtime_wall_body_exists(neighbor), "Adjacent wall lost collision after contacted tile destruction.")

	var indestructible_chunk := preload("res://game/world/procgen/runtime_wall_chunk.gd").new()
	root.add_child(indestructible_chunk)
	indestructible_chunk.call("setup", tilemap, Vector2i.ZERO, false)
	indestructible_chunk.call("add_wall_tile", Vector2i.ZERO, Vector2.ZERO, Vector2(16.0, 16.0))
	var indestructible_result: Dictionary = indestructible_chunk.call(
		"receive_projectile_hit", tilemap.wall_tile_max_health + 1.0, "player", Vector2.ZERO
	)
	assert(bool(indestructible_result.get("blocked", false)))
	assert(str(indestructible_result.get("reason", "")) == "indestructible_wall")
	indestructible_chunk.queue_free()

	print("[RuntimeWallCollisionCompactionSmoke] ok bodies=%d shapes=%d victim=%s neighbor=%s" % [
		body_count, shape_count, str(victim), str(neighbor),
	])
	quit(0)
