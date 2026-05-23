extends RefCounted
class_name GothicCompoundGenerator

const GothicCompoundAssetDefsScript := preload("res://game/world/procgen/gothic_compound/gothic_compound_asset_defs.gd")
const GothicCompoundConfigScript := preload("res://game/world/procgen/gothic_compound/gothic_compound_config.gd")
const GothicCompoundResultScript := preload("res://game/world/procgen/gothic_compound/gothic_compound_result.gd")
const GothicCompoundValidatorScript := preload("res://game/world/procgen/gothic_compound/gothic_compound_validator.gd")

var cfg = null
var rng := RandomNumberGenerator.new()


func _init(config = null) -> void:
	cfg = config if config != null else GothicCompoundConfigScript.new()


func generate(ctx: Object):
	var result = GothicCompoundResultScript.new()
	if not cfg.enabled:
		result.errors.append("Gothic compound generation disabled.")
		return result
	var validator := GothicCompoundValidatorScript.new()
	rng.seed = _compound_seed(int(ctx.get("world_seed")))
	for attempt in range(cfg.max_placement_attempts):
		var rect := _find_candidate_rect(ctx)
		if rect.size == Vector2i.ZERO:
			continue
		result = _generate_at_rect(ctx, rect, false)
		if validator.call("validate", ctx, result):
			result.ok = true
			return result
	result = _generate_at_rect(ctx, _fallback_rect(ctx), true)
	result.used_fallback = true
	result.ok = validator.call("validate", ctx, result)
	if not result.ok:
		result.errors.append("Fallback gothic compound failed validation.")
	return result


func _compound_seed(world_seed: int) -> int:
	return hash("%d:gothic_compound_v1" % world_seed)


func _find_candidate_rect(ctx: Object) -> Rect2i:
	var map_size: Vector2i = ctx.get("map_size")
	var width := rng.randi_range(cfg.min_size.x, cfg.max_size.x)
	var height := rng.randi_range(cfg.min_size.y, cfg.max_size.y)
	var min_x: int = cfg.margin_from_map_edge
	var min_y: int = cfg.margin_from_map_edge
	var max_x: int = map_size.x - width - cfg.margin_from_map_edge
	var max_y: int = map_size.y - height - cfg.margin_from_map_edge
	if max_x <= min_x or max_y <= min_y:
		return Rect2i()
	var rect := Rect2i(
		Vector2i(rng.randi_range(min_x, max_x), rng.randi_range(min_y, max_y)),
		Vector2i(width, height)
	)
	if _rect_has_conflicts(ctx, rect.grow(cfg.outer_margin_fill)):
		return Rect2i()
	return rect


func _fallback_rect(ctx: Object) -> Rect2i:
	var map_size: Vector2i = ctx.get("map_size")
	var size := Vector2i(
		mini(cfg.min_size.x, map_size.x - cfg.margin_from_map_edge * 2),
		mini(cfg.min_size.y, map_size.y - cfg.margin_from_map_edge * 2)
	)
	var pos := Vector2i(
		int((map_size.x - size.x) / 2),
		maxi(cfg.margin_from_map_edge, int((map_size.y - size.y) / 2))
	)
	return Rect2i(pos, size)


func _rect_has_conflicts(ctx: Object, rect: Rect2i) -> bool:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if not _in_map(ctx, cell):
				return true
			if ctx.call("is_reserved", cell):
				return true
	return false


func _generate_at_rect(ctx: Object, rect: Rect2i, fallback: bool):
	var result = GothicCompoundResultScript.new()
	result.rect = rect
	result.used_fallback = fallback
	result.gate_width_tiles = cfg.gate_width_tiles
	_reserve_and_clear(ctx, rect)
	_fill_base_terrain(ctx, rect)
	_build_perimeter(ctx, result, rect)
	_place_gate(ctx, result, rect)
	_define_zones(result, rect)
	_carve_approach_road(ctx, result)
	_place_command_keep(ctx, result, rect)
	_define_keep_plaza_zone(result)
	_place_terminal(ctx, result)
	_carve_internal_road(ctx, result, rect)
	_place_utility_structures(ctx, result, rect)
	_place_defenses(ctx, result, rect)
	_place_exterior_resources(ctx, result, rect)
	_place_scatter_and_decals(ctx, result, rect)
	_place_spawn_markers(ctx, result, rect)
	return result


