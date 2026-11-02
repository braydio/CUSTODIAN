extends RefCounted
class_name TerrainStampPlacer

const SCHEMA := "custodian.procgen_macro_presentation.v1"


func build_plan(
	seed: int,
	regions: Array[Dictionary],
	catalog: TerrainStampCatalog,
	context: Dictionary,
	max_stamps: int = 8
) -> Dictionary:
	var placements: Array[Dictionary] = []
	var fallback_ids: Array[String] = []
	var rejection_counts: Dictionary = {}
	var rejections: Array[Dictionary] = []
	var occupied_solid: Dictionary = {}
	var occupied_surface: Dictionary = {}
	var occupied_chasm: Dictionary = {}
	var placements_by_domain: Dictionary = {}
	var placements_by_family: Dictionary = {}
	var placements_by_stamp: Dictionary = {}
	var max_stamps_by_domain: Dictionary = context.get("max_stamps_by_domain", {})
	var max_stamps_by_family: Dictionary = context.get("max_stamps_by_family", {})
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
			var biome_id := StringName(region.get("biome_id", &""))
			var families_by_biome: Dictionary = context.get("families_by_biome", {})
			var families := PackedStringArray()
			for family: Variant in families_by_biome.get(biome_id, context.get("families", PackedStringArray())):
				if not families.has(String(family)): families.append(String(family))
			for family: Variant in context.get("global_families", PackedStringArray()):
				if not families.has(String(family)): families.append(String(family))
			var minimums_by_biome: Dictionary = context.get("min_region_cells_by_biome", {})
			var context_minimum := int(minimums_by_biome.get(biome_id, context.get("min_region_cells", 0)))
			var profiles := catalog.filter_profiles(families, StringName(region.get("kind_name", "")), StringName(region.get("biome_id", &"")))
			var candidates: Array[Dictionary] = []
			for profile: TerrainStampProfile in profiles:
				var placement_domain := int(profile.placement_domain)
				if max_stamps_by_family.has(profile.family_id) and int(placements_by_family.get(profile.family_id, 0)) >= int(max_stamps_by_family[profile.family_id]):
					_count_rejection(rejection_counts, "family_budget_exhausted")
					continue
				if int(placements_by_stamp.get(profile.stamp_id, 0)) >= profile.max_instances_per_map:
					_count_rejection(rejection_counts, "stamp_budget_exhausted")
					continue
				if max_stamps_by_domain.has(placement_domain) and int(placements_by_domain.get(placement_domain, 0)) >= int(max_stamps_by_domain[placement_domain]):
					_count_rejection(rejection_counts, "domain_budget_exhausted")
					continue
				if int(region.get("cell_count", 0)) < maxi(profile.min_region_cells, context_minimum):
					_count_rejection(rejection_counts, "region_too_small")
					continue
				for origin: Vector2i in region.get("anchor_candidates", []):
					for flip_h: bool in ([false, true] if profile.allow_flip_h else [false]):
						var candidate := _candidate(profile, region, origin, flip_h, context, occupied_solid, occupied_surface, occupied_chasm)
						if not bool(candidate.get("valid", false)):
							var reason := String(candidate.get("reason", "unknown"))
							_count_rejection(rejection_counts, reason)
							if rejections.size() < 64:
								rejections.append({"stamp_id": profile.stamp_id, "region_id": String(region.get("region_id", "")), "biome_id": StringName(region.get("biome_id", &"")), "anchor_cell": origin, "flip_h": flip_h, "reason": reason})
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
				placements_by_family[selected["family_id"]] = int(placements_by_family.get(selected["family_id"], 0)) + 1
				placements_by_stamp[selected["stamp_id"]] = int(placements_by_stamp.get(selected["stamp_id"], 0)) + 1
				var selected_domain := int(selected.get("placement_domain", TerrainStampProfile.PlacementDomain.SURFACE))
				placements_by_domain[selected_domain] = int(placements_by_domain.get(selected_domain, 0)) + 1
				for cell: Vector2i in selected["solid_cells"]:
					occupied_solid[cell] = true
					if selected_domain == TerrainStampProfile.PlacementDomain.SURFACE:
						occupied_surface[cell] = true
				if selected_domain == TerrainStampProfile.PlacementDomain.SURFACE:
					for cell: Vector2i in selected["presentation_cells"]:
						occupied_surface[cell] = true
				for cell: Vector2i in selected["chasm_cells"]:
					occupied_chasm[cell] = true
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
		"placements_by_family": _sorted_dictionary(placements_by_family),
		"rejections": rejections,
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


