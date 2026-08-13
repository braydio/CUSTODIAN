class_name PersistentCompoundLayoutPlanner
extends RefCounted

## Deterministic semantic-campus planner. It derives geometry only and owns no
## runtime or simulation state.

const DEFAULT_GRAPH_PATH := "res://game/world/compound/rooms/graphs/persistent_compound_layout_v1.json"
const COMMAND_TYPE := "command_post"
const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _graph: RoomGraph
var _rng := RandomNumberGenerator.new()
var _seed := 0
var _config: Dictionary = {}
var _target_room_count := 0


func _init(graph: RoomGraph = null) -> void:
	_graph = graph


func load_default_graph() -> bool:
	_graph = RoomGraph.new()
	return _graph.load_from_json_file(DEFAULT_GRAPH_PATH)


func generate_layout(seed: int, compound_rect: Rect2i, ingress: Array[Vector2i] = []) -> Dictionary:
	_seed = seed
	_rng.seed = seed
	if _graph == null and not load_default_graph():
		return _invalid("graph_load_failed", compound_rect, ingress)
	_config = _graph.get_layout_config()
	var inner := compound_rect.grow(-int(_config.get("outer_clearance_tiles", 4)))
	if inner.size.x < 24 or inner.size.y < 20:
		return _invalid("compound_bounds_too_small", compound_rect, ingress)

	var target := _rng.randi_range(
		int(_config.get("target_room_count_min", 10)),
		int(_config.get("target_room_count_max", 13))
	)
	_target_room_count = target
	var assignments: Array[Dictionary] = []
	var rooms: Array[Dictionary] = []
	for roster_attempt in range(12):
		_rng.seed = seed + roster_attempt * 104729
		assignments = _select_assignments(target)
		rooms = _place_rooms(assignments, compound_rect, inner)
		if rooms.size() == assignments.size() and _required_types_present(rooms):
			break
	if rooms.size() < assignments.size() or not _required_types_present(rooms):
		return _invalid("required_room_placement_failed", compound_rect, ingress)

	var connection_result := _connect_rooms(rooms, compound_rect)
	if not bool(connection_result.get("connected", false)):
		return _invalid("room_graph_disconnected", compound_rect, ingress)

	var connections: Array[Dictionary] = connection_result.get("connections", [])
	var corridor_cells: Array[Vector2i] = connection_result.get("corridor_cells", [])
	var room_cells := _rect_cell_set(rooms)
	var courtyard_cells: Array[Vector2i] = []
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			var cell := Vector2i(x, y)
			if not room_cells.has(cell):
				courtyard_cells.append(cell)

	var buildings: Array[Rect2i] = []
	var zone_counts := {"core": 0, "operational": 0, "perimeter": 0}
	var occupied_area := 0
	for room in rooms:
		var rect: Rect2i = room["rect"]
		buildings.append(rect)
		occupied_area += rect.get_area()
		var zone := String(room.get("zone", "operational"))
		zone_counts[zone] = int(zone_counts.get(zone, 0)) + 1
	var negative_ratio := 1.0 - float(occupied_area) / float(maxi(1, inner.get_area()))
	var command := _room_by_type(rooms, COMMAND_TYPE)
	var command_rect: Rect2i = command.get("rect", Rect2i())
	var terminal_anchor := command_rect.position + Vector2i(command_rect.size.x / 2, command_rect.size.y / 2)

	return {
		"valid": true,
		"schema_version": int(_config.get("schema_version", 1)),
		"rect": compound_rect,
		"ingress": ingress.duplicate(),
		"rooms": rooms,
		"connections": connections,
		"corridor_cells": corridor_cells,
		"courtyard_cells": courtyard_cells,
		"buildings": buildings,
		"primary_anchor": terminal_anchor,
		"terminal_anchor": terminal_anchor,
		"diagnostics": {
			"target_room_count": target,
			"actual_room_count": rooms.size(),
			"core_count": zone_counts["core"],
			"operational_count": zone_counts["operational"],
			"perimeter_count": zone_counts["perimeter"],
			"negative_space_ratio": negative_ratio,
			"connected": true,
			"fallbacks_used": 0,
		},
	}


