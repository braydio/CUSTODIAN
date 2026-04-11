extends Node
class_name ContractWorldLoader

@export var contract_map_path: NodePath = NodePath("/root/GameRoot/World/ContractMap")
@export var world_path: NodePath = NodePath("/root/GameRoot/World")
@export var sectors_container_path: NodePath = NodePath("/root/GameRoot/World/Sectors")
@export var operator_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var spawn_nodes_path: NodePath = NodePath("/root/GameRoot/World/SpawnNodes")
@export var command_terminal_path: NodePath = NodePath("/root/GameRoot/World/CommandTerminal")
@export var items_root_path: NodePath = NodePath("/root/GameRoot/World/Items")
@export var camera_path: NodePath = NodePath("/root/GameRoot/World/Camera2D")
@export var navigation_system_path: NodePath = NodePath("/root/GameRoot/NavigationSystem")
@export var runtime_map_container_name: String = "ProcGenRuntime"
@export var hide_static_sectors: bool = true
@export var reposition_operator_from_contract: bool = true
@export var reposition_spawn_nodes_from_contract: bool = true
@export var reposition_terminal_from_contract: bool = true
@export var reposition_items_from_contract: bool = true
@export var reposition_camera_from_contract: bool = true
@export var fallback_tile_size: float = 16.0

const SECTOR_TILE_PX := 24.0
const PROCGEN_SECTOR_LAYOUT := {
	"ARCHIVE": 0,
	"POWER": 1,
	"DEFENSE": 2,
	"STORAGE": 3,
}
const DEFENSE_TURRET_LAYOUT := {
	"TurretGunner": Vector2(-0.26, -0.18),
	"TurretBlaster": Vector2(0.24, -0.12),
	"TurretRepeater": Vector2(-0.18, 0.22),
	"TurretSniper": Vector2(0.20, 0.26),
}

var _contract_map_node: Node = null
var _active_procgen_map: Node = null


func _ready() -> void:
	add_to_group("contract_world_loader")
	call_deferred("_bind_contract_map")


func _bind_contract_map() -> void:
	_contract_map_node = get_node_or_null(contract_map_path)
	if _contract_map_node == null:
		push_warning("[ContractWorldLoader] ContractMap not found at %s" % String(contract_map_path))
		return
	if not _contract_map_node.has_signal("contract_generated"):
		push_warning("[ContractWorldLoader] ContractMap missing signal: contract_generated")
		return

	var callback := Callable(self, "_on_contract_generated")
	if not _contract_map_node.is_connected("contract_generated", callback):
		_contract_map_node.connect("contract_generated", callback)

	if _contract_map_node.has_method("get_latest_contract"):
		var latest: Variant = _contract_map_node.call("get_latest_contract")
		if latest is Dictionary and not (latest as Dictionary).is_empty():
			_on_contract_generated(latest)


func _on_contract_generated(contract: Dictionary) -> void:
	var map_block: Dictionary = contract.get("map", {}) as Dictionary
	var level_data: Dictionary = map_block.get("level_data", {}) as Dictionary
	var map_instance_variant: Variant = map_block.get("instance")
	if not (map_instance_variant is Node):
		push_warning("[ContractWorldLoader] Contract map instance missing or invalid")
		return

	var map_instance: Node = map_instance_variant as Node
	_attach_procgen_map(map_instance)
	var sectors_positioned := _position_static_sectors_from_contract(level_data, map_instance)

	if hide_static_sectors and not sectors_positioned:
		var sectors_node := get_node_or_null(sectors_container_path)
		_deactivate_static_sectors(sectors_node)

	if reposition_operator_from_contract:
		_position_operator(level_data, map_instance)
	if reposition_spawn_nodes_from_contract:
		_position_spawn_nodes(level_data, map_instance)
	if reposition_terminal_from_contract:
		_position_command_terminal(level_data, map_instance)
	if reposition_items_from_contract:
		_position_item_anchors(level_data, map_instance)
	if reposition_camera_from_contract:
		_refresh_camera(map_instance)
	_rebuild_navigation(map_instance)
	_mark_contract_ready()


func _mark_contract_ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("mark_contract_ready"):
		game_state.call("mark_contract_ready")


