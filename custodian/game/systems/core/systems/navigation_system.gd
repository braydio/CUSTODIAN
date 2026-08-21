extends Node
class_name NavigationSystem

const ENEMY_NAVIGATION_BROKER_SCRIPT := preload(
	"res://game/systems/core/systems/enemy_navigation_broker.gd"
)
const ENEMY_SPATIAL_INDEX_SCRIPT := preload(
	"res://game/systems/simulation/enemy_spatial_index.gd"
)

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
var runtime_blocker_provider: Node
var runtime_navigation_provider: Node
var _walkable_tiles: Dictionary = {}  # Vector2i -> bool
var _initialized: bool = false
var navigation_revision := 0
var enemy_navigation_broker: EnemyNavigationBroker
var enemy_spatial_index: EnemySpatialIndex

var _init_deferred: bool = false

func _ready() -> void:
	add_to_group("navigation")
	enemy_navigation_broker = ENEMY_NAVIGATION_BROKER_SCRIPT.new()
	enemy_navigation_broker.name = "EnemyNavigationBroker"
	add_child(enemy_navigation_broker)
	enemy_navigation_broker.configure(self)
	enemy_spatial_index = ENEMY_SPATIAL_INDEX_SCRIPT.new()
	enemy_spatial_index.name = "EnemySpatialIndex"
	add_child(enemy_spatial_index)
	# Defer initialization to allow procgen to finish
	call_deferred("_initialize_navigation_deferred")


func _exit_tree() -> void:
	astar = null
	floor_tilemap = null
	walls_tilemap = null
	runtime_blocker_provider = null
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
	var world_loader = get_tree().get_first_node_in_group("contract_world_loader")
	if world_loader != null:
		if world_loader.has_method("is_contract_activation_aborted") and bool(world_loader.call("is_contract_activation_aborted")):
			print("[NavigationSystem] Contract generation failed; navigation initialization skipped")
			return
		if world_loader.has_method("is_contract_world_pending") and bool(world_loader.call("is_contract_world_pending")):
			return

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
	if runtime_blocker_provider == null:
		for provider in get_tree().get_nodes_in_group("procgen_walkability_provider"):
			if provider != null and provider.get("floor_tilemap") == floor_tilemap:
				runtime_blocker_provider = provider
				break
	
	astar = AStar2D.new()
	_walkable_tiles.clear()
	_build_navigation_graph()
	_initialized = true
	navigation_revision += 1
	navigation_ready.emit()
	print("[NavigationSystem] Initialized with ", _walkable_tiles.size(), " walkable tiles")


func set_runtime_tilemaps(p_floor_tilemap: TileMapLayer, p_walls_tilemap: TileMapLayer, p_runtime_blocker_provider: Node = null) -> void:
	floor_tilemap = p_floor_tilemap
	walls_tilemap = p_walls_tilemap
	runtime_blocker_provider = p_runtime_blocker_provider


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

	if runtime_blocker_provider != null \
			and is_instance_valid(runtime_blocker_provider) \
			and runtime_blocker_provider.has_method("is_runtime_walkable_after_props") \
			and not bool(runtime_blocker_provider.call("is_runtime_walkable_after_props", cell)):
		return false
	
	return true


func _connect_adjacent_cells(cell: Vector2i) -> void:
	for neighbor in [cell + Vector2i.RIGHT, cell + Vector2i.DOWN]:
		if _walkable_tiles.has(neighbor):
			var from_id := _cell_to_id(cell)
			var to_id := _cell_to_id(neighbor)
			if _can_traverse_edge(cell, neighbor):
				astar.connect_points(from_id, to_id, false)
			if _can_traverse_edge(neighbor, cell):
				astar.connect_points(to_id, from_id, false)


func _can_traverse_edge(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if not _walkable_tiles.has(from_cell) or not _walkable_tiles.has(to_cell):
		return false
	if runtime_blocker_provider != null \
			and is_instance_valid(runtime_blocker_provider) \
			and runtime_blocker_provider.has_method("can_actor_move_between_tiles"):
		return bool(runtime_blocker_provider.call("can_actor_move_between_tiles", from_cell, to_cell))
	return true


func get_path_to_target(start: Vector2, target: Vector2) -> PackedVector2Array:
	return compute_path_immediate(start, target)


func compute_path_immediate(start: Vector2, target: Vector2) -> PackedVector2Array:
	if runtime_navigation_provider != null and is_instance_valid(runtime_navigation_provider):
		return runtime_navigation_provider.call("compute_path", start, target) as PackedVector2Array
	if not _initialized or astar == null:
		return PackedVector2Array([start, target])
	
	var start_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(start)) if floor_tilemap else Vector2i()
	var target_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(target)) if floor_tilemap else Vector2i()
	
	# Clamp to walkable tiles
	start_cell = _get_nearest_walkable(start_cell)
	target_cell = _get_nearest_walkable(target_cell)
	
	if not _walkable_tiles.has(start_cell) or not _walkable_tiles.has(target_cell):
		return PackedVector2Array()
	
	var start_id = _cell_to_id(start_cell)
	var target_id = _cell_to_id(target_cell)
	
	if not astar.has_point(start_id) or not astar.has_point(target_id):
		return PackedVector2Array()
	
	var path_points = astar.get_point_path(start_id, target_id)
	
	if path_points.is_empty():
		return PackedVector2Array()
	
	return smooth_path(path_points)


