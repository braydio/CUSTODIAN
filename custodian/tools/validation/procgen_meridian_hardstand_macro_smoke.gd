extends SceneTree

const CATALOG := preload("res://content/procgen/presentation/terrain_stamp_catalog_v1.tres")
const PROFILE := preload("res://game/world/procgen/presentation/terrain_stamp_profile.gd")
const EXTRACTOR := preload("res://game/world/procgen/presentation/terrain_region_extractor.gd")
const PLACER := preload("res://game/world/procgen/presentation/terrain_stamp_placer.gd")
const CATALOG_SCRIPT := preload("res://game/world/procgen/presentation/terrain_stamp_catalog.gd")

var failed := false

func _init() -> void:
	var report: Dictionary = CATALOG.validation_report(true)
	_check(report.rejected.is_empty(), "catalog has rejected profiles")
	_check(report.valid.size() == 36, "catalog total is not 36")
	var meridian: Array[TerrainStampProfile] = []
	for profile: TerrainStampProfile in report.valid:
		if profile.family_id != &"procgen_surface_meridian_hardstand":
			continue
		meridian.append(profile)
		_check(profile.placement_domain == PROFILE.PlacementDomain.SURFACE, "%s is not SURFACE" % profile.stamp_id)
		_check(profile.depth_band == PROFILE.DepthBand.GROUND, "%s is not GROUND" % profile.stamp_id)
		_check(profile.required_biome == &"", "%s has biome restriction" % profile.stamp_id)
		_check(not profile.allow_flip_h, "%s allows flipping" % profile.stamp_id)
		_check(profile.solid_mask_cells.is_empty(), "%s has solid cells" % profile.stamp_id)
		_check(not profile.walkable_overlay_cells.is_empty(), "%s has no overlay mask" % profile.stamp_id)
		_check(profile.reveal_probe_cells.size() == 8, "%s does not have eight probes" % profile.stamp_id)
	_check(meridian.size() == 10, "Meridian profile count is not 10")

	var extractor := EXTRACTOR.new()
	var material_cells := {Vector2i(1, 1): &"hardened_civic", Vector2i(2, 1): &"hardened_civic", Vector2i(5, 1): &"hardened_industrial", Vector2i(5, 2): &"hardened_industrial", Vector2i(6, 1): &"natural_soft"}
	var floor_cells := {}
	for cell: Vector2i in material_cells.keys(): floor_cells[cell] = true
	var regions: Array[Dictionary] = extractor.extract({"floor_cells": floor_cells, "surface_material_by_cell": material_cells, "terrain_result": {"regions": [], "traversal_by_cell": {}}, "biome_id_by_cell": {}, "map_bounds": Rect2i(0, 0, 8, 8)})
	var kinds := {}
	for region: Dictionary in regions: kinds[String(region.kind_name)] = true
	_check(kinds.has("hardened_civic_floor"), "civic material region missing")
	_check(kinds.has("hardened_industrial_floor"), "industrial material region missing")
	_check(kinds.has("hardstand_natural_boundary"), "hardstand boundary region missing")

	var profile := PROFILE.new()
	profile.stamp_id = &"meridian_fixture"
	profile.family_id = &"procgen_surface_meridian_hardstand"
	profile.canvas_px = Vector2i(1024, 1024)
	profile.texture = load("res://content/tiles/procgen_macro/runtime/meridian_hardstand/meridian_hardstand_corner_01.png")
	profile.footprint_size_cells = Vector2i(1, 1)
	profile.walkable_overlay_cells = [Vector2i.ZERO]
	profile.reveal_probe_cells = [Vector2i.ZERO]
	profile.allowed_region_kinds = PackedStringArray(["hardened_civic_floor"])
	profile.allowed_surface_materials = PackedStringArray(["hardened_civic"])
	profile.min_region_cells = 1
	var catalog := CATALOG_SCRIPT.new()
	catalog.stamps = [profile]
	var base := {"seed": 7, "map_bounds": Rect2i(0, 0, 4, 4), "floor_cells": {Vector2i.ZERO: true}, "wall_cells": {}, "chasm_cells": {}, "terrain_result": {"traversal_by_cell": {Vector2i.ZERO: "walkable"}}, "families_by_biome": {&"": PackedStringArray(["procgen_surface_meridian_hardstand"])} , "surface_material_by_cell": {Vector2i.ZERO: &"natural_soft"}, "surface_claim_cells": {}, "protected_cells": {}, "required_cells": {}, "reserved_cells": {}, "ingress_clearance_cells": {}, "max_stamps_by_family": {&"procgen_surface_meridian_hardstand": 2}}
	var plan := PLACER.new().build_plan(7, [{"region_id": "r", "kind_name": "hardened_civic_floor", "biome_id": &"", "bounds": Rect2i(0, 0, 1, 1), "cell_count": 1, "anchor_candidates": [Vector2i.ZERO]}], catalog, base, 16)
	_check(plan.placements.is_empty(), "wrong material was accepted")
	_check(int(plan.rejection_counts.get("surface_material_mismatch", 0)) > 0, "wrong material rejection missing")
	base.surface_material_by_cell[Vector2i.ZERO] = &"hardened_civic"
	base.surface_claim_cells[Vector2i.ZERO] = true
	plan = PLACER.new().build_plan(7, [{"region_id": "r", "kind_name": "hardened_civic_floor", "biome_id": &"", "bounds": Rect2i(0, 0, 1, 1), "cell_count": 1, "anchor_candidates": [Vector2i.ZERO]}], catalog, base, 16)
	_check(plan.placements.size() == 1, "matching constructed surface claim was rejected")

	if failed: print("procgen_meridian_hardstand_macro_smoke: FAIL"); quit(1)
	print("procgen_meridian_hardstand_macro_smoke: PASS profiles=10 catalog=36 regions=%s" % [kinds.keys()])
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("procgen_meridian_hardstand_macro_smoke: " + message)
