class_name MeridianCivicArtPresenter
extends Node2D

const Palette := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_palette.gd")
const FLOOR := preload("res://content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png")
const WALL := preload("res://content/tiles/ash_bell/lower_quarter/meridian_civic_wall_atlas_512.png")
const PROPS := preload("res://content/tiles/ash_bell/lower_quarter/meridian_civic_props_atlas_512.png")
const OVERLAP := preload("res://content/tiles/ash_bell/lower_quarter/ash_bell_overlap_atlas_512.png")
const TILE_SIZE := 32

var map_origin := Vector2.ZERO
var walkable_regions: Array[Rect2i] = []
var district := &"lower_quarter"

func configure(origin: Vector2, regions: Array[Rect2i], district_id: StringName = &"lower_quarter") -> void:
	map_origin = origin
	walkable_regions = regions.duplicate()
	district = district_id
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(map_origin, Vector2(128, 96) * TILE_SIZE), Color("11161a"), true)
	for region in walkable_regions: _draw_floor_region(region, _floor_category(region))
	match district:
		&"lower_quarter": _draw_lower_quarter()
		&"west_gate_works": _draw_west_gate()
		&"station_ix": _draw_station_ix()

func _draw_floor_region(region: Rect2i, category: String) -> void:
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x): _draw_cell(FLOOR, Palette.FLOOR[category], Vector2i(x, y))

func _floor_category(region: Rect2i) -> String:
	if district == &"station_ix": return "transit_marking"
	if district == &"west_gate_works": return "road"
	if region == Rect2i(16, 34, 46, 20): return "market"
	if region == Rect2i(56, 36, 24, 14): return "basin"
	if region.position.x >= 74 and region.position.y >= 30: return "road"
	return "civic_worn"

func _draw_lower_quarter() -> void:
	_draw_wall_band(Rect2i(48, 66, 10, 18), "retaining")
	_draw_wall_band(Rect2i(70, 68, 10, 16), "wall_straight")
	_draw_wall_band(Rect2i(26, 55, 6, 25), "arcade")
	for y in range(51, 79, 5): _draw_prop(Vector2i(31, y), "amber_warning_lamp")
	for cell in [Vector2i(54, 88), Vector2i(75, 88), Vector2i(22, 38), Vector2i(48, 48), Vector2i(60, 43)]: _draw_prop(cell, "lamp")
	for cell in [Vector2i(22, 45), Vector2i(30, 38), Vector2i(42, 49), Vector2i(51, 40)]: _draw_prop(cell, "bench")
	for x in range(56, 73): _draw_prop(Vector2i(x, 72 + (x % 3)), "rubble")
	_draw_wrong_street()

func _draw_wrong_street() -> void:
	for y in range(30, 54):
		for x in range(84, 92):
			_draw_cell(OVERLAP if (x + y) % 2 else FLOOR, Palette.OVERLAP["seam"] if (x + y) % 2 else Palette.FLOOR["civic_cracked"], Vector2i(x, y))
		for x in range(92, 108): _draw_cell(OVERLAP, Palette.OVERLAP["imported_floor"], Vector2i(x, y))
	for x in range(92, 108): _draw_cell(OVERLAP, Palette.OVERLAP["imported_curb"], Vector2i(x, 36 + ((x - 92) / 4)))
	for cell in [Vector2i(94, 33), Vector2i(98, 37), Vector2i(102, 41), Vector2i(106, 45)]: _draw_cell(OVERLAP, Palette.OVERLAP["imported_service_channel"], cell)
	for cell in [Vector2i(95, 50), Vector2i(101, 48), Vector2i(105, 34)]: _draw_cell(OVERLAP, Palette.OVERLAP["damaged_import"], cell)

func _draw_west_gate() -> void:
	for rect in [Rect2i(6, 14, 4, 20), Rect2i(32, 12, 3, 22), Rect2i(47, 14, 3, 20), Rect2i(13, 3, 18, 2)]: _draw_wall_band(rect, "service_wall")
	for cell in [Vector2i(10, 20), Vector2i(16, 20), Vector2i(24, 16), Vector2i(38, 20), Vector2i(45, 27)]: _draw_prop(cell, "amber_warning_lamp")
	for cell in [Vector2i(16, 28), Vector2i(26, 28), Vector2i(39, 28)]: _draw_prop(cell, "utility_box")

func _draw_station_ix() -> void:
	for rect in [Rect2i(7, 31, 2, 14), Rect2i(27, 30, 2, 14), Rect2i(39, 29, 2, 14), Rect2i(55, 29, 2, 14)]: _draw_wall_band(rect, "service_wall")
	for x in range(25, 37, 2): _draw_prop(Vector2i(x, 47), "utility_box")
	for cell in [Vector2i(27, 45), Vector2i(36, 45), Vector2i(18, 35), Vector2i(48, 35)]: _draw_prop(cell, "amber_warning_lamp")

func _draw_wall_band(rect: Rect2i, category: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x): _draw_cell(WALL, Palette.WALL[category], Vector2i(x, y))

func _draw_prop(cell: Vector2i, category: String) -> void: _draw_cell(PROPS, Palette.PROPS[category], cell)

func _draw_cell(texture: Texture2D, variants: Array, cell: Vector2i) -> void:
	var source := Palette.choose(variants, cell)
	var destination := Rect2(map_origin + Vector2(cell * TILE_SIZE), Vector2.ONE * TILE_SIZE)
	draw_texture_rect_region(texture, destination, Rect2(source * TILE_SIZE, Vector2i.ONE * TILE_SIZE))