func _asset(asset_id: String) -> Dictionary:
	return GothicCompoundAssetDefsScript.get_asset(asset_id)


func _reserve_and_clear(ctx: Object, rect: Rect2i) -> void:
	var grown := rect.grow(cfg.outer_margin_fill)
	for y in range(grown.position.y, grown.end.y):
		for x in range(grown.position.x, grown.end.x):
			var cell := Vector2i(x, y)
			if not _in_map(ctx, cell):
				continue
			ctx.call("clear_cell", cell)
			ctx.call("reserve_cell", cell)


func _fill_base_terrain(ctx: Object, rect: Rect2i) -> void:
	var outer := rect.grow(cfg.outer_margin_fill)
	for y in range(outer.position.y, outer.end.y):
		for x in range(outer.position.x, outer.end.x):
			var cell := Vector2i(x, y)
			if not _in_map(ctx, cell):
				continue
			var asset: Dictionary = _asset("terrain_stone_a") if rect.has_point(cell) else _pick_exterior_ground(cell)
			ctx.call("set_floor", cell, asset)
			ctx.call("mark_walkable", cell, true)
	_apply_interior_floor_patches(ctx, rect)
	_apply_exterior_ground_patches(ctx, outer, rect)


func _apply_interior_floor_patches(ctx: Object, rect: Rect2i) -> void:
	var patch_count := 8
	for i in range(patch_count):
		var center := Vector2i(
			rng.randi_range(rect.position.x + 3, rect.end.x - 4),
			rng.randi_range(rect.position.y + 3, rect.end.y - 4)
		)
		var radius := rng.randi_range(2, 4)
		var asset := _asset("terrain_stone_b") if rng.randf() < 0.67 else _asset("terrain_stone_c")
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				var cell := Vector2i(x, y)
				if rect.has_point(cell) and center.distance_to(cell) <= float(radius):
					ctx.call("set_floor", cell, asset)
					ctx.call("mark_walkable", cell, true)


func _apply_exterior_ground_patches(ctx: Object, outer: Rect2i, rect: Rect2i) -> void:
	for i in range(10):
		var center := Vector2i(
			rng.randi_range(outer.position.x, outer.end.x - 1),
			rng.randi_range(outer.position.y, outer.end.y - 1)
		)
		if rect.has_point(center):
			continue
		var radius := rng.randi_range(2, 5)
		var asset := _asset("terrain_ash_b") if rng.randf() < 0.6 else _asset("terrain_rocky_ash")
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				var cell := Vector2i(x, y)
				if outer.has_point(cell) and not rect.has_point(cell) and _in_map(ctx, cell) and center.distance_to(cell) <= float(radius):
					ctx.call("set_floor", cell, asset)
					ctx.call("mark_walkable", cell, true)


func _build_perimeter(ctx: Object, result, rect: Rect2i) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x - 1
	var y1 := rect.end.y - 1
	var gate_center_x := x0 + int(rect.size.x / 2)
	var gate_half := int(cfg.gate_width_tiles / 2)
	for x in range(x0, x1 + 1):
		_place_wall_cell(ctx, result, Vector2i(x, y0), "h")
		if abs(x - gate_center_x) > gate_half:
			_place_wall_cell(ctx, result, Vector2i(x, y1), "h")
	for y in range(y0, y1 + 1):
		_place_wall_cell(ctx, result, Vector2i(x0, y), "v")
		_place_wall_cell(ctx, result, Vector2i(x1, y), "v")
	_place_corner(ctx, result, Vector2i(x0, y0), "nw")
	_place_corner(ctx, result, Vector2i(x1, y0), "ne")
	_place_corner(ctx, result, Vector2i(x0, y1), "sw")
	_place_corner(ctx, result, Vector2i(x1, y1), "se")
	_place_corner_bastions(ctx, result, rect)
	_place_wall_pillars(ctx, result, rect)
	result.flags["has_perimeter"] = true


