extends SceneTree

const TILESET_PATH := "res://content/tiles/tilesets/procgen_world_tileset.tres"
const SOURCE_IDS := [124, 125, 126, 127, 128]

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tile_set := load(TILESET_PATH) as TileSet
	_assert(tile_set != null, "procgen world TileSet did not load")
	if tile_set != null:
		for source_id in SOURCE_IDS:
			_assert(tile_set.has_source(source_id), "missing ocean source %d" % source_id)
			if not tile_set.has_source(source_id):
				continue
			var source := tile_set.get_source(source_id) as TileSetAtlasSource
			_assert(source != null, "ocean source %d is not an atlas" % source_id)
			if source == null:
				continue
			_assert(source.texture != null, "ocean source %d texture is missing" % source_id)
			if source.texture != null:
				_assert(source.texture.get_size() == Vector2(32, 32), "ocean source %d is not 32x32" % source_id)
			_assert(source.get_tiles_count() == 1, "ocean source %d is not one static tile" % source_id)
			_assert(source.has_tile(Vector2i.ZERO), "ocean source %d lacks atlas 0,0" % source_id)
			var tile_data := source.get_tile_data(Vector2i.ZERO, 0)
			_assert(tile_data != null, "ocean source %d lacks base tile data" % source_id)
			if tile_data == null:
				continue
			for layer in range(tile_set.get_physics_layers_count()):
				_assert(tile_data.get_collision_polygons_count(layer) == 0, "ocean source %d owns collision" % source_id)
			for layer in range(tile_set.get_navigation_layers_count()):
				_assert(tile_data.get_navigation_polygon(layer) == null, "ocean source %d owns navigation" % source_id)
	if _errors.is_empty():
		print("[ProcgenOceanTilesetSmoke] PASS ids=124-128 size=32x32 frames=1")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenOceanTilesetSmoke] %s" % error)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
