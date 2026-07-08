class_name TerrainBallistics
extends RefCounted

const EDGE_NONE := "none"
const EDGE_WALL_HIGH := "wall_high"
const EDGE_LEDGE_FIRE_OVER := "ledge_fire_over"
const EDGE_DROP := "drop"
const EDGE_RAMP := "ramp"
const EDGE_STAIR := "stair"

const TRAVERSAL_WALKABLE := "walkable"
const TRAVERSAL_BLOCKED := "blocked"
const TRAVERSAL_LEDGE := "ledge"
const TRAVERSAL_RAMP := "ramp"
const TRAVERSAL_STAIR := "stair"
const TRAVERSAL_DROP := "drop"

static var debug_enabled := false


static func trace_projectile_tiles(context: Dictionary, from_world: Vector2, to_world: Vector2) -> Dictionary:
	var from_tile := _world_to_tile(context, from_world)
	var to_tile := _world_to_tile(context, to_world)
	var height_by_cell: Dictionary = context.get("height_by_cell", {})
	var source_height := int(height_by_cell.get(from_tile, 0))
	var target_height := int(height_by_cell.get(to_tile, 0))
	var result := {
		"allowed": true,
		"blocked_by": "",
		"blocked_at_tile": to_tile,
		"blocked_at_world": to_world,
		"crossed_edges": [],
		"cover_type": EDGE_NONE,
		"source_height": source_height,
		"target_height": target_height,
		"source_tile": from_tile,
		"target_tile": to_tile,
	}
	var tiles := trace_tiles(from_tile, to_tile)
	if tiles.size() <= 1:
		return result

	var direction_label := _height_direction(source_height, target_height)
	for index in range(1, tiles.size()):
		var previous: Vector2i = tiles[index - 1]
		var current: Vector2i = tiles[index]
		var profile := classify_boundary(context, previous, current)
		var edge := {
			"from_tile": previous,
			"to_tile": current,
			"profile": profile,
		}
		(result["crossed_edges"] as Array).append(edge)
		if _boundary_allows(context, profile, source_height, target_height):
			continue
		result["allowed"] = false
		result["blocked_by"] = profile
		result["cover_type"] = profile
		result["blocked_at_tile"] = current
		result["blocked_at_world"] = _tile_to_world(context, current)
		if debug_enabled:
			print("[TerrainBallistics] blocked from=%s to=%s by=%s direction=%s at=%s" % [
				str(from_tile), str(to_tile), profile, direction_label, str(current),
			])
		return result

	if debug_enabled and source_height > target_height:
		for edge_variant in result["crossed_edges"]:
			var crossed_edge: Dictionary = edge_variant
			if String(crossed_edge.get("profile", "")) == EDGE_LEDGE_FIRE_OVER:
				print("[TerrainBallistics] allowed high_to_low ledge from=%s to=%s" % [str(from_tile), str(to_tile)])
				break
	return result


