class_name LayoutAssembler
extends RefCounted

## Assembles room templates into a connected level layout.

const TILE_SIZE := 32
const ROOM_SPACING := 2

var _rng: RandomNumberGenerator
var _room_loader: RoomLoader
var _room_graph: RoomGraph
var _placed_rooms: Array = []

func _init(room_loader: RoomLoader, room_graph: RoomGraph, rng: RandomNumberGenerator = null) -> void:
	_room_loader = room_loader
	_room_graph = room_graph
	_rng = rng if rng else RandomNumberGenerator.new()

func generate_layout(seed: int) -> Dictionary:
	_rng.seed = int(seed)

	if _room_graph != null:
		_room_graph.set_seed(seed)

	if _room_loader != null:
		_room_loader.set_seed(seed)

	_placed_rooms.clear()

	if _room_loader == null:
		push_error("[LayoutAssembler] Missing RoomLoader")
		return {
			"rooms": [],
			"connections": [],
			"bounds": {"min": Vector2i.ZERO, "max": Vector2i.ZERO},
			"room_count": 0,
			"errors": ["missing_room_loader"],
		}

	if _room_graph == null:
		push_error("[LayoutAssembler] Missing RoomGraph")
		return {
			"rooms": [],
			"connections": [],
			"bounds": {"min": Vector2i.ZERO, "max": Vector2i.ZERO},
			"room_count": 0,
			"errors": ["missing_room_graph"],
		}
	
	var layout := {
		"rooms": [],
		"connections": [],
		"bounds": {"min": Vector2i.ZERO, "max": Vector2i.ZERO},
	}
	
	var room_assignments := _generate_room_assignments()
	var layout_cell_step := _calculate_layout_cell_step(room_assignments)

	var room_instances := _generate_graph_walk_room_instances(room_assignments, layout_cell_step)

	if room_instances.is_empty() and not room_assignments.is_empty():
		room_instances = _generate_grid_room_instances(room_assignments, layout_cell_step)
	
	layout["rooms"] = room_instances
	layout["connections"] = _generate_connections(room_instances)
	layout["bounds"] = _calculate_bounds(room_instances)
	layout["room_count"] = room_instances.size()

	if layout["connections"].is_empty() and room_instances.size() > 1:
		push_warning("[LayoutAssembler] Generated layout has multiple rooms but no valid connections")

	_placed_rooms = room_instances.duplicate(true)
	
	return layout

func _generate_graph_walk_room_instances(room_assignments: Array, layout_cell_step: Vector2i) -> Array:
	var room_instances: Array = []

	if room_assignments.is_empty():
		return room_instances

	var occupied_grid: Dictionary = {}
	var placed_assignment_indices: Dictionary = {}
	var start_index := _find_start_assignment_index(room_assignments)

	if start_index < 0:
		return room_instances

	var start_assignment: Dictionary = room_assignments[start_index]
	var start_room := _make_room_instance(start_assignment, Vector2i.ZERO, Vector2.ZERO, 0)

	if start_room.is_empty():
		return room_instances

	room_instances.append(start_room)
	occupied_grid[Vector2i.ZERO] = true
	placed_assignment_indices[start_index] = true

	var made_progress := true

	while made_progress and placed_assignment_indices.size() < room_assignments.size():
		made_progress = false
		var placed_snapshot := room_instances.duplicate(true)

		for parent_variant in placed_snapshot:
			if not (parent_variant is Dictionary):
				continue

			var parent_room := parent_variant as Dictionary

			for assignment_index in range(room_assignments.size()):
				if placed_assignment_indices.has(assignment_index):
					continue

				var assignment: Dictionary = room_assignments[assignment_index]
				var placed_room := _try_place_assignment_near_room(
					assignment,
					parent_room,
					room_instances,
					occupied_grid
				)

				if placed_room.is_empty():
					continue

				room_instances.append(placed_room)
				occupied_grid[placed_room["grid_position"]] = true
				placed_assignment_indices[assignment_index] = true
				made_progress = true
				break

			if made_progress:
				break

	_append_unplaced_assignments_to_grid(
		room_assignments,
		layout_cell_step,
		room_instances,
		occupied_grid,
		placed_assignment_indices
	)

	return room_instances


