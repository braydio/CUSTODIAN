extends Node
class_name ContractWorldLoader

@export var contract_map_path: NodePath = NodePath("/root/GameRoot/World/ContractMap")
@export var world_path: NodePath = NodePath("/root/GameRoot/World")
@export var sectors_container_path: NodePath = NodePath("/root/GameRoot/World/Sectors")
@export var operator_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var spawn_nodes_path: NodePath = NodePath("/root/GameRoot/World/SpawnNodes")
@export var command_terminal_path: NodePath = NodePath("/root/GameRoot/World/CommandTerminal")
@export var vehicle_root_path: NodePath = NodePath("/root/GameRoot/World")
@export var items_root_path: NodePath = NodePath("/root/GameRoot/World/Items")
@export var camera_path: NodePath = NodePath("/root/GameRoot/World/Camera2D")
@export var navigation_system_path: NodePath = NodePath("/root/GameRoot/NavigationSystem")
@export var runtime_map_container_name: String = "ProcGenRuntime"
@export var hide_static_sectors: bool = true
@export var reposition_operator_from_contract: bool = true
@export var reposition_spawn_nodes_from_contract: bool = true
@export var reposition_terminal_from_contract: bool = true
@export var reposition_vehicles_from_contract: bool = true
@export var reposition_items_from_contract: bool = true
@export var reposition_camera_from_contract: bool = true
@export var place_arrn_relays_from_contract: bool = true
@export var place_tutorial_resource_nodes_from_contract: bool = true
@export var place_expedition_resource_nodes_from_contract: bool = true
@export var place_gothic_compound_connection: bool = true
@export var place_sundered_keep_connection: bool = true
@export var debug_start_near_sundered_keep_entrance: bool = true
@export var debug_sundered_keep_start_offset: Vector2 = Vector2(48.0, 0.0)
@export_range(0, 7, 1) var tutorial_resource_node_count: int = 3
@export_range(2, 64, 1) var tutorial_resource_min_distance_tiles: int = 10
@export_range(4, 96, 1) var tutorial_resource_max_distance_tiles: int = 42
@export_range(2, 32, 1) var tutorial_resource_min_spacing_tiles: int = 12
@export_range(0, 24, 1) var expedition_resource_node_count: int = 8
@export_range(8, 160, 1) var expedition_resource_min_distance_tiles: int = 46
@export_range(2, 48, 1) var expedition_resource_min_spacing_tiles: int = 10
@export_range(0.0, 1.0, 0.01) var expedition_resource_min_intensity: float = 0.30
@export var fallback_tile_size: float = 16.0

const ARRN_RELAY_SCENE := preload("res://game/actors/relay/relay.tscn")
const RESOURCE_NODE_SCENE := preload("res://game/resources/resource_node.tscn")
const GOTHIC_COMPOUND_MAP_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_map.gd")
const GOTHIC_COMPOUND_TRAVEL_GATE_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_travel_gate.gd")
const SUNDERED_KEEP_MAP_SCRIPT := preload("res://game/world/sundered_keep/sundered_keep_map.gd")
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


func _exit_tree() -> void:
	var callback := Callable(self, "_on_contract_generated")
	if _contract_map_node != null and is_instance_valid(_contract_map_node):
		if _contract_map_node.is_connected("contract_generated", callback):
			_contract_map_node.disconnect("contract_generated", callback)
	_contract_map_node = null
	_active_procgen_map = null


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
	if reposition_vehicles_from_contract:
		_position_vehicles(level_data, map_instance)
	if reposition_items_from_contract:
		_position_item_anchors(level_data, map_instance)
	if place_tutorial_resource_nodes_from_contract:
		_position_tutorial_resource_nodes(level_data, map_instance)
	if place_expedition_resource_nodes_from_contract:
		_position_expedition_resource_nodes(level_data, map_instance)
	if place_arrn_relays_from_contract:
		_position_arrn_relays(level_data, map_instance)
	if place_gothic_compound_connection:
		_place_gothic_compound_connection(level_data, map_instance)
	if place_sundered_keep_connection:
		_place_sundered_keep_connection(level_data, map_instance)
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