func _place_wall_cell(ctx: Object, result, cell: Vector2i, orientation: String) -> void:
	var asset := _asset("wall_v") if orientation == "v" else _asset("wall_h")
	if orientation == "h":
		var roll := _stable_noise01(cell, 41)
		if int(cell.x + cell.y) % 11 == 0:
			asset = _asset("wall_h_b")
		elif roll < cfg.wall_damage_chance:
			asset = _asset("wall_h_damaged")
		elif roll < cfg.wall_damage_chance + 0.04:
			asset = _asset("wall_h_broken")
	elif int(cell.x + cell.y) % 9 == 0:
		asset = _asset("wall_pillar")
	ctx.call("set_wall", cell, asset, true)
	ctx.call("mark_blocked", cell, true)
	result.placed_walls.append(cell)


func _place_corner(ctx: Object, result, cell: Vector2i, kind: String) -> void:
	var asset := _asset("wall_pillar")
	match kind:
		"sw":
			asset = _asset("wall_corner_sw")
		"se", "ne":
			asset = _asset("wall_corner_se")
		"nw":
			asset = _asset("wall_corner_spire")
	ctx.call("set_wall", cell, asset, true)
	ctx.call("mark_blocked", cell, true)
	result.placed_walls.append(cell)


func _place_wall_pillars(ctx: Object, result, rect: Rect2i) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x - 1
	var y1 := rect.end.y - 1
	for x in range(x0 + cfg.wall_pillar_stride, x1, cfg.wall_pillar_stride):
		_place_pillar(ctx, result, Vector2i(x, y0))
		if abs(x - (x0 + int(rect.size.x / 2))) > cfg.gate_width_tiles:
			_place_pillar(ctx, result, Vector2i(x, y1))
	for y in range(y0 + cfg.wall_pillar_stride, y1, cfg.wall_pillar_stride):
		_place_pillar(ctx, result, Vector2i(x0, y))
		_place_pillar(ctx, result, Vector2i(x1, y))


func _place_corner_bastions(ctx: Object, result, rect: Rect2i) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x - 1
	var y1 := rect.end.y - 1
	var bastion_cells := [
		Vector2i(x0 + 1, y0 + 1),
		Vector2i(x1 - 1, y0 + 1),
		Vector2i(x0 + 1, y1 - 1),
		Vector2i(x1 - 1, y1 - 1),
	]
	for cell in bastion_cells:
		_place_pillar(ctx, result, cell)


func _place_pillar(ctx: Object, result, cell: Vector2i) -> void:
	ctx.call("set_wall", cell, _asset("wall_pillar"), true)
	ctx.call("mark_blocked", cell, true)
	result.placed_walls.append(cell)


func _place_gate(ctx: Object, result, rect: Rect2i) -> void:
	var gate_center := Vector2i(rect.position.x + int(rect.size.x / 2), rect.end.y - 1)
	result.gate_cell = gate_center
	var gate_half := int(cfg.gate_width_tiles / 2)
	for dx in range(-gate_half, gate_half + 1):
		var cell := gate_center + Vector2i(dx, 0)
		ctx.call("clear_cell", cell)
		ctx.call("set_road", cell, _asset("gate_threshold_open"))
		ctx.call("mark_blocked", cell, false)
		ctx.call("mark_walkable", cell, true)
		result.required_walkable[cell] = true
	ctx.call("spawn_prop_def", gate_center + Vector2i(-3, -4), _asset("gatehouse_open"))
	_place_gate_cluster(ctx, result, gate_center, gate_half)
	result.flags["has_gate"] = true


func _place_gate_cluster(ctx: Object, result, gate_center: Vector2i, gate_half: int) -> void:
	var left_pillar := gate_center + Vector2i(-gate_half - 1, 0)
	var right_pillar := gate_center + Vector2i(gate_half + 1, 0)
	for pillar in [left_pillar, right_pillar]:
		if _in_map(ctx, pillar):
			ctx.call("set_wall", pillar, _asset("wall_pillar"), true)
			ctx.call("mark_blocked", pillar, true)
			result.placed_walls.append(pillar)
	var lamp_cells := [
		gate_center + Vector2i(-gate_half - 2, -2),
		gate_center + Vector2i(gate_half + 2, -2),
	]
	for cell in lamp_cells:
		if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
			_place_prop_checked(ctx, result, cell, _asset("gate_lamp").get("footprint", Vector2i.ONE), _asset("gate_lamp"), true)


