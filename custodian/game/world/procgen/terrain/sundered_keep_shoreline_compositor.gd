@tool
extends RefCounted
class_name SunderedKeepShorelineCompositor

const OCEAN_SHORE_TOPOLOGY_RESOLVER := preload(
	"res://game/world/procgen/terrain/ocean_shore_topology_resolver.gd"
)
const CLIFF_CATALOG := preload(
	"res://game/world/procgen/terrain/sundered_keep_cliff_asset_catalog.gd"
)

const DEFAULT_CELL_WORLD_SIZE := 32.0
const DEFAULT_CLIFF_SPACING_PX := 32.0
const DEFAULT_CLIFF_OVERLAP_PX := 16.0
const DEFAULT_SURF_ALPHA := 0.22
const DEFAULT_SHORE_BAND_WIDTH_CELLS := 2
const DEFAULT_CLIFF_MODULATE := Color(0.72, 0.77, 0.84, 0.96)
const DEFAULT_GLUE_WIDTH_PX := 40.0
const DEFAULT_GLUE_COLOR := Color(0.12, 0.15, 0.18, 0.92)

const FLOOR_SOURCE_ROCK := 129
const FLOOR_SOURCE_CRACKED := 130
const FLOOR_SOURCE_WET := 131

const CLIFF_OFFSETS_WORLD := {
	"n": Vector2(0.0, 32.0),
	"e": Vector2(-18.0, 24.0),
	"s": Vector2(0.0, -24.0),
	"w": Vector2(18.0, 24.0),
}

const FOAM_SOURCE_IDS := {
	"shore_n": 125,
	"shore_e": 126,
	"shore_s": 127,
	"shore_w": 128,
	"corner_ne": 133,
	"corner_nw": 134,
	"corner_se": 135,
	"corner_sw": 136,
	"inner_corner_ne": 137,
	"inner_corner_nw": 138,
	"inner_corner_se": 139,
	"inner_corner_sw": 140,
	"endcap_n": 141,
	"endcap_e": 142,
	"endcap_s": 143,
	"endcap_w": 144,
	"t_junction_n": 145,
	"t_junction_e": 146,
	"t_junction_s": 147,
	"t_junction_w": 148,
}

const CARDINALS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]


static func build_plan(
	floor_cells: Dictionary,
	ocean_cells: Dictionary,
	seed: int,
	options: Dictionary = {}
) -> Dictionary:
	var cell_world_size := maxf(
		1.0,
		float(options.get("cell_world_size", DEFAULT_CELL_WORLD_SIZE))
	)
	var spacing := maxf(
		1.0,
		float(options.get("cliff_spacing_px", DEFAULT_CLIFF_SPACING_PX))
	)
	var overlap := clampf(
		float(options.get("cliff_overlap_px", DEFAULT_CLIFF_OVERLAP_PX)),
		0.0,
		spacing * 0.5
	)
	var shore_band_width := maxi(
		0,
		int(options.get(
			"shore_band_width_cells",
			DEFAULT_SHORE_BAND_WIDTH_CELLS
		))
	)
	var segments := _extract_segments(floor_cells, ocean_cells, cell_world_size)
	var runs := _order_segments_into_runs(segments)
	var cliffs := _build_cliff_placements(
		runs,
		floor_cells,
		seed,
		spacing,
		cell_world_size,
		maxf(0.0, float(options.get("corner_exclusion_px", spacing * 0.75)))
	)
	var foam := _build_foam_plan(segments, floor_cells, ocean_cells)
	var floor_band := _build_floor_band_plan(
		floor_cells,
		ocean_cells,
		seed,
		shore_band_width
	)
	return {
		"schema": "custodian.sundered_keep.shoreline_plan.v2",
		"seed": seed,
		"cell_world_size": cell_world_size,
		"cliff_spacing_px": spacing,
		"cliff_overlap_px": overlap,
		"foam_alpha": clampf(
			float(options.get("foam_alpha", DEFAULT_SURF_ALPHA)),
			0.0,
			1.0
		),
		"shore_band_width_cells": shore_band_width,
		"cliff_modulate": options.get(
			"cliff_modulate",
			DEFAULT_CLIFF_MODULATE
		),
		"glue_width_px": maxf(
			0.0,
			float(options.get("glue_width_px", DEFAULT_GLUE_WIDTH_PX))
		),
		"glue_color": options.get("glue_color", DEFAULT_GLUE_COLOR),
		"segments": segments,
		"runs": runs,
		"cliffs": cliffs,
		"foam": foam,
		"floor_band": floor_band,
	}