func _position_tutorial_resource_nodes(level_data: Dictionary, map_instance: Node) -> void:
	var items_root := get_node_or_null(items_root_path)
	if items_root == null:
		return
	for child in items_root.get_children():
		if child.is_in_group("generated_tutorial_resource_node"):
			child.queue_free()
	if tutorial_resource_node_count <= 0:
		return

	var candidate_tiles := _build_tutorial_resource_candidate_tiles(level_data, map_instance)
	if candidate_tiles.is_empty():
		return

	var presets := _get_tutorial_resource_presets()
	var placed_tiles: Array[Vector2i] = []
	var max_nodes: int = mini(tutorial_resource_node_count, presets.size())
	for preset_index in range(max_nodes):
		var preset: Dictionary = presets[preset_index]
		var chosen_tile := _pick_tutorial_resource_tile(candidate_tiles, placed_tiles)
		if chosen_tile == Vector2i.ZERO:
			continue
		var node := _instantiate_generated_resource_node(
			items_root,
			preset,
			"TutorialResource_%s" % String(preset.get("node_kind", "resource")),
			"generated_tutorial_resource_node"
		)
		if node == null:
			continue
		node.global_position = _tile_to_world(map_instance, chosen_tile)
		placed_tiles.append(chosen_tile)


func _position_expedition_resource_nodes(level_data: Dictionary, map_instance: Node) -> void:
	var items_root := get_node_or_null(items_root_path)
	if items_root == null:
		return
	for child in items_root.get_children():
		if child.is_in_group("generated_expedition_resource_node"):
			child.queue_free()
	if expedition_resource_node_count <= 0:
		return

	var candidate_tiles := _build_expedition_resource_candidate_tiles(level_data, map_instance)
	if candidate_tiles.is_empty():
		return

	var presets := _get_expedition_resource_presets()
	if presets.is_empty():
		return

	var placed_tiles: Array[Vector2i] = []
	for preset_index in range(expedition_resource_node_count):
		var preset: Dictionary = presets[preset_index % presets.size()]
		var chosen_tile := _pick_expedition_resource_tile(candidate_tiles, placed_tiles, preset_index)
		if chosen_tile == Vector2i.ZERO:
			continue
		var node := _instantiate_generated_resource_node(
			items_root,
			preset,
			"ExpeditionResource_%02d_%s" % [preset_index + 1, String(preset.get("node_kind", "resource"))],
			"generated_expedition_resource_node"
		)
		if node == null:
			continue
		node.global_position = _tile_to_world(map_instance, chosen_tile)
		placed_tiles.append(chosen_tile)


func _instantiate_generated_resource_node(items_root: Node, preset: Dictionary, node_name: String, group_name: String) -> ResourceNode:
	var node := RESOURCE_NODE_SCENE.instantiate() as ResourceNode
	if node == null:
		return null
	node.name = node_name
	node.add_to_group(group_name)
	_apply_resource_node_preset(node, preset)
	items_root.add_child(node)
	return node


func _build_tutorial_resource_candidate_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}
	var raw_tiles: Array = level_data.get("floor_cells", [])
	if raw_tiles.is_empty():
		raw_tiles = level_data.get("random_floor_tiles", [])
	var player_spawn: Variant = level_data.get("player_spawn")
	var spawn_tile := player_spawn as Vector2i if player_spawn is Vector2i else Vector2i.ZERO
	var min_dist_sq := tutorial_resource_min_distance_tiles * tutorial_resource_min_distance_tiles
	var max_dist_sq := tutorial_resource_max_distance_tiles * tutorial_resource_max_distance_tiles
	var compound_rect: Rect2i = level_data.get("compound_rect", Rect2i()) as Rect2i

	for tile_variant in raw_tiles:
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		if seen.has(tile):
			continue
		seen[tile] = true
		if not _is_walkable_floor_tile(map_instance, tile):
			continue
		if compound_rect.size.x > 0 and compound_rect.size.y > 0 and compound_rect.has_point(tile):
			continue
		var dist_sq := tile.distance_squared_to(spawn_tile)
		if dist_sq < min_dist_sq or dist_sq > max_dist_sq:
			continue
		if _count_walkable_neighbors(map_instance, tile) < 3:
			continue
		candidates.append(tile)

	if candidates.is_empty():
		for tile_variant in raw_tiles:
			if tile_variant is Vector2i and _is_walkable_floor_tile(map_instance, tile_variant as Vector2i):
				candidates.append(tile_variant as Vector2i)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_score := _stable_resource_tile_score(a, spawn_tile)
		var b_score := _stable_resource_tile_score(b, spawn_tile)
		if a_score == b_score:
			return a.x == b.x and a.y < b.y or a.x < b.x
		return a_score < b_score
	)
	return candidates


