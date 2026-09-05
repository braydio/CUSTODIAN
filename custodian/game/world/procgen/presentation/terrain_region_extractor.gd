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
	for raw_region: Variant in terrain_result.get("regions", []):
		var data := _region_dictionary(raw_region)
		if String(data.get("kind_name", "")) != "mountain_wall":
			continue
		var cells := _sorted_cells(data.get("cells", []))
		if cells.is_empty():
			continue
		regions.append(_make_region("mountain_wall", &"rocky_upland", cells))

	var floor_cells: Dictionary = context.get("floor_cells", {})
	var biome_by_cell: Dictionary = context.get("biome_id_by_cell", {})
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

	regions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("region_id", "")) < String(b.get("region_id", ""))
	)
	return regions


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
