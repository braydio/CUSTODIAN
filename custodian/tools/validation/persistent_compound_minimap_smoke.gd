extends SceneTree

const VIEW_SCRIPT := preload("res://game/ui/minimap/minimap_view.gd")
const PLANNER := preload("res://game/world/compound/rooms/persistent_compound_layout_planner.gd")

var _failed := false


func _init() -> void:
	var planner := PLANNER.new()
	_expect(planner.load_default_graph(), "semantic compound graph loads")
	var layout := planner.generate_layout(1337, Rect2i(4, 4, 64, 52), [Vector2i(20, 4), Vector2i(48, 55)])
	var view := VIEW_SCRIPT.new() as MinimapView
	view.size = Vector2(360, 260)
	root.add_child(view)
	view.set_level_data({
		"map_size": Vector2i(80, 64),
		"tile_size": Vector2(32, 32),
		"compound_rect": layout["rect"],
		"compound_ingress": layout["ingress"],
		"compound_rooms": layout["rooms"],
		"compound_connections": layout["connections"],
		"compound_buildings": layout["buildings"],
	})
	var summary := view.get_compound_layout_summary()
	_expect(bool(summary.get("semantic_layout", false)), "semantic minimap mode recognized")
	_expect(int(summary.get("room_count", 0)) == (layout["rooms"] as Array).size(), "room count matches")
	_expect(int(summary.get("connection_count", 0)) == (layout["connections"] as Array).size(), "connection count matches")
	_expect(int(summary.get("legacy_building_count", 0)) == int(summary.get("room_count", -1)), "legacy mirror retained")
	view.set_overview_mode(true)
	_expect(view.get_map_draw_rect().encloses(view.call("_tile_rect_to_panel", layout["rect"], view.get_map_draw_rect())), "semantic compound stays inside draw rect")

	view.set_level_data({
		"map_size": Vector2i(32, 32),
		"compound_rect": Rect2i(4, 4, 20, 18),
		"compound_buildings": [Rect2i(7, 7, 8, 6), Rect2i(16, 15, 6, 5)],
	})
	var legacy := view.get_compound_layout_summary()
	_expect(not bool(legacy.get("semantic_layout", true)), "legacy-only level data uses fallback")
	_expect(int(legacy.get("legacy_building_count", 0)) == 2, "legacy rectangles remain readable")
	view.size = Vector2(128, 128)
	view.queue_redraw()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		push_error("persistent_compound_minimap_smoke failed")
		quit(1)
		return
	print("persistent_compound_minimap_smoke passed")
	quit()
