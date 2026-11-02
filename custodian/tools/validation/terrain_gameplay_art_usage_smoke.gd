extends SceneTree

const PROCGEN_TILEMAP := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const TILESET_PATH := "res://content/tiles/tilesets/procgen_world_tileset.tres"

const NEW_VISUAL_CHECKS := {
	"terrain_connector_ground_32": {"source_id": 60, "layer": "floor"},
	"ramp_north_wide_32": {"source_id": 82, "layer": "floor"},
	"chasm_void_32": {"source_id": 100, "layer": "wall"},
	"bridge_stone_mid_horizontal_32": {"source_id": 115, "layer": "floor"},
}

const OLD_VISUAL_CHECKS := {
	"elevated_floor_32": 33,
	"elevation_edge_north_32": 34,
	"ramp_north_32": 38,
	"cliff_chasm_drop_32": 58,
}

var _failed := false


func _init() -> void:
	var runtime_sources: Dictionary = PROCGEN_TILEMAP.TERRAIN_TILESET_SOURCES
	_validate_gameplay_pack_coverage(runtime_sources)
	_validate_old_sources(runtime_sources)
	_validate_painting(runtime_sources)

	if _failed:
		print("[TerrainGameplayArtUsageSmoke] FAILED")
		quit(1)
		return
	print("[TerrainGameplayArtUsageSmoke] ok")
	quit(0)


func _validate_gameplay_pack_coverage(runtime_sources: Dictionary) -> void:
	var source_ids := {}
	for tile_id in runtime_sources:
		var source_id := int((runtime_sources[tile_id] as Dictionary).get("source_id", -1))
		if _is_gameplay_pack_source_id(source_id):
			source_ids[source_id] = tile_id
	_require(source_ids.size() == 62, "Expected 62 gameplay-pack source IDs, got %d." % source_ids.size())
	for source_id in range(60, 78):
		_require(source_ids.has(source_id), "Missing connector runtime source ID %d." % source_id)
	for source_id in range(80, 100):
		_require(source_ids.has(source_id), "Missing ascent runtime source ID %d." % source_id)
	for source_id in range(100, 124):
		_require(source_ids.has(source_id), "Missing chasm/bridge runtime source ID %d." % source_id)


func _validate_old_sources(runtime_sources: Dictionary) -> void:
	for tile_id in OLD_VISUAL_CHECKS:
		_require(runtime_sources.has(tile_id), "Missing old terrain visual '%s'." % tile_id)
		if runtime_sources.has(tile_id):
			_require(
				int((runtime_sources[tile_id] as Dictionary).get("source_id", -1)) == int(OLD_VISUAL_CHECKS[tile_id]),
				"Old terrain visual '%s' source ID changed." % tile_id
			)


func _validate_painting(runtime_sources: Dictionary) -> void:
	var tileset := load(TILESET_PATH) as TileSet
	_require(tileset != null, "Could not load active procgen TileSet.")
	if tileset == null:
		return

	var procgen_tilemap := PROCGEN_TILEMAP.new()
	var floor := TileMapLayer.new()
	var walls := TileMapLayer.new()
	floor.tile_set = tileset
	walls.tile_set = tileset
	procgen_tilemap.floor_tilemap = floor
	procgen_tilemap.walls_tilemap = walls

	var index := 0
	for tile_id in NEW_VISUAL_CHECKS:
		var cell := Vector2i(index, 0)
		var expected: Dictionary = NEW_VISUAL_CHECKS[tile_id]
		_require(procgen_tilemap._apply_terrain_tile_visual(cell, tile_id), "Could not paint '%s'." % tile_id)
		if String(expected["layer"]) == "wall":
			_require(walls.get_cell_source_id(cell) == int(expected["source_id"]), "'%s' painted the wrong wall source." % tile_id)
			_require(floor.get_cell_source_id(cell) == -1, "'%s' should not leave floor authority." % tile_id)
		else:
			_require(floor.get_cell_source_id(cell) == int(expected["source_id"]), "'%s' painted the wrong floor source." % tile_id)
			_require(walls.get_cell_source_id(cell) == -1, "'%s' should not leave wall authority." % tile_id)
		index += 1

	var connector_cell := Vector2i(index, 0)
	procgen_tilemap._set_region_tile(connector_cell, "compound_connector_road", "compound_ingress")
	procgen_tilemap._apply_connector_region_visual(connector_cell)
	_require(floor.get_cell_source_id(connector_cell) == 76, "Compound connector selection should paint source 76.")
	var repair_cell := Vector2i(index + 1, 0)
	procgen_tilemap._set_region_tile(repair_cell, "pre_terrain_required_connector", "authority_repair")
	procgen_tilemap._apply_connector_region_visual(repair_cell)
	var repair_source := floor.get_cell_source_id(repair_cell)
	_require(repair_source in [60, 61, 62, 63, 77], "Authority-repair selection should paint a deterministic Connector Pack variant.")

	var usage := procgen_tilemap.debug_dump_runtime_tileset_source_usage()
	var gameplay_counts: Dictionary = usage.get("gameplay_pack_counts", {})
	_require(int(gameplay_counts.get("connector", 0)) == 3, "Runtime usage should count direct, corridor, and repair connector tiles.")
	_require(int(gameplay_counts.get("ascent", 0)) == 1, "Runtime usage should count one ascent tile.")
	_require(int(gameplay_counts.get("chasm_bridge", 0)) == 2, "Runtime usage should count chasm and bridge tiles.")

	procgen_tilemap.free()
	floor.free()
	walls.free()


func _is_gameplay_pack_source_id(source_id: int) -> bool:
	return (source_id >= 60 and source_id <= 77) \
			or (source_id >= 80 and source_id <= 99) \
			or (source_id >= 100 and source_id <= 123)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerrainGameplayArtUsageSmoke] " + message)
