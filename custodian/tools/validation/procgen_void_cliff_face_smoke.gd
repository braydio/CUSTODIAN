extends SceneTree

const FACE_SCRIPT := preload("res://game/world/procgen/presentation/procgen_void_cliff_face.gd")
const TILESET := preload("res://content/tiles/tilesets/procgen_world_tileset.tres")
const SOURCE_PATHS := {
	149: "void_cliff_face_top_01_32.png",
	150: "void_cliff_face_body_01_32.png",
	151: "void_cliff_face_body_02_32.png",
	152: "void_cliff_face_body_cracked_01_32.png",
	153: "void_cliff_face_bottom_01_32.png",
	154: "void_cliff_face_bottom_broken_01_32.png",
}
const ROLE_SOURCE_IDS := {
	"top": 149,
	"body_01": 150,
	"body_02": 151,
	"body_cracked": 152,
	"bottom": 153,
	"bottom_broken": 154,
}
const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


func _init() -> void:
	for source_id: int in SOURCE_PATHS:
		assert(TILESET.has_source(source_id), "Missing fascia source %d" % source_id)
		var source := TILESET.get_source(source_id) as TileSetAtlasSource
		assert(source != null and source.texture != null)
		assert(source.texture.resource_path.ends_with(SOURCE_PATHS[source_id]))
		assert(source.get_tiles_count() == 1)

	var face := FACE_SCRIPT.new() as ProcgenVoidCliffFace
	face.tile_set = TILESET
	face.collision_enabled = false
	face.navigation_enabled = false
	root.add_child(face)
	assert(not face.collision_enabled and not face.navigation_enabled)
	assert(face.min_depth_tiles == 4 and face.max_depth_tiles == 8)
	assert(face.typical_max_depth_tiles == 6 and face.deep_section_percent == 12)
	assert(face.min_enclosed_chasm_cells_for_fascia == 24)

	var floor_cells: Dictionary = {}
	var chasm_cells: Dictionary = {}
	var ocean_cells: Dictionary = {}
	var floor_rect := Rect2i(Vector2i(24, 24), Vector2i(48, 48))
	for y in 96:
		for x in 96:
			var cell := Vector2i(x, y)
			if floor_rect.has_point(cell):
				floor_cells[cell] = true
			elif x < 4 and y < 4:
				ocean_cells[cell] = true
			else:
				chasm_cells[cell] = true
	var tiny_pocket := Vector2i(48, 48)
	floor_cells.erase(tiny_pocket)
	chasm_cells[tiny_pocket] = true
	var wall_cells: Dictionary = {}
	for x in range(36, 44):
		wall_cells[Vector2i(x, 23)] = {"source_id": 12}
	for y in range(36, 44):
		wall_cells[Vector2i(72, y)] = {"source_id": 12}
	for x in range(36, 44):
		wall_cells[Vector2i(x, 72)] = {"source_id": 12}
	for y in range(36, 44):
		wall_cells[Vector2i(23, y)] = {"source_id": 12}
	# Exercise a two-cell wall lip and a later wall that must hard-stop a ray.
	wall_cells[Vector2i(36, 22)] = {"source_id": 12}
	wall_cells[Vector2i(50, 20)] = {"source_id": 12}
	var floor_before := _dictionary_fingerprint(floor_cells)
	var chasm_before := _dictionary_fingerprint(chasm_cells)
	var walls_before := _dictionary_fingerprint(wall_cells)

	face.configure_from_surface_cells(floor_cells, chasm_cells, 17, wall_cells)
	var first_cells := face.get_used_cells()
	first_cells.sort()
	var first_fingerprint := _fingerprint(face, first_cells)
	_assert_plan(face, first_cells, floor_cells, chasm_cells, ocean_cells, wall_cells)
	var state := face.get_debug_state()
	assert(state["source_ids"] == ROLE_SOURCE_IDS)
	assert(int(state["frontier_cells"]) > 0)
	assert(int(state["painted_cells"]) == first_cells.size())
	assert(float(state["cells_per_frontier"]) >= 1.0)
	assert(int(state["suppressed_pocket_count"]) == 1)
	assert(int(state["wall_lip_frontier_count"]) > 0)
	assert(int(state["wall_excluded_cell_count"]) >= 33)
	assert(not tiny_pocket in first_cells, "Tiny enclosed chasm pocket received full fascia")
	assert(not Vector2i(50, 20) in first_cells, "Fascia painted a later wall cell")
	assert(not Vector2i(50, 19) in first_cells, "Fascia resumed beyond a later wall")
	_assert_wall_lip_roles(face)
	assert(_dictionary_fingerprint(floor_cells) == floor_before)
	assert(_dictionary_fingerprint(chasm_cells) == chasm_before)
	assert(_dictionary_fingerprint(wall_cells) == walls_before)
	var deep_frontiers := 0
	for data_variant: Variant in face.get_debug_paint_plan().values():
		var data := data_variant as Dictionary
		if int(data["distance"]) == 1 and int(data["depth_limit"]) > face.typical_max_depth_tiles:
			deep_frontiers += 1
	assert(deep_frontiers > 0, "Representative fascia has no sparse deep sections")
	assert(deep_frontiers * 2 < int(state["frontier_cells"]), "Deep fascia sections are not sparse")
	for count_key: String in [
		"top_count", "body_01_count", "body_02_count", "body_cracked_count",
		"bottom_count", "bottom_broken_count",
	]:
		assert(int(state[count_key]) > 0, "%s did not appear" % count_key)

	face.configure_from_surface_cells(floor_cells, chasm_cells, 17, wall_cells)
	var repeated_cells := face.get_used_cells()
	repeated_cells.sort()
	assert(repeated_cells == first_cells)
	assert(_fingerprint(face, repeated_cells) == first_fingerprint)

	face.min_depth_tiles = 8
	face.max_depth_tiles = 8
	face.configure_from_surface_cells(floor_cells, chasm_cells, 17, wall_cells)
	var fixed_cells := face.get_used_cells()
	fixed_cells.sort()
	var fixed_fingerprint := _fingerprint(face, fixed_cells)
	face.configure_from_surface_cells(floor_cells, chasm_cells, 71, wall_cells)
	var varied_cells := face.get_used_cells()
	varied_cells.sort()
	assert(varied_cells == fixed_cells, "Cosmetic seed changed fixed-depth topology")
	assert(_fingerprint(face, varied_cells) != fixed_fingerprint)
	var representative_fingerprints: Dictionary = {}
	for representative_seed in [3, 17, 41, 71, 113]:
		face.configure_from_surface_cells(floor_cells, chasm_cells, representative_seed, wall_cells)
		var representative_cells := face.get_used_cells()
		representative_cells.sort()
		_assert_plan(face, representative_cells, floor_cells, chasm_cells, ocean_cells, wall_cells)
		representative_fingerprints[_fingerprint(face, representative_cells)] = true
	assert(representative_fingerprints.size() > 1, "Five representative seeds did not exercise fascia variation")

	print("procgen_void_cliff_face_smoke: PASS cells=%d sources=%d representative_seeds=5" % [first_cells.size(), SOURCE_PATHS.size()])
	quit(0)


