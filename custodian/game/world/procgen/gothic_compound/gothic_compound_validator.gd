extends RefCounted
class_name GothicCompoundValidator


static func validate(ctx: Object, result) -> bool:
	var validation_errors: Array[String] = []
	_require(result.rect.size != Vector2i.ZERO, validation_errors, "No compound rect.")
	_require(bool(result.flags.get("has_perimeter", false)), validation_errors, "No perimeter.")
	_require(bool(result.flags.get("has_gate", false)), validation_errors, "No gate.")
	_require(bool(result.flags.get("has_command_keep", false)), validation_errors, "No command keep.")
	_require(bool(result.flags.get("has_terminal", false)), validation_errors, "No terminal.")
	_require(bool(result.flags.get("has_approach_road", false)), validation_errors, "No approach road.")
	_require(bool(result.flags.get("has_internal_road", false)), validation_errors, "No internal road.")
	_require(result.placed_walls.size() >= 20, validation_errors, "Too few wall cells.")
	_require(result.placed_resources.size() >= 1, validation_errors, "No resource nodes.")
	_warn(result.placed_decals <= 25, validation_errors,
		"Too many interior decals: %d (expected <= 25)" % result.placed_decals)
	for error in result.placement_errors:
		validation_errors.append(str(error))
	if not validation_errors.is_empty():
		result.errors = validation_errors
		return false
	_validate_required_walkable(ctx, result, validation_errors)
	_validate_gate_passage(ctx, result, validation_errors)
	_validate_path(ctx, result, result.approach_path, "approach", validation_errors)
	_validate_path(ctx, result, result.internal_path, "internal", validation_errors)
	_validate_perimeter(ctx, result, validation_errors)
	result.errors = validation_errors
	return validation_errors.is_empty()


static func _require(condition: bool, errors: Array[String], message: String) -> void:
	if not condition:
		errors.append(message)


static func _warn(condition: bool, errors: Array[String], message: String) -> void:
	if not condition:
		errors.append("WARNING: %s" % message)


static func _validate_required_walkable(ctx: Object, result, errors: Array[String]) -> void:
	for cell in result.required_walkable.keys():
		if ctx.call("is_blocked", cell):
			errors.append("Required path cell is blocked: %s" % str(cell))


static func _validate_gate_passage(ctx: Object, result, errors: Array[String]) -> void:
	if ctx.call("is_blocked", result.gate_cell):
		errors.append("Gate cell is blocked: %s" % str(result.gate_cell))
	if not ctx.call("is_walkable", result.gate_cell):
		errors.append("Gate cell is not walkable: %s" % str(result.gate_cell))


static func _validate_path(ctx: Object, result, path: Array[Vector2i], label: String, errors: Array[String]) -> void:
	for cell in path:
		if ctx.call("is_blocked", cell):
			errors.append("%s path blocked at %s" % [label, str(cell)])
			return
		if not ctx.call("is_walkable", cell):
			errors.append("%s path not walkable at %s" % [label, str(cell)])
			return


static func _validate_perimeter(ctx: Object, result, errors: Array[String]) -> void:
	var rect: Rect2i = result.rect
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x - 1
	var y1 := rect.end.y - 1
	var gate_half := int(maxi(1, int(result.gate_width_tiles)) / 2)
	for x in range(x0, x1 + 1):
		var north := Vector2i(x, y0)
		if not ctx.call("is_blocked", north):
			errors.append("North perimeter gap at %s" % str(north))
			return
		var south := Vector2i(x, y1)
		var is_gate_gap: bool = abs(x - result.gate_cell.x) <= gate_half
		if is_gate_gap:
			if ctx.call("is_blocked", south):
				errors.append("Gate gap is blocked at %s" % str(south))
				return
		elif not ctx.call("is_blocked", south):
			errors.append("South perimeter gap at %s" % str(south))
			return
	for y in range(y0, y1 + 1):
		var west := Vector2i(x0, y)
		var east := Vector2i(x1, y)
		if not ctx.call("is_blocked", west):
			errors.append("West perimeter gap at %s" % str(west))
			return
		if not ctx.call("is_blocked", east):
			errors.append("East perimeter gap at %s" % str(east))
			return
