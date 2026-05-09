class_name MinimapView
extends Control

@export var background_color: Color = Color(0.025, 0.030, 0.032, 0.95)
@export var floor_color: Color = Color(0.18, 0.22, 0.19, 1.0)
@export var wall_color: Color = Color(0.045, 0.055, 0.064, 1.0)
@export var interior_floor_color: Color = Color(0.22, 0.24, 0.21, 1.0)
@export var interior_wall_color: Color = Color(0.065, 0.075, 0.080, 1.0)
@export var compound_color: Color = Color(0.28, 0.33, 0.18, 0.75)
@export var room_color: Color = Color(0.45, 0.52, 0.30, 0.90)
@export var player_color: Color = Color(0.72, 0.94, 0.96, 1.0)
@export var enemy_color: Color = Color(0.86, 0.22, 0.18, 1.0)
@export var passive_creature_color: Color = Color(0.42, 0.86, 0.52, 1.0)
@export var objective_color: Color = Color(0.95, 0.72, 0.24, 1.0)
@export var terminal_color: Color = Color(0.38, 0.70, 0.96, 1.0)
@export var vehicle_color: Color = Color(0.96, 0.80, 0.32, 1.0)
@export var turret_color: Color = Color(0.40, 0.92, 0.78, 1.0)
@export var grid_color: Color = Color(0.32, 0.38, 0.32, 0.16)

@export var map_padding_px: float = 9.0
@export var player_pip_radius_px: float = 3.5
@export var enemy_pip_radius_px: float = 2.1
@export var passive_creature_pip_radius_px: float = 2.6
@export var utility_marker_radius_px: float = 3.0
@export var room_marker_radius_px: float = 1.6
@export var draw_grid: bool = true

var map_size: Vector2i = Vector2i.ZERO
var tile_size: Vector2 = Vector2(32, 32)
var floor_cells: Array[Vector2i] = []
var wall_cells: Array[Vector2i] = []
var rooms: Array[Vector2i] = []
var interior_rooms: Array[Rect2i] = []
var compound_rect: Rect2i = Rect2i()
var compound_ingress: Array[Vector2i] = []
var compound_buildings: Array[Rect2i] = []
var region_tiles: Dictionary = {}

var map_texture: ImageTexture = null
var procgen_tilemap: Node = null
var player_node: Node2D = null
var enemy_nodes: Array[Node2D] = []
var objective_nodes: Array[Node2D] = []
var terminal_nodes: Array[Node2D] = []
var vehicle_nodes: Array[Node2D] = []
var turret_nodes: Array[Node2D] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)


func set_level_data(data: Dictionary) -> void:
	map_size = data.get("map_size", Vector2i.ZERO)
	tile_size = data.get("tile_size", Vector2(32, 32))
	floor_cells = _as_vector2i_array(data.get("floor_cells", []))
	wall_cells = _as_vector2i_array(data.get("wall_cells", []))
	rooms = _as_vector2i_array(data.get("rooms", []))
	interior_rooms = _as_rect2i_array(data.get("interior_rooms", []))
	compound_rect = data.get("compound_rect", Rect2i())
	compound_ingress = _as_vector2i_array(data.get("compound_ingress", []))
	compound_buildings = _as_rect2i_array(data.get("compound_buildings", []))
	region_tiles = data.get("region_tiles", {})
	_rebuild_map_texture()
	queue_redraw()


func set_procgen_tilemap(node: Node) -> void:
	procgen_tilemap = node


func set_player(node: Node2D) -> void:
	player_node = node


func set_enemies(nodes: Array[Node2D]) -> void:
	enemy_nodes = nodes


func set_objectives(nodes: Array[Node2D]) -> void:
	objective_nodes = nodes


func set_terminals(nodes: Array[Node2D]) -> void:
	terminal_nodes = nodes


func set_vehicles(nodes: Array[Node2D]) -> void:
	vehicle_nodes = nodes


func set_turrets(nodes: Array[Node2D]) -> void:
	turret_nodes = nodes