static func apply_floor_band(plan: Dictionary, floor_tilemap: TileMapLayer) -> Dictionary:
	var counts := {FLOOR_SOURCE_ROCK: 0, FLOOR_SOURCE_CRACKED: 0, FLOOR_SOURCE_WET: 0}
	if floor_tilemap == null:
		return counts
	for entry_variant in plan.get("floor_band", []):
		var entry := entry_variant as Dictionary
		var cell := entry.get("cell", Vector2i.ZERO) as Vector2i
		var source_id := int(entry.get("source_id", -1))
		if source_id < 0:
			continue
		floor_tilemap.set_cell(cell, source_id, Vector2i.ZERO, 0)
		if counts.has(source_id):
			counts[source_id] = int(counts[source_id]) + 1
	return counts


static func apply_foam(
	plan: Dictionary,
	foam_tilemap: TileMapLayer,
	extra_overlay_parent: Node2D
) -> int:
	if foam_tilemap == null:
		return 0
	foam_tilemap.clear()
	foam_tilemap.self_modulate.a = float(plan.get("foam_alpha", DEFAULT_SURF_ALPHA))
	_clear_children(extra_overlay_parent)
	var count := 0
	for entry_variant in plan.get("foam", []):
		var entry := entry_variant as Dictionary
		var cell := entry.get("cell", Vector2i.ZERO) as Vector2i
		var source_ids := entry.get("source_ids", []) as Array
		for source_index in range(source_ids.size()):
			var source_id := int(source_ids[source_index])
			if source_index == 0:
				foam_tilemap.set_cell(cell, source_id, Vector2i.ZERO, 0)
			else:
				_add_extra_foam_sprite(
					foam_tilemap,
					extra_overlay_parent,
					cell,
					source_id
				)
			count += 1
	return count


static func build_cliff_presentation(
	plan: Dictionary,
	presentation_root: Node2D,
	local_cell_size: Vector2,
	presentation_world_scale := Vector2.ONE,
	show_ribbon := true,
	show_cliffs := true
) -> Dictionary:
	if presentation_root == null:
		return {}
	_clear_children(presentation_root)
	var safe_scale := Vector2(
		maxf(absf(presentation_world_scale.x), 0.001),
		maxf(absf(presentation_world_scale.y), 0.001)
	)
	var world_per_grid := float(plan.get("cell_world_size", DEFAULT_CELL_WORLD_SIZE))
	var local_per_world := Vector2(
		local_cell_size.x / world_per_grid,
		local_cell_size.y / world_per_grid
	)
	var ribbon_count := 0
	if show_ribbon:
		for run_variant in plan.get("runs", []):
			var run := run_variant as Dictionary
			var points := PackedVector2Array()
			for point_variant in run.get("points_grid", []):
				points.append((point_variant as Vector2) * local_cell_size)
			if points.size() < 2:
				continue
			var ribbon := Line2D.new()
			ribbon.name = "CliffGlueRibbon_%d" % ribbon_count
			ribbon.points = points
			ribbon.width = float(plan.get("glue_width_px", DEFAULT_GLUE_WIDTH_PX)) \
				/ maxf(safe_scale.x, safe_scale.y)
			ribbon.default_color = plan.get("glue_color", DEFAULT_GLUE_COLOR) as Color
			ribbon.antialiased = false
			ribbon.begin_cap_mode = Line2D.LINE_CAP_BOX
			ribbon.end_cap_mode = Line2D.LINE_CAP_BOX
			ribbon.joint_mode = Line2D.LINE_JOINT_BEVEL
			ribbon.z_index = 0
			presentation_root.add_child(ribbon)
			ribbon_count += 1
	var cliff_count := 0
	if show_cliffs:
		for entry_variant in plan.get("cliffs", []):
			var entry := entry_variant as Dictionary
			var facing := String(entry.get("facing", "n"))
			var asset_key := String(entry.get("asset_key", "edge_%s" % facing))
			var spec := CLIFF_CATALOG.get_spec(asset_key)
			if spec.is_empty():
				continue
			var sprite := Sprite2D.new()
			sprite.name = "Cliff_%04d_%s" % [cliff_count, asset_key]
			sprite.texture = spec.get("texture") as Texture2D
			sprite.centered = false
			var grid_position := entry.get("position_grid", Vector2.ZERO) as Vector2
			var kind := String(entry.get("kind", "edge"))
			var world_offset := Vector2.ZERO
			if kind in ["edge", "face_slice"]:
				world_offset = CLIFF_OFFSETS_WORLD.get(facing, Vector2.ZERO) as Vector2
			sprite.position = grid_position * local_cell_size + world_offset * local_per_world
			sprite.offset = -(spec.get("pivot_px", Vector2.ZERO) as Vector2)
			sprite.scale = Vector2.ONE / safe_scale
			sprite.modulate = plan.get("cliff_modulate", DEFAULT_CLIFF_MODULATE) as Color
			sprite.z_index = 1
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.set_meta("facing", facing)
			sprite.set_meta("kind", kind)
			sprite.set_meta("asset_key", asset_key)
			sprite.set_meta("arc_distance_px", float(entry.get("arc_distance_px", 0.0)))
			sprite.set_meta("run_index", int(entry.get("run_index", 0)))
			presentation_root.add_child(sprite)
			cliff_count += 1
	return {"ribbon_count": ribbon_count, "cliff_count": cliff_count}