static func trace_tiles(from_tile: Vector2i, to_tile: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [from_tile]
	if from_tile == to_tile:
		return cells

	var dx: int = to_tile.x - from_tile.x
	var dy: int = to_tile.y - from_tile.y
	var nx: int = absi(dx)
	var ny: int = absi(dy)
	var sign_x: int = 1 if dx > 0 else -1
	var sign_y: int = 1 if dy > 0 else -1
	var current: Vector2i = from_tile
	var ix: int = 0
	var iy: int = 0
	while ix < nx or iy < ny:
		var x_progress: int = (1 + 2 * ix) * ny
		var y_progress: int = (1 + 2 * iy) * nx
		if x_progress == y_progress:
			current += Vector2i(sign_x, sign_y)
			ix += 1
			iy += 1
		elif x_progress < y_progress:
			current.x += sign_x
			ix += 1
		else:
			current.y += sign_y
			iy += 1
		cells.append(current)
	return cells


static func classify_boundary(context: Dictionary, from_tile: Vector2i, to_tile: Vector2i) -> String:
	var custom_classifier: Callable = context.get("classify_edge_profile", Callable())
	if custom_classifier.is_valid():
		return String(custom_classifier.call(from_tile, to_tile))

	var delta := to_tile - from_tile
	if abs(delta.x) + abs(delta.y) > 1:
		var horizontal := from_tile + Vector2i(signi(delta.x), 0)
		var vertical := from_tile + Vector2i(0, signi(delta.y))
		return _strongest_profile([
			classify_boundary(context, from_tile, horizontal),
			classify_boundary(context, from_tile, vertical),
		])

	var explicit := _explicit_edge_profile(context, from_tile, to_tile)
	if explicit != EDGE_NONE:
		return explicit

	var hard_blocker: Callable = context.get("is_hard_projectile_blocker", Callable())
	if hard_blocker.is_valid() and bool(hard_blocker.call(to_tile)):
		return EDGE_WALL_HIGH

	var traversal_by_cell: Dictionary = context.get("traversal_by_cell", {})
	var terrain_type_by_cell: Dictionary = context.get("terrain_type_by_cell", {})
	var from_traversal := String(traversal_by_cell.get(from_tile, TRAVERSAL_WALKABLE))
	var to_traversal := String(traversal_by_cell.get(to_tile, TRAVERSAL_WALKABLE))
	var from_terrain: Variant = terrain_type_by_cell.get(from_tile, "")
	var to_terrain: Variant = terrain_type_by_cell.get(to_tile, "")

	if from_traversal == TRAVERSAL_BLOCKED or to_traversal == TRAVERSAL_BLOCKED \
			or _is_hard_wall_type(from_terrain) or _is_hard_wall_type(to_terrain):
		return EDGE_WALL_HIGH
	if (from_traversal == TRAVERSAL_DROP or to_traversal == TRAVERSAL_DROP) \
			and not _is_crossing_surface(context, from_tile, to_tile):
		return EDGE_DROP
	if from_traversal == TRAVERSAL_LEDGE or to_traversal == TRAVERSAL_LEDGE:
		return EDGE_LEDGE_FIRE_OVER
	if from_traversal == TRAVERSAL_RAMP or to_traversal == TRAVERSAL_RAMP:
		return EDGE_RAMP
	if from_traversal == TRAVERSAL_STAIR or to_traversal == TRAVERSAL_STAIR:
		return EDGE_STAIR

	var height_by_cell: Dictionary = context.get("height_by_cell", {})
	var from_height := int(height_by_cell.get(from_tile, 0))
	var to_height := int(height_by_cell.get(to_tile, 0))
	if abs(from_height - to_height) == 1:
		return EDGE_LEDGE_FIRE_OVER
	return EDGE_NONE


static func summarize_context(context: Dictionary) -> Dictionary:
	var height_counts := {}
	for value in (context.get("height_by_cell", {}) as Dictionary).values():
		var key := str(int(value))
		height_counts[key] = int(height_counts.get(key, 0)) + 1
	var traversal_counts := {}
	for value in (context.get("traversal_by_cell", {}) as Dictionary).values():
		var key := String(value)
		traversal_counts[key] = int(traversal_counts.get(key, 0)) + 1
	var edge_counts := {}
	for profile_variant in (context.get("edge_profile_by_cell", {}) as Dictionary).values():
		if not (profile_variant is Dictionary):
			continue
		for value in (profile_variant as Dictionary).values():
			var key := String(value)
			edge_counts[key] = int(edge_counts.get(key, 0)) + 1
	return {
		"cell_count": (context.get("traversal_by_cell", {}) as Dictionary).size(),
		"height_count_by_value": height_counts,
		"traversal_count_by_value": traversal_counts,
		"edge_profile_count_by_value": edge_counts,
	}


static func _boundary_allows(
	context: Dictionary,
	profile: String,
	source_height: int,
	target_height: int
) -> bool:
	if profile == EDGE_WALL_HIGH or profile == EDGE_DROP:
		return false
	if profile == EDGE_NONE or profile == EDGE_RAMP or profile == EDGE_STAIR:
		return true
	if profile != EDGE_LEDGE_FIRE_OVER:
		return true
	if source_height > target_height:
		return true
	if source_height < target_height:
		return false
	return source_height > 0 and target_height > 0 \
			or bool(context.get("allow_same_height_ledge_fire", false))


static func _explicit_edge_profile(context: Dictionary, from_tile: Vector2i, to_tile: Vector2i) -> String:
	var edge_profiles: Dictionary = context.get("edge_profile_by_cell", {})
	var profiles: Variant = edge_profiles.get(from_tile, {})
	if not (profiles is Dictionary):
		return EDGE_NONE
	var direction_name := _direction_name(to_tile - from_tile)
	if direction_name.is_empty():
		return EDGE_NONE
	return String((profiles as Dictionary).get(direction_name, EDGE_NONE))


static func _direction_name(delta: Vector2i) -> String:
	if delta == Vector2i.UP:
		return "north"
	if delta == Vector2i.DOWN:
		return "south"
	if delta == Vector2i.RIGHT:
		return "east"
	if delta == Vector2i.LEFT:
		return "west"
	return ""


static func _strongest_profile(profiles: Array) -> String:
	for candidate in [EDGE_WALL_HIGH, EDGE_DROP, EDGE_LEDGE_FIRE_OVER, EDGE_RAMP, EDGE_STAIR]:
		if profiles.has(candidate):
			return candidate
	return EDGE_NONE


static func _world_to_tile(context: Dictionary, world: Vector2) -> Vector2i:
	var converter: Callable = context.get("world_to_tile", Callable())
	if converter.is_valid():
		return converter.call(world) as Vector2i
	var tile_size := _tile_size_vector(context.get("tile_size", 16))
	var world_origin: Vector2 = context.get("world_origin", Vector2.ZERO)
	var map_origin: Vector2i = context.get("map_origin", Vector2i.ZERO)
	return map_origin + Vector2i(
		floori((world.x - world_origin.x) / maxf(tile_size.x, 1.0)),
		floori((world.y - world_origin.y) / maxf(tile_size.y, 1.0))
	)


static func _tile_to_world(context: Dictionary, tile: Vector2i) -> Vector2:
	var converter: Callable = context.get("tile_to_world", Callable())
	if converter.is_valid():
		return converter.call(tile) as Vector2
	var tile_size := _tile_size_vector(context.get("tile_size", 16))
	var world_origin: Vector2 = context.get("world_origin", Vector2.ZERO)
	var map_origin: Vector2i = context.get("map_origin", Vector2i.ZERO)
	var relative := tile - map_origin
	return world_origin + Vector2(relative) * tile_size + tile_size * 0.5


static func _tile_size_vector(value: Variant) -> Vector2:
	if value is Vector2i:
		return Vector2(value)
	if value is Vector2:
		return value
	var scalar := float(value)
	return Vector2(scalar, scalar)


static func _height_direction(source_height: int, target_height: int) -> String:
	if source_height > target_height:
		return "high_to_low"
	if source_height < target_height:
		return "low_to_high"
	return "same_height"


static func _is_hard_wall_type(value: Variant) -> bool:
	var label := str(value).to_lower()
	return label.contains("mountain_wall") or label.contains("hard_wall") or label == "wall_high"


static func _is_crossing_surface(context: Dictionary, from_tile: Vector2i, to_tile: Vector2i) -> bool:
	var traversal_by_cell: Dictionary = context.get("traversal_by_cell", {})
	for tile in [from_tile, to_tile]:
		var traversal := String(traversal_by_cell.get(tile, ""))
		if traversal == TRAVERSAL_RAMP or traversal == TRAVERSAL_STAIR:
			return true
		var tile_id := String((context.get("tile_by_cell", {}) as Dictionary).get(tile, "")).to_lower()
		if tile_id.contains("bridge"):
			return true
	return false
