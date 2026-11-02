extends StaticBody2D
class_name ProcGenRuntimeWallChunk

var procgen_tilemap: ProcGenTilemap = null
var chunk_position := Vector2i.ZERO
var destructible := true
var _tile_shapes: Dictionary = {}


func setup(owner_tilemap: ProcGenTilemap, wall_chunk: Vector2i, allow_destruction: bool = true) -> void:
	procgen_tilemap = owner_tilemap
	chunk_position = wall_chunk
	destructible = allow_destruction
	if destructible:
		add_to_group("destructible_wall")
	add_to_group("runtime_wall_chunk")


func add_wall_tile(tile: Vector2i, shape_position: Vector2, collision_size: Vector2) -> void:
	if _tile_shapes.has(tile):
		return
	var shape := CollisionShape2D.new()
	shape.name = "Tile_%d_%d" % [tile.x, tile.y]
	shape.position = shape_position
	shape.set_meta("wall_tile", tile)
	var rectangle := RectangleShape2D.new()
	rectangle.size = collision_size
	shape.shape = rectangle
	add_child(shape)
	_tile_shapes[tile] = shape


func remove_wall_tile(tile: Vector2i) -> void:
	var shape := _tile_shapes.get(tile, null) as CollisionShape2D
	if shape == null:
		return
	_tile_shapes.erase(tile)
	shape.set_deferred("disabled", true)
	shape.queue_free()


func has_wall_tile(tile: Vector2i) -> bool:
	return _tile_shapes.has(tile)


func is_empty() -> bool:
	return _tile_shapes.is_empty()


func get_wall_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile_variant in _tile_shapes.keys():
		if tile_variant is Vector2i:
			tiles.append(tile_variant as Vector2i)
	return tiles


func get_wall_shape_count() -> int:
	return _tile_shapes.size()


func resolve_wall_tile_at_global(impact_global_position: Vector2) -> Vector2i:
	var impact_local := to_local(impact_global_position)
	var best_tile := Vector2i(999999, 999999)
	var best_distance_sq := INF
	for tile_variant in _tile_shapes.keys():
		var tile := tile_variant as Vector2i
		var shape := _tile_shapes[tile] as CollisionShape2D
		if shape == null or not is_instance_valid(shape):
			continue
		var distance_sq := impact_local.distance_squared_to(shape.position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_tile = tile
	return best_tile


func receive_projectile_hit(amount: float, attacker_team: String, impact_global_position := Vector2(INF, INF)) -> Dictionary:
	if not destructible:
		return {"blocked": true, "destroyed": false, "reason": "indestructible_wall"}
	if procgen_tilemap == null or not is_finite(impact_global_position.x) or not is_finite(impact_global_position.y):
		return {"blocked": true, "destroyed": false, "reason": "missing_wall_impact_position"}
	var tile := resolve_wall_tile_at_global(impact_global_position)
	if tile == Vector2i(999999, 999999):
		return {"blocked": true, "destroyed": false, "reason": "unresolved_wall_tile"}
	return procgen_tilemap.damage_wall_tile(tile, amount, attacker_team)


func take_damage_at_global(amount: float, impact_global_position: Vector2, attacker_team: String = "") -> Dictionary:
	return receive_projectile_hit(amount, attacker_team, impact_global_position)