func update_tile(tile: Vector2i, terrain_kind: String) -> void:
	if not _is_tile_inside(tile):
		return
	if terrain_kind == "floor":
		if not floor_cells.has(tile):
			floor_cells.append(tile)
		wall_cells.erase(tile)
	elif terrain_kind == "wall":
		if not wall_cells.has(tile):
			wall_cells.append(tile)
		floor_cells.erase(tile)
	_rebuild_map_texture()
	queue_redraw()


func get_status_summary() -> Dictionary:
	return {
		"map_size": map_size,
		"floor_cells": floor_cells.size(),
		"wall_cells": wall_cells.size(),
		"enemies": _count_hostile_enemy_nodes(),
		"passive_creatures": _count_passive_creature_nodes(),
		"objectives": objective_nodes.size(),
		"terminals": terminal_nodes.size(),
		"vehicles": vehicle_nodes.size(),
		"turrets": turret_nodes.size(),
		"has_player": player_node != null and is_instance_valid(player_node),
	}


func local_to_world(local_pos: Vector2) -> Vector2:
	if map_size.x <= 0 or map_size.y <= 0:
		return Vector2.ZERO
	var map_rect := _get_map_rect()
	if map_rect.size.x <= 0.001 or map_rect.size.y <= 0.001:
		return Vector2.ZERO
	var clamped_pos := Vector2(
		clampf(local_pos.x, map_rect.position.x, map_rect.end.x - 0.001),
		clampf(local_pos.y, map_rect.position.y, map_rect.end.y - 0.001)
	)
	var normalized := (clamped_pos - map_rect.position) / map_rect.size
	var tile := Vector2i(
		clampi(int(floor(normalized.x * float(map_size.x))), 0, map_size.x - 1),
		clampi(int(floor(normalized.y * float(map_size.y))), 0, map_size.y - 1)
	)
	if procgen_tilemap != null and procgen_tilemap.has_method("minimap_tile_to_global"):
		return procgen_tilemap.call("minimap_tile_to_global", tile)
	return Vector2(tile) * tile_size


func _process(_delta: float) -> void:
	queue_redraw()


func _rebuild_map_texture() -> void:
	if map_size.x <= 0 or map_size.y <= 0:
		map_texture = null
		return

	var image := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	image.fill(background_color)

	for tile in floor_cells:
		if _is_tile_inside(tile):
			image.set_pixel(tile.x, tile.y, _terrain_color(tile, false))

	for tile in wall_cells:
		if _is_tile_inside(tile):
			image.set_pixel(tile.x, tile.y, _terrain_color(tile, true))

	map_texture = ImageTexture.create_from_image(image)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color, true)
	if map_texture == null or map_size.x <= 0 or map_size.y <= 0:
		return

	var map_rect := _get_map_rect()
	draw_texture_rect(map_texture, map_rect, false)

	if draw_grid:
		_draw_grid(map_rect)
	_draw_compound_overlay(map_rect)
	_draw_interior_room_overlays(map_rect)
	_draw_room_markers(map_rect)
	_draw_terminal_pips(map_rect)
	_draw_vehicle_pips(map_rect)
	_draw_turret_pips(map_rect)
	_draw_objective_pips(map_rect)
	_draw_enemy_pips(map_rect)
	_draw_player_pip(map_rect)


func _get_map_rect() -> Rect2:
	var available := size - Vector2(map_padding_px * 2.0, map_padding_px * 2.0)
	var scale := minf(available.x / float(maxi(1, map_size.x)), available.y / float(maxi(1, map_size.y)))
	var draw_size := Vector2(float(map_size.x), float(map_size.y)) * scale
	var origin := (size - draw_size) * 0.5
	return Rect2(origin, draw_size)


func _tile_to_panel(tile: Vector2i, map_rect: Rect2) -> Vector2:
	var sx := map_rect.size.x / float(maxi(1, map_size.x))
	var sy := map_rect.size.y / float(maxi(1, map_size.y))
	return map_rect.position + Vector2((float(tile.x) + 0.5) * sx, (float(tile.y) + 0.5) * sy)


