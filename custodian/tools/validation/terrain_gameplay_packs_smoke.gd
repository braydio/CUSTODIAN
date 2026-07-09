extends SceneTree

const MANIFESTS := {
	"connector": {
		"path": "res://content/tiles/terrain/manifests/connector_pack.game32.json",
		"runtime_dir": "res://content/tiles/terrain/runtime/connector/",
		"label": "Connector",
		"source_id_start": 60,
		"source_id_count": 18,
		"symbolic_const": "CONNECTOR",
		"symbolic_helper": "connector",
	},
	"ascent": {
		"path": "res://content/tiles/terrain/manifests/ascent_pack.game32.json",
		"runtime_dir": "res://content/tiles/terrain/runtime/ascent/",
		"label": "Ascent",
		"source_id_start": 80,
		"source_id_count": 20,
		"symbolic_const": "ASCENT",
		"symbolic_helper": "ascent",
	},
	"chasm_bridge": {
		"path": "res://content/tiles/terrain/manifests/chasm_bridge_pack.game32.json",
		"runtime_dir": "res://content/tiles/terrain/runtime/chasm_bridge/",
		"label": "Chasm+Bridge",
		"source_id_start": 100,
		"source_id_count": 24,
		"symbolic_const": "",
		"symbolic_helper": "",
	},
}

const TERRAIN_TILE_IDS := preload("res://game/world/procgen/terrain/terrain_tile_ids.gd")
const PROCGEN_TILEMAP := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const TILESET_PATH := "res://content/tiles/tilesets/procgen_world_tileset.tres"
const REGISTRATION_REPORT_PATH := "res://../reports/terrain_pack_ingest/terrain_gameplay_tileset_sources.json"
var tile_id_helper := TERRAIN_TILE_IDS.new()

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
	var manifests := {}

	for pack_key in MANIFESTS:
		var info := MANIFESTS[pack_key] as Dictionary
		var manifest := _load_manifest(info)
		if manifest.is_empty():
			failed = true
			continue
		manifests[pack_key] = manifest
		if not _validate_manifest(info, manifest):
			failed = true

	if not _validate_symbolic_ids(manifests):
		failed = true

	if not _validate_non_walkable():
		failed = true

	if not _validate_tileset_registration(manifests):
		failed = true

	if not _validate_runtime_visual_map(manifests):
		failed = true

	if not _validate_registration_report(manifests):
		failed = true

	if failed:
		print("[TerrainGameplayPacksSmoke] FAILED: one or more checks did not pass.")
		quit(1)
	else:
		print("[TerrainGameplayPacksSmoke] All checks passed.")
		quit(0)


func _load_manifest(info: Dictionary) -> Dictionary:
	var label: String = String(info["label"])
	var manifest_path: String = String(info["path"])

	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		push_error("%s: Could not open manifest: %s" % [label, manifest_path])
		print("  FAIL %s: manifest open error" % [label])
		return {}

	var raw := file.get_as_text()
	file.close()

	var j := JSON.new()
	var parse_err := j.parse(raw)
	if parse_err != OK:
		push_error("%s: JSON parse error: %s" % [label, j.get_error_message()])
		print("  FAIL %s: manifest parse error" % [label])
		return {}

	var data = j.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("%s: Manifest root is not a Dictionary." % [label])
		print("  FAIL %s: manifest structure" % [label])
		return {}

	return data


func _validate_manifest(info: Dictionary, data: Dictionary) -> bool:
	var ok := true
	var label: String = String(info["label"])
	var runtime_dir: String = String(info["runtime_dir"])

	if data.get("tile_size", -1) != 32:
		push_error("%s: tile_size expected 32, got %s." % [label, str(data.get("tile_size"))])
		ok = false

	var tiles: Variant = data.get("tiles", [])
	if typeof(tiles) != TYPE_ARRAY or tiles.is_empty():
		push_error("%s: No tiles array in manifest." % [label])
		print("  FAIL %s: no tiles" % [label])
		return false

	print("  %s: %d tiles in manifest" % [label, tiles.size()])
	if tiles.size() != int(info["source_id_count"]):
		push_error("%s: manifest tile count=%d, expected %d." % [label, tiles.size(), int(info["source_id_count"])])
		ok = false

	for tile in tiles:
		if typeof(tile) != TYPE_DICTIONARY:
			push_error("%s: Tile entry is not a Dictionary." % [label])
			ok = false
			continue

		var tile_id: String = String(tile.get("id", "unknown"))
		var tile_file: String = String(tile.get("file", ""))

		if tile_file.is_empty():
			push_error("%s (%s): Missing 'file' field." % [label, tile_id])
			ok = false
			continue

		var full_path: String = runtime_dir.path_join(tile_file)
		if not FileAccess.file_exists(full_path):
			push_error("%s (%s): Runtime PNG not found: %s" % [label, tile_id, full_path])
			ok = false
			continue

		var img := Image.new()
		var load_err := img.load(_global_path(full_path))
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


