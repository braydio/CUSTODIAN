extends SceneTree

const COMPOSER := preload("res://game/world/procgen/presentation/procgen_macro_presentation_composer.gd")
const CATALOG := preload("res://game/world/procgen/presentation/terrain_stamp_catalog.gd")
const PROFILE := preload("res://game/world/procgen/presentation/terrain_stamp_profile.gd")
const PLACER := preload("res://game/world/procgen/presentation/terrain_stamp_placer.gd")
const REGION_EXTRACTOR := preload("res://game/world/procgen/presentation/terrain_region_extractor.gd")
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
	_require((production_report.valid as Array).size() == 36, "production macro catalog does not contain thirty-six profiles")
	var production_chasm_count := 0
	var production_surface_count := 0
	for production_profile: TerrainStampProfile in production_report.valid:
		if production_profile.placement_domain == TerrainStampProfile.PlacementDomain.CHASM:
			production_chasm_count += 1
			_require(production_profile.depth_band == TerrainStampProfile.DepthBand.BACK, "production depth profile is not BACK")
		else:
			production_surface_count += 1
	_require(production_chasm_count == 16, "production catalog does not retain sixteen CHASM profiles")
	_require(production_surface_count == 20, "production catalog does not contain twenty SURFACE profiles")
	var first := composer.build_plan(context, catalog)
	var second := composer.build_plan(context, catalog)
	_require(first == second, "same input and seed changed the normalized plan")
	_require(first.fingerprint == second.fingerprint, "same input changed fingerprint")
	_require(context == before, "planning mutated semantic input")
	_require((first.placements as Array).size() == 1, "fixture did not place one valid stamp")
	_validate_masks(first.placements[0], context)
	_validate_chasm_contract_and_placement(composer)
	_validate_biome_family_selection(composer)
	_validate_production_catalog_selection(composer)
	_validate_production_surface_profiles()
	_validate_domain_budgets_and_surface_overlap()
	_validate_surface_biome_isolation()
	_validate_region_biome_ownership(composer)

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


