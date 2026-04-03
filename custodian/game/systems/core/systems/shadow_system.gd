extends Node2D
class_name ShadowSystem

@export var shadow_offset_px: Vector2 = Vector2(6.0, 6.0)
@export_range(0.0, 1.0, 0.01) var edge_alpha: float = 0.18
@export_range(0.0, 1.0, 0.01) var corner_alpha: float = 0.30
@export_range(0.0, 16.0, 0.5) var edge_inset_px: float = 3.0
@export_range(0.0, 1.0, 0.01) var corner_scale: float = 0.7

var floor_tilemap: TileMapLayer = null
var walls_tilemap: TileMapLayer = null

var _edge_cells: Dictionary = {}
var _corner_cells: Dictionary = {}
var _tile_size: Vector2 = Vector2(16.0, 16.0)
var _regeneration_queued: bool = false


func initialize(p_floor_tilemap: TileMapLayer, p_walls_tilemap: TileMapLayer) -> void:
	floor_tilemap = p_floor_tilemap
	walls_tilemap = p_walls_tilemap
	_update_tile_size()


func request_regenerate() -> void:
	if _regeneration_queued:
		return
	_regeneration_queued = true
	call_deferred("_regenerate_deferred")


func clear_shadows() -> void:
	_edge_cells.clear()
	_corner_cells.clear()
	queue_redraw()


func generate_shadows() -> void:
	if not _has_valid_tilemaps():
		clear_shadows()
		return

	_update_tile_size()
	_edge_cells.clear()
	_corner_cells.clear()

	var floor_cells: Dictionary = {}
	var wall_cells: Dictionary = {}

	for cell in floor_tilemap.get_used_cells():
		if _is_floor_cell(cell):
			floor_cells[cell] = true

	for cell in walls_tilemap.get_used_cells():
		if walls_tilemap.get_cell_source_id(cell) >= 0:
			wall_cells[cell] = true

	for cell in floor_cells.keys():
		var edge_strength := 0.0
		if wall_cells.has(cell + Vector2i.UP):
			edge_strength += edge_alpha
		if wall_cells.has(cell + Vector2i.LEFT):
			edge_strength += edge_alpha
		if edge_strength > 0.0:
			_edge_cells[cell] = min(edge_strength, 0.55)

		if wall_cells.has(cell + Vector2i.UP) and wall_cells.has(cell + Vector2i.LEFT):
			_corner_cells[cell] = corner_alpha

	queue_redraw()


func _draw() -> void:
	if _edge_cells.is_empty() and _corner_cells.is_empty():
		return

	var edge_size := Vector2(
		max(_tile_size.x - edge_inset_px * 2.0, 6.0),
		max(_tile_size.y - edge_inset_px * 2.0, 6.0)
	)
	var corner_size := edge_size * corner_scale

	for cell in _edge_cells.keys():
		var center := _cell_center_in_overlay_space(cell)
		var alpha := float(_edge_cells[cell])
		_draw_shadow_rect(center, edge_size, shadow_offset_px, alpha)

	for cell in _corner_cells.keys():
		var center := _cell_center_in_overlay_space(cell)
		var corner_offset := shadow_offset_px + (_tile_size - corner_size) * 0.18
		_draw_shadow_rect(center, corner_size, corner_offset, float(_corner_cells[cell]))


func _regenerate_deferred() -> void:
	_regeneration_queued = false
	generate_shadows()


func _draw_shadow_rect(center: Vector2, size: Vector2, offset: Vector2, alpha: float) -> void:
	var origin := center - size * 0.5 + offset
	draw_rect(Rect2(origin, size), Color(0.0, 0.0, 0.0, alpha), true)


func _cell_center_in_overlay_space(cell: Vector2i) -> Vector2:
	if floor_tilemap == null:
		return Vector2.ZERO
	var local_in_tilemap := floor_tilemap.map_to_local(cell)
	var global_pos := floor_tilemap.to_global(local_in_tilemap)
	return to_local(global_pos)


func _is_floor_cell(cell: Vector2i) -> bool:
	if floor_tilemap == null:
		return false
	if floor_tilemap.get_cell_source_id(cell) < 0:
		return false
	if walls_tilemap != null and walls_tilemap.get_cell_source_id(cell) >= 0:
		return false
	return true


func _has_valid_tilemaps() -> bool:
	return is_instance_valid(floor_tilemap) and is_instance_valid(walls_tilemap)


func _update_tile_size() -> void:
	if floor_tilemap != null and floor_tilemap.tile_set != null:
		_tile_size = Vector2(floor_tilemap.tile_set.tile_size)
