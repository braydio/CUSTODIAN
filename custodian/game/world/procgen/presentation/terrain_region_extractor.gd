extends RefCounted
class_name TerrainMacroRegionExtractor

const EXCLUDED_REGION_PARTS := [
	"road", "path", "parking", "connector", "rescue", "spawn", "portal",
	"interior", "threshold", "door", "gate", "objective", "authored",
	"reserved", "compound",
]
const NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func extract(context: Dictionary) -> Array[Dictionary]:
	var regions: Array[Dictionary] = []
	var terrain_result: Dictionary = context.get("terrain_result", {})
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var biome_by_cell: Dictionary = context.get("biome_id_by_cell", {})
	for raw_region: Variant in terrain_result.get("regions", []):
		var data := _region_dictionary(raw_region)
		if String(data.get("kind_name", "")) != "mountain_wall":
			continue
		var cells := _sorted_cells(data.get("cells", []))
		if cells.is_empty():
			continue
		for component: Dictionary in _split_mountain_wall_components(cells, biome_by_cell, floor_cells):
			regions.append(_make_region("mountain_wall", StringName(component.get("biome_id", &"")), component.get("cells", [])))

	var remaining: Dictionary = {}
	for key: Variant in floor_cells.keys():
		if not key is Vector2i:
			continue
		var cell := key as Vector2i
		if StringName(biome_by_cell.get(cell, &"")) != &"rocky_upland":
			continue
		if not _is_walkable(cell, terrain_result) or _is_excluded(cell, context):
			continue
		remaining[cell] = true

	while not remaining.is_empty():
		var starts := _sorted_cells(remaining.keys())
		var start: Vector2i = starts[0]
		var queue: Array[Vector2i] = [start]
		var component: Array[Vector2i] = []
		remaining.erase(start)
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_front()
			component.append(cell)
			for delta: Vector2i in NEIGHBORS:
				var neighbor: Vector2i = cell + delta
				if remaining.has(neighbor):
					remaining.erase(neighbor)
					queue.append(neighbor)
		regions.append(_make_region("rocky_upland_floor", &"rocky_upland", component))

	regions.append_array(_extract_surface_material_regions(context))

	regions.append_array(_extract_depth_south_edges(context))

	regions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("region_id", "")) < String(b.get("region_id", ""))
	)
	return regions


