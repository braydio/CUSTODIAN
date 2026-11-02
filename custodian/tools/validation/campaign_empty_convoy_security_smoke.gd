extends SceneTree

const SPAWNER_SCRIPT := preload("res://game/systems/spawning/ambient_enemy_spawner.gd")
const CONTRACT_SCENE := preload("res://game/world/procgen/custodian_contract_map.tscn")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const PURSUIT_SCENE := preload("res://game/actors/enemies/pursuit_frame.tscn")
const NAVIGATION_SYSTEM_SCRIPT := preload("res://game/systems/core/systems/navigation_system.gd")
const SITE_SCRIPT := preload("res://game/world/events/campaign/empty_convoy_site.gd")
const CONTRACT_SEED := 2
const EXPECTED_MAP_SEED := 3570245418


class WalkabilityProbe extends Node:
	var reject_all := false
	var reject_call := -1
	var call_count := 0


	func find_safe_runtime_walkable_global(position: Vector2, _radius_tiles: int) -> Vector2:
		call_count += 1
		return Vector2.INF if reject_all or call_count == reject_call else position


class NavigationProbe extends Node:
	func get_path_to_target(start: Vector2, target: Vector2) -> PackedVector2Array:
		return PackedVector2Array([start, target])


var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var memory := root.get_node_or_null("WorldEventMemory")
	_expect(memory != null, "WorldEventMemory autoload must be available")
	if memory == null:
		quit(1)
		return
	memory.call("reset_run_events", 620184)
	var probe := WalkabilityProbe.new()
	probe.add_to_group("procgen_walkability_provider")
	root.add_child(probe)
	var navigation := NavigationProbe.new()
	navigation.add_to_group("navigation")
	root.add_child(navigation)
	var spawner := SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	spawner.enemy_scene = GRUNT_SCENE
	spawner.enemy_scenes = [GRUNT_SCENE, PURSUIT_SCENE]
	root.add_child(spawner)
	await process_frame

	var site: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(site)
	site.configure_runtime(41002, memory, spawner)
	_expect(site.get_interaction_prompt() == "SCAN CARGO CRADLE", "idle convoy should expose the scan interaction")
	site.interact(null)
	await _drain_spawn_queue(spawner)
	var first_wave := _event_enemies(site.event_id)
	_expect(site.security_state == &"active", "registered safe spawns should activate security")
	_expect(first_wave.size() == 3, "scan should spawn no more than three registered units")
	_expect(site.expected_enemy_count == 3, "event state should persist the realized bounded wave size")
	for enemy in first_wave:
		var facing: Vector2 = enemy.call("get_ability_facing")
		var outward: Vector2 = (enemy.global_position - site.global_position).normalized()
		_expect(facing.dot(outward) > 0.9, "security unit should face outward from the cradle")
	site.interact(null)
	_expect(_event_enemies(site.event_id).size() == 3, "repeat scan must not spawn a duplicate wave")
	for enemy in first_wave:
		enemy.call("die")
	_expect(site.security_state == &"cleared", "security should clear only after every spawned unit is defeated")
	_expect(bool(memory.call("has_spawned", site.event_id)), "cleared state should persist in WorldEventMemory")
	_expect(not bool(memory.call("is_completed", site.event_id)), "defender clearance must not mark the custody trace complete")
	_expect(site.get_interaction_prompt_body().contains("CUSTODY UNVERIFIED"), "clear readback must not claim shipment custody")
	site.queue_free()
	await process_frame

	# The shared ambient cap also applies to event-triggered waves.
	spawner.max_active_ambient_enemies = 2
	var capped: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(capped)
	capped.configure_runtime(41007, memory, spawner)
	capped.interact(null)
	_expect(capped.security_state == &"security_deferred", "partial ambient capacity must defer the complete convoy wave")
	_expect(_event_enemies(capped.event_id).is_empty(), "capacity exhaustion must not start a partial wave")
	_expect(not capped.get_interaction_prompt().contains("RECORD CUSTODY TRACE"), "capacity exhaustion must not unlock custody trace")
	spawner.max_active_ambient_enemies = 12
	capped.interact(null)
	await _drain_spawn_queue(spawner)
	_expect(_event_enemies(capped.event_id).size() == 3, "deferred convoy should retry the complete wave after capacity becomes available")
	for enemy in _event_enemies(capped.event_id):
		enemy.call("die")
	_expect(capped.security_state == &"cleared", "retried convoy wave should clear after all registered defenders are defeated")
	capped.queue_free()
	await process_frame

	# An interrupted active wave remains unresolved on reentry when its actors no longer exist.
	memory.call("reset_run_events", 620185)
	var interrupted: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(interrupted)
	interrupted.configure_runtime(41003, memory, spawner)
	interrupted.interact(null)
	await _drain_spawn_queue(spawner)
	var interrupted_id: StringName = interrupted.event_id
	var interrupted_enemies := _event_enemies(interrupted_id)
	_expect(interrupted_enemies.size() == 3, "second run seed should activate its own wave")
	interrupted.queue_free()
	await process_frame
	var resumed: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(resumed)
	resumed.configure_runtime(41003, memory, spawner)
	_expect(resumed.security_state == &"security_unresolved", "missing active actors on reentry must remain unverified")
	_expect(_event_enemies(interrupted_id).is_empty(), "reentry must not duplicate the interrupted wave")
	_expect(not resumed.get_interaction_prompt().contains("RECORD CUSTODY TRACE"), "missing active actors must not unlock custody trace")
	resumed.interact(null)
	_expect(resumed.security_state == &"security_unresolved", "interacting with a missing unverified wave must not complete it")
	for enemy in interrupted_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	resumed.queue_free()
	await process_frame

	# An unregistered enemy or absent safe position stays inspectable without crashing.
	var empty_spawner := SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	root.add_child(empty_spawner)
	await process_frame
	var unavailable: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(unavailable)
	unavailable.configure_runtime(41004, memory, empty_spawner)
	unavailable.interact(null)
	_expect(unavailable.security_state == &"empty_defense", "missing registered enemy scenes should enter evidence mode")
	_expect(unavailable.get_interaction_prompt_body().contains("EVIDENCE RETAINED"), "empty-defense mode should retain evidence readback")
	_expect(_event_enemies(unavailable.event_id).is_empty(), "empty-defense mode must not create enemies")
	probe.reject_all = true
	var unsafe: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(unsafe)
	unsafe.configure_runtime(41005, memory, spawner)
	unsafe.interact(null)
	_expect(unsafe.security_state == &"security_deferred", "temporary walkability rejection must remain retryable")
	_expect(_event_enemies(unsafe.event_id).is_empty(), "unsafe spawn resolution must not create enemies")
	_expect(not unsafe.get_interaction_prompt().contains("RECORD CUSTODY TRACE"), "unsafe spawn resolution must not unlock custody trace")
	probe.reject_all = false
	unsafe.interact(null)
	await _drain_spawn_queue(spawner)
	_expect(_event_enemies(unsafe.event_id).size() == 3, "deferred walkability case should recover when real positions become available")
	for enemy in _event_enemies(unsafe.event_id):
		enemy.call("die")
	unsafe.queue_free()
	await process_frame

	# One queue-time failure cannot shrink the required wave or count as a defeat.
	var queue_rejection: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(queue_rejection)
	queue_rejection.configure_runtime(41006, memory, spawner)
	probe.reject_call = probe.call_count + 5 # 3 preflight resolutions, then reject queue slot 2.
	queue_rejection.interact(null)
	await _drain_spawn_queue(spawner)
	probe.reject_call = -1
	var partial_wave := _event_enemies(queue_rejection.event_id)
	_expect(partial_wave.size() == 2, "queue-time rejection fixture should create one accepted partial wave")
	_expect(queue_rejection.security_state == &"security_deferred", "partial queue success must remain deferred for the rejected slot")
	for enemy in partial_wave:
		enemy.call("die")
	_expect(queue_rejection.security_state != &"cleared", "defeating accepted partial spawns must not clear a missing slot")
	queue_rejection.interact(null)
	await _drain_spawn_queue(spawner)
	_expect(_event_enemies(queue_rejection.event_id).size() == 1, "retry should spawn only the queue-rejected slot")
	for enemy in _event_enemies(queue_rejection.event_id):
		enemy.call("die")
	_expect(queue_rejection.security_state == &"cleared", "all three successful, defeated identities should clear the retried wave")
	queue_rejection.queue_free()
	await process_frame
	var unavailable_service := Node.new()
	root.add_child(unavailable_service)
	var no_spawner: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(no_spawner)
	no_spawner.configure_runtime(41008, memory, unavailable_service)
	no_spawner.interact(null)
	_expect(no_spawner.security_state == &"security_deferred", "missing spawn service must not be treated as registered defender absence")
	_expect(not no_spawner.get_interaction_prompt().contains("RECORD CUSTODY TRACE"), "missing spawn service must not unlock custody trace")
	no_spawner.queue_free()
	unavailable_service.queue_free()
	await process_frame

	await _run_contract_seed_case(memory)
	for enemy in get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for node in [probe, navigation, spawner, empty_spawner]:
		if is_instance_valid(node):
			node.queue_free()
	await process_frame
	await process_frame
	if is_instance_valid(unavailable):
		unavailable.queue_free()
	await process_frame

	if _errors.is_empty():
		print("PASS: empty convoy security bounded wave, completion, run identity, reentry, and fail-closed evidence")
		quit(0)
	else:
		for message in _errors:
			push_error(message)
		quit(1)


