class_name MeridianCivicArtPresenter
extends Node2D

const Palette := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_palette.gd")
const FLOOR := preload("res://content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png")
const WALL := preload("res://content/tiles/ash_bell/lower_quarter/meridian_civic_wall_atlas_512.png")
const OVERLAP := preload("res://content/tiles/ash_bell/lower_quarter/ash_bell_overlap_atlas_512.png")
const TILE_SIZE := 32

const LOWER_MARKET_RECT := Rect2i(16, 34, 46, 20)
const CIVIC_BASIN_RECT := Rect2i(56, 36, 24, 14)
const ARRIVAL_PLATFORM_RECT := Rect2i(52, 82, 24, 12)
const EVACUATION_ARCADE_RECT := Rect2i(32, 48, 14, 32)
const DIRECT_PERSONNEL_RECT := Rect2i(58, 70, 12, 14)
const WRONG_STREET_BOUNDARY_RECT := Rect2i(84, 30, 8, 24)
const WRONG_STREET_IMPORT_RECT := Rect2i(92, 30, 16, 24)
const ANSWERS_COURT_RECT := Rect2i(55, 8, 34, 22)
const EAST_SWITCHBACK_RECT := Rect2i(84, 16, 24, 52)
const STATION_THRESHOLD_RECT := Rect2i(72, 58, 30, 10)

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
	for cell: Vector2i in _collect_walkable_cells():
		_draw_cell_source(FLOOR, get_floor_source_cell(cell), cell)
	match district:
		&"lower_quarter": _draw_lower_quarter()
		&"west_gate_works": _draw_west_gate()
		&"station_ix": _draw_station_ix()


func get_floor_material(cell: Vector2i) -> StringName:
	match district:
		&"west_gate_works":
			return &"road_base"
		&"station_ix":
			return &"road_base" if Rect2i(22, 24, 20, 16).has_point(cell) else &"normal_civic"
	if WRONG_STREET_IMPORT_RECT.has_point(cell):
		return &"overlap_import"
	if ARRIVAL_PLATFORM_RECT.has_point(cell) or CIVIC_BASIN_RECT.has_point(cell) or ANSWERS_COURT_RECT.has_point(cell) or STATION_THRESHOLD_RECT.has_point(cell):
		return &"normal_civic"
	if LOWER_MARKET_RECT.has_point(cell):
		return &"market_ground"
	if EVACUATION_ARCADE_RECT.has_point(cell) or DIRECT_PERSONNEL_RECT.has_point(cell) or EAST_SWITCHBACK_RECT.has_point(cell):
		return &"road_base"
	return &"normal_civic"


func get_floor_source_cell(cell: Vector2i) -> Vector2i:
	match get_floor_material(cell):
		&"market_ground":
			if Palette._stable_hash(cell, 0x5319) % 100 < 85:
				return Palette.choose(Palette.MARKET_GROUND, cell, 0x3481)
			return Palette.choose(Palette.WORN_CIVIC, cell, 0x8791)
		&"road_base":
			if Palette._stable_hash(cell, 0x19d3) % 100 < 90:
				return Palette.choose(Palette.ROAD_BASE, cell, 0x7123)
			return Palette.choose(Palette.WORN_CIVIC, cell, 0x2657)
		&"overlap_import":
			# The Ash-Bell atlas replaces this base in _draw_wrong_street().
			return Palette.choose(Palette.BASE_CIVIC, cell, 0x4117)
		_:
			return Palette.choose_normal_civic(cell)


func _collect_walkable_cells() -> Array[Vector2i]:
	var unique: Dictionary = {}
	for region: Rect2i in walkable_regions:
		for y in range(region.position.y, region.end.y):
			for x in range(region.position.x, region.end.x):
				unique[Vector2i(x, y)] = true
	var cells: Array[Vector2i] = []
	for cell_variant: Variant in unique.keys():
		cells.append(cell_variant as Vector2i)
	cells.sort()
	return cells


