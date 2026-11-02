extends SceneTree

const ROAD_AUTHORITY := preload("res://game/world/procgen/roads/procgen_road_authority.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_state_and_graph_contract()
	_test_semantics_publication()
	_test_facade_delegation()
	if _failed:
		quit(1)
	else:
		print("procgen_road_authority_smoke: PASS")
		quit(0)


func _test_state_and_graph_contract() -> void:
	var authority = ROAD_AUTHORITY.new()
	var connected_cells := [Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5)]
	for cell in connected_cells:
		authority.add_road_tile(cell)
	authority.add_road_centerline_tile(Vector2i(6, 5))
	authority.add_path_centerline_tile(Vector2i(4, 5))
	authority.set_parking_zone_center(Vector2i(7, 5))
	authority.add_parking_tile(Vector2i(7, 5))
	authority.append_compound_connector_centerline(Vector2i(8, 5))
	authority.add_road_tile(Vector2i(20, 2))
	authority.add_road_tile(Vector2i(21, 2))
	_require(authority.is_road_tile(Vector2i(5, 5)), "road insertion/query failed")
	_require(authority.is_parking_tile(Vector2i(7, 5)), "parking insertion/query failed")
	_require(authority.connected_road_tiles(Vector2i(5, 5)).size() == 3, "connected flood differs")
	var components: Array = authority.road_surface_components()
	_require(components.size() == 2, "component partition differs")
	var largest_first: Array = authority.road_surface_components_largest_first()
	_require((largest_first[0] as Array).size() == 3, "largest-first component order differs")
	var pair: Array[Vector2i] = authority.next_component_repair_pair(
		largest_first[0] as Array[Vector2i], largest_first[1] as Array[Vector2i]
	)
	_require(pair == [Vector2i(7, 5), Vector2i(20, 2)], "nearest component repair pair differs: %s" % [pair])
	var anchor_plan: Dictionary = authority.next_required_road_anchor(
		[Vector2i(5, 5), Vector2i(21, 2)], Vector2i(5, 5), Vector2i(32, 32)
	)
	_require(anchor_plan.get("from") == Vector2i(5, 5), "repair root selection differs")
	_require(anchor_plan.get("to") == Vector2i(21, 2), "disconnected anchor selection differs")
	var edge_plan: Array[Vector2i] = authority.edge_prune_plan(Vector2i(32, 32))
	_require(edge_plan.has(Vector2i(20, 2)), "small disconnected edge component was not planned for pruning")
	var disconnected_plan: Array[Vector2i] = authority.disconnected_prune_plan(Vector2i(5, 5), 3)
	_require(disconnected_plan.size() == 2, "small disconnected component pruning differs")
	authority.clear_generated_road_tiles(Vector2i(20, 2))
	_require(not authority.is_road_tile(Vector2i(20, 2)), "road clear left canonical state")
	authority.clear_path_centerline()
	authority.clear_compound_connector_centerline()
	authority.clear_parking_tiles()
	authority.reset_generated_roads()
	_require(authority.main_road_tiles.is_empty(), "road reset left main-road state")
	_require(authority.road_centerline_tiles.is_empty(), "road reset left centerline state")
	_require(authority.compound_connector_centerline_tiles.is_empty(), "road reset left connector state")
	_require(authority.parking_zone_center == Vector2i.ZERO, "road reset left parking center")


func _test_semantics_publication() -> void:
	var authority = ROAD_AUTHORITY.new()
	var parking := {Vector2i(4, 4): true}
	var summary := {"ruined_road_cell_count": 1}
	var first := authority.publish_road_semantics(
		{Vector2i(1, 1): true}, {Vector2i(2, 2): true}, parking, true, summary
	)
	_require(first.get("parking_cell_count") == 1, "semantic parking count was not published")
	_require(authority.get_ruined_road_tiles() == [Vector2i(1, 1)], "ruined-road getter differs")
	_require(authority.get_service_hardstand_tiles() == [Vector2i(2, 2)], "hardstand getter differs")
	var existing_parking: Dictionary = authority.parking_zone_tiles.duplicate(true)
	authority.publish_road_semantics({}, {}, {}, false, {})
	_require(authority.parking_zone_tiles == existing_parking, "semantic publication replaced archived parking")
	var snapshot := authority.get_road_semantics_summary()
	snapshot.clear()
	_require(not authority.road_semantics_summary.is_empty(), "summary getter exposed mutable owner state")
	authority.clear_road_semantics()
	_require(authority.ruined_road_cells.is_empty(), "semantic reset left ruined-road state")
	_require(authority.service_hardstand_cells.is_empty(), "semantic reset left hardstand state")


func _test_facade_delegation() -> void:
	var source := FileAccess.get_file_as_string("res://game/world/procgen/proc_gen_tilemap.gd")
	for legacy_field in [
		"var _main_road_tiles",
		"var _road_centerline_tiles",
		"var _path_centerline_tiles",
		"var _compound_connector_centerline_tiles",
		"var _parking_zone_tiles",
		"var _ruined_road_cells",
		"var _service_hardstand_cells",
		"var _road_semantics_summary",
		"var _parking_zone_center",
	]:
		_require(not source.contains(legacy_field), "facade still declares canonical field %s" % legacy_field)
	_require(source.contains("var _road_authority: ProcgenRoadAuthority"), "facade does not own the focused road authority object")
	_require(source.contains("_road_authority.next_required_road_anchor("), "facade repair does not delegate to road authority")
	_require(source.contains("_road_authority.road_surface_components_largest_first()") and source.contains("_road_authority.next_component_repair_pair(primary, component)"), "component repair is not delegated")
	_require(source.contains("_road_authority.edge_prune_plan("), "edge pruning is not delegated")
	_require(source.contains("_road_authority.publish_road_semantics("), "semantic output is not published to road authority")
	_require(source.contains("var _road_visual_tiles"), "presentation-only road mask moved out of the façade")
	_require(source.contains("_remove_road_piece_decal(tile)"), "road decal realization left the façade")


func _require(condition: bool, reason: String) -> void:
	if condition:
		return
	_failed = true
	push_error(reason)
