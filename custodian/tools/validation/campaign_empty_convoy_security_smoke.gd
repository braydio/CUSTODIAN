extends SceneTree

const SPAWNER_SCRIPT := preload("res://game/systems/spawning/ambient_enemy_spawner.gd")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const PURSUIT_SCENE := preload("res://game/actors/enemies/pursuit_frame.tscn")
const SITE_SCRIPT := preload("res://game/world/events/campaign/empty_convoy_site.gd")


class WalkabilityProbe extends Node:
	var reject_all := false


	func find_safe_runtime_walkable_global(position: Vector2, _radius_tiles: int) -> Vector2:
		return Vector2.INF if reject_all else position


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
	_expect(bool(memory.call("is_completed", site.event_id)), "cleared state should persist in WorldEventMemory")
	_expect(site.get_interaction_prompt_body().contains("CUSTODY UNVERIFIED"), "clear readback must not claim shipment custody")
	site.queue_free()
	await process_frame

	# An interrupted active wave is never respawned on reentry when its actors no longer exist.
	memory.call("reset_run_events", 620185)
	var interrupted: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(interrupted)
	interrupted.configure_runtime(41003, memory, spawner)
	interrupted.interact(null)
	var interrupted_id: StringName = interrupted.event_id
	var interrupted_enemies := _event_enemies(interrupted_id)
	_expect(interrupted_enemies.size() == 3, "second run seed should activate its own wave")
	interrupted.queue_free()
	await process_frame
	var resumed: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(resumed)
	resumed.configure_runtime(41003, memory, spawner)
	_expect(resumed.security_state == &"empty_defense", "missing active actors on reentry should fail closed")
	_expect(_event_enemies(interrupted_id).is_empty(), "reentry must not duplicate the interrupted wave")
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
	_expect(unsafe.security_state == &"empty_defense", "no safe spawn positions should fail closed")
	_expect(_event_enemies(unsafe.event_id).is_empty(), "unsafe spawn resolution must not create enemies")

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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
