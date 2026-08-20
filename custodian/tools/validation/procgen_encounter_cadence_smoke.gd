extends SceneTree

const PLANNER := preload("res://game/world/procgen/encounters/encounter_cadence_planner.gd")
const CLASSIFIER := preload("res://game/world/procgen/playability/playable_pocket_classifier.gd")

func _init() -> void:
	var floor: Dictionary = {}; var pockets: Array[Dictionary] = []
	for index in 7:
		var rect := Rect2i(Vector2i(index * 30, 0), Vector2i(18, 14))
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x): floor[Vector2i(x, y)] = true
		var kind := "safe_pocket" if index == 3 else "faction_site"
		var classified := CLASSIFIER.new().classify([{"kind": kind, "rect": rect, "center": rect.get_center()}], floor)
		var pocket := (classified.pockets as Array)[0] as Dictionary
		if index != 3:
			assert(not (pocket.encounter_spawn_cells as Array).is_empty())
		pocket["ascent_rank"] = index
		pockets.append(pocket)
	var context := {"seed": 17, "playability": {"pockets": pockets, "hard_clearance_cells": {}}, "floor_cells": floor, "spawn_tile": Vector2i.ZERO, "is_runtime_walkable": func(cell: Vector2i) -> bool: return floor.has(cell), "is_valid_spawn_cell": func(cell: Vector2i) -> bool: return floor.has(cell)}
	var first := PLANNER.new().build(context); var second := PLANNER.new().build(context)
	assert(var_to_str(first) == var_to_str(second))
	var last_major := false
	for encounter in first.encounters:
		var pocket := pockets[int(encounter.pocket_index)]
		assert(pocket.role == "combat_pocket")
		assert((pocket.encounter_spawn_cells as Array).has(encounter.anchor_tile))
		assert((pocket.rect as Rect2i).has_point(encounter.home_tile))
		assert(not (first.get("hard_clearance_cells", {}) as Dictionary).has(encounter.anchor_tile))
		assert(not (last_major and encounter.tier == "major")); last_major = encounter.tier == "major"
	var loader_source := FileAccess.get_file_as_string("res://game/systems/core/systems/contract_world_loader.gd")
	var spawner_source := FileAccess.get_file_as_string("res://game/systems/spawning/ambient_enemy_spawner.gd")
	assert(loader_source.find("custodian.procgen_encounter_plan.v1") >= 0)
	assert(loader_source.find("_place_encounter_plan_markers") >= 0 and loader_source.find("_place_legacy_ambient_enemy_markers") >= 0)
	assert(spawner_source.find("leash_radius_tiles") >= 0 and spawner_source.find("behavior_profile_id") >= 0)
	var camp_source := FileAccess.get_file_as_string("res://game/systems/spawning/ambient_enemy_camp.gd")
	assert(camp_source.find("cap - active - pending") >= 0)
	print("procgen_encounter_cadence_smoke: PASS encounters=%d" % first.encounters.size())
	quit(0)
