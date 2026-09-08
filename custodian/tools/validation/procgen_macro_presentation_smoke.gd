extends SceneTree

const COMPOSER := preload("res://game/world/procgen/presentation/procgen_macro_presentation_composer.gd")
const CATALOG := preload("res://game/world/procgen/presentation/terrain_stamp_catalog.gd")
const PROFILE := preload("res://game/world/procgen/presentation/terrain_stamp_profile.gd")
const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const MAP_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const PRODUCTION_CATALOG := preload("res://content/procgen/presentation/terrain_stamp_catalog_v1.tres")

var _failed := false


func _init() -> void:
	var profile := _fixture_profile()
	var catalog := CATALOG.new() as TerrainStampCatalog
	catalog.stamps = [profile]
	var context := _fixture_context()
	var before := context.duplicate(true)
	var composer := COMPOSER.new() as ProcgenMacroPresentationComposer
	var production_report: Dictionary = PRODUCTION_CATALOG.validation_report(true)
	_require((production_report.rejected as Array).is_empty(), "production macro catalog has rejected profiles")
	_require((production_report.valid as Array).size() == 9, "production macro catalog does not contain nine depth profiles")
	for production_profile: TerrainStampProfile in production_report.valid:
		_require(production_profile.placement_domain == TerrainStampProfile.PlacementDomain.CHASM, "production depth profile is not CHASM")
		_require(production_profile.depth_band == TerrainStampProfile.DepthBand.BACK, "production depth profile is not BACK")
	var first := composer.build_plan(context, catalog)
	var second := composer.build_plan(context, catalog)
	_require(first == second, "same input and seed changed the normalized plan")
	_require(first.fingerprint == second.fingerprint, "same input changed fingerprint")
	_require(context == before, "planning mutated semantic input")
	_require((first.placements as Array).size() == 1, "fixture did not place one valid stamp")
	_validate_masks(first.placements[0], context)
	_validate_chasm_contract_and_placement(composer)
	_validate_biome_family_selection(composer)

	var empty_catalog := CATALOG.new() as TerrainStampCatalog
	var fallback := composer.build_plan(context, empty_catalog)
	_require((fallback.placements as Array).is_empty(), "empty catalog created a placement")
	_require((fallback.fallback_region_ids as Array).size() == (fallback.regions as Array).size(), "empty catalog did not report every region as fallback")
	_require(context == before, "empty-catalog fallback mutated semantics")

	var scene := MAP_SCENE.instantiate()
	root.add_child(scene)
	var back := scene.get_node("NavigationRegion2D/TerrainPresentationBack") as Node2D
	var ground := scene.get_node("NavigationRegion2D/TerrainPresentationGround") as Node2D
	var front := scene.get_node("NavigationRegion2D/TerrainPresentationFront") as Node2D
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


func _validate_chasm_contract_and_placement(composer: ProcgenMacroPresentationComposer) -> void:
	var profile := _chasm_profile(&"depth_universal_a", &"procgen_depth_universal")
	_require(profile.solid_mask_cells.is_empty() and profile.walkable_overlay_cells.is_empty(), "CHASM fixture unexpectedly owns surface masks")
	_require(profile.validate_contract(false).is_empty(), "valid CHASM profile failed contract")
	var invalid := _chasm_profile(&"depth_invalid", &"procgen_depth_universal")
	invalid.chasm_core_rect = Rect2i(3, 2, 3, 2)
	_require(not invalid.validate_contract(false).is_empty(), "out-of-footprint CHASM core passed contract")
	var catalog := CATALOG.new() as TerrainStampCatalog
	catalog.stamps = [profile]
	var context := _chasm_context(&"scrubland")
	var before := context.duplicate(true)
	var first := composer.build_plan(context, catalog)
	var second := composer.build_plan(context, catalog)
	_require(first.fingerprint == second.fingerprint, "CHASM fingerprint is not deterministic")
	_require((first.placements as Array).size() == 1, "valid CHASM semantics did not place")
	var placement: Dictionary = first.placements[0]
	_require(int(placement.depth_band) == TerrainStampProfile.DepthBand.BACK, "CHASM stamp escaped BACK band")
	_require(not (placement.chasm_cells as Array).is_empty(), "CHASM plan omitted semantic core cells")
	for cell: Vector2i in placement.chasm_cells:
		_require((context.chasm_cells as Dictionary).has(cell), "CHASM plan escaped chasm authority")
	for cell: Vector2i in placement.reveal_probe_cells:
		_require((context.floor_cells as Dictionary).has(cell), "CHASM reveal probe is not explicit live floor semantics")
	_require(context == before, "CHASM planning mutated semantic authority")
	var claimed := context.duplicate(true)
	claimed.reserved_cells = (context.chasm_cells as Dictionary).duplicate()
	_require((composer.build_plan(claimed, catalog).placements as Array).is_empty(), "CHASM stamp overlapped a reserved presentation claim")
	var no_chasm := context.duplicate(true)
	no_chasm.chasm_cells = {}
	_require((composer.build_plan(no_chasm, catalog).placements as Array).is_empty(), "CHASM stamp placed without chasm semantics")
	var alternate_found := false
	var profile_b := _chasm_profile(&"depth_universal_b", &"procgen_depth_universal")
	profile_b.weight = 1
	catalog.stamps = [profile, profile_b]
	var initial_id := String((composer.build_plan(context, catalog).placements as Array)[0].stamp_id)
	for seed: int in range(2, 64):
		context.seed = seed
		if String((composer.build_plan(context, catalog).placements as Array)[0].stamp_id) != initial_id:
			alternate_found = true
			break
	_require(alternate_found, "eligible stamp selection never varied across seeds")


