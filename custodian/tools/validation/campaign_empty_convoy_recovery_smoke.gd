extends SceneTree

const SPAWNER_SCRIPT := preload("res://game/systems/spawning/ambient_enemy_spawner.gd")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const PURSUIT_SCENE := preload("res://game/actors/enemies/pursuit_frame.tscn")
const SITE_SCRIPT := preload("res://game/world/events/campaign/empty_convoy_site.gd")


class WalkabilityProbe extends Node:
	func find_safe_runtime_walkable_global(position: Vector2, _radius_tiles: int) -> Vector2:
		return position


class NavigationProbe extends Node:
	func get_path_to_target(start: Vector2, target: Vector2) -> PackedVector2Array:
		return PackedVector2Array([start, target])


class MissingLedger extends Node:
	var grant_count := 0


	func get_resource_defs() -> Dictionary:
		return {}


	func add(_resource_id: String, _amount: int) -> void:
		grant_count += 1


var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var memory := root.get_node_or_null("WorldEventMemory")
	var ledger := root.get_node_or_null("ResourceLedger")
	_expect(memory != null, "WorldEventMemory autoload must be available")
	_expect(ledger != null, "ResourceLedger autoload must be available")
	if memory == null or ledger == null:
		quit(1)
		return
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

	# Defeated security unlocks a trace and a single valid ledger grant.
	memory.call("reset_run_events", 730101)
	ledger.call("clear")
	var start_amount := int(ledger.call("get_amount", "ruin_scrap"))
	var site: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(site)
	site.configure_runtime(51001, memory, spawner)
	site.interact(null)
	await _drain_spawn_queue(spawner)
	var event_enemies := _event_enemies(site.event_id)
	_expect(event_enemies.size() == 3, "recovery test should use the bounded registered security wave")
	for enemy in event_enemies:
		enemy.call("die")
	_expect(site.security_state == &"cleared", "security defeat should unlock trace recovery")
	site.interact(null)
	_expect(site.security_state == &"trace_recorded", "valid ledger should record the custody trace")
	_expect(site.get_interaction_prompt_body().contains("SHIPMENT UNVERIFIED"), "trace must not identify cargo")
	_expect(int(ledger.call("get_amount", "ruin_scrap")) == start_amount + 1, "first trace interaction should grant one ruin scrap")
	var payload: Dictionary = memory.call("get_payload", site.event_id)
	_expect(bool(payload.get("custody_trace_recorded", false)), "trace receipt should persist in WorldEventMemory")
	_expect(bool(payload.get("salvage_granted", false)), "receipt should record exactly-once salvage disposition")
	_expect((payload.get("defeated_slots", []) as Array).size() == 3, "trace receipt should preserve the completed security record")
	site.interact(null)
	_expect(int(ledger.call("get_amount", "ruin_scrap")) == start_amount + 1, "interaction spam must not duplicate salvage")
	var event_id: StringName = site.event_id
	site.queue_free()
	await process_frame
	var resumed: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(resumed)
	resumed.configure_runtime(51001, memory, spawner)
	_expect(resumed.security_state == &"trace_recorded", "same-run reentry should restore the trace state")
	resumed.interact(null)
	_expect(int(ledger.call("get_amount", "ruin_scrap")) == start_amount + 1, "reentry must not grant salvage twice")
	resumed.queue_free()
	await process_frame

	# A legitimate safe-empty defense still permits evidence and a valid salvage item.
	memory.call("reset_run_events", 730102)
	var empty_spawner := SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	root.add_child(empty_spawner)
	await process_frame
	var safe_empty: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(safe_empty)
	safe_empty.configure_runtime(51002, memory, empty_spawner)
	safe_empty.interact(null)
	_expect(safe_empty.security_state == &"empty_defense", "missing defenders should preserve the safe-empty path")
	var safe_empty_amount := int(ledger.call("get_amount", "ruin_scrap"))
	safe_empty.interact(null)
	_expect(safe_empty.security_state == &"trace_recorded", "safe-empty defense should still allow custody evidence")
	_expect(int(ledger.call("get_amount", "ruin_scrap")) == safe_empty_amount + 1, "safe-empty trace should use the valid ledger once")
	safe_empty.interact(null)
	_expect(int(ledger.call("get_amount", "ruin_scrap")) == safe_empty_amount + 1, "safe-empty reread must not duplicate salvage")
	safe_empty.queue_free()
	empty_spawner.queue_free()
	await process_frame

	# Missing resource definitions produce evidence-only completion and no grant.
	memory.call("reset_run_events", 730103)
	var no_item_spawner := SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	root.add_child(no_item_spawner)
	await process_frame
	var no_item_ledger := MissingLedger.new()
	root.add_child(no_item_ledger)
	var evidence_only: EmptyConvoySite = SITE_SCRIPT.new()
	root.add_child(evidence_only)
	evidence_only.configure_runtime(51003, memory, no_item_spawner, no_item_ledger)
	evidence_only.interact(null)
	_expect(evidence_only.security_state == &"empty_defense", "unregistered defense should remain inspectable")
	evidence_only.interact(null)
	_expect(evidence_only.security_state == &"evidence_only", "missing resource definition should retain evidence only")
	_expect(evidence_only.get_interaction_prompt_body().contains("SHIPMENT UNVERIFIED"), "evidence-only readback should retain the unverified trace")
	_expect(no_item_ledger.grant_count == 0, "unknown resource definition must not receive a grant")
	_expect(bool(memory.call("is_completed", evidence_only.event_id)), "evidence-only disposition should still complete the trace event")
	var evidence_payload: Dictionary = memory.call("get_payload", evidence_only.event_id)
	_expect(not bool(evidence_payload.get("salvage_granted", true)), "evidence-only receipt must explicitly record no salvage")
	evidence_only.interact(null)
	_expect(no_item_ledger.grant_count == 0, "evidence-only reread must not attempt a grant")
	evidence_only.queue_free()
	no_item_spawner.queue_free()
	no_item_ledger.queue_free()
	probe.queue_free()
	navigation.queue_free()
	spawner.queue_free()
	await process_frame

	if _errors.is_empty():
		print("PASS: convoy custody trace, exactly-once salvage, safe-empty evidence, reentry, and ledger fallback")
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