static func fixture_to_json(
	seed: int,
	floor_cells: Dictionary,
	ocean_cells: Dictionary,
	optional_bounds: Dictionary = {},
	vista_context: Dictionary = {}
) -> String:
	return JSON.stringify({
		"schema": "custodian.sundered_keep.shoreline_fixture.v1",
		"seed": seed,
		"floor_cells": _sorted_cell_arrays(floor_cells),
		"ocean_cells": _sorted_cell_arrays(ocean_cells),
		"bounds": optional_bounds,
		"vista_context": vista_context,
	}, "\t") + "\n"


static func fixture_from_json(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {}
	var data := parsed as Dictionary
	return {
		"seed": int(data.get("seed", 0)),
		"floor_cells": _cell_dictionary(data.get("floor_cells", [])),
		"ocean_cells": _cell_dictionary(data.get("ocean_cells", [])),
		"bounds": (data.get("bounds", {}) as Dictionary).duplicate(true),
		"vista_context": (data.get("vista_context", {}) as Dictionary).duplicate(true),
	}


static func plan_fingerprint(plan: Dictionary) -> String:
	var normalized := {
		"segments": _normalized_segments(plan.get("segments", [])),
		"runs": _normalized_runs(plan.get("runs", [])),
		"cliffs": _normalized_cliffs(plan.get("cliffs", [])),
		"foam": _normalized_foam(plan.get("foam", [])),
		"floor_band": _normalized_floor_band(plan.get("floor_band", [])),
	}
	return JSON.stringify(normalized)


static func _extract_segments(
	floor_cells: Dictionary,
	ocean_cells: Dictionary,
	cell_world_size: float
) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var ordered_floor := floor_cells.keys()
	ordered_floor.sort_custom(_cell_less)
	for cell_variant in ordered_floor:
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		for direction in CARDINALS:
			var ocean_cell := cell + direction
			if not ocean_cells.has(ocean_cell):
				continue
			var endpoints := _directed_boundary_endpoints(cell, direction)
			var start_grid := endpoints[0] as Vector2
			var end_grid := endpoints[1] as Vector2
			var start_world := start_grid * cell_world_size
			var end_world := end_grid * cell_world_size
			segments.append({
				"id": segments.size(),
				"floor_cell": cell,
				"ocean_cell": ocean_cell,
				"start_grid": start_grid,
				"end_grid": end_grid,
				"start_world": start_world,
				"end_world": end_world,
				"tangent": (end_world - start_world).normalized(),
				"outward_normal": Vector2(direction),
				"facing": _facing_for_direction(direction),
				"length_px": start_world.distance_to(end_world),
			})
	return segments


static func _order_segments_into_runs(segments: Array[Dictionary]) -> Array[Dictionary]:
	var by_start: Dictionary = {}
	var incoming: Dictionary = {}
	for segment in segments:
		var start_key := _point_key(segment["start_grid"] as Vector2)
		var end_key := _point_key(segment["end_grid"] as Vector2)
		if not by_start.has(start_key):
			by_start[start_key] = []
		(by_start[start_key] as Array).append(segment)
		incoming[end_key] = int(incoming.get(end_key, 0)) + 1
	var unused: Dictionary = {}
	for segment in segments:
		unused[int(segment["id"])] = segment
	var starts: Array[Dictionary] = []
	for segment in segments:
		var start_key := _point_key(segment["start_grid"] as Vector2)
		if int(incoming.get(start_key, 0)) == 0:
			starts.append(segment)
	starts.sort_custom(_segment_less)
	var runs: Array[Dictionary] = []
	for start_segment in starts:
		if unused.has(int(start_segment["id"])):
			runs.append(_walk_run(start_segment, unused, by_start))
	while not unused.is_empty():
		var remaining := unused.values() as Array
		remaining.sort_custom(_segment_less)
		runs.append(_walk_run(remaining[0] as Dictionary, unused, by_start))
	for run_index in range(runs.size()):
		runs[run_index]["index"] = run_index
	return runs


static func _walk_run(
	start_segment: Dictionary,
	unused: Dictionary,
	by_start: Dictionary
) -> Dictionary:
	var ordered: Array[Dictionary] = []
	var current := start_segment
	var first_point := current["start_grid"] as Vector2
	var cumulative := 0.0
	while not current.is_empty() and unused.has(int(current["id"])):
		unused.erase(int(current["id"]))
		current = current.duplicate(true)
		current["cumulative_arc_distance"] = cumulative
		cumulative += float(current["length_px"])
		ordered.append(current)
		var end_grid := current["end_grid"] as Vector2
		var candidates: Array = by_start.get(_point_key(end_grid), []) as Array
		current = _choose_next_segment(candidates, unused, current)
		if end_grid.is_equal_approx(first_point) and current.is_empty():
			break
	var points: Array[Vector2] = []
	if not ordered.is_empty():
		points.append(ordered[0]["start_grid"] as Vector2)
		for segment in ordered:
			points.append(segment["end_grid"] as Vector2)
	return {
		"segments": ordered,
		"points_grid": points,
		"length_px": cumulative,
		"facing": String(ordered[0]["facing"]) if not ordered.is_empty() else "",
		"closed": points.size() > 2 and points[0].is_equal_approx(points[-1]),
	}


static func _choose_next_segment(
	candidates: Array,
	unused: Dictionary,
	previous: Dictionary
) -> Dictionary:
	var available: Array[Dictionary] = []
	for candidate_variant in candidates:
		var candidate := candidate_variant as Dictionary
		if unused.has(int(candidate["id"])):
			available.append(candidate)
	if available.is_empty():
		return {}
	var previous_tangent := previous["tangent"] as Vector2
	available.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score := _turn_score(previous_tangent, a["tangent"] as Vector2)
		var b_score := _turn_score(previous_tangent, b["tangent"] as Vector2)
		if not is_equal_approx(a_score, b_score):
			return a_score < b_score
		return _segment_less(a, b)
	)
	return available[0]


