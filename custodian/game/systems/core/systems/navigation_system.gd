extends Node
class_name NavigationSystem

## AStar2D-based navigation connected to floor tilemap.
## Provides pathfinding for enemies through the compound.

signal navigation_ready()
signal navigation_dirty()

@export var floor_tilemap_path: NodePath
@export var walls_tilemap_path: NodePath
@export var tile_size: Vector2i = Vector2i(32, 32)

var astar: AStar2D
var floor_tilemap: TileMapLayer
var walls_tilemap: TileMapLayer
var _walkable_tiles: Dictionary = {}  # Vector2i -> bool
var _initialized: bool = false

var _init_deferred: bool = false

func _ready() -> void:
	add_to_group("navigation")
	# Defer initialization to allow procgen to finish
	call_deferred("_initialize_navigation_deferred")


func _exit_tree() -> void:
	astar = null
	floor_tilemap = null
	walls_tilemap = null
	_walkable_tiles.clear()
	_initialized = false
	_init_deferred = false


func _initialize_navigation_deferred() -> void:
	if _init_deferred:
		return
	_init_deferred = true
	
	# Wait a bit for procgen to complete
	await get_tree().create_timer(0.5).timeout
	_initialize_navigation()


func _initialize_navigation() -> void:
	if floor_tilemap_path != NodePath():
		floor_tilemap = get_node_or_null(floor_tilemap_path)
	
	if walls_tilemap_path != NodePath():
		walls_tilemap = get_node_or_null(walls_tilemap_path)
	
	# Try to find tilemaps automatically if not assigned
	if floor_tilemap == null:
		floor_tilemap = _find_floor_tilemap()
	
	if floor_tilemap == null:
		push_warning("[NavigationSystem] No floor tilemap found")
		return
	
	astar = AStar2D.new()
	_walkable_tiles.clear()
	_build_navigation_graph()
	_initialized = true
	navigation_ready.emit()
	print("[NavigationSystem] Initialized with ", _walkable_tiles.size(), " walkable tiles")


func set_runtime_tilemaps(p_floor_tilemap: TileMapLayer, p_walls_tilemap: TileMapLayer) -> void:
	floor_tilemap = p_floor_tilemap
	walls_tilemap = p_walls_tilemap


func _find_floor_tilemap() -> TileMapLayer:
	# Try to find from world loader / contract map
	var world_loader = get_tree().get_first_node_in_group("contract_world_loader")
	if world_loader and world_loader.has_method("get_active_map_instance"):
		var map_instance = world_loader.get_active_map_instance()
		if map_instance and "floor_tilemap" in map_instance:
			return map_instance.get("floor_tilemap")
	
	# Try direct child of world
	var world = get_tree().get_first_node_in_group("world")
	if world == null:
		world = get_node_or_null("/root/GameRoot/World")
	
	if world:
		# Look for ProcGenMap in world children
		for child in world.get_children():
			if child.has_method("get_floor_tilemap"):
				return child.get_floor_tilemap()
			if child.name.contains("ProcGen"):
				var ft = child.get_node_or_null("Floor")
				if ft is TileMapLayer:
					return ft
				# Check nested ProcGenTilemap
				for nested in child.get_children():
					if "floor_tilemap" in nested:
						return nested.get("floor_tilemap")
	
	# Look for tilemap in world directly
	if world:
		var tilemap = world.get_node_or_null("Floor")
		if tilemap is TileMapLayer:
			return tilemap
	
	return null


func _build_navigation_graph() -> void:
	if floor_tilemap == null:
		return
	
	var used_cells = floor_tilemap.get_used_cells()
	
	for cell in used_cells:
		if _is_walkable(cell):
			_walkable_tiles[cell] = true
			var world_pos = floor_tilemap.to_global(floor_tilemap.map_to_local(cell))
			astar.add_point(_cell_to_id(cell), world_pos, 1.0)
	
	# Connect adjacent points
	for cell in _walkable_tiles.keys():
		_connect_adjacent_cells(cell)


