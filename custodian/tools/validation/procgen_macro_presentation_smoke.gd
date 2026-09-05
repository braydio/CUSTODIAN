extends SceneTree

const COMPOSER := preload("res://game/world/procgen/presentation/procgen_macro_presentation_composer.gd")
const CATALOG := preload("res://game/world/procgen/presentation/terrain_stamp_catalog.gd")
const PROFILE := preload("res://game/world/procgen/presentation/terrain_stamp_profile.gd")
const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const MAP_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")

var _failed := false


func _init() -> void:
	var profile := _fixture_profile()
	var catalog := CATALOG.new() as TerrainStampCatalog
	catalog.stamps = [profile]
	var context := _fixture_context()
	var before := context.duplicate(true)
	var composer := COMPOSER.new() as ProcgenMacroPresentationComposer
	var first := composer.build_plan(context, catalog)
	var second := composer.build_plan(context, catalog)
	_require(first == second, "same input and seed changed the normalized plan")
	_require(first.fingerprint == second.fingerprint, "same input changed fingerprint")
	_require(context == before, "planning mutated semantic input")
	_require((first.placements as Array).size() == 1, "fixture did not place one valid stamp")
	_validate_masks(first.placements[0], context)

	var empty_catalog := CATALOG.new() as TerrainStampCatalog
	var fallback := composer.build_plan(context, empty_catalog)
	_require((fallback.placements as Array).is_empty(), "empty catalog created a placement")
	_require((fallback.fallback_region_ids as Array).size() == (fallback.regions as Array).size(), "empty catalog did not report every region as fallback")
	_require(context == before, "empty-catalog fallback mutated semantics")

	var scene := MAP_SCENE.instantiate()
	root.add_child(scene)
	var back := scene.get_node("NavigationRegion2D/MacroPresentationBack") as Node2D
	var ground := scene.get_node("NavigationRegion2D/MacroPresentationGround") as Node2D
	var front := scene.get_node("NavigationRegion2D/MacroPresentationFront") as Node2D
	var floor := scene.get_node("NavigationRegion2D/Floor") as TileMapLayer
	var walls := scene.get_node("NavigationRegion2D/Walls") as TileMapLayer
	var roots := {"back": back, "ground": ground, "front": front}
	first["streaming_enabled"] = true
	var applied := composer.apply_plan(first, catalog, roots, floor, walls, back.global_transform.get_scale())
	_require(int(applied.sprite_count) == 1, "composer did not create fixture sprite")
	_require(back.get_child_count() == 1 and ground.get_child_count() == 0 and front.get_child_count() == 0, "stamp used the wrong depth root")
	var sprite := back.get_child(0) as Sprite2D
	_require(sprite != null and not sprite.visible, "streaming stamp should start hidden")
	_require(not sprite.centered, "macro sprite must use authored top-left positioning")
	_require(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "macro sprite filtering is not nearest")
	_require(sprite.offset == -profile.pivot_px, "macro sprite pivot was not applied")
	_require(sprite.get_child_count() == 0, "macro sprite unexpectedly owns collision children")
	_require(sprite.global_transform.get_scale().is_equal_approx(Vector2.ONE), "root scale was not compensated")

	_paint_fixture_cell(walls, Vector2i(2, 2))
	composer.refresh_streaming_visibility(first, roots, floor, walls)
	_require(not sprite.visible, "partial reveal exposed the macro stamp")
	_paint_fixture_cell(floor, Vector2i(3, 2))
	composer.refresh_streaming_visibility(first, roots, floor, walls)
	_require(sprite.visible, "complete reveal did not expose the macro stamp")
	floor.erase_cell(Vector2i(3, 2))
	composer.refresh_streaming_visibility(first, roots, floor, walls)
	_require(not sprite.visible, "unload did not hide the macro stamp")

	var host := MAP_SCRIPT.new() as ProcGenTilemap
	host._macro_presentation_dressing_clearance_cells[Vector2i(9, 9)] = true
	_require(host.is_inside_macro_presentation_dressing_clearance(Vector2i(9, 9)), "macro clearance lookup failed")
	_require(not host._runtime_prop_blocker_cells.has(Vector2i(9, 9)), "macro clearance created a runtime blocker")
	_validate_pipeline_order()

	scene.queue_free()
	host.free()
	if _failed:
		quit(1)
		return
	print("procgen_macro_presentation_smoke: PASS fingerprint=%s" % first.fingerprint)
	quit(0)


