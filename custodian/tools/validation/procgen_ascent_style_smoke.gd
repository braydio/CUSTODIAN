extends SceneTree

const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const TerrainBuilderScript := preload("res://game/world/procgen/terrain/terrain_builder.gd")


func _init() -> void:
	var profile = WorldProgressProfileScript.load_from_path("res://content/procgen/world_profiles/sundered_keep_ascent.json")
	assert(profile.bands.size() >= 4)
	var floor_cells: Array[Vector2i] = []
	for x in range(0, 320):
		for y in range(0, 32):
			floor_cells.append(Vector2i(x, y))
	var context := {
		"seed": 12345,
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"start_cell": Vector2i(4, 16),
		"required_cells": [Vector2i(4, 16), Vector2i(140, 16), Vector2i(300, 16)],
		"enable_industrial_platform": false,
		"enable_mountain_boundary": false,
		"enable_ascent_route": true,
		"world_progress_profile": profile,
	}
	var first := _build(context)
	var second := _build(context)
	assert(bool(first.get("connectivity", {}).get("ok", false)))
	assert(int(first.get("debug_summary", {}).get("max_height", 0)) > 0)
	assert(_signature(first) == _signature(second))
	assert(String(profile.get_cell_progress(Vector2i(300, 16), 12345).get("band_id", "")) == "slog_ascent")
	print("procgen_ascent_style_smoke: PASS")
	quit()


func _build(context: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	return TerrainBuilderScript.new().build_terrain(Rect2i(Vector2i.ZERO, Vector2i(320, 32)), rng, context)


func _signature(result: Dictionary) -> String:
	return str(result.get("debug_regions", [])) + str(result.get("debug_summary", {}))
