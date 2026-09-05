extends RefCounted
class_name TerrainStampPlacer

const SCHEMA := "custodian.procgen_macro_presentation.v1"


func build_plan(
	seed: int,
	regions: Array[Dictionary],
	catalog: TerrainStampCatalog,
	context: Dictionary,
	max_stamps: int = 12
) -> Dictionary:
	var placements: Array[Dictionary] = []
	var fallback_ids: Array[String] = []
	var rejection_counts: Dictionary = {}
	var occupied_solid: Dictionary = {}
	var normalized_regions: Array[Dictionary] = []
	for region: Dictionary in regions:
		normalized_regions.append({
			"region_id": String(region.get("region_id", "")),
			"kind_name": String(region.get("kind_name", "")),
			"biome_id": StringName(region.get("biome_id", &"")),
			"bounds": region.get("bounds", Rect2i()),
			"cell_count": int(region.get("cell_count", 0)),
		})
		var placed_for_region := false
		if placements.size() < max_stamps and catalog != null:
			var families: PackedStringArray = context.get("families", PackedStringArray())
			var profiles := catalog.filter_profiles(families, StringName(region.get("kind_name", "")), StringName(region.get("biome_id", &"")))
			var candidates: Array[Dictionary] = []
			for profile: TerrainStampProfile in profiles:
				if int(region.get("cell_count", 0)) < maxi(profile.min_region_cells, int(context.get("min_region_cells", 0))):
					_count_rejection(rejection_counts, "region_too_small")
					continue
				for origin: Vector2i in region.get("anchor_candidates", []):
					for flip_h: bool in ([false, true] if profile.allow_flip_h else [false]):
						var candidate := _candidate(profile, region, origin, flip_h, context, occupied_solid)
						if not bool(candidate.get("valid", false)):
							_count_rejection(rejection_counts, String(candidate.get("reason", "unknown")))
							continue
						candidate["rank"] = _stable_hash(seed, String(region.get("region_id", "")), String(profile.stamp_id), origin, profile.weight)
						candidates.append(candidate)
			if not candidates.is_empty():
				candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
					if int(a["rank"]) == int(b["rank"]):
						return String(a["stamp_id"]) < String(b["stamp_id"])
					return int(a["rank"]) < int(b["rank"])
				)
				var selected := candidates[0].duplicate(true)
				selected.erase("valid")
				selected.erase("reason")
				selected.erase("rank")
				placements.append(selected)
				for cell: Vector2i in selected["solid_cells"]:
					occupied_solid[cell] = true
				placed_for_region = true
		if not placed_for_region:
			fallback_ids.append(String(region.get("region_id", "")))

	var plan := {
		"schema": SCHEMA,
		"seed": seed,
		"regions": normalized_regions,
		"placements": placements,
		"fallback_region_ids": fallback_ids,
		"rejection_counts": _sorted_dictionary(rejection_counts),
	}
	plan["fingerprint"] = plan_fingerprint(plan)
	return plan


func plan_fingerprint(plan: Dictionary) -> String:
	var normalized := {
		"schema": String(plan.get("schema", SCHEMA)),
		"seed": int(plan.get("seed", 0)),
		"regions": _normalize_regions(plan.get("regions", [])),
		"placements": _normalize_placements(plan.get("placements", [])),
		"fallback_region_ids": Array(plan.get("fallback_region_ids", [])).duplicate(),
		"rejection_counts": _sorted_dictionary(plan.get("rejection_counts", {})),
	}
	return JSON.stringify(normalized).sha256_text()


