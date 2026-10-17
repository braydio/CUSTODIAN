class_name PersistentCompoundLayoutPlanner
extends RefCounted

## Deterministic semantic-campus planner. It derives geometry only and owns no
## runtime or simulation state.

const DEFAULT_GRAPH_PATH := "res://game/world/compound/rooms/graphs/persistent_compound_layout_v1.json"
const ARCHETYPE_PROFILES_PATH := "res://game/world/compound/rooms/profiles/compound_archetype_profiles_v1.json"
const COMMAND_TYPE := "command_post"
const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

# Connected-bunker geometry (Type B). One compound reservation is split into two
# disjoint layers: a surface yard with access housings in the north band, and a
# wall-filled subsurface region below a solid separator. No cell belongs to both.
const BUNKER_GEOMETRY_ID := "connected_bunker_subsurface_v1"
const LAYER_SURFACE := "surface"
const LAYER_SUBSURFACE := "subsurface"
const BUNKER_ROOM_GAP := 1
const BUNKER_SPINE_WIDTH := 3
const BUNKER_SEPARATOR_ROWS := 2
const BUNKER_HOUSING_SIZE := Vector2i(9, 8)
const BUNKER_HOUSING_COUNT := 2
const BUNKER_YARD_APPROACH_ROWS := 4
const BUNKER_YARD_APRON_ROWS := 2
const BUNKER_MIN_SURFACE_ROWS := BUNKER_HOUSING_SIZE.y + BUNKER_YARD_APPROACH_ROWS + BUNKER_YARD_APRON_ROWS

var _graph: RoomGraph
var _rng := RandomNumberGenerator.new()
var _seed := 0
var _config: Dictionary = {}
var _archetype_profiles: Dictionary = {}
var _target_room_count := 0


func _init(graph: RoomGraph = null) -> void:
	_graph = graph


func load_default_graph() -> bool:
	_graph = RoomGraph.new()
	if not _graph.load_from_json_file(DEFAULT_GRAPH_PATH):
		return false
	return _load_archetype_profiles()


func generate_layout(
	seed: int,
	compound_rect: Rect2i,
	ingress: Array[Vector2i] = [],
	archetype_id: StringName = &""
) -> Dictionary:
	_seed = seed
	_rng.seed = seed
	if _graph == null and not load_default_graph():
		return _invalid("graph_load_failed", compound_rect, ingress)
	var profile_result := _resolve_archetype_profile(archetype_id)
	if not profile_result.get("valid", false):
		return _invalid("unknown_archetype_id", compound_rect, ingress)
	var archetype_profile: Dictionary = profile_result.get("profile", {})
	_config = _graph.get_layout_config()
	if String(archetype_profile.get("geometry_id", "")) == BUNKER_GEOMETRY_ID:
		return _generate_connected_bunker(compound_rect, ingress, archetype_profile)
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
	var fabricator_anchor := _pick_fabricator_anchor(rooms)
	var construction_zone_anchor := _pick_construction_zone_anchor(
		compound_rect,
		inner,
		rooms,
		fabricator_anchor
	)
	if fabricator_anchor == Vector2i.ZERO or construction_zone_anchor == Vector2i.ZERO:
		return _invalid("population_anchor_placement_failed", compound_rect, ingress)

	var layout := {
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
		"fabricator_anchor": fabricator_anchor,
		"construction_zone_anchor": construction_zone_anchor,
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
	if not archetype_profile.is_empty():
		var selected_id := String(archetype_profile.get("archetype_id", ""))
		var layer_id := String(archetype_profile.get("layer_id", ""))
		var profile_version := int(archetype_profile.get("profile_version", 0))
		layout["archetype_id"] = selected_id
		layout["layer_id"] = layer_id
		layout["archetype_profile_version"] = profile_version
		for room in layout["rooms"]:
			room["archetype_id"] = selected_id
			room["layer_id"] = layer_id
			room["archetype_profile_version"] = profile_version
		for connection in layout["connections"]:
			connection["archetype_id"] = selected_id
			connection["layer_id"] = layer_id
			connection["archetype_profile_version"] = profile_version
	return layout


func _load_archetype_profiles() -> bool:
	_archetype_profiles.clear()
	if not FileAccess.file_exists(ARCHETYPE_PROFILES_PATH):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARCHETYPE_PROFILES_PATH))
	if not parsed is Dictionary:
		return false
	var source := parsed as Dictionary
	if int(source.get("schema_version", 0)) != 1:
		return false
	var profiles: Variant = source.get("profiles", {})
	if not profiles is Dictionary:
		return false
	for required_id in ["legacy", "walled_yard", "connected_bunker"]:
		var profile: Variant = profiles.get(required_id)
		if not profile is Dictionary:
			return false
		var entry := (profile as Dictionary).duplicate(true)
		if String(entry.get("archetype_id", "")) != required_id:
			return false
		if String(entry.get("layer_id", "")) != "surface":
			return false
		if int(entry.get("profile_version", 0)) != 1:
			return false
		_archetype_profiles[required_id] = entry
	return true


