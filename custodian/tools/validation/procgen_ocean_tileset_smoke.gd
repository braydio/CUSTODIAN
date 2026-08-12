extends SceneTree

const TILESET_PATH := "res://content/tiles/tilesets/procgen_world_tileset.tres"
const SOURCE_IDS := [124, 125, 126, 127, 128]
const FRONTAGE_FLOOR_SOURCE_IDS := [129, 130, 131, 132]
const KEEP_CLIFF_PATHS := [
	"res://content/runtime/sundered_keep/terrain/cliffs/cliff_edge_n.png",
	"res://content/runtime/sundered_keep/terrain/cliffs/cliff_edge_e.png",
	"res://content/runtime/sundered_keep/terrain/cliffs/cliff_edge_s.png",
	"res://content/runtime/sundered_keep/terrain/cliffs/cliff_edge_w.png",
]

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
		for source_id in FRONTAGE_FLOOR_SOURCE_IDS:
			_assert(tile_set.has_source(source_id), "missing Sundered Keep frontage floor source %d" % source_id)
			if not tile_set.has_source(source_id):
				continue
			var source := tile_set.get_source(source_id) as TileSetAtlasSource
			_assert(source != null and source.texture != null, "frontage floor source %d has no texture" % source_id)
			if source != null and source.texture != null:
				_assert(source.texture.get_size() == Vector2(32, 32), "frontage floor source %d is not 32x32" % source_id)
		_assert_foam_overlay_alpha(tile_set)
	_assert_keep_cliff_assets()
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


func _assert_foam_overlay_alpha(tile_set: TileSet) -> void:
	for source_id in [125, 126, 127, 128]:
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		var image := source.texture.get_image() if source != null and source.texture != null else null
		_assert(image != null and not image.is_empty(), "foam overlay failed to load from source %d" % source_id)
		if image == null or image.is_empty():
			continue
		_assert(image.get_size() == Vector2i(32, 32), "foam overlay source %d is not 32x32" % source_id)
		var occupied := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				if image.get_pixel(x, y).a > 0.01:
					occupied += 1
		var coverage := float(occupied) / float(image.get_width() * image.get_height())
		_assert(coverage <= 0.30, "foam overlay source %d still reads as a full square (%0.3f)" % [source_id, coverage])


func _assert_keep_cliff_assets() -> void:
	for path in KEEP_CLIFF_PATHS:
		var texture := load(path) as Texture2D
		_assert(texture != null, "missing Sundered Keep coastline texture: %s" % path)
		if texture != null:
			_assert(texture.get_size() == Vector2(64, 96), "Sundered Keep coastline texture is not 64x96: %s" % path)
