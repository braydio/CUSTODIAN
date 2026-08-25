extends SceneTree

const Palette := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_palette.gd")
const PresenterScript := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd")
const RUNTIME_ATLAS := "res://content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png"
const CLEAN_ATLAS := "res://asset_drop/source_work/meridian_civic_floor/meridian_civic_floor_atlas__alpha_clean.png"
const CLEANER := "res://tools/art/clean_meridian_civic_floor_atlas.py"

const EXPECTED_BASE := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(10, 0), Vector2i(8, 1), Vector2i(11, 1), Vector2i(12, 1),
	Vector2i(0, 2), Vector2i(10, 2),
]
const EXPECTED_WORN := [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
const EXPECTED_ROAD := [
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5),
	Vector2i(3, 5), Vector2i(11, 5), Vector2i(12, 5),
]


func _init() -> void:
	assert(Palette.BASE_CIVIC == EXPECTED_BASE)
	assert(Palette.BASE_CIVIC_FIELD.size() == 8)
	assert(Palette.BASE_CIVIC_STRUCTURAL == [Vector2i(8, 1), Vector2i(10, 2)])
	assert(Palette.WORN_CIVIC == EXPECTED_WORN)
	assert(Palette.ROAD_BASE == EXPECTED_ROAD)
	assert(Palette.MARKET_GROUND.size() == 31)
	assert(Palette.TRANSIT_MARKINGS.size() == 26)
	assert(Palette.CIVIC_ACCENTS.size() == 13)
	for x in 16:
		assert(Vector2i(x, 8) in Palette.MARKET_GROUND)
		assert(Vector2i(x, 4) in Palette.TRANSIT_MARKINGS)
	for x in 13:
		assert(Vector2i(x, 7) in Palette.CIVIC_ACCENTS)

	var forbidden_generic := (
		Palette.TRANSIT_MARKINGS + Palette.CIVIC_ACCENTS
		+ Palette.SERVICE_DETAILS + Palette.TECHNICAL_DETAILS
		+ Palette.MARKET_GROUND + Palette.ROAD_BASE
	)
	var base_count := 0
	var worn_count := 0
	for y in 100:
		for x in 100:
			var cell := Vector2i(x, y)
			var chosen := Palette.choose_normal_civic(cell)
			assert(chosen not in forbidden_generic)
			assert(chosen in Palette.BASE_CIVIC or chosen in Palette.WORN_CIVIC)
			assert(chosen not in Palette.BASE_CIVIC_STRUCTURAL)
			if chosen in Palette.BASE_CIVIC:
				base_count += 1
			else:
				worn_count += 1
	assert(base_count > 8500 and base_count < 9100)
	assert(worn_count > 900 and worn_count < 1500)

	var presenter := PresenterScript.new() as MeridianCivicArtPresenter
	presenter.configure(Vector2.ZERO, [], &"lower_quarter")
	assert(presenter.get_floor_material(Vector2i(64, 88)) == &"normal_civic")
	assert(presenter.get_floor_material(Vector2i(64, 78)) == &"road_base")
	assert(presenter.get_floor_material(Vector2i(39, 65)) == &"road_base")
	assert(presenter.get_floor_material(Vector2i(35, 43)) == &"market_ground")
	assert(presenter.get_floor_material(Vector2i(66, 43)) == &"normal_civic")
	assert(presenter.get_floor_material(Vector2i(79, 43)) == &"normal_civic")
	assert(presenter.get_floor_material(Vector2i(104, 43)) == &"overlap_import")
	assert(presenter.get_floor_material(Vector2i(72, 20)) == &"normal_civic")
	assert(presenter.get_floor_material(Vector2i(92, 22)) == &"road_base")
	assert(presenter.get_floor_material(Vector2i(78, 64)) == &"normal_civic")
	presenter.free()

	var runtime_path := ProjectSettings.globalize_path(RUNTIME_ATLAS)
	var clean_path := ProjectSettings.globalize_path(CLEAN_ATLAS)
	assert(FileAccess.get_md5(runtime_path) == FileAccess.get_md5(clean_path))
	var image := Image.load_from_file(runtime_path)
	assert(image != null and image.get_size() == Vector2i(512, 512))
	var transparent_pixels := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a == 0.0:
				transparent_pixels += 1
	assert(transparent_pixels > 30000)
	for cell: Vector2i in Palette.BASE_CIVIC + Palette.WORN_CIVIC + Palette.ROAD_BASE + Palette.MARKET_GROUND:
		_assert_cell_opaque(image, cell)

	var cleaner_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(CLEANER))
	assert("asset_drop/source_work/meridian_civic_floor" in cleaner_source)
	assert("lower_quarter_region" not in cleaner_source)
	assert("KEEP_OPAQUE" in cleaner_source and "FLOOD_THRESHOLD = 30" in cleaner_source and "HALO_THRESHOLD = 48" in cleaner_source)
	assert("rand" not in FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd")))

	print("ash_bell_lower_quarter_floor_atlas_smoke: PASS base=%d worn=%d transparent=%d" % [base_count, worn_count, transparent_pixels])
	quit(0)


func _assert_cell_opaque(image: Image, cell: Vector2i) -> void:
	for y in range(cell.y * 32, cell.y * 32 + 32):
		for x in range(cell.x * 32, cell.x * 32 + 32):
			assert(image.get_pixel(x, y).a == 1.0, "Ground cell %s contains transparency" % cell)
