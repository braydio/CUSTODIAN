class_name MinimapController
extends Control

@export var minimap_view_path: NodePath = NodePath("MinimapView")
@export var procgen_tilemap_path: NodePath
@export var player_group_name: StringName = &"player"
@export var enemy_group_name: StringName = &"enemy"
@export var objective_group_name: StringName = &"objective"
@export var terminal_group_name: StringName = &"command_terminal"
@export var vehicle_group_name: StringName = &"vehicle"
@export var turret_group_name: StringName = &"turret"
@export var relay_group_name: StringName = &"arrn_relay"
@export var refresh_entities_interval: float = 0.25
@export var retry_procgen_interval: float = 0.35
@export var enable_expand_toggle: bool = true
@export var toggle_expand_action: StringName = &"toggle_minimap_expand"
@export var compact_size: Vector2 = Vector2(224, 224)
@export var expanded_size: Vector2 = Vector2(560, 560)
@export var screen_margin: Vector2 = Vector2(20, 20)

var minimap_view: Node = null
var procgen_tilemap: Node = null
var _refresh_accum := 0.0
var _retry_accum := 0.0
var _connected_procgen_id := 0
var _expanded := false


func _ready() -> void:
	minimap_view = get_node_or_null(minimap_view_path)
	_apply_minimap_size(false)
	_resolve_procgen()
	_refresh_dynamic_nodes()
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if not enable_expand_toggle or not visible:
		return
	if InputMap.has_action(toggle_expand_action) and event.is_action_pressed(toggle_expand_action):
		toggle_expanded()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if procgen_tilemap == null or not is_instance_valid(procgen_tilemap):
		_retry_accum += delta
		if _retry_accum >= retry_procgen_interval:
			_retry_accum = 0.0
			_resolve_procgen()

	_refresh_accum += delta
	if _refresh_accum >= refresh_entities_interval:
		_refresh_accum = 0.0
		_refresh_dynamic_nodes()


func get_status_summary() -> Dictionary:
	var view_status := {}
	if minimap_view != null and minimap_view.has_method("get_status_summary"):
		view_status = minimap_view.call("get_status_summary")
	view_status["procgen_connected"] = procgen_tilemap != null and is_instance_valid(procgen_tilemap)
	view_status["visible"] = visible
	view_status["expanded"] = _expanded
	return view_status


func toggle_expanded() -> void:
	set_expanded(not _expanded)


func set_expanded(expanded: bool) -> void:
	if not enable_expand_toggle:
		return
	_expanded = expanded
	_apply_minimap_size(_expanded)


func refresh_now() -> void:
	_resolve_procgen()
	_refresh_dynamic_nodes()


func local_to_world(local_pos: Vector2) -> Vector2:
	minimap_view = get_node_or_null(minimap_view_path)
	if minimap_view == null or not (minimap_view is Control) or not minimap_view.has_method("local_to_world"):
		return Vector2.ZERO
	var view_control := minimap_view as Control
	var global_pos: Vector2 = get_global_transform() * local_pos
	var view_local: Vector2 = view_control.get_global_transform().affine_inverse() * global_pos
	return minimap_view.call("local_to_world", view_local)


func _apply_minimap_size(expanded: bool) -> void:
	if not enable_expand_toggle:
		return
	var target_size := expanded_size if expanded else compact_size
	custom_minimum_size = target_size
	if get_parent() is Container:
		return
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_right = -screen_margin.x
	offset_left = offset_right - target_size.x
	offset_top = screen_margin.y
	offset_bottom = offset_top + target_size.y


func _resolve_procgen() -> void:
	minimap_view = get_node_or_null(minimap_view_path)
	if procgen_tilemap_path != NodePath(""):
		procgen_tilemap = get_node_or_null(procgen_tilemap_path)
	if procgen_tilemap == null or not is_instance_valid(procgen_tilemap):
		procgen_tilemap = _find_procgen_tilemap()
	_connect_procgen()


