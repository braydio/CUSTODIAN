extends RefCounted
class_name ProcgenRoadSemanticsResolver

const ROAD_SEGMENT_LENGTH := 24
const ROAD_RUN_MIN := 10
const ROAD_RUN_MAX := 16
const ROAD_HALF_WIDTH := 2
const ROAD_START_CLEARANCE := 12
const ROAD_SEGMENT_CHANCE_PERCENT := 45
const NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const EXCLUDED_REGION_TOKENS: Array[String] = [
	"authored", "story_room", "faction_", "interior", "threshold",
]


func resolve(context: Dictionary) -> Dictionary:
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var wall_cells: Dictionary = context.get("wall_cells", {})
	var chasm_cells: Dictionary = context.get("chasm_cells", {})
	var ocean_cells: Dictionary = context.get("ocean_cells", {})
	var route_cells: Dictionary = context.get("route_cells", {})
	var centerline: Array[Vector2i] = _sorted_cells(context.get("route_centerline_cells", []))
	var centerline_distance: Dictionary = context.get("centerline_distance", {})
	var reserved_cells: Dictionary = context.get("reserved_cells", {})
	var region_kinds: Dictionary = context.get("region_kind_by_cell", {})
	var seed := int(context.get("seed", 0))
	var spawn: Vector2i = context.get("spawn_cell", Vector2i.ZERO)
	var arcs := _build_route_arc_distance(centerline, spawn)
	var segments: Dictionary = {}
	for cell: Vector2i in centerline:
		if not arcs.has(cell):
			continue
		var segment := int(arcs[cell]) / ROAD_SEGMENT_LENGTH
		if not segments.has(segment):
			segments[segment] = []
		(segments[segment] as Array).append(cell)
	var segment_ids: Array[int] = []
	for key: Variant in segments.keys():
		segment_ids.append(int(key))
	segment_ids.sort()
	var selected_segments: Array[int] = []
	var last_selected := -999999
	for segment: int in segment_ids:
		if segment == last_selected + 1:
			continue
		if _stable_hash(seed, segment, 0x524F4144) % 100 < ROAD_SEGMENT_CHANCE_PERCENT:
			selected_segments.append(segment)
			last_selected = segment
	var road_cells := _expand_selected_segments(
		selected_segments, segments, arcs, seed, floor_cells, wall_cells,
		chasm_cells, ocean_cells, route_cells, centerline_distance,
		reserved_cells, region_kinds
	)
	var eligible_arc_cells := _eligible_arc_cells(
		centerline, arcs, floor_cells, wall_cells, chasm_cells, ocean_cells,
		route_cells, reserved_cells, region_kinds
	)
	if eligible_arc_cells.size() >= 48 and road_cells.is_empty():
		var eligible_arcs: Array[int] = []
		for cell: Vector2i in eligible_arc_cells:
			eligible_arcs.append(int(arcs[cell]))
		eligible_arcs.sort()
		var median_arc := eligible_arcs[eligible_arcs.size() / 2]
		var fallback_order: Array[int] = []
		for cell: Vector2i in eligible_arc_cells:
			var segment := int(arcs[cell]) / ROAD_SEGMENT_LENGTH
			if not fallback_order.has(segment):
				fallback_order.append(segment)
		fallback_order.sort_custom(func(a: int, b: int) -> bool:
			var a_distance := _segment_arc_distance(a, median_arc, eligible_arc_cells, arcs)
			var b_distance := _segment_arc_distance(b, median_arc, eligible_arc_cells, arcs)
			return a_distance < b_distance or (a_distance == b_distance and a < b)
		)
		for fallback_segment: int in fallback_order:
			var attempt := _expand_selected_segments(
				[fallback_segment], segments, arcs, seed, floor_cells, wall_cells,
				chasm_cells, ocean_cells, route_cells, centerline_distance,
				reserved_cells, region_kinds
			)
			if not attempt.is_empty():
				road_cells = attempt
				break
	var apron := _build_service_apron(context, floor_cells, wall_cells, chasm_cells, ocean_cells, reserved_cells, region_kinds)
	var parking := apron.duplicate(true)
	var fragment_count := _count_components(road_cells)
	var fingerprint := _fingerprint(road_cells, apron, parking)
	return {
		"ruined_road_cells": road_cells,
		"service_hardstand_cells": apron,
		"parking_cells": parking,
		"summary": {
			"ruined_road_cell_count": road_cells.size(),
			"ruined_road_fragment_count": fragment_count,
			"service_hardstand_cell_count": apron.size(),
			"parking_cell_count": parking.size(),
			"fingerprint": fingerprint,
		},
		"fingerprint": fingerprint,
	}


