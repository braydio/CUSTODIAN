extends RefCounted
class_name ProcgenSurfaceMaterialResolver

const IDS := preload("res://game/world/procgen/surfaces/surface_material_ids.gd")

func resolve(context: Dictionary) -> Dictionary:
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var wall_cells: Dictionary = context.get("wall_cells", {})
	var chasm_cells: Dictionary = context.get("chasm_cells", {})
	var biome_by_cell: Dictionary = context.get("biome_by_cell", {})
	var region_kind_by_cell: Dictionary = context.get("region_kind_by_cell", {})
	var region_data_by_cell: Dictionary = context.get("region_data_by_cell", {})
	var parking_cells: Dictionary = context.get("parking_cells", {})
	var road_cells: Dictionary = context.get("road_cells", {})
	var path_cells: Dictionary = context.get("path_cells", {})
	var bridge_cells: Dictionary = context.get("bridge_cells", {})
	var reserved_cells: Dictionary = context.get("reserved_cells", {})
	var authored_cells: Dictionary = context.get("authored_cells", {})
	var material_by_cell: Dictionary = {}
	var counts: Dictionary = {}
	var cells: Array[Vector2i] = []
	for value: Variant in floor_cells.keys():
		if value is Vector2i:
			cells.append(value as Vector2i)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	for cell: Vector2i in cells:
		if wall_cells.has(cell) or chasm_cells.has(cell):
			continue
		var material := _resolve_cell(cell, biome_by_cell, region_kind_by_cell,
			region_data_by_cell, parking_cells, road_cells, path_cells,
			bridge_cells, reserved_cells, authored_cells)
		material_by_cell[cell] = material
		counts[material] = int(counts.get(material, 0)) + 1
	var fingerprint_parts: Array[String] = []
	for cell: Vector2i in cells:
		if material_by_cell.has(cell):
			fingerprint_parts.append("%d,%d:%s" % [cell.x, cell.y, String(material_by_cell[cell])])
	return {
		"material_by_cell": material_by_cell,
		"counts": counts,
		"fingerprint": ("|".join(fingerprint_parts)).sha256_text(),
	}


func _resolve_cell(cell: Vector2i, biome_by_cell: Dictionary, region_kind_by_cell: Dictionary,
	region_data_by_cell: Dictionary, parking_cells: Dictionary, road_cells: Dictionary,
	path_cells: Dictionary, bridge_cells: Dictionary, reserved_cells: Dictionary,
	authored_cells: Dictionary) -> StringName:
	var region := String(region_kind_by_cell.get(cell, "")).to_lower()
	var region_data: Dictionary = region_data_by_cell.get(cell, {}) as Dictionary
	if authored_cells.has(cell) or reserved_cells.has(cell) or _contains_any(region, ["authored", "landmark", "story_room", "faction_"]):
		return IDS.AUTHORED_LANDMARK
	if bridge_cells.has(cell) or _contains_any(region, ["bridge", "ramp_bridge"]):
		return IDS.BRIDGE
	if _contains_any(region, ["industrial", "service_hardstand", "hardstand", "platform", "apron"]):
		return IDS.HARDENED_INDUSTRIAL
	if parking_cells.has(cell) or _contains_any(region, ["parking", "plaza", "civic"]):
		return IDS.HARDENED_CIVIC
	if road_cells.has(cell) or path_cells.has(cell) or _contains_any(region, ["road", "path", "connector"]):
		return IDS.RUINED_ROAD
	if _contains_any(String(region_data.get("surface_role", "")).to_lower(), ["bridge"]):
		return IDS.BRIDGE
	var biome := StringName(biome_by_cell.get(cell, &""))
	if biome == &"wetland":
		return IDS.WET_GROUND
	if biome == &"rocky_upland":
		return IDS.NATURAL_ROCK
	return IDS.NATURAL_SOFT


func _contains_any(value: String, tokens: Array[String]) -> bool:
	for token: String in tokens:
		if value.contains(token):
			return true
	return false
