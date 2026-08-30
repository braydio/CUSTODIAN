extends SceneTree

const Palette := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_palette.gd")
const PresenterScript := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd")
const RUNTIME_ATLAS := "res://content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png"

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

	assert(Palette.SRC_CIVIC_LIGHT == Vector2i(2, 0))
	assert(Palette.SRC_CIVIC_DARK == Vector2i(8, 0))
	assert(Palette.SRC_MARKET_BASE == Vector2i(1, 8))
	assert(Palette.SRC_ROAD_GREY == Vector2i(2, 5))
	assert(Palette.SRC_ROAD_DARK == Vector2i(11, 5))
	assert(Palette.SRC_ROAD_LINE_H == Vector2i(1, 4))
	assert(Palette.SRC_ROAD_LINE_V_DASH == Vector2i(5, 4))
	assert(Palette.SRC_ROAD_ARROW_N == Vector2i(10, 4))

	var presenter := PresenterScript.new() as MeridianCivicArtPresenter
	presenter.configure(Vector2.ZERO, [], &"lower_quarter")
	assert(presenter.get_floor_material(Vector2i(64, 88)) == &"road_base")
	assert(presenter.get_floor_material(Vector2i(64, 78)) == &"road_base")
	assert(presenter.get_floor_material(Vector2i(39, 65)) == &"road_base")
	assert(presenter.get_floor_material(Vector2i(35, 43)) == &"market_ground")
	assert(presenter.get_floor_material(Vector2i(66, 43)) == &"normal_civic")
	assert(presenter.get_floor_material(Vector2i(79, 43)) == &"normal_civic")
	assert(presenter.get_floor_material(Vector2i(104, 43)) == &"overlap_import")
	assert(presenter.get_floor_material(Vector2i(72, 20)) == &"normal_civic")
	assert(presenter.get_floor_material(Vector2i(92, 22)) == &"road_base")
	assert(presenter.get_floor_material(Vector2i(78, 64)) == &"normal_civic")
	assert(presenter.get_floor_source_cell(Vector2i(55, 88)) == Palette.SRC_CIVIC_LIGHT)
	assert(presenter.get_floor_source_cell(Vector2i(64, 88)) == Palette.SRC_ROAD_GREY)
	assert(presenter.get_floor_source_cell(Vector2i(39, 65)) == Palette.SRC_ROAD_DARK)
	assert(presenter.get_floor_source_cell(Vector2i(35, 43)) == Palette.SRC_MARKET_BASE)
	assert(presenter.get_floor_source_cell(Vector2i(20, 37)) == Palette.SRC_MARKET_WORN_A)
	assert(presenter.get_floor_source_cell(Vector2i(58, 38)) == Palette.SRC_CIVIC_LIGHT_WORN_A)
	assert(presenter.get_floor_overlay_source_cell(Vector2i(64, 85)) == Palette.SRC_ROAD_ARROW_N)
	assert(presenter.get_floor_overlay_source_cell(Vector2i(64, 86)) == Palette.SRC_ROAD_LINE_V_DASH)
	assert(presenter.get_floor_overlay_source_cell(Vector2i(62, 82)) == Palette.SRC_ROAD_CROSSWALK_H)
	presenter.configure(Vector2.ZERO, [], &"west_gate_works")
	assert(presenter.get_floor_source_cell(Vector2i(52, 22)) == Palette.SRC_CIVIC_DARK)
	assert(presenter.get_floor_source_cell(Vector2i(24, 20)) == Palette.SRC_ROAD_DARK)
	assert(presenter.get_floor_overlay_source_cell(Vector2i(54, 24)) == Palette.SRC_ROAD_LINE_H)
	presenter.configure(Vector2.ZERO, [], &"station_ix")
	assert(presenter.get_floor_source_cell(Vector2i(32, 28)) == Palette.SRC_ROAD_DARK)
	assert(presenter.get_floor_source_cell(Vector2i(16, 36)) == Vector2i(12, 0))
	assert(presenter.get_floor_source_cell(Vector2i(32, 48)) == Palette.SRC_CIVIC_DARK)
	assert(presenter.get_floor_overlay_source_cell(Vector2i(32, 51)) == Palette.SRC_ROAD_ARROW_N)
	assert(presenter.get_floor_overlay_source_cell(Vector2i(24, 33)) == Vector2i(9, 12))
	presenter.free()

	var runtime_path := ProjectSettings.globalize_path(RUNTIME_ATLAS)
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

	var presenter_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd"))
	assert("Palette.choose" not in presenter_source)
	assert("_stable_hash" not in presenter_source)
	assert("_draw_floor_overlay" not in presenter_source)
	assert("Palette.SERVICE_DETAILS" not in presenter_source)
	assert("Palette.CIVIC_ACCENTS" not in presenter_source)
	assert("_draw_cell(WALL" not in presenter_source)

	print("ash_bell_lower_quarter_floor_atlas_smoke: PASS authored_sources=true transparent=%d" % transparent_pixels)
	quit(0)


func _assert_cell_opaque(image: Image, cell: Vector2i) -> void:
	for y in range(cell.y * 32, cell.y * 32 + 32):
		for x in range(cell.x * 32, cell.x * 32 + 32):
			assert(image.get_pixel(x, y).a == 1.0, "Ground cell %s contains transparency" % cell)
