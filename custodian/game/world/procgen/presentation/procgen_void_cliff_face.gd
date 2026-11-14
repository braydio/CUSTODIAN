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
@export_range(1, 12, 1) var min_depth_tiles := 4
@export_range(1, 12, 1) var max_depth_tiles := 8
@export_range(1, 12, 1) var typical_max_depth_tiles := 6
@export_range(0, 100, 1) var deep_section_percent := 12
@export_range(1, 16, 1) var variation_patch_tiles := 4

@export_group("Pocket Suppression")
@export_range(0, 256, 1) var min_enclosed_chasm_cells_for_fascia := 24

var _last_seed := 0
var _last_frontier_cell_count := 0
var _last_painted_cell_count := 0
var _last_suppressed_pocket_count := 0
var _last_wall_lip_frontier_count := 0
var _last_wall_excluded_cell_count := 0
var _last_role_counts := _empty_role_counts()
var _last_paint_plan: Dictionary = {}


func configure_from_surface_cells(
	floor_cells: Dictionary,
	chasm_cells: Dictionary,
	seed: int,
	wall_cells: Dictionary = {}
) -> void:
	clear()
	_last_seed = seed
	_last_frontier_cell_count = 0
	_last_painted_cell_count = 0
	_last_suppressed_pocket_count = 0
	_last_wall_lip_frontier_count = 0
	_last_wall_excluded_cell_count = 0
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

	var eligible_chasm_cells := _classify_fascia_chasm_cells(chasm_cells)
	var frontier_directions: Dictionary = {}

	for floor_variant: Variant in floor_cells.keys():
		if not floor_variant is Vector2i:
			continue
		var floor_cell := floor_variant as Vector2i
		for direction in CARDINALS:
			var first_chasm_cell := floor_cell + direction
			if not eligible_chasm_cells.has(first_chasm_cell):
				continue
			var directions: Array = frontier_directions.get(first_chasm_cell, [])
			directions.append(direction)
			frontier_directions[first_chasm_cell] = directions

	var frontier_cells: Array[Vector2i] = []
	for frontier_variant: Variant in frontier_directions.keys():
		frontier_cells.append(frontier_variant as Vector2i)
	frontier_cells.sort()
	_last_frontier_cell_count = frontier_cells.size()

	# A generated wall may validly occupy the first semantic chasm cell. In that
	# case the wall owns the visible lip and the fascia begins at the first clear
	# chasm cell beyond the contiguous wall run.
	for frontier_cell: Vector2i in frontier_cells:
		var outward_direction := _resolve_outward_direction(
			frontier_cell,
			frontier_directions[frontier_cell] as Array,
			seed
		)
		var visible_start := frontier_cell
		var wall_lip_depth := 0
		while eligible_chasm_cells.has(visible_start) and wall_cells.has(visible_start):
			wall_lip_depth += 1
			_last_wall_excluded_cell_count += 1
			visible_start += outward_direction
		if wall_lip_depth > 0:
			_last_wall_lip_frontier_count += 1
		if not eligible_chasm_cells.has(visible_start):
			continue
		# Do not carry one ray through a second, independently exposed frontier.
		if wall_lip_depth > 0 and frontier_directions.has(visible_start):
			continue
		var depth_limit := _depth_limit_for_frontier(frontier_cell, seed)
		var candidate := {
			"distance": 1,
			"depth_limit": depth_limit,
			"frontier_cell": frontier_cell,
			"visible_start_cell": visible_start,
			"outward_direction": outward_direction,
			"wall_lip_depth": wall_lip_depth,
			"wall_backed": wall_lip_depth > 0,
		}
		var existing := _last_paint_plan.get(visible_start, {}) as Dictionary
		if existing.is_empty() or (bool(existing.get("wall_backed", false)) and wall_lip_depth == 0):
			_last_paint_plan[visible_start] = candidate

	var visible_frontiers: Array[Vector2i] = []
	for cell_variant: Variant in _last_paint_plan.keys():
		visible_frontiers.append(cell_variant as Vector2i)
	visible_frontiers.sort()
	for visible_start: Vector2i in visible_frontiers:
		var frontier_plan := _last_paint_plan[visible_start] as Dictionary
		var frontier_cell := frontier_plan["frontier_cell"] as Vector2i
		var outward_direction := frontier_plan["outward_direction"] as Vector2i
		var depth_limit := int(frontier_plan["depth_limit"])
		var terminal_cell := visible_start
		for distance in range(2, depth_limit + 1):
			var cell := visible_start + outward_direction * (distance - 1)
			if not eligible_chasm_cells.has(cell):
				break
			if wall_cells.has(cell):
				break
			if frontier_directions.has(cell):
				break
			var previous_data := _last_paint_plan.get(cell, {}) as Dictionary
			if not previous_data.is_empty() and int(previous_data["distance"]) <= distance:
				break
			_last_paint_plan[cell] = {
				"distance": distance,
				"depth_limit": depth_limit,
				"frontier_cell": frontier_cell,
				"visible_start_cell": visible_start,
				"outward_direction": outward_direction,
				"wall_lip_depth": int(frontier_plan["wall_lip_depth"]),
				"wall_backed": bool(frontier_plan["wall_backed"]),
			}
			terminal_cell = cell
		if terminal_cell != visible_start:
			var terminal_plan := _last_paint_plan[terminal_cell] as Dictionary
			if terminal_plan["frontier_cell"] == frontier_cell:
				terminal_plan["depth_limit"] = int(terminal_plan["distance"])

	for cell_variant: Variant in _last_paint_plan:
		var cell := cell_variant as Vector2i
		var paint_data := _last_paint_plan[cell] as Dictionary
		var role := _role_for_cell(
			cell,
			int(paint_data["distance"]),
			int(paint_data["depth_limit"]),
			seed,
			bool(paint_data["wall_backed"])
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
		"frontier_cells": _last_frontier_cell_count,
		"painted_cells": _last_painted_cell_count,
		"cells_per_frontier": (
			float(_last_painted_cell_count) / float(_last_frontier_cell_count)
			if _last_frontier_cell_count > 0 else 0.0
		),
		"suppressed_pocket_count": _last_suppressed_pocket_count,
		"wall_lip_frontier_count": _last_wall_lip_frontier_count,
		"wall_excluded_cell_count": _last_wall_excluded_cell_count,
		"source_ids": FASCIA_SOURCE_IDS.duplicate(true),
		"top_count": int(_last_role_counts["top"]),
		"body_01_count": int(_last_role_counts["body_01"]),
		"body_02_count": int(_last_role_counts["body_02"]),
		"body_cracked_count": int(_last_role_counts["body_cracked"]),
		"bottom_count": int(_last_role_counts["bottom"]),
		"bottom_broken_count": int(_last_role_counts["bottom_broken"]),
		"min_depth_tiles": mini(min_depth_tiles, max_depth_tiles),
		"max_depth_tiles": maxi(min_depth_tiles, max_depth_tiles),
		"typical_max_depth_tiles": typical_max_depth_tiles,
		"deep_section_percent": deep_section_percent,
		"min_enclosed_chasm_cells_for_fascia": min_enclosed_chasm_cells_for_fascia,
		"variation_patch_tiles": variation_patch_tiles,
		"seed": _last_seed,
	}


