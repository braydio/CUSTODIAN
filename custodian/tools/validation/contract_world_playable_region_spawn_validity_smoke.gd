extends SceneTree

## Covers CONTRACT_WORLD_PLAYABLE_REGION_SPAWN_VALIDITY_FIX: a final Operator
## spawn must pass canonical spawn validity and belong to the accepted main
## playable component. A tile that is merely painted floor (exterior/underlevel
## presentation, or a disconnected island) must never become the Operator
## position, and no safe spawn must fail closed without moving the Operator.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const WORLD_LOADER_SCRIPT := preload(
	"res://game/systems/core/systems/contract_world_loader.gd"
)
const TEST_SEED := 424242
const FAR := Vector2(-9999.0, -9999.0)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	game_root.add_child(operator)
	var loader := WORLD_LOADER_SCRIPT.new()
	loader.set("operator_path", NodePath("../Operator"))
	game_root.add_child(loader)

	var map := await _generate_map()
	var component := map.get_main_playable_component()
	_expect(not component.is_empty(), "fixture must have a non-empty main playable component")
	if component.is_empty():
		_finish()
		return

	var good := _pick_good_tile(map, component)
	var exterior := _pick_exterior_tile(map)
	var island := _pick_island_tile(map, component, good)
	_expect(good != Vector2i.ZERO, "fixture needs a good in-component tile")
	_expect(exterior != Vector2i.ZERO, "fixture needs an exterior (non-generated) tile")
	_expect(island != Vector2i.ZERO, "fixture needs a disconnected island tile")
	if _errors.size() > 0:
		_finish()
		return

	# Paint the bad candidates exactly like real floor so the OLD predicate
	# (painted floor + no ingress clearance) accepts them.
	var source_id := map.floor_tilemap.get_cell_source_id(good)
	var atlas := map.floor_tilemap.get_cell_atlas_coords(good)
	# Sever the island: wall its four neighbours so it stays canonically valid
	# and painted but is no longer 4-connected to the main component.
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		(map.get("_generated_wall_cells") as Dictionary)[island + d] = true
	component = map.get_main_playable_component()
	for bad: Vector2i in [exterior, island]:
		map.floor_tilemap.set_cell(bad, source_id, atlas)
		var old_predicate: bool = loader.call("_is_walkable_floor_tile", map, bad) \
			and not loader.call("_is_inside_ingress_clearance", map, bad)
		_expect(old_predicate, "old predicate must accept the painted bad tile %s" % bad)
		_expect(
			not loader.call("_is_safe_operator_spawn_tile", map, bad, component),
			"new predicate must reject the painted-but-not-main-playable tile %s" % bad
		)
		_expect(not component.has(bad), "bad tile %s must be outside the main component" % bad)
	_expect(
		loader.call("_is_safe_operator_spawn_tile", map, good, component),
		"new predicate must accept the in-component tile"
	)
	_expect(map.is_valid_spawn_cell(island) and map.is_runtime_navigation_walkable(island), "island is canonically valid but disconnected (isolates the component rule)")
	_expect(not map.is_valid_spawn_cell(exterior), "exterior tile must fail canonical spawn validity")

	# Compound selection: only a bad tile -> fails closed, Operator unmoved.
	for bad: Vector2i in [exterior, island]:
		var bad_only := {"compound_rect": Rect2i(bad, Vector2i.ONE), "player_spawn": Vector2i.ZERO}
		operator.global_position = FAR
		_expect(not loader.call("_position_operator", bad_only, map), "bad-only compound must fail closed (%s)" % bad)
		_expect(operator.global_position == FAR, "failed placement must not move the Operator (%s)" % bad)

	# Bad tile preferred by rect centre + good tile available: lands on good, deterministically.
	var span := Rect2i(Vector2i(mini(good.x, exterior.x), mini(good.y, exterior.y)), Vector2i.ONE)
	span = span.expand(good + Vector2i.ONE).expand(exterior + Vector2i.ONE)
	var mixed := {"compound_rect": span, "player_spawn": Vector2i.ZERO}
	operator.global_position = FAR
	_expect(loader.call("_position_operator", mixed, map), "a valid candidate in the rect must place the Operator")
	var first := operator.global_position
	var landed: Vector2i = map.floor_tilemap.local_to_map(map.floor_tilemap.to_local(first))
	_expect(landed != exterior and landed != island, "Operator must never land on a bad tile")
	_expect(map.is_valid_spawn_cell(landed) and map.is_runtime_navigation_walkable(landed), "final Operator tile must be canonically valid and walkable")
	_expect(component.has(landed), "final Operator tile must be in the main playable component")
	operator.global_position = FAR
	loader.call("_position_operator", mixed, map)
	_expect(operator.global_position.is_equal_approx(first), "repeated selection must be identical")

	# player_spawn fallback obeys the same invariant.
	for bad: Vector2i in [exterior, island]:
		var fallback_bad := {"compound_rect": Rect2i(Vector2i.ZERO, Vector2i.ZERO), "player_spawn": bad}
		operator.global_position = FAR
		_expect(not loader.call("_position_operator", fallback_bad, map), "bad player_spawn fallback must fail closed (%s)" % bad)
		_expect(operator.global_position == FAR, "failed fallback must not move the Operator (%s)" % bad)
	var fallback_good := {"compound_rect": Rect2i(Vector2i.ZERO, Vector2i.ZERO), "player_spawn": good}
	_expect(loader.call("_position_operator", fallback_good, map), "valid player_spawn fallback must place the Operator")
	_expect(
		operator.global_position.is_equal_approx(map.tile_to_global_position(good)),
		"fallback Operator must land on the valid player_spawn tile"
	)

	# Placement stays before camera snap in contract installation.
	var source := FileAccess.get_file_as_string("res://game/systems/core/systems/contract_world_loader.gd")
	var install := source.find("func _on_contract_generated(")
	var operator_call := source.find("if reposition_operator_from_contract:", install)
	var camera_call := source.find("_refresh_camera(map_instance)", operator_call)
	_expect(install >= 0 and operator_call > install and camera_call > operator_call, "camera snap must follow valid Operator placement")

	game_root.queue_free()
	map.queue_free()
	await process_frame
	_finish()


