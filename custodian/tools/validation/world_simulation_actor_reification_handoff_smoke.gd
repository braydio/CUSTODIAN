extends SceneTree

const DOMAIN := "F14C_DOMAIN"
const GROUP := "F14C_PATROL"
const ACTOR := "GRUNT_001"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_legacy_v5_snapshot()
	var state := WorldSimulationState.new(1401)
	state.abstract_activity.register_location(DOMAIN, "A")
	state.abstract_activity.register_location(DOMAIN, "B")
	_check(state.abstract_activity.register_group(DOMAIN, GROUP, "A", "HOLD_SITE", ["A", "B"], 0, 0.5, 12.0, ACTOR), "group registration failed")
	var kernel := SimulationKernel.new(state)
	var anchor_a := Node2D.new()
	anchor_a.name = "AnchorA"
	var anchor_b := Node2D.new()
	anchor_b.name = "AnchorB"
	anchor_b.position = Vector2(128.0, 64.0)
	root.add_child(anchor_a)
	root.add_child(anchor_b)
	var coordinator := ActorReificationCoordinator.new()
	root.add_child(coordinator)
	_check(coordinator.bind(kernel, {"A": anchor_a, "B": anchor_b}), "coordinator failed to bind")
	var actor := load("res://game/actors/enemies/enemy_grunt.tscn").instantiate() as Enemy
	actor.set_meta("actor_id", ACTOR)
	actor.set_meta("group_id", GROUP)
	actor.set_meta("domain_id", DOMAIN)
	actor.set_meta("location_id", "A")
	actor.health = 39.0
	actor.max_health = 78.0
	actor.attack_objective = "defend_relay"
	root.add_child(actor)
	await process_frame
	_check(coordinator.claim_physical_actor(DOMAIN, GROUP, actor, "A"), "physical actor claim failed")
	var duplicate := load("res://game/actors/enemies/enemy_grunt.tscn").instantiate() as Enemy
	duplicate.set_meta("actor_id", ACTOR)
	duplicate.set_meta("group_id", GROUP)
	duplicate.set_meta("domain_id", DOMAIN)
	duplicate.set_meta("location_id", "A")
	root.add_child(duplicate)
	await process_frame
	var duplicate_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(duplicate_request).get("ok", false)), "duplicate actor identity was accepted")
	_check(actor.is_inside_tree() and String(state.abstract_activity.get_group(DOMAIN, GROUP).representation) == "physical", "duplicate rejection changed physical authority")
	duplicate.queue_free()
	await process_frame
	actor.set_meta("spawn_pending", true)
	var pending_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(pending_request).get("ok", false)), "pending spawn actor was transferred")
	_check(actor.is_inside_tree() and String(state.abstract_activity.get_group(DOMAIN, GROUP).representation) == "physical", "pending-spawn rejection changed authority")
	actor.remove_meta("spawn_pending")
	actor.restore_lifecycle_state(actor.health, actor.max_health, true, Enemy.LifeState.DYING)
	var dead_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(dead_request).get("ok", false)), "dying actor was transferred")
	_check(actor.is_inside_tree() and String(state.abstract_activity.get_group(DOMAIN, GROUP).representation) == "physical", "dying-actor rejection changed authority")
	actor.restore_lifecycle_state(actor.health, actor.max_health, false, Enemy.LifeState.LOOTABLE_CORPSE)
	var corpse_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(corpse_request).get("ok", false)), "corpse actor was transferred")
	actor.restore_lifecycle_state(actor.health, actor.max_health, false, Enemy.LifeState.ALIVE)
	var loot_carrier := actor.get_node("EnemyLootCarrier") as EnemyLootCarrier
	loot_carrier.set_payload({"ruin_scrap": 1})
	var loot_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(loot_request).get("ok", false)), "loot-bearing actor was transferred")
	loot_carrier.clear_payload()
	actor._standard_enemy_melee.attack_id = "TEST_ACTIVE_ATTACK"
	var active_attack_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(active_attack_request).get("ok", false)), "actor with an active attack was transferred")
	actor._standard_enemy_melee.attack_id = ""
	actor.set_meta("pending_projectile", true)
	var attack_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(attack_request).get("ok", false)), "actor with pending projectile interaction was transferred")
	actor.remove_meta("pending_projectile")
	actor.health = actor.max_health + 1.0
	var failed_commit_request := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	_check(not bool(coordinator.take_result(failed_commit_request).get("ok", false)), "invalid actor projection committed to abstract ownership")
	_check(actor.is_inside_tree() and String(state.abstract_activity.get_group(DOMAIN, GROUP).representation) == "physical", "failed abstract commit did not restore physical authority")
	actor.health = 39.0
	var unload_id := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	var repeated_unload_id := coordinator.request_abstract(DOMAIN, GROUP, actor, "A")
	kernel.step_once()
	var unload_result := coordinator.take_result(unload_id)
	_check(bool(unload_result.get("ok", false)), "physical-to-abstract transfer failed: %s" % unload_result.get("reason", "unknown"))
	_check(not bool(coordinator.take_result(repeated_unload_id).get("ok", false)), "repeated same-boundary unload was accepted twice")
	_check(not actor.is_inside_tree(), "abstract transfer left the actor or descendants in the gameplay tree")
	var abstract_record := state.abstract_activity.get_group(DOMAIN, GROUP)
	_check(String(abstract_record.get("representation", "")) == "abstract", "abstract authority was not committed")
	_check(String((abstract_record.get("actor_projection", {}) as Dictionary).get("actor_id", "")) == ACTOR, "abstract actor projection lost stable identity")
	_check(is_equal_approx(float(abstract_record.condition), 0.5), "abstract actor condition did not preserve health fraction")
	for index in 119:
		kernel.step_once()
	abstract_record = state.abstract_activity.get_group(DOMAIN, GROUP)
	_check(String(abstract_record.location_id) == "B", "abstract group did not advance to B")
	_check(state.abstract_activity.causal_events.size() == 1, "offscreen travel did not emit exactly one bounded causal event")
	var invalid_site_request := coordinator.request_physical(DOMAIN, GROUP, "MISSING_SITE")
	kernel.step_once()
	_check(not bool(coordinator.take_result(invalid_site_request).get("ok", false)), "invalid geographic site was accepted")
	_check(String(state.abstract_activity.get_group(DOMAIN, GROUP).representation) == "abstract", "invalid site rejection changed abstract authority")
	var snapshot := SimulationSnapshot.capture(state).to_dict()
	var restored := SimulationSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
	_check(restored != null, "abstract actor snapshot failed to restore")
	var replay_a := SimulationSnapshot.restore(snapshot)
	var replay_b := SimulationSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
	if replay_a != null and replay_b != null:
		var replay_kernel_a := SimulationKernel.new(replay_a)
		var replay_kernel_b := SimulationKernel.new(replay_b)
		for index in 120:
			replay_kernel_a.step_once()
			replay_kernel_b.step_once()
		_check(replay_a.canonical_fingerprint() == replay_b.canonical_fingerprint(), "same-seed abstract actor replay fingerprint diverged")
		_check(SimulationCanonicalJson.encode(replay_a.abstract_activity.causal_events) == SimulationCanonicalJson.encode(replay_b.abstract_activity.causal_events), "same-seed abstract actor events diverged")
	if restored != null:
		state = restored
		kernel = SimulationKernel.new(state)
		coordinator.queue_free()
		coordinator = ActorReificationCoordinator.new()
		root.add_child(coordinator)
		coordinator.bind(kernel, {"A": anchor_a, "B": anchor_b})
		var stored_group: Dictionary = state.abstract_activity.groups["%s::%s" % [DOMAIN, GROUP]]
		var stored_projection: Dictionary = stored_group.actor_projection
		stored_projection.health = stored_projection.max_health + 1.0
		var failed_stage_request := coordinator.request_physical(DOMAIN, GROUP, "B")
		kernel.step_once()
		_check(not bool(coordinator.take_result(failed_stage_request).get("ok", false)), "invalid staged Grunt projection committed")
		await process_frame
		_check(String(state.abstract_activity.get_group(DOMAIN, GROUP).representation) == "abstract", "failed staged restore changed simulation authority")
		_check(coordinator._find_actors(DOMAIN, ACTOR).is_empty(), "failed staged restore left a physical Grunt")
		stored_projection.health = 39.0
	var finite_anchor_position := anchor_b.global_position
	for invalid_x: float in [NAN, INF]:
		anchor_b.global_position = Vector2(invalid_x, finite_anchor_position.y)
		var before_invalid_anchor := state.abstract_activity.get_group(DOMAIN, GROUP).duplicate(true)
		var before_invalid_anchor_events := SimulationCanonicalJson.encode(state.abstract_activity.causal_events)
		var invalid_anchor_request := coordinator.request_physical(DOMAIN, GROUP, "B")
		kernel.step_once()
		_check(not bool(coordinator.take_result(invalid_anchor_request).get("ok", false)), "nonfinite physical anchor was accepted")
		_check(SimulationCanonicalJson.encode(state.abstract_activity.get_group(DOMAIN, GROUP)) == SimulationCanonicalJson.encode(before_invalid_anchor), "nonfinite anchor rejection changed abstract authority")
		_check(SimulationCanonicalJson.encode(state.abstract_activity.causal_events) == before_invalid_anchor_events, "nonfinite anchor rejection changed causal history")
		await process_frame
		_check(coordinator._find_actors(DOMAIN, ACTOR).is_empty(), "nonfinite anchor rejection leaked a physical Grunt")
	anchor_b.global_position = finite_anchor_position
	var reify_id := coordinator.request_physical(DOMAIN, GROUP, "B")
	kernel.step_once()
	var reify_result := coordinator.take_result(reify_id)
	_check(bool(reify_result.get("ok", false)), "abstract-to-physical transfer failed: %s" % reify_result.get("reason", "unknown"))
	var restored_actor: Enemy = reify_result.get("actor")
	_check(restored_actor != null and restored_actor.is_inside_tree(), "reification did not create a live Grunt")
	if restored_actor != null:
		_check(String(restored_actor.get_meta("actor_id", "")) == ACTOR, "reified actor identity changed")
		_check(String(restored_actor.get_meta("group_id", "")) == GROUP, "reified group identity changed")
		_check(is_equal_approx(restored_actor.health, 39.0), "reified actor health changed")
		_check(restored_actor.attack_objective == "defend_relay", "reified actor objective changed")
		_check(restored_actor.global_position == anchor_b.global_position, "reified actor used the wrong anchor")
		for index in 120:
			kernel.step_once()
		var physical_record := state.abstract_activity.get_group(DOMAIN, GROUP)
		_check(String(physical_record.location_id) == "B" and state.abstract_activity.causal_events.size() == 1, "abstract movement advanced while the actor was physical")
		_check(is_equal_approx(float(physical_record.condition), 0.5), "physical ownership changed actor condition")
		var second_unload := coordinator.request_abstract(DOMAIN, GROUP, restored_actor, "B")
		kernel.step_once()
		_check(bool(coordinator.take_result(second_unload).get("ok", false)), "second unload/reentry cycle failed to unload")
		var second_reentry := coordinator.request_physical(DOMAIN, GROUP, "B")
		kernel.step_once()
		var second_result := coordinator.take_result(second_reentry)
		_check(bool(second_result.get("ok", false)), "second unload/reentry cycle failed to reify")
		var second_actor: Enemy = second_result.get("actor")
		_check(second_actor != null and String(second_actor.get_meta("actor_id", "")) == ACTOR, "second reentry duplicated or changed identity")
	var repeat_id := coordinator.request_physical(DOMAIN, GROUP, "B")
	kernel.step_once()
	_check(not bool(coordinator.take_result(repeat_id).get("ok", false)), "repeated reentry created a duplicate actor")
	_finish()


