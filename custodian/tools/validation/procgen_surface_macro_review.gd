extends SceneTree

const CATALOG := preload("res://content/procgen/presentation/terrain_stamp_catalog_v1.tres")
const OUTPUT := "res://../reports/procgen_surface_macro_rocky_upland"
const CELL_SIZE := 32
const OPERATOR_SIZE := Vector2i(32, 64)
const GRID_COLOR := Color(0.82, 0.88, 0.92, 0.28)
const SOLID_COLOR := Color(0.92, 0.20, 0.16, 0.44)
const OVERLAY_COLOR := Color(0.12, 0.72, 0.92, 0.42)
const PROBE_COLOR := Color(1.0, 0.86, 0.18, 0.92)
const OPERATOR_COLOR := Color(0.86, 0.76, 0.38, 0.92)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output_path)
	var report := {
		"schema": "custodian.procgen_surface_macro_review.v1",
		"family_id": "procgen_surface_rocky_upland",
		"cell_size_px": CELL_SIZE,
		"operator_reference_px": [OPERATOR_SIZE.x, OPERATOR_SIZE.y],
		"profiles": [],
	}
	var failures := PackedStringArray()
	for profile: TerrainStampProfile in CATALOG.stamps:
		if profile.family_id != &"procgen_surface_rocky_upland":
			continue
		var image := profile.texture.get_image().duplicate()
		image.convert(Image.FORMAT_RGBA8)
		_draw_grid(image)
		_draw_cells(image, profile.solid_mask_cells, SOLID_COLOR)
		_draw_cells(image, profile.walkable_overlay_cells, OVERLAY_COLOR)
		_draw_probes(image, profile.reveal_probe_cells)
		_draw_operator_reference(image)
		var filename := "%s_review.png" % profile.stamp_id
		var error: Error = image.save_png(output_path.path_join(filename))
		if error != OK:
			push_error("procgen surface macro review failed to save %s" % filename)
			quit(1)
			return
		var semantic_cells: Array[Vector2i] = profile.solid_mask_cells + profile.walkable_overlay_cells
		var semantic_bounds := _cell_bounds(semantic_cells)
		var probe_bounds := _cell_bounds(profile.reveal_probe_cells)
		if profile.reveal_probe_cells.size() < 5 or profile.reveal_probe_cells.size() > 9:
			failures.append("%s reveal probe count is outside 5-9" % profile.stamp_id)
		if probe_bounds.size.x * 2 < semantic_bounds.size.x or probe_bounds.size.y * 2 < semantic_bounds.size.y:
			failures.append("%s reveal probes do not span the semantic contact footprint" % profile.stamp_id)
		report.profiles.append({
			"stamp_id": String(profile.stamp_id),
			"review": filename,
			"canvas_px": [profile.canvas_px.x, profile.canvas_px.y],
			"footprint_cells": [profile.footprint_size_cells.x, profile.footprint_size_cells.y],
			"solid_mask_cells": profile.solid_mask_cells.size(),
			"walkable_overlay_cells": profile.walkable_overlay_cells.size(),
			"reveal_probe_cells": profile.reveal_probe_cells.size(),
			"semantic_bounds": _rect_json(semantic_bounds),
			"probe_bounds": _rect_json(probe_bounds),
			"pivot_px": [profile.pivot_px.x, profile.pivot_px.y],
		})
	report["failures"] = failures
	var report_file := FileAccess.open(output_path.path_join("review_manifest.json"), FileAccess.WRITE)
	if report_file == null:
		push_error("procgen surface macro review could not write manifest")
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "  ") + "\n")
	print("procgen_surface_macro_review: %s profiles=%d output=%s" % ["PASS" if failures.is_empty() else "FAIL", report.profiles.size(), output_path])
	quit(0 if report.profiles.size() == 10 and failures.is_empty() else 1)


func _cell_bounds(cells: Array[Vector2i]) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _rect_json(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _draw_grid(image: Image) -> void:
	for x: int in range(0, image.get_width(), CELL_SIZE):
		image.fill_rect(Rect2i(x, 0, 1, image.get_height()), GRID_COLOR)
	for y: int in range(0, image.get_height(), CELL_SIZE):
		image.fill_rect(Rect2i(0, y, image.get_width(), 1), GRID_COLOR)


func _draw_cells(image: Image, cells: Array[Vector2i], color: Color) -> void:
	for cell: Vector2i in cells:
		var rect := Rect2i(cell * CELL_SIZE, Vector2i(CELL_SIZE, CELL_SIZE))
		_blend_rect(image, rect, color)


func _draw_probes(image: Image, cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		var center := cell * CELL_SIZE + Vector2i(CELL_SIZE / 2, CELL_SIZE / 2)
		image.fill_rect(Rect2i(center - Vector2i(4, 4), Vector2i(9, 9)), PROBE_COLOR)


func _draw_operator_reference(image: Image) -> void:
	var origin := Vector2i(image.get_width() - OPERATOR_SIZE.x - 8, image.get_height() - OPERATOR_SIZE.y - 8)
	_blend_rect(image, Rect2i(origin, OPERATOR_SIZE), OPERATOR_COLOR)
	image.fill_rect(Rect2i(origin.x, origin.y + 30, OPERATOR_SIZE.x, 2), Color.WHITE)


func _blend_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y: int in range(clipped.position.y, clipped.end.y):
		for x: int in range(clipped.position.x, clipped.end.x):
			image.set_pixel(x, y, image.get_pixel(x, y).blend(color))