func _build_expedition_resource_candidate_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}
	var raw_tiles: Array = level_data.get("floor_cells", [])
	if raw_tiles.is_empty():
		raw_tiles = level_data.get("random_floor_tiles", [])
	var player_spawn: Variant = level_data.get("player_spawn")
	var spawn_tile := player_spawn as Vector2i if player_spawn is Vector2i else Vector2i.ZERO
	var min_dist_sq := expedition_resource_min_distance_tiles * expedition_resource_min_distance_tiles
	var compound_rect: Rect2i = level_data.get("compound_rect", Rect2i()) as Rect2i
	var road_tiles := _build_tile_lookup(level_data.get("main_road_tiles", []))
	var parking_tiles := _build_tile_lookup(level_data.get("parking_zone_tiles", []))

	for tile_variant in raw_tiles:
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		if seen.has(tile):
			continue
		seen[tile] = true
		if not _is_expedition_resource_candidate(tile, spawn_tile, min_dist_sq, compound_rect, road_tiles, parking_tiles, map_instance):
			continue
		candidates.append(tile)

	if candidates.is_empty():
		seen.clear()
		for tile_variant in raw_tiles:
			if not (tile_variant is Vector2i):
				continue
			var tile := tile_variant as Vector2i
			if seen.has(tile):
				continue
			seen[tile] = true
			if _is_fallback_expedition_resource_candidate(tile, compound_rect, road_tiles, parking_tiles, map_instance):
				candidates.append(tile)

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_score := _stable_expedition_resource_tile_score(a, spawn_tile)
		var b_score := _stable_expedition_resource_tile_score(b, spawn_tile)
		if a_score == b_score:
			return a.x == b.x and a.y < b.y or a.x < b.x
		return a_score < b_score
	)
	return candidates


func _is_expedition_resource_candidate(
	tile: Vector2i,
	spawn_tile: Vector2i,
	min_dist_sq: int,
	compound_rect: Rect2i,
	road_tiles: Dictionary,
	parking_tiles: Dictionary,
	map_instance: Node
) -> bool:
	if spawn_tile != Vector2i.ZERO and tile.distance_squared_to(spawn_tile) < min_dist_sq:
		return false
	if not _is_fallback_expedition_resource_candidate(tile, compound_rect, road_tiles, parking_tiles, map_instance):
		return false
	return _get_map_tile_intensity(map_instance, tile) >= expedition_resource_min_intensity


func _is_fallback_expedition_resource_candidate(
	tile: Vector2i,
	compound_rect: Rect2i,
	road_tiles: Dictionary,
	parking_tiles: Dictionary,
	map_instance: Node
) -> bool:
	if compound_rect.size.x > 0 and compound_rect.size.y > 0 and compound_rect.has_point(tile):
		return false
	if road_tiles.has(tile) or parking_tiles.has(tile):
		return false
	if _is_excluded_resource_region(_get_map_region_type(map_instance, tile)):
		return false
	if not _is_walkable_floor_tile(map_instance, tile):
		return false
	return _count_walkable_neighbors(map_instance, tile) >= 3


func _pick_expedition_resource_tile(candidates: Array[Vector2i], placed_tiles: Array[Vector2i], preset_index: int) -> Vector2i:
	if candidates.is_empty():
		return Vector2i.ZERO
	var start_index := preset_index % candidates.size()
	for offset in range(candidates.size()):
		var tile: Vector2i = candidates[(start_index + offset) % candidates.size()]
		if not _is_far_enough_from_resource_tiles(tile, placed_tiles, expedition_resource_min_spacing_tiles):
			continue
		return tile
	for offset in range(candidates.size()):
		var tile: Vector2i = candidates[(start_index + offset) % candidates.size()]
		if _is_far_enough_from_resource_tiles(tile, placed_tiles, maxi(2, int(expedition_resource_min_spacing_tiles / 2))):
			return tile
	return Vector2i.ZERO


