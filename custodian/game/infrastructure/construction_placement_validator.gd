class_name ConstructionPlacementValidator
extends RefCounted

const VALID := &"valid"


func snap_world_origin(world_position: Vector2, definition: StructureDefinition) -> Vector2:
	var grid := maxi(1, definition.grid_size if definition != null else 32)
	return Vector2(
		roundf(world_position.x / float(grid)) * grid,
		roundf(world_position.y / float(grid)) * grid
	)


func get_rotated_footprint_tiles(
	definition: StructureDefinition,
	rotation_degrees: int
) -> Vector2i:
	if definition == null:
		return Vector2i.ZERO
	var normalized := posmod(rotation_degrees, 360)
	if normalized == 90 or normalized == 270:
		return Vector2i(definition.footprint_tiles.y, definition.footprint_tiles.x)
	return definition.footprint_tiles


func get_footprint_world_rect(
	snapped_position: Vector2,
	definition: StructureDefinition,
	rotation_degrees: int
) -> Rect2:
	var tiles := get_rotated_footprint_tiles(definition, rotation_degrees)
	var grid := maxi(1, definition.grid_size if definition != null else 32)
	return Rect2(snapped_position, Vector2(tiles * grid))


func validate(
	world_position: Vector2,
	definition: StructureDefinition,
	rotation_degrees: int,
	tree: SceneTree,
	floor_tilemap: TileMapLayer = null,
	zones: Array[Node] = [],
	operator: Node2D = null
) -> Dictionary:
	if definition == null:
		return _result(false, &"unsupported_zone", "INVALID STRUCTURE DEFINITION")
	var origin := snap_world_origin(world_position, definition)
	var world_rect := get_footprint_world_rect(origin, definition, rotation_degrees)
	var compatible_zone: ConstructionZone2D = null
	var inside_any_zone := false
	for zone_node in zones:
		var zone := zone_node as ConstructionZone2D
		if zone == null or not zone.enabled:
			continue
		if zone.contains_world_rect(world_rect):
			inside_any_zone = true
			if zone.supports_definition(definition):
				compatible_zone = zone
				break
	if compatible_zone == null:
		return _result(
			false,
			&"unsupported_zone" if inside_any_zone else &"outside_construction_zone",
			"UNSUPPORTED CONSTRUCTION ZONE" if inside_any_zone else "OUTSIDE CONSTRUCTION ZONE",
			world_rect, origin
		)
	if floor_tilemap != null and not _has_complete_floor(world_rect, definition.grid_size, floor_tilemap):
		return _result(false, &"invalid_floor", "INVALID FLOOR", world_rect, origin, compatible_zone)
	if operator != null and _point_distance_to_rect(operator.global_position, world_rect) < definition.operator_clearance:
		return _result(false, &"operator_clearance", "OPERATOR CLEARANCE REQUIRED", world_rect, origin, compatible_zone)
	if tree != null:
		var occupancy := _find_occupancy(tree, world_rect, definition.placement_clearance, operator)
		if occupancy == &"reserved_path":
			return _result(false, &"reserved_path", "RESERVED CONSTRUCTION PATH", world_rect, origin, compatible_zone)
		if occupancy == &"occupied":
			return _result(false, &"occupied", "FOOTPRINT BLOCKED", world_rect, origin, compatible_zone)
	return _result(true, VALID, "VALID CONSTRUCTION SITE", world_rect, origin, compatible_zone)


func _has_complete_floor(world_rect: Rect2, _grid_size: int, floor_tilemap: TileMapLayer) -> bool:
	var first := floor_tilemap.local_to_map(floor_tilemap.to_local(world_rect.position + Vector2(0.001, 0.001)))
	var last := floor_tilemap.local_to_map(floor_tilemap.to_local(world_rect.end - Vector2(0.001, 0.001)))
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			if floor_tilemap.get_cell_tile_data(Vector2i(x, y)) == null:
				return false
	return true


func _find_occupancy(
	tree: SceneTree,
	world_rect: Rect2,
	clearance: float,
	operator: Node2D
) -> StringName:
	var seen := {}
	for group_name in [&"structure", &"infrastructure_structure", &"turret", &"construction_blocker", &"construction_reserved_path", &"enemy", &"enemies"]:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node) or node == operator or seen.has(node):
				continue
			seen[node] = true
			if not node is Node2D:
				continue
			var node_rect := _get_node_world_rect(node as Node2D, clearance)
			if world_rect.intersects(node_rect):
				return &"reserved_path" if node.is_in_group("construction_reserved_path") else &"occupied"
	return &""


func _get_node_world_rect(node: Node2D, clearance: float) -> Rect2:
	if node.has_method("get_construction_footprint_world_rect"):
		return node.call("get_construction_footprint_world_rect") as Rect2
	for child in node.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var shape := (child as CollisionShape2D).shape as RectangleShape2D
			var center := (child as CollisionShape2D).global_position
			return Rect2(center - shape.size * 0.5, shape.size).grow(clearance)
	return Rect2(node.global_position - Vector2.ONE * clearance, Vector2.ONE * clearance * 2.0)


func _point_distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var nearest := Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
	return point.distance_to(nearest)


func _result(
	valid: bool,
	reason: StringName,
	message: String,
	world_rect: Rect2 = Rect2(),
	origin: Vector2 = Vector2.ZERO,
	zone: ConstructionZone2D = null
) -> Dictionary:
	return {
		"valid": valid,
		"reason": reason,
		"message": message,
		"world_rect": world_rect,
		"grid_origin": origin,
		"zone_id": zone.zone_id if zone != null else &"",
	}