func _validate_symbolic_ids(manifests: Dictionary) -> bool:
	var ok := true
	var const_names := ["CONNECTOR", "ASCENT", "CHASM", "BRIDGE"]
	var helper_names := ["connector", "ascent", "chasm", "bridge"]
	var const_map: Dictionary = tile_id_helper.get_script().get_script_constant_map()

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
		if tile_id_helper.has_method(name):
			print("  PASS TerrainTileIds.%s(): exists" % [name])
		else:
			push_error("TerrainTileIds.%s() method not found." % [name])
			print("  FAIL TerrainTileIds.%s(): not found" % [name])
			ok = false

	var pack_symbolic_checks := {
		"connector": {
			"constants": ["CONNECTOR"],
			"helper": "connector",
		},
		"ascent": {
			"constants": ["ASCENT"],
			"helper": "ascent",
		},
		"chasm_bridge": {
			"constants": ["CHASM", "BRIDGE"],
			"helper": "",
		},
	}

	for pack_key in pack_symbolic_checks:
		var manifest := manifests.get(pack_key, {}) as Dictionary
		var tile_ids := _manifest_tile_id_set(manifest)
		var check := pack_symbolic_checks[pack_key] as Dictionary
		for const_name in check.get("constants", []):
			var value_map = const_map.get(const_name, {})
			if typeof(value_map) != TYPE_DICTIONARY:
				continue
			for symbolic_key in value_map:
				var tile_id := String(value_map[symbolic_key])
				if not tile_ids.has(tile_id):
					push_error("TerrainTileIds.%s.%s resolves to '%s', which is not in %s manifest." % [const_name, symbolic_key, tile_id, pack_key])
					ok = false
				var helper_name := String(check.get("helper", ""))
				if not helper_name.is_empty() and tile_id_helper.has_method(helper_name):
					var helper_value := String(tile_id_helper.call(helper_name, symbolic_key, "__missing__"))
					if helper_value != tile_id:
						push_error("TerrainTileIds.%s('%s') returned '%s', expected '%s'." % [helper_name, symbolic_key, helper_value, tile_id])
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
		if tile_id_helper.has_method("connector"):
			var result := tile_id_helper.connector(tile_id, fallback)
			if result != fallback:
				push_error("Non-walkable '%s' resolved by connector() to walkable '%s'." % [tile_id, result])
				ok = false
		if tile_id_helper.has_method("ascent"):
			var result := tile_id_helper.ascent(tile_id, fallback)
			if result != fallback:
				push_error("Non-walkable '%s' resolved by ascent() to walkable '%s'." % [tile_id, result])
				ok = false

	if not ok:
		print("  FAIL Non-walkable chasm tile check")
		return false

	print("  PASS Non-walkable check")
	return true