func _select_assignments(target: int) -> Array[Dictionary]:
	var assignments: Array[Dictionary] = []
	var counts := {}
	for room_type_variant in _graph.get_available_types():
		var room_type := String(room_type_variant)
		if not _graph.is_required(room_type):
			continue
		for index in range(_graph.get_min_count(room_type)):
			assignments.append(_make_assignment(room_type, index + 1))
			counts[room_type] = int(counts.get(room_type, 0)) + 1

	while assignments.size() < target:
		var candidates: Array[String] = []
		var total_weight := 0.0
		for room_type_variant in _graph.get_available_types():
			var room_type := String(room_type_variant)
			if int(counts.get(room_type, 0)) >= _graph.get_max_count(room_type):
				continue
			var weight := maxf(0.0, float(_graph.get_room_config(room_type).get("selection_weight", 1.0)))
			if weight <= 0.0:
				continue
			candidates.append(room_type)
			total_weight += weight
		if candidates.is_empty():
			break
		var roll := _rng.randf_range(0.0, total_weight)
		var selected := candidates[-1]
		for room_type in candidates:
			roll -= float(_graph.get_room_config(room_type).get("selection_weight", 1.0))
			if roll <= 0.0:
				selected = room_type
				break
		var next_index := int(counts.get(selected, 0)) + 1
		assignments.append(_make_assignment(selected, next_index))
		counts[selected] = next_index

	assignments.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := int(a.get("placement_priority", 0))
		var pb := int(b.get("placement_priority", 0))
		return pa > pb if pa != pb else String(a["id"]) < String(b["id"])
	)
	return assignments


func _make_assignment(room_type: String, ordinal: int) -> Dictionary:
	var config := _graph.get_room_config(room_type).duplicate(true)
	var footprint_min := _vector2i_from_json(config.get("footprint_min", [8, 6]))
	var footprint_max := _vector2i_from_json(config.get("footprint_max", footprint_min))
	var width_floor := footprint_min.x
	var height_floor := footprint_min.y
	if _target_room_count <= 10:
		width_floor = maxi(footprint_min.x, footprint_max.x - 1)
		height_floor = maxi(footprint_min.y, footprint_max.y - 1)
	elif _target_room_count == 11:
		width_floor = int(ceil(float(footprint_min.x + footprint_max.x) * 0.5))
		height_floor = int(ceil(float(footprint_min.y + footprint_max.y) * 0.5))
	var width := _rng.randi_range(width_floor, maxi(width_floor, footprint_max.x))
	var height := _rng.randi_range(height_floor, maxi(height_floor, footprint_max.y))
	config["id"] = "%s_%02d" % [room_type, ordinal]
	config["type"] = room_type
	config["size"] = Vector2i(width, height)
	return config


func _place_rooms(assignments: Array[Dictionary], bounds: Rect2i, inner: Rect2i) -> Array[Dictionary]:
	for attempt in range(24):
		var result := _place_rooms_attempt(assignments, bounds, inner, attempt)
		if result.size() == assignments.size():
			return result
	return []


func _place_rooms_attempt(assignments: Array[Dictionary], bounds: Rect2i, inner: Rect2i, attempt: int) -> Array[Dictionary]:
	var placed: Array[Dictionary] = []
	var clearance := int(_config.get("room_clearance_tiles", 2))
	for assignment in assignments:
		var scored := _score_placement_candidates(assignment, assignment["size"], bounds, inner, placed, clearance, false)
		if scored.is_empty():
			var min_size := _vector2i_from_json(assignment.get("footprint_min", assignment["size"]))
			scored = _score_placement_candidates(assignment, min_size, bounds, inner, placed, clearance, false)
		if scored.is_empty():
			var min_size := _vector2i_from_json(assignment.get("footprint_min", assignment["size"]))
			scored = _score_placement_candidates(assignment, min_size, bounds, inner, placed, clearance, true)
		if scored.is_empty():
			return []
		scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var sa := float(a["score"])
			var sb := float(b["score"])
			if not is_equal_approx(sa, sb):
				return sa > sb
			return _stable_rect_rank(assignment["id"], a["rect"]) < _stable_rect_rank(assignment["id"], b["rect"])
		)
		var choice_count: int = mini(12, scored.size())
		var choice_index: int = int(abs(hash("%s:%d:%d" % [assignment["id"], _seed, attempt])) % choice_count)
		var chosen: Dictionary = scored[choice_index]
		var room := assignment.duplicate(true)
		room.erase("size")
		room["rect"] = chosen["rect"]
		room["center"] = Vector2i((chosen["rect"] as Rect2i).get_center())
		room["door_cells"] = []
		room["connection_ids"] = []
		placed.append(room)
	return placed


