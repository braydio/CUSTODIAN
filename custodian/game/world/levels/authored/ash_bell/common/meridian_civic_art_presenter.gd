class_name MeridianCivicArtPresenter
extends Node2D

const Palette := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_palette.gd")
const FLOOR := preload("res://content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png")
const WALL := preload("res://content/tiles/ash_bell/lower_quarter/meridian_civic_wall_atlas_512.png")
const OVERLAP := preload("res://content/tiles/ash_bell/lower_quarter/ash_bell_overlap_atlas_512.png")
const TILE_SIZE := 32

const ENTRANCE_SOUTH_THRESHOLD_RECT := Rect2i(60, 90, 9, 4)
const ENTRANCE_FORECOURT_RECT := Rect2i(54, 84, 21, 6)
const ENTRANCE_NORTH_APRON_RECT := Rect2i(57, 82, 14, 2)
const ARRIVAL_AXIS_RECT := Rect2i(62, 82, 5, 12)
const DIRECT_COLLAPSE_FLOOR_RECT := Rect2i(58, 71, 12, 4)
const DIRECT_PERSONNEL_RECT := Rect2i(58, 70, 12, 14)
const WEST_DETOUR_RECT := Rect2i(38, 74, 22, 8)
const EVACUATION_ARCADE_RECT := Rect2i(32, 48, 14, 32)
const LOWER_MARKET_RECT := Rect2i(16, 34, 46, 20)
const CIVIC_BASIN_RECT := Rect2i(56, 36, 24, 14)
const WRONG_STREET_LOCAL_RECT := Rect2i(74, 30, 10, 24)
const WRONG_STREET_BOUNDARY_RECT := Rect2i(84, 30, 8, 24)
const WRONG_STREET_IMPORT_RECT := Rect2i(92, 30, 16, 24)
const NORTH_RAMP_RECT := Rect2i(84, 18, 12, 14)
const ANSWERS_COURT_RECT := Rect2i(55, 8, 34, 22)
const UPPER_EAST_TRAVERSE_RECT := Rect2i(84, 16, 24, 10)
const EAST_SWITCHBACK_RECT := Rect2i(98, 22, 10, 44)
const STATION_THRESHOLD_RECT := Rect2i(72, 58, 30, 10)
const WEST_GATE_BRANCH_RECT := Rect2i(4, 39, 14, 8)

const LOWER_QUARTER_FLOOR_OVERRIDES := {
	Vector2i(55, 85): Vector2i(5, 0), Vector2i(58, 88): Vector2i(6, 0),
	Vector2i(55, 89): Vector2i(5, 0), Vector2i(73, 85): Vector2i(5, 0),
	Vector2i(70, 88): Vector2i(6, 0), Vector2i(73, 89): Vector2i(5, 0),
	Vector2i(57, 83): Vector2i(6, 0), Vector2i(70, 83): Vector2i(5, 0),
	Vector2i(60, 92): Vector2i(10, 0), Vector2i(68, 92): Vector2i(10, 0),
	Vector2i(58, 38): Vector2i(5, 0), Vector2i(62, 47): Vector2i(6, 0),
	Vector2i(76, 38): Vector2i(5, 0), Vector2i(78, 46): Vector2i(6, 0),
	Vector2i(57, 10): Vector2i(5, 0), Vector2i(86, 11): Vector2i(6, 0),
	Vector2i(60, 27): Vector2i(5, 0), Vector2i(84, 27): Vector2i(6, 0),
	Vector2i(76, 32): Vector2i(10, 0), Vector2i(82, 45): Vector2i(10, 0),
	Vector2i(79, 51): Vector2i(10, 0), Vector2i(74, 60): Vector2i(10, 0),
	Vector2i(96, 61): Vector2i(10, 0), Vector2i(81, 66): Vector2i(10, 0),
	Vector2i(99, 65): Vector2i(10, 0), Vector2i(20, 37): Vector2i(2, 8),
	Vector2i(25, 45): Vector2i(5, 8), Vector2i(33, 52): Vector2i(3, 9),
	Vector2i(40, 35): Vector2i(10, 9), Vector2i(49, 50): Vector2i(2, 8),
	Vector2i(58, 52): Vector2i(5, 8), Vector2i(53, 35): Vector2i(3, 9),
	Vector2i(30, 49): Vector2i(10, 9),
}