func _pick_tutorial_resource_tile(candidates: Array[Vector2i], placed_tiles: Array[Vector2i]) -> Vector2i:
	for tile in candidates:
		if not _is_far_enough_from_resource_tiles(tile, placed_tiles, tutorial_resource_min_spacing_tiles):
			continue
		return tile
	for tile in candidates:
		if _is_far_enough_from_resource_tiles(tile, placed_tiles, maxi(2, int(tutorial_resource_min_spacing_tiles / 2))):
			return tile
	return Vector2i.ZERO


func _is_far_enough_from_resource_tiles(tile: Vector2i, placed_tiles: Array[Vector2i], min_spacing: int) -> bool:
	var min_dist_sq := min_spacing * min_spacing
	for placed in placed_tiles:
		if tile.distance_squared_to(placed) < min_dist_sq:
			return false
	return true


func _stable_resource_tile_score(tile: Vector2i, anchor_tile: Vector2i) -> int:
	var value := 2166136261
	for number in [tile.x, tile.y, anchor_tile.x, anchor_tile.y, tutorial_resource_node_count]:
		value = value ^ int(number)
		value = (value * 16777619) & 0x7fffffff
	return value


func _stable_expedition_resource_tile_score(tile: Vector2i, anchor_tile: Vector2i) -> int:
	var value := 2166136261
	for number in [tile.x, tile.y, anchor_tile.x, anchor_tile.y, expedition_resource_node_count, expedition_resource_min_distance_tiles]:
		value = value ^ int(number)
		value = (value * 16777619) & 0x7fffffff
	return value