func _position_static_sectors_from_contract(level_data: Dictionary, map_instance: Node) -> bool:
	var sectors_root := get_node_or_null(sectors_container_path)
	if sectors_root == null:
		return false

	var building_tiles: Array[Rect2i] = []
	for item in level_data.get("compound_buildings", []):
		if item is Rect2i:
			building_tiles.append(item as Rect2i)
	if building_tiles.is_empty():
		return false

	var ingress_tiles: Array[Vector2i] = []
	for item in level_data.get("compound_ingress", []):
		if item is Vector2i:
			ingress_tiles.append(item as Vector2i)

	var positioned_any := false
	for sector_name in PROCGEN_SECTOR_LAYOUT.keys():
		var sector_index: int = int(PROCGEN_SECTOR_LAYOUT[sector_name])
		if sector_index >= building_tiles.size():
			continue
		var sector_node := sectors_root.get_node_or_null(String(sector_name)) as Node2D
		if sector_node == null:
			continue
		var sector_rect: Rect2i = building_tiles[sector_index]
		_position_sector_node(sector_node, sector_rect, ingress_tiles, map_instance)
		positioned_any = true
		if sector_name == "DEFENSE":
			_position_defense_turrets(sector_node, sector_rect)

	return positioned_any


func _position_sector_node(sector_node: Node2D, sector_rect: Rect2i, ingress_tiles: Array[Vector2i], map_instance: Node) -> void:
	sector_node.visible = true
	sector_node.process_mode = Node.PROCESS_MODE_INHERIT
	sector_node.scale = _get_sector_runtime_scale(map_instance)
	sector_node.global_position = _rect_center_to_world(map_instance, sector_rect)

	if sector_node is Sector:
		var sector := sector_node as Sector
		sector.size_tiles = sector_rect.size
		sector.door_sides = _infer_sector_doors(sector_rect, ingress_tiles)
		sector._build_geometry()
		_disable_sector_runtime_shell(sector)
		sector.update_visuals()


func _position_defense_turrets(defense_sector: Node2D, sector_rect: Rect2i) -> void:
	var half_w := float(sector_rect.size.x) * SECTOR_TILE_PX * 0.5
	var half_h := float(sector_rect.size.y) * SECTOR_TILE_PX * 0.5
	for child in defense_sector.get_children():
		if not (child is Node2D):
			continue
		var turret := child as Node2D
		var normalized: Vector2 = DEFENSE_TURRET_LAYOUT.get(String(turret.name), Vector2.ZERO)
		turret.position = Vector2(half_w * normalized.x, half_h * normalized.y)
		turret.visible = true
		turret.process_mode = Node.PROCESS_MODE_INHERIT


func _rect_center_to_world(map_instance: Node, rect: Rect2i) -> Vector2:
	var center_tile := Vector2i(
		rect.position.x + int(rect.size.x / 2),
		rect.position.y + int(rect.size.y / 2)
	)
	return _tile_to_world(map_instance, center_tile)


func _infer_sector_doors(sector_rect: Rect2i, ingress_tiles: Array[Vector2i]) -> PackedStringArray:
	var doors := PackedStringArray()
	var max_distance := 4
	for ingress in ingress_tiles:
		if ingress.y >= sector_rect.position.y - max_distance and ingress.y <= sector_rect.position.y + max_distance:
			if ingress.x >= sector_rect.position.x and ingress.x < sector_rect.end.x and not doors.has("N"):
				doors.append("N")
		if ingress.y >= sector_rect.end.y - 1 - max_distance and ingress.y <= sector_rect.end.y - 1 + max_distance:
			if ingress.x >= sector_rect.position.x and ingress.x < sector_rect.end.x and not doors.has("S"):
				doors.append("S")
		if ingress.x >= sector_rect.position.x - max_distance and ingress.x <= sector_rect.position.x + max_distance:
			if ingress.y >= sector_rect.position.y and ingress.y < sector_rect.end.y and not doors.has("W"):
				doors.append("W")
		if ingress.x >= sector_rect.end.x - 1 - max_distance and ingress.x <= sector_rect.end.x - 1 + max_distance:
			if ingress.y >= sector_rect.position.y and ingress.y < sector_rect.end.y and not doors.has("E"):
				doors.append("E")
	if doors.is_empty():
		doors.append("N")
	return doors


func _attach_procgen_map(map_instance: Node) -> void:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		push_warning("[ContractWorldLoader] World not found at %s" % String(world_path))
		return

	var runtime_container := world.get_node_or_null(runtime_map_container_name) as Node2D
	if runtime_container == null:
		runtime_container = Node2D.new()
		runtime_container.name = runtime_map_container_name
		runtime_container.z_index = -100
		world.add_child(runtime_container)

	if map_instance.get_parent() != runtime_container:
		map_instance.reparent(runtime_container)

	map_instance.visible = true
	map_instance.z_index = -100
	_active_procgen_map = map_instance


