extends SceneTree

const PROCGEN_TILEMAP := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const FOLIAGE_SHADER := preload("res://game/world/procgen/foliage_life.gdshader")
const TILESET_PATH := "res://content/tiles/tilesets/procgen_world_tileset.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tileset := load(TILESET_PATH) as TileSet
	_require(tileset != null, "Could not load active procgen TileSet.")
	if tileset == null:
		_finish()
		return

	var tilemap := PROCGEN_TILEMAP.new() as ProcGenTilemap
	tilemap.name = "ProcGenCombatReadabilitySmokeMap"
	var floor := TileMapLayer.new()
	floor.name = "Floor"
	floor.tile_set = tileset
	var walls := TileMapLayer.new()
	walls.name = "Walls"
	walls.tile_set = tileset
	tilemap.add_child(floor)
	tilemap.add_child(walls)
	tilemap.floor_tilemap = floor
	tilemap.walls_tilemap = walls
	tilemap.floor_source_id = 10
	tilemap.alternate_floor_source_ids = [9]
	tilemap.full_grid_floor_source_ids = [9, 10]
	tilemap.floor_value_cluster_variant_source_ids = [9, 10]
	root.add_child(tilemap)
	await process_frame

	_seed_floor(tilemap, floor)
	_validate_floor_debug_report(tilemap)
	_validate_readability_cluster_skip(tilemap, floor)
	await _validate_combat_foliage_profile(tilemap)

	tilemap.queue_free()
	await process_frame
	_finish()


func _seed_floor(tilemap: ProcGenTilemap, floor: TileMapLayer) -> void:
	for y in range(12):
		for x in range(12):
			var cell := Vector2i(x, y)
			floor.set_cell(cell, 10, Vector2i.ZERO, 0)
			tilemap._generated_floor_cells[cell] = {
				"source_id": 10,
				"atlas": Vector2i.ZERO,
				"alternative": 0,
			}
	tilemap._set_region_tile(Vector2i(2, 2), "spawn_clearing", "safe")
	tilemap._set_region_tile(Vector2i(3, 2), "portal_plaza", "portal")
	tilemap._set_region_tile(Vector2i(4, 2), "compound_ingress", "compound")
	tilemap._set_region_tile(Vector2i(5, 2), "faction_camp", "faction_activity")
	tilemap._set_region_tile(Vector2i(6, 2), "story_room_floor", "story_room")


func _validate_floor_debug_report(tilemap: ProcGenTilemap) -> void:
	var report := tilemap.debug_get_floor_tile_report(Vector2i(2, 2))
	_require(int(report.get("source_id", -1)) == 10, "Floor debug report should expose source id.")
	_require(str(report.get("region_type", "")) == "spawn_clearing", "Floor debug report should expose region type.")
	_require(bool(report.get("generated_floor", false)), "Floor debug report should expose generated floor membership.")
	_require(report.has("valid_spawn_cell"), "Floor debug report should expose spawn-validity state.")


func _validate_readability_cluster_skip(tilemap: ProcGenTilemap, floor: TileMapLayer) -> void:
	var gameplay_result := {
		"height_by_cell": {},
		"traversal_by_cell": {},
		"terrain_type_by_cell": {},
		"tile_by_cell": {},
		"ramp_dir_by_cell": {},
		"edge_profile_by_cell": {},
	}
	tilemap._apply_floor_value_clusters(gameplay_result, 12345)
	for cell in [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2)]:
		_require(floor.get_cell_source_id(cell) == 10, "Combat/readability floor tile %s should skip cluster source swaps." % str(cell))
	_require(not tilemap.get_last_floor_value_cluster_summary().is_empty(), "Floor cluster summary should remain available.")


func _validate_combat_foliage_profile(tilemap: ProcGenTilemap) -> void:
	var material := ShaderMaterial.new()
	material.shader = FOLIAGE_SHADER
	tilemap._combat_readability_timer = 0.0
	tilemap._apply_foliage_occlusion_material(material, [Vector2(10, 10)])
	_require(is_equal_approx(float(material.get_shader_parameter("bubble_radius")), tilemap.foliage_player_occlusion_radius), "Normal foliage radius should use exploration profile.")
	_require(is_equal_approx(float(material.get_shader_parameter("bubble_alpha")), tilemap.foliage_player_occlusion_alpha), "Normal foliage alpha should use exploration profile.")

	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	player.global_position = Vector2.ZERO
	root.add_child(player)
	var enemy := Node2D.new()
	enemy.name = "Enemy"
	enemy.add_to_group("enemy")
	enemy.global_position = Vector2(64, 0)
	root.add_child(enemy)
	await process_frame

	tilemap._update_combat_readability_state(0.1)
	var state := tilemap.debug_get_combat_readability_state()
	_require(bool(state.get("active", false)), "Enemy near player should activate combat readability.")
	tilemap._apply_foliage_occlusion_material(material, [Vector2(10, 10)])
	_require(is_equal_approx(float(material.get_shader_parameter("bubble_radius")), tilemap.combat_foliage_occlusion_radius), "Combat foliage radius should use combat profile.")
	_require(is_equal_approx(float(material.get_shader_parameter("bubble_alpha")), tilemap.combat_foliage_occlusion_alpha), "Combat foliage alpha should use combat profile.")

	enemy.queue_free()
	player.queue_free()


func _finish() -> void:
	if _failed:
		print("[ProcgenCombatReadabilitySmoke] FAILED")
		quit(1)
		return
	print("[ProcgenCombatReadabilitySmoke] ok")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[ProcgenCombatReadabilitySmoke] " + message)