func _validate_domain_budgets_and_surface_overlap() -> void:
	var chasm_profile := _chasm_profile(&"budget_chasm", &"procgen_depth_universal")
	chasm_profile.footprint_size_cells = Vector2i.ONE
	chasm_profile.chasm_core_rect = Rect2i(Vector2i.ZERO, Vector2i.ONE)
	chasm_profile.reveal_probe_cells = [Vector2i.ZERO]
	var surface_profile := _fixture_profile()
	surface_profile.stamp_id = &"budget_surface"
	surface_profile.family_id = &"procgen_surface_rocky_upland"
	surface_profile.footprint_size_cells = Vector2i.ONE
	surface_profile.solid_mask_cells = []
	surface_profile.walkable_overlay_cells = [Vector2i.ZERO]
	surface_profile.reveal_probe_cells = [Vector2i.ZERO]
	var catalog := CATALOG.new() as TerrainStampCatalog
	catalog.stamps = [chasm_profile, surface_profile]
	var regions: Array[Dictionary] = []
	var floor_cells: Dictionary = {}
	var chasm_cells: Dictionary = {}
	var biome_cells: Dictionary = {}
	for index: int in range(9):
		var cell := Vector2i(index + 1, 1)
		floor_cells[cell] = true
		chasm_cells[cell] = true
		biome_cells[cell] = &"rocky_upland"
		regions.append({"region_id": "chasm_%02d" % index, "kind_name": "depth_south_edge", "biome_id": &"rocky_upland", "bounds": Rect2i(cell, Vector2i.ONE), "cell_count": 1, "anchor_candidates": [cell]})
	var surface_cell := Vector2i(12, 1)
	floor_cells[surface_cell] = true
	biome_cells[surface_cell] = &"rocky_upland"
	regions.append({"region_id": "surface", "kind_name": "mountain_wall", "biome_id": &"rocky_upland", "bounds": Rect2i(surface_cell, Vector2i.ONE), "cell_count": 1, "anchor_candidates": [surface_cell]})
	var context := {
		"map_bounds": Rect2i(Vector2i.ZERO, Vector2i(16, 4)),
		"floor_cells": floor_cells, "wall_cells": {}, "chasm_cells": chasm_cells,
		"terrain_result": {"traversal_by_cell": {}}, "biome_id_by_cell": biome_cells,
		"protected_cells": {}, "required_cells": {}, "reserved_cells": {}, "ingress_clearance_cells": {},
		"families": PackedStringArray(["procgen_depth_universal", "procgen_surface_rocky_upland"]),
		"max_stamps_by_domain": {TerrainStampProfile.PlacementDomain.CHASM: 8, TerrainStampProfile.PlacementDomain.SURFACE: 6},
	}
	var before := context.duplicate(true)
	var placer := PLACER.new() as TerrainStampPlacer
	var plan: Dictionary = placer.build_plan(17, regions, catalog, context, 14)
	var chasm_count := 0
	var surface_count := 0
	for placement: Dictionary in plan.placements:
		if int(placement.placement_domain) == TerrainStampProfile.PlacementDomain.CHASM:
			chasm_count += 1
		else:
			surface_count += 1
	_require(chasm_count == 8, "CHASM domain budget was not enforced at eight")
	_require(surface_count == 1, "CHASM budget exhaustion starved a valid SURFACE placement")
	_require((plan.placements as Array).size() <= 14, "overall macro stamp budget was exceeded")
	_require(int(plan.rejection_counts.get("domain_budget_exhausted", 0)) > 0, "domain budget exhaustion was not observable")
	_require(context == before, "domain-budget planning mutated semantic context")
	for placement: Dictionary in plan.placements:
		_require(placement.has("placement_domain"), "normalized placement omitted placement_domain")
	var altered_domain_plan := plan.duplicate(true)
	for placement: Dictionary in altered_domain_plan.placements:
		if int(placement.placement_domain) == TerrainStampProfile.PlacementDomain.CHASM:
			placement.erase("placement_domain")
			break
	_require(placer.plan_fingerprint(altered_domain_plan) != plan.fingerprint, "placement_domain did not affect the plan fingerprint")

	var overlap_regions: Array[Dictionary] = [
		{"region_id": "surface_a", "kind_name": "mountain_wall", "biome_id": &"rocky_upland", "bounds": Rect2i(surface_cell, Vector2i.ONE), "cell_count": 1, "anchor_candidates": [surface_cell]},
		{"region_id": "surface_b", "kind_name": "mountain_wall", "biome_id": &"rocky_upland", "bounds": Rect2i(surface_cell, Vector2i.ONE), "cell_count": 1, "anchor_candidates": [surface_cell]},
	]
	var overlap_plan: Dictionary = placer.build_plan(17, overlap_regions, catalog, context, 14)
	_require((overlap_plan.placements as Array).size() == 1, "overlapping SURFACE stamps both placed")
	_require(int(overlap_plan.rejection_counts.get("surface_presentation_overlap", 0)) > 0, "SURFACE overlap rejection was not observable")

	var offset_surface := _fixture_profile()
	offset_surface.stamp_id = &"offset_surface"
	offset_surface.family_id = &"procgen_surface_rocky_upland"
	offset_surface.footprint_size_cells = Vector2i(8, 8)
	offset_surface.solid_mask_cells = []
	offset_surface.walkable_overlay_cells = [Vector2i(3, 4)]
	offset_surface.reveal_probe_cells = [Vector2i(3, 4), Vector2i(4, 4)]
	var offset_catalog := CATALOG.new() as TerrainStampCatalog
	offset_catalog.stamps = [offset_surface]
	var offset_plan: Dictionary = placer.build_plan(17, [overlap_regions[0]], offset_catalog, context, 1)
	_require((offset_plan.placements as Array).size() == 1, "offset SURFACE semantic anchor did not place")
	_require((offset_plan.placements[0] as Dictionary).origin_cell == surface_cell - Vector2i(3, 4), "SURFACE origin did not align its semantic mask to the region anchor")
	var protected_footprint_context := context.duplicate(true)
	protected_footprint_context.protected_cells = {surface_cell + Vector2i(1, 0): true}
	var protected_footprint_plan: Dictionary = placer.build_plan(17, [overlap_regions[0]], offset_catalog, protected_footprint_context, 1)
	_require((protected_footprint_plan.placements as Array).is_empty(), "giant SURFACE footprint crossed a protected route outside its semantic mask")
	_require(int(protected_footprint_plan.rejection_counts.get("protected_presentation_footprint", 0)) > 0, "protected visual-footprint rejection was not observable")
	for claim_key: String in ["required_cells", "reserved_cells", "ingress_clearance_cells"]:
		var claim_context := context.duplicate(true)
		claim_context[claim_key] = {surface_cell: true}
		var claim_plan: Dictionary = placer.build_plan(17, [overlap_regions[0]], offset_catalog, claim_context, 1)
		_require((claim_plan.placements as Array).is_empty(), "SURFACE semantic cell crossed %s" % claim_key)
		_require(int(claim_plan.rejection_counts.get("protected_surface_claim", 0)) > 0 or int(claim_plan.rejection_counts.get("protected_presentation_footprint", 0)) > 0, "%s claim rejection was not observable" % claim_key)

	var legacy_context := context.duplicate(true)
	legacy_context.erase("max_stamps_by_domain")
	var legacy_plan: Dictionary = placer.build_plan(17, regions, catalog, legacy_context, 14)
	_require((legacy_plan.placements as Array).size() == 10, "missing domain budgets did not preserve legacy overall-limit behavior")