func _generate_grid_room_instances(room_assignments: Array, layout_cell_step: Vector2i) -> Array:
	var room_instances: Array = []
	var occupied_grid: Dictionary = {}
	var placed_assignment_indices: Dictionary = {}

	_append_unplaced_assignments_to_grid(
		room_assignments,
		layout_cell_step,
		room_instances,
		occupied_grid,
		placed_assignment_indices
	)

	return room_instances


func _append_unplaced_assignments_to_grid(
	room_assignments: Array,
	layout_cell_step: Vector2i,
	room_instances: Array,
	occupied_grid: Dictionary,
	placed_assignment_indices: Dictionary
) -> void:
	var fallback_grid_pos := Vector2i.ZERO

	for assignment_index in range(room_assignments.size()):
		if placed_assignment_indices.has(assignment_index):
			continue

		var assignment: Dictionary = room_assignments[assignment_index]
		fallback_grid_pos = _next_free_grid_position(fallback_grid_pos, occupied_grid)
		var world_position := _grid_to_world(fallback_grid_pos, layout_cell_step)
		var room_instance := _make_room_instance(assignment, fallback_grid_pos, world_position, room_instances.size())

		if room_instance.is_empty():
			continue

		room_instance["placement_mode"] = "fallback_grid"
		room_instances.append(room_instance)
		occupied_grid[fallback_grid_pos] = true
		placed_assignment_indices[assignment_index] = true


func _find_start_assignment_index(room_assignments: Array) -> int:
	for assignment_index in range(room_assignments.size()):
		var assignment: Dictionary = room_assignments[assignment_index]
		var room_type := String(assignment.get("type", "")).to_lower()

		if room_type.contains("start") or room_type.contains("spawn") or room_type.contains("entry"):
			return assignment_index

	for assignment_index in range(room_assignments.size()):
		var assignment: Dictionary = room_assignments[assignment_index]
		var room_type := String(assignment.get("type", ""))

		if _room_graph.is_required(room_type):
			return assignment_index

	return 0 if not room_assignments.is_empty() else -1


func _try_place_assignment_near_room(
	assignment: Dictionary,
	parent_room: Dictionary,
	room_instances: Array,
	occupied_grid: Dictionary
) -> Dictionary:
	var room_type := String(assignment.get("type", ""))
	var template_name := String(assignment.get("template", ""))
	var template := _room_loader.get_template(template_name)

	if template.is_empty():
		return {}

	for direction in _direction_names():
		var target_grid := Vector2i(parent_room["grid_position"]) + _direction_vector(direction)

		if occupied_grid.has(target_grid):
			continue

		if not _room_graph.allows_connection(String(parent_room.get("type", "")), room_type, direction):
			continue

		var opposite_direction := _opposite_direction(direction)
		var parent_doors: Array = parent_room["doors"].get(direction, [])
		var candidate_doors: Array = _collect_doors(template).get(opposite_direction, [])

		if parent_doors.is_empty() or candidate_doors.is_empty():
			continue

		var door_pair := _find_compatible_door_pair(parent_doors, candidate_doors)

		if door_pair.is_empty():
			continue

		var world_position := _resolve_aligned_room_world_position(
			parent_room,
			door_pair["from_door"],
			door_pair["to_door"],
			direction
		)

		if _room_overlaps_existing(world_position, template, room_instances):
			continue

		var room_instance := _make_room_instance(assignment, target_grid, world_position, room_instances.size())

		if room_instance.is_empty():
			continue

		room_instance["placement_mode"] = "graph_door_aligned"
		room_instance["placed_from_room"] = parent_room.get("id", parent_room.get("template", ""))
		room_instance["placed_from_direction"] = direction
		return room_instance

	return {}


