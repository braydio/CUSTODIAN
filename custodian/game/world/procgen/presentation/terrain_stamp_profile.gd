extends Resource
class_name TerrainStampProfile

enum DepthBand {
	BACK,
	GROUND,
	FRONT,
}

@export var stamp_id: StringName
@export var family_id: StringName
@export var texture: Texture2D
@export var canvas_px: Vector2i
@export var pivot_px: Vector2
@export var footprint_size_cells: Vector2i
@export var solid_mask_cells: Array[Vector2i] = []
@export var walkable_overlay_cells: Array[Vector2i] = []
@export var reveal_probe_cells: Array[Vector2i] = []
@export var allowed_region_kinds: PackedStringArray
@export var required_biome: StringName = &""
@export_range(1, 65535, 1) var min_region_cells: int = 1
@export var depth_band: DepthBand = DepthBand.BACK
@export_range(1, 100, 1) var weight: int = 1
@export var claims_dressing_clearance: bool = true
@export var allow_flip_h: bool = false


func resolved_reveal_probe_cells() -> Array[Vector2i]:
	if not reveal_probe_cells.is_empty():
		return reveal_probe_cells.duplicate()
	var result: Array[Vector2i] = solid_mask_cells.duplicate()
	for cell: Vector2i in walkable_overlay_cells:
		if not result.has(cell):
			result.append(cell)
	return result


func validate_contract(require_texture: bool = true) -> PackedStringArray:
	var failures := PackedStringArray()
	if stamp_id == &"":
		failures.append("missing_stamp_id")
	if family_id == &"":
		failures.append("missing_family_id")
	if require_texture and texture == null:
		failures.append("null_texture")
	if texture != null and Vector2i(texture.get_size()) != canvas_px:
		failures.append("canvas_texture_mismatch")
	if canvas_px.x <= 0 or canvas_px.y <= 0:
		failures.append("invalid_canvas")
	if footprint_size_cells.x <= 0 or footprint_size_cells.y <= 0:
		failures.append("invalid_footprint")
	if solid_mask_cells.is_empty() and walkable_overlay_cells.is_empty():
		failures.append("empty_semantic_masks")
	var margin := Vector2(canvas_px) * 0.5
	if (
		pivot_px.x < -margin.x or pivot_px.y < -margin.y
		or pivot_px.x > float(canvas_px.x) + margin.x
		or pivot_px.y > float(canvas_px.y) + margin.y
	):
		failures.append("pivot_out_of_bounds")
	for cell: Vector2i in solid_mask_cells + walkable_overlay_cells + reveal_probe_cells:
		if not Rect2i(Vector2i.ZERO, footprint_size_cells).has_point(cell):
			failures.append("mask_cell_out_of_footprint")
			break
	return failures

