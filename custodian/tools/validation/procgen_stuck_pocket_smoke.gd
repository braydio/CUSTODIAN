extends SceneTree

const FOLIAGE_SPAWNER_SCRIPT := preload("res://game/world/procgen/foliage/procgen_foliage_spawner.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tilemap := ProcGenTilemap.new()
	tilemap.generation_output_enabled = false
	var procgen := ProcGen.new()
	procgen.map_size = Vector2i(64, 64)
	tilemap.procgen_node = procgen
	tilemap.add_child(procgen)
	root.add_child(tilemap)

	var floors: Dictionary = {}
	for y in range(5):
		for x in range(5):
			floors[Vector2i(x, y)] = {"source_id": 0}
	tilemap.set("_generated_floor_cells", floors)
	tilemap.set("_generated_wall_cells", {})

	var target := Vector2i(2, 2)
	var owners: Array[Node2D] = []
	for blocked_tile in [target + Vector2i.UP, target + Vector2i.RIGHT, target + Vector2i.DOWN]:
		var owner := Node2D.new()
		owner.name = "SmokeBlocker_%s_%s" % [blocked_tile.x, blocked_tile.y]
		tilemap.add_child(owner)
		owners.append(owner)
		tilemap.register_runtime_prop_blocker(blocked_tile, 0, owner, &"smoke_prop")

	assert(tilemap.has_runtime_prop_blocker_at_tile(target + Vector2i.UP))
	assert(not tilemap.is_runtime_walkable_after_props(target + Vector2i.UP))
	assert(tilemap.get_runtime_escape_neighbor_count(target) == 1)
	var detected := tilemap.validate_no_stuck_pockets(false)
	assert((detected.get("flagged", []) as Array).has(target), "Expected collision-created stuck pocket at %s: %s" % [target, detected])

	var remediated := tilemap.validate_no_stuck_pockets(true)
	assert(int(remediated.get("remediated", 0)) > 0)
	assert(tilemap.get_runtime_escape_neighbor_count(target) >= 2)
	var report := tilemap.debug_get_stuck_report_at_global(tilemap.tile_to_global_position(target))
	assert(report.has("seed") and report.has("blocker_sources") and report.has("local_collision_mask"))
	assert(int(report.get("reachable_area_tiles", 0)) >= 8)

	var route_cells := {Vector2i(10, 10): true}
	tilemap.set("_main_road_tiles", route_cells)
	assert(bool(tilemap.call("_is_inside_required_route_clearance", Vector2i(13, 10), 3)))
	assert(not bool(tilemap.call("_is_inside_required_route_clearance", Vector2i(14, 10), 3)))
	assert(bool(tilemap.call("_is_inside_tree_trunk_clearance", Vector2i(12, 10))))
	var foliage_spawner := FOLIAGE_SPAWNER_SCRIPT.new()
	var foliage_context := {
		"is_inside_tree_trunk_clearance": Callable(tilemap, "_is_inside_tree_trunk_clearance"),
		"foliage_probabilistic_tree_collision": false,
	}
	assert(not bool(foliage_spawner.call("_should_add_tree_trunk_collision", foliage_context, Vector2i(12, 10))))
	assert(bool(foliage_spawner.call("_should_add_tree_trunk_collision", foliage_context, Vector2i(20, 20))))

	var unregister_owner := Node2D.new()
	tilemap.add_child(unregister_owner)
	tilemap.register_runtime_prop_blocker(Vector2i(4, 4), 0, unregister_owner, &"tree_trunk")
	assert(tilemap.has_runtime_prop_blocker_at_tile(Vector2i(4, 4)))
	tilemap.unregister_runtime_prop_blocker(unregister_owner)
	assert(not tilemap.has_runtime_prop_blocker_at_tile(Vector2i(4, 4)))

	print("[ProcgenStuckPocketSmoke] ok detected=%d remediated=%d escape_neighbors=%d" % [
		(detected.get("flagged", []) as Array).size(),
		int(remediated.get("remediated", 0)),
		tilemap.get_runtime_escape_neighbor_count(target),
	])
	quit(0)
