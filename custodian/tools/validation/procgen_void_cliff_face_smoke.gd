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
	assert(face.min_depth_tiles == 3 and face.max_depth_tiles == 8)

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

	face.configure_from_surface_cells(floor_cells, chasm_cells, 17)
	var first_cells := face.get_used_cells()
	first_cells.sort()
	var first_fingerprint := _fingerprint(face, first_cells)
	_assert_plan(face, first_cells, floor_cells, chasm_cells, ocean_cells)
	var state := face.get_debug_state()
	assert(state["source_ids"] == ROLE_SOURCE_IDS)
	for count_key: String in [
		"top_count", "body_01_count", "body_02_count", "body_cracked_count",
		"bottom_count", "bottom_broken_count",
	]:
		assert(int(state[count_key]) > 0, "%s did not appear" % count_key)

	face.configure_from_surface_cells(floor_cells, chasm_cells, 17)
	var repeated_cells := face.get_used_cells()
	repeated_cells.sort()
	assert(repeated_cells == first_cells)
	assert(_fingerprint(face, repeated_cells) == first_fingerprint)

	face.min_depth_tiles = 8
	face.max_depth_tiles = 8
	face.configure_from_surface_cells(floor_cells, chasm_cells, 17)
	var fixed_cells := face.get_used_cells()
	fixed_cells.sort()
	var fixed_fingerprint := _fingerprint(face, fixed_cells)
	face.configure_from_surface_cells(floor_cells, chasm_cells, 71)
	var varied_cells := face.get_used_cells()
	varied_cells.sort()
	assert(varied_cells == fixed_cells, "Cosmetic seed changed fixed-depth topology")
	assert(_fingerprint(face, varied_cells) != fixed_fingerprint)

	print("procgen_void_cliff_face_smoke: PASS cells=%d sources=%d" % [first_cells.size(), SOURCE_PATHS.size()])
	quit(0)


func _assert_plan(
	face: ProcgenVoidCliffFace,
	cells: Array[Vector2i],
	floor_cells: Dictionary,
	chasm_cells: Dictionary,
	ocean_cells: Dictionary
) -> void:
	var plan := face.get_debug_paint_plan()
	for cell in cells:
		assert(chasm_cells.has(cell))
		assert(not floor_cells.has(cell) and not ocean_cells.has(cell))
		var data := plan[cell] as Dictionary
		var distance := int(data["distance"])
		var depth_limit := int(data["depth_limit"])
		var role := String(data["role"])
		assert(distance >= 1 and distance <= depth_limit)
		assert(depth_limit >= 3 and depth_limit <= 8)
		assert(face.get_cell_source_id(cell) == int(ROLE_SOURCE_IDS[role]))
		assert(face.get_cell_source_id(cell) != 45)
		if distance == 1:
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
