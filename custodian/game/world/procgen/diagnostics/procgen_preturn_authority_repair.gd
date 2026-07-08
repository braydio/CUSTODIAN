class_name ProcgenPreterrainAuthorityRepair
extends RefCounted

const MAX_ITERATIONS := 8


static func repair(context: Dictionary) -> Dictionary:
	var compute_diagnostics: Callable = context.get("compute_diagnostics", Callable())
	var set_bridge_floor: Callable = context.get("set_bridge_floor", Callable())
	var carve_bridge: Callable = context.get("carve_bridge", Callable())
	if not compute_diagnostics.is_valid() or not set_bridge_floor.is_valid() or not carve_bridge.is_valid():
		return {"carved_cells": 0, "iterations": 0, "bridges_carved": 0, "required_promotions": 0}

	var total_carved := 0
	var iterations := 0
	var bridges_carved := 0
	var required_promotions := 0
	var seen_bridges := {}
	for _iteration in range(MAX_ITERATIONS):
		iterations += 1
		var diagnostics: Dictionary = compute_diagnostics.call()
		if int(diagnostics.get("pre_terrain_missing_required_count", 0)) <= 0:
			break
		var promoted_this_iteration := _promote_required_samples(diagnostics, set_bridge_floor)
		required_promotions += promoted_this_iteration
		var bridge_candidates: Array = diagnostics.get("pre_terrain_bridge_candidates", [])
		if bridge_candidates.is_empty() and promoted_this_iteration <= 0:
			break
		var carved_this_iteration := 0
		for candidate in bridge_candidates:
			if not (candidate is Dictionary):
				continue
			var from_tile_variant: Variant = (candidate as Dictionary).get("from_tile", Vector2i.ZERO)
			var to_tile_variant: Variant = (candidate as Dictionary).get("to_tile", Vector2i.ZERO)
			if not (from_tile_variant is Vector2i and to_tile_variant is Vector2i):
				continue
			var bridge_key := "%s>%s" % [str(from_tile_variant), str(to_tile_variant)]
			if seen_bridges.has(bridge_key):
				continue
			seen_bridges[bridge_key] = true
			var carved := int(carve_bridge.call(from_tile_variant, to_tile_variant))
			carved_this_iteration += carved
			if carved > 0:
				bridges_carved += 1
		total_carved += promoted_this_iteration + carved_this_iteration
		if promoted_this_iteration + carved_this_iteration <= 0:
			break
	return {
		"carved_cells": total_carved,
		"iterations": iterations,
		"bridges_carved": bridges_carved,
		"required_promotions": required_promotions,
	}


static func _promote_required_samples(diagnostics: Dictionary, set_bridge_floor: Callable) -> int:
	var promoted := 0
	for sample in diagnostics.get("pre_terrain_missing_required_samples", []):
		if not (sample is Dictionary):
			continue
		var tile_variant: Variant = (sample as Dictionary).get("tile", Vector2i.ZERO)
		if tile_variant is Vector2i:
			promoted += int(set_bridge_floor.call(tile_variant))
	return promoted