func _draw_lower_quarter() -> void:
	_draw_authored_floor_overlays()
	_draw_wall_band(Rect2i(48, 66, 10, 18), "retaining")
	_draw_wall_band(Rect2i(70, 68, 10, 16), "wall_straight")
	_draw_wall_band(Rect2i(26, 55, 6, 25), "arcade")
	_draw_wrong_street()


func _draw_authored_floor_overlays() -> void:
	for cell: Vector2i in [
		Vector2i(61, 89), Vector2i(64, 89), Vector2i(67, 89),
		Vector2i(62, 79), Vector2i(65, 76), Vector2i(60, 73),
		Vector2i(39, 74), Vector2i(35, 65), Vector2i(33, 56),
		Vector2i(66, 47), Vector2i(76, 43), Vector2i(87, 27),
		Vector2i(100, 27), Vector2i(99, 42), Vector2i(94, 62), Vector2i(82, 64),
	]:
		_draw_floor_overlay(cell, Palette.TRANSIT_MARKINGS, 0x2d11)
	for cell: Vector2i in [Vector2i(61, 40), Vector2i(69, 40), Vector2i(61, 47), Vector2i(69, 47), Vector2i(34, 55), Vector2i(39, 55)]:
		_draw_floor_overlay(cell, Palette.SERVICE_DETAILS, 0x6381)
	for cell: Vector2i in [Vector2i(64, 43), Vector2i(68, 43), Vector2i(69, 20), Vector2i(75, 20), Vector2i(89, 21), Vector2i(78, 64)]:
		_draw_floor_overlay(cell, Palette.CIVIC_ACCENTS, 0x1a57)


func _draw_wrong_street() -> void:
	# Local Meridian paving remains restrained. Only sparse seam details mark the
	# boundary, and only the import band replaces it with Ash-Bell material.
	for y in range(WRONG_STREET_BOUNDARY_RECT.position.y, WRONG_STREET_BOUNDARY_RECT.end.y, 3):
		for x in range(WRONG_STREET_BOUNDARY_RECT.position.x, WRONG_STREET_BOUNDARY_RECT.end.x, 2):
			_draw_cell(OVERLAP, Palette.OVERLAP["seam"], Vector2i(x, y))
	for y in range(WRONG_STREET_IMPORT_RECT.position.y, WRONG_STREET_IMPORT_RECT.end.y):
		for x in range(WRONG_STREET_IMPORT_RECT.position.x, WRONG_STREET_IMPORT_RECT.end.x):
			_draw_cell(OVERLAP, Palette.OVERLAP["imported_floor"], Vector2i(x, y))
	for x in range(92, 108):
		_draw_cell(OVERLAP, Palette.OVERLAP["imported_curb"], Vector2i(x, 36 + ((x - 92) / 4)))
	for cell in [Vector2i(94, 33), Vector2i(98, 37), Vector2i(102, 41), Vector2i(106, 45)]:
		_draw_cell(OVERLAP, Palette.OVERLAP["imported_service_channel"], cell)
	for cell in [Vector2i(95, 50), Vector2i(101, 48), Vector2i(105, 34)]:
		_draw_cell(OVERLAP, Palette.OVERLAP["damaged_import"], cell)


func _draw_west_gate() -> void:
	for cell: Vector2i in [Vector2i(54, 24), Vector2i(42, 24), Vector2i(30, 24), Vector2i(18, 24), Vector2i(18, 8), Vector2i(28, 36)]:
		_draw_floor_overlay(cell, Palette.TRANSIT_MARKINGS, 0x5189)
	for cell: Vector2i in [Vector2i(12, 24), Vector2i(22, 30), Vector2i(38, 24), Vector2i(30, 8)]:
		_draw_floor_overlay(cell, Palette.TECHNICAL_DETAILS, 0x9a13)
	for rect in [Rect2i(6, 14, 4, 20), Rect2i(32, 12, 3, 22), Rect2i(47, 14, 3, 20), Rect2i(13, 3, 18, 2)]:
		_draw_wall_band(rect, "service_wall")


