extends SceneTree

const IDS := preload("res://game/world/procgen/surfaces/surface_material_ids.gd")
const RESOLVER := preload("res://game/world/procgen/surfaces/surface_material_resolver.gd")
const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")

var _failed := false

func _init() -> void:
	var floor_cells := {
		Vector2i(1, 1): true, Vector2i(2, 1): true, Vector2i(3, 1): true,
		Vector2i(4, 1): true, Vector2i(5, 1): true, Vector2i(6, 1): true,
		Vector2i(7, 1): true, Vector2i(8, 1): true, Vector2i(9, 1): true, Vector2i(10, 1): true,
	}
	var before := floor_cells.duplicate(true)
	var context := {
		"floor_cells": floor_cells,
		"wall_cells": {Vector2i(8, 1): true},
		"chasm_cells": {Vector2i(7, 1): true},
		"biome_by_cell": {
			Vector2i(1, 1): &"rocky_upland", Vector2i(2, 1): &"wetland",
			Vector2i(3, 1): &"scrubland", Vector2i(4, 1): &"rocky_upland",
			Vector2i(5, 1): &"wetland", Vector2i(6, 1): &"scrubland",
		},
		"region_kind_by_cell": {
			Vector2i(2, 1): "parking_zone", Vector2i(3, 1): "industrial_platform",
			Vector2i(4, 1): "portal_plaza", Vector2i(5, 1): "main_road",
			Vector2i(6, 1): "authored_scene_floor",
		},
		"region_data_by_cell": {},
		"parking_cells": {Vector2i(2, 1): true},
		"road_cells": {Vector2i(5, 1): true},
		"path_cells": {}, "bridge_cells": {Vector2i(10, 1): true},
		"reserved_cells": {}, "authored_cells": {Vector2i(6, 1): true},
	}
	var resolver := RESOLVER.new()
	var first: Dictionary = resolver.resolve(context)
	var second: Dictionary = resolver.resolve(context)
	_require(first.fingerprint == second.fingerprint, "same material input changed fingerprint")
	_require(first.material_by_cell == second.material_by_cell, "same material input changed classification")
	_require(context.floor_cells == before, "material resolution mutated floor authority")
	_require(first.material_by_cell.get(Vector2i(1, 1)) == IDS.NATURAL_ROCK, "rocky natural floor was not natural_rock")
	_require(first.material_by_cell.get(Vector2i(2, 1)) == IDS.HARDENED_CIVIC, "parking did not override wet biome")
	_require(first.material_by_cell.get(Vector2i(3, 1)) == IDS.HARDENED_INDUSTRIAL, "industrial platform did not override biome")
	_require(first.material_by_cell.get(Vector2i(4, 1)) == IDS.HARDENED_CIVIC, "civic plaza did not override biome")
	_require(first.material_by_cell.get(Vector2i(5, 1)) == IDS.RUINED_ROAD, "road did not resolve ruined_road")
	_require(first.material_by_cell.get(Vector2i(6, 1)) == IDS.AUTHORED_LANDMARK, "authored surface did not win precedence")
	_require(first.material_by_cell.get(Vector2i(9, 1)) == IDS.NATURAL_SOFT, "ordinary natural floor was not natural_soft")
	_require(first.material_by_cell.get(Vector2i(10, 1)) == IDS.BRIDGE, "bridge did not win precedence")
	_require(not first.material_by_cell.has(Vector2i(7, 1)) and not first.material_by_cell.has(Vector2i(8, 1)), "wall/chasm received floor material")
	_require(first.counts.get(IDS.WET_GROUND, 0) == 0, "constructed cells fell through to wet ground")

	var source := FileAccess.get_file_as_string("res://game/world/procgen/proc_gen_tilemap.gd")
	_require(source.contains("get_surface_material_at_tile(cell)"), "floor clusters do not consult surface materials")
	_require(source.contains("SURFACE_MATERIAL_IDS.HARDENED_CIVIC"), "constructed cluster skip policy is missing")
	var scene := MAP_SCENE.instantiate()
	root.add_child(scene)
	var overlay := scene.get_node_or_null("NavigationRegion2D/SurfaceMaterialOverlay") as TileMapLayer
	_require(overlay != null, "surface material overlay layer is missing")
	if overlay != null:
		_require(not overlay.collision_enabled, "surface material overlay owns collision")
		_require(not overlay.navigation_enabled, "surface material overlay owns navigation")
	scene.queue_free()
	if _failed:
		quit(1)
		return
	print("procgen_surface_material_smoke: PASS fingerprint=%s counts=%s" % [first.fingerprint, str(first.counts)])
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("procgen_surface_material_smoke: " + message)