func _score_placement_candidates(
	assignment: Dictionary,
	size: Vector2i,
	bounds: Rect2i,
	inner: Rect2i,
	placed: Array[Dictionary],
	clearance: int,
	relaxed_zone: bool
) -> Array[Dictionary]:
	var scored: Array[Dictionary] = []
	for position in _candidate_positions(size, inner):
		var rect := Rect2i(position, size)
		if _overlaps_any(rect.grow(clearance), placed):
			continue
		if relaxed_zone:
			if not _edge_candidate_allowed(assignment, rect, bounds):
				continue
		elif not _zone_candidate_allowed(assignment, rect, bounds):
			continue
		scored.append({"rect": rect, "score": _score_candidate(assignment, rect, bounds, placed)})
	return scored


func _candidate_positions(size: Vector2i, inner: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(inner.position.y, inner.end.y - size.y + 1, 2):
		for x in range(inner.position.x, inner.end.x - size.x + 1, 2):
			result.append(Vector2i(x, y))
	return result


func _zone_candidate_allowed(assignment: Dictionary, rect: Rect2i, bounds: Rect2i) -> bool:
	var center := Vector2(rect.get_center())
	var bounds_center := Vector2(bounds.get_center())
	var normalized := Vector2(
		absf(center.x - bounds_center.x) / maxf(1.0, float(bounds.size.x) * 0.5),
		absf(center.y - bounds_center.y) / maxf(1.0, float(bounds.size.y) * 0.5)
	)
	var radial := maxf(normalized.x, normalized.y)
	match String(assignment.get("zone", "operational")):
		"core":
			if radial > 0.52:
				return false
		"operational":
			if radial < 0.22 or radial > 0.82:
				return false
		"perimeter":
			if radial < 0.58:
				return false

	var edge := String(assignment.get("edge_preference", "none"))
	var margin := int(_config.get("outer_clearance_tiles", 4)) + 5
	if edge == "north" and rect.position.y > bounds.position.y + margin:
		return false
	if edge == "south" and rect.end.y < bounds.end.y - margin:
		return false
	return true


func _edge_candidate_allowed(assignment: Dictionary, rect: Rect2i, bounds: Rect2i) -> bool:
	var edge := String(assignment.get("edge_preference", "none"))
	var margin := int(_config.get("outer_clearance_tiles", 4)) + 7
	if edge == "north":
		return rect.position.y <= bounds.position.y + margin
	if edge == "south":
		return rect.end.y >= bounds.end.y - margin
	return true


func _score_candidate(assignment: Dictionary, rect: Rect2i, bounds: Rect2i, placed: Array[Dictionary]) -> float:
	var center := Vector2(rect.get_center())
	var bounds_center := Vector2(bounds.get_center())
	var distance := center.distance_to(bounds_center)
	var score := 0.0
	match String(assignment.get("zone", "operational")):
		"core": score -= distance * 2.0
		"operational": score -= absf(distance - minf(bounds.size.x, bounds.size.y) * 0.28)
		"perimeter": score += distance * 1.5

	var edge := String(assignment.get("edge_preference", "none"))
	if edge == "north": score -= float(rect.position.y - bounds.position.y) * 3.0
	elif edge == "south": score -= float(bounds.end.y - rect.end.y) * 3.0
	elif edge == "any":
		score -= float(mini(mini(rect.position.x - bounds.position.x, bounds.end.x - rect.end.x), mini(rect.position.y - bounds.position.y, bounds.end.y - rect.end.y))) * 2.0

	var preferred: Array = assignment.get("preferred_neighbors", [])
	var nearest := INF
	for room in placed:
		var other_center := Vector2((room["rect"] as Rect2i).get_center())
		var d := center.distance_to(other_center)
		if preferred.has(String(room.get("type", ""))):
			score -= d * 0.9
		nearest = minf(nearest, d)
	if nearest < INF:
		score -= absf(nearest - 16.0) * 0.35

	# Penalize repeated center axes so the campus does not collapse into a grid.
	for room in placed:
		var other: Vector2i = room["center"]
		if abs(other.x - int(center.x)) <= 1: score -= 14.0
		if abs(other.y - int(center.y)) <= 1: score -= 10.0
	return score


func _connect_rooms(rooms: Array[Dictionary], bounds: Rect2i) -> Dictionary:
	var command := _room_by_type(rooms, COMMAND_TYPE)
	if command.is_empty():
		return {"connected": false}
	var connected := {String(command["id"]): true}
	var connections: Array[Dictionary] = []
	var corridor_set := {}
	while connected.size() < rooms.size():
		var best := {}
		var best_score := INF
		for child in rooms:
			if connected.has(String(child["id"])):
				continue
			for parent in rooms:
				if not connected.has(String(parent["id"])):
					continue
				if not _graph.allows_connection(String(parent["type"]), String(child["type"])):
					continue
				var score := Vector2(parent["center"]).distance_to(Vector2(child["center"]))
				if (child.get("preferred_neighbors", []) as Array).has(String(parent["type"])):
					score -= 18.0
				if _room_degree(parent, connections) >= 3:
					score += 22.0
				if score < best_score:
					best_score = score
					best = {"from": parent, "to": child}
		if best.is_empty():
			return {"connected": false}
		var connection := _build_connection(best["from"], best["to"], rooms, bounds, connections.size())
		if connection.is_empty():
			return {"connected": false}
		connections.append(connection)
		connected[String((best["to"] as Dictionary)["id"])] = true
		for cell in connection["path_cells"]:
			for expanded in _expand_corridor_cell(cell, int(_config.get("corridor_width_tiles", 3))):
				corridor_set[expanded] = true

	var corridor_cells: Array[Vector2i] = []
	var room_cells := _room_blocked_cells(rooms, [])
	var door_cells := {}
	for room in rooms:
		for door in room.get("door_cells", []):
			if door is Vector2i:
				door_cells[door] = true
	for cell in corridor_set.keys():
		if bounds.has_point(cell) and (not room_cells.has(cell) or door_cells.has(cell)):
			corridor_cells.append(cell)
	corridor_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	return {"connected": true, "connections": connections, "corridor_cells": corridor_cells}


func _build_connection(from_room: Dictionary, to_room: Dictionary, rooms: Array[Dictionary], bounds: Rect2i, index: int) -> Dictionary:
	var from_door := _door_toward(from_room["rect"], to_room["center"])
	var to_door := _door_toward(to_room["rect"], from_room["center"])
	var blocked := _room_blocked_cells(rooms, [])
	blocked.erase(from_door)
	blocked.erase(to_door)
	var path := _find_path(from_door, to_door, bounds.grow(-1), blocked)
	if path.is_empty():
		return {}
	var connection_id := "%s__%s" % [from_room["id"], to_room["id"]]
	(from_room["door_cells"] as Array).append_array(_door_width_cells(from_room["rect"], from_door))
	(to_room["door_cells"] as Array).append_array(_door_width_cells(to_room["rect"], to_door))
	(from_room["connection_ids"] as Array).append(connection_id)
	(to_room["connection_ids"] as Array).append(connection_id)
	return {
		"id": connection_id,
		"from_room_id": from_room["id"],
		"to_room_id": to_room["id"],
		"from_door": from_door,
		"to_door": to_door,
		"path_cells": path,
		"index": index,
	}


func _find_path(start: Vector2i, goal: Vector2i, bounds: Rect2i, blocked: Dictionary) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start]
	var head := 0
	var came_from := {start: start}
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		if current == goal:
			break
		var directions: Array[Vector2i] = CARDINALS.duplicate()
		directions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da := (current + a).distance_squared_to(goal)
			var db := (current + b).distance_squared_to(goal)
			return da < db if da != db else _stable_cell_rank(current + a) < _stable_cell_rank(current + b)
		)
		for direction: Vector2i in directions:
			var next_cell: Vector2i = current + direction
			if not bounds.has_point(next_cell) or came_from.has(next_cell):
				continue
			if blocked.has(next_cell) and next_cell != goal:
				continue
			came_from[next_cell] = current
			frontier.append(next_cell)
	if not came_from.has(goal):
		return []
	var reverse_path: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		reverse_path.append(cursor)
		cursor = came_from[cursor]
	reverse_path.append(start)
	reverse_path.reverse()
	return reverse_path