func _extract_surface_material_regions(context: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var material_by_cell: Dictionary = context.get("surface_material_by_cell", {})
	var floor_cells: Dictionary = context.get("floor_cells", {})
	for material_kind: StringName in [&"hardened_civic", &"hardened_industrial", &"ruined_road"]:
		var remaining: Dictionary = {}
		for key: Variant in material_by_cell.keys():
			if key is Vector2i and StringName(material_by_cell[key]) == material_kind and floor_cells.has(key): remaining[key] = true
		while not remaining.is_empty():
			var start := _sorted_cells(remaining.keys())[0]
			var queue: Array[Vector2i] = [start]
			var component: Array[Vector2i] = []
			remaining.erase(start)
			while not queue.is_empty():
				var cell: Vector2i = queue.pop_front()
				component.append(cell)
				for delta: Vector2i in NEIGHBORS:
					var neighbor := cell + delta
					if remaining.has(neighbor): remaining.erase(neighbor); queue.append(neighbor)
			result.append(_make_region("%s_floor" % String(material_kind), &"", component))
	var boundary: Array[Vector2i] = []
	for key: Variant in material_by_cell.keys():
		if not key is Vector2i or not floor_cells.has(key): continue
		var material := StringName(material_by_cell[key])
		if material not in [&"hardened_civic", &"hardened_industrial", &"ruined_road"]: continue
		for delta: Vector2i in NEIGHBORS:
			if StringName(material_by_cell.get((key as Vector2i) + delta, &"")) in [&"natural_soft", &"natural_rock", &"wet_ground"]:
				boundary.append(key as Vector2i)
				break
	if not boundary.is_empty(): result.append(_make_region("hardstand_natural_boundary", &"", _sorted_cells(boundary)))
	return result


func _extract_depth_south_edges(context: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var chasm_cells: Dictionary = context.get("chasm_cells", {})
	var biome_by_cell: Dictionary = context.get("biome_id_by_cell", {})
	var exposed: Array[Vector2i] = []
	for key: Variant in floor_cells.keys():
		if key is Vector2i:
			var cell := key as Vector2i
			if chasm_cells.has(cell + Vector2i.DOWN) and not _is_excluded(cell, context):
				exposed.append(cell)
	exposed = _sorted_cells(exposed)
	var run: Array[Vector2i] = []
	var run_biome: StringName = &""
	for cell: Vector2i in exposed:
		var biome := StringName(biome_by_cell.get(cell, &""))
		var continues := not run.is_empty() and cell.y == run[-1].y and cell.x == run[-1].x + 1 and biome == run_biome
		if not continues and not run.is_empty():
			result.append(_make_depth_edge_region(run, run_biome))
			run = []
		if run.is_empty():
			run_biome = biome
		run.append(cell)
	if not run.is_empty():
		result.append(_make_depth_edge_region(run, run_biome))
	return result


func _make_depth_edge_region(cells: Array[Vector2i], biome_id: StringName) -> Dictionary:
	var region := _make_region("depth_south_edge", biome_id, cells)
	var anchors: Array[Vector2i] = []
	for cell: Vector2i in cells:
		anchors.append(cell + Vector2i.DOWN)
	region["anchor_candidates"] = anchors
	return region


func _region_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	if value != null and value.has_method("to_dictionary"):
		return value.call("to_dictionary") as Dictionary
	return {}


func _make_region(kind_name: String, biome_id: StringName, raw_cells: Variant) -> Dictionary:
	var cells := _sorted_cells(raw_cells)
	var bounds := _bounds(cells)
	return {
		"region_id": "%s:%d:%d:%d:%d" % [kind_name, bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
		"kind_name": kind_name,
		"biome_id": biome_id,
		"bounds": bounds,
		"cells": cells,
		"cell_count": cells.size(),
		"anchor_candidates": cells.duplicate(),
	}


func _split_mountain_wall_components(cells: Array[Vector2i], biome_by_cell: Dictionary, floor_cells: Dictionary) -> Array[Dictionary]:
	var biome_cells: Dictionary = {}
	for cell: Vector2i in cells:
		var biome := _mountain_cell_biome(cell, biome_by_cell, floor_cells)
		if biome == &"":
			continue
		if not biome_cells.has(biome):
			biome_cells[biome] = {}
		(biome_cells[biome] as Dictionary)[cell] = true
	var components: Array[Dictionary] = []
	var biome_keys: Array[StringName] = []
	for key: Variant in biome_cells.keys():
		biome_keys.append(StringName(key))
	biome_keys.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for biome: StringName in biome_keys:
		var remaining: Dictionary = biome_cells[biome]
		while not remaining.is_empty():
			var start := _sorted_cells(remaining.keys())[0]
			var queue: Array[Vector2i] = [start]
			var component_cells: Array[Vector2i] = []
			remaining.erase(start)
			while not queue.is_empty():
				var cell: Vector2i = queue.pop_front()
				component_cells.append(cell)
				for delta: Vector2i in NEIGHBORS:
					var neighbor := cell + delta
					if remaining.has(neighbor):
						remaining.erase(neighbor)
						queue.append(neighbor)
			components.append({"biome_id": biome, "cells": _sorted_cells(component_cells)})
	return components


func _mountain_cell_biome(cell: Vector2i, biome_by_cell: Dictionary, floor_cells: Dictionary) -> StringName:
	var direct := StringName(biome_by_cell.get(cell, &""))
	var counts: Dictionary = {}
	for delta: Vector2i in NEIGHBORS:
		var neighbor := cell + delta
		if not floor_cells.has(neighbor):
			continue
		var biome := StringName(biome_by_cell.get(neighbor, &""))
		if biome != &"":
			counts[biome] = int(counts.get(biome, 0)) + 1
	if counts.is_empty():
		return direct
	var candidates: Array[StringName] = []
	for key: Variant in counts.keys():
		candidates.append(StringName(key))
	candidates.sort_custom(func(a: StringName, b: StringName) -> bool:
		var ac := int(counts[a])
		var bc := int(counts[b])
		return ac > bc or (ac == bc and String(a) < String(b))
	)
	return candidates[0]


func _is_walkable(cell: Vector2i, terrain_result: Dictionary) -> bool:
	var traversal := String((terrain_result.get("traversal_by_cell", {}) as Dictionary).get(cell, "walkable"))
	return traversal in ["walkable", "ramp", "stair"]


func _is_excluded(cell: Vector2i, context: Dictionary) -> bool:
	if not (context.get("map_bounds", Rect2i()) as Rect2i).has_point(cell):
		return true
	for key in ["protected_cells", "required_cells", "reserved_cells", "ingress_clearance_cells"]:
		if (context.get(key, {}) as Dictionary).has(cell):
			return true
	var region_name := String((context.get("region_kind_by_cell", {}) as Dictionary).get(cell, "")).to_lower()
	if region_name.begins_with("faction_") or region_name.begins_with("story_room_"):
		return true
	for part: String in EXCLUDED_REGION_PARTS:
		if region_name.contains(part):
			return true
	return false


func _sorted_cells(values: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value: Variant in values:
		if value is Vector2i and not result.has(value):
			result.append(value)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return result


func _bounds(cells: Array[Vector2i]) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
