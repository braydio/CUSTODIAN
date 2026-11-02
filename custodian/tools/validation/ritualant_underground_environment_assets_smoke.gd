extends SceneTree

const FAMILY_ID := "ritualant_underground_environment"
const FAMILY_PATH := "res://content/metadata/assets/families/ritualant_underground_environment.asset.json"
const CATALOG_PATH := "res://content/metadata/assets/generated/asset_catalog.generated.json"
const SCENE_PATH := "res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn"
const SITE_SCENE_PATH := "res://game/world/events/ash_bell/forlorn_ritualant_site.tscn"
const EFFECT_FAMILY_ID := "ritualant_underground_hazard_fx"
const EFFECTS := {
	"thread_warning_sweep_01": ["res://content/sprites/effects/runtime/ritualant_underground_hazard/ritualant_underground_hazard__fx__hazard__thread_warning_sweep_01__omni__8f__384x96.png", Vector2i(3072, 96), 8],
	"thread_activation_burst_01": ["res://content/sprites/effects/runtime/ritualant_underground_hazard/ritualant_underground_hazard__fx__hazard__thread_activation_burst_01__omni__10f__384x128.png", Vector2i(3840, 128), 10],
}
const CANONICAL := {
	"far_void_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__far_void_01__2048x2048.png", Vector2i(2048, 2048)],
	"mid_depth_south_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__mid_depth_south_01__2048x1536.png", Vector2i(2048, 1536)],
	"mid_depth_middle_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__mid_depth_middle_01__2048x1792.png", Vector2i(2048, 1792)],
	"mid_depth_north_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__mid_depth_north_01__2048x1792.png", Vector2i(2048, 1792)],
	"cavern_repeat_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__ground__cavern_repeat_01__512x512.png", Vector2i(512, 512)],
	"landing_shelf_apron_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__landing_shelf_apron_01__768x512.png", Vector2i(768, 512)],
	"cavern_rim_south_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__cavern_rim_south_01__1024x1024.png", Vector2i(1024, 1024)],
	"cavern_rim_middle_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__cavern_rim_middle_01__1024x1024.png", Vector2i(1024, 1024)],
	"cavern_rim_north_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__cavern_rim_north_01__1024x1024.png", Vector2i(1024, 1024)],
	"mineral_haze_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__mineral_haze_01__1536x1536.png", Vector2i(1536, 1536)],
	"chapel_haze_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__underlay__chapel_haze_01__1024x768.png", Vector2i(1024, 768)],
	"arena_expanded_floor_base_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__arena__expanded_floor_base_01__2594x1737.png", Vector2i(2594, 1737)],
	"chapel_connector_apron_02": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__chapel_connector_apron_02__768x384.png", Vector2i(768, 384)],
	"chapel_threshold_forelip_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__occluder__chapel_threshold_forelip_01__1024x512.png", Vector2i(1024, 512)],
	"lower_quarter_seal_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__occluder__lower_quarter_seal_01__1024x512.png", Vector2i(1024, 512)],
	"thread_zone_decal_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__hazard__thread_zone_decal_01__384x96.png", Vector2i(384, 96)],
	"chapel_outer_blend_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__chapel_outer_blend_01__1280x1024.png", Vector2i(1280, 1024)],
	"wet_ground_detail_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__wet_ground_detail_01__384x256.png", Vector2i(384, 256)],
	"fracture_detail_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__overlay__fracture_detail_01__256x256.png", Vector2i(256, 256)],
	"shaft_scroll_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__lift__shaft_scroll_01__256x1536.png", Vector2i(256, 1536)],
	"arrival_back_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__lift__arrival_back_01__768x1536.png", Vector2i(768, 1536)],
	"arrival_fore_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__lift__arrival_fore_01__768x1536.png", Vector2i(768, 1536)],
	"landing_mouth_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__lift__landing_mouth_01__768x512.png", Vector2i(768, 512)],
	"distant_chapel_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__vista__distant_chapel_01__320x160.png", Vector2i(320, 160)],
	"south_right_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__occluder__south_right_01__768x512.png", Vector2i(768, 512)],
	"middle_left_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__occluder__middle_left_01__768x512.png", Vector2i(768, 512)],
	"middle_right_pillar_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__occluder__middle_right_pillar_01__512x768.png", Vector2i(512, 768)],
	"deep_left_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__occluder__deep_left_01__768x512.png", Vector2i(768, 512)],
	"rock_small_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__prop__rock_small_01__128x96.png", Vector2i(128, 96)],
	"rock_medium_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__prop__rock_medium_01__192x128.png", Vector2i(192, 128)],
	"stalagmite_tall_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__prop__stalagmite_tall_01__160x256.png", Vector2i(160, 256)],
	"stalagmite_wide_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__prop__stalagmite_wide_01__256x160.png", Vector2i(256, 160)],
	"service_rail_broken_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__prop__service_rail_broken_01__256x128.png", Vector2i(256, 128)],
	"chain_anchor_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__prop__chain_anchor_01__160x192.png", Vector2i(160, 192)],
	"mineral_seep_01": ["res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__prop__mineral_seep_01__256x192.png", Vector2i(256, 192)],
}
const ALPHA_REQUIRED := ["mineral_haze_01", "chapel_haze_01", "landing_shelf_apron_01", "cavern_rim_south_01", "cavern_rim_middle_01", "cavern_rim_north_01", "chapel_connector_apron_02", "chapel_threshold_forelip_01", "lower_quarter_seal_01", "thread_zone_decal_01", "chapel_outer_blend_01", "wet_ground_detail_01", "fracture_detail_01", "arrival_fore_01", "landing_mouth_01", "distant_chapel_01", "south_right_01", "middle_left_01", "middle_right_pillar_01", "deep_left_01", "rock_small_01", "rock_medium_01", "stalagmite_tall_01", "stalagmite_wide_01", "service_rail_broken_01", "chain_anchor_01", "mineral_seep_01"]