func _event_enemies(target_event_id: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for enemy in get_nodes_in_group("enemy"):
		if String(enemy.get_meta("empty_convoy_event_id", "")) == String(target_event_id):
			result.append(enemy)
	return result


func _drain_spawn_queue(spawner: Node) -> void:
	for _frame in range(10):
		if int(spawner.call("get_pending_spawn_count")) == 0:
			return
		await physics_frame
	_expect(int(spawner.call("get_pending_spawn_count")) == 0, "ambient spawn queue should drain")


func _run_contract_seed_case(memory: Node) -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	world.add_child(enemies)
	var contract_map := CONTRACT_SCENE.instantiate() as CustodianContractMap
	contract_map.name = "ContractMap"
	contract_map.auto_generate_on_ready = false
	contract_map.map_generation_attempts = 1
	world.add_child(contract_map)
	var real_spawner := SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	real_spawner.name = "AmbientEnemySpawner"
	real_spawner.enemy_scene = GRUNT_SCENE
	real_spawner.enemy_scenes = [GRUNT_SCENE, PURSUIT_SCENE]
	real_spawner.enemy_container_path = NodePath("../World/Enemies")
	game_root.add_child(real_spawner)
	var navigation_system := NAVIGATION_SYSTEM_SCRIPT.new() as NavigationSystem
	navigation_system.name = "NavigationSystem"
	game_root.add_child(navigation_system)
	memory.call("reset_run_events", 620186)
	await process_frame
	await contract_map.generate_contract(CONTRACT_SEED)
	var contract: Dictionary = contract_map.get_latest_contract()
	var map_data: Dictionary = contract.get("map", {})
	var generated_map_seed := int(map_data.get("map_seed", -1))
	print("[EmptyConvoySecuritySmoke] contract_seed=%d map_seed=%d" % [CONTRACT_SEED, generated_map_seed])
	_expect(generated_map_seed == EXPECTED_MAP_SEED, "contract seed 2 generated map seed changed from the preserved production fixture")
	var map_instance := map_data.get("instance") as Node
	_expect(map_instance != null and map_instance.is_in_group("procgen_walkability_provider"), "contract seed 2 must use the real generated-map walkability provider")
	var convoy: EmptyConvoySite = null
	if map_instance != null:
		for node in map_instance.find_children("*", "", true, false):
			if node is EmptyConvoySite:
				convoy = node as EmptyConvoySite
				break
	_expect(convoy != null, "contract seed 2 must insert the actual Empty Convoy scene")
	if convoy != null:
		convoy.configure_runtime(generated_map_seed, memory, real_spawner)
		convoy.interact(null)
		await _drain_spawn_queue(real_spawner)
		var actual_enemies := _event_enemies(convoy.event_id)
		var deferred_without_reward := convoy.security_state in [&"security_deferred", &"security_unresolved"] \
			and not convoy.get_interaction_prompt().contains("RECORD CUSTODY TRACE") \
			and not bool(memory.call("is_completed", convoy.event_id))
		_expect(actual_enemies.size() == 3 or deferred_without_reward, "production seed must spawn three defenders or remain explicitly unresolved without completion")
		print("[EmptyConvoySecuritySmoke] convoy_state=%s accepted_enemies=%d" % [String(convoy.security_state), actual_enemies.size()])
		for enemy in actual_enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
	contract_map.queue_free()
	await process_frame
	game_root.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
