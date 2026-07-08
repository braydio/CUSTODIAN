class_name ProcgenPreterrainDiagnostics
extends RefCounted

const CARDINAL_DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const SAMPLE_CAP := 20
const REQUIRED_CELL_CLASSIFIER_SCRIPT := preload("res://game/world/procgen/diagnostics/procgen_required_cell_classifier.gd")
const COMPONENT_ANALYZER_SCRIPT := preload("res://game/world/procgen/diagnostics/procgen_component_analyzer.gd")


static func compute(context: Dictionary) -> Dictionary:
	var map_size: Vector2i = context.get("map_size", Vector2i.ZERO)
	var spawn: Vector2i = context.get("spawn", Vector2i.ZERO)
	var entries: Array[Dictionary] = context.get("required_cell_entries", [])
	var required_cells: Array[Vector2i] = REQUIRED_CELL_CLASSIFIER_SCRIPT.entries_to_cells(entries)
	var layout_reachable := _flood_fill(map_size, spawn, context.get("is_layout_walkable", Callable()))
	var baseline_reachable := _flood_fill(map_size, spawn, context.get("is_baseline_walkable", Callable()))
	var semantic_reachable := _flood_fill(map_size, spawn, context.get("is_semantic_walkable", Callable()))
	var missing_samples: Array[Dictionary] = []
	var connected_count := 0
	var layout_connected_count := 0
	var semantic_connected_count := 0
	var missing_by_source := {}
	var missing_by_reason := {}
	var entry_by_tile := {}
	for entry in entries:
		var tile_variant: Variant = entry.get("tile", Vector2i.ZERO)
		if tile_variant is Vector2i and not entry_by_tile.has(tile_variant):
			entry_by_tile[tile_variant] = entry

	for cell in required_cells:
		if layout_reachable.has(cell):
			layout_connected_count += 1
		if semantic_reachable.has(cell):
			semantic_connected_count += 1
		if baseline_reachable.has(cell):
			connected_count += 1
			continue
		var entry: Dictionary = entry_by_tile.get(cell, {"tile": cell, "source": "unknown"})
		var source := String(entry.get("source", "unknown"))
		var reason := _classify_missing_reason(context, cell, map_size)
		missing_by_source[source] = int(missing_by_source.get(source, 0)) + 1
		missing_by_reason[reason] = int(missing_by_reason.get(reason, 0)) + 1
		if missing_samples.size() < SAMPLE_CAP:
			missing_samples.append(_build_missing_sample(context, cell, source, reason, baseline_reachable))

	var required_count: int = required_cells.size()
	var denominator := float(required_count)
	var graph_disagreement := _compute_graph_disagreements(context, entries, map_size)
	var component_context := context.duplicate()
	component_context["required_cell_entries"] = entries
	var components: Dictionary = COMPONENT_ANALYZER_SCRIPT.analyze(component_context)
	return {
		"pre_terrain_spawn_tile": spawn,
		"pre_terrain_required_cell_count": required_count,
		"pre_terrain_missing_required_count": required_count - connected_count,
		"pre_terrain_reachable_floor_count": baseline_reachable.size(),
		"pre_terrain_connected_required_ratio": float(connected_count) / denominator if required_count > 0 else 1.0,
		"pre_terrain_layout_connected_required_ratio": float(layout_connected_count) / denominator if required_count > 0 else 1.0,
		"pre_terrain_baseline_connected_required_ratio": float(connected_count) / denominator if required_count > 0 else 1.0,
		"pre_terrain_semantic_connected_required_ratio": float(semantic_connected_count) / denominator if required_count > 0 else 1.0,
		"pre_terrain_missing_required_samples": missing_samples,
		"pre_terrain_missing_required_by_source": missing_by_source,
		"pre_terrain_missing_required_by_reason": missing_by_reason,
		"pre_terrain_graph_disagreement_count": int(graph_disagreement.get("count", 0)),
		"pre_terrain_graph_disagreement_samples": graph_disagreement.get("samples", []),
		"pre_terrain_component_count": int(components.get("pre_terrain_component_count", 0)),
		"pre_terrain_spawn_component_size": int(components.get("pre_terrain_spawn_component_size", 0)),
		"pre_terrain_required_components": components.get("pre_terrain_required_components", {}),
		"pre_terrain_largest_missing_component_size": int(components.get("pre_terrain_largest_missing_component_size", 0)),
		"pre_terrain_bridge_candidates": components.get("pre_terrain_bridge_candidates", []),
		"pre_terrain_total_floor_cells": (context.get("floor_cells", {}) as Dictionary).size(),
		"pre_terrain_total_wall_cells": (context.get("wall_cells", {}) as Dictionary).size(),
	}


