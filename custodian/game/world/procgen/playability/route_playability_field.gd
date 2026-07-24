extends RefCounted
class_name RoutePlayabilityField

const ROUTE_DISTANCE_FIELD_SCRIPT := preload(
	"res://game/world/procgen/playability/route_distance_field.gd"
)
const POCKET_CLASSIFIER_SCRIPT := preload(
	"res://game/world/procgen/playability/playable_pocket_classifier.gd"
)

const HARD_CLEARANCE_RADIUS := 2
const SHOULDER_RADIUS := 5
const SPARSE_RADIUS := 9
const MIN_POST_DRESSING_ROUTE_WIDTH := 7

const NEIGHBORS_8: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]


func build(
	floor_cells: Dictionary,
	main_route_cells: Array[Vector2i],
	main_route_centerline_cells: Array[Vector2i] = [],
	reserved_regions: Array[Dictionary] = []
) -> Dictionary:
	var distance_builder := ROUTE_DISTANCE_FIELD_SCRIPT.new()
	var route_distance: Dictionary = distance_builder.build(
		floor_cells,
		main_route_cells
	)
	var centerline_sources := main_route_centerline_cells
	if centerline_sources.is_empty():
		centerline_sources = main_route_cells
	var centerline_distance: Dictionary = distance_builder.build(
		floor_cells,
		centerline_sources
	)
	var pocket_result: Dictionary = POCKET_CLASSIFIER_SCRIPT.new().classify(
		reserved_regions,
		floor_cells
	)

	var route_lookup: Dictionary = {}
	var hard_clearance: Dictionary = {}
	var shoulder: Dictionary = {}
	var sparse: Dictionary = {}
	var deep: Dictionary = {}

	for cell in main_route_cells:
		if floor_cells.has(cell):
			route_lookup[cell] = true

	for cell_variant in floor_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var distance := int(route_distance.get(cell, SPARSE_RADIUS + 1))
		if distance <= HARD_CLEARANCE_RADIUS:
			hard_clearance[cell] = true
		elif distance <= SHOULDER_RADIUS:
			shoulder[cell] = true
		elif distance <= SPARSE_RADIUS:
			sparse[cell] = true
		else:
			deep[cell] = true

	for source in [
		pocket_result.get("critical_clearance_cells", {}),
		pocket_result.get("encounter_clearance_cells", {}),
	]:
		for cell_variant in (source as Dictionary).keys():
			var cell := cell_variant as Vector2i
			hard_clearance[cell] = true
			shoulder.erase(cell)
			sparse.erase(cell)
			deep.erase(cell)

	return {
		"schema": "custodian.procgen_playability.v1",
		"route_cells": route_lookup,
		"route_distance": route_distance,
		"centerline_distance": centerline_distance,
		"hard_clearance_cells": hard_clearance,
		"shoulder_cells": shoulder,
		"sparse_dressing_cells": sparse,
		"deep_dressing_cells": deep,
		"pockets": pocket_result.get("pockets", []),
		"protected_cells": pocket_result.get("protected_cells", {}),
		"encounter_clearance_cells": pocket_result.get(
			"encounter_clearance_cells",
			{}
		),
		"encounter_spawn_cells": pocket_result.get(
			"encounter_spawn_cells",
			[]
		),
		"required_centers": pocket_result.get("required_centers", []),
	}


func cleanup_floor(
	floor_cells: Dictionary,
	protected_cells: Dictionary,
	map_size: Vector2i
) -> Dictionary:
	var cleaned := floor_cells.duplicate(true)
	var removed := 0
	var filled := 0
	var remove_cells: Array[Vector2i] = []

	for cell_variant in floor_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if protected_cells.has(cell):
			continue
		if _neighbor_count(cell, floor_cells) < 3:
			remove_cells.append(cell)

	for cell in remove_cells:
		cleaned.erase(cell)
		removed += 1

	for y in range(1, map_size.y - 1):
		for x in range(1, map_size.x - 1):
			var cell := Vector2i(x, y)
			if cleaned.has(cell):
				continue
			if _neighbor_count(cell, cleaned) >= 6:
				cleaned[cell] = true
				filled += 1

	return {
		"floor_cells": cleaned,
		"removed_tendrils": removed,
		"filled_holes": filled,
	}


