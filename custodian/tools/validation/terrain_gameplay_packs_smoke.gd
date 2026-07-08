extends SceneTree

const MANIFESTS := {
	"connector": {
		"path": "res://content/tiles/terrain/manifests/connector_pack.game32.json",
		"runtime_dir": "res://content/tiles/terrain/runtime/connector/",
		"label": "Connector",
	},
	"ascent": {
		"path": "res://content/tiles/terrain/manifests/ascent_pack.game32.json",
		"runtime_dir": "res://content/tiles/terrain/runtime/ascent/",
		"label": "Ascent",
	},
	"chasm_bridge": {
		"path": "res://content/tiles/terrain/manifests/chasm_bridge_pack.game32.json",
		"runtime_dir": "res://content/tiles/terrain/runtime/chasm_bridge/",
		"label": "Chasm+Bridge",
	},
}

const TERRAIN_TILE_IDS := preload("res://game/world/procgen/terrain/terrain_tile_ids.gd")

const CHASM_NON_WALKABLE_IDS := [
	"chasm_void_32",
	"chasm_edge_n_32",
	"chasm_edge_s_32",
	"chasm_edge_e_32",
	"chasm_edge_w_32",
	"chasm_outer_corner_ne_32",
	"chasm_outer_corner_nw_32",
	"chasm_outer_corner_se_32",
	"chasm_outer_corner_sw_32",
	"chasm_inner_corner_ne_32",
	"chasm_inner_corner_nw_32",
	"chasm_inner_corner_se_32",
	"chasm_inner_corner_sw_32",
	"collapsed_gap_32",
	"broken_gap_edge_32",
]