func _resolve_archetype_profile(archetype_id: StringName) -> Dictionary:
	# An omitted ID is the compatibility path: preserve the exact legacy layout
	# dictionary so existing callers and serialized baselines remain unchanged.
	if archetype_id == &"":
		return {"valid": true, "profile": {}}
	var profile: Variant = _archetype_profiles.get(String(archetype_id))
	if not profile is Dictionary:
		return {"valid": false}
	return {"valid": true, "profile": (profile as Dictionary).duplicate(true)}


func _pick_fabricator_anchor(rooms: Array[Dictionary]) -> Vector2i:
	for preferred_type in ["fabrication", "maintenance", "service_annex"]:
		var room := _room_by_type(rooms, preferred_type)
		var rect: Rect2i = room.get("rect", Rect2i())
		if rect.size.x >= 3 and rect.size.y >= 3:
			return Vector2i(rect.get_center())
	return Vector2i.ZERO


func _pick_construction_zone_anchor(
	compound_rect: Rect2i,
	inner: Rect2i,
	rooms: Array[Dictionary],
	fabricator_anchor: Vector2i
) -> Vector2i:
	# Reserve a valid initial Capacitor footprint within the larger behavioral
	# zone; the zone's remaining area is still validated against live floor at use.
	const ZONE_SIZE := Vector2i(3, 2)
	var candidates: Array[Dictionary] = []
	for y in range(inner.position.y, inner.end.y - ZONE_SIZE.y + 1):
		for x in range(inner.position.x, inner.end.x - ZONE_SIZE.x + 1):
			var zone_rect := Rect2i(Vector2i(x, y), ZONE_SIZE)
			if _overlaps_any(zone_rect, rooms):
				continue
			var center := Vector2i(zone_rect.get_center())
			var edge_clearance := mini(
				mini(zone_rect.position.x - compound_rect.position.x, compound_rect.end.x - zone_rect.end.x),
				mini(zone_rect.position.y - compound_rect.position.y, compound_rect.end.y - zone_rect.end.y)
			)
			candidates.append({
				"anchor": center,
				"score": -center.distance_squared_to(fabricator_anchor) + edge_clearance * 64,
			})
	if candidates.is_empty():
		return Vector2i.ZERO
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var anchor_a: Vector2i = a.get("anchor", Vector2i.ZERO)
		var anchor_b: Vector2i = b.get("anchor", Vector2i.ZERO)
		return anchor_a.y < anchor_b.y if anchor_a.y != anchor_b.y else anchor_a.x < anchor_b.x
	)
	return candidates[0].get("anchor", Vector2i.ZERO)


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