func _define_zones(result, rect: Rect2i) -> void:
	result.zones["outer_perimeter"] = rect
	result.zones["inner_yard"] = Rect2i(
		Vector2i(rect.position.x + 8, rect.position.y + 9),
		Vector2i(maxi(4, rect.size.x - 16), maxi(4, rect.size.y - 15))
	)
	result.zones["north_keep_pad"] = Rect2i(
		Vector2i(rect.position.x + int(rect.size.x / 2) - 6, rect.position.y + 3),
		Vector2i(12, 9)
	)
	result.zones["west_utility_pad"] = Rect2i(
		Vector2i(rect.position.x + 7, rect.position.y + int(rect.size.y / 2) - 10),
		Vector2i(8, 8)
	)
	result.zones["east_utility_pad"] = Rect2i(
		Vector2i(rect.end.x - 15, rect.position.y + int(rect.size.y / 2) - 10),
		Vector2i(8, 8)
	)
	result.zones["gate_killzone"] = Rect2i(
		Vector2i(result.gate_cell.x - 7, result.gate_cell.y - 6),
		Vector2i(14, 6)
	)
	result.zones["exterior_ruin_belt"] = rect.grow(cfg.outer_margin_fill)


func _define_keep_plaza_zone(result) -> void:
	if result.command_keep_cell == Vector2i.ZERO:
		return
	result.zones["keep_plaza"] = Rect2i(
		result.command_keep_cell - Vector2i(5, 0),
		Vector2i(11, 5)
	)


func _carve_approach_road(ctx: Object, result) -> void:
	var map_size: Vector2i = ctx.get("map_size")
	var start := Vector2i(result.gate_cell.x, map_size.y - 2)
	var end_cell: Vector2i = result.gate_cell + Vector2i(0, 1)
	var path := _orthogonal_path(start, end_cell, false)
	for cell in path:
		if not _in_map(ctx, cell):
			continue
		ctx.call("set_road", cell, _pick_ns_road())
		ctx.call("mark_walkable", cell, true)
		ctx.call("mark_blocked", cell, false)
	result.approach_path = path
	result.mark_required_path(path)
	if path.size() >= 4:
		result.flags["has_approach_road"] = true


func _carve_internal_road(ctx: Object, result, rect: Rect2i) -> void:
	var yard_center := Vector2i(rect.position.x + int(rect.size.x / 2), rect.position.y + int(rect.size.y / 2))
	var path := _orthogonal_path(result.gate_cell + Vector2i(0, -1), result.command_keep_cell, true)
	for cell in path:
		if not rect.has_point(cell):
			continue
		var asset: Dictionary = _asset("road_cross") if cell == yard_center else _pick_ns_road()
		ctx.call("set_road", cell, asset)
		ctx.call("mark_walkable", cell, true)
		ctx.call("mark_blocked", cell, false)
	_carve_horizontal_road_chunks(ctx, rect.position.x + 7, rect.end.x - 8, yard_center.y)
	_carve_service_paths(ctx, result, rect, yard_center)
	result.internal_path = path
	result.mark_required_path(path)
	result.flags["has_internal_road"] = path.size() >= 4
	var fountain_cell := yard_center + Vector2i(-2, -2)
	if not _is_in_keep_plaza(result, fountain_cell):
		ctx.call("spawn_prop_def", fountain_cell, _asset("fountain"))


func _carve_horizontal_road_chunks(ctx: Object, x0: int, x1: int, y: int) -> void:
	var x := x0
	while x <= x1:
		var remaining := x1 - x + 1
		if remaining >= 4:
			var def := _asset("road_ew_long")
			ctx.call("spawn_prop_def", Vector2i(x, y), def)
			for ox in range(4):
				var cell := Vector2i(x + ox, y)
				ctx.call("mark_walkable", cell, true)
				ctx.call("mark_blocked", cell, false)
			x += 4
		else:
			var cell := Vector2i(x, y)
			ctx.call("set_road", cell, _asset("road_cross"))
			ctx.call("mark_walkable", cell, true)
			ctx.call("mark_blocked", cell, false)
			x += 1


func _carve_service_paths(ctx: Object, result, rect: Rect2i, yard_center: Vector2i) -> void:
	var targets: Array[Vector2i] = []
	var west_pad: Rect2i = result.zones.get("west_utility_pad", Rect2i())
	var east_pad: Rect2i = result.zones.get("east_utility_pad", Rect2i())
	if west_pad.size != Vector2i.ZERO:
		targets.append(Vector2i(west_pad.position.x + int(west_pad.size.x / 2), west_pad.end.y + 1))
	if east_pad.size != Vector2i.ZERO:
		targets.append(Vector2i(east_pad.position.x + int(east_pad.size.x / 2), east_pad.end.y + 1))
	if result.terminal_cell != Vector2i.ZERO:
		targets.append(result.terminal_cell + Vector2i(2, 4))
	for target in targets:
		_carve_optional_service_path(ctx, result, rect, yard_center, target)