const CHECKERBOARD_CHECKPOINTS := [
	Vector2i(0, 0),
	Vector2i(0, 31),
	Vector2i(31, 0),
	Vector2i(31, 31),
	Vector2i(0, 16),
	Vector2i(31, 16),
	Vector2i(16, 0),
	Vector2i(16, 31),
	Vector2i(8, 8),
	Vector2i(24, 24),
	Vector2i(8, 24),
	Vector2i(24, 8),
	Vector2i(16, 16),
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failed := false

	for pack_key in MANIFESTS:
		var info := MANIFESTS[pack_key] as Dictionary
		if not _validate_manifest(info):
			failed = true

	if not _validate_symbolic_ids():
		failed = true

	if not _validate_non_walkable():
		failed = true

	if failed:
		print("[TerrainGameplayPacksSmoke] FAILED: one or more checks did not pass.")
		quit(1)
	else:
		print("[TerrainGameplayPacksSmoke] All checks passed.")
		quit(0)


func _validate_manifest(info: Dictionary) -> bool:
	var ok := true
	var label := info["label"]
	var manifest_path := info["path"]
	var runtime_dir := info["runtime_dir"]

	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		push_error("%s: Could not open manifest: %s" % [label, manifest_path])
		print("  FAIL %s: manifest open error" % [label])
		return false

	var raw := file.get_as_text()
	file.close()

	var j := JSON.new()
	var parse_err := j.parse(raw)
	if parse_err != OK:
		push_error("%s: JSON parse error: %s" % [label, j.get_error_message()])
		print("  FAIL %s: manifest parse error" % [label])
		return false

	var data = j.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("%s: Manifest root is not a Dictionary." % [label])
		print("  FAIL %s: manifest structure" % [label])
		return false

	if data.get("tile_size", -1) != 32:
		push_error("%s: tile_size expected 32, got %s." % [label, str(data.get("tile_size"))])
		ok = false

	var tiles = data.get("tiles", [])
	if typeof(tiles) != TYPE_ARRAY or tiles.is_empty():
		push_error("%s: No tiles array in manifest." % [label])
		print("  FAIL %s: no tiles" % [label])
		return false

	print("  %s: %d tiles in manifest" % [label, tiles.size()])

	for tile in tiles:
		if typeof(tile) != TYPE_DICTIONARY:
			push_error("%s: Tile entry is not a Dictionary." % [label])
			ok = false
			continue

		var tile_id := tile.get("id", "unknown")
		var tile_file := tile.get("file", "")

		if tile_file.is_empty():
			push_error("%s (%s): Missing 'file' field." % [label, tile_id])
			ok = false
			continue

		var full_path := runtime_dir.path_join(tile_file)
		if not FileAccess.file_exists(full_path):
			push_error("%s (%s): Runtime PNG not found: %s" % [label, tile_id, full_path])
			ok = false
			continue

		var img := Image.new()
		var load_err := img.load(full_path)
		if load_err != OK:
			push_error("%s (%s): Image load error %d: %s" % [label, tile_id, load_err, full_path])
			ok = false
			continue

		if img.get_size() != Vector2i(32, 32):
			push_error("%s (%s): Size %dx%d, expected 32x32." % [label, tile_id, img.get_width(), img.get_height()])
			ok = false

		if not _format_has_alpha(img.get_format()):
			push_error("%s (%s): No alpha channel (format %d)." % [label, tile_id, img.get_format()])
			ok = false

		if _has_checkerboard_remnant(img):
			push_warning("%s (%s): Possible checkerboard remnant detected at corner/edge pixel." % [label, tile_id])

	if not ok:
		print("  FAIL %s: tile validation errors found" % [label])
		return false

	print("  PASS %s: all tiles valid" % [label])
	return true


func _format_has_alpha(format: Image.Format) -> bool:
	return format in [
		Image.FORMAT_RGBA8,
		Image.FORMAT_RGBA4444,
		Image.FORMAT_RGBA5551,
		Image.FORMAT_LA8,
		Image.FORMAT_RGBAF,
		Image.FORMAT_RGBAH,
		Image.FORMAT_ETC2_RGBA8,
		Image.FORMAT_BPTC_RGBA,
		Image.FORMAT_ASTC_4x4,
		Image.FORMAT_ASTC_8x8,
	]


func _has_checkerboard_remnant(img: Image) -> bool:
	for pos in CHECKERBOARD_CHECKPOINTS:
		var c := img.get_pixel(pos.x, pos.y)
		if c.a >= 0.99 and c.r > 0.78 and c.g > 0.78 and c.b > 0.78:
			return true
	return false


func _validate_symbolic_ids() -> bool:
	var ok := true
	var const_names := ["CONNECTOR", "ASCENT", "CHASM", "BRIDGE"]
	var helper_names := ["connector", "ascent", "chasm", "bridge"]
	var const_map := TERRAIN_TILE_IDS.get_script_constant_map()

	for name in const_names:
		if const_map.has(name):
			var value = const_map[name]
			if typeof(value) == TYPE_DICTIONARY:
				if value.is_empty():
					push_error("TerrainTileIds.%s is an empty Dictionary." % [name])
					print("  FAIL TerrainTileIds.%s: empty dict" % [name])
					ok = false
				else:
					print("  PASS TerrainTileIds.%s: Dictionary with %d entries" % [name, value.size()])
			else:
				push_error("TerrainTileIds.%s is not a Dictionary (type %d)." % [name, typeof(value)])
				print("  FAIL TerrainTileIds.%s: wrong type" % [name])
				ok = false
		else:
			push_error("TerrainTileIds.%s constant not found." % [name])
			print("  FAIL TerrainTileIds.%s: not found" % [name])
			ok = false

	for name in helper_names:
		if TERRAIN_TILE_IDS.has_method(name):
			print("  PASS TerrainTileIds.%s(): exists" % [name])
		else:
			push_error("TerrainTileIds.%s() method not found." % [name])
			print("  FAIL TerrainTileIds.%s(): not found" % [name])
			ok = false

	if not ok:
		print("  FAIL Symbolic ID resolution checks")
		return false

	print("  PASS Symbolic ID resolution")
	return true


func _validate_non_walkable() -> bool:
	var ok := true
	var fallback := "existing_floor"

	for tile_id in CHASM_NON_WALKABLE_IDS:
		if TERRAIN_TILE_IDS.has_method("connector"):
			var result := TERRAIN_TILE_IDS.connector(tile_id, fallback)
			if result != fallback:
				push_error("Non-walkable '%s' resolved by connector() to walkable '%s'." % [tile_id, result])
				ok = false
		if TERRAIN_TILE_IDS.has_method("ascent"):
			var result := TERRAIN_TILE_IDS.ascent(tile_id, fallback)
			if result != fallback:
				push_error("Non-walkable '%s' resolved by ascent() to walkable '%s'." % [tile_id, result])
				ok = false

	if not ok:
		print("  FAIL Non-walkable chasm tile check")
		return false

	print("  PASS Non-walkable check")
	return true
