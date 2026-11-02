extends SceneTree

const CONTRACT_SCENE := preload(
	"res://game/world/procgen/custodian_contract_map.tscn"
)
const SPAWNER_SCRIPT := preload(
	"res://game/world/levels/world_ingress_spawner.gd"
)
const SEED_COUNT := 100
const REQUIRED_IDENTITY := "forlorn_ritualant_underground"

var _errors: Array[String] = []
var _directions: Dictionary = {}
var _profiles: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var seed_count := SEED_COUNT
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed-count="):
			seed_count = maxi(1, int(argument.trim_prefix("--seed-count=")))
	var contract_map := CONTRACT_SCENE.instantiate() as CustodianContractMap
	contract_map.auto_generate_on_ready = false
	root.add_child(contract_map)
	await process_frame
	var world := Node2D.new()
	world.name = "IngressSweepWorld"
	root.add_child(world)
	var spawner := SPAWNER_SCRIPT.new()
	world.add_child(spawner)
	for seed in range(seed_count):
		await contract_map.generate_contract(seed)
		var contract := contract_map.get_latest_contract()
		if contract.is_empty():
			_errors.append(
				"seed=%d generation failed: %s" % [
					seed, contract_map.get_latest_generation_failure()
				]
			)
			continue
		var profile := contract.get("world_profile", {}) as Dictionary
		_profiles[str(profile.get("planet_key", "missing"))] = true
		var map_record := contract.get("map", {}) as Dictionary
		var map_instance := map_record.get("instance") as Node
		var level_data := map_record.get("level_data", {}) as Dictionary
		var dry_run := spawner.validate_required_ingresses(level_data, map_instance)
		if not bool(dry_run.get("ok", false)):
			_errors.append(
				"seed=%d accepted contract failed required-ingress dry-run: %s" % [
					seed, dry_run.get("failures", [])
				]
			)
			continue
		var placed := spawner.place_all(level_data, map_instance, world)
		var required_nodes := get_nodes_in_group(
			"generated_world_ingress_" + REQUIRED_IDENTITY
		)
		if required_nodes.is_empty():
			_errors.append(
				"seed=%d accepted contract omitted required ingress; placed=%d errors=%s" % [
					seed, placed.size(), spawner.get_last_errors()
				]
			)
			continue
		var ingress := required_nodes.front() as Node
		var outward := ingress.get_meta(
			"world_ingress_outward_direction", Vector2i.ZERO
		) as Vector2i
		_directions[outward] = true
		_validate_threadway_for_ingress(seed, ingress, map_instance, level_data)
		if (seed + 1) % 10 == 0 or seed + 1 == seed_count:
			print(
				"[RequiredRitualantIngressContractSweep] progress=%d/%d profiles=%s directions=%s"
				% [seed + 1, seed_count, _profiles.keys(), _directions.keys()]
			)
	if seed_count >= SEED_COUNT and _profiles.size() < 6:
		_errors.append("100-seed sweep did not exercise all six planet profiles: %s" % [_profiles.keys()])
	if seed_count >= SEED_COUNT:
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if not _directions.has(direction):
				_errors.append("100-seed sweep did not place direction %s" % direction)
	if _errors.is_empty():
		print(
			"[RequiredRitualantIngressContractSweep] PASS seeds=%d profiles=%s directions=%s"
			% [seed_count, _profiles.keys(), _directions.keys()]
		)
		quit(0)
		return
	for error in _errors:
		push_error("[RequiredRitualantIngressContractSweep] %s" % error)
	quit(1)