func _find_procgen_tilemap() -> Node:
	var nodes := get_tree().get_nodes_in_group("procgen_tilemap")
	for node in nodes:
		if node != null and is_instance_valid(node):
			return node
	for group_name in ["sundered_keep_map", "connected_map"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node != null and is_instance_valid(node) and node.has_method("get_level_data"):
				return node

	var root := get_tree().current_scene
	if root == null:
		return null
	var procgen := _find_child_by_script_class(root, "ProcGenTilemap")
	if procgen != null:
		return procgen
	return _find_child_with_method(root, "get_level_data")


func _find_child_by_script_class(root: Node, class_name_text: String) -> Node:
	if root == null:
		return null
	var script: Script = root.get_script()
	if script != null and String(script.get_global_name()) == class_name_text:
		return root
	for child in root.get_children():
		var found := _find_child_by_script_class(child, class_name_text)
		if found != null:
			return found
	return null


func _find_child_with_method(root: Node, method_name: String) -> Node:
	if root == null:
		return null
	if root.has_method(method_name):
		return root
	for child in root.get_children():
		var found := _find_child_with_method(child, method_name)
		if found != null:
			return found
	return null


func _connect_procgen() -> void:
	if procgen_tilemap == null or minimap_view == null:
		return
	var procgen_id := procgen_tilemap.get_instance_id()
	if _connected_procgen_id == procgen_id:
		return
	_connected_procgen_id = procgen_id

	minimap_view.set_procgen_tilemap(procgen_tilemap)
	if procgen_tilemap.has_signal("level_data_ready") and not procgen_tilemap.level_data_ready.is_connected(_on_level_data_ready):
		procgen_tilemap.level_data_ready.connect(_on_level_data_ready)
	if procgen_tilemap.has_signal("minimap_tile_changed") and not procgen_tilemap.minimap_tile_changed.is_connected(_on_minimap_tile_changed):
		procgen_tilemap.minimap_tile_changed.connect(_on_minimap_tile_changed)
	if procgen_tilemap.has_method("get_level_data"):
		var data: Dictionary = procgen_tilemap.call("get_level_data")
		if data.get("map_size", Vector2i.ZERO) != Vector2i.ZERO:
			_on_level_data_ready(data)


func _on_level_data_ready(data: Dictionary) -> void:
	if minimap_view != null:
		minimap_view.set_level_data(data)


func _on_minimap_tile_changed(tile: Vector2i, terrain_kind: String) -> void:
	if minimap_view != null:
		minimap_view.update_tile(tile, terrain_kind)


func _refresh_dynamic_nodes() -> void:
	if minimap_view == null:
		return
	var player := get_tree().get_first_node_in_group(player_group_name) as Node2D
	if player != null:
		minimap_view.set_player(player)

	var enemies: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(enemy_group_name):
		if node is Node2D:
			enemies.append(node as Node2D)

	var objectives: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(objective_group_name):
		if node is Node2D:
			objectives.append(node as Node2D)

	var terminals: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(terminal_group_name):
		if node is Node2D:
			terminals.append(node as Node2D)

	var vehicles: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(vehicle_group_name):
		if node is Node2D:
			vehicles.append(node as Node2D)

	var turrets: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(turret_group_name):
		if node is Node2D:
			turrets.append(node as Node2D)

	var relays: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(relay_group_name):
		if node is Node2D and bool(node.get("visible")):
			relays.append(node as Node2D)

	minimap_view.set_enemies(enemies)
	minimap_view.set_objectives(objectives)
	if minimap_view.has_method("set_terminals"):
		minimap_view.call("set_terminals", terminals)
	if minimap_view.has_method("set_vehicles"):
		minimap_view.call("set_vehicles", vehicles)
	if minimap_view.has_method("set_turrets"):
		minimap_view.call("set_turrets", turrets)
	if minimap_view.has_method("set_relays"):
		minimap_view.call("set_relays", relays)
	if procgen_tilemap == null or not is_instance_valid(procgen_tilemap):
		_update_dynamic_bounds(player, enemies, objectives, terminals, vehicles, turrets, relays)


func _update_dynamic_bounds(
	player: Node2D,
	enemies: Array[Node2D],
	objectives: Array[Node2D],
	terminals: Array[Node2D],
	vehicles: Array[Node2D],
	turrets: Array[Node2D],
	relays: Array[Node2D]
) -> void:
	if minimap_view == null or not minimap_view.has_method("set_world_bounds"):
		return
	var nodes: Array[Node2D] = []
	if player != null:
		nodes.append(player)
	nodes.append_array(enemies)
	nodes.append_array(objectives)
	nodes.append_array(terminals)
	nodes.append_array(vehicles)
	nodes.append_array(turrets)
	nodes.append_array(relays)
	if nodes.is_empty():
		return
	var min_pos := nodes[0].global_position
	var max_pos := nodes[0].global_position
	for node in nodes:
		min_pos.x = minf(min_pos.x, node.global_position.x)
		min_pos.y = minf(min_pos.y, node.global_position.y)
		max_pos.x = maxf(max_pos.x, node.global_position.x)
		max_pos.y = maxf(max_pos.y, node.global_position.y)
	var margin := Vector2(384.0, 384.0)
	var rect := Rect2(min_pos - margin, (max_pos - min_pos) + margin * 2.0)
	rect.size.x = maxf(rect.size.x, 1024.0)
	rect.size.y = maxf(rect.size.y, 1024.0)
	minimap_view.call("set_world_bounds", rect)
