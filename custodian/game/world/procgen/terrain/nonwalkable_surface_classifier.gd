extends RefCounted
class_name NonwalkableSurfaceClassifier

const SURFACE_CHASM := &"chasm"
const SURFACE_OCEAN := &"ocean"

const CARDINALS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]


func classify(
	map_size: Vector2i,
	floor_cells: Dictionary,
	surface_claims: Array[Dictionary]
) -> Dictionary:
	var kind_by_cell: Dictionary = {}
	var chasm_cells: Dictionary = {}
	var ocean_cells: Dictionary = {}
	var claim_cells_by_id: Dictionary = {}
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			if floor_cells.has(cell):
				continue
			kind_by_cell[cell] = SURFACE_CHASM
			chasm_cells[cell] = true

	for claim in surface_claims:
		if StringName(claim.get("kind", &"")) != SURFACE_OCEAN:
			continue
		var claim_id := StringName(claim.get("id", &""))
		if claim_id == &"":
			continue
		var bounds_variant: Variant = claim.get(
			"bounds", Rect2i(Vector2i.ZERO, map_size)
		)
		if not bounds_variant is Rect2i:
			continue
		var bounds := (bounds_variant as Rect2i).intersection(
			Rect2i(Vector2i.ZERO, map_size)
		)
		if not bounds.has_area():
			continue
		var claimed := _flood_claim(map_size, floor_cells, bounds, claim)
		claim_cells_by_id[claim_id] = claimed
		for cell_variant in claimed.keys():
			var cell := cell_variant as Vector2i
			if floor_cells.has(cell):
				continue
			kind_by_cell[cell] = SURFACE_OCEAN
			ocean_cells[cell] = true
			chasm_cells.erase(cell)

	return {
		"kind_by_cell": kind_by_cell,
		"chasm_cells": chasm_cells,
		"ocean_cells": ocean_cells,
		"claim_cells_by_id": claim_cells_by_id,
		"summary": {
			"chasm_cells": chasm_cells.size(),
			"ocean_cells": ocean_cells.size(),
			"surface_cells": kind_by_cell.size(),
			"claim_count": claim_cells_by_id.size(),
		},
	}


func _flood_claim(
	map_size: Vector2i,
	floor_cells: Dictionary,
	bounds: Rect2i,
	claim: Dictionary
) -> Dictionary:
	var result: Dictionary = {}
	var queued: Dictionary = {}
	var pending: Array[Vector2i] = []
	var seed_edge := StringName(claim.get("seed_edge", &"north"))
	match seed_edge:
		&"north":
			for x in range(bounds.position.x, bounds.end.x):
				_queue_seed(Vector2i(x, bounds.position.y), floor_cells, queued, pending)
		&"south":
			for x in range(bounds.position.x, bounds.end.x):
				_queue_seed(Vector2i(x, bounds.end.y - 1), floor_cells, queued, pending)
		&"west":
			for y in range(bounds.position.y, bounds.end.y):
				_queue_seed(Vector2i(bounds.position.x, y), floor_cells, queued, pending)
		&"east":
			for y in range(bounds.position.y, bounds.end.y):
				_queue_seed(Vector2i(bounds.end.x - 1, y), floor_cells, queued, pending)
		_:
			return result

	var map_bounds := Rect2i(Vector2i.ZERO, map_size)
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		if result.has(cell) or not bounds.has_point(cell) \
				or not map_bounds.has_point(cell) or floor_cells.has(cell):
			continue
		result[cell] = true
		for direction in CARDINALS:
			var neighbor := cell + direction
			if queued.has(neighbor) or not bounds.has_point(neighbor) \
					or floor_cells.has(neighbor):
				continue
			queued[neighbor] = true
			pending.append(neighbor)
	return result


func _queue_seed(
	cell: Vector2i,
	floor_cells: Dictionary,
	queued: Dictionary,
	pending: Array[Vector2i]
) -> void:
	if floor_cells.has(cell) or queued.has(cell):
		return
	queued[cell] = true
	pending.append(cell)
