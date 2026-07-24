extends RefCounted
class_name AscentFieldBuilder

const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")

const BORDER_THICKNESS := 1
const MIN_ROUTE_WIDTH := 9
const MAX_ROUTE_WIDTH := 15
const TERRACE_MIN_SIZE := Vector2i(18, 12)
const SPAWN_PAD_SIZE := Vector2i(20, 16)
const EXIT_PAD_SIZE := Vector2i(22, 16)
const SAFE_PAD_SIZE := Vector2i(18, 14)


func build_field(graph, map_size: Vector2i, seed: int = 0) -> Dictionary:
	var floor_cells: Dictionary = {}
	var wall_cells: Dictionary = {}
	var reserved_regions: Array[Dictionary] = []
	var main_route_cells: Array[Vector2i] = []
	var main_route_centerline_cells: Array[Vector2i] = []
	var branch_route_cells: Array[Vector2i] = []
	var branch_route_centerline_cells: Array[Vector2i] = []
	var vista_cells: Array[Vector2i] = []
	var route_widths: Array[int] = []
	var terrace_count := 0
	var side_pocket_count := 0

	for edge in graph.edges:
		var from_node = graph.get_node_by_id(edge.from_id)
		var to_node = graph.get_node_by_id(edge.to_id)
		if from_node == null or to_node == null:
			continue
		if edge.kind == 0:
			var width := _route_width_for_edge(edge, seed)
			route_widths.append(width)
			_carve_path(
				floor_cells,
				main_route_cells,
				main_route_centerline_cells,
				from_node.cell,
				to_node.cell,
				width,
				map_size
			)
		else:
			_carve_path(
				floor_cells,
				branch_route_cells,
				branch_route_centerline_cells,
				from_node.cell,
				to_node.cell,
				7,
				map_size
			)

	for node in graph.nodes:
		var kind_name := IntentNodeScript.kind_to_string(node.kind)
		if _is_main_route_node(node):
			var size := _terrace_size_for_node(node, seed)
			var rect := _centered_rect(node.cell, size, map_size)
			_carve_rect(floor_cells, rect)
			reserved_regions.append(_region_from_node(node, rect, "terrace"))
			terrace_count += 1
			if kind_name == "ascent_beat" and (node.ascent_rank % 3) == 0:
				vista_cells.append(node.cell)
		elif kind_name == "story_room" \
				or kind_name == "faction_site" \
				or kind_name == "resource_pocket" \
				or kind_name == "safe_pocket" \
				or kind_name == "vista":
			var pocket_size := SAFE_PAD_SIZE if kind_name == "safe_pocket" else Vector2i(
				18 + int(abs(node.id.hash()) % 8),
				(14 if kind_name == "faction_site" else 12)
				+ int(abs((node.id + "h").hash()) % 6)
			)
			var pocket := _centered_rect(node.cell, pocket_size, map_size)
			_carve_rect(floor_cells, pocket)
			reserved_regions.append(_region_from_node(node, pocket, kind_name))
			side_pocket_count += 1
			if kind_name == "vista":
				vista_cells.append(node.cell)

	_add_exterior_shoulders(floor_cells, graph, map_size)
	_add_border_blockers(wall_cells, map_size)
	_add_ridge_fragments(wall_cells, floor_cells, graph, map_size, seed)
	_remove_wall_floor_overlaps(wall_cells, floor_cells)

	var floor_count := floor_cells.size()
	var wall_count := wall_cells.size()
	var average_route_width := _average_int(route_widths)
	return {
		"floor_cells": floor_cells,
		"wall_cells": wall_cells,
		"reserved_regions": reserved_regions,
		"main_route_cells": _dict_keys_as_vector2i_array(_cell_lookup(main_route_cells)),
		"main_route_centerline_cells": _dict_keys_as_vector2i_array(
			_cell_lookup(main_route_centerline_cells)
		),
		"branch_route_cells": _dict_keys_as_vector2i_array(
			_cell_lookup(branch_route_cells)
		),
		"vista_cells": vista_cells,
		"debug_summary": {
			"mode": "ascent_field",
			"floor_cells": floor_count,
			"wall_cells": wall_count,
			"wall_floor_ratio": float(wall_count) / float(maxi(1, floor_count)),
			"terrace_count": terrace_count,
			"side_pocket_count": side_pocket_count,
			"average_main_route_width": average_route_width,
			"route_widths": route_widths.duplicate(),
			"vista_count": vista_cells.size(),
		},
	}


func _route_width_for_edge(edge, seed: int) -> int:
	var basis := int(abs(("%s:%d" % [edge.id, seed]).hash()))
	return clampi(MIN_ROUTE_WIDTH + basis % (MAX_ROUTE_WIDTH - MIN_ROUTE_WIDTH + 1), MIN_ROUTE_WIDTH, MAX_ROUTE_WIDTH)