func _carve_optional_service_path(ctx: Object, result, rect: Rect2i, start: Vector2i, target: Vector2i) -> void:
	var path := _orthogonal_path(start, target, false)
	var previous := start
	for cell in path:
		if not rect.has_point(cell):
			continue
		if result.required_walkable.has(cell) or _is_in_keep_plaza(result, cell):
			continue
		if ctx.call("is_blocked", cell):
			continue
		var asset := _asset("road_cross") if cell.y == previous.y else _pick_ns_road()
		ctx.call("set_road", cell, asset)
		ctx.call("mark_walkable", cell, true)
		ctx.call("mark_blocked", cell, false)
		previous = cell


func _place_command_keep(ctx: Object, result, rect: Rect2i) -> bool:
	var def := _asset("command_keep")
	var size: Vector2i = def.get("footprint", Vector2i(10, 7))
	var pos := Vector2i(
		rect.position.x + int((rect.size.x - size.x) / 2),
		rect.position.y + 3
	)
	if not _can_place_rect(ctx, result, pos, size, true):
		result.placement_errors.append("command_keep could not fit")
		return false
	ctx.call("spawn_prop_def", pos, def)
	result.command_keep_cell = pos + Vector2i(int(size.x / 2), size.y)
	result.flags["has_command_keep"] = true
	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			result.placed_structures.append(Vector2i(x, y))
	return true


func _place_terminal(ctx: Object, result) -> bool:
	var def := _asset("terminal")
	var size: Vector2i = def.get("footprint", Vector2i(2, 2))
	var terminal_pos: Vector2i = result.command_keep_cell + Vector2i(6, 1)
	if not _can_place_rect(ctx, result, terminal_pos, size, true):
		terminal_pos = result.command_keep_cell + Vector2i(8, 2)
	if not _can_place_rect(ctx, result, terminal_pos, size, true):
		terminal_pos = result.command_keep_cell + Vector2i(-10, 2)
	if not _can_place_rect(ctx, result, terminal_pos, size, true):
		result.placement_errors.append("terminal could not fit")
		return false
	result.terminal_cell = terminal_pos
	ctx.call("spawn_prop_def", terminal_pos, def)
	result.flags["has_terminal"] = true
	for y in range(terminal_pos.y, terminal_pos.y + size.y):
		for x in range(terminal_pos.x, terminal_pos.x + size.x):
			result.placed_structures.append(Vector2i(x, y))
	return true


func _place_utility_structures(ctx: Object, result, rect: Rect2i) -> void:
	var west_pad: Rect2i = result.zones.get("west_utility_pad", Rect2i())
	var east_pad: Rect2i = result.zones.get("east_utility_pad", Rect2i())
	var yard: Rect2i = result.zones.get("inner_yard", Rect2i())
	var candidates := []

	if west_pad.size != Vector2i.ZERO:
		candidates.append({"cell": west_pad.position, "asset": _asset("utility_fan")})

	if east_pad.size != Vector2i.ZERO:
		candidates.append({"cell": east_pad.position, "asset": _asset("machine_house")})

	# Bell frame: anchored to inner yard north edge, centered on x-axis
	if yard.size != Vector2i.ZERO:
		var bell_x := int((yard.position.x + yard.end.x) / 2) - 2
		candidates.append({"cell": Vector2i(bell_x, yard.position.y), "asset": _asset("bell_frame")})

	for entry in candidates:
		var def: Dictionary = entry["asset"]
		_place_prop_checked(ctx, result, entry["cell"], def.get("footprint", Vector2i.ONE), def, bool(def.get("blocks", true)))