func _get_tutorial_resource_presets() -> Array[Dictionary]:
	return [
		{
			"node_kind": "blackwood_deadfall",
			"harvest_label": "CUT",
			"resource_id": "blackwood",
			"work_required": 5,
			"yield_amount": 6,
			"secondary_yields": {"ruin_scrap": 1},
			"standing_color": Color(0.16, 0.1, 0.075, 1.0),
			"depleted_color": Color(0.07, 0.055, 0.045, 1.0),
			"prompt_resource_label": "BLACKWOOD",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__depleted__1f__96.png",
			"idle_fx_sheet_path": "res://content/sprites/effects/harvesting_nodes/blackwood_deadfall/props__harvesting_nodes__blackwood_deadfall__node__fx_idle__5f__96.png",
			"strike_fx_sheet_path": "res://content/sprites/effects/harvesting_nodes/blackwood_deadfall/props__harvesting_nodes__blackwood_deadfall__node__fx_strike_idle__5f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "alloy_vein",
			"harvest_label": "MINE",
			"resource_id": "structural_alloy",
			"work_required": 4,
			"yield_amount": 5,
			"secondary_yields": {"ruin_scrap": 2},
			"standing_color": Color(0.25, 0.28, 0.31, 1.0),
			"depleted_color": Color(0.08, 0.085, 0.09, 1.0),
			"prompt_resource_label": "STRUCTURAL ALLOY",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/exposed_alloy_vein/exposed_alloy_vein__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/exposed_alloy_vein/exposed_alloy_vein__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "machine_wreckage",
			"harvest_label": "SALVAGE",
			"resource_id": "ruin_scrap",
			"work_required": 2,
			"yield_amount": 10,
			"secondary_yields": {"capacitor_dust": 1},
			"standing_color": Color(0.18, 0.18, 0.17, 1.0),
			"depleted_color": Color(0.07, 0.07, 0.065, 1.0),
			"prompt_resource_label": "RUIN SCRAP",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/collapsed_machine_shell/collapsed_machine_shell__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/collapsed_machine_shell/collapsed_machine_shell__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "fungal_resin_pod",
			"harvest_label": "CUT",
			"resource_id": "resin_clot",
			"work_required": 3,
			"yield_amount": 4,
			"secondary_yields": {"fiber_moss": 2},
			"standing_color": Color(0.28, 0.18, 0.09, 1.0),
			"depleted_color": Color(0.09, 0.06, 0.04, 1.0),
			"prompt_resource_label": "RESIN CLOT",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/fungal_resin_pod/fungal_resin_pod__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/fungal_resin_pod/fungal_resin_pod__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "ruptured_capacitor_bank",
			"harvest_label": "SALVAGE",
			"resource_id": "capacitor_dust",
			"work_required": 3,
			"yield_amount": 6,
			"secondary_yields": {"power_components": 1, "ruin_scrap": 1},
			"standing_color": Color(0.18, 0.2, 0.24, 1.0),
			"depleted_color": Color(0.06, 0.065, 0.075, 1.0),
			"prompt_resource_label": "CAPACITOR DUST",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/ruptured_capacitor_bank/ruptured_capacitor_bank__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/ruptured_capacitor_bank/ruptured_capacitor_bank__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "broken_signal_relay",
			"harvest_label": "EXTRACT",
			"resource_id": "signal_filament",
			"work_required": 4,
			"yield_amount": 1,
			"secondary_yields": {"capacitor_dust": 2, "ruin_scrap": 2},
			"standing_color": Color(0.1, 0.2, 0.24, 1.0),
			"depleted_color": Color(0.045, 0.06, 0.065, 1.0),
			"prompt_resource_label": "SIGNAL FILAMENT",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/broken_signal_relay/broken_signal_relay__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/broken_signal_relay/broken_signal_relay__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "shattered_archive_terminal",
			"harvest_label": "EXTRACT",
			"resource_id": "memory_glass_fragment",
			"work_required": 4,
			"yield_amount": 2,
			"secondary_yields": {"signal_filament": 1},
			"standing_color": Color(0.15, 0.16, 0.24, 1.0),
			"depleted_color": Color(0.05, 0.052, 0.07, 1.0),
			"prompt_resource_label": "MEMORY GLASS",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/shattered_archive_terminal/shattered_archive_terminal__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/shattered_archive_terminal/shattered_archive_terminal__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
	]


func _get_expedition_resource_presets() -> Array[Dictionary]:
	return _get_tutorial_resource_presets()


func _apply_resource_node_preset(node: ResourceNode, preset: Dictionary) -> void:
	for key in preset.keys():
		node.set(String(key), preset[key])


func _position_arrn_relays(level_data: Dictionary, map_instance: Node) -> void:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		return
	var relay_root := world.get_node_or_null("ARRNRelays") as Node2D
	if relay_root == null:
		relay_root = Node2D.new()
		relay_root.name = "ARRNRelays"
		world.add_child(relay_root)
	for child in relay_root.get_children():
		child.queue_free()

	var relay_specs := [
		{"relay_id": &"R_NORTH", "sector_id": &"T_NORTH", "anchor": Vector2(0.50, 0.16)},
		{"relay_id": &"R_SOUTH", "sector_id": &"T_SOUTH", "anchor": Vector2(0.50, 0.84)},
		{"relay_id": &"R_ARCHIVE", "sector_id": &"ARCHIVE", "anchor": Vector2(0.18, 0.50)},
		{"relay_id": &"R_GATEWAY", "sector_id": &"GATEWAY", "anchor": Vector2(0.84, 0.50)},
	]
	var used_tiles: Dictionary = {}
	for spec in relay_specs:
		var tile := _pick_arrn_relay_tile(level_data, spec["anchor"], used_tiles)
		if tile == Vector2i.ZERO:
			continue
		used_tiles[tile] = true
		var relay := ARRN_RELAY_SCENE.instantiate() as Node2D
		relay.name = String(spec["relay_id"])
		relay.set("relay_id", spec["relay_id"])
		relay.set("sector_id", spec["sector_id"])
		relay.global_position = _tile_to_world(map_instance, tile)
		relay_root.add_child(relay)
		var arrn_manager := get_node_or_null("/root/ARRNManager")
		if arrn_manager != null and arrn_manager.has_method("set_relay_world_position"):
			arrn_manager.call("set_relay_world_position", spec["relay_id"], relay.global_position)


func _place_gothic_compound_connection(level_data: Dictionary, map_instance: Node) -> void:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		return

	var connected_root := world.get_node_or_null("ConnectedMaps") as Node2D
	if connected_root == null:
		connected_root = Node2D.new()
		connected_root.name = "ConnectedMaps"
		world.add_child(connected_root)
	for child in connected_root.get_children():
		if child.is_in_group("generated_gothic_compound_connection"):
			child.queue_free()
	for child in world.get_children():
		if child.is_in_group("generated_gothic_compound_connection") and child.get_parent() == world:
			child.queue_free()

	var main_gate_tile := _pick_gothic_compound_gate_tile(level_data, map_instance)
	if main_gate_tile == Vector2i.ZERO:
		return
	var main_gate_position := _tile_to_world(map_instance, main_gate_tile)

	var gothic_map := GOTHIC_COMPOUND_MAP_SCRIPT.new() as Node2D
	if gothic_map == null:
		return
	gothic_map.name = "GothicCompoundMap"
	gothic_map.add_to_group("generated_gothic_compound_connection")
	gothic_map.global_position = _get_gothic_compound_world_offset(level_data, map_instance)
	gothic_map.call("configure_connection", map_instance, main_gate_position)
	connected_root.add_child(gothic_map)

	var main_gate := GOTHIC_COMPOUND_TRAVEL_GATE_SCRIPT.new() as Node2D
	if main_gate == null:
		return
	main_gate.name = "GothicCompoundTravelGate"
	main_gate.add_to_group("generated_gothic_compound_connection")
	main_gate.call("configure", gothic_map, 0, "ENTER GOTHIC COMPOUND")
	main_gate.global_position = main_gate_position
	world.add_child(main_gate)


func _place_sundered_keep_connection(level_data: Dictionary, map_instance: Node) -> void:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		return

	var connected_root := world.get_node_or_null("ConnectedMaps") as Node2D
	if connected_root == null:
		connected_root = Node2D.new()
		connected_root.name = "ConnectedMaps"
		world.add_child(connected_root)
	for child in connected_root.get_children():
		if child.is_in_group("generated_sundered_keep_connection"):
			child.queue_free()
	for child in world.get_children():
		if child.is_in_group("generated_sundered_keep_connection") and child.get_parent() == world:
			child.queue_free()

	var main_gate_tile := _pick_sundered_keep_gate_tile(level_data, map_instance)
	if main_gate_tile == Vector2i.ZERO:
		return
	var main_gate_position := _tile_to_world(map_instance, main_gate_tile)

	var keep_map := SUNDERED_KEEP_MAP_SCRIPT.new() as Node2D
	if keep_map == null:
		return
	keep_map.name = "SunderedKeepMap"
	keep_map.add_to_group("generated_sundered_keep_connection")
	keep_map.global_position = _get_sundered_keep_world_offset(level_data, map_instance)
	keep_map.call("configure_connection", map_instance, main_gate_position)
	connected_root.add_child(keep_map)

	var main_gate := GOTHIC_COMPOUND_TRAVEL_GATE_SCRIPT.new() as Node2D
	if main_gate == null:
		return
	main_gate.name = "SunderedKeepTravelGate"
	main_gate.add_to_group("generated_sundered_keep_connection")
	main_gate.call("configure", keep_map, 0, "ENTER SUNDERED KEEP")
	main_gate.global_position = main_gate_position
	world.add_child(main_gate)

	if debug_start_near_sundered_keep_entrance:
		var operator := get_node_or_null(operator_path) as Node2D
		if operator != null:
			operator.global_position = main_gate.global_position + debug_sundered_keep_start_offset


func _pick_gothic_compound_gate_tile(level_data: Dictionary, map_instance: Node) -> Vector2i:
	var compound_rect_variant: Variant = level_data.get("compound_rect")
	var ingress_tiles: Array[Vector2i] = []
	for item in level_data.get("compound_ingress", []):
		if item is Vector2i:
			ingress_tiles.append(item as Vector2i)
	if compound_rect_variant is Rect2i and not ingress_tiles.is_empty():
		var compound_rect := compound_rect_variant as Rect2i
		var preferred_ingress := ingress_tiles[0]
		var direction := -_get_compound_ingress_direction(preferred_ingress, compound_rect)
		for depth in range(3, 10):
			var candidate: Vector2i = preferred_ingress + direction * depth
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return preferred_ingress

	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		var spawn_tile := player_spawn as Vector2i
		for offset in [Vector2i(0, 8), Vector2i(8, 0), Vector2i(-8, 0), Vector2i(0, -8)]:
			var candidate: Vector2i = spawn_tile + offset
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return spawn_tile
	return Vector2i.ZERO


func _pick_sundered_keep_gate_tile(level_data: Dictionary, map_instance: Node) -> Vector2i:
	var gothic_gate_tile := _pick_gothic_compound_gate_tile(level_data, map_instance)
	var offsets := [
		Vector2i(4, 0),
		Vector2i(-4, 0),
		Vector2i(0, 4),
		Vector2i(0, -4),
		Vector2i(6, 2),
		Vector2i(-6, 2),
	]
	if gothic_gate_tile != Vector2i.ZERO:
		for offset in offsets:
			var candidate: Vector2i = gothic_gate_tile + offset
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return gothic_gate_tile

	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		var spawn_tile := player_spawn as Vector2i
		for offset in [Vector2i(0, 12), Vector2i(12, 0), Vector2i(-12, 0), Vector2i(0, -12)]:
			var candidate: Vector2i = spawn_tile + offset
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return spawn_tile
	return Vector2i.ZERO


func _get_gothic_compound_world_offset(level_data: Dictionary, map_instance: Node) -> Vector2:
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var tile_size := Vector2(fallback_tile_size, fallback_tile_size)
	if map_instance is ProcGenTilemap:
		tile_size = (map_instance as ProcGenTilemap).get_runtime_tile_size()
	var width_px := float(maxi(map_size.x, 96)) * tile_size.x
	return Vector2(width_px + 1800.0, 0.0)


func _get_sundered_keep_world_offset(level_data: Dictionary, map_instance: Node) -> Vector2:
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var tile_size := Vector2(fallback_tile_size, fallback_tile_size)
	if map_instance is ProcGenTilemap:
		tile_size = (map_instance as ProcGenTilemap).get_runtime_tile_size()
	var width_px := float(maxi(map_size.x, 96)) * tile_size.x
	return Vector2(width_px + 4700.0, 0.0)


func _pick_arrn_relay_tile(level_data: Dictionary, anchor: Vector2, used_tiles: Dictionary) -> Vector2i:
	var floor_tiles: Array[Vector2i] = []
	for tile in level_data.get("floor_cells", []):
		if tile is Vector2i:
			floor_tiles.append(tile as Vector2i)
	if floor_tiles.is_empty():
		for tile in level_data.get("rooms_by_distance", []):
			if tile is Vector2i:
				floor_tiles.append(tile as Vector2i)
	if floor_tiles.is_empty():
		return Vector2i.ZERO

	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var target := Vector2i(
		int(round(float(map_size.x) * anchor.x)),
		int(round(float(map_size.y) * anchor.y))
	) if map_size != Vector2i.ZERO else floor_tiles[0]
	floor_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(target) < b.distance_squared_to(target))
	for tile in floor_tiles:
		if used_tiles.has(tile):
			continue
		return tile
	return floor_tiles[0]