func _validate_surface_biome_isolation() -> void:
	var surface := _fixture_profile()
	surface.family_id = &"procgen_surface_rocky_upland"
	var catalog := CATALOG.new() as TerrainStampCatalog
	catalog.stamps = [surface]
	_require(catalog.filter_profiles(PackedStringArray(["procgen_surface_rocky_upland"]), &"mountain_wall", &"rocky_upland").size() == 1, "rocky surface family is unavailable to rocky_upland")
	for biome: StringName in [&"scrubland", &"woodland", &"wetland"]:
		_require(catalog.filter_profiles(PackedStringArray(["procgen_surface_rocky_upland"]), &"mountain_wall", biome).is_empty(), "rocky surface family leaked into %s" % biome)


func _validate_region_biome_ownership(composer: ProcgenMacroPresentationComposer) -> void:
	var extractor := REGION_EXTRACTOR.new() as TerrainMacroRegionExtractor
	var wall_cells := [Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4)]
	var floors := {Vector2i(4, 5): true, Vector2i(5, 5): true, Vector2i(6, 5): true, Vector2i(7, 5): true}
	var biome_map := {
		Vector2i(4, 5): &"woodland", Vector2i(5, 5): &"woodland",
		Vector2i(6, 5): &"wetland", Vector2i(7, 5): &"wetland",
	}
	var context := {
		"terrain_result": {"regions": [{"kind_name": "mountain_wall", "cells": wall_cells}], "traversal_by_cell": {}},
		"floor_cells": floors, "biome_id_by_cell": biome_map,
		"map_bounds": Rect2i(Vector2i.ZERO, Vector2i(16, 16)),
		"protected_cells": {}, "required_cells": {}, "reserved_cells": {}, "ingress_clearance_cells": {},
		"region_kind_by_cell": {}, "chasm_cells": {},
	}
	var regions := extractor.extract(context)
	_require(regions.size() == 2, "mountain wall was not split into biome-consistent components")
	for region: Dictionary in regions:
		if String(region.get("kind_name", "")) != "mountain_wall":
			continue
		_require(StringName(region.get("biome_id", &"")) != &"rocky_upland", "non-rocky mountain wall was hardcoded to rocky_upland")
	var surface := PRODUCTION_CATALOG.get_profile(&"granite_cliff_mass_south_01")
	var catalog := CATALOG.new() as TerrainStampCatalog
	catalog.stamps = [surface]
	var woodland_region: Dictionary = {}
	for region: Dictionary in regions:
		if region.get("biome_id", &"") == &"woodland":
			woodland_region = region
	_require(not woodland_region.is_empty(), "woodland mountain wall component was not emitted")
	var wall_authority: Dictionary = {}
	for cell: Vector2i in wall_cells:
		wall_authority[cell] = true
	var plan_context := {
		"seed": 41, "max_stamps": 1, "map_bounds": Rect2i(Vector2i.ZERO, Vector2i(64, 64)),
		"floor_cells": {}, "wall_cells": wall_authority, "chasm_cells": {},
		"terrain_result": {"traversal_by_cell": {}, "regions": [woodland_region]}, "biome_id_by_cell": biome_map,
		"protected_cells": {}, "required_cells": {}, "reserved_cells": {}, "ingress_clearance_cells": {},
		"region_kind_by_cell": {}, "families": PackedStringArray(["procgen_surface_rocky_upland"]),
		"families_by_biome": {&"woodland": PackedStringArray(["procgen_surface_rocky_upland"])},
		"min_region_cells_by_biome": {&"woodland": 0},
	}
	var plan := composer.build_plan(plan_context, catalog)
	_require((plan.placements as Array).is_empty(), "woodland mountain wall received Rocky Upland SURFACE art")


