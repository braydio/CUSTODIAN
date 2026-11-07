extends SceneTree

const PROCGEN_TILEMAP_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const WORLD_INGRESS_SPAWNER_SCRIPT := preload("res://game/world/levels/world_ingress_spawner.gd")
const CELL_SIZE := Vector2(32.0, 32.0)
const TILES: Array[Vector2i] = [
	Vector2i(7, 9),
	Vector2i(0, 0),
	Vector2i(-3, 4),
]
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_layer := TileMapLayer.new()
	floor_layer.position = Vector2(80.0, -64.0)
	root.add_child(floor_layer)
	# Keep the ProcGenTilemap unbound to the runtime tree: this is a focused
	# coordinate regression, not a second generation or gameplay authority.
	var map := PROCGEN_TILEMAP_SCRIPT.new() as ProcGenTilemap
	map.floor_tilemap = floor_layer
	var spawner := WORLD_INGRESS_SPAWNER_SCRIPT.new() as WorldIngressSpawner
	_check_coordinates(map, spawner, floor_layer, "tileset-free")

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	floor_layer.tile_set = tile_set
	_check_coordinates(map, spawner, floor_layer, "tileset-backed")

	spawner.free()
	map.free()
	floor_layer.queue_free()
	if _failures.is_empty():
		print("procgen_tilesetless_ingress_coordinates_smoke: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("procgen_tilesetless_ingress_coordinates_smoke: " + failure)
	quit(1)


func _check_coordinates(
	map: ProcGenTilemap,
	spawner: WorldIngressSpawner,
	floor_layer: TileMapLayer,
	mode: String
) -> void:
	for tile in TILES:
		var expected := floor_layer.to_global(
			Vector2(tile) * CELL_SIZE + CELL_SIZE * 0.5
		)
		var from_map: Vector2 = map.tile_to_global_position(tile)
		var from_spawner: Vector2 = spawner.call("_tile_to_world", map, tile)
		_check(from_map.is_equal_approx(expected), "%s: map tile %s mapped to %s, expected %s" % [
			mode, tile, from_map, expected
		])
		_check(from_spawner.is_equal_approx(expected), "%s: ingress tile %s mapped to %s, expected %s" % [
			mode, tile, from_spawner, expected
		])
		var round_trip: Vector2i = map.call("_global_to_tile", expected)
		_check(round_trip == tile, "%s: global tile %s round-tripped to %s" % [
			mode, tile, round_trip
		])


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
