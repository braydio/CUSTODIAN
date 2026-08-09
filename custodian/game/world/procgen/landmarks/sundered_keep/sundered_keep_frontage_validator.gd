extends RefCounted
class_name SunderedKeepFrontageValidator

const MIN_ROUTE_WIDTH := 7
const CARDINALS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]


func validate(
	frontage: Dictionary,
	base_main_route_cells: Array[Vector2i] = []
) -> Dictionary:
	var errors: Array[String] = []
	if frontage.is_empty():
		errors.append("frontage result is empty")
		return _result(errors)
	if str(frontage.get("landmark_id", "")) != "sundered_keep_frontage":
		errors.append("landmark_id is not sundered_keep_frontage")
	var centerline: Array[Vector2i] = _vector2i_array(
		frontage.get("route_centerline", [])
	)
	var floor_cells: Dictionary = frontage.get("floor_cells", {})
	var route_cells: Dictionary = frontage.get("primary_route_cells", {})
	var hard_clearance: Dictionary = frontage.get(
		"hard_clearance_cells",
		{}
	)
	var gate: Variant = frontage.get("gate_anchor")
	if centerline.size() < 8:
		errors.append("frontage centerline is too short")
	if not gate is Vector2i or not floor_cells.has(gate):
		errors.append("gate anchor is not generated floor")
	if not centerline.is_empty() \
			and not base_main_route_cells.has(centerline[0]):
		errors.append("frontage does not attach to the existing main route")
	for cell in centerline:
		if not route_cells.has(cell) or not hard_clearance.has(cell):
			errors.append("centerline cell lacks protected route authority")
			break
	var minimum_width := _minimum_route_width(centerline, floor_cells)
	if minimum_width < MIN_ROUTE_WIDTH:
		errors.append(
			"minimum route width %d is below %d"
			% [minimum_width, MIN_ROUTE_WIDTH]
		)
	if not centerline.is_empty() and gate is Vector2i:
		var reachable := _collect_reachable(centerline[0], floor_cells)
		if not reachable.has(gate):
			errors.append("gate anchor is unreachable from frontage entry")
		if not _is_reverse_connected(centerline, reachable):
			errors.append("frontage is not reverse traversable")
		var commit_cells: Dictionary = frontage.get("vista_commit_cells", {})
		if commit_cells.is_empty():
			errors.append("frontage has no vista commit-line authority")
		else:
			var without_commit := floor_cells.duplicate()
			for cell in commit_cells.keys():
				without_commit.erase(cell)
			var bypass_reachable := _collect_reachable(
				centerline[0],
				without_commit
			)
			if bypass_reachable.has(gate):
				errors.append(
					"frontage has a terminal bypass around the vista commit line"
				)
	var apron: Dictionary = frontage.get("terminal_apron_cells", {})
	if apron.is_empty() or (gate is Vector2i and not apron.has(gate)):
		errors.append("terminal apron is missing generated gate authority")
	var camera_anchors: Dictionary = frontage.get(
		"camera_semantic_anchors",
		{}
	)
	if not _camera_anchors_are_ordered(centerline, camera_anchors):
		errors.append("camera semantic anchors are not ordered")
	var summary: Dictionary = frontage.get("debug_summary", {})
	if bool(summary.get("rectangular_authored_footprint", true)):
		errors.append("frontage reports rectangular authored authority")
	if bool(summary.get("special_room_owned", true)):
		errors.append("frontage reports special-room ownership")
	if bool(summary.get("route_master_ground", true)):
		errors.append("frontage reports route-master ground authority")
	return _result(errors, minimum_width)


func stable_fingerprint(frontage: Dictionary) -> String:
	var centerline: Array[Vector2i] = _vector2i_array(
		frontage.get("route_centerline", [])
	)
	var values := PackedStringArray()
	values.append(str(frontage.get("grammar_id", "")))
	values.append(str(frontage.get("gate_anchor", Vector2i.ZERO)))
	values.append(str(frontage.get("overlook_anchor", Vector2i.ZERO)))
	for cell in centerline:
		values.append("%d,%d" % [cell.x, cell.y])
	values.append(
		"floor=%d" % (
			frontage.get("floor_cells", {}) as Dictionary
		).size()
	)
	values.append(
		"cliff=%d" % (
			frontage.get("cliff_cells", {}) as Dictionary
		).size()
	)
	values.append(
		"commit=%d" % (
			frontage.get("vista_commit_cells", {}) as Dictionary
		).size()
	)
	return "%08x" % abs("|".join(values).hash())


func _result(
	errors: Array[String],
	minimum_width: int = 0
) -> Dictionary:
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"minimum_route_width": minimum_width,
	}


func _minimum_route_width(
	centerline: Array[Vector2i],
	floor_cells: Dictionary
) -> int:
	if centerline.is_empty():
		return 0
	var minimum_width := 999999
	for index in range(centerline.size()):
		var cell := centerline[index]
		var tangent := Vector2i.UP
		if index + 1 < centerline.size():
			tangent = centerline[index + 1] - cell
		elif index > 0:
			tangent = cell - centerline[index - 1]
		var negative := Vector2i.LEFT
		var positive := Vector2i.RIGHT
		if absi(tangent.x) > absi(tangent.y):
			negative = Vector2i.UP
			positive = Vector2i.DOWN
		var width := _axis_width(cell, negative, positive, floor_cells)
		minimum_width = mini(minimum_width, width)
	return minimum_width


func _axis_width(
	center: Vector2i,
	negative: Vector2i,
	positive: Vector2i,
	floor_cells: Dictionary
) -> int:
	if not floor_cells.has(center):
		return 0
	var width := 1
	var cursor := center + negative
	while floor_cells.has(cursor):
		width += 1
		cursor += negative
	cursor = center + positive
	while floor_cells.has(cursor):
		width += 1
		cursor += positive
	return width


func _collect_reachable(
	start: Vector2i,
	floor_cells: Dictionary
) -> Dictionary:
	var result := {}
	if not floor_cells.has(start):
		return result
	var queue: Array[Vector2i] = [start]
	result[start] = true
	while not queue.is_empty():
		var cell := queue.pop_front() as Vector2i
		for direction in CARDINALS:
			var neighbor := cell + direction
			if result.has(neighbor) or not floor_cells.has(neighbor):
				continue
			result[neighbor] = true
			queue.append(neighbor)
	return result


func _is_reverse_connected(
	centerline: Array[Vector2i],
	reachable: Dictionary
) -> bool:
	for cell in centerline:
		if not reachable.has(cell):
			return false
	return true


func _camera_anchors_are_ordered(
	centerline: Array[Vector2i],
	anchors: Dictionary
) -> bool:
	var ordered_names := [
		"frontage_entry",
		"first_influence_start",
		"first_reveal_apex",
		"first_return_complete",
		"frontage_reveal_start",
		"frontage_apex",
		"gameplay_return",
		"gate_threshold",
	]
	var previous_index := -1
	for anchor_name in ordered_names:
		var anchor: Variant = anchors.get(anchor_name)
		if not anchor is Vector2i:
			return false
		var index := centerline.find(anchor as Vector2i)
		if index < previous_index or index < 0:
			return false
		previous_index = index
	return true


func _vector2i_array(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not value is Array:
		return result
	for item in value:
		if item is Vector2i:
			result.append(item as Vector2i)
	return result