func _door_toward(rect: Rect2i, target: Vector2i) -> Vector2i:
	var center := Vector2i(rect.get_center())
	var delta := target - center
	if abs(delta.x) > abs(delta.y):
		return Vector2i(rect.end.x - 1 if delta.x > 0 else rect.position.x, center.y)
	return Vector2i(center.x, rect.end.y - 1 if delta.y > 0 else rect.position.y)


func _door_width_cells(rect: Rect2i, door: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var horizontal_wall := door.y == rect.position.y or door.y == rect.end.y - 1
	for offset in range(-1, 2):
		var cell := door + (Vector2i(offset, 0) if horizontal_wall else Vector2i(0, offset))
		if rect.has_point(cell):
			result.append(cell)
	return result


func _expand_corridor_cell(cell: Vector2i, width: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var radius := maxi(0, int(width / 2))
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			result.append(cell + Vector2i(x, y))
	return result


func _room_blocked_cells(rooms: Array[Dictionary], excluded_ids: Array[String]) -> Dictionary:
	var blocked := {}
	for room in rooms:
		if excluded_ids.has(String(room["id"])):
			continue
		var rect: Rect2i = room["rect"]
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				blocked[Vector2i(x, y)] = true
	return blocked


func _rect_cell_set(rooms: Array[Dictionary]) -> Dictionary:
	var cells := {}
	for room in rooms:
		var rect: Rect2i = room["rect"]
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				cells[Vector2i(x, y)] = true
	return cells


func _overlaps_any(candidate: Rect2i, rooms: Array[Dictionary]) -> bool:
	for room in rooms:
		if candidate.intersects(room["rect"]):
			return true
	return false


func _required_types_present(rooms: Array[Dictionary]) -> bool:
	for room_type_variant in _graph.get_available_types():
		var room_type := String(room_type_variant)
		if _graph.is_required(room_type) and _room_by_type(rooms, room_type).is_empty():
			return false
	return true


func _room_by_type(rooms: Array[Dictionary], room_type: String) -> Dictionary:
	for room in rooms:
		if String(room.get("type", "")) == room_type:
			return room
	return {}


func _room_degree(room: Dictionary, connections: Array[Dictionary]) -> int:
	var degree := 0
	for connection in connections:
		if connection.get("from_room_id") == room.get("id") or connection.get("to_room_id") == room.get("id"):
			degree += 1
	return degree


func _vector2i_from_json(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


func _stable_rect_rank(room_id: Variant, rect: Rect2i) -> int:
	return abs(hash("%s:%d:%d:%d" % [room_id, rect.position.x, rect.position.y, _seed]))


func _stable_cell_rank(cell: Vector2i) -> int:
	return abs(hash("%d:%d:%d" % [cell.x, cell.y, _seed]))


func _invalid(reason: String, rect: Rect2i, ingress: Array[Vector2i]) -> Dictionary:
	return {
		"valid": false,
		"schema_version": 1,
		"rect": rect,
		"ingress": ingress.duplicate(),
		"rooms": [],
		"connections": [],
		"corridor_cells": [],
		"courtyard_cells": [],
		"buildings": [],
		"diagnostics": {"connected": false, "failure_reason": reason, "fallbacks_used": 0},
	}