func _position_operator(level_data: Dictionary, map_instance: Node) -> void:
	var operator := get_node_or_null(operator_path) as Node2D
	if operator == null:
		return
	var compound_spawn := _pick_compound_spawn_tile(level_data, map_instance)
	if compound_spawn != Vector2i.ZERO:
		operator.global_position = _tile_to_world(map_instance, compound_spawn)
		return
	var player_spawn: Variant = level_data.get("player_spawn")
	if not (player_spawn is Vector2i):
		return
	operator.global_position = _tile_to_world(map_instance, player_spawn as Vector2i)


func _position_spawn_nodes(level_data: Dictionary, map_instance: Node) -> void:
	var spawn_root := get_node_or_null(spawn_nodes_path)
	if spawn_root == null:
		return

	var nodes: Array[Node2D] = []
	for child in spawn_root.get_children():
		if child is Node2D:
			nodes.append(child as Node2D)
	if nodes.is_empty():
		return

	var compound_ingress_raw: Array = level_data.get("compound_ingress", [])
	var map_size_variant: Variant = level_data.get("map_size", Vector2i.ZERO)
	var corridor_spawns_raw: Array = level_data.get("corridor_spawns", [])
	var room_fallback_raw: Array = level_data.get("rooms_by_distance", [])
	var tiles: Array[Vector2i] = []
	for item in compound_ingress_raw:
		if item is Vector2i and map_size_variant is Vector2i:
			var projected := _project_ingress_to_edge(item as Vector2i, map_size_variant as Vector2i)
			tiles.append(projected)
	for item in corridor_spawns_raw:
		if item is Vector2i:
			tiles.append(item as Vector2i)
	if tiles.is_empty():
		for item in room_fallback_raw:
			if item is Vector2i:
				tiles.append(item as Vector2i)
	if tiles.is_empty():
		return

	for i in range(nodes.size()):
		var tile_index: int = 0
		if tiles.size() > 1 and nodes.size() > 1:
			tile_index = int(round(float(i) * float(tiles.size() - 1) / float(nodes.size() - 1)))
		tile_index = clamp(tile_index, 0, tiles.size() - 1)
		nodes[i].global_position = _tile_to_world(map_instance, tiles[tile_index])


func _refresh_camera(map_instance: Node) -> void:
	var camera := get_node_or_null(camera_path) as Node
	if camera == null:
		return
	if camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	if camera.has_method("snap_to_player_spawn"):
		var operator := get_node_or_null(operator_path) as Node2D
		if operator != null:
			camera.call("snap_to_player_spawn", operator.global_position)


func _rebuild_navigation(map_instance: Node) -> void:
	var nav := get_node_or_null(navigation_system_path)
	if nav == null:
		push_warning("[ContractWorldLoader] NavigationSystem not found at %s" % String(navigation_system_path))
		return
	if not nav.has_method("rebuild"):
		push_warning("[ContractWorldLoader] NavigationSystem missing rebuild method")
		return

	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		if nav.has_method("set_runtime_tilemaps"):
			nav.call("set_runtime_tilemaps", pg.floor_tilemap, pg.walls_tilemap)
		else:
			if pg.floor_tilemap:
				nav.floor_tilemap = pg.floor_tilemap
			if pg.walls_tilemap:
				nav.walls_tilemap = pg.walls_tilemap
	nav.rebuild()
	print("[ContractWorldLoader] Navigation rebuilt with procgen tilemaps")


func get_active_map_instance() -> Node:
	return _active_procgen_map


func _position_command_terminal(level_data: Dictionary, map_instance: Node) -> void:
	var terminal := get_node_or_null(command_terminal_path) as Node2D
	if terminal == null:
		return

	var compound_rect: Variant = level_data.get("compound_rect")
	var compound_tiles := _get_compound_walkable_tiles(level_data, map_instance)
	var player_spawn_tile := _pick_compound_spawn_tile(level_data, map_instance)
	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn_tile == Vector2i.ZERO and player_spawn is Vector2i:
		player_spawn_tile = player_spawn as Vector2i

	var target_tile := Vector2i.ZERO
	if player_spawn_tile != Vector2i.ZERO:
		target_tile = player_spawn_tile
	if compound_rect is Rect2i:
		target_tile = Vector2i((compound_rect as Rect2i).get_center())

	var chosen_tile := _pick_closest_tile(compound_tiles, target_tile)
	if chosen_tile == Vector2i.ZERO:
		chosen_tile = player_spawn_tile
	terminal.global_position = _tile_to_world(map_instance, chosen_tile)