func _global_to_tile(global_position: Vector2) -> Vector2i:
	if procgen_tilemap != null and procgen_tilemap.has_method("global_to_minimap_tile"):
		return procgen_tilemap.call("global_to_minimap_tile", global_position)
	return Vector2i(
		int(round(global_position.x / maxf(1.0, tile_size.x))),
		int(round(global_position.y / maxf(1.0, tile_size.y)))
	)


func _draw_player_pip(map_rect: Rect2) -> void:
	if player_node == null or not is_instance_valid(player_node):
		return
	var tile := _global_to_tile(player_node.global_position)
	if not _is_tile_inside(tile):
		return
	var p := _tile_to_panel(tile, map_rect)
	draw_circle(p, player_pip_radius_px + 2.0, Color(0.0, 0.0, 0.0, 0.92))
	draw_circle(p, player_pip_radius_px, player_color)


func _draw_enemy_pips(map_rect: Rect2) -> void:
	for enemy in enemy_nodes:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_dead") and bool(enemy.call("is_dead")):
			continue
		var tile := _global_to_tile(enemy.global_position)
		if _is_tile_inside(tile):
			var panel_pos := _tile_to_panel(tile, map_rect)
			if _is_passive_creature_node(enemy):
				_draw_passive_creature_marker(panel_pos)
			else:
				draw_circle(panel_pos, enemy_pip_radius_px, enemy_color)


func _draw_passive_creature_marker(panel_pos: Vector2) -> void:
	var r := passive_creature_pip_radius_px
	var points := PackedVector2Array([
		panel_pos + Vector2(0.0, -r),
		panel_pos + Vector2(r, 0.0),
		panel_pos + Vector2(0.0, r),
		panel_pos + Vector2(-r, 0.0),
	])
	draw_colored_polygon(points, passive_creature_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.02, 0.035, 0.025, 0.95), 1.0)


func _draw_terminal_pips(map_rect: Rect2) -> void:
	for terminal in terminal_nodes:
		if terminal == null or not is_instance_valid(terminal):
			continue
		var tile := _global_to_tile(terminal.global_position)
		if _is_tile_inside(tile):
			_draw_square_marker(_tile_to_panel(tile, map_rect), terminal_color)


func _draw_vehicle_pips(map_rect: Rect2) -> void:
	for vehicle in vehicle_nodes:
		if vehicle == null or not is_instance_valid(vehicle):
			continue
		var tile := _global_to_tile(vehicle.global_position)
		if _is_tile_inside(tile):
			_draw_triangle_marker(_tile_to_panel(tile, map_rect), vehicle_color)


func _draw_turret_pips(map_rect: Rect2) -> void:
	for turret in turret_nodes:
		if turret == null or not is_instance_valid(turret):
			continue
		var tile := _global_to_tile(turret.global_position)
		if _is_tile_inside(tile):
			_draw_cross_marker(_tile_to_panel(tile, map_rect), turret_color)


func _draw_square_marker(panel_pos: Vector2, color: Color) -> void:
	var r := utility_marker_radius_px
	draw_rect(Rect2(panel_pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), Color(0.0, 0.0, 0.0, 0.9), true)
	draw_rect(Rect2(panel_pos - Vector2(r - 1.0, r - 1.0), Vector2((r - 1.0) * 2.0, (r - 1.0) * 2.0)), color, true)


