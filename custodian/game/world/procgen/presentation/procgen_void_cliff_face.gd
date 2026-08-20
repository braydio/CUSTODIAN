class_name ProcgenVoidCliffFace
extends TileMapLayer

const CARDINALS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]

@export_group("Presentation")
@export var presentation_enabled := true

@export_group("Depth")
@export_range(1, 12, 1) var min_depth_tiles := 3
@export_range(1, 12, 1) var max_depth_tiles := 8
@export_range(1, 16, 1) var variation_patch_tiles := 4

@export_group("Tile")
@export var body_source_id := 45
@export var body_atlas_coord := Vector2i.ZERO

var _last_seed := 0
var _last_painted_cell_count := 0


func configure_from_surface_cells(
	floor_cells: Dictionary,
	chasm_cells: Dictionary,
	seed: int
) -> void:
	clear()
	_last_seed = seed
	_last_painted_cell_count = 0

	if not presentation_enabled:
		visible = false
		return
	if tile_set == null:
		visible = false
		push_warning("[ProcgenVoidCliffFace] Missing TileSet.")
		return
	if not tile_set.has_source(body_source_id):
		visible = false
		push_warning(
			"[ProcgenVoidCliffFace] Missing body TileSet source %d."
			% body_source_id
		)
		return
	if floor_cells.is_empty() or chasm_cells.is_empty():
		visible = false
		return

	var queue_cells: Array[Vector2i] = []
	var queue_distances: Array[int] = []
	var queue_limits: Array[int] = []
	var best_remaining_by_cell: Dictionary = {}

	for floor_variant: Variant in floor_cells.keys():
		if not floor_variant is Vector2i:
			continue
		var floor_cell := floor_variant as Vector2i
		var depth_limit := _depth_limit_for_frontier(floor_cell, seed)
		for direction in CARDINALS:
			var first_chasm_cell := floor_cell + direction
			if not chasm_cells.has(first_chasm_cell):
				continue
			var remaining := depth_limit - 1
			var previous := int(best_remaining_by_cell.get(first_chasm_cell, -1))
			if remaining <= previous:
				continue
			best_remaining_by_cell[first_chasm_cell] = remaining
			queue_cells.append(first_chasm_cell)
			queue_distances.append(1)
			queue_limits.append(depth_limit)

	var cursor := 0
	while cursor < queue_cells.size():
		var cell := queue_cells[cursor]
		var distance := queue_distances[cursor]
		var depth_limit := queue_limits[cursor]
		cursor += 1
		var remaining := depth_limit - distance
		if remaining < int(best_remaining_by_cell.get(cell, -1)):
			continue
		if not chasm_cells.has(cell):
			continue
		set_cell(cell, body_source_id, body_atlas_coord, 0)
		if distance >= depth_limit:
			continue
		var next_distance := distance + 1
		var next_remaining := depth_limit - next_distance
		for direction in CARDINALS:
			var neighbor := cell + direction
			if not chasm_cells.has(neighbor):
				continue
			var previous := int(best_remaining_by_cell.get(neighbor, -1))
			if next_remaining <= previous:
				continue
			best_remaining_by_cell[neighbor] = next_remaining
			queue_cells.append(neighbor)
			queue_distances.append(next_distance)
			queue_limits.append(depth_limit)

	_last_painted_cell_count = get_used_cells().size()
	visible = _last_painted_cell_count > 0


func get_debug_state() -> Dictionary:
	return {
		"visible": visible,
		"painted_cells": _last_painted_cell_count,
		"source_id": body_source_id,
		"min_depth_tiles": mini(min_depth_tiles, max_depth_tiles),
		"max_depth_tiles": maxi(min_depth_tiles, max_depth_tiles),
		"variation_patch_tiles": variation_patch_tiles,
		"seed": _last_seed,
	}


func _depth_limit_for_frontier(frontier_cell: Vector2i, seed: int) -> int:
	var low := mini(min_depth_tiles, max_depth_tiles)
	var high := maxi(min_depth_tiles, max_depth_tiles)
	if low == high:
		return low
	var patch_size := maxi(1, variation_patch_tiles)
	var patch := Vector2i(
		floori(float(frontier_cell.x) / float(patch_size)),
		floori(float(frontier_cell.y) / float(patch_size))
	)
	var span := high - low + 1
	return low + (_stable_hash(patch, seed) % span)


func _stable_hash(cell: Vector2i, seed: int) -> int:
	var value: int = seed
	value ^= cell.x * 73856093
	value ^= cell.y * 19349663
	value ^= (cell.x + cell.y) * 83492791
	return absi(value)
