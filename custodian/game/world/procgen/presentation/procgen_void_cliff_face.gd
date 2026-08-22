class_name ProcgenVoidCliffFace
extends TileMapLayer

const CARDINALS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]
const ATLAS_COORD := Vector2i.ZERO
const FASCIA_SOURCE_IDS := {
	"top": 149,
	"body_01": 150,
	"body_02": 151,
	"body_cracked": 152,
	"bottom": 153,
	"bottom_broken": 154,
}
const BODY_01_CUTOFF := 45
const BODY_02_CUTOFF := 85
const BOTTOM_CUTOFF := 75
const BODY_VARIATION_SALT := 0x2f31a5
const BOTTOM_VARIATION_SALT := 0x5b7d19

@export_group("Presentation")
@export var presentation_enabled := true

@export_group("Depth")
@export_range(1, 12, 1) var min_depth_tiles := 3
@export_range(1, 12, 1) var max_depth_tiles := 8
@export_range(1, 16, 1) var variation_patch_tiles := 4

var _last_seed := 0
var _last_painted_cell_count := 0
var _last_role_counts := _empty_role_counts()
var _last_paint_plan: Dictionary = {}


func configure_from_surface_cells(
	floor_cells: Dictionary,
	chasm_cells: Dictionary,
	seed: int
) -> void:
	clear()
	_last_seed = seed
	_last_painted_cell_count = 0
	_last_role_counts = _empty_role_counts()
	_last_paint_plan.clear()

	if not presentation_enabled:
		visible = false
		return
	if tile_set == null:
		visible = false
		push_warning("[ProcgenVoidCliffFace] Missing TileSet.")
		return
	for role: String in FASCIA_SOURCE_IDS:
		var source_id := int(FASCIA_SOURCE_IDS[role])
		if not tile_set.has_source(source_id):
			visible = false
			push_warning("[ProcgenVoidCliffFace] Missing %s TileSet source %d." % [role, source_id])
			return
	if floor_cells.is_empty() or chasm_cells.is_empty():
		visible = false
		return

	var queue_cells: Array[Vector2i] = []
	var queue_distances: Array[int] = []
	var queue_limits: Array[int] = []
	var best_remaining_by_cell: Dictionary = {}
	var frontier_cells: Dictionary = {}

	for floor_variant: Variant in floor_cells.keys():
		if not floor_variant is Vector2i:
			continue
		var floor_cell := floor_variant as Vector2i
		var depth_limit := _depth_limit_for_frontier(floor_cell, seed)
		for direction in CARDINALS:
			var first_chasm_cell := floor_cell + direction
			if not chasm_cells.has(first_chasm_cell):
				continue
			frontier_cells[first_chasm_cell] = true
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
		_last_paint_plan[cell] = {
			"distance": distance,
			"depth_limit": depth_limit,
		}
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

	for cell_variant: Variant in _last_paint_plan:
		var cell := cell_variant as Vector2i
		var paint_data := _last_paint_plan[cell] as Dictionary
		if frontier_cells.has(cell):
			paint_data["distance"] = 1
		var role := _role_for_cell(
			cell,
			int(paint_data["distance"]),
			int(paint_data["depth_limit"]),
			seed
		)
		paint_data["role"] = role
		var source_id := int(FASCIA_SOURCE_IDS[role])
		set_cell(cell, source_id, ATLAS_COORD, 0)
		_last_role_counts[role] = int(_last_role_counts[role]) + 1

	_last_painted_cell_count = get_used_cells().size()
	visible = _last_painted_cell_count > 0


func get_debug_state() -> Dictionary:
	return {
		"visible": visible,
		"painted_cells": _last_painted_cell_count,
		"source_ids": FASCIA_SOURCE_IDS.duplicate(true),
		"top_count": int(_last_role_counts["top"]),
		"body_01_count": int(_last_role_counts["body_01"]),
		"body_02_count": int(_last_role_counts["body_02"]),
		"body_cracked_count": int(_last_role_counts["body_cracked"]),
		"bottom_count": int(_last_role_counts["bottom"]),
		"bottom_broken_count": int(_last_role_counts["bottom_broken"]),
		"min_depth_tiles": mini(min_depth_tiles, max_depth_tiles),
		"max_depth_tiles": maxi(min_depth_tiles, max_depth_tiles),
		"variation_patch_tiles": variation_patch_tiles,
		"seed": _last_seed,
	}


func get_debug_paint_plan() -> Dictionary:
	return _last_paint_plan.duplicate(true)


func _role_for_cell(cell: Vector2i, distance: int, depth_limit: int, seed: int) -> String:
	if distance == 1:
		return "top"
	if distance >= depth_limit:
		return (
			"bottom"
			if _clustered_roll(cell, seed, BOTTOM_VARIATION_SALT) < BOTTOM_CUTOFF
			else "bottom_broken"
		)
	var body_roll := _clustered_roll(cell, seed, BODY_VARIATION_SALT)
	if body_roll < BODY_01_CUTOFF:
		return "body_01"
	if body_roll < BODY_02_CUTOFF:
		return "body_02"
	return "body_cracked"


func _clustered_roll(cell: Vector2i, seed: int, salt: int) -> int:
	var patch_size := maxi(1, variation_patch_tiles)
	var patch := Vector2i(
		floori(float(cell.x) / float(patch_size)),
		floori(float(cell.y) / float(patch_size))
	)
	var patch_roll := _stable_hash(patch, seed ^ salt) % 100
	var cell_roll := _stable_hash(cell, seed ^ (salt * 3)) % 100
	return (patch_roll * 3 + cell_roll) / 4


func _empty_role_counts() -> Dictionary:
	return {
		"top": 0,
		"body_01": 0,
		"body_02": 0,
		"body_cracked": 0,
		"bottom": 0,
		"bottom_broken": 0,
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