func _fixture_profile() -> TerrainStampProfile:
	var image := Image.create_empty(64, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.4, 0.4, 1.0))
	var profile := PROFILE.new() as TerrainStampProfile
	profile.stamp_id = &"fixture_granite_01"
	profile.family_id = &"granite_cliff_mass"
	profile.texture = ImageTexture.create_from_image(image)
	profile.canvas_px = Vector2i(64, 32)
	profile.pivot_px = Vector2(16, 16)
	profile.footprint_size_cells = Vector2i(2, 1)
	profile.solid_mask_cells = [Vector2i(0, 0)]
	profile.walkable_overlay_cells = [Vector2i(1, 0)]
	profile.allowed_region_kinds = PackedStringArray(["mountain_wall"])
	profile.required_biome = &"rocky_upland"
	profile.depth_band = TerrainStampProfile.DepthBand.BACK
	return profile


func _fixture_context() -> Dictionary:
	return {
		"seed": 4421,
		"max_stamps": 12,
		"map_bounds": Rect2i(Vector2i.ZERO, Vector2i(12, 12)),
		"floor_cells": {Vector2i(3, 2): true},
		"wall_cells": {Vector2i(2, 2): true},
		"terrain_result": {
			"traversal_by_cell": {Vector2i(2, 2): "blocked", Vector2i(3, 2): "walkable"},
			"regions": [{"kind_name": "mountain_wall", "cells": [Vector2i(2, 2), Vector2i(3, 2)]}],
		},
		"biome_id_by_cell": {Vector2i(3, 2): &"rocky_upland"},
		"protected_cells": {},
		"required_cells": {},
		"reserved_cells": {},
		"ingress_clearance_cells": {},
		"region_kind_by_cell": {},
		"families": PackedStringArray(["granite_cliff_mass"]),
		"min_region_cells": 0,
	}


func _validate_masks(placement: Dictionary, context: Dictionary) -> void:
	for cell: Vector2i in placement.solid_cells:
		_require((context.wall_cells as Dictionary).has(cell), "solid mask escaped blocked authority")
	for cell: Vector2i in placement.overlay_cells:
		_require((context.floor_cells as Dictionary).has(cell), "overlay mask escaped walkable authority")


func _paint_fixture_cell(layer: TileMapLayer, cell: Vector2i) -> void:
	layer.set_cell(cell, 10, Vector2i.ZERO, 0)


func _validate_pipeline_order() -> void:
	var source := FileAccess.get_file_as_string("res://game/world/procgen/proc_gen_tilemap.gd")
	var fill_start := source.find("func _fill_tilemaps()")
	var fill_end := source.find("func ", fill_start + 20)
	var body := source.substr(fill_start, fill_end - fill_start)
	var final_capture := body.rfind("_capture_generated_tile_state(map_size)")
	var biome := body.find("_build_biome_field()")
	var macro := body.find("_build_macro_presentation_plan(map_size)")
	var streaming := body.find("_prepare_streaming_reveal()")
	_require(final_capture >= 0 and final_capture < biome, "biome field precedes final structural capture")
	_require(biome < macro and macro < streaming, "macro plan is not between final biome and streaming setup")
	var promotion_start := source.find("func promote_evaluated_candidate_to_final()")
	var promotion_end := source.find("func _fill_tilemaps()", promotion_start)
	var promotion := source.substr(promotion_start, promotion_end - promotion_start)
	_require(promotion.find("_rebuild_macro_presentation(map_size)") < promotion.find("_generate_foliage(map_size)"), "promotion builds foliage before macro presentation")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("procgen_macro_presentation_smoke: " + message)