func _candidate(profile: TerrainStampProfile, region: Dictionary, anchor: Vector2i, flip_h: bool, context: Dictionary, occupied: Dictionary, occupied_surface: Dictionary, occupied_chasm: Dictionary) -> Dictionary:
	var core_position := profile.chasm_core_rect.position
	if profile.placement_domain == TerrainStampProfile.PlacementDomain.SURFACE:
		var semantic_cells: Array[Vector2i] = profile.solid_mask_cells if not profile.solid_mask_cells.is_empty() else profile.walkable_overlay_cells
		if not semantic_cells.is_empty():
			core_position = semantic_cells[0]
	if flip_h:
		if profile.placement_domain == TerrainStampProfile.PlacementDomain.CHASM:
			core_position.x = profile.footprint_size_cells.x - profile.chasm_core_rect.end.x
		else:
			core_position.x = profile.footprint_size_cells.x - 1 - core_position.x
	var origin := anchor - core_position
	var solid := _mapped_cells(profile.solid_mask_cells, profile.footprint_size_cells, origin, flip_h)
	var overlay := _mapped_cells(profile.walkable_overlay_cells, profile.footprint_size_cells, origin, flip_h)
	var probes := _mapped_cells(profile.resolved_reveal_probe_cells(), profile.footprint_size_cells, origin, flip_h)
	var chasm := _mapped_rect(profile.chasm_core_rect, profile.footprint_size_cells, origin, flip_h)
	var presentation := _surface_presentation_cells(profile, origin, flip_h)
	var bounds: Rect2i = context.get("map_bounds", Rect2i())
	var wall_cells: Dictionary = context.get("wall_cells", {})
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var terrain: Dictionary = context.get("terrain_result", {})
	var traversal: Dictionary = terrain.get("traversal_by_cell", {})
	var protected: Dictionary = context.get("protected_cells", {})
	var biome_by_cell: Dictionary = context.get("biome_id_by_cell", {})
	var chasm_cells: Dictionary = context.get("chasm_cells", {})
	var material_by_cell: Dictionary = context.get("surface_material_by_cell", {})
	if profile.placement_domain == TerrainStampProfile.PlacementDomain.CHASM:
		for cell: Vector2i in chasm:
			if not bounds.has_point(cell): return {"valid": false, "reason": "chasm_outside_map"}
			if _has_presentation_claim(cell, context): return {"valid": false, "reason": "protected_chasm"}
			if not chasm_cells.has(cell): return {"valid": false, "reason": "chasm_semantic_mismatch"}
			if occupied_chasm.has(cell): return {"valid": false, "reason": "chasm_presentation_overlap"}
	else:
		for cell: Vector2i in presentation:
			if not bounds.has_point(cell):
				continue
			if _has_presentation_claim(cell, context): return {"valid": false, "reason": "protected_presentation_footprint"}
			var presentation_claim := _surface_claim_reason(profile, cell, context, material_by_cell)
			if presentation_claim != "": return {"valid": false, "reason": presentation_claim}
			if not profile.allowed_surface_materials.is_empty() and not profile.allowed_surface_materials.has(String(material_by_cell.get(cell, &""))): return {"valid": false, "reason": "surface_material_mismatch"}
			if occupied_surface.has(cell): return {"valid": false, "reason": "surface_presentation_overlap"}
	for cell: Vector2i in solid:
		if not bounds.has_point(cell): return {"valid": false, "reason": "outside_map"}
		if profile.placement_domain == TerrainStampProfile.PlacementDomain.SURFACE:
			var solid_claim := _surface_claim_reason(profile, cell, context, material_by_cell)
			if solid_claim != "": return {"valid": false, "reason": solid_claim}
		if profile.placement_domain == TerrainStampProfile.PlacementDomain.CHASM and protected.has(cell): return {"valid": false, "reason": "protected_solid"}
		if profile.placement_domain == TerrainStampProfile.PlacementDomain.SURFACE and occupied_surface.has(cell): return {"valid": false, "reason": "surface_presentation_overlap"}
		if occupied.has(cell): return {"valid": false, "reason": "solid_overlap"}
		if not wall_cells.has(cell) and not String(traversal.get(cell, "")).to_lower() in ["blocked", "ledge", "drop"]:
			return {"valid": false, "reason": "solid_semantic_mismatch"}
	for cell: Vector2i in overlay:
		if not bounds.has_point(cell): return {"valid": false, "reason": "outside_map"}
		if profile.placement_domain == TerrainStampProfile.PlacementDomain.SURFACE:
			var overlay_claim := _surface_claim_reason(profile, cell, context, material_by_cell)
			if overlay_claim != "": return {"valid": false, "reason": overlay_claim}
			if not profile.allowed_surface_materials.is_empty() and not profile.allowed_surface_materials.has(String(material_by_cell.get(cell, &""))): return {"valid": false, "reason": "surface_material_mismatch"}
		if profile.placement_domain == TerrainStampProfile.PlacementDomain.SURFACE and occupied_surface.has(cell): return {"valid": false, "reason": "surface_presentation_overlap"}
		if profile.required_biome != &"" and StringName(biome_by_cell.get(cell, profile.required_biome)) != profile.required_biome:
			return {"valid": false, "reason": "semantic_biome_mismatch"}
		if not floor_cells.has(cell) or not String(traversal.get(cell, "walkable")).to_lower() in ["walkable", "ramp", "stair"]:
			return {"valid": false, "reason": "overlay_semantic_mismatch"}
	return {
		"valid": true,
		"stamp_id": profile.stamp_id,
		"family_id": profile.family_id,
		"region_id": String(region.get("region_id", "")),
		"biome_id": StringName(region.get("biome_id", &"")),
		"origin_cell": origin,
		"anchor_cell": anchor,
		"placement_domain": profile.placement_domain,
		"depth_band": profile.depth_band,
		"solid_cells": solid,
		"overlay_cells": overlay,
		"chasm_cells": chasm,
		"presentation_cells": presentation,
		"reveal_probe_cells": probes,
		"visual_footprint": Rect2i(origin, profile.footprint_size_cells),
		"flip_h": flip_h,
		"claims_dressing_clearance": profile.claims_dressing_clearance,
}