func _build_route_arc_distance(centerline: Array[Vector2i], spawn: Vector2i) -> Dictionary:
	var members: Dictionary = {}
	for cell: Vector2i in centerline:
		members[cell] = true
	if members.is_empty():
		return {}
	var start := centerline[0]
	var best_distance := start.distance_squared_to(spawn)
	for cell: Vector2i in centerline:
		var distance := cell.distance_squared_to(spawn)
		if distance < best_distance or (distance == best_distance and _cell_less(cell, start)):
			start = cell
			best_distance = distance
	var result: Dictionary = {start: 0}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var neighbors: Array[Vector2i] = []
		for delta: Vector2i in NEIGHBORS:
			var next := current + delta
			if members.has(next) and not result.has(next):
				neighbors.append(next)
		neighbors.sort_custom(_cell_less)
		for next: Vector2i in neighbors:
			result[next] = int(result[current]) + 1
			queue.append(next)
	# Main-route centerlines should be connected. Keep disconnected authored
	# fragments deterministic without treating input array order as geometry.
	var unreachable: Array[Vector2i] = []
	for cell: Vector2i in centerline:
		if not result.has(cell): unreachable.append(cell)
	unreachable.sort_custom(_cell_less)
	while not unreachable.is_empty():
		var root: Vector2i = unreachable.pop_front()
		var max_arc := 0
		for arc_value: Variant in result.values():
			max_arc = maxi(max_arc, int(arc_value))
		result[root] = max_arc + 1
		queue = [root]
		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			for delta: Vector2i in NEIGHBORS:
				var next := current + delta
				if members.has(next) and not result.has(next):
					result[next] = int(result[current]) + 1
					unreachable.erase(next)
					queue.append(next)
	return result


func _expand_selected_segments(selected: Array, segments: Dictionary, arcs: Dictionary,
		seed: int, floor_cells: Dictionary, wall_cells: Dictionary,
		chasm_cells: Dictionary, ocean_cells: Dictionary, route_cells: Dictionary,
		centerline_distance: Dictionary, reserved_cells: Dictionary,
		region_kinds: Dictionary) -> Dictionary:
	var cores: Dictionary = {}
	for segment_value: Variant in selected:
		var segment := int(segment_value)
		var start_offset := 2 + _stable_hash(seed, segment, 0x53544152) % 5
		var run_length := ROAD_RUN_MIN + _stable_hash(seed, segment, 0x4C454E47) % (ROAD_RUN_MAX - ROAD_RUN_MIN + 1)
		var begin_arc := segment * ROAD_SEGMENT_LENGTH + start_offset
		var end_arc := mini(segment * ROAD_SEGMENT_LENGTH + ROAD_SEGMENT_LENGTH, begin_arc + run_length)
		for cell: Vector2i in segments.get(segment, []):
			var arc := int(arcs[cell])
			if arc >= ROAD_START_CLEARANCE and arc >= begin_arc and arc < end_arc:
				cores[cell] = true
	var result: Dictionary = {}
	for cell: Vector2i in cores.keys():
		for candidate_value: Variant in floor_cells.keys():
			if not candidate_value is Vector2i:
				continue
			var candidate := candidate_value as Vector2i
			var manhattan_to_core := absi(candidate.x - cell.x) + absi(candidate.y - cell.y)
			if manhattan_to_core > ROAD_HALF_WIDTH:
				continue
			if int(centerline_distance.get(candidate, 999999)) > ROAD_HALF_WIDTH:
				continue
			if _nearest_arc_within(candidate, arcs) < ROAD_START_CLEARANCE:
				continue
			if not route_cells.has(candidate) or wall_cells.has(candidate) or chasm_cells.has(candidate) or ocean_cells.has(candidate) or reserved_cells.has(candidate):
				continue
			if _excluded_region(region_kinds.get(candidate, "")):
				continue
			result[candidate] = true
	return result