func _assert_plan(
	face: ProcgenVoidCliffFace,
	cells: Array[Vector2i],
	floor_cells: Dictionary,
	chasm_cells: Dictionary,
	ocean_cells: Dictionary,
	wall_cells: Dictionary
) -> void:
	var plan := face.get_debug_paint_plan()
	for cell in cells:
		assert(chasm_cells.has(cell))
		assert(not floor_cells.has(cell) and not ocean_cells.has(cell))
		assert(not wall_cells.has(cell), "Void fascia overlaps generated wall at %s" % cell)
		var data := plan[cell] as Dictionary
		var distance := int(data["distance"])
		var depth_limit := int(data["depth_limit"])
		var role := String(data["role"])
		var frontier_cell := data["frontier_cell"] as Vector2i
		var visible_start := data["visible_start_cell"] as Vector2i
		var outward_direction := data["outward_direction"] as Vector2i
		var wall_backed := bool(data["wall_backed"])
		assert(distance >= 1 and distance <= depth_limit)
		# Rays can terminate early at another frontier, a surface boundary, or a
		# later wall even when their authored target depth is larger.
		assert(depth_limit >= 1 and depth_limit <= face.max_depth_tiles)
		assert(outward_direction in CARDINALS)
		assert(cell == visible_start + outward_direction * (distance - 1), "Fascia spread laterally from its visible start normal")
		assert(floor_cells.has(frontier_cell - outward_direction), "Frontier normal lacks a corresponding floor edge")
		assert(face.get_cell_source_id(cell) == int(ROLE_SOURCE_IDS[role]))
		if distance == 1:
			if wall_backed:
				assert(role in ["body_01", "body_02", "body_cracked"])
			else:
				assert(role == "top")
		elif distance == depth_limit:
			assert(role == "bottom" or role == "bottom_broken")
		else:
			assert(role == "body_01" or role == "body_02" or role == "body_cracked")


func _fingerprint(face: ProcgenVoidCliffFace, cells: Array[Vector2i]) -> String:
	var parts: PackedStringArray = []
	for cell in cells:
		parts.append("%d,%d:%d" % [cell.x, cell.y, face.get_cell_source_id(cell)])
	return "|".join(parts)


func _assert_wall_lip_roles(face: ProcgenVoidCliffFace) -> void:
	var plan := face.get_debug_paint_plan()
	var saw_wall_body := false
	var saw_wall_bottom := false
	var saw_exposed_top := false
	for data_variant: Variant in plan.values():
		var data := data_variant as Dictionary
		var role := String(data["role"])
		if bool(data["wall_backed"]):
			if int(data["distance"]) == 1:
				saw_wall_body = role in ["body_01", "body_02", "body_cracked"]
			if int(data["distance"]) == int(data["depth_limit"]):
				saw_wall_bottom = saw_wall_bottom or role in ["bottom", "bottom_broken"]
		elif int(data["distance"]) == 1 and role == "top":
			saw_exposed_top = true
	assert(saw_wall_body, "Wall-backed fascia did not begin with a body role")
	assert(saw_wall_bottom, "Wall-backed fascia did not terminate with a bottom role")
	assert(saw_exposed_top, "Unwalled frontier did not retain its top role")


func _dictionary_fingerprint(cells: Dictionary) -> String:
	var rows := PackedStringArray()
	for cell_variant: Variant in cells.keys():
		var cell := cell_variant as Vector2i
		rows.append("%d,%d:%s" % [cell.x, cell.y, var_to_str(cells[cell])])
	rows.sort()
	return "|".join(rows)