func smooth_path(raw_path: PackedVector2Array) -> PackedVector2Array:
	if raw_path.size() <= 2:
		return raw_path
	var result := PackedVector2Array([raw_path[0]])
	var anchor := 0
	while anchor < raw_path.size() - 1:
		var selected := anchor + 1
		for candidate in range(raw_path.size() - 1, anchor, -1):
			if has_grid_line_of_sight(raw_path[anchor], raw_path[candidate], 1):
				selected = candidate
				break
		result.append(raw_path[selected])
		anchor = selected
	return result


func has_grid_line_of_sight(
	start: Vector2,
	target: Vector2,
	clearance_cells := 0
) -> bool:
	if floor_tilemap == null or _walkable_tiles.is_empty():
		return false
	var start_cell := floor_tilemap.local_to_map(
		floor_tilemap.to_local(start)
	)
	var target_cell := floor_tilemap.local_to_map(
		floor_tilemap.to_local(target)
	)
	var current := start_cell
	var dx := absi(target_cell.x - start_cell.x)
	var dy := absi(target_cell.y - start_cell.y)
	var step_x := 1 if start_cell.x < target_cell.x else -1
	var step_y := 1 if start_cell.y < target_cell.y else -1
	var error := dx - dy
	while true:
		if not _cell_has_clearance(current, clearance_cells):
			return false
		if current == target_cell:
			return true
		var next := current
		var doubled_error := error * 2
		if doubled_error > -dy:
			error -= dy
			next.x += step_x
		if doubled_error < dx:
			error += dx
			next.y += step_y
		if not _can_traverse_raster_step(current, next, clearance_cells):
			return false
		current = next
	return false


func _can_traverse_raster_step(from_cell: Vector2i, to_cell: Vector2i, clearance_cells: int) -> bool:
	if not _cell_has_clearance(to_cell, clearance_cells):
		return false
	if from_cell.x == to_cell.x or from_cell.y == to_cell.y:
		return _can_traverse_edge(from_cell, to_cell)
	var via_x := Vector2i(to_cell.x, from_cell.y)
	var via_y := Vector2i(from_cell.x, to_cell.y)
	var x_route := _cell_has_clearance(via_x, clearance_cells) \
		and _can_traverse_edge(from_cell, via_x) \
		and _can_traverse_edge(via_x, to_cell)
	var y_route := _cell_has_clearance(via_y, clearance_cells) \
		and _can_traverse_edge(from_cell, via_y) \
		and _can_traverse_edge(via_y, to_cell)
	return x_route or y_route


func _cell_has_clearance(cell: Vector2i, clearance_cells: int) -> bool:
	for y_offset in range(-clearance_cells, clearance_cells + 1):
		for x_offset in range(-clearance_cells, clearance_cells + 1):
			if not _walkable_tiles.has(
				cell + Vector2i(x_offset, y_offset)
			):
				return false
	return true


func request_enemy_path(
	requester: Node,
	start: Vector2,
	target: Vector2,
	callback: Callable
) -> bool:
	if enemy_navigation_broker == null:
		return false
	return enemy_navigation_broker.request_path(
		requester,
		start,
		target,
		callback
	)


func get_navigation_revision() -> int:
	if runtime_navigation_provider != null and is_instance_valid(runtime_navigation_provider):
		return int(runtime_navigation_provider.call("get_navigation_revision"))
	return navigation_revision


func set_runtime_navigation_provider(provider: Node) -> Node:
	var previous := runtime_navigation_provider
	runtime_navigation_provider = provider
	navigation_revision += 1
	navigation_dirty.emit()
	return previous


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
	if runtime_navigation_provider != null and is_instance_valid(runtime_navigation_provider):
		return bool(runtime_navigation_provider.call("is_world_position_walkable", position))
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
	var world_loader = get_tree().get_first_node_in_group("contract_world_loader")
	if world_loader != null and world_loader.has_method("is_contract_activation_aborted") and bool(world_loader.call("is_contract_activation_aborted")):
		print("[NavigationSystem] Contract generation failed; navigation rebuild skipped")
		return
	_initialize_navigation()
	navigation_dirty.emit()


func get_navigation_authority_debug_snapshot() -> Dictionary:
	var authoritative_floor_count := 0
	if (
		runtime_blocker_provider != null
		and is_instance_valid(runtime_blocker_provider)
		and runtime_blocker_provider.has_method(
			"debug_get_generated_floor_cells"
		)
	):
		var authoritative: Dictionary = runtime_blocker_provider.call(
			"debug_get_generated_floor_cells"
		)
		authoritative_floor_count = authoritative.size()
	return {
		"authoritative_floor_count": authoritative_floor_count,
		"painted_floor_count": (
			floor_tilemap.get_used_cells().size()
			if floor_tilemap != null
			else 0
		),
		"navigation_point_count": _walkable_tiles.size(),
		"initialized": _initialized,
	}