func _generate_connected_bunker(compound_rect: Rect2i, ingress: Array[Vector2i], profile: Dictionary) -> Dictionary:
	var margin := int(_config.get("outer_clearance_tiles", 4))
	var inner := compound_rect.grow(-margin)
	var specs := _bunker_room_specs()
	if specs.is_empty():
		return _invalid("connected_bunker_catalog_invalid", compound_rect, ingress)
	var rows := {}
	for attempt in range(24):
		rows = _plan_bunker_rows(specs, inner.size.x, attempt)
		if bool(rows.get("fits", false)):
			break
	if not bool(rows.get("fits", false)):
		return _invalid("connected_bunker_bounds_too_small", compound_rect, ingress)
	var north_height: int = rows["north_height"]
	var south_height: int = rows["south_height"]
	var underground_height := north_height + BUNKER_SPINE_WIDTH + south_height
	var surface_height := inner.size.y - BUNKER_SEPARATOR_ROWS - underground_height
	if surface_height < BUNKER_MIN_SURFACE_ROWS:
		return _invalid("connected_bunker_bounds_too_small", compound_rect, ingress)

	var yard := Rect2i(inner.position, Vector2i(inner.size.x, surface_height))
	var surface_region := Rect2i(
		compound_rect.position,
		Vector2i(compound_rect.size.x, yard.end.y - compound_rect.position.y)
	)
	var separator_top := yard.end.y
	var underground_top := separator_top + BUNKER_SEPARATOR_ROWS
	var subsurface_region := Rect2i(
		Vector2i(compound_rect.position.x, underground_top),
		Vector2i(compound_rect.size.x, compound_rect.end.y - underground_top)
	)
	var spine_top := underground_top + north_height
	var spine_mid_y := spine_top + BUNKER_SPINE_WIDTH / 2

	var rooms: Array[Dictionary] = []
	var x_min := 1 << 30
	var x_max := -(1 << 30)
	for side in ["north", "south"]:
		var row: Array = rows[side]
		var slack: int = inner.size.x - int(rows["%s_width" % side])
		var cursor: int = inner.position.x + int(abs(hash("%d:%s" % [_seed, side])) % (slack + 1))
		for spec_variant in row:
			var spec := spec_variant as Dictionary
			var size: Vector2i = spec["size"]
			var position := Vector2i(cursor, spine_top - size.y if side == "north" else spine_top + BUNKER_SPINE_WIDTH)
			var rect := Rect2i(position, size)
			var room := (spec["config"] as Dictionary).duplicate(true)
			room["id"] = spec["id"]
			room["type"] = spec["type"]
			room["rect"] = rect
			room["center"] = Vector2i(rect.get_center())
			room["side"] = side
			var door := Vector2i(rect.get_center().x, rect.end.y - 1 if side == "north" else rect.position.y)
			room["door_cells"] = _door_width_cells(rect, door)
			room["threshold_cell"] = door
			room["connection_ids"] = []
			rooms.append(room)
			x_min = mini(x_min, rect.position.x)
			x_max = maxi(x_max, rect.end.x)
			cursor += size.x + BUNKER_ROOM_GAP
	rooms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))

	var spine_cells: Array[Vector2i] = []
	for y in range(spine_top, spine_top + BUNKER_SPINE_WIDTH):
		for x in range(x_min, x_max):
			spine_cells.append(Vector2i(x, y))

	var command := _room_by_type(rooms, COMMAND_TYPE)
	if command.is_empty():
		return _invalid("connected_bunker_catalog_invalid", compound_rect, ingress)
	var connections: Array[Dictionary] = []
	var thresholds: Array[Dictionary] = []
	for room in rooms:
		var door: Vector2i = room["threshold_cell"]
		var toward_spine := Vector2i.DOWN if String(room["side"]) == "north" else Vector2i.UP
		thresholds.append({
			"id": "threshold_%s" % room["id"],
			"room_id": room["id"],
			"cell": door,
			"spine_cell": door + toward_spine,
			"layer_id": LAYER_SUBSURFACE,
		})
		if room["id"] == command["id"]:
			continue
		var connection_id := "%s__%s" % [command["id"], room["id"]]
		connections.append({
			"id": connection_id,
			"from_room_id": command["id"],
			"to_room_id": room["id"],
			"from_door": command["threshold_cell"],
			"to_door": door,
			"path_cells": _bunker_tunnel_path(command["threshold_cell"], door, spine_mid_y),
			"index": connections.size(),
			"edge_type": "tunnel",
			"layer_id": LAYER_SUBSURFACE,
		})
		(command["connection_ids"] as Array).append(connection_id)
		(room["connection_ids"] as Array).append(connection_id)

	var housings: Array[Dictionary] = []
	var entries: Array[Dictionary] = []
	var housing_y := yard.end.y - BUNKER_YARD_APRON_ROWS - BUNKER_HOUSING_SIZE.y
	var entry_anchors: Array[Vector2i] = [
		Vector2i(x_min + 1, spine_mid_y),
		Vector2i(x_max - 2, spine_mid_y),
	]
	for index in range(BUNKER_HOUSING_COUNT):
		var fraction := (index * 2 + 1)
		var jitter: int = int(abs(hash("%d:housing:%d" % [_seed, index])) % 5) - 2
		var center_x: int = yard.position.x + yard.size.x * fraction / (BUNKER_HOUSING_COUNT * 2) + jitter
		var housing_rect := Rect2i(Vector2i(center_x - BUNKER_HOUSING_SIZE.x / 2, housing_y), BUNKER_HOUSING_SIZE)
		var housing_id := "surface_housing_%02d" % (index + 1)
		var entry_id := "vertical_entry_%02d" % (index + 1)
		var housing_door := Vector2i(housing_rect.get_center().x, housing_rect.position.y)
		var threshold := Vector2i(housing_rect.get_center())
		housings.append({
			"id": housing_id,
			"type": "surface_housing",
			"rect": housing_rect,
			"center": threshold,
			"door_cells": _door_width_cells(housing_rect, housing_door),
			"threshold_cell": threshold,
			"vertical_entry_id": entry_id,
			"layer_id": LAYER_SURFACE,
		})
		entries.append({
			"id": entry_id,
			"edge_type": "vertical_entry",
			"reversible": true,
			"housing_id": housing_id,
			"surface_layer_id": LAYER_SURFACE,
			"subsurface_layer_id": LAYER_SUBSURFACE,
			"surface_anchor": threshold,
			"subsurface_anchor": entry_anchors[index],
		})

	var housing_cells := _rect_cell_set(housings)
	var courtyard_cells: Array[Vector2i] = []
	for y in range(yard.position.y, yard.end.y):
		for x in range(yard.position.x, yard.end.x):
			var cell := Vector2i(x, y)
			if not housing_cells.has(cell):
				courtyard_cells.append(cell)
	var surface_ingress := _bunker_surface_ingress(ingress, compound_rect, surface_region)

	var corridor_cells: Array[Vector2i] = spine_cells.duplicate()
	for room in rooms:
		for door in room["door_cells"]:
			corridor_cells.append(door)
	corridor_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)

	var buildings: Array[Rect2i] = []
	for housing in housings:
		buildings.append(housing["rect"])
	var command_rect: Rect2i = command["rect"]
	var terminal_anchor := Vector2i(command_rect.get_center())
	var fabricator_anchor := _pick_fabricator_anchor(rooms)
	var construction_zone_anchor := _pick_construction_zone_anchor(compound_rect, yard, housings, fabricator_anchor)
	if fabricator_anchor == Vector2i.ZERO or construction_zone_anchor == Vector2i.ZERO:
		return _invalid("population_anchor_placement_failed", compound_rect, ingress)
	var first_door: Vector2i = (housings[0]["door_cells"] as Array)[1]
	var primary_anchor := first_door + Vector2i.UP * 2

	var zone_counts := {"core": 0, "operational": 0, "perimeter": 0}
	var occupied_area := 0
	for room in rooms:
		occupied_area += (room["rect"] as Rect2i).get_area()
		var zone := String(room.get("zone", "operational"))
		zone_counts[zone] = int(zone_counts.get(zone, 0)) + 1
	var selected_id := String(profile.get("archetype_id", ""))
	var profile_version := int(profile.get("profile_version", 0))
	var content_rect := Rect2i(Vector2i(inner.position.x, underground_top), Vector2i(inner.size.x, underground_height))
	var layout := {
		"valid": true,
		"schema_version": int(_config.get("schema_version", 1)),
		"rect": compound_rect,
		"ingress": surface_ingress,
		"rooms": rooms,
		"connections": connections,
		"corridor_cells": corridor_cells,
		"courtyard_cells": courtyard_cells,
		"buildings": buildings,
		"primary_anchor": primary_anchor,
		"terminal_anchor": terminal_anchor,
		"fabricator_anchor": fabricator_anchor,
		"construction_zone_anchor": construction_zone_anchor,
		"archetype_id": selected_id,
		"layer_id": LAYER_SURFACE,
		"archetype_profile_version": profile_version,
		"layers": {
			LAYER_SURFACE: {"layer_id": LAYER_SURFACE, "rect": surface_region, "yard_rect": yard},
			LAYER_SUBSURFACE: {
				"layer_id": LAYER_SUBSURFACE,
				"rect": subsurface_region,
				"content_rect": content_rect,
				"separator_rect": Rect2i(Vector2i(compound_rect.position.x, separator_top), Vector2i(compound_rect.size.x, BUNKER_SEPARATOR_ROWS)),
			},
		},
		"surface_housings": housings,
		"vertical_entries": entries,
		"compartment_thresholds": thresholds,
		"spine_cells": spine_cells,
		"diagnostics": {
			"target_room_count": rooms.size(),
			"actual_room_count": rooms.size(),
			"core_count": zone_counts["core"],
			"operational_count": zone_counts["operational"],
			"perimeter_count": zone_counts["perimeter"],
			"negative_space_ratio": 1.0 - float(occupied_area) / float(maxi(1, content_rect.get_area())),
			"connected": true,
			"fallbacks_used": 0,
			"spine_length": x_max - x_min,
			"housing_count": housings.size(),
			"vertical_entry_count": entries.size(),
		},
	}
	for room in layout["rooms"]:
		room["archetype_id"] = selected_id
		room["layer_id"] = LAYER_SUBSURFACE
		room["archetype_profile_version"] = profile_version
	for housing in layout["surface_housings"]:
		housing["archetype_id"] = selected_id
		housing["archetype_profile_version"] = profile_version
	for connection in layout["connections"]:
		connection["archetype_id"] = selected_id
		connection["archetype_profile_version"] = profile_version
	var failure := _bunker_connectivity_failure(layout)
	if not failure.is_empty():
		return _invalid(failure, compound_rect, ingress)
	return layout