const WEST_GATE_ENTRY_RECT := Rect2i(48, 18, 12, 12)
const WEST_GATE_CONTROL_RECT := Rect2i(34, 16, 16, 16)
const WEST_GATE_PRESSURE_RECT := Rect2i(20, 12, 16, 24)
const WEST_GATE_MOTOR_RECT := Rect2i(8, 16, 14, 16)
const WEST_GATE_ARCHIVE_RECT := Rect2i(14, 4, 16, 8)
const WEST_GATE_CLOSURE_RECT := Rect2i(20, 32, 28, 10)

const STATION_GROUND_INTAKE_RECT := Rect2i(24, 44, 16, 10)
const STATION_WEST_RECORDS_RECT := Rect2i(8, 32, 20, 12)
const STATION_SYNC_PLANT_RECT := Rect2i(22, 24, 20, 16)
const STATION_EAST_RECORDS_RECT := Rect2i(40, 30, 16, 12)
const STATION_ANSWER_CHAMBER_RECT := Rect2i(15, 2, 34, 28)
const STATION_CONNECTOR_RECT := Rect2i(30, 39, 4, 6)

const DIRECT_ROUTE_WEST_MASS := Rect2i(48, 66, 10, 18)
const DIRECT_ROUTE_EAST_MASS := Rect2i(70, 68, 10, 16)
const EVACUATION_ARCADE_MASS := Rect2i(26, 55, 6, 25)
const WALL_ROOF_SOURCE := Vector2i(8, 0)
const WALL_CAP_SOURCE := Vector2i(0, 0)
const WALL_FACE_SOURCE := Vector2i(1, 4)
const EVACUATION_ARCADE_FACE := {
	Vector2i(26, 79): Vector2i(0, 1),
	Vector2i(27, 79): Vector2i(2, 1),
	Vector2i(28, 79): Vector2i(4, 1),
	Vector2i(29, 79): Vector2i(5, 1),
	Vector2i(30, 79): Vector2i(2, 1),
	Vector2i(31, 79): Vector2i(0, 1),
}

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
	_draw_authored_floor_overlays()
	match district:
		&"lower_quarter": _draw_lower_quarter()
		&"west_gate_works": _draw_west_gate()
		&"station_ix": _draw_station_ix()


func get_floor_material(cell: Vector2i) -> StringName:
	match district:
		&"west_gate_works":
			return &"road_base" if _get_west_gate_base(cell) == Palette.SRC_ROAD_DARK else &"normal_civic"
		&"station_ix":
			return &"road_base" if _get_station_ix_base(cell) == Palette.SRC_ROAD_DARK else &"normal_civic"
	if WRONG_STREET_IMPORT_RECT.has_point(cell):
		return &"overlap_import"
	if LOWER_MARKET_RECT.has_point(cell):
		return &"market_ground"
	var source := _get_lower_quarter_base(cell)
	if source == Palette.SRC_ROAD_GREY or source == Palette.SRC_ROAD_DARK:
		return &"road_base"
	return &"normal_civic"


func get_floor_source_cell(cell: Vector2i) -> Vector2i:
	match district:
		&"west_gate_works": return _get_west_gate_base(cell)
		&"station_ix": return _get_station_ix_base(cell)
		_:
			if LOWER_QUARTER_FLOOR_OVERRIDES.has(cell):
				return LOWER_QUARTER_FLOOR_OVERRIDES[cell] as Vector2i
			return _get_lower_quarter_base(cell)