func _make_room_instance(assignment: Dictionary, grid_position: Vector2i, world_position: Vector2, room_index: int) -> Dictionary:
	var template_name := String(assignment.get("template", ""))
	var template := _room_loader.get_template(template_name)

	if template.is_empty():
		push_warning("[LayoutAssembler] Template not found: " + template_name)
		return {}

	var room_type := String(assignment.get("type", ""))
	var room_id := "%s_%02d" % [room_type, room_index]

	return {
		"id": room_id,
		"type": room_type,
		"template": template_name,
		"grid_position": grid_position,
		"world_position": world_position,
		"width": template.get("width", 0),
		"height": template.get("height", 0),
		"doors": _collect_doors(template),
		"properties": template.get("properties", {}).duplicate(true),
		"markers": _offset_markers(template.get("markers", []), world_position),
		"stairs": _offset_markers(template.get("stairs", []), world_position),
		"player_spawn": _offset_tile(template.get("player_spawn", null), world_position),
		"terminal_marker": _offset_tile(template.get("terminal_marker", null), world_position),
		"enemy_spawns": _offset_tiles(template.get("enemy_spawns", []), world_position),
		"turret_mounts": _offset_tiles(template.get("turret_mounts", []), world_position),
		"floor_index": int(template.get("floor_index", 0)),
		"template_family": str(template.get("template_family", "")),
		"intensity": _estimate_room_intensity(room_type, grid_position),
		"placement_mode": "graph_root" if room_index == 0 else "grid",
	}


func _resolve_aligned_room_world_position(
	parent_room: Dictionary,
	parent_door: Dictionary,
	candidate_door: Dictionary,
	direction: String
) -> Vector2:
	var parent_door_tile := _resolve_connection_door_tile(parent_room, parent_door)
	var candidate_door_tile := _door_local_tile(candidate_door)
	var candidate_origin := parent_door_tile + _direction_vector(direction) - candidate_door_tile
	return Vector2(
		float(candidate_origin.x * TILE_SIZE),
		float(candidate_origin.y * TILE_SIZE)
	)


func _room_overlaps_existing(world_position: Vector2, template: Dictionary, room_instances: Array) -> bool:
	var origin := _world_to_tile_origin(world_position)
	var size := Vector2i(int(template.get("width", 0)), int(template.get("height", 0)))
	var rect := Rect2i(origin, size)

	for room_variant in room_instances:
		if not (room_variant is Dictionary):
			continue

		var room := room_variant as Dictionary
		var room_origin := _world_to_tile_origin(room.get("world_position", Vector2.ZERO))
		var room_size := Vector2i(int(room.get("width", 0)), int(room.get("height", 0)))

		if rect.intersects(Rect2i(room_origin, room_size)):
			return true

	return false


func _next_free_grid_position(start_position: Vector2i, occupied_grid: Dictionary) -> Vector2i:
	var grid_pos := start_position

	while occupied_grid.has(grid_pos):
		grid_pos.x += 1

		if grid_pos.x >= 3:
			grid_pos.x = 0
			grid_pos.y += 1

	return grid_pos


func _estimate_room_intensity(room_type: String, grid_pos: Vector2i) -> float:
	var distance_score := clampf(Vector2(grid_pos).length() / 4.0, 0.0, 1.0)
	var type_bonus := 0.0
	var lowered := room_type.to_lower()

	if lowered.contains("combat") or lowered.contains("encounter"):
		type_bonus += 0.20

	if lowered.contains("objective") or lowered.contains("boss") or lowered.contains("exit"):
		type_bonus += 0.35

	if lowered.contains("start") or lowered.contains("spawn") or lowered.contains("entry"):
		type_bonus -= 0.30

	return clampf(distance_score + type_bonus, 0.0, 1.0)

func _generate_room_assignments() -> Array:
	var assignments := []
	
	var available_types := _room_graph.get_available_types()
	
	for room_type in available_types:
		if _room_graph.is_required(room_type):
			var count := _room_graph.get_min_count(room_type)
			for i in range(count):
				var template_name := _room_graph.get_random_template(room_type)
				assignments.append({
					"type": room_type,
					"template": template_name,
				})
	
	for room_type in available_types:
		if not _room_graph.is_required(room_type):
			var count := _room_graph.get_random_count(room_type)
			for i in range(count):
				var template_name := _room_graph.get_random_template(room_type)
				assignments.append({
					"type": room_type,
					"template": template_name,
				})
	
	for i in range(assignments.size() - 1, 0, -1):
		var swap_with: int = _rng.randi_range(0, i)
		var temp = assignments[i]
		assignments[i] = assignments[swap_with]
		assignments[swap_with] = temp

	assignments.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _room_assignment_priority(a) < _room_assignment_priority(b)
	)
	
	return assignments

