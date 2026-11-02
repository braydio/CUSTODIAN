extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)
	var tilemap = map as ProcGenTilemap
	assert(tilemap != null)
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	if procgen == null:
		procgen = map.find_child("ProcGen", true, false) as ProcGen
	assert(procgen != null)

	procgen.generate_seed = false
	procgen.seed = 20260616
	procgen.map_size = Vector2i(176, 176)

	tilemap.world_shape_mode = ProcGenTilemap.WorldShapeMode.ASCENT_FIELD
	tilemap.worldgen_intent_enabled = true
	tilemap.world_progression_enabled = true
	tilemap.ascent_route_enabled = true
	tilemap.story_rooms_enabled = true
	tilemap.faction_ambient_sites_enabled = true
	tilemap.generate()

	for _i in range(120):
		await process_frame

	var data: Dictionary = tilemap.get_level_data()
	var summary: Dictionary = data.get("ascent_field_summary", {})
	var map_size: Vector2i = data.get("map_size", Vector2i.ZERO)
	var floor_cells: Array = data.get("floor_cells", [])
	var wall_cells: Array = data.get("wall_cells", [])
	var route_cells: Array = data.get("main_route_cells", [])
	var reserved_regions: Array = data.get("worldgen_reserved_regions", [])

	assert(String(data.get("world_shape_mode", "")) == "ascent_field")
	assert(not (data.get("worldgen_intent_graph", {}) as Dictionary).is_empty())
	assert(floor_cells.size() > 0)
	assert(route_cells.size() > 0)
	assert(float(summary.get("average_main_route_width", 0.0)) >= 9.0)
	assert(int(summary.get("terrace_count", 0)) >= 2)
	assert(_count_story_faction_regions(reserved_regions) >= 2)
	assert(float(summary.get("wall_floor_ratio", 99.0)) <= 0.45)
	assert(_route_has_uphill_span(route_cells, map_size))
	assert(_min_route_width(summary) >= 9)
	_export_debug_image(data)

	print("procgen_ascent_style_smoke: PASS summary=%s debug=user://procgen_ascent_field_debug.png" % [str(summary)])
	quit(0)


func _count_story_faction_regions(regions: Array) -> int:
	var count := 0
	for raw_region in regions:
		if not (raw_region is Dictionary):
			continue
		var region := raw_region as Dictionary
		var kind := String(region.get("kind", ""))
		if kind == "story_room" or kind == "faction_site":
			var rect: Rect2i = region.get("rect", Rect2i())
			if rect.size.x >= 12 and rect.size.y >= 8:
				count += 1
	return count


func _route_has_uphill_span(route_cells: Array, map_size: Vector2i) -> bool:
	var min_y := 999999
	var max_y := -999999
	for raw_cell in route_cells:
		if not (raw_cell is Vector2i):
			continue
		var cell := raw_cell as Vector2i
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
	return min_y < int(float(map_size.y) * 0.35) and max_y > int(float(map_size.y) * 0.70)


func _min_route_width(summary: Dictionary) -> int:
	var widths: Array = summary.get("route_widths", [])
	if widths.is_empty():
		return 0
	var min_width := 999999
	for raw_width in widths:
		min_width = mini(min_width, int(raw_width))
	return min_width


func _export_debug_image(data: Dictionary) -> void:
	var map_size: Vector2i = data.get("map_size", Vector2i.ZERO)
	if map_size.x <= 0 or map_size.y <= 0:
		return
	var image := Image.create_empty(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.02, 0.025, 1.0))
	_paint_cells(image, data.get("floor_cells", []), Color(0.28, 0.31, 0.25, 1.0))
	_paint_cells(image, data.get("wall_cells", []), Color(0.08, 0.09, 0.10, 1.0))
	_paint_cells(image, data.get("main_route_cells", []), Color(0.66, 0.58, 0.34, 1.0))
	_paint_cells(image, data.get("vista_cells", []), Color(0.35, 0.65, 0.95, 1.0))
	for raw_region in data.get("worldgen_reserved_regions", []):
		if not (raw_region is Dictionary):
			continue
		var region := raw_region as Dictionary
		var rect: Rect2i = region.get("rect", Rect2i())
		var color := Color(0.7, 0.5, 0.2, 1.0)
		var kind := String(region.get("kind", ""))
		if kind == "story_room":
			color = Color(0.75, 0.35, 0.9, 1.0)
		elif kind == "faction_site":
			color = Color(0.9, 0.32, 0.22, 1.0)
		_paint_rect_outline(image, rect, color)
	image.save_png("user://procgen_ascent_field_debug.png")


func _paint_cells(image: Image, cells: Array, color: Color) -> void:
	for raw_cell in cells:
		if not (raw_cell is Vector2i):
			continue
		var cell := raw_cell as Vector2i
		if cell.x >= 0 and cell.y >= 0 and cell.x < image.get_width() and cell.y < image.get_height():
			image.set_pixel(cell.x, cell.y, color)


func _paint_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.end.x):
		_set_debug_pixel(image, Vector2i(x, rect.position.y), color)
		_set_debug_pixel(image, Vector2i(x, rect.end.y - 1), color)
	for y in range(rect.position.y, rect.end.y):
		_set_debug_pixel(image, Vector2i(rect.position.x, y), color)
		_set_debug_pixel(image, Vector2i(rect.end.x - 1, y), color)


func _set_debug_pixel(image: Image, cell: Vector2i, color: Color) -> void:
	if cell.x >= 0 and cell.y >= 0 and cell.x < image.get_width() and cell.y < image.get_height():
		image.set_pixel(cell.x, cell.y, color)