func _position_vehicles(level_data: Dictionary, map_instance: Node) -> void:
	var vehicle_root := get_node_or_null(vehicle_root_path)
	if vehicle_root == null:
		return

	var vehicle_nodes: Array[Node2D] = []
	for child in vehicle_root.get_children():
		if child is Node2D and child.is_in_group("vehicle"):
			vehicle_nodes.append(child as Node2D)
	if vehicle_nodes.is_empty():
		return

	var parking_tiles := _filter_open_tiles(_get_parking_zone_tiles(level_data, map_instance), map_instance)
	if not parking_tiles.is_empty():
		_position_vehicle_nodes_on_tiles(vehicle_nodes, parking_tiles, level_data, map_instance)
		return

	var compound_tiles := _filter_open_compound_tiles(_get_compound_walkable_tiles(level_data, map_instance), map_instance)
	if compound_tiles.is_empty():
		compound_tiles = _get_compound_walkable_tiles(level_data, map_instance)
	if compound_tiles.is_empty():
		return

	var anchor_tile := _pick_compound_spawn_tile(level_data, map_instance)
	var player_spawn: Variant = level_data.get("player_spawn")
	if anchor_tile == Vector2i.ZERO and player_spawn is Vector2i:
		anchor_tile = player_spawn as Vector2i

	var ordered_tiles := compound_tiles.duplicate()
	if anchor_tile != Vector2i.ZERO:
		ordered_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(anchor_tile) < b.distance_squared_to(anchor_tile))

	var used_tiles: Dictionary = {}
	for vehicle in vehicle_nodes:
		var chosen_tile := Vector2i.ZERO
		for tile in ordered_tiles:
			if used_tiles.has(tile):
				continue
			var dist_sq: int = tile.distance_squared_to(anchor_tile)
			if dist_sq < 16:
				continue
			chosen_tile = tile
			break
		if chosen_tile == Vector2i.ZERO:
			for tile in ordered_tiles:
				if not used_tiles.has(tile):
					chosen_tile = tile
					break
		if chosen_tile == Vector2i.ZERO:
			continue
		used_tiles[chosen_tile] = true
		vehicle.global_position = _tile_to_world(map_instance, chosen_tile)


