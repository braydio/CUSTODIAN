class_name SurfaceMaterialOverlay
extends TileMapLayer

const TILE_SIZE := Vector2i(32, 32)
const BASE_TEXTURE := preload("res://content/tiles/procgen/surfaces/hardened/meridian_hardened_floor_base_v1_32.png")
const TRANSITION_TEXTURE := preload("res://content/tiles/procgen/surfaces/hardened/meridian_hardened_floor_transition_v1_32.png")
const DETAIL_TEXTURE := preload("res://content/tiles/procgen/surfaces/hardened/meridian_hardened_floor_detail_v1_32.png")
const HARDENED_MATERIALS := [&"hardened_civic", &"hardened_industrial"]

var _atlas_source_id := 0

func apply_material_map(material_by_cell: Dictionary) -> void:
	clear()
	# Keep this presentation atlas isolated from the gameplay TileSet.
	tile_set = TileSet.new()
	tile_set.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = BASE_TEXTURE
	atlas.texture_region_size = TILE_SIZE
	for y in range(4):
		for x in range(8):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, _atlas_source_id)
	for cell_value: Variant in material_by_cell.keys():
		if not cell_value is Vector2i:
			continue
		var material := StringName(material_by_cell[cell_value])
		if material not in HARDENED_MATERIALS:
			continue
		var cell := cell_value as Vector2i
		var variant: int = absi(cell.x * 17 + cell.y * 31) % 32
		set_cell(cell, _atlas_source_id, Vector2i(variant % 8, variant / 8), 0)