func _validate_production_surface_profiles() -> void:
	var cliff_ids := PackedStringArray([
		"granite_cliff_mass_south_01", "granite_cliff_mass_south_02",
		"granite_cliff_mass_east_01", "granite_cliff_mass_west_01",
		"granite_cliff_corner_se_01", "granite_cliff_corner_sw_01",
	])
	var shelf_ids := PackedStringArray([
		"granite_shelf_large_01", "granite_shelf_large_02", "granite_shelf_small_01",
	])
	var surface_ids := cliff_ids.duplicate()
	surface_ids.append_array(shelf_ids)
	surface_ids.append("scree_overlay_01")
	for stamp_id: String in surface_ids:
		var profile := PRODUCTION_CATALOG.get_profile(StringName(stamp_id))
		_require(profile != null, "missing Rocky Upland SURFACE profile %s" % stamp_id)
		if profile == null:
			continue
		_require(profile.family_id == &"procgen_surface_rocky_upland", "surface profile has wrong family %s" % stamp_id)
		_require(profile.placement_domain == TerrainStampProfile.PlacementDomain.SURFACE, "surface profile has wrong domain %s" % stamp_id)
		_require(profile.required_biome == &"rocky_upland", "surface profile has wrong biome %s" % stamp_id)
		_require(not profile.allow_flip_h, "surface profile permits horizontal flip %s" % stamp_id)
		_require(profile.reveal_probe_cells.size() >= 5 and profile.reveal_probe_cells.size() <= 9, "surface profile reveal probe count is outside 5-9 %s" % stamp_id)
		_require(not profile.resolved_reveal_probe_cells().is_empty(), "surface profile has no reveal probes %s" % stamp_id)
		_require(profile.solid_mask_cells.size() + profile.walkable_overlay_cells.size() >= 10, "surface profile regressed to a placeholder-scale semantic mask %s" % stamp_id)
		if cliff_ids.has(stamp_id):
			_require(profile.allowed_region_kinds == PackedStringArray(["mountain_wall"]), "cliff profile has wrong region kind %s" % stamp_id)
			_require(profile.depth_band == TerrainStampProfile.DepthBand.BACK, "cliff profile has wrong depth band %s" % stamp_id)
			_require(not profile.solid_mask_cells.is_empty() and profile.walkable_overlay_cells.is_empty(), "cliff profile semantic masks are invalid %s" % stamp_id)
			_require(profile.claims_dressing_clearance, "cliff profile does not claim dressing clearance %s" % stamp_id)
		else:
			_require(profile.allowed_region_kinds == PackedStringArray(["rocky_upland_floor"]), "ground profile has wrong region kind %s" % stamp_id)
			_require(profile.depth_band == TerrainStampProfile.DepthBand.GROUND, "ground profile has wrong depth band %s" % stamp_id)
			_require(profile.solid_mask_cells.is_empty() and not profile.walkable_overlay_cells.is_empty(), "ground profile semantic masks are invalid %s" % stamp_id)
			_require(profile.claims_dressing_clearance == (stamp_id != "scree_overlay_01"), "ground profile has wrong dressing clearance %s" % stamp_id)

	for biome: StringName in [&"scrubland", &"woodland", &"wetland"]:
		var leaked := PRODUCTION_CATALOG.filter_profiles(PackedStringArray(["procgen_surface_rocky_upland"]), &"mountain_wall", biome)
		_require(leaked.is_empty(), "production Rocky Upland SURFACE profiles leaked into %s" % biome)