func _bunker_room_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var types: Array[String] = []
	for room_type_variant in _graph.get_available_types():
		types.append(String(room_type_variant))
	types.sort()
	for room_type in types:
		if not _graph.is_required(room_type):
			continue
		var config := _graph.get_room_config(room_type)
		var size := _vector2i_from_json(config.get("footprint_min", [8, 6]))
		for index in range(_graph.get_min_count(room_type)):
			specs.append({
				"id": "%s_%02d" % [room_type, index + 1],
				"type": room_type,
				"config": config,
				"size": size,
			})
	return specs


func _plan_bunker_rows(specs: Array[Dictionary], row_limit: int, attempt: int) -> Dictionary:
	var ordered := specs.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ha: int = abs(hash("%s:%d:%d" % [a["id"], _seed, attempt]))
		var hb: int = abs(hash("%s:%d:%d" % [b["id"], _seed, attempt]))
		return ha < hb if ha != hb else String(a["id"]) < String(b["id"])
	)
	var north: Array = []
	var south: Array = []
	var north_width := 0
	var south_width := 0
	for spec in ordered:
		var width: int = (spec["size"] as Vector2i).x + BUNKER_ROOM_GAP
		if north_width <= south_width:
			north.append(spec)
			north_width += width
		else:
			south.append(spec)
			south_width += width
	north_width = maxi(0, north_width - BUNKER_ROOM_GAP)
	south_width = maxi(0, south_width - BUNKER_ROOM_GAP)
	var north_height := 0
	var south_height := 0
	for spec in north:
		north_height = maxi(north_height, (spec["size"] as Vector2i).y)
	for spec in south:
		south_height = maxi(south_height, (spec["size"] as Vector2i).y)
	return {
		"fits": not north.is_empty() and not south.is_empty() and north_width <= row_limit and south_width <= row_limit,
		"north": north,
		"south": south,
		"north_width": north_width,
		"south_width": south_width,
		"north_height": north_height,
		"south_height": south_height,
	}