func _room_assignment_priority(assignment: Dictionary) -> int:
	var room_type := String(assignment.get("type", "")).to_lower()

	if room_type.contains("start") or room_type.contains("spawn") or room_type.contains("entry"):
		return 0

	if room_type.contains("hub") or room_type.contains("safe"):
		return 1

	if room_type.contains("combat") or room_type.contains("encounter"):
		return 5

	if room_type.contains("objective") or room_type.contains("boss") or room_type.contains("exit"):
		return 9

	return 4

func _collect_doors(template: Dictionary) -> Dictionary:
	return {
		"north": template.get("doors_north", []),
		"south": template.get("doors_south", []),
		"east": template.get("doors_east", []),
		"west": template.get("doors_west", []),
	}

func _direction_names() -> Array[String]:
	return ["east", "south", "west", "north"]

func _direction_vector(direction: String) -> Vector2i:
	match direction:
		"north":
			return Vector2i(0, -1)
		"south":
			return Vector2i(0, 1)
		"east":
			return Vector2i(1, 0)
		"west":
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO

func _opposite_direction(direction: String) -> String:
	match direction:
		"north":
			return "south"
		"south":
			return "north"
		"east":
			return "west"
		"west":
			return "east"
		_:
			return "any"

func _offset_tile(tile: Variant, world_position: Vector2) -> Variant:
	if tile is Vector2i:
		var template_tile: Vector2i = tile
		return template_tile + _world_to_tile_origin(world_position)
	return null

func _offset_tiles(tiles: Array, world_position: Vector2) -> Array:
	var offset_tiles: Array = []
	var origin := _world_to_tile_origin(world_position)
	for tile in tiles:
		if tile is Vector2i:
			offset_tiles.append((tile as Vector2i) + origin)
	return offset_tiles

func _offset_markers(markers: Array, world_position: Vector2) -> Array:
	var offset_markers: Array = []
	var origin := _world_to_tile_origin(world_position)
	for marker in markers:
		if marker is Dictionary:
			var offset_marker: Dictionary = marker.duplicate(true)
			var tile_position: Variant = offset_marker.get("tile_position")
			if tile_position is Vector2i:
				var template_tile: Vector2i = tile_position
				offset_marker["tile_position"] = template_tile + origin
			var pixel_position: Variant = offset_marker.get("pixel_position")
			if pixel_position is Vector2:
				offset_marker["pixel_position"] = (pixel_position as Vector2) + world_position
			offset_markers.append(offset_marker)
	return offset_markers

func _world_to_tile_origin(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(round(world_position.x / TILE_SIZE)),
		int(round(world_position.y / TILE_SIZE))
	)

func _grid_to_world(grid_pos: Vector2i, layout_cell_step: Vector2i) -> Vector2:
	return Vector2(
		float(grid_pos.x * layout_cell_step.x),
		float(grid_pos.y * layout_cell_step.y)
	)

func _calculate_layout_cell_step(room_assignments: Array) -> Vector2i:
	var max_width_tiles := 1
	var max_height_tiles := 1

	for assignment_variant in room_assignments:
		if not (assignment_variant is Dictionary):
			continue

		var assignment := assignment_variant as Dictionary
		var template_name := String(assignment.get("template", ""))
		if template_name.is_empty():
			continue

		var template := _room_loader.get_template(template_name)
		if template.is_empty():
			continue

		max_width_tiles = maxi(max_width_tiles, int(template.get("width", 1)))
		max_height_tiles = maxi(max_height_tiles, int(template.get("height", 1)))

	return Vector2i(
		(max_width_tiles + ROOM_SPACING) * TILE_SIZE,
		(max_height_tiles + ROOM_SPACING) * TILE_SIZE
	)

func _generate_connections(room_instances: Array) -> Array:
	var connections := []
	
	for i in range(room_instances.size()):
		for j in range(i + 1, room_instances.size()):
			var room_a: Dictionary = room_instances[i]
			var room_b: Dictionary = room_instances[j]
			
			var conn := _find_connection(room_a, room_b)
			if conn.size() > 0:
				connections.append(conn)
	
	return connections