func _check_legacy_v5_snapshot() -> void:
	var claims := AbstractActivitySimulationState.new()
	claims.register_location(DOMAIN, "A")
	claims.register_location(DOMAIN, "B")
	_check(claims.register_group(DOMAIN, GROUP, "A", "HOLD_SITE", ["A", "B"], 0, 1.0, 0.0, ACTOR), "initial actor identity claim failed")
	_check(not claims.register_group(DOMAIN, "SECOND_GROUP", "A", "HOLD_SITE", ["A", "B"], 0, 1.0, 0.0, ACTOR), "duplicate domain-scoped actor ID was accepted")
	var legacy_state := WorldSimulationState.new(77)
	legacy_state.abstract_activity.register_location(DOMAIN, "A")
	legacy_state.abstract_activity.register_location(DOMAIN, "B")
	legacy_state.abstract_activity.register_group(DOMAIN, GROUP, "A", "HOLD_SITE", ["A", "B"])
	var legacy_kernel := SimulationKernel.new(legacy_state)
	for index in 60:
		legacy_kernel.step_once()
	var snapshot := SimulationSnapshot.capture(legacy_state).to_dict()
	var activity: Dictionary = snapshot.state.abstract_activity
	activity.schema_version = 1
	for group: Dictionary in activity.groups:
		group.erase("actor_id")
		group.erase("representation")
		group.erase("actor_projection")
	for event: Dictionary in activity.causal_events:
		event.event_id = "%s.%s.%d" % [DOMAIN, GROUP, int(event.fixed_tick)]
	snapshot.fingerprint = SimulationCanonicalJson.sha256(snapshot.state)
	var migrated := SimulationSnapshot.restore(snapshot)
	_check(migrated != null, "schema-v5 snapshot with pre-correction event IDs did not migrate")
	if migrated != null:
		_check(migrated.abstract_activity.causal_events.size() == 1, "legacy migration lost the abstract activity event")
	var corrupted_fingerprint := snapshot.duplicate(true)
	corrupted_fingerprint.fingerprint = "corrupted"
	_check(SimulationSnapshot.restore(corrupted_fingerprint) == null, "schema-v5 migration accepted a corrupted incoming fingerprint")
	var stale_fingerprint := snapshot.duplicate(true)
	stale_fingerprint.state.seed = int(stale_fingerprint.state.seed) + 1
	_check(SimulationSnapshot.restore(stale_fingerprint) == null, "schema-v5 migration accepted payload tampering with a stale fingerprint")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("WORLD_SIMULATION_ACTOR_REIFICATION_HANDOFF_SMOKE: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