func _validate_tileset_registration(manifests: Dictionary) -> bool:
	var ok := true
	var report := _load_registration_report()
	var source_texture_paths := _build_report_source_texture_paths(report, manifests)
	var tileset_resource := ResourceLoader.load(TILESET_PATH)
	if tileset_resource == null or not (tileset_resource is TileSet):
		push_error("Could not load TileSet resource: %s" % [TILESET_PATH])
		print("  FAIL TileSet registration: load failed")
		return false

	var tileset := tileset_resource as TileSet
	for pack_key in MANIFESTS:
		var info := MANIFESTS[pack_key] as Dictionary
		var manifest := manifests.get(pack_key, {}) as Dictionary
		var expected_ids := _expected_source_ids(info)
		for source_id in expected_ids:
			if not tileset.has_source(source_id):
				push_error("%s: No TileSet atlas source for source_id=%d." % [info["label"], source_id])
				ok = false
				continue

			var source := tileset.get_source(source_id)
			if source == null or not (source is TileSetAtlasSource):
				push_error("%s: source_id=%d is not a TileSetAtlasSource." % [info["label"], source_id])
				ok = false
				continue

			var atlas := source as TileSetAtlasSource
			if atlas.texture_region_size != Vector2i(32, 32):
				push_error("%s: source_id=%d texture_region_size=%s, expected (32, 32)." % [info["label"], source_id, str(atlas.texture_region_size)])
				ok = false

			if not atlas.has_tile(Vector2i.ZERO):
				push_error("%s: source_id=%d does not contain atlas coord (0, 0)." % [info["label"], source_id])
				ok = false

			var expected_texture_path := String(source_texture_paths.get(source_id, ""))
			if expected_texture_path.is_empty():
				expected_texture_path = _expected_texture_for_source_id(info, manifest, source_id)
			if expected_texture_path.is_empty():
				push_error("%s: no manifest tile maps to source_id=%d." % [info["label"], source_id])
				ok = false
				continue

			var texture := atlas.texture
			if texture == null:
				push_error("%s: source_id=%d has no texture." % [info["label"], source_id])
				ok = false
				continue

			if texture.resource_path != expected_texture_path:
				push_error("%s: source_id=%d texture path '%s' does not match manifest runtime PNG '%s'." % [info["label"], source_id, texture.resource_path, expected_texture_path])
				ok = false

		if ok:
			print("  PASS %s TileSet atlas registration: source IDs %d-%d" % [info["label"], int(info["source_id_start"]), int(info["source_id_start"]) + int(info["source_id_count"]) - 1])

	if not ok:
		print("  FAIL TileSet atlas source registration")
		return false

	print("  PASS TileSet atlas source registration")
	return true


func _validate_runtime_visual_map(manifests: Dictionary) -> bool:
	var ok := true
	var runtime_sources: Dictionary = PROCGEN_TILEMAP.TERRAIN_TILESET_SOURCES
	for pack_key in MANIFESTS:
		var info := MANIFESTS[pack_key] as Dictionary
		var manifest := manifests.get(pack_key, {}) as Dictionary
		var tiles: Array = manifest.get("tiles", [])
		var source_start := int(info["source_id_start"])
		for index in range(tiles.size()):
			var tile: Dictionary = tiles[index]
			var tile_id := String(tile.get("id", ""))
			var expected_source_id := source_start + index
			if not runtime_sources.has(tile_id):
				push_error("%s: '%s' is registered in TileSet but missing from ProcGenTilemap.TERRAIN_TILESET_SOURCES." % [info["label"], tile_id])
				ok = false
				continue
			var source_def: Dictionary = runtime_sources[tile_id]
			if int(source_def.get("source_id", -1)) != expected_source_id:
				push_error("%s: '%s' runtime source_id=%s, expected %d." % [info["label"], tile_id, str(source_def.get("source_id")), expected_source_id])
				ok = false
			var expected_layer := "wall" if pack_key == "chasm_bridge" and expected_source_id <= 114 else "floor"
			if String(source_def.get("layer", "")) != expected_layer:
				push_error("%s: '%s' runtime layer='%s', expected '%s'." % [info["label"], tile_id, String(source_def.get("layer", "")), expected_layer])
				ok = false
	if not ok:
		print("  FAIL ProcGenTilemap runtime visual source map")
		return false
	print("  PASS ProcGenTilemap runtime visual source map: all 62 gameplay art IDs")
	return true