func _get_lower_quarter_base(cell: Vector2i) -> Vector2i:
	if ANSWERS_COURT_RECT.has_point(cell): return Palette.SRC_CIVIC_LIGHT
	if STATION_THRESHOLD_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if CIVIC_BASIN_RECT.has_point(cell): return Palette.SRC_CIVIC_LIGHT
	if WRONG_STREET_IMPORT_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if DIRECT_COLLAPSE_FLOOR_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if WEST_DETOUR_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if DIRECT_PERSONNEL_RECT.has_point(cell): return Palette.SRC_ROAD_GREY
	if ARRIVAL_AXIS_RECT.has_point(cell): return Palette.SRC_ROAD_GREY
	if ENTRANCE_SOUTH_THRESHOLD_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if ENTRANCE_FORECOURT_RECT.has_point(cell): return Palette.SRC_CIVIC_LIGHT
	if ENTRANCE_NORTH_APRON_RECT.has_point(cell): return Palette.SRC_CIVIC_LIGHT
	if EVACUATION_ARCADE_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if NORTH_RAMP_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if UPPER_EAST_TRAVERSE_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if EAST_SWITCHBACK_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if WEST_GATE_BRANCH_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if LOWER_MARKET_RECT.has_point(cell): return Palette.SRC_MARKET_BASE
	if WRONG_STREET_LOCAL_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if WRONG_STREET_BOUNDARY_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	return Palette.SRC_CIVIC_DARK


func _get_west_gate_base(cell: Vector2i) -> Vector2i:
	if WEST_GATE_ENTRY_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if WEST_GATE_CONTROL_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if WEST_GATE_PRESSURE_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if WEST_GATE_MOTOR_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if WEST_GATE_ARCHIVE_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if WEST_GATE_CLOSURE_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	return Palette.SRC_CIVIC_DARK


func _get_station_ix_base(cell: Vector2i) -> Vector2i:
	if STATION_SYNC_PLANT_RECT.has_point(cell): return Palette.SRC_ROAD_DARK
	if STATION_GROUND_INTAKE_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if STATION_WEST_RECORDS_RECT.has_point(cell): return Vector2i(12, 0)
	if STATION_EAST_RECORDS_RECT.has_point(cell): return Vector2i(12, 0)
	if STATION_ANSWER_CHAMBER_RECT.has_point(cell): return Palette.SRC_CIVIC_DARK
	if STATION_CONNECTOR_RECT.has_point(cell): return Vector2i(12, 0)
	return Palette.SRC_CIVIC_DARK


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
	_draw_authored_wall_mass(DIRECT_ROUTE_WEST_MASS)
	_draw_authored_wall_mass(DIRECT_ROUTE_EAST_MASS)
	_draw_authored_wall_mass(EVACUATION_ARCADE_MASS, EVACUATION_ARCADE_FACE)
	_draw_wrong_street()


func _draw_authored_wall_mass(
	rect: Rect2i,
	explicit_south_face: Dictionary = {},
) -> void:
	# Structural volume is a coherent roof field. Wall-atlas modules only
	# describe exposed edges and authored openings; they never tile the mass.
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_draw_cell_source(FLOOR, WALL_ROOF_SOURCE, Vector2i(x, y))

	for x in range(rect.position.x, rect.end.x):
		_draw_cell_source(WALL, WALL_CAP_SOURCE, Vector2i(x, rect.position.y))

	var south_y := rect.end.y - 1
	for x in range(rect.position.x, rect.end.x):
		var cell := Vector2i(x, south_y)
		var source := explicit_south_face.get(cell, WALL_FACE_SOURCE) as Vector2i
		_draw_cell_source(WALL, source, cell)


func _draw_authored_floor_overlays() -> void:
	for cell: Vector2i in _collect_walkable_cells():
		var source := get_floor_overlay_source_cell(cell)
		if source != Vector2i(-1, -1):
			_draw_cell_source(FLOOR, source, cell)