func _eligible_arc_cells(centerline: Array[Vector2i], arcs: Dictionary,
		floor_cells: Dictionary, wall_cells: Dictionary, chasm_cells: Dictionary,
		ocean_cells: Dictionary, route_cells: Dictionary, reserved_cells: Dictionary,
		region_kinds: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in centerline:
		if int(arcs.get(cell, 0)) < ROAD_START_CLEARANCE:
			continue
		if floor_cells.has(cell) and route_cells.has(cell) and not wall_cells.has(cell) \
				and not chasm_cells.has(cell) and not ocean_cells.has(cell) \
				and not reserved_cells.has(cell) and not _excluded_region(region_kinds.get(cell, "")):
			result.append(cell)
	return result


func _build_service_apron(context: Dictionary, floor_cells: Dictionary,
		wall_cells: Dictionary, chasm_cells: Dictionary, ocean_cells: Dictionary,
		reserved_cells: Dictionary, region_kinds: Dictionary) -> Dictionary:
	var ingress: Array = context.get("compound_ingress_cells", [])
	var centerline: Array[Vector2i] = _sorted_cells(context.get("route_centerline_cells", []))
	if ingress.is_empty() or centerline.is_empty():
		return {}
	var primary_ingress: Vector2i = ingress[0]
	var compound_rect: Rect2i = context.get("compound_rect", Rect2i())
	var anchor := Vector2i.ZERO
	var found_anchor := false
	var best_distance := 13
	for cell: Vector2i in centerline:
		if compound_rect.has_point(cell) or not floor_cells.has(cell) or wall_cells.has(cell) \
				or chasm_cells.has(cell) or ocean_cells.has(cell):
			continue
		var distance := absi(cell.x - primary_ingress.x) + absi(cell.y - primary_ingress.y)
		if distance < best_distance or (distance == best_distance and (not found_anchor or _cell_less(cell, anchor))):
			best_distance = distance
			anchor = cell
			found_anchor = true
	if best_distance > 12 or not found_anchor:
		return {}
	var accepted: Dictionary = {}
	var rect := Rect2i(anchor - Vector2i(4, 3), Vector2i(9, 7))
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if not floor_cells.has(cell) or wall_cells.has(cell) or chasm_cells.has(cell) \
					or ocean_cells.has(cell) or reserved_cells.has(cell) or _excluded_region(region_kinds.get(cell, "")):
				continue
			accepted[cell] = true
	return accepted if accepted.size() >= 30 else {}


func _excluded_region(value: Variant) -> bool:
	var region := String(value).to_lower()
	for token: String in EXCLUDED_REGION_TOKENS:
		if region.contains(token): return true
	return false


func _count_components(cells: Dictionary) -> int:
	var remaining := cells.duplicate()
	var count := 0
	while not remaining.is_empty():
		count += 1
		var starts := _sorted_cells(remaining.keys())
		var queue: Array[Vector2i] = [starts[0]]
		remaining.erase(starts[0])
		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			for delta: Vector2i in NEIGHBORS:
				var next := current + delta
				if remaining.has(next):
					remaining.erase(next)
					queue.append(next)
	return count


func _segment_arc_distance(segment: int, median_arc: int,
		eligible_cells: Array[Vector2i], arcs: Dictionary) -> int:
	var best := 999999
	for cell: Vector2i in eligible_cells:
		if int(arcs[cell]) / ROAD_SEGMENT_LENGTH == segment:
			best = mini(best, absi(int(arcs[cell]) - median_arc))
	return best


func _fingerprint(roads: Dictionary, apron: Dictionary, parking: Dictionary) -> String:
	var parts: Array[String] = []
	for label in ["road", "apron", "parking"]:
		var source: Dictionary = roads if label == "road" else (apron if label == "apron" else parking)
		for cell: Vector2i in _sorted_cells(source.keys()):
			parts.append("%s:%d,%d" % [label, cell.x, cell.y])
	return "|".join(parts).sha256_text()


func _stable_hash(seed: int, index: int, salt: int) -> int:
	var value: int = 2166136261
	for byte: int in ("%d:%d:%d" % [seed, index, salt]).to_utf8_buffer():
		value = ((value ^ byte) * 16777619) & 0x7fffffff
	return value


func _nearest_arc_within(cell: Vector2i, arcs: Dictionary) -> int:
	var nearest_distance := ROAD_HALF_WIDTH + 1
	var nearest_arc := -1
	for center_value: Variant in arcs.keys():
		if not center_value is Vector2i:
			continue
		var center := center_value as Vector2i
		var distance := absi(center.x - cell.x) + absi(center.y - cell.y)
		if distance < nearest_distance or (distance == nearest_distance and int(arcs[center]) < nearest_arc):
			nearest_distance = distance
			nearest_arc = int(arcs[center])
	return nearest_arc if nearest_distance <= ROAD_HALF_WIDTH else -1


func _sorted_cells(values: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value: Variant in values:
		if value is Vector2i and not result.has(value): result.append(value)
	result.sort_custom(_cell_less)
	return result


func _cell_less(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