func _cell_to_id(cell: Vector2i) -> int:
	return (int(cell.x) << 32) | (int(cell.y) & 0xffffffff)


func _id_to_cell(id: int) -> Vector2i:
	return Vector2i(
		int(id >> 32),
		int(id & 0xffffffff)
	)


func _is_walkable(cell: Vector2i) -> bool:
	if floor_tilemap == null:
		return false
	
	var source_id = floor_tilemap.get_cell_source_id(cell)
	if source_id < 0:
		return false
	
	# Check walls tilemap
	if walls_tilemap != null:
		var wall_source = walls_tilemap.get_cell_source_id(cell)
		if wall_source >= 0:
			return false
	
	return true


func _connect_adjacent_cells(cell: Vector2i) -> void:
	var neighbors = [
		cell + Vector2i(0, -1),  # North
		cell + Vector2i(1, 0),   # East
		cell + Vector2i(0, 1),   # South
		cell + Vector2i(-1, 0),  # West
	]
	
	for neighbor in neighbors:
		if _walkable_tiles.has(neighbor):
			astar.connect_points(
				_cell_to_id(cell),
				_cell_to_id(neighbor),
				true
			)


func get_path_to_target(start: Vector2, target: Vector2) -> PackedVector2Array:
	if not _initialized or astar == null:
		return PackedVector2Array([start, target])
	
	var start_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(start)) if floor_tilemap else Vector2i()
	var target_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(target)) if floor_tilemap else Vector2i()
	
	# Clamp to walkable tiles
	start_cell = _get_nearest_walkable(start_cell)
	target_cell = _get_nearest_walkable(target_cell)
	
	if not _walkable_tiles.has(start_cell) or not _walkable_tiles.has(target_cell):
		return PackedVector2Array([start, target])
	
	var start_id = _cell_to_id(start_cell)
	var target_id = _cell_to_id(target_cell)
	
	if not astar.has_point(start_id) or not astar.has_point(target_id):
		return PackedVector2Array([start, target])
	
	var path_points = astar.get_point_path(start_id, target_id)
	
	if path_points.is_empty():
		return PackedVector2Array([start, target])
	
	return path_points


func _get_nearest_walkable(cell: Vector2i) -> Vector2i:
	if _walkable_tiles.has(cell):
		return cell
	
	# Search in expanding circles
	for radius in range(1, 10):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var check = cell + Vector2i(dx, dy)
				if _walkable_tiles.has(check):
					return check
	
	return cell


func is_in_walkable_area(position: Vector2) -> bool:
	if floor_tilemap == null:
		return true
	
	var cell = floor_tilemap.local_to_map(floor_tilemap.to_local(position))
	return _walkable_tiles.has(cell)


func get_random_walkable_position() -> Vector2:
	if _walkable_tiles.is_empty():
		return Vector2.ZERO
	
	var cells = _walkable_tiles.keys()
	cells.shuffle()
	
	for cell in cells:
		var world_pos = floor_tilemap.to_global(floor_tilemap.map_to_local(cell))
		if _is_position_clear(world_pos):
			return world_pos
	
	return Vector2.ZERO


func _is_position_clear(pos: Vector2) -> bool:
	var viewport := get_viewport()
	if viewport == null or viewport.world_2d == null:
		return true
	var space = viewport.world_2d.direct_space_state
	if space == null:
		return true
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1  # Default collision
	
	var results = space.intersect_point(query, 1)
	return results.is_empty()


func get_path_length(path: PackedVector2Array) -> float:
	var length = 0.0
	for i in range(1, path.size()):
		length += path[i].distance_to(path[i-1])
	return length


func rebuild() -> void:
	if astar != null:
		astar.clear()
	_walkable_tiles.clear()
	_initialized = false
	_initialize_navigation()
	navigation_dirty.emit()
