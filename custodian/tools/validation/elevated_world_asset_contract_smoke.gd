extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const TILESET := preload("res://content/tiles/tilesets/procgen_world_tileset.tres")
const RUNTIME_BACKGROUNDS := [
	"res://content/backgrounds/procgen/endless_forest/endless_forest_depth_haze_1536x1024.png",
	"res://content/backgrounds/procgen/endless_forest/endless_forest_canopy_mass_1536x1024.png",
	"res://content/backgrounds/procgen/endless_forest/endless_forest_wall_growth_1536x1024.png",
]
const CONTACT_SHADOW_SOURCE := (
	"res://content/backgrounds/procgen/endless_forest/source/"
	+ "endless_forest_chasm_contact_shadow_source_1536x1024.png"
)

const EXPECTED := {
	44: "rock_ground_flat_32.png", 45: "rock_plateau_raised_32.png",
	46: "cliff_edge_north_32.png", 47: "cliff_edge_south_32.png",
	48: "cliff_edge_east_32.png", 49: "cliff_edge_west_32.png",
	50: "cliff_outer_nw_32.png", 51: "cliff_outer_ne_32.png",
	52: "cliff_outer_sw_32.png", 53: "cliff_outer_se_32.png",
	54: "cliff_inner_nw_32.png", 55: "cliff_inner_ne_32.png",
	56: "cliff_inner_sw_32.png", 57: "cliff_inner_se_32.png",
	58: "cliff_chasm_drop_32.png", 59: "mountain_wall_impassable_32.png",
	100: "chasm_void_32.png", 101: "chasm_edge_n_32.png",
	102: "chasm_edge_s_32.png", 103: "chasm_edge_e_32.png",
	104: "chasm_edge_w_32.png", 105: "chasm_outer_corner_ne_32.png",
	106: "chasm_outer_corner_nw_32.png", 107: "chasm_outer_corner_se_32.png",
	108: "chasm_outer_corner_sw_32.png", 109: "chasm_inner_corner_ne_32.png",
	110: "chasm_inner_corner_nw_32.png", 111: "chasm_inner_corner_se_32.png",
	112: "chasm_inner_corner_sw_32.png", 113: "collapsed_gap_32.png",
	114: "broken_gap_edge_32.png",
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for source_id: int in EXPECTED:
		assert(TILESET.has_source(source_id), "Missing TileSet source %d" % source_id)
		var source := TILESET.get_source(source_id) as TileSetAtlasSource
		assert(source != null and source.texture != null)
		var path := source.texture.resource_path
		assert(path.ends_with(EXPECTED[source_id]), "Source %d mismatch: %s" % [source_id, path])
		assert(not path.contains("/elevated_world/source/") and not path.contains("/elevated_world/archive/"))
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert(image != null and image.get_size() == Vector2i(32, 32), "%s must be 32x32" % path)
		assert(path.ends_with(".png"))
		if source_id in range(46, 58) or source_id in range(101, 113):
			assert(_has_transparency(image), "%s must contain true alpha" % path)

	for path: String in RUNTIME_BACKGROUNDS:
		_assert_image_size(path, Vector2i(1536, 1024))
		_assert_import_settings(path + ".import", false)
	_assert_image_size(CONTACT_SHADOW_SOURCE, Vector2i(1536, 1024))
	_assert_import_settings(CONTACT_SHADOW_SOURCE + ".import", false)

	var map := MAP_SCENE.instantiate()
	root.add_child(map)
	var backdrop := map.get_node_or_null("DepthBackdrop") as ProcgenDepthBackdrop
	assert(backdrop != null)
	_assert_no_physics_or_navigation(backdrop)
	backdrop.configure_from_cells([
		Vector2i(-12, -8),
		Vector2i(20, 14),
	])
	await process_frame
	assert(backdrop.visible)
	var fallback_regions := (
		backdrop.get_node("ChasmPresentationRoot").get_children()
	)
	assert(fallback_regions.size() == 1)
	var fallback := fallback_regions[0] as Node2D
	assert(fallback != null and fallback.name == "WorldDepthBackdrop")
	assert(fallback.get_meta("world_cell_bounds", Rect2i()) == Rect2i(-12, -8, 33, 23))
	assert(fallback.get_child_count() == 3)

	backdrop.configure_from_chasm_cells([
		Vector2i(-2, 4), Vector2i(-1, 4),
		Vector2i(-2, 5), Vector2i(-1, 5),
		Vector2i(7, 12), Vector2i(8, 12),
		Vector2i(7, 13), Vector2i(8, 13),
	])
	await process_frame
	assert(backdrop.visible)
	assert(backdrop.z_index == -300 and not backdrop.z_as_relative)
	var regions := backdrop.get_node("ChasmPresentationRoot").get_children()
	assert(regions.size() == 2)
	for region_variant: Variant in regions:
		var region := region_variant as Node2D
		assert(region != null)
		assert(region.scale.x >= 0.75 and region.scale.x <= 1.25)
		assert(is_equal_approx(region.scale.x, region.scale.y))
		var layers := [
			region.get_node_or_null("FarHaze") as Sprite2D,
			region.get_node_or_null("CanopyMass") as Sprite2D,
			region.get_node_or_null("WallGrowth") as Sprite2D,
		]
		for index in layers.size():
			var layer := layers[index] as Sprite2D
			assert(layer != null and layer.texture != null)
			assert(not layer.region_enabled, "Forest compositions must not repeat")
			assert(layer.texture_repeat == CanvasItem.TEXTURE_REPEAT_DISABLED)
			assert(layer.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR)
			assert(layer.centered)
			assert(layer.z_index == index - 3)
	assert(is_equal_approx(backdrop.far_haze_alpha, 0.30))
	assert(is_equal_approx(backdrop.canopy_alpha, 0.90))
	assert(is_equal_approx(backdrop.wall_growth_alpha, 0.48))
	assert(
		_find_texture_path(map, CONTACT_SHADOW_SOURCE).is_empty(),
		"Contact-shadow source must not be wired globally"
	)
	map.queue_free()
	print("elevated_world_asset_contract_smoke: PASS sources=%d" % EXPECTED.size())
	quit(0)


func _assert_image_size(path: String, expected: Vector2i) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null and image.get_size() == expected, "%s must be %s" % [path, expected])


func _assert_import_settings(path: String, mipmaps: bool) -> void:
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
	assert(not text.is_empty(), "Missing import metadata: %s" % path)
	assert("compress/mode=0" in text, "%s must use lossless compression" % path)
	assert(
		("mipmaps/generate=true" if mipmaps else "mipmaps/generate=false") in text,
		"%s mipmap setting mismatch" % path
	)


func _find_texture_path(node: Node, path: String) -> String:
	for child: Node in node.find_children("*", "", true, false):
		if child is Sprite2D:
			var texture := (child as Sprite2D).texture
			if texture != null and texture.resource_path == path:
				return texture.resource_path
	return ""


func _has_transparency(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.99:
				return true
	return false


func _assert_no_physics_or_navigation(node: Node) -> void:
	for child in node.find_children("*", "", true, false):
		assert(not child is CollisionObject2D, "Backdrop must not contain collision")
		assert(not child is NavigationRegion2D, "Backdrop must not contain navigation")