static func _build_cliff_placements(
	runs: Array[Dictionary],
	floor_cells: Dictionary,
	seed: int,
	spacing: float,
	cell_world_size: float,
	corner_exclusion: float
) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	for run in runs:
		var corners := _classify_run_corners(run, floor_cells, cell_world_size)
		var exclusions: Array[float] = []
		for corner_variant in corners:
			var corner := corner_variant as Dictionary
			exclusions.append(float(corner["arc_distance_px"]))
			placements.append(corner)
		var length := float(run.get("length_px", 0.0))
		var distance := 0.0
		var sample_index := 0
		var recent_assets: Array[String] = []
		var since_canonical := 0
		while distance < length - 0.001 or (is_zero_approx(distance) and is_zero_approx(length)):
			if not _inside_corner_exclusion(
				distance, exclusions, length, bool(run.get("closed", false)), corner_exclusion
			):
				var sample := _sample_run(run, distance, cell_world_size)
				if not sample.is_empty():
					var facing := String(sample.get("facing", "n"))
					var asset_key := "edge_%s" % facing
					var kind := "edge"
					if facing in ["n", "s"]:
						asset_key = _select_straight_asset(
							seed,
							int(run.get("index", 0)),
							sample_index,
							facing,
							recent_assets,
							since_canonical
						)
						kind = "face_slice" if asset_key.begins_with("face_slice") else "edge"
					if kind == "edge":
						since_canonical = 0
					else:
						since_canonical += 1
					recent_assets.append(asset_key)
					if recent_assets.size() > 3:
						recent_assets.pop_front()
					placements.append(_placement_from_sample(
						run, distance, sample, kind, asset_key, cell_world_size
					))
			distance += spacing
			sample_index += 1
	placements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["run_index"]) != int(b["run_index"]):
			return int(a["run_index"]) < int(b["run_index"])
		if not is_equal_approx(float(a["arc_distance_px"]), float(b["arc_distance_px"])):
			return float(a["arc_distance_px"]) < float(b["arc_distance_px"])
		return String(a["kind"]) < String(b["kind"])
	)
	return placements