func _place_defenses(ctx: Object, result, rect: Rect2i) -> void:
	var gate: Vector2i = result.gate_cell
	var killzone: Rect2i = result.zones.get("gate_killzone", Rect2i())
	var yard: Rect2i = result.zones.get("inner_yard", rect)

	# Gate killzone: sandbags flanking the gate opening
	var sandbag_positions := [
		Vector2i(gate.x - 8, killzone.position.y + 1),
		Vector2i(gate.x + 4, killzone.position.y + 1),
		Vector2i(gate.x - 8, killzone.end.y - 2),
		Vector2i(gate.x + 4, killzone.end.y - 2),
	]
	for cell in sandbag_positions:
		if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
			_place_prop_checked(ctx, result, cell, _asset("sandbag_h").get("footprint", Vector2i.ONE), _asset("sandbag_h"), true)

	# Gate exterior: spike barricades outside gate approach
	var spike_positions := [
		gate + Vector2i(-2, 2),
		gate + Vector2i(1, 2),
	]
	for cell in spike_positions:
		if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
			_place_prop_checked(ctx, result, cell, _asset("spike_h").get("footprint", Vector2i.ONE), _asset("spike_h"), true)

	# Inner yard: stone covers flanking the main path
	var stone_cover_positions := [
		Vector2i(yard.position.x + 3, yard.position.y + 2),
		Vector2i(yard.end.x - 6, yard.position.y + 2),
	]
	for cell in stone_cover_positions:
		if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
			_place_prop_checked(ctx, result, cell, _asset("stone_cover_h").get("footprint", Vector2i.ONE), _asset("stone_cover_h"), true)


func _place_exterior_resources(ctx: Object, result, rect: Rect2i) -> void:
	var positions := [
		Vector2i(rect.position.x - 4, rect.position.y + int(rect.size.y / 2)),
		Vector2i(rect.end.x + 2, rect.position.y + int(rect.size.y / 2)),
		Vector2i(rect.position.x + 4, rect.end.y + 4),
	]
	var assets := [
		_asset("resource_ruin_scrap"),
		_asset("resource_blackwood"),
		_asset("resource_ruin_scrap"),
	]
	for i in range(mini(cfg.exterior_resource_count, positions.size())):
		var pos: Vector2i = positions[i]
		if _in_map(ctx, pos) and not ctx.call("is_blocked", pos):
			ctx.call("spawn_prop_def", pos, assets[i])
			ctx.call("mark_walkable", pos, true)
			result.placed_resources.append(pos)


func _place_scatter_and_decals(ctx: Object, result, rect: Rect2i) -> void:
	_place_fixed_light_pools(ctx, result, rect)
	_place_zone_floor_decals(ctx, result, rect)
	_place_exterior_clusters(ctx, result, rect)


func _place_fixed_light_pools(ctx: Object, result, rect: Rect2i) -> void:
	var anchors := [
		result.gate_cell + Vector2i(-4, -3),
		result.gate_cell + Vector2i(4, -3),
		result.command_keep_cell + Vector2i(-5, 2),
		result.command_keep_cell + Vector2i(5, 2),
		result.terminal_cell + Vector2i(1, 1),
	]
	for cell in anchors:
		if rect.has_point(cell) and not _is_in_keep_plaza(result, cell) and _can_place_decal(ctx, result, cell, Vector2i(3, 3)):
			ctx.call("set_decal_def", cell, _asset("light_pool"))
			result.placed_decals += 1


func _place_zone_floor_decals(ctx: Object, result, rect: Rect2i) -> void:
	var anchors: Array[Dictionary] = [
		{"cell": result.terminal_cell + Vector2i(0, 4), "asset": "grate_square"},
		{"cell": result.terminal_cell + Vector2i(3, 0), "asset": "grate_round"},
	]
	var west_pad: Rect2i = result.zones.get("west_utility_pad", Rect2i())
	var east_pad: Rect2i = result.zones.get("east_utility_pad", Rect2i())
	if west_pad.size != Vector2i.ZERO:
		anchors.append({"cell": west_pad.position + Vector2i(2, west_pad.size.y), "asset": "grate_round"})
	if east_pad.size != Vector2i.ZERO:
		anchors.append({"cell": east_pad.position + Vector2i(2, east_pad.size.y), "asset": "grate_square"})
	anchors.append({"cell": Vector2i(rect.position.x + int(rect.size.x / 2), rect.position.y + int(rect.size.y / 2)), "asset": "floor_sigil"})
	for entry in anchors:
		var cell: Vector2i = entry["cell"]
		if not rect.has_point(cell) or _is_in_keep_plaza(result, cell):
			continue
		var def := _asset(str(entry["asset"]))
		var size: Vector2i = def.get("footprint", Vector2i.ONE)
		if not _can_place_decal(ctx, result, cell, size):
			continue
		ctx.call("set_decal_def", cell, def)
		result.placed_decals += 1


