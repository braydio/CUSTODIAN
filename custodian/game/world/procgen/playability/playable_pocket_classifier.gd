extends RefCounted
class_name PlayablePocketClassifier


func classify(
	reserved_regions: Array[Dictionary],
	floor_cells: Dictionary
) -> Dictionary:
	var pockets: Array[Dictionary] = []
	var protected_cells: Dictionary = {}
	var critical_clearance_cells: Dictionary = {}
	var encounter_clearance_cells: Dictionary = {}
	var encounter_spawn_cells: Array[Vector2i] = []
	var required_centers: Array[Vector2i] = []

	for region in reserved_regions:
		var rect: Rect2i = region.get("rect", Rect2i())
		var center: Vector2i = region.get("center", rect.get_center())
		var source_kind := String(region.get("kind", region.get("shape_kind", "pocket")))
		var role := _role_for_kind(source_kind)
		var required := bool(region.get("required", false))
		var clearance_radius := _clearance_radius_for_role(role)
		var pocket := region.duplicate(true)
		pocket["role"] = role
		pocket["clearance_radius_tiles"] = clearance_radius
		pocket["encounter_eligible"] = role == "combat_pocket"
		pockets.append(pocket)

		if required or role == "combat_pocket":
			required_centers.append(center)

		for cell in _rect_floor_cells(rect, floor_cells):
			protected_cells[cell] = true

		if clearance_radius > 0:
			_add_disc(
				critical_clearance_cells,
				center,
				clearance_radius,
				floor_cells
			)

		if role == "combat_pocket":
			var clear_rect := _central_clear_rect(rect)
			pocket["clear_rect"] = clear_rect
			for cell in _rect_floor_cells(clear_rect, floor_cells):
				encounter_clearance_cells[cell] = true
			encounter_spawn_cells.append_array(
				_encounter_edge_cells(rect, clear_rect, floor_cells)
			)

	return {
		"pockets": pockets,
		"protected_cells": protected_cells,
		"critical_clearance_cells": critical_clearance_cells,
		"encounter_clearance_cells": encounter_clearance_cells,
		"encounter_spawn_cells": encounter_spawn_cells,
		"required_centers": required_centers,
	}


func _role_for_kind(kind: String) -> String:
	match kind:
		"spawn":
			return "arrival_pad"
		"exit_gate":
			return "exit_pad"
		"safe_pocket":
			return "safe_pocket"
		"resource_pocket":
			return "resource_pocket"
		"vista":
			return "vista"
		"story_room":
			return "story_insertion"
		"faction_site", "ascent_beat":
			return "combat_pocket"
		"branch", "shortcut":
			return "branch"
		_:
			return "travel_corridor"


func _clearance_radius_for_role(role: String) -> int:
	match role:
		"arrival_pad":
			return 7
		"exit_pad":
			return 6
		"safe_pocket":
			return 6
		"resource_pocket", "story_insertion":
			return 4
		_:
			return 0


func _central_clear_rect(rect: Rect2i) -> Rect2i:
	if rect.size.x <= 2 or rect.size.y <= 2:
		return rect
	var target_size := Vector2i(
		maxi(1, int(floor(float(rect.size.x) * 0.84))),
		maxi(1, int(floor(float(rect.size.y) * 0.84)))
	)
	return Rect2i(rect.get_center() - target_size / 2, target_size)


func _rect_floor_cells(
	rect: Rect2i,
	floor_cells: Dictionary
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if floor_cells.has(cell):
				result.append(cell)
	return result


func _add_disc(
	target: Dictionary,
	center: Vector2i,
	radius: int,
	floor_cells: Dictionary
) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var offset := Vector2i(x, y)
			if offset.length_squared() > radius * radius:
				continue
			var cell := center + offset
			if floor_cells.has(cell):
				target[cell] = true


func _encounter_edge_cells(
	rect: Rect2i,
	clear_rect: Rect2i,
	floor_cells: Dictionary
) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(rect.position.x + 2, rect.get_center().y),
		Vector2i(rect.end.x - 3, rect.get_center().y),
		Vector2i(rect.get_center().x, rect.position.y + 2),
		Vector2i(rect.get_center().x, rect.end.y - 3),
	]
	for cell in offsets:
		if rect.has_point(cell) \
				and not clear_rect.has_point(cell) \
				and floor_cells.has(cell):
			candidates.append(cell)
	return candidates