func _position_item_anchors(level_data: Dictionary, map_instance: Node) -> void:
	var items_root := get_node_or_null(items_root_path)
	if items_root == null:
		return

	var random_floor_tiles_raw: Array = level_data.get("random_floor_tiles", [])
	var room_tiles_raw: Array = level_data.get("rooms_by_distance", [])
	var available_tiles: Array[Vector2i] = []
	for tile in random_floor_tiles_raw:
		if tile is Vector2i:
			available_tiles.append(tile as Vector2i)
	if available_tiles.is_empty():
		for tile in room_tiles_raw:
			if tile is Vector2i:
				available_tiles.append(tile as Vector2i)
	if available_tiles.is_empty():
		return

	available_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.x == b.x and a.y < b.y or a.x < b.x)

	var player_spawn: Variant = level_data.get("player_spawn")
	var target_tile := Vector2i.ZERO
	if player_spawn is Vector2i:
		target_tile = player_spawn as Vector2i

	var ordered_tiles := available_tiles.duplicate()
	if target_tile != Vector2i.ZERO:
		ordered_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(target_tile) < b.distance_squared_to(target_tile))

	var used_tiles: Dictionary = {}
	var tile_index := 0
	for child in items_root.get_children():
		if not (child is Node2D):
			continue
		while tile_index < ordered_tiles.size() and used_tiles.has(ordered_tiles[tile_index]):
			tile_index += 1
		if tile_index >= ordered_tiles.size():
			break
		var tile: Vector2i = ordered_tiles[tile_index]
		used_tiles[tile] = true
		(child as Node2D).global_position = _tile_to_world(map_instance, tile)
		tile_index += 1


func _project_ingress_to_edge(ingress: Vector2i, map_size: Vector2i) -> Vector2i:
	var left: int = ingress.x
	var right: int = (map_size.x - 1) - ingress.x
	var top: int = ingress.y
	var bottom: int = (map_size.y - 1) - ingress.y
	var best: int = min(min(left, right), min(top, bottom))
	var margin: int = 1
	if best == left:
		return Vector2i(margin, ingress.y)
	if best == right:
		return Vector2i(map_size.x - 1 - margin, ingress.y)
	if best == top:
		return Vector2i(ingress.x, margin)
	return Vector2i(ingress.x, map_size.y - 1 - margin)


func _tile_to_world(map_instance: Node, tile: Vector2i) -> Vector2:
	if map_instance is ProcGenTilemap:
		var pg: ProcGenTilemap = map_instance as ProcGenTilemap
		if pg.floor_tilemap != null:
			var tm: TileMapLayer = pg.floor_tilemap
			var local := tm.map_to_local(tile)
			return tm.to_global(local)
	if map_instance is Node2D:
		return (map_instance as Node2D).global_position + Vector2(tile) * fallback_tile_size
	return Vector2(tile) * fallback_tile_size


func _pick_closest_tile(tiles: Array[Vector2i], target_tile: Vector2i) -> Vector2i:
	if tiles.is_empty():
		return Vector2i.ZERO
	var best_tile: Vector2i = tiles[0]
	var best_distance := best_tile.distance_squared_to(target_tile)
	for tile in tiles:
		var dist := tile.distance_squared_to(target_tile)
		if dist < best_distance:
			best_distance = dist
			best_tile = tile
	return best_tile


func _pick_compound_spawn_tile(level_data: Dictionary, map_instance: Node) -> Vector2i:
	var walkable_tiles := _get_compound_walkable_tiles(level_data, map_instance)
	if walkable_tiles.is_empty():
		return Vector2i.ZERO
	var open_tiles := _filter_open_compound_tiles(walkable_tiles, map_instance)
	var preferred_tiles := open_tiles if not open_tiles.is_empty() else walkable_tiles

	var compound_rect_variant: Variant = level_data.get("compound_rect")
	var ingress_tiles: Array[Vector2i] = []
	for item in level_data.get("compound_ingress", []):
		if item is Vector2i:
			ingress_tiles.append(item as Vector2i)

	if compound_rect_variant is Rect2i:
		var compound_rect := compound_rect_variant as Rect2i
		for ingress in ingress_tiles:
			var picked := _pick_ingress_adjacent_spawn_tile(ingress, compound_rect, preferred_tiles, map_instance)
			if picked != Vector2i.ZERO:
				return picked
		return _pick_closest_tile(preferred_tiles, Vector2i(compound_rect.get_center()))

	return preferred_tiles[0]


