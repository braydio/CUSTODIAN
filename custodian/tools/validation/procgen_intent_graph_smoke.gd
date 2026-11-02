extends SceneTree

const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const AscentSpineBuilderScript := preload("res://game/world/procgen/intent/ascent_spine_builder.gd")
const RegionFootprintReserverScript := preload("res://game/world/procgen/intent/region_footprint_reserver.gd")


func _init() -> void:
	var profile = WorldProgressProfileScript.load_from_path("res://content/procgen/world_profiles/sundered_keep_ascent.json")
	assert(profile != null)

	var context := {
		"seed": 99111,
		"map_size": Vector2i(160, 160),
		"origin_cell": Vector2i(80, 148),
		"route_beat_count": 7,
		"world_progress_profile": profile,
	}
	var builder := AscentSpineBuilderScript.new()
	var graph = builder.call("build", context)
	assert(graph != null)
	assert(graph.nodes.size() >= 8)
	assert(graph.edges.size() >= 7)
	assert(graph.get_required_cells().size() >= 2)

	var previous_y := 999999
	for cell in graph.get_main_route_cells():
		assert(cell.x >= 0 and cell.y >= 0)
		assert(cell.x < graph.map_size.x and cell.y < graph.map_size.y)
		previous_y = mini(previous_y, cell.y)
	assert(previous_y < graph.origin_cell.y)

	var reserver := RegionFootprintReserverScript.new()
	var reservations: Dictionary = reserver.call("build_reservations", graph, graph.map_size)
	assert((reservations.get("floor_cells", {}) as Dictionary).size() > 0)
	assert((reservations.get("reserved_regions", []) as Array).size() > 0)

	var graph2 = builder.call("build", context)
	assert(JSON.stringify(graph.to_dictionary()) == JSON.stringify(graph2.to_dictionary()))

	print("procgen_intent_graph_smoke: PASS")
	quit(0)