func _terrace_size_for_node(node, seed: int) -> Vector2i:
	match node.kind:
		IntentNodeScript.NodeKind.SPAWN:
			return SPAWN_PAD_SIZE
		IntentNodeScript.NodeKind.EXIT_GATE:
			return EXIT_PAD_SIZE
		IntentNodeScript.NodeKind.SAFE_POCKET:
			return SAFE_PAD_SIZE
	var basis := int(abs(("%s:%d:terrace" % [node.id, seed]).hash()))
	var minimum_size := Vector2i(18, 14) \
			if node.kind == IntentNodeScript.NodeKind.ASCENT_BEAT \
			else TERRACE_MIN_SIZE
	return Vector2i(
		minimum_size.x + basis % 9,
		minimum_size.y + int(basis / 11) % 7
	)


func _is_main_route_node(node) -> bool:
	return node.kind == IntentNodeScript.NodeKind.SPAWN \
			or node.kind == IntentNodeScript.NodeKind.MAIN_ROUTE \
			or node.kind == IntentNodeScript.NodeKind.ASCENT_BEAT \
			or node.kind == IntentNodeScript.NodeKind.EXIT_GATE


func _region_from_node(node, rect: Rect2i, fallback_kind: String) -> Dictionary:
	return {
		"id": node.id,
		"kind": IntentNodeScript.kind_to_string(node.kind) if fallback_kind == "terrace" else fallback_kind,
		"shape_kind": fallback_kind,
		"rect": rect,
		"center": node.cell,
		"radius_tiles": maxi(rect.size.x, rect.size.y) / 2,
		"runtime_height": node.runtime_height,
		"ascent_rank": node.ascent_rank,
		"band_id": node.band_id,
		"style_id": node.style_id,
		"faction_id": node.faction_id,
		"story_id": node.story_id,
		"required": node.required,
	}


func _add_exterior_shoulders(floor_cells: Dictionary, graph, map_size: Vector2i) -> void:
	for node in graph.nodes:
		if not _is_main_route_node(node):
			continue
		var shoulder := _centered_rect(node.cell + Vector2i(0, 4), Vector2i(28, 10), map_size)
		_carve_rect(floor_cells, shoulder)


func _add_border_blockers(wall_cells: Dictionary, map_size: Vector2i) -> void:
	for x in range(map_size.x):
		for y in range(BORDER_THICKNESS):
			wall_cells[Vector2i(x, y)] = true
			wall_cells[Vector2i(x, map_size.y - 1 - y)] = true
	for y in range(map_size.y):
		for x in range(BORDER_THICKNESS):
			wall_cells[Vector2i(x, y)] = true
			wall_cells[Vector2i(map_size.x - 1 - x, y)] = true


func _add_ridge_fragments(wall_cells: Dictionary, floor_cells: Dictionary, graph, map_size: Vector2i, seed: int) -> void:
	for node in graph.nodes:
		if not _is_main_route_node(node):
			continue
		var y := clampi(node.cell.y + 8, BORDER_THICKNESS, map_size.y - BORDER_THICKNESS - 1)
		var length := 10 + int(abs(("%s:%d:ridge" % [node.id, seed]).hash()) % 14)
		var start_x := clampi(node.cell.x - int(length / 2), BORDER_THICKNESS, map_size.x - BORDER_THICKNESS - 1)
		for offset in range(length):
			var cell := Vector2i(start_x + offset, y)
			if not Rect2i(Vector2i.ZERO, map_size).has_point(cell):
				continue
			if floor_cells.has(cell) and offset % 7 != 0:
				continue
			wall_cells[cell] = true


func _remove_wall_floor_overlaps(wall_cells: Dictionary, floor_cells: Dictionary) -> void:
	for cell in floor_cells.keys():
		wall_cells.erase(cell)


func _carve_path(
	floor_cells: Dictionary,
	route_cells: Array[Vector2i],
	centerline_cells: Array[Vector2i],
	from_cell: Vector2i,
	to_cell: Vector2i,
	width: int,
	map_size: Vector2i
) -> void:
	var points := _bresenham(from_cell, to_cell)
	var radius := maxi(4, int(floor(float(width) * 0.5)))
	for point in points:
		if Rect2i(Vector2i.ZERO, map_size).has_point(point):
			centerline_cells.append(point)
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if Vector2i(dx, dy).length_squared() > radius * radius:
					continue
				var cell := point + Vector2i(dx, dy)
				if Rect2i(Vector2i.ZERO, map_size).has_point(cell):
					floor_cells[cell] = true
					route_cells.append(cell)


func _carve_rect(floor_cells: Dictionary, rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			floor_cells[Vector2i(x, y)] = true


func _centered_rect(center: Vector2i, size: Vector2i, map_size: Vector2i) -> Rect2i:
	var rect := Rect2i(center - Vector2i(size.x / 2, size.y / 2), size)
	return rect.intersection(Rect2i(Vector2i(BORDER_THICKNESS, BORDER_THICKNESS), map_size - Vector2i(BORDER_THICKNESS * 2, BORDER_THICKNESS * 2)))


func _cell_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup


func _dict_keys_as_vector2i_array(dict: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for key in dict.keys():
		if key is Vector2i:
			result.append(key)
	return result


func _average_int(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0
	for value in values:
		total += value
	return float(total) / float(values.size())


func _bresenham(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0 := a.x
	var y0 := a.y
	var x1 := b.x
	var y1 := b.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return points