func _position_vehicle_nodes_on_tiles(vehicle_nodes: Array[Node2D], tiles: Array[Vector2i], level_data: Dictionary, map_instance: Node) -> void:
	var anchor_tile := Vector2i.ZERO
	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		anchor_tile = player_spawn as Vector2i
	var ordered_tiles := tiles.duplicate()
	if anchor_tile != Vector2i.ZERO:
		ordered_tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var a_score := a.distance_squared_to(anchor_tile)
			var b_score := b.distance_squared_to(anchor_tile)
			if a_score == b_score:
				return a.x == b.x and a.y < b.y or a.x < b.x
			return a_score < b_score
		)
	var used_tiles: Dictionary = {}
	for vehicle in vehicle_nodes:
		var chosen_tile := Vector2i.ZERO
		for tile in ordered_tiles:
			if used_tiles.has(tile):
				continue
			if anchor_tile != Vector2i.ZERO and tile.distance_squared_to(anchor_tile) < 9:
				continue
			chosen_tile = tile
			break
		if chosen_tile == Vector2i.ZERO:
			for tile in ordered_tiles:
				if not used_tiles.has(tile):
					chosen_tile = tile
					break
		if chosen_tile == Vector2i.ZERO:
			continue
		used_tiles[chosen_tile] = true
		vehicle.global_position = _tile_to_world(map_instance, chosen_tile)