func _has_presentation_claim(cell: Vector2i, context: Dictionary) -> bool:
	for key: String in ["protected_cells", "required_cells", "reserved_cells", "ingress_clearance_cells"]:
		if (context.get(key, {}) as Dictionary).has(cell):
			return true
	return false


func _surface_claim_reason(profile: TerrainStampProfile, cell: Vector2i, context: Dictionary, material_by_cell: Dictionary) -> String:
	if _has_presentation_claim(cell, context):
		return "protected_surface_claim"
	var claims: Dictionary = context.get("surface_claim_cells", {})
	if not claims.has(cell):
		return ""
	if profile.allowed_surface_materials.is_empty() or not profile.allowed_surface_materials.has(String(material_by_cell.get(cell, &""))):
		return "constructed_surface_claim_mismatch"
	return ""


func _mapped_rect(rect: Rect2i, size: Vector2i, origin: Vector2i, flip_h: bool) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return _mapped_cells(cells, size, origin, flip_h)


func _surface_presentation_cells(profile: TerrainStampProfile, origin: Vector2i, flip_h: bool) -> Array[Vector2i]:
	if profile.placement_domain != TerrainStampProfile.PlacementDomain.SURFACE:
		return []
	var local_cells: Dictionary = {}
	for cell: Vector2i in profile.solid_mask_cells + profile.walkable_overlay_cells + profile.resolved_reveal_probe_cells():
		local_cells[cell] = true
	var authored_cells: Array[Vector2i] = []
	for cell: Vector2i in local_cells:
		authored_cells.append(cell)
	return _mapped_cells(authored_cells, profile.footprint_size_cells, origin, flip_h)


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
		entry["placement_domain"] = int(entry.get("placement_domain", TerrainStampProfile.PlacementDomain.SURFACE))
		for key in ["origin_cell", "anchor_cell", "visual_footprint"]: entry[key] = str(entry.get(key))
		for key in ["solid_cells", "overlay_cells", "chasm_cells", "presentation_cells", "reveal_probe_cells"]:
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