static func _placement_from_sample(
	run: Dictionary,
	distance: float,
	sample: Dictionary,
	kind: String,
	asset_key: String,
	cell_world_size: float
) -> Dictionary:
	var position_grid := sample.get("position_grid", Vector2.ZERO) as Vector2
	return {
		"kind": kind,
		"asset_key": asset_key,
		"run_index": int(run.get("index", 0)),
		"arc_distance_px": clampf(distance, 0.0, float(run.get("length_px", 0.0))),
		"position_grid": position_grid,
		"position_world": position_grid * cell_world_size,
		"facing": sample["facing"],
		"outward_normal": sample["outward_normal"],
		"corner_vertex_grid": null,
	}


static func _classify_run_corners(
	run: Dictionary,
	floor_cells: Dictionary,
	cell_world_size: float
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var segments := run.get("segments", []) as Array
	if segments.size() < 2:
		return result
	var first_index := 0 if bool(run.get("closed", false)) else 1
	for current_index in range(first_index, segments.size()):
		var previous_index := posmod(current_index - 1, segments.size())
		var previous := segments[previous_index] as Dictionary
		var current := segments[current_index] as Dictionary
		if String(previous["facing"]) == String(current["facing"]):
			continue
		var vertex := current["start_grid"] as Vector2
		var topology := _classify_vertex(vertex, floor_cells)
		if topology.is_empty():
			continue
		var kind := String(topology["kind"])
		var direction := String(topology["direction"])
		var distance := float(current.get("cumulative_arc_distance", 0.0))
		var facing := String(current.get("facing", "n"))
		result.append({
			"kind": kind,
			"asset_key": "%s_%s" % [kind, direction],
			"run_index": int(run.get("index", 0)),
			"arc_distance_px": distance,
			"position_grid": vertex,
			"position_world": vertex * cell_world_size,
			"facing": facing,
			"outward_normal": current.get("outward_normal", Vector2.ZERO),
			"corner_vertex_grid": vertex,
		})
	return result


static func _classify_vertex(vertex: Vector2, floor_cells: Dictionary) -> Dictionary:
	var origin := Vector2i(roundi(vertex.x), roundi(vertex.y))
	var quadrants := {
		"nw": origin + Vector2i(-1, -1),
		"ne": origin + Vector2i(0, -1),
		"sw": origin + Vector2i(-1, 0),
		"se": origin,
	}
	var occupied: Array[String] = []
	var empty: Array[String] = []
	for direction in ["ne", "nw", "se", "sw"]:
		if floor_cells.has(quadrants[direction]):
			occupied.append(direction)
		else:
			empty.append(direction)
	if occupied.size() == 1:
		return {"kind": "outer_corner", "direction": occupied[0]}
	if occupied.size() == 3:
		return {"kind": "inner_corner", "direction": empty[0]}
	return {}


static func _inside_corner_exclusion(
	distance: float,
	corners: Array[float],
	length: float,
	closed: bool,
	exclusion: float
) -> bool:
	for corner_distance in corners:
		var delta := absf(distance - corner_distance)
		if closed:
			delta = minf(delta, maxf(0.0, length - delta))
		if delta < exclusion - 0.001:
			return true
	return false


static func _select_straight_asset(
	seed: int,
	run_index: int,
	sample_index: int,
	facing: String,
	recent: Array[String],
	since_canonical: int
) -> String:
	var canonical := "edge_%s" % facing
	if since_canonical >= 3:
		return canonical
	var hash := absi(seed * 83492791 ^ run_index * 73856093 ^ sample_index * 19349663)
	var roll := hash % 100
	var selected := canonical
	if roll >= 45 and roll < 75:
		selected = "face_slice_01"
	elif roll >= 75 and roll < 90:
		selected = "face_slice_wet_01"
	elif roll >= 90:
		selected = "face_slice_mossy_01"
	if recent.size() >= 2 and recent[-1] == selected and recent[-2] == selected:
		return canonical
	return selected


static func _sample_run(
	run: Dictionary,
	distance: float,
	cell_world_size: float
) -> Dictionary:
	var clamped_distance := clampf(distance, 0.0, float(run.get("length_px", 0.0)))
	var segments := run.get("segments", []) as Array
	for segment_index in range(segments.size()):
		var segment := segments[segment_index] as Dictionary
		var start_distance := float(segment["cumulative_arc_distance"])
		var length := float(segment["length_px"])
		if clamped_distance <= start_distance + length + 0.001 \
				or segment_index == segments.size() - 1:
			var ratio := clampf((clamped_distance - start_distance) / maxf(length, 0.001), 0.0, 1.0)
			return {
				"position_grid": (segment["start_grid"] as Vector2).lerp(
					segment["end_grid"] as Vector2,
					ratio
				),
				"facing": segment["facing"],
				"outward_normal": segment["outward_normal"],
				"position_world": (segment["start_world"] as Vector2).lerp(
					segment["end_world"] as Vector2,
					ratio
				),
			}
	return {}


static func _build_foam_plan(
	segments: Array[Dictionary],
	floor_cells: Dictionary,
	ocean_cells: Dictionary
) -> Array[Dictionary]:
	var boundary_ocean: Dictionary = {}
	for segment in segments:
		boundary_ocean[segment["ocean_cell"] as Vector2i] = true
		var floor_cell := segment["floor_cell"] as Vector2i
		for diagonal_variant in [
			Vector2i(-1, -1),
			Vector2i(1, -1),
			Vector2i(-1, 1),
			Vector2i(1, 1),
		]:
			var diagonal := diagonal_variant as Vector2i
			var diagonal_cell: Vector2i = floor_cell + diagonal
			if ocean_cells.has(diagonal_cell):
				boundary_ocean[diagonal_cell] = true
	var cells := boundary_ocean.keys()
	cells.sort_custom(_cell_less)
	var result: Array[Dictionary] = []
	for cell_variant in cells:
		var cell := cell_variant as Vector2i
		var topology_keys: Array[String] = OCEAN_SHORE_TOPOLOGY_RESOLVER.resolve(
			cell,
			floor_cells
		)
		var source_ids: Array[int] = []
		for topology_key in topology_keys:
			var source_id := int(FOAM_SOURCE_IDS.get(topology_key, -1))
			if source_id >= 0:
				source_ids.append(source_id)
		if not source_ids.is_empty():
			result.append({
				"cell": cell,
				"topology_keys": topology_keys,
				"source_ids": source_ids,
			})
	return result


static func _build_floor_band_plan(
	floor_cells: Dictionary,
	ocean_cells: Dictionary,
	seed: int,
	band_width: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if band_width <= 0:
		return result
	var cells := floor_cells.keys()
	cells.sort_custom(_cell_less)
	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var distance := ocean_manhattan_distance(cell, ocean_cells, band_width)
		if distance > band_width:
			continue
		var variation := _cell_hash(cell + Vector2i(2861, 1877), seed) % 100
		var source_id := FLOOR_SOURCE_ROCK
		if distance == 1:
			source_id = FLOOR_SOURCE_ROCK if variation < 70 else FLOOR_SOURCE_CRACKED
		elif distance == 2:
			if variation < 45:
				source_id = FLOOR_SOURCE_ROCK
			elif variation < 80:
				source_id = FLOOR_SOURCE_CRACKED
			else:
				source_id = FLOOR_SOURCE_WET
		else:
			source_id = FLOOR_SOURCE_ROCK if variation < 65 else FLOOR_SOURCE_CRACKED
		result.append({"cell": cell, "distance": distance, "source_id": source_id})
	return result


static func ocean_manhattan_distance(
	cell: Vector2i,
	ocean_cells: Dictionary,
	max_distance: int
) -> int:
	for distance in range(1, max_distance + 1):
		for x_offset in range(-distance, distance + 1):
			var y_offset := distance - absi(x_offset)
			if ocean_cells.has(cell + Vector2i(x_offset, y_offset)):
				return distance
			if y_offset > 0 and ocean_cells.has(cell + Vector2i(x_offset, -y_offset)):
				return distance
	return max_distance + 1


static func _directed_boundary_endpoints(
	cell: Vector2i,
	direction: Vector2i
) -> Array[Vector2]:
	var x := float(cell.x)
	var y := float(cell.y)
	if direction == Vector2i.UP:
		return [Vector2(x + 1.0, y), Vector2(x, y)]
	if direction == Vector2i.RIGHT:
		return [Vector2(x + 1.0, y + 1.0), Vector2(x + 1.0, y)]
	if direction == Vector2i.DOWN:
		return [Vector2(x, y + 1.0), Vector2(x + 1.0, y + 1.0)]
	return [Vector2(x, y), Vector2(x, y + 1.0)]


static func _facing_for_direction(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "n"
	if direction == Vector2i.RIGHT:
		return "e"
	if direction == Vector2i.DOWN:
		return "s"
	return "w"


static func _turn_score(previous: Vector2, next: Vector2) -> float:
	var cross := previous.cross(next)
	var dot := previous.dot(next)
	if dot > 0.5:
		return 0.0
	if cross < -0.5:
		return 1.0
	if cross > 0.5:
		return 2.0
	return 3.0


static func _point_key(point: Vector2) -> String:
	return "%d:%d" % [roundi(point.x), roundi(point.y)]


static func _cell_less(a: Variant, b: Variant) -> bool:
	var a_cell := a as Vector2i
	var b_cell := b as Vector2i
	return a_cell.y < b_cell.y or (a_cell.y == b_cell.y and a_cell.x < b_cell.x)


static func _segment_less(a: Dictionary, b: Dictionary) -> bool:
	var a_start := a["start_grid"] as Vector2
	var b_start := b["start_grid"] as Vector2
	if not is_equal_approx(a_start.y, b_start.y):
		return a_start.y < b_start.y
	if not is_equal_approx(a_start.x, b_start.x):
		return a_start.x < b_start.x
	return int(a["id"]) < int(b["id"])


static func _cell_hash(cell: Vector2i, seed: int) -> int:
	var hashed := int(cell.x) * 73856093
	hashed ^= int(cell.y) * 19349663
	hashed ^= seed * 83492791
	return absi(hashed)


static func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


static func _add_extra_foam_sprite(
	foam_tilemap: TileMapLayer,
	parent: Node2D,
	cell: Vector2i,
	source_id: int
) -> void:
	if parent == null or foam_tilemap.tile_set == null:
		return
	var source := foam_tilemap.tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null or source.texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "ShoreOverlay_%d_%d_%d" % [cell.x, cell.y, source_id]
	sprite.texture = source.texture
	sprite.position = foam_tilemap.map_to_local(cell)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)


static func _sorted_cell_arrays(cells: Dictionary) -> Array[Array]:
	var keys := cells.keys()
	keys.sort_custom(_cell_less)
	var result: Array[Array] = []
	for cell_variant in keys:
		if cell_variant is Vector2i:
			var cell := cell_variant as Vector2i
			result.append([cell.x, cell.y])
	return result


static func _cell_dictionary(values: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not values is Array:
		return result
	for value_variant in values as Array:
		if value_variant is Array and (value_variant as Array).size() >= 2:
			var value := value_variant as Array
			result[Vector2i(int(value[0]), int(value[1]))] = true
	return result


static func _normalized_segments(values: Variant) -> Array:
	var result := []
	for value_variant in values as Array:
		var value := value_variant as Dictionary
		result.append([
			value["start_grid"], value["end_grid"], value["facing"],
			value["floor_cell"], value["ocean_cell"],
		])
	return result


static func _normalized_runs(values: Variant) -> Array:
	var result := []
	for value_variant in values as Array:
		var value := value_variant as Dictionary
		result.append([value["points_grid"], value["length_px"], value["closed"]])
	return result


static func _normalized_cliffs(values: Variant) -> Array:
	var result := []
	for value_variant in values as Array:
		var value := value_variant as Dictionary
		result.append([
			value["kind"],
			value["asset_key"],
			value["position_grid"],
			value["facing"],
			value["arc_distance_px"],
			value.get("corner_vertex_grid"),
		])
	return result


static func _normalized_foam(values: Variant) -> Array:
	var result := []
	for value_variant in values as Array:
		var value := value_variant as Dictionary
		result.append([value["cell"], value["topology_keys"], value["source_ids"]])
	return result


static func _normalized_floor_band(values: Variant) -> Array:
	var result := []
	for value_variant in values as Array:
		var value := value_variant as Dictionary
		result.append([value["cell"], value["distance"], value["source_id"]])
	return result