func _validate_registration_report(manifests: Dictionary) -> bool:
	if not FileAccess.file_exists(_global_path(REGISTRATION_REPORT_PATH)):
		push_error("TileSet registration report is missing: %s" % [REGISTRATION_REPORT_PATH])
		print("  FAIL TileSet registration report: missing")
		return false

	var report := _load_registration_report()
	if report.is_empty():
		print("  FAIL TileSet registration report: parse failed")
		return false

	var packs: Variant = report.get("packs", {})
	if typeof(packs) != TYPE_DICTIONARY:
		push_error("TileSet registration report has no packs dictionary.")
		print("  FAIL TileSet registration report: missing packs")
		return false

	var ok := true
	var seen_source_ids := {}
	for pack_key in MANIFESTS:
		var info := MANIFESTS[pack_key] as Dictionary
		var pack_report: Variant = packs.get(pack_key, {})
		if typeof(pack_report) != TYPE_DICTIONARY:
			push_error("TileSet registration report missing pack '%s'." % [pack_key])
			ok = false
			continue

		var expected_start := int(info["source_id_start"])
		if int(pack_report.get("source_id_start", -1)) != expected_start:
			push_error("%s report source_id_start=%s, expected %d." % [info["label"], str(pack_report.get("source_id_start")), expected_start])
			ok = false

		var tiles: Variant = pack_report.get("tiles", {})
		if typeof(tiles) != TYPE_DICTIONARY:
			push_error("%s report tiles is not a dictionary." % [info["label"]])
			ok = false
			continue

		var expected_count := int(info["source_id_count"])
		if tiles.size() != expected_count:
			push_error("%s report tile count=%d, expected %d." % [info["label"], tiles.size(), expected_count])
			ok = false

		var manifest_ids := _manifest_tile_id_set(manifests.get(pack_key, {}) as Dictionary)
		for tile_id in tiles:
			if not manifest_ids.has(String(tile_id)):
				push_error("%s report contains tile_id '%s' not present in manifest." % [info["label"], String(tile_id)])
				ok = false
			var source_id := int(tiles[tile_id])
			if source_id < expected_start or source_id >= expected_start + expected_count:
				push_error("%s report tile_id '%s' uses source_id=%d outside expected range %d-%d." % [info["label"], String(tile_id), source_id, expected_start, expected_start + expected_count - 1])
				ok = false
			if seen_source_ids.has(source_id):
				push_error("Duplicate TileSet source_id=%d in report: %s and %s." % [source_id, seen_source_ids[source_id], String(tile_id)])
				ok = false
			else:
				seen_source_ids[source_id] = String(tile_id)

		for expected_source_id in _expected_source_ids(info):
			if not seen_source_ids.has(expected_source_id):
				push_error("%s report missing expected source_id=%d." % [info["label"], expected_source_id])
				ok = false

	if not ok:
		print("  FAIL TileSet registration report validation")
		return false

	print("  PASS TileSet registration report validation")
	return true


func _load_registration_report() -> Dictionary:
	var file := FileAccess.open(_global_path(REGISTRATION_REPORT_PATH), FileAccess.READ)
	if file == null:
		push_error("Could not open TileSet registration report: %s" % [REGISTRATION_REPORT_PATH])
		return {}

	var raw := file.get_as_text()
	file.close()

	var j := JSON.new()
	var parse_err := j.parse(raw)
	if parse_err != OK or typeof(j.data) != TYPE_DICTIONARY:
		push_error("TileSet registration report parse failed: %s" % [j.get_error_message()])
		return {}

	return j.data as Dictionary


func _build_report_source_texture_paths(report: Dictionary, manifests: Dictionary) -> Dictionary:
	var result := {}
	var packs: Variant = report.get("packs", {}) if not report.is_empty() else {}
	if typeof(packs) != TYPE_DICTIONARY:
		return result

	for pack_key in MANIFESTS:
		var info := MANIFESTS[pack_key] as Dictionary
		var pack_report: Variant = packs.get(pack_key, {})
		if typeof(pack_report) != TYPE_DICTIONARY:
			continue

		var tiles: Variant = pack_report.get("tiles", {})
		if typeof(tiles) != TYPE_DICTIONARY:
			continue

		var tile_file_by_id := _manifest_tile_file_map(manifests.get(pack_key, {}) as Dictionary)
		for tile_id in tiles:
			var tile_file := String(tile_file_by_id.get(String(tile_id), ""))
			if tile_file.is_empty():
				continue
			var source_id := int(tiles[tile_id])
			result[source_id] = String(info["runtime_dir"]).path_join(tile_file)
	return result


func _manifest_tile_id_set(manifest: Dictionary) -> Dictionary:
	var result := {}
	for tile in manifest.get("tiles", []):
		if typeof(tile) == TYPE_DICTIONARY:
			result[String(tile.get("id", ""))] = true
	return result


func _manifest_tile_file_map(manifest: Dictionary) -> Dictionary:
	var result := {}
	for tile in manifest.get("tiles", []):
		if typeof(tile) == TYPE_DICTIONARY:
			result[String(tile.get("id", ""))] = String(tile.get("file", ""))
	return result


func _expected_source_ids(info: Dictionary) -> Array[int]:
	var ids: Array[int] = []
	var start := int(info["source_id_start"])
	var count := int(info["source_id_count"])
	for offset in range(count):
		ids.append(start + offset)
	return ids


func _expected_texture_for_source_id(info: Dictionary, manifest: Dictionary, source_id: int) -> String:
	var index := source_id - int(info["source_id_start"])
	var tiles: Variant = manifest.get("tiles", [])
	if index < 0 or index >= tiles.size():
		return ""
	var tile: Variant = tiles[index]
	if typeof(tile) != TYPE_DICTIONARY:
		return ""
	return String(info["runtime_dir"]).path_join(String(tile.get("file", "")))


func _global_path(path: String) -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path