func _draw_station_ix() -> void:
	for cell: Vector2i in [Vector2i(32, 51), Vector2i(32, 46), Vector2i(24, 37), Vector2i(32, 37), Vector2i(40, 37), Vector2i(32, 26), Vector2i(32, 21)]:
		_draw_floor_overlay(cell, Palette.TRANSIT_MARKINGS, 0x8421)
	for cell: Vector2i in [Vector2i(24, 33), Vector2i(40, 33), Vector2i(32, 18), Vector2i(30, 11), Vector2i(34, 11)]:
		_draw_floor_overlay(cell, Palette.TECHNICAL_DETAILS, 0x1471)
	for rect in [Rect2i(7, 31, 2, 14), Rect2i(27, 30, 2, 14), Rect2i(39, 29, 2, 14), Rect2i(55, 29, 2, 14)]:
		_draw_wall_band(rect, "service_wall")


func _draw_floor_overlay(cell: Vector2i, variants: Array, salt: int) -> void:
	_draw_cell_source(FLOOR, Palette.choose(variants, cell, salt), cell)


func _draw_wall_band(rect: Rect2i, category: String) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return

	# The wall atlas contains facade/perimeter modules with transparent negative
	# space. Architecture is a large continuous civic mass underneath them,
	# not one opaque 32x32 decorative tile repeated through every cell.
	var world_rect := Rect2(
		map_origin + Vector2(rect.position * TILE_SIZE),
		Vector2(rect.size * TILE_SIZE)
	)

	var mass_color := Color("1d2327")
	if category == "arcade":
		mass_color = Color("20272b")
	elif category == "service_wall":
		mass_color = Color("1b2024")
	elif category == "damaged_wall":
		mass_color = Color("1b1d1f")

	draw_rect(world_rect, mass_color, true)

	var top_y := rect.position.y
	var bottom_y := rect.end.y - 1

	# Quiet continuous roof/parapet line.
	for x in range(rect.position.x, rect.end.x):
		_draw_cell(WALL, Palette.WALL_TOP_STRAIGHT, Vector2i(x, top_y))

	# Bottom-facing facade is what should carry most visual information.
	var facade_variants: Array = Palette.WALL_RETAINING_FACES
	match category:
		"arcade":
			facade_variants = Palette.WALL_ARCH_FACADES
		"service_wall":
			facade_variants = Palette.WALL_SERVICE_FACADES
		"damaged_wall":
			facade_variants = Palette.WALL_DAMAGED
		"rail_edge", "parapet":
			facade_variants = Palette.WALL_RAIL_EDGES
		_:
			facade_variants = Palette.WALL_RETAINING_FACES

	for x in range(rect.position.x, rect.end.x):
		_draw_cell(WALL, facade_variants, Vector2i(x, bottom_y))

	# Sparse facade rhythm for tall masses. Never refill the whole rectangle.
	if rect.size.y >= 6 and category not in ["rail_edge", "parapet"]:
		for y in range(rect.position.y + 3, rect.end.y - 2, 4):
			for x in range(rect.position.x + 1, rect.end.x - 1, 4):
				var detail_pool: Array = (
					Palette.WALL_SERVICE_FACADES
					if category != "damaged_wall"
					else Palette.WALL_DAMAGED
				)
				_draw_cell(WALL, detail_pool, Vector2i(x, y))


func _draw_cell(texture: Texture2D, variants: Array, cell: Vector2i) -> void:
	_draw_cell_source(texture, Palette.choose(variants, cell), cell)


func _draw_cell_source(texture: Texture2D, source: Vector2i, cell: Vector2i) -> void:
	var destination := Rect2(map_origin + Vector2(cell * TILE_SIZE), Vector2.ONE * TILE_SIZE)
	draw_texture_rect_region(texture, destination, Rect2(source * TILE_SIZE, Vector2i.ONE * TILE_SIZE))