func _get_compound_walkable_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var compound_rect_variant: Variant = level_data.get("compound_rect")
	if not (compound_rect_variant is Rect2i):
		return tiles

	var compound_rect := compound_rect_variant as Rect2i
	for x in range(compound_rect.position.x, compound_rect.end.x):
		for y in range(compound_rect.position.y, compound_rect.end.y):
			var tile := Vector2i(x, y)
			if _is_walkable_floor_tile(map_instance, tile):
				tiles.append(tile)
	return tiles


func _filter_open_compound_tiles(tiles: Array[Vector2i], map_instance: Node) -> Array[Vector2i]:
	var open_tiles: Array[Vector2i] = []
	for tile in tiles:
		if _count_walkable_neighbors(map_instance, tile) >= 2:
			open_tiles.append(tile)
	return open_tiles


func _get_compound_interior_tile(ingress: Vector2i, compound_rect: Rect2i) -> Vector2i:
	var depth := 2
	if ingress.y <= compound_rect.position.y:
		return ingress + Vector2i.DOWN * depth
	if ingress.y >= compound_rect.end.y - 1:
		return ingress + Vector2i.UP * depth
	if ingress.x <= compound_rect.position.x:
		return ingress + Vector2i.RIGHT * depth
	return ingress + Vector2i.LEFT * depth


func _pick_ingress_adjacent_spawn_tile(ingress: Vector2i, compound_rect: Rect2i, candidate_tiles: Array[Vector2i], map_instance: Node) -> Vector2i:
	if candidate_tiles.is_empty():
		return Vector2i.ZERO
	var ingress_dir := _get_compound_ingress_direction(ingress, compound_rect)
	for depth in range(2, 7):
		var probe := ingress + ingress_dir * depth
		if candidate_tiles.has(probe):
			return probe
		if _is_walkable_floor_tile(map_instance, probe):
			var nearby := _pick_closest_tile(candidate_tiles, probe)
			if nearby != Vector2i.ZERO and nearby.distance_squared_to(probe) <= 4:
				return nearby
	var target := _get_compound_interior_tile(ingress, compound_rect)
	return _pick_closest_tile(candidate_tiles, target)


func _get_compound_ingress_direction(ingress: Vector2i, compound_rect: Rect2i) -> Vector2i:
	if ingress.y <= compound_rect.position.y:
		return Vector2i.DOWN
	if ingress.y >= compound_rect.end.y - 1:
		return Vector2i.UP
	if ingress.x <= compound_rect.position.x:
		return Vector2i.RIGHT
	return Vector2i.LEFT


func _is_walkable_floor_tile(map_instance: Node, tile: Vector2i) -> bool:
	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		if pg.walls_tilemap != null and pg.walls_tilemap.get_cell_source_id(tile) >= 0:
			return false
		if pg.floor_tilemap != null and pg.floor_tilemap.get_cell_source_id(tile) >= 0:
			if pg.has_method("is_hole_tile") and bool(pg.call("is_hole_tile", tile)):
				return false
			return true
	return false


func _count_walkable_neighbors(map_instance: Node, tile: Vector2i) -> int:
	var count := 0
	for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _is_walkable_floor_tile(map_instance, tile + offset):
			count += 1
	return count


func _deactivate_static_sectors(sectors_node: Node) -> void:
	if sectors_node == null:
		return

	for node in sectors_node.find_children("*"):
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is CollisionShape2D:
			(node as CollisionShape2D).set_deferred("disabled", true)
		elif node is CollisionPolygon2D:
			(node as CollisionPolygon2D).set_deferred("disabled", true)
		elif node is CollisionObject2D:
			var co := node as CollisionObject2D
			co.set_deferred("collision_layer", 0)
			co.set_deferred("collision_mask", 0)


func _disable_sector_runtime_shell(sector: Sector) -> void:
	if sector == null:
		return
	if sector.floor_rect:
		sector.floor_rect.visible = false
	if sector.walls:
		sector.walls.visible = false
	if sector.wall_collision:
		sector.wall_collision.set_deferred("collision_layer", 0)
		sector.wall_collision.set_deferred("collision_mask", 0)
		for child in sector.wall_collision.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", true)


func _get_sector_runtime_scale(map_instance: Node) -> Vector2:
	var runtime_tile_px := fallback_tile_size
	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		var tile_size := pg.get_runtime_tile_size()
		runtime_tile_px = max(tile_size.x, 1.0)
	var scale_factor := runtime_tile_px / SECTOR_TILE_PX
	return Vector2(scale_factor, scale_factor)