func _can_place_decal(ctx: Object, result, pos: Vector2i, size: Vector2i) -> bool:
	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			var cell := Vector2i(x, y)
			if result.required_walkable.has(cell):
				return false
			if _is_in_keep_plaza(result, cell):
				return false
			if ctx.call("is_blocked", cell):
				return false
	return true


func _place_exterior_clusters(ctx: Object, result, rect: Rect2i) -> void:
	var clusters := [
		{"origin": Vector2i(rect.position.x - 4, rect.position.y + 4), "kind": "ruin"},
		{"origin": Vector2i(rect.end.x + 2, rect.position.y + 5), "kind": "funerary"},
		{"origin": Vector2i(rect.position.x - 5, rect.position.y + int(rect.size.y * 0.62)), "kind": "deadwood"},
		{"origin": Vector2i(rect.end.x + 2, rect.position.y + int(rect.size.y * 0.62)), "kind": "deadwood"},
		{"origin": Vector2i(rect.position.x + 5, rect.end.y + 4), "kind": "roadside"},
		{"origin": Vector2i(rect.end.x - 8, rect.end.y + 4), "kind": "roadside"},
		{"origin": Vector2i(rect.position.x - 5, rect.end.y - 7), "kind": "ruin"},
	]
	for cluster in clusters:
		_emit_exterior_cluster(ctx, result, rect, cluster["origin"], str(cluster["kind"]))


func _emit_exterior_cluster(ctx: Object, result, rect: Rect2i, origin: Vector2i, kind: String) -> void:
	var patterns := {
		"ruin": [
			{"offset": Vector2i(0, 0), "asset": "rubble_m"},
			{"offset": Vector2i(3, 1), "asset": "rubble_s"},
			{"offset": Vector2i(1, 3), "asset": "collapsed_spire"},
		],
		"deadwood": [
			{"offset": Vector2i(0, 0), "asset": "dead_tree"},
			{"offset": Vector2i(4, 3), "asset": "dead_shrub"},
			{"offset": Vector2i(-2, 4), "asset": "rubble_s"},
		],
		"funerary": [
			{"offset": Vector2i(0, 0), "asset": "banner"},
			{"offset": Vector2i(2, 3), "asset": "rubble_s"},
			{"offset": Vector2i(-2, 2), "asset": "dead_shrub"},
		],
		"roadside": [
			{"offset": Vector2i(0, 0), "asset": "rubble_s"},
			{"offset": Vector2i(3, 1), "asset": "rubble_m"},
			{"offset": Vector2i(6, 0), "asset": "dead_shrub"},
		],
	}
	for entry in patterns.get(kind, []):
		var cell: Vector2i = origin + entry["offset"]
		if rect.has_point(cell) or not _in_map(ctx, cell):
			continue
		if _is_near_approach(result, cell, 3.0):
			continue
		var asset := _asset(str(entry["asset"]))
		_place_prop_checked(ctx, result, cell, asset.get("footprint", Vector2i.ONE), asset, bool(asset.get("blocks", false)))


func _place_exterior_scatter(ctx: Object, result, cell: Vector2i) -> void:
	var roll := rng.randf()
	var asset := _asset("rubble_s")
	if roll < 0.22:
		asset = _asset("rubble_s")
	elif roll < 0.40:
		asset = _asset("rubble_m")
	elif roll < 0.52:
		asset = _asset("dead_shrub")
	elif roll < 0.62:
		asset = _asset("dead_tree")
	elif roll < 0.72:
		asset = _asset("collapsed_spire")
	else:
		asset = _asset("banner")
	_place_prop_checked(ctx, result, cell, asset.get("footprint", Vector2i.ONE), asset, bool(asset.get("blocks", false)))


func _is_near_approach(result, cell: Vector2i, radius: float) -> bool:
	for ap in result.approach_path:
		if ap.distance_to(cell) <= radius:
			return true
	return false


func _is_in_keep_plaza(result, cell: Vector2i) -> bool:
	var plaza: Rect2i = result.zones.get("keep_plaza", Rect2i())
	return plaza.size != Vector2i.ZERO and plaza.has_point(cell)