func _draw_triangle_marker(panel_pos: Vector2, color: Color) -> void:
	var r := utility_marker_radius_px + 0.8
	var points := PackedVector2Array([
		panel_pos + Vector2(0.0, -r),
		panel_pos + Vector2(r, r),
		panel_pos + Vector2(-r, r),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color(0.0, 0.0, 0.0, 0.9), 1.0)


func _draw_cross_marker(panel_pos: Vector2, color: Color) -> void:
	var r := utility_marker_radius_px + 0.5
	draw_line(panel_pos + Vector2(-r, 0.0), panel_pos + Vector2(r, 0.0), Color(0.0, 0.0, 0.0, 0.9), 3.0)
	draw_line(panel_pos + Vector2(0.0, -r), panel_pos + Vector2(0.0, r), Color(0.0, 0.0, 0.0, 0.9), 3.0)
	draw_line(panel_pos + Vector2(-r, 0.0), panel_pos + Vector2(r, 0.0), color, 1.5)
	draw_line(panel_pos + Vector2(0.0, -r), panel_pos + Vector2(0.0, r), color, 1.5)


func _is_passive_creature_node(node: Node) -> bool:
	if node == null:
		return false
	if node.is_in_group("ambient_critter"):
		return true
	if node.has_method("is_passive_enemy"):
		return bool(node.call("is_passive_enemy"))
	return false


func _count_hostile_enemy_nodes() -> int:
	var count := 0
	for enemy in enemy_nodes:
		if enemy != null and is_instance_valid(enemy) and not _is_passive_creature_node(enemy):
			count += 1
	return count


func _count_passive_creature_nodes() -> int:
	var count := 0
	for enemy in enemy_nodes:
		if enemy != null and is_instance_valid(enemy) and _is_passive_creature_node(enemy):
			count += 1
	return count


func _draw_objective_pips(map_rect: Rect2) -> void:
	for objective in objective_nodes:
		if objective == null or not is_instance_valid(objective):
			continue
		var tile := _global_to_tile(objective.global_position)
		if _is_tile_inside(tile):
			draw_circle(_tile_to_panel(tile, map_rect), enemy_pip_radius_px + 1.2, objective_color)


func _draw_room_markers(map_rect: Rect2) -> void:
	for room_tile in rooms:
		if _is_tile_inside(room_tile):
			draw_circle(_tile_to_panel(room_tile, map_rect), room_marker_radius_px, room_color)


func _draw_compound_overlay(map_rect: Rect2) -> void:
	if compound_rect.size.x <= 0 or compound_rect.size.y <= 0:
		return
	draw_rect(_tile_rect_to_panel(compound_rect, map_rect), compound_color, false, 1.0)
	for building in compound_buildings:
		if building.size.x > 0 and building.size.y > 0:
			draw_rect(_tile_rect_to_panel(building, map_rect), Color(compound_color.r, compound_color.g, compound_color.b, 0.28), true)


func _draw_interior_room_overlays(map_rect: Rect2) -> void:
	for room in interior_rooms:
		if room.size.x > 0 and room.size.y > 0:
			draw_rect(_tile_rect_to_panel(room, map_rect), Color(0.58, 0.62, 0.46, 0.22), false, 1.0)


func _draw_grid(map_rect: Rect2) -> void:
	var step := maxf(8.0, minf(map_rect.size.x, map_rect.size.y) / 12.0)
	var x := map_rect.position.x
	while x <= map_rect.end.x:
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), grid_color, 1.0)
		x += step
	var y := map_rect.position.y
	while y <= map_rect.end.y:
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), grid_color, 1.0)
		y += step


func _tile_rect_to_panel(tile_rect: Rect2i, map_rect: Rect2) -> Rect2:
	var sx := map_rect.size.x / float(maxi(1, map_size.x))
	var sy := map_rect.size.y / float(maxi(1, map_size.y))
	return Rect2(
		map_rect.position + Vector2(float(tile_rect.position.x) * sx, float(tile_rect.position.y) * sy),
		Vector2(float(tile_rect.size.x) * sx, float(tile_rect.size.y) * sy)
	)


func _terrain_color(tile: Vector2i, is_wall: bool) -> Color:
	var region_type := _region_type(tile)
	if region_type.begins_with("interior"):
		return interior_wall_color if is_wall else interior_floor_color
	return wall_color if is_wall else floor_color


func _region_type(tile: Vector2i) -> String:
	var data: Variant = region_tiles.get(tile, {})
	if data is Dictionary:
		return String((data as Dictionary).get("region_type", ""))
	return ""


func _is_tile_inside(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size.x and tile.y < map_size.y


func _as_vector2i_array(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if value is Array:
		for item in value:
			if item is Vector2i:
				result.append(item)
	return result


func _as_rect2i_array(value: Variant) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	if value is Array:
		for item in value:
			if item is Rect2i:
				result.append(item)
	return result