func get_floor_overlay_source_cell(cell: Vector2i) -> Vector2i:
	if district == &"west_gate_works":
		if (cell.y == 24 and cell.x in range(10, 58)) or (cell.y == 36 and cell.x in range(22, 47)):
			return Palette.SRC_ROAD_LINE_H
		return Vector2i(-1, -1)
	if district == &"station_ix":
		if cell == Vector2i(32, 51): return Palette.SRC_ROAD_ARROW_N
		if cell.x == 32 and (cell.y in range(46, 51) or cell.y in range(27, 38)):
			return Palette.SRC_ROAD_LINE_V_DASH
		if cell == Vector2i(24, 33): return Vector2i(9, 12)
		if cell == Vector2i(40, 33): return Vector2i(11, 12)
		if cell == Vector2i(32, 18): return Vector2i(13, 13)
		return Vector2i(-1, -1)
	if cell == Vector2i(64, 86) or cell == Vector2i(64, 78) or cell == Vector2i(89, 22) or cell == Vector2i(103, 28) or cell == Vector2i(103, 52):
		return Palette.SRC_ROAD_ARROW_N
	if cell.y == 90 and cell.x in range(60, 69): return Palette.SRC_ROAD_LINE_H_DOUBLE
	if cell.y == 89 and cell.x in range(62, 67): return Palette.SRC_ROAD_CROSSWALK_H
	if cell.x == 64 and (cell.y in range(91, 93) or cell.y in range(84, 89) or cell.y in range(75, 84)):
		return Palette.SRC_ROAD_LINE_V_DASH
	if cell.y == 79 and cell.x in range(40, 64): return Palette.SRC_ROAD_LINE_H
	if cell.x == 39 and cell.y in range(50, 74): return Palette.SRC_ROAD_LINE_V_DASH
	if cell.y == 42 and cell.x in range(6, 17): return Palette.SRC_ROAD_LINE_H
	if cell.x == 89 and cell.y in range(20, 31): return Palette.SRC_ROAD_LINE_V_DASH
	if cell.y == 22 and cell.x in range(90, 103): return Palette.SRC_ROAD_LINE_H
	if cell.x == 103 and cell.y in range(26, 63): return Palette.SRC_ROAD_LINE_V_DASH
	return Vector2i(-1, -1)


func _draw_wrong_street() -> void:
	# Local Meridian paving remains restrained. Only sparse seam details mark the
	# boundary, and only the import band replaces it with Ash-Bell material.
	for y in range(WRONG_STREET_BOUNDARY_RECT.position.y, WRONG_STREET_BOUNDARY_RECT.end.y, 3):
		for x in range(WRONG_STREET_BOUNDARY_RECT.position.x, WRONG_STREET_BOUNDARY_RECT.end.x, 2):
			_draw_cell_source(OVERLAP, Vector2i(7, 5), Vector2i(x, y))
	for y in range(WRONG_STREET_IMPORT_RECT.position.y, WRONG_STREET_IMPORT_RECT.end.y):
		for x in range(WRONG_STREET_IMPORT_RECT.position.x, WRONG_STREET_IMPORT_RECT.end.x):
			_draw_cell_source(OVERLAP, Vector2i(0, 0), Vector2i(x, y))
	for x in range(92, 108):
		_draw_cell_source(OVERLAP, Vector2i(0, 4), Vector2i(x, 36 + ((x - 92) / 4)))
	for cell in [Vector2i(94, 33), Vector2i(98, 37), Vector2i(102, 41), Vector2i(106, 45)]:
		_draw_cell_source(OVERLAP, Vector2i(0, 2), cell)
	for cell in [Vector2i(95, 50), Vector2i(101, 48), Vector2i(105, 34)]:
		_draw_cell_source(OVERLAP, Vector2i(0, 10), cell)


func _draw_west_gate() -> void:
	for rect in [Rect2i(6, 14, 4, 20), Rect2i(32, 12, 3, 22), Rect2i(47, 14, 3, 20), Rect2i(13, 3, 18, 2)]:
		_draw_wall_band(rect, "service_wall")


func _draw_station_ix() -> void:
	for rect in [Rect2i(7, 31, 2, 14), Rect2i(27, 30, 2, 14), Rect2i(39, 29, 2, 14), Rect2i(55, 29, 2, 14)]:
		_draw_wall_band(rect, "service_wall")


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
		_draw_cell_source(WALL, Vector2i(0, 0), Vector2i(x, top_y))

	# Bottom-facing facade is what should carry most visual information.
	for x in range(rect.position.x, rect.end.x):
		_draw_cell_source(WALL, Vector2i(1, 4), Vector2i(x, bottom_y))

func _draw_cell_source(texture: Texture2D, source: Vector2i, cell: Vector2i) -> void:
	var destination := Rect2(map_origin + Vector2(cell * TILE_SIZE), Vector2.ONE * TILE_SIZE)
	draw_texture_rect_region(texture, destination, Rect2(source * TILE_SIZE, Vector2i.ONE * TILE_SIZE))