func _get_parking_zone_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile_variant in level_data.get("parking_zone_tiles", []):
		if tile_variant is Vector2i and _is_walkable_floor_tile(map_instance, tile_variant as Vector2i):
			tiles.append(tile_variant as Vector2i)
	if not tiles.is_empty():
		return tiles
	for tile_variant in level_data.get("main_road_tiles", []):
		if tile_variant is Vector2i and _is_walkable_floor_tile(map_instance, tile_variant as Vector2i):
			tiles.append(tile_variant as Vector2i)
	return tiles


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
	return _filter_open_tiles(tiles, map_instance)


func _filter_open_tiles(tiles: Array[Vector2i], map_instance: Node) -> Array[Vector2i]:
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


func _build_tile_lookup(raw_tiles: Variant) -> Dictionary:
	var lookup := {}
	if not (raw_tiles is Array):
		return lookup
	for tile_variant in raw_tiles:
		if tile_variant is Vector2i:
			lookup[tile_variant as Vector2i] = true
	return lookup


func _get_map_region_type(map_instance: Node, tile: Vector2i) -> String:
	if map_instance != null and map_instance.has_method("get_region_type_at_tile"):
		return String(map_instance.call("get_region_type_at_tile", tile))
	return "exterior"


func _get_map_tile_intensity(map_instance: Node, tile: Vector2i) -> float:
	if map_instance != null and map_instance.has_method("get_intensity_at_tile"):
		return float(map_instance.call("get_intensity_at_tile", tile))
	return 0.0


func _is_excluded_resource_region(region_type: String) -> bool:
	return region_type in [
		"spawn_clearing",
		"main_road",
		"parking_zone",
		"soft_path",
		"compound_approach",
		"compound_connector_road",
		"compound_connector_elevated_road",
		"compound_connector_ramp",
		"interior_floor",
		"interior_wall",
		"interior_threshold",
	]


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
