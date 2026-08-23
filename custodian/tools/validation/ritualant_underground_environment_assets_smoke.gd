extends SceneTree

const FAMILY_ID := "ritualant_underground_environment"
const FAMILY_PATH := "res://content/metadata/assets/families/ritualant_underground_environment.asset.json"
const CATALOG_PATH := "res://content/metadata/assets/generated/asset_catalog.generated.json"
const SCENE_PATH := "res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn"
const CANONICAL := {
	"far_void_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__far_void_01__2048x2048.png", Vector2i(2048, 2048)],
	"mid_depth_south_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__mid_depth_south_01__2048x1536.png", Vector2i(2048, 1536)],
	"mid_depth_middle_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__mid_depth_middle_01__2048x1792.png", Vector2i(2048, 1792)],
	"mid_depth_north_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__mid_depth_north_01__2048x1792.png", Vector2i(2048, 1792)],
	"cavern_repeat_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__ground__cavern_repeat_01__512x512.png", Vector2i(512, 512)],
	"landing_shelf_apron_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__landing_shelf_apron_01__768x512.png", Vector2i(768, 512)],
	"cavern_rim_south_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__cavern_rim_south_01__1024x1024.png", Vector2i(1024, 1024)],
	"cavern_rim_middle_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__cavern_rim_middle_01__1024x1024.png", Vector2i(1024, 1024)],
	"cavern_rim_north_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__cavern_rim_north_01__1024x1024.png", Vector2i(1024, 1024)]
}
const ALPHA_REQUIRED := ["landing_shelf_apron_01", "cavern_rim_south_01", "cavern_rim_middle_01", "cavern_rim_north_01"]

func _init() -> void:
	_assert_true(FileAccess.file_exists(FAMILY_PATH), "family contract exists")
	_assert_true(FileAccess.file_exists(CATALOG_PATH), "generated catalog exists")
	_assert_true(FileAccess.file_exists(SCENE_PATH), "authored Underground scene exists")
	if not _all_files_present():
		return
	_assert_catalog()
	_assert_scene_references()
	print("[ritualant_underground_environment_assets_smoke] PASS")
	quit(0)


func _all_files_present() -> bool:
	var ok := true
	for state_id: String in CANONICAL:
		var record: Array = CANONICAL[state_id]
		var path := String(record[0])
		var expected: Vector2i = record[1]
		_assert_true(ResourceLoader.exists(path), "%s exists" % path)
		_assert_true(FileAccess.file_exists(path + ".import"), "%s imported" % path)
		var texture := load(path) as Texture2D
		_assert_true(texture != null, "%s loads as Texture2D" % path)
		if texture == null:
			ok = false
			continue
		_assert_true(Vector2i(texture.get_width(), texture.get_height()) == expected, "%s exact dimensions" % state_id)
		if state_id in ALPHA_REQUIRED:
			_assert_true(_contains_non_opaque(texture), "%s contains non-opaque pixels" % state_id)
	return ok


func _contains_non_opaque(texture: Texture2D) -> bool:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return false
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.999:
				return true
	return false


func _assert_catalog() -> void:
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	_assert_true(catalog is Dictionary, "catalog parses")
	if not catalog is Dictionary:
		return
	var family: Dictionary = (catalog as Dictionary).get("families", {}).get(FAMILY_ID, {})
	var assets: Dictionary = family.get("assets", {})
	for state_id: String in CANONICAL:
		var entry: Dictionary = assets.get(state_id + "::omni", {})
		_assert_true(String(entry.get("state_id", "")) == state_id, "catalog resolves %s" % state_id)
		_assert_true(String(entry.get("path", "")) == String(CANONICAL[state_id][0]).trim_prefix("res://"), "catalog path %s" % state_id)


func _assert_scene_references() -> void:
	var scene_text := FileAccess.get_file_as_string(SCENE_PATH)
	for state_id: String in CANONICAL:
		var path := String(CANONICAL[state_id][0])
		_assert_true(scene_text.count(path) == 1, "scene references %s exactly once" % state_id)
	var packed := load(SCENE_PATH) as PackedScene
	_assert_true(packed != null, "authored Underground scene loads")


func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error("[ritualant_underground_environment_assets_smoke] Assertion failed: %s" % label)
		quit(1)