func _init() -> void:
	_assert_true(FileAccess.file_exists(FAMILY_PATH), "family contract exists")
	_assert_true(FileAccess.file_exists(CATALOG_PATH), "generated catalog exists")
	_assert_true(FileAccess.file_exists(SCENE_PATH), "authored Underground scene exists")
	if not _all_files_present():
		return
	_assert_catalog()
	_assert_scene_references()
	_assert_effects()
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
			var minimum := 0.15 if state_id in ["distant_chapel_01", "south_right_01", "middle_left_01", "middle_right_pillar_01", "deep_left_01", "rock_small_01", "rock_medium_01", "stalagmite_tall_01", "stalagmite_wide_01", "service_rail_broken_01", "chain_anchor_01", "mineral_seep_01"] else 0.05
			_assert_true(_transparent_fraction(texture) >= minimum, "%s meaningful transparent area" % state_id)
	return ok


func _transparent_fraction(texture: Texture2D) -> float:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return 0.0
	var transparent := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.05:
				transparent += 1
	return float(transparent) / float(image.get_width() * image.get_height())


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
	var site_text := FileAccess.get_file_as_string(SITE_SCENE_PATH)
	for state_id: String in CANONICAL:
		var path := String(CANONICAL[state_id][0])
		if state_id == "shaft_scroll_01":
			var lift_text := FileAccess.get_file_as_string("res://game/world/approaches/ash_bell/ash_bell_lift_ingress_presentation.tscn")
			_assert_true(lift_text.count(path) == 1, "surface lift references shaft_scroll_01 exactly once")
		elif state_id == "thread_zone_decal_01":
			_assert_true(site_text.count(path) == 1, "site scene references thread decal exactly once")
		else:
			_assert_true(scene_text.count(path) == 1, "scene references %s exactly once" % state_id)
	var packed := load(SCENE_PATH) as PackedScene
	_assert_true(packed != null, "authored Underground scene loads")
	var level := packed.instantiate()
	var arena := level.get_node_or_null("BackgroundRoot/RitualantArenaExpandedBase") as Sprite2D
	_assert_true(arena != null and arena.scale == Vector2.ONE, "expanded arena uses native scale")
	var forelip := level.get_node_or_null("OcclusionRoot/ChapelThreshold") as Sprite2D
	_assert_true(forelip != null and forelip.get_child_count() == 0, "forelip remains presentation-only")
	level.free()


func _assert_effects() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	var assets: Dictionary = catalog.get("families", {}).get(EFFECT_FAMILY_ID, {}).get("assets", {})
	for state_id: String in EFFECTS:
		var record: Array = EFFECTS[state_id]
		var path := String(record[0])
		var expected: Vector2i = record[1]
		var frame_count := int(record[2])
		_assert_true(ResourceLoader.exists(path), "%s effect exists" % state_id)
		var texture := load(path) as Texture2D
		_assert_true(texture != null and Vector2i(texture.get_width(), texture.get_height()) == expected, "%s exact strip dimensions" % state_id)
		var entry: Dictionary = assets.get(state_id + "::omni", {})
		_assert_true(int(entry.get("frames", 0)) == frame_count, "%s catalog frame count" % state_id)
	var warning := load("res://content/sprites/effects/runtime/ritualant_underground_hazard/thread_warning_sweep_frames.tres") as SpriteFrames
	var activation := load("res://content/sprites/effects/runtime/ritualant_underground_hazard/thread_activation_burst_frames.tres") as SpriteFrames
	_assert_true(warning != null and warning.get_frame_count(&"warning") == 8 and warning.get_animation_loop(&"warning"), "warning SpriteFrames contract")
	_assert_true(activation != null and activation.get_frame_count(&"activate") == 10 and not activation.get_animation_loop(&"activate"), "activation SpriteFrames contract")


func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error("[ritualant_underground_environment_assets_smoke] Assertion failed: %s" % label)
		quit(1)