func _place_spawn_markers(ctx: Object, result, rect: Rect2i) -> void:
	var marker_cells := [
		Vector2i(result.gate_cell.x, result.gate_cell.y + 8),
		Vector2i(rect.position.x - 5, rect.position.y + int(rect.size.y / 2)),
		Vector2i(rect.end.x + 4, rect.position.y + int(rect.size.y / 2)),
		Vector2i(rect.position.x + int(rect.size.x / 2), rect.position.y - 5),
	]
	var marker_assets := [
		_asset("marker_spawn_plain"),
		_asset("marker_spawn_amber"),
		_asset("marker_spawn_stone"),
		_asset("marker_spawn_ember"),
	]
	for i in range(mini(cfg.enemy_marker_count, marker_cells.size())):
		var cell: Vector2i = marker_cells[i]
		if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
			ctx.call("spawn_marker", cell, marker_assets[i], "enemy_spawn")
			result.placed_markers.append(cell)


func _place_blocking_structure_checked(ctx: Object, result, pos: Vector2i, size: Vector2i, asset: Dictionary, blocks: bool, label: String) -> bool:
	if not _can_place_rect(ctx, result, pos, size, true):
		result.placement_errors.append("Could not place required structure: %s" % label)
		return false
	var def := asset.duplicate(true)
	def["blocks"] = blocks
	def["footprint"] = size
	ctx.call("spawn_prop_def", pos, def)
	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			var cell := Vector2i(x, y)
			if blocks:
				ctx.call("mark_blocked", cell, true)
			result.placed_structures.append(cell)
	return true


func _place_prop_checked(ctx: Object, result, pos: Vector2i, size: Vector2i, asset: Dictionary, blocks: bool) -> bool:
	if not _can_place_rect(ctx, result, pos, size, true):
		return false
	var def := asset.duplicate(true)
	def["blocks"] = blocks
	def["footprint"] = size
	ctx.call("spawn_prop_def", pos, def)
	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			var cell := Vector2i(x, y)
			result.placed_props.append(cell)
			if blocks:
				ctx.call("mark_blocked", cell, true)
	return true


func _can_place_rect(ctx: Object, result, pos: Vector2i, size: Vector2i, respect_required_path: bool) -> bool:
	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			var cell := Vector2i(x, y)
			if not _in_map(ctx, cell):
				return false
			if respect_required_path and result.required_walkable.has(cell):
				return false
			if ctx.call("is_blocked", cell):
				return false
	return true


func _orthogonal_path(start: Vector2i, end: Vector2i, vertical_first: bool) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := start
	if vertical_first:
		while current.y != end.y:
			path.append(current)
			current.y += _signi(end.y - current.y)
		while current.x != end.x:
			path.append(current)
			current.x += _signi(end.x - current.x)
	else:
		while current.x != end.x:
			path.append(current)
			current.x += _signi(end.x - current.x)
		while current.y != end.y:
			path.append(current)
			current.y += _signi(end.y - current.y)
	path.append(end)
	return path


func _pick_exterior_ground(cell: Vector2i) -> Dictionary:
	var roll := _stable_noise01(cell, 17)
	if roll < 0.45:
		return _asset("terrain_ash_a")
	if roll < 0.70:
		return _asset("terrain_ash_b")
	if roll < 0.84:
		return _asset("terrain_rocky_ash")
	if roll < 0.94:
		return _asset("terrain_ash_roots")
	return _asset("terrain_cracked_rock_b")


func _pick_ns_road() -> Dictionary:
	var roll := rng.randf()
	if roll < 0.60:
		return _asset("road_ns_a")
	if roll < 0.82:
		return _asset("road_ns_b")
	if roll < 0.92:
		return _asset("road_ns_cracked")
	return _asset("road_ns_a")


func _stable_noise01(cell: Vector2i, salt: int) -> float:
	var hashed := hash("%d:%d:%d" % [cell.x, cell.y, salt])
	return float(abs(hashed % 10000)) / 10000.0


func _in_map(ctx: Object, cell: Vector2i) -> bool:
	var map_size: Vector2i = ctx.get("map_size")
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y


func _signi(value: int) -> int:
	if value < 0:
		return -1
	if value > 0:
		return 1
	return 0
