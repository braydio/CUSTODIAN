extends SceneTree

const FOLIAGE_SPAWNER_SCRIPT := preload("res://game/world/procgen/foliage/procgen_foliage_spawner.gd")
const PROP_SCENE := preload("res://content/props/ruins/scenes/ProceduralProp.tscn")
const SLAB_DEFINITION := preload("res://content/props/ruins/data/prop_definitions/slab_01.tres")
const PORTAL_DEFINITION := preload("res://content/props/ruins/data/prop_definitions/portal_ring_01.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")
	var tilemap := ProcGenTilemap.new()
	tilemap.generation_output_enabled = false
	var procgen := ProcGen.new()
	procgen.map_size = Vector2i(64, 64)
	tilemap.procgen_node = procgen
	tilemap.add_child(procgen)
	var floor_layer := TileMapLayer.new()
	floor_layer.tile_set = TileSet.new()
	floor_layer.tile_set.tile_size = Vector2i(16, 16)
	tilemap.floor_tilemap = floor_layer
	tilemap.add_child(floor_layer)
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
	if observatory != null:
		var remediation_warnings: Array = observatory.call("get_recent_warnings", 10)
		var remediation_data: Dictionary = {}
		for warning in remediation_warnings:
			if String((warning as Dictionary).get("message", "")) == "Procgen stuck pocket collision remediated.":
				remediation_data = (warning as Dictionary).get("data", {}) as Dictionary
				break
		for field in ["pocket_id", "center_cell", "cell_count", "blocker_source", "remediation_action"]:
			assert(remediation_data.has(field), "Remediation warning missing %s" % field)
	var report := tilemap.debug_get_stuck_report_at_global(tilemap.tile_to_global_position(target))
	assert(report.has("seed") and report.has("blocker_sources") and report.has("local_collision_mask"))
	assert(int(report.get("reachable_area_tiles", 0)) >= 8)

	var route_cells := {Vector2i(10, 10): true}
	tilemap.set("_main_road_tiles", route_cells)
	assert(bool(tilemap.call("_is_inside_required_route_clearance", Vector2i(13, 10), 3)))
	assert(not bool(tilemap.call("_is_inside_required_route_clearance", Vector2i(14, 10), 3)))
	var projected_source := Vector2i(12, 10)
	assert(not bool(tilemap.call("_is_inside_required_route_clearance", projected_source, 0)), "Projected-footprint smoke requires a clear anchor tile")
	var projected_world := floor_layer.to_global(floor_layer.map_to_local(projected_source))
	var protected_verdict: Dictionary = tilemap.call(
		"_validate_ruin_prop_candidate",
		SLAB_DEFINITION,
		projected_source,
		projected_world
	)
	assert(not bool(protected_verdict.get("allowed", true)), "Collision footprint crossing route must be rejected before spawn")
	assert(String(protected_verdict.get("protected_zone_type", "")) == "required_route")
	assert(not (protected_verdict.get("collision_rect_tile_footprint", []) as Array).is_empty())
	assert(protected_verdict.has("seed") and protected_verdict.has("collision_rect_global"))
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

	var existing_blocker_owner := Node2D.new()
	tilemap.add_child(existing_blocker_owner)
	var existing_source := Vector2i(20, 20)
	var existing_world := floor_layer.to_global(floor_layer.map_to_local(existing_source))
	var existing_rect: Rect2 = tilemap.call("_get_definition_collision_rect_global", SLAB_DEFINITION, existing_world)
	var existing_cells: Array = tilemap.call("_collision_cells_for_global_rect", existing_rect)
	assert(not existing_cells.is_empty())
	tilemap.register_runtime_prop_blocker(existing_cells[0], 0, existing_blocker_owner, &"smoke_existing_prop")
	var existing_verdict: Dictionary = tilemap.call(
		"_validate_ruin_prop_candidate",
		SLAB_DEFINITION,
		existing_source,
		existing_world
	)
	assert(not bool(existing_verdict.get("allowed", true)), "Candidate footprint overlapping runtime blocker must be rejected")
	assert(String(existing_verdict.get("protected_zone_type", "")) == "existing_runtime_blocker")
	tilemap.unregister_runtime_prop_blocker(existing_blocker_owner)

	var slab := PROP_SCENE.instantiate() as ProceduralProp
	slab.definition = SLAB_DEFINITION
	slab.generate_on_ready = false
	tilemap.add_child(slab)
	slab.global_position = floor_layer.to_global(floor_layer.map_to_local(Vector2i(20, 20)))
	slab.generate_variant()
	tilemap.call("_register_runtime_prop_node", slab, &"ruin_prop")
	var slab_rect := slab.get_collision_rect_global()
	var expected_cells: Array = tilemap.call("_collision_cells_for_global_rect", slab_rect)
	var blocker_sources: Dictionary = tilemap.get("_runtime_prop_blocker_sources")
	var slab_source: Dictionary = blocker_sources.get(str(slab.get_instance_id()), {})
	assert(not expected_cells.is_empty(), "Corrected slab collision must occupy runtime blocker cells")
	assert(slab_source.get("cells", []) == expected_cells, "Runtime blocker authority must use corrected global collision rect")
	assert(is_equal_approx(slab.get_collision_rect_root_local().end.y, 0.0), "Slab collision must end at its contact anchor")
	tilemap.ruin_prop_force_collision_debug = true
	tilemap.call("_observe_ruin_prop_collision", slab)
	if observatory != null:
		assert(not observatory.call("get_recent_events", 10, &"prop_collision_alignment_warning").is_empty())
		assert(int(observatory.get("gauges").get("procgen_runtime_prop_blocker_cells", 0)) > 0)

		var bad_definition := SLAB_DEFINITION.duplicate(true) as PropDefinition
		bad_definition.id = &"smoke_misaligned_slab"
		bad_definition.collision_shape_offset = Vector2(0, 8)
		var bad_prop := PROP_SCENE.instantiate() as ProceduralProp
		bad_prop.definition = bad_definition
		bad_prop.generate_on_ready = false
		tilemap.add_child(bad_prop)
		bad_prop.global_position = floor_layer.to_global(floor_layer.map_to_local(Vector2i(30, 30)))
		bad_prop.generate_variant()
		tilemap.call("_register_runtime_prop_node", bad_prop, &"ruin_prop")
		tilemap.call("_observe_ruin_prop_collision", bad_prop)
		assert(int(observatory.get("counters").get("prop_collision_alignment_warnings", 0)) >= 1)

		var protected_routes: Dictionary = tilemap.get("_main_road_tiles")
		protected_routes[expected_cells[0]] = true
		tilemap.set("_main_road_tiles", protected_routes)
		assert(bool(tilemap.call("_enforce_ruin_prop_blocker_clearance", slab)))
		assert(not tilemap.has_runtime_prop_blocker_at_tile(expected_cells[0]), "Protected route cell retained ruin prop collision")
		assert(int(observatory.get("counters").get("procgen_runtime_blockers_cleared_for_protected_zones", 0)) == 1)
		assert(int(observatory.get("counters").get("procgen_prop_candidates_rejected_protected_zone", 0)) >= 1)
		assert(int(observatory.get("counters").get("procgen_prop_candidates_rejected_existing_blocker", 0)) >= 1)
		assert(int(observatory.get("gauges").get("procgen_stuck_pockets_detected_last_generation", -1)) >= 0)

	var portal := PROP_SCENE.instantiate() as ProceduralProp
	portal.definition = PORTAL_DEFINITION
	portal.generate_on_ready = false
	tilemap.add_child(portal)
	portal.global_position = floor_layer.to_global(floor_layer.map_to_local(Vector2i(50, 50)))
	portal.generate_variant()
	tilemap.call("_register_runtime_prop_node", portal, &"ruin_prop")
	var portal_lane_tile := floor_layer.local_to_map(floor_layer.to_local(portal.global_position + Vector2(0, -47)))
	var portal_left_tile := floor_layer.local_to_map(floor_layer.to_local(portal.global_position + Vector2(-53.5, -47)))
	var portal_right_tile := floor_layer.local_to_map(floor_layer.to_local(portal.global_position + Vector2(49.5, -47)))
	assert(not tilemap.has_runtime_prop_blocker_at_tile(portal_lane_tile), "Portal multi-shape blocker union filled its center lane")
	assert(tilemap.has_runtime_prop_blocker_at_tile(portal_left_tile))
	assert(tilemap.has_runtime_prop_blocker_at_tile(portal_right_tile))
	assert(not bool(tilemap.call("_enforce_ruin_prop_blocker_clearance", portal)), "Portal authored side blockers must be clearance-exempt")

	print("[ProcgenStuckPocketSmoke] ok detected=%d remediated=%d escape_neighbors=%d" % [
		(detected.get("flagged", []) as Array).size(),
		int(remediated.get("remediated", 0)),
		tilemap.get_runtime_escape_neighbor_count(target),
	])
	quit(0)