func _validate_production_catalog_selection(composer: ProcgenMacroPresentationComposer) -> void:
	var follow_on := {
		&"woodland_overgrown_works_v1": &"woodland",
		&"wetland_flooded_basin_v1": &"wetland",
		&"wetland_reed_channels_v1": &"wetland",
		&"wetland_drowned_service_platform_v1": &"wetland",
		&"rocky_upland_cliff_bowl_v1": &"rocky_upland",
		&"rocky_upland_talus_ravine_v1": &"rocky_upland",
		&"rocky_upland_exposed_ledge_v1": &"rocky_upland",
	}
	for stamp_id: StringName in follow_on:
		var profile := PRODUCTION_CATALOG.get_profile(stamp_id)
		_require(profile != null, "missing follow-on production profile %s" % stamp_id)
		if profile == null:
			continue
		_require(profile.family_id == &"procgen_depth_chunks", "follow-on profile has wrong family %s" % stamp_id)
		_require(profile.required_biome == follow_on[stamp_id], "follow-on profile has wrong biome %s" % stamp_id)
		_require(profile.placement_domain == TerrainStampProfile.PlacementDomain.CHASM, "follow-on profile is not CHASM %s" % stamp_id)
		_require(profile.depth_band == TerrainStampProfile.DepthBand.BACK, "follow-on profile is not BACK %s" % stamp_id)
		_require(not profile.claims_dressing_clearance, "follow-on profile claims dressing clearance %s" % stamp_id)
	var expected := {
		&"woodland": {"families": PackedStringArray(["procgen_depth_universal", "procgen_depth_woodland", "procgen_depth_chunks"]), "allow": [&"woodland_overgrown_works_v1"], "deny": [&"wetland_flooded_basin_v1", &"wetland_reed_channels_v1", &"wetland_drowned_service_platform_v1", &"rocky_upland_cliff_bowl_v1", &"rocky_upland_talus_ravine_v1", &"rocky_upland_exposed_ledge_v1"]},
		&"wetland": {"families": PackedStringArray(["procgen_depth_universal", "procgen_depth_chunks"]), "allow": [&"wetland_flooded_basin_v1", &"wetland_reed_channels_v1", &"wetland_drowned_service_platform_v1"], "deny": [&"woodland_overgrown_works_v1", &"rocky_upland_cliff_bowl_v1", &"rocky_upland_talus_ravine_v1", &"rocky_upland_exposed_ledge_v1", &"dry_basin_v1", &"wash_channel_v1", &"service_scar_v1"]},
		&"rocky_upland": {"families": PackedStringArray(["procgen_depth_universal", "procgen_depth_chunks"]), "allow": [&"rocky_upland_cliff_bowl_v1", &"rocky_upland_talus_ravine_v1", &"rocky_upland_exposed_ledge_v1"], "deny": [&"woodland_overgrown_works_v1", &"wetland_flooded_basin_v1", &"wetland_reed_channels_v1", &"wetland_drowned_service_platform_v1", &"dry_basin_v1", &"wash_channel_v1", &"service_scar_v1"]},
		&"scrubland": {"families": PackedStringArray(["procgen_depth_universal", "procgen_depth_scrubland"]), "allow": [], "deny": [&"woodland_overgrown_works_v1", &"wetland_flooded_basin_v1", &"wetland_reed_channels_v1", &"wetland_drowned_service_platform_v1", &"rocky_upland_cliff_bowl_v1", &"rocky_upland_talus_ravine_v1", &"rocky_upland_exposed_ledge_v1"]},
	}
	for biome: StringName in expected:
		var filtered := PRODUCTION_CATALOG.filter_profiles(expected[biome]["families"], &"depth_south_edge", biome)
		var ids := {}
		for profile: TerrainStampProfile in filtered:
			ids[profile.stamp_id] = true
		for stamp_id: StringName in expected[biome].allow:
			_require(ids.has(stamp_id), "%s cannot see expected production stamp %s" % [biome, stamp_id])
		for stamp_id: StringName in expected[biome].deny:
			_require(not ids.has(stamp_id), "%s leaked production stamp %s" % [biome, stamp_id])
		if biome == &"scrubland":
			for stamp_id: StringName in ids:
				var scrub_profile := PRODUCTION_CATALOG.get_profile(stamp_id)
				_require(scrub_profile.family_id != &"procgen_depth_chunks", "scrubland gained follow-on family")
		var context := _production_chasm_context(biome) if biome != &"scrubland" else _chasm_context(biome)
		var before := context.duplicate(true)
		context.families = expected[biome]["families"]
		context.families_by_biome = {biome: expected[biome]["families"]}
		before.families = expected[biome]["families"]
		before.families_by_biome = {biome: expected[biome]["families"]}
		var first := composer.build_plan(context, PRODUCTION_CATALOG)
		var second := composer.build_plan(context, PRODUCTION_CATALOG)
		_require(first.fingerprint == second.fingerprint, "%s production selection is not deterministic" % biome)
		_require(context == before, "%s production planning changed semantic context" % biome)
		if biome != &"scrubland":
			var selected_ids := {}
			for seed: int in range(1, 33):
				context.seed = seed
				var plan := composer.build_plan(context, PRODUCTION_CATALOG)
				_require(not (plan.placements as Array).is_empty(), "%s production context did not resolve a depth placement" % biome)
				if not (plan.placements as Array).is_empty():
					var placement: Dictionary = plan.placements[0]
					_require(placement.biome_id == biome, "%s production placement selected another biome" % biome)
					selected_ids[placement.stamp_id] = true
			_require(selected_ids.size() > 1, "%s production eligible selection never varied" % biome)


func _production_chasm_context(biome: StringName) -> Dictionary:
	var floors: Dictionary = {}
	var chasm: Dictionary = {}
	var biomes: Dictionary = {}
	for x: int in range(6, 34):
		var floor_cell := Vector2i(x, 2)
		floors[floor_cell] = true
		biomes[floor_cell] = biome
		for y: int in range(3, 14):
			chasm[Vector2i(x, y)] = true
	return {
		"seed": 1, "max_stamps": 8,
		"map_bounds": Rect2i(Vector2i.ZERO, Vector2i(40, 16)),
		"floor_cells": floors, "wall_cells": {}, "chasm_cells": chasm,
		"terrain_result": {"traversal_by_cell": {}},
		"biome_id_by_cell": biomes,
		"protected_cells": {}, "required_cells": {}, "reserved_cells": {},
		"ingress_clearance_cells": {}, "region_kind_by_cell": {},
		"families": PackedStringArray(["procgen_depth_universal", "procgen_depth_chunks"]),
		"families_by_biome": {biome: PackedStringArray(["procgen_depth_universal", "procgen_depth_chunks"])},
		"min_region_cells_by_biome": {biome: 0},
	}


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
