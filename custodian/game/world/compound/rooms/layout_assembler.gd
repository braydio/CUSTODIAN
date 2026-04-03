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
	_placed_rooms.clear()
	
	var layout := {
		"rooms": [],
		"connections": [],
		"bounds": {"min": Vector2i.ZERO, "max": Vector2i.ZERO},
	}
	
	var room_assignments := _generate_room_assignments()
	
	var current_grid_pos := Vector2i.ZERO
	var room_instances := []
	
	for i in range(room_assignments.size()):
		var assignment: Dictionary = room_assignments[i]
		var template_name: String = assignment["template"]
		var template: Dictionary = _room_loader.get_template(template_name)
		
		if template.is_empty():
			push_warning("[LayoutAssembler] Template not found: " + template_name)
			continue
		
		var room_world_position := _grid_to_world(current_grid_pos, template)
		var room_instance: Dictionary = {
			"type": assignment["type"],
			"template": template_name,
			"grid_position": current_grid_pos,
			"world_position": room_world_position,
			"width": template.get("width", 0),
			"height": template.get("height", 0),
			"doors": _collect_doors(template),
			"properties": template.get("properties", {}).duplicate(true),
			"markers": _offset_markers(template.get("markers", []), room_world_position),
			"stairs": _offset_markers(template.get("stairs", []), room_world_position),
			"player_spawn": _offset_tile(template.get("player_spawn", null), room_world_position),
			"terminal_marker": _offset_tile(template.get("terminal_marker", null), room_world_position),
			"enemy_spawns": _offset_tiles(template.get("enemy_spawns", []), room_world_position),
			"turret_mounts": _offset_tiles(template.get("turret_mounts", []), room_world_position),
			"floor_index": int(template.get("floor_index", 0)),
			"template_family": str(template.get("template_family", "")),
		}
		
		room_instances.append(room_instance)
		current_grid_pos.x += 1
		if current_grid_pos.x >= 3:
			current_grid_pos.x = 0
			current_grid_pos.y += 1
	
	layout["rooms"] = room_instances
	layout["connections"] = _generate_connections(room_instances)
	layout["bounds"] = _calculate_bounds(room_instances)
	layout["room_count"] = room_instances.size()
	
	return layout

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
	
	return assignments

func _collect_doors(template: Dictionary) -> Dictionary:
	return {
		"north": template.get("doors_north", []),
		"south": template.get("doors_south", []),
		"east": template.get("doors_east", []),
		"west": template.get("doors_west", []),
	}

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

func _grid_to_world(grid_pos: Vector2i, template: Dictionary) -> Vector2:
	var room_width: int = int(template.get("width", 10)) * TILE_SIZE
	var room_height: int = int(template.get("height", 10)) * TILE_SIZE
	var spacing := ROOM_SPACING * TILE_SIZE
	
	return Vector2(
		grid_pos.x * (room_width + spacing),
		grid_pos.y * (room_height + spacing)
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
	var doors_a: Array = room_a["doors"].get(dir_a, [])
	var doors_b: Array = room_b["doors"].get(dir_b, [])
	
	if doors_a.is_empty() or doors_b.is_empty():
		return {}
	
	var door_a = doors_a[0] if doors_a.size() > 0 else {}
	var door_b = doors_b[0] if doors_b.size() > 0 else {}
	
	if not _room_loader.can_connect(door_a, door_b):
		return {}
	
	return {
		"from_room": room_a["template"],
		"to_room": room_b["template"],
		"from_direction": dir_a,
		"to_direction": dir_b,
		"from_door": door_a,
		"to_door": door_b,
	}

func _calculate_bounds(room_instances: Array) -> Dictionary:
	if room_instances.is_empty():
		return {"min": Vector2i.ZERO, "max": Vector2i.ZERO}
	
	var min_pos := Vector2i(99999, 99999)
	var max_pos := Vector2i(-99999, -99999)
	
	for room in room_instances:
		var world: Vector2 = room["world_position"]
		var grid: Vector2i = room["grid_position"]
		var size := Vector2i(room["width"], room["height"])
		
		min_pos.x = min(min_pos.x, grid.x)
		min_pos.y = min(min_pos.y, grid.y)
		max_pos.x = max(max_pos.x, grid.x + 1)
		max_pos.y = max(max_pos.y, grid.y + 1)
	
	return {"min": min_pos, "max": max_pos}

func get_placed_rooms() -> Array:
	return _placed_rooms