func audit(
	floor_cells: Dictionary,
	blocker_cells: Dictionary,
	main_route_cells: Array[Vector2i],
	main_route_centerline_cells: Array[Vector2i],
	required_cells: Array[Vector2i]
) -> Dictionary:
	var violations: Array[Dictionary] = []
	var navigable: Dictionary = {}
	for cell_variant in floor_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if not blocker_cells.has(cell):
			navigable[cell] = true

	for cell in main_route_cells:
		if blocker_cells.has(cell):
			violations.append({
				"kind": "route_blocked",
				"cell": cell,
			})

	var minimum_width := 999999
	var centerline_lookup: Dictionary = {}
	for cell in main_route_centerline_cells:
		centerline_lookup[cell] = true
	for center in main_route_centerline_cells:
		var width := _route_width_at(
			center,
			navigable,
			centerline_lookup
		)
		minimum_width = mini(minimum_width, width)
		if width < MIN_POST_DRESSING_ROUTE_WIDTH:
			violations.append({
				"kind": "route_width",
				"cell": center,
				"width": width,
			})

	if main_route_centerline_cells.is_empty():
		minimum_width = 0

	var reachable: Dictionary = {}
	if not required_cells.is_empty():
		reachable = _collect_reachable(required_cells[0], navigable)
		for cell in required_cells:
			if not reachable.has(cell):
				violations.append({
					"kind": "required_unreachable",
					"cell": cell,
				})

	return {
		"schema": "custodian.procgen_playability.audit.v1",
		"ok": violations.is_empty(),
		"minimum_route_width": minimum_width,
		"required_cell_count": required_cells.size(),
		"reachable_required_count": required_cells.size() - _count_kind(
			violations,
			"required_unreachable"
		),
		"violations": violations,
	}


func _route_width_at(
	center: Vector2i,
	navigable: Dictionary,
	centerline: Dictionary
) -> int:
	var has_horizontal := centerline.has(center + Vector2i.LEFT) \
			or centerline.has(center + Vector2i.RIGHT)
	var has_vertical := centerline.has(center + Vector2i.UP) \
			or centerline.has(center + Vector2i.DOWN)
	if has_horizontal and not has_vertical:
		return _axis_width(
			center,
			Vector2i.UP,
			Vector2i.DOWN,
			navigable
		)
	if has_vertical and not has_horizontal:
		return _axis_width(
			center,
			Vector2i.LEFT,
			Vector2i.RIGHT,
			navigable
		)
	var horizontal_width := _axis_width(
		center,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		navigable
	)
	var vertical_width := _axis_width(
		center,
		Vector2i.UP,
		Vector2i.DOWN,
		navigable
	)
	return mini(horizontal_width, vertical_width)


func _axis_width(
	center: Vector2i,
	negative: Vector2i,
	positive: Vector2i,
	navigable: Dictionary
) -> int:
	if not navigable.has(center):
		return 0
	var width := 1
	for direction_variant in [negative, positive]:
		var direction := direction_variant as Vector2i
		var cursor: Vector2i = center + direction
		while navigable.has(cursor) and cursor.distance_to(center) <= 12.0:
			width += 1
			cursor += direction
	return width


func _collect_reachable(
	start: Vector2i,
	navigable: Dictionary
) -> Dictionary:
	var visited: Dictionary = {}
	if not navigable.has(start):
		return visited
	var frontier: Array[Vector2i] = [start]
	visited[start] = true
	var cursor := 0
	while cursor < frontier.size():
		var cell: Vector2i = frontier[cursor]
		cursor += 1
		for direction_variant in [
			Vector2i.LEFT,
			Vector2i.RIGHT,
			Vector2i.UP,
			Vector2i.DOWN,
		]:
			var direction := direction_variant as Vector2i
			var neighbor: Vector2i = cell + direction
			if visited.has(neighbor) or not navigable.has(neighbor):
				continue
			visited[neighbor] = true
			frontier.append(neighbor)
	return visited


func _neighbor_count(cell: Vector2i, cells: Dictionary) -> int:
	var count := 0
	for offset in NEIGHBORS_8:
		if cells.has(cell + offset):
			count += 1
	return count


func _count_kind(rows: Array[Dictionary], kind: String) -> int:
	var count := 0
	for row in rows:
		if String(row.get("kind", "")) == kind:
			count += 1
	return count