func _bunker_tunnel_path(from_door: Vector2i, to_door: Vector2i, spine_mid_y: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for y in _inclusive_range(from_door.y, spine_mid_y):
		path.append(Vector2i(from_door.x, y))
	for x in _inclusive_range(from_door.x, to_door.x):
		var cell := Vector2i(x, spine_mid_y)
		if path.is_empty() or path[-1] != cell:
			path.append(cell)
	for y in _inclusive_range(spine_mid_y, to_door.y):
		var cell := Vector2i(to_door.x, y)
		if path[-1] != cell:
			path.append(cell)
	return path


func _inclusive_range(from_value: int, to_value: int) -> Array[int]:
	var values: Array[int] = []
	var step := 1 if to_value >= from_value else -1
	var value := from_value
	while true:
		values.append(value)
		if value == to_value:
			break
		value += step
	return values


func _bunker_surface_ingress(ingress: Array[Vector2i], compound_rect: Rect2i, surface_region: Rect2i) -> Array[Vector2i]:
	# Only the surface band may open to the outside; the subsurface region stays sealed.
	var result: Array[Vector2i] = []
	for cell in ingress:
		if surface_region.has_point(cell) and cell.y < surface_region.end.y - 1:
			result.append(cell)
	var fallback_x: Array[int] = [
		compound_rect.position.x + compound_rect.size.x / 4,
		compound_rect.position.x + compound_rect.size.x * 3 / 4,
	]
	for x in fallback_x:
		if result.size() >= 2:
			break
		var cell := Vector2i(x, compound_rect.position.y)
		if not result.has(cell):
			result.append(cell)
	return result


func _bunker_connectivity_failure(layout: Dictionary) -> String:
	var underground := {}
	for cell in layout["spine_cells"]:
		underground[cell] = true
	for room in layout["rooms"]:
		var rect: Rect2i = room["rect"]
		var doors := {}
		for door in room["door_cells"]:
			doors[door] = true
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				var perimeter := x == rect.position.x or x == rect.end.x - 1 or y == rect.position.y or y == rect.end.y - 1
				if not perimeter or doors.has(cell):
					underground[cell] = true
	var entries: Array = layout["vertical_entries"]
	if entries.size() < 2:
		return "connected_bunker_entries_missing"
	var reached := _flood_cells(entries[0]["subsurface_anchor"], underground)
	for entry in entries:
		if not reached.has(entry["subsurface_anchor"]):
			return "connected_bunker_underground_disconnected"
	for room in layout["rooms"]:
		if not reached.has((room["rect"] as Rect2i).get_center()) or not reached.has(room["threshold_cell"]):
			return "connected_bunker_underground_disconnected"
	if reached.size() != underground.size():
		return "connected_bunker_underground_disconnected"
	var surface := {}
	for cell in layout["courtyard_cells"]:
		surface[cell] = true
	for housing in layout["surface_housings"]:
		var rect: Rect2i = housing["rect"]
		var doors := {}
		for door in housing["door_cells"]:
			doors[door] = true
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				var perimeter := x == rect.position.x or x == rect.end.x - 1 or y == rect.position.y or y == rect.end.y - 1
				if not perimeter or doors.has(cell):
					surface[cell] = true
	var start: Vector2i = layout["primary_anchor"]
	if not surface.has(start):
		return "connected_bunker_surface_disconnected"
	var surface_reached := _flood_cells(start, surface)
	for entry in entries:
		if not surface_reached.has(entry["surface_anchor"]):
			return "connected_bunker_surface_disconnected"
	return ""


func _flood_cells(start: Vector2i, cells: Dictionary) -> Dictionary:
	var seen := {}
	if not cells.has(start):
		return seen
	var frontier: Array[Vector2i] = [start]
	seen[start] = true
	var head := 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		for direction in CARDINALS:
			var next_cell: Vector2i = current + direction
			if cells.has(next_cell) and not seen.has(next_cell):
				seen[next_cell] = true
				frontier.append(next_cell)
	return seen


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