func _validate_biome_family_selection(composer: ProcgenMacroPresentationComposer) -> void:
	var universal := _chasm_profile(&"universal", &"procgen_depth_universal")
	var scrub := _chasm_profile(&"scrub", &"procgen_depth_scrubland", &"scrubland")
	var woodland := _chasm_profile(&"woodland", &"procgen_depth_woodland", &"woodland")
	var catalog := CATALOG.new() as TerrainStampCatalog
	catalog.stamps = [universal, scrub, woodland]
	var allowed := {
		&"scrubland": PackedStringArray(["procgen_depth_universal", "procgen_depth_scrubland"]),
		&"woodland": PackedStringArray(["procgen_depth_universal", "procgen_depth_woodland"]),
		&"wetland": PackedStringArray(["procgen_depth_universal"]),
		&"rocky_upland": PackedStringArray(["procgen_depth_universal"]),
	}
	for biome: StringName in allowed:
		var context := _chasm_context(biome)
		context.families_by_biome = {biome: allowed[biome]}
		for seed: int in range(1, 20):
			context.seed = seed
			var placements: Array = composer.build_plan(context, catalog).placements
			_require(not placements.is_empty(), "depth family fixture produced no placement for %s" % biome)
			if placements.is_empty():
				continue
			var family := String(placements[0].family_id)
			_require(allowed[biome].has(family), "biome %s selected disallowed family %s" % [biome, family])


func _chasm_profile(id: StringName, family: StringName, biome: StringName = &"") -> TerrainStampProfile:
	var image := Image.create_empty(128, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.2, 0.2, 1.0))
	var profile := PROFILE.new() as TerrainStampProfile
	profile.stamp_id = id
	profile.family_id = family
	profile.texture = ImageTexture.create_from_image(image)
	profile.canvas_px = Vector2i(128, 96)
	profile.footprint_size_cells = Vector2i(4, 3)
	profile.placement_domain = TerrainStampProfile.PlacementDomain.CHASM
	profile.chasm_core_rect = Rect2i(1, 1, 2, 2)
	profile.reveal_probe_cells = [Vector2i(1, 0), Vector2i(2, 0)]
	profile.allowed_region_kinds = PackedStringArray(["depth_south_edge"])
	profile.required_biome = biome
	profile.depth_band = TerrainStampProfile.DepthBand.BACK
	profile.claims_dressing_clearance = false
	profile.allow_flip_h = true
	return profile


func _chasm_context(biome: StringName) -> Dictionary:
	var floors: Dictionary = {}
	var chasm: Dictionary = {}
	var biomes: Dictionary = {}
	for x: int in range(2, 10):
		floors[Vector2i(x, 2)] = true
		biomes[Vector2i(x, 2)] = biome
		for y: int in range(3, 7):
			chasm[Vector2i(x, y)] = true
	return {
		"seed": 1,
		"max_stamps": 8,
		"map_bounds": Rect2i(Vector2i.ZERO, Vector2i(12, 8)),
		"floor_cells": floors,
		"wall_cells": {},
		"chasm_cells": chasm,
		"terrain_result": {"traversal_by_cell": {}},
		"biome_id_by_cell": biomes,
		"protected_cells": {}, "required_cells": {}, "reserved_cells": {},
		"ingress_clearance_cells": {}, "region_kind_by_cell": {},
		"families": PackedStringArray(["procgen_depth_universal"]),
		"families_by_biome": {biome: PackedStringArray(["procgen_depth_universal"])},
		"min_region_cells_by_biome": {biome: 0},
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