static func _flood_fill(map_size: Vector2i, start: Vector2i, is_walkable: Callable) -> Dictionary:
	var reachable := {}
	if not is_walkable.is_valid() or not bool(is_walkable.call(start, map_size)):
		return reachable
	var open: Array[Vector2i] = [start]
	reachable[start] = true
	while not open.is_empty():
		var current: Vector2i = open.pop_back()
		for direction in CARDINAL_DIRECTIONS:
			var next := current + direction
			if reachable.has(next) or not bool(is_walkable.call(next, map_size)):
				continue
			reachable[next] = true
			open.append(next)
	return reachable


static func _classify_missing_reason(context: Dictionary, cell: Vector2i, map_size: Vector2i) -> String:
	var classifier: Callable = context.get("classify_missing_reason", Callable())
	return String(classifier.call(cell, map_size)) if classifier.is_valid() else "unreachable_from_spawn"


static func _build_missing_sample(context: Dictionary, cell: Vector2i, source: String, reason: String, reachable: Dictionary) -> Dictionary:
	var builder: Callable = context.get("build_missing_sample", Callable())
	if builder.is_valid():
		return builder.call(cell, source, reason, reachable)
	return {"tile": cell, "source": source if not source.is_empty() else "unknown", "reason": reason}


static func _compute_graph_disagreements(context: Dictionary, entries: Array[Dictionary], map_size: Vector2i) -> Dictionary:
	var samples: Array[Dictionary] = []
	var count := 0
	var layout: Callable = context.get("is_layout_walkable", Callable())
	var baseline: Callable = context.get("is_baseline_walkable", Callable())
	var semantic: Callable = context.get("is_semantic_walkable", Callable())
	var region_query: Callable = context.get("get_region_data_at_tile", Callable())
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var wall_cells: Dictionary = context.get("wall_cells", {})
	var road_cells: Dictionary = context.get("road_cells", {})
	var parking_cells: Dictionary = context.get("parking_cells", {})
	for entry in entries:
		var tile_variant: Variant = entry.get("tile", Vector2i.ZERO)
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		var layout_walkable := bool(layout.call(tile, map_size))
		var baseline_walkable := bool(baseline.call(tile, map_size))
		var semantic_walkable := bool(semantic.call(tile, map_size))
		if layout_walkable == baseline_walkable and baseline_walkable == semantic_walkable:
			continue
		count += 1
		if samples.size() >= SAMPLE_CAP:
			continue
		var region: Dictionary = region_query.call(tile) if region_query.is_valid() else {}
		samples.append({
			"tile": tile,
			"source": String(entry.get("source", "unknown")),
			"layout_walkable": layout_walkable,
			"terrain_baseline_walkable": baseline_walkable,
			"semantic_walkable": semantic_walkable,
			"floor_authority": floor_cells.has(tile),
			"wall_authority": wall_cells.has(tile),
			"road_authority": road_cells.has(tile),
			"parking_authority": parking_cells.has(tile),
			"region_type": String(region.get("region_type", "exterior")),
			"zone": String(region.get("zone", "natural")),
		})
	return {"count": count, "samples": samples}