func get_debug_paint_plan() -> Dictionary:
	return _last_paint_plan.duplicate(true)


func _role_for_cell(
		cell: Vector2i,
		distance: int,
		depth_limit: int,
		seed: int,
		wall_backed: bool
) -> String:
	if distance == 1 and not wall_backed:
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
	var typical_high := clampi(typical_max_depth_tiles, low, high)
	var patch_size := maxi(1, variation_patch_tiles)
	var patch := Vector2i(
		floori(float(frontier_cell.x) / float(patch_size)),
		floori(float(frontier_cell.y) / float(patch_size))
	)
	var roll := _stable_hash(patch, seed) % 100
	if high > typical_high and roll < deep_section_percent:
		var deep_span := high - typical_high
		return typical_high + 1 + (_stable_hash(patch, seed ^ 0x4d31f7) % deep_span)
	var typical_span := typical_high - low + 1
	return low + (_stable_hash(patch, seed) % typical_span)


func _resolve_outward_direction(frontier_cell: Vector2i, directions: Array, seed: int) -> Vector2i:
	var summed := Vector2i.ZERO
	for direction_variant: Variant in directions:
		if direction_variant is Vector2i:
			summed += direction_variant as Vector2i
	if absi(summed.x) > absi(summed.y):
		return Vector2i(signi(summed.x), 0)
	if absi(summed.y) > absi(summed.x):
		return Vector2i(0, signi(summed.y))
	var candidates: Array[Vector2i] = []
	for direction_variant: Variant in directions:
		if direction_variant is Vector2i and direction_variant not in candidates:
			candidates.append(direction_variant as Vector2i)
	if candidates.is_empty():
		return Vector2i.DOWN
	candidates.sort()
	return candidates[_stable_hash(frontier_cell, seed ^ 0x713ab9) % candidates.size()]


func _classify_fascia_chasm_cells(chasm_cells: Dictionary) -> Dictionary:
	var eligible: Dictionary = {}
	var visited: Dictionary = {}
	var bounds := _cell_bounds(chasm_cells)
	for cell_variant: Variant in chasm_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var start := cell_variant as Vector2i
		if visited.has(start):
			continue
		var component: Array[Vector2i] = []
		var queue: Array[Vector2i] = [start]
		visited[start] = true
		var touches_exterior := false
		var cursor := 0
		while cursor < queue.size():
			var cell := queue[cursor]
			cursor += 1
			component.append(cell)
			touches_exterior = touches_exterior or _touches_bounds(cell, bounds)
			for direction: Vector2i in CARDINALS:
				var neighbor := cell + direction
				if chasm_cells.has(neighbor) and not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
		var qualifies := (
			touches_exterior
			or component.size() >= min_enclosed_chasm_cells_for_fascia
			or min_enclosed_chasm_cells_for_fascia <= 0
		)
		if qualifies:
			for cell: Vector2i in component:
				eligible[cell] = true
		else:
			_last_suppressed_pocket_count += 1
	return eligible


func _cell_bounds(cells: Dictionary) -> Rect2i:
	var first := true
	var minimum := Vector2i.ZERO
	var maximum := Vector2i.ZERO
	for cell_variant: Variant in cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if first:
			minimum = cell
			maximum = cell
			first = false
		else:
			minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
			maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _touches_bounds(cell: Vector2i, bounds: Rect2i) -> bool:
	var end := bounds.end - Vector2i.ONE
	return cell.x == bounds.position.x or cell.y == bounds.position.y or cell.x == end.x or cell.y == end.y


func _stable_hash(cell: Vector2i, seed: int) -> int:
	var value: int = seed
	value ^= cell.x * 73856093
	value ^= cell.y * 19349663
	value ^= (cell.x + cell.y) * 83492791
	return absi(value)
