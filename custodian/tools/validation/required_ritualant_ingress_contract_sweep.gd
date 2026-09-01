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