func _candidate(profile: TerrainStampProfile, region: Dictionary, origin: Vector2i, flip_h: bool, context: Dictionary, occupied: Dictionary) -> Dictionary:
	var solid := _mapped_cells(profile.solid_mask_cells, profile.footprint_size_cells, origin, flip_h)
	var overlay := _mapped_cells(profile.walkable_overlay_cells, profile.footprint_size_cells, origin, flip_h)
	var probes := _mapped_cells(profile.resolved_reveal_probe_cells(), profile.footprint_size_cells, origin, flip_h)
	var bounds: Rect2i = context.get("map_bounds", Rect2i())
	var wall_cells: Dictionary = context.get("wall_cells", {})
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var terrain: Dictionary = context.get("terrain_result", {})
	var traversal: Dictionary = terrain.get("traversal_by_cell", {})
	var protected: Dictionary = context.get("protected_cells", {})
	for cell: Vector2i in solid:
		if not bounds.has_point(cell): return {"valid": false, "reason": "outside_map"}
		if protected.has(cell): return {"valid": false, "reason": "protected_solid"}
		if occupied.has(cell): return {"valid": false, "reason": "solid_overlap"}
		if not wall_cells.has(cell) and not String(traversal.get(cell, "")).to_lower() in ["blocked", "ledge", "drop"]:
			return {"valid": false, "reason": "solid_semantic_mismatch"}
	for cell: Vector2i in overlay:
		if not bounds.has_point(cell): return {"valid": false, "reason": "outside_map"}
		if not floor_cells.has(cell) or not String(traversal.get(cell, "walkable")).to_lower() in ["walkable", "ramp", "stair"]:
			return {"valid": false, "reason": "overlay_semantic_mismatch"}
	return {
		"valid": true,
		"stamp_id": profile.stamp_id,
		"family_id": profile.family_id,
		"region_id": String(region.get("region_id", "")),
		"origin_cell": origin,
		"anchor_cell": origin,
		"depth_band": profile.depth_band,
		"solid_cells": solid,
		"overlay_cells": overlay,
		"reveal_probe_cells": probes,
		"visual_footprint": Rect2i(origin, profile.footprint_size_cells),
		"flip_h": flip_h,
		"claims_dressing_clearance": profile.claims_dressing_clearance,
	}


func _mapped_cells(cells: Array[Vector2i], size: Vector2i, origin: Vector2i, flip_h: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in cells:
		var local := Vector2i(size.x - 1 - cell.x, cell.y) if flip_h else cell
		result.append(origin + local)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return result


func _stable_hash(seed: int, region_id: String, stamp_id: String, origin: Vector2i, weight: int) -> int:
	var text := "%d|%s|%s|%d|%d" % [seed, region_id, stamp_id, origin.x, origin.y]
	return int(text.sha256_text().substr(0, 8).hex_to_int()) / maxi(weight, 1)


func _count_rejection(counts: Dictionary, reason: String) -> void:
	counts[reason] = int(counts.get(reason, 0)) + 1


func _normalize_regions(values: Variant) -> Array:
	var result: Array = []
	for value: Dictionary in values:
		result.append({"region_id": String(value.get("region_id", "")), "kind_name": String(value.get("kind_name", "")), "biome_id": String(value.get("biome_id", "")), "bounds": str(value.get("bounds", Rect2i())), "cell_count": int(value.get("cell_count", 0))})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["region_id"]) < String(b["region_id"]))
	return result


func _normalize_placements(values: Variant) -> Array:
	var result: Array = []
	for value: Dictionary in values:
		var entry := value.duplicate(true)
		for key in ["origin_cell", "anchor_cell", "visual_footprint"]: entry[key] = str(entry.get(key))
		for key in ["solid_cells", "overlay_cells", "reveal_probe_cells"]:
			var strings: Array[String] = []
			for cell: Variant in entry.get(key, []): strings.append(str(cell))
			strings.sort()
			entry[key] = strings
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return "%s|%s" % [a.get("region_id", ""), a.get("stamp_id", "")] < "%s|%s" % [b.get("region_id", ""), b.get("stamp_id", "")]
	)
	return result


func _sorted_dictionary(value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var keys := source.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	var result: Dictionary = {}
	for key: Variant in keys: result[String(key)] = source[key]
	return result