# Section E: prove the Threadway is actually resolvable for real generated
# ingresses, not just that the ingress node exists. Awards the canonical
# unlock resource straight to the ingress (bypassing ResourceLedger, which
# is not present in this headless harness), drives the same
# _resolve_threadway() path real gameplay uses, and checks the committed
# connector plan against the map's own playability/reachability authority.
func _validate_threadway_for_ingress(
	seed: int,
	ingress: Node,
	map_instance: Node,
	level_data: Dictionary
) -> void:
	var presentation := ingress.get_node_or_null(
		"AshBellLiftIngressPresentation"
	)
	if presentation == null:
		_errors.append("seed=%d ingress has no attached lift presentation" % seed)
		return
	var approach_world: Vector2 = presentation.call(
		"get_interaction_approach_position"
	)
	var approach_tile: Vector2i = map_instance.call("_global_to_tile", approach_world)

	var hard_clearance := {}
	if map_instance.has_method("debug_get_route_playability"):
		var route_playability: Dictionary = map_instance.call(
			"debug_get_route_playability"
		)
		hard_clearance = route_playability.get("hard_clearance_cells", {}) as Dictionary

	var floor_before: Dictionary = map_instance.call("debug_get_generated_floor_cells")
	var spawn_tile: Vector2i = map_instance.call("get_player_spawn")
	var reachable_before := _floor_component(spawn_tile, floor_before)
	if reachable_before.has(approach_tile):
		_errors.append(
			"seed=%d ritualant interaction approach was reachable before Threadway eligibility"
			% seed
		)

	# 1. Award canonical white_thread_knot eligibility directly (no ResourceLedger autoload here).
	ingress.call("_on_resource_added", "white_thread_knot", 1, 1)
	if not bool(ingress.call("debug_is_threadway_unlocked")):
		_errors.append("seed=%d awarding white_thread_knot did not unlock the Threadway" % seed)
		return

	# 2-4. Evaluate canonical connector, allow documented fallback, commit synchronously.
	ingress.call("_resolve_threadway", false)
	var resolved := bool(ingress.call("debug_is_threadway_resolved"))
	var result: Dictionary = ingress.call("debug_get_threadway_result")
	if not resolved or not bool(result.get("ok", false)):
		_errors.append(
			"seed=%d outward=%s no Threadway connector plan succeeded (canonical or fallback): %s"
			% [seed, str(ingress.get_meta("world_ingress_outward_direction", Vector2i.ZERO)), str(result)]
		)
		return

	var cells := result.get("cells", []) as Array
	if cells.is_empty():
		_errors.append("seed=%d committed Threadway plan has zero cells" % seed)
	print(
		(
			"[RequiredRitualantIngressContractSweep] threadway seed=%d outward=%s "
			+ "island_anchor=%s endpoint=%s cell_count=%d already_connected=%s reason=%s"
		) % [
			seed,
			str(ingress.get_meta("world_ingress_outward_direction", Vector2i.ZERO)),
			str(result.get("island_anchor_tile", "?")),
			str(result.get("endpoint_tile", "?")),
			cells.size(),
			str(result.get("already_connected", false)),
			str(result.get("reason", "ok")),
		]
	)

	# 6. Threadway cells must not intersect protected hard blockers.
	for cell_variant in cells:
		if hard_clearance.has(cell_variant):
			_errors.append(
				"seed=%d Threadway cell %s intersects a protected hard-clearance cell"
				% [seed, str(cell_variant)]
			)
			break

	# 5 & 7. Connector must reach the main reachable component and make the
	# interaction approach reachable from the player's spawn.
	var floor_after: Dictionary = map_instance.call("debug_get_generated_floor_cells")
	var reachable_after := _floor_component(spawn_tile, floor_after)
	if not reachable_after.has(approach_tile):
		_errors.append(
			"seed=%d committed Threadway connector did not make the interaction approach (%s) reachable from spawn (%s)"
			% [seed, str(approach_tile), str(spawn_tile)]
		)
	var island_anchor: Variant = result.get("island_anchor_tile")
	if island_anchor is Vector2i and not reachable_after.has(island_anchor as Vector2i):
		_errors.append(
			"seed=%d committed Threadway connector's island anchor %s did not join the main reachable component"
			% [seed, str(island_anchor)]
		)


func _floor_component(origin: Vector2i, floor: Dictionary) -> Dictionary:
	var result := {}
	if not floor.has(origin):
		return result
	var pending: Array[Vector2i] = [origin]
	result[origin] = true
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = cell + direction
			if floor.has(neighbor) and not result.has(neighbor):
				result[neighbor] = true
				pending.append(neighbor)
	return result