func _pick_good_tile(map: ProcGenTilemap, component: Dictionary) -> Vector2i:
	var keys: Array = component.keys()
	keys.sort()
	for key: Vector2i in keys:
		if map.floor_tilemap.get_cell_source_id(key) >= 0 and map.walls_tilemap.get_cell_source_id(key) < 0:
			return key
	return Vector2i.ZERO


## Inside the map, not canonical generated floor.
func _pick_exterior_tile(map: ProcGenTilemap) -> Vector2i:
	var generated := map.get("_generated_floor_cells") as Dictionary
	var size := (map.procgen_node as ProcGen).map_size
	for y in range(2, size.y - 2):
		for x in range(2, size.x - 2):
			var tile := Vector2i(x, y)
			if not generated.has(tile) and not map.is_valid_spawn_cell(tile):
				return tile
	return Vector2i.ZERO


## A component tile whose four neighbours are also in the component and far
## from `good`; severing those neighbours makes it a disconnected island.
func _pick_island_tile(map: ProcGenTilemap, component: Dictionary, good: Vector2i) -> Vector2i:
	var keys: Array = component.keys()
	keys.sort()
	keys.reverse()
	for key: Vector2i in keys:
		if key.distance_to(good) < 8.0 or key == map.get_player_spawn():
			continue
		if map.floor_tilemap.get_cell_source_id(key) < 0 or map.walls_tilemap.get_cell_source_id(key) >= 0:
			continue
		var ringed := true
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not component.has(key + d) or key.distance_to(map.get_player_spawn()) < 2.0:
				ringed = false
		if ringed:
			return key
	return Vector2i.ZERO


func _generate_map() -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.name = "PlayableRegionSpawnValidityMap"
	root.add_child(map)
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = TEST_SEED
	generator.map_size = Vector2i(112, 96)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.auto_bake_nav = false
	map.generate()
	await process_frame
	return map


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error("[ContractWorldPlayableRegionSpawnValiditySmoke] " + message)


func _finish() -> void:
	if not _errors.is_empty():
		push_error("ContractWorldPlayableRegionSpawnValiditySmoke failed (%d errors)" % _errors.size())
		quit(1)
		return
	print("[ContractWorldPlayableRegionSpawnValiditySmoke] PASS")
	quit(0)