func _find_connection(room_a: Dictionary, room_b: Dictionary) -> Dictionary:
	var pos_a: Vector2i = room_a["grid_position"]
	var pos_b: Vector2i = room_b["grid_position"]
	
	var diff := pos_b - pos_a
	
	if diff.x == 1 and diff.y == 0:
		return _make_connection(room_a, room_b, "east", "west")
	elif diff.x == -1 and diff.y == 0:
		return _make_connection(room_a, room_b, "west", "east")
	elif diff.x == 0 and diff.y == 1:
		return _make_connection(room_a, room_b, "south", "north")
	elif diff.x == 0 and diff.y == -1:
		return _make_connection(room_a, room_b, "north", "south")
	
	return {}

func _make_connection(room_a: Dictionary, room_b: Dictionary, dir_a: String, dir_b: String) -> Dictionary:
	if _room_graph != null:
		if not _room_graph.allows_connection(String(room_a.get("type", "")), String(room_b.get("type", "")), dir_a):
			return {}

	var doors_a: Array = room_a["doors"].get(dir_a, [])
	var doors_b: Array = room_b["doors"].get(dir_b, [])
	
	if doors_a.is_empty() or doors_b.is_empty():
		return {}
	
	var door_pair := _find_compatible_door_pair(doors_a, doors_b)
	if door_pair.is_empty():
		return {}
	
	var door_a: Dictionary = door_pair["from_door"]
	var door_b: Dictionary = door_pair["to_door"]
	var from_tile := _resolve_connection_door_tile(room_a, door_a)
	var to_tile := _resolve_connection_door_tile(room_b, door_b)

	return {
		"from_room": room_a.get("id", room_a["template"]),
		"to_room": room_b.get("id", room_b["template"]),
		"from_template": room_a["template"],
		"to_template": room_b["template"],
		"from_direction": dir_a,
		"to_direction": dir_b,
		"from_door": door_a,
		"to_door": door_b,
		"from_tile": from_tile,
		"to_tile": to_tile,
	}

func _find_compatible_door_pair(doors_a: Array, doors_b: Array) -> Dictionary:
	var compatible_pairs: Array[Dictionary] = []

	for door_a_variant in doors_a:
		if not (door_a_variant is Dictionary):
			continue

		var door_a := door_a_variant as Dictionary

		for door_b_variant in doors_b:
			if not (door_b_variant is Dictionary):
				continue

			var door_b := door_b_variant as Dictionary

			if _room_loader.can_connect(door_a, door_b):
				compatible_pairs.append({
					"from_door": door_a,
					"to_door": door_b,
				})

	if compatible_pairs.is_empty():
		return {}

	var index := _rng.randi_range(0, compatible_pairs.size() - 1)
	return compatible_pairs[index]

func _resolve_connection_door_tile(room: Dictionary, door: Dictionary) -> Vector2i:
	var room_origin := _world_to_tile_origin(room.get("world_position", Vector2.ZERO))
	var tile_value: Variant = door.get("tile_position", null)

	if tile_value is Vector2i:
		return room_origin + (tile_value as Vector2i)

	return room_origin + _door_local_tile(door)


func _door_local_tile(door: Dictionary) -> Vector2i:
	var tile_value: Variant = door.get("tile_position", null)

	if tile_value is Vector2i:
		return tile_value as Vector2i

	var x := int(door.get("x", 0))
	var y := int(door.get("y", 0))
	return Vector2i(x, y)

func _calculate_bounds(room_instances: Array) -> Dictionary:
	if room_instances.is_empty():
		return {"min": Vector2i.ZERO, "max": Vector2i.ZERO, "size": Vector2i.ZERO}
	
	var min_pos := Vector2i(999999, 999999)
	var max_pos := Vector2i(-999999, -999999)
	
	for room_variant in room_instances:
		if not (room_variant is Dictionary):
			continue

		var room := room_variant as Dictionary
		var world: Vector2 = room.get("world_position", Vector2.ZERO)
		var origin := _world_to_tile_origin(world)
		var size := Vector2i(
			int(room.get("width", 0)),
			int(room.get("height", 0))
		)
		
		min_pos.x = mini(min_pos.x, origin.x)
		min_pos.y = mini(min_pos.y, origin.y)
		max_pos.x = maxi(max_pos.x, origin.x + size.x)
		max_pos.y = maxi(max_pos.y, origin.y + size.y)
	
	return {
		"min": min_pos,
		"max": max_pos,
		"size": max_pos - min_pos,
	}

func get_placed_rooms() -> Array:
	return _placed_rooms
