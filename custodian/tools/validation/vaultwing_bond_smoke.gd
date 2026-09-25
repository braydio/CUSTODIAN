extends SceneTree

const VAULTWING_SCENE := preload("res://game/actors/ambient/vaultwing/vaultwing.tscn")
const TURRET_SCENE := preload("res://game/actors/defense/turret.tscn")
const DRONE_SCENE := preload("res://game/actors/allies/combat_drone.tscn")
const SPAWNER_SCRIPT := preload("res://game/systems/spawning/vaultwing_spawner.gd")
const BondState := preload("res://game/actors/ambient/vaultwing/vaultwing_bond_state.gd")
const Relationship := preload("res://game/systems/combat/actor_relationship_resolver.gd")

var failures: PackedStringArray = PackedStringArray()

func _init() -> void:
	await _run()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({"schema":"custodian.headless_test.result.v1", "test":"vaultwing_bond_smoke", "passed":failures.is_empty(), "failures":failures}))
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var player := Node2D.new()
	player.name = "Operator"
	player.add_to_group("player")
	root.add_child(player)
	var enemy := Node2D.new()
	enemy.name = "HostileEnemy"
	enemy.add_to_group("enemy")
	root.add_child(enemy)
	var vaultwing := VAULTWING_SCENE.instantiate()
	root.add_child(vaultwing)
	await physics_frame
	vaultwing.global_position = Vector2.ZERO
	player.global_position = Vector2(120.0, 0.0)
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	var actor_id: int = vaultwing.get_instance_id()
	var behavior_id: int = vaultwing.behavior.get_instance_id()
	var presentation_id: int = vaultwing.presentation.get_instance_id()
	var health_before: float = vaultwing.health

	# Feeder, bait, and interaction-state gates are explicit and report rejection.
	if vaultwing.offer_bait(&"vaultwing_bait", null): _fail("null feeder was accepted")
	if vaultwing.offer_bait(&"invalid_bait", player): _fail("invalid bait was accepted")
	if vaultwing.get_bond_state().peaceful_feed_count != 0: _fail("rejected bait advanced progress")
	for unsafe_state in [VaultwingBehaviorController.State.GROUND_ATTACK, VaultwingBehaviorController.State.GROUND_STALK, VaultwingBehaviorController.State.GROUND_STAGGER, VaultwingBehaviorController.State.LAND, VaultwingBehaviorController.State.TAKEOFF, VaultwingBehaviorController.State.RETREAT]:
		vaultwing.behavior.force_state(unsafe_state)
		if vaultwing.offer_bait(&"vaultwing_bait", player): _fail("bait was accepted during %s" % VaultwingBehaviorController.State.keys()[unsafe_state])
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.PERCH_IDLE)
	if not vaultwing.offer_bait(&"vaultwing_bait", player): _fail("safe perched feeding was rejected")
	vaultwing.get_bond_state().call("interrupt_interaction", &"smoke_cancel")
	if vaultwing.get_bond_state().peaceful_feed_count != 0: _fail("cancelled perch interaction advanced progress")
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	if vaultwing.complete_bond_trial(&"vaultwing_bait", null): _fail("bond trial accepted a null feeder")
	if not vaultwing.offer_bait(&"vaultwing_bait", player): _fail("valid feed attempt did not start")
	if vaultwing.offer_bait(&"invalid_bait", player): _fail("invalid bait did not interrupt active attempt")
	if vaultwing.get_bond_state().is_feed_attempt_active() or vaultwing.get_bond_state().peaceful_feed_count != 0:
		_fail("invalid bait interruption advanced progress or left attempt active")

	if not await _peaceful_feed(vaultwing, player, 1):
		_fail("first completed feed did not enter OBSERVING")
	if vaultwing.get_bond_stage() != BondState.OBSERVING: _fail("first completed feed did not enter OBSERVING")
	# Four instantaneous API calls in one encounter cannot farm stage progression.
	for _i in range(3):
		if vaultwing.offer_bait(&"vaultwing_bait", player): _fail("same-encounter bait spam was accepted")
	if vaultwing.get_bond_stage() != BondState.OBSERVING: _fail("same encounter advanced beyond OBSERVING")

	# Interrupt a valid observation by leaving range; historical progress remains.
	player.global_position += Vector2(420.0, 0.0)
	await create_timer(2.6).timeout
	player.global_position = vaultwing.global_position + Vector2(120.0, 0.0)
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	if not vaultwing.offer_bait(&"vaultwing_bait", player): _fail("valid second encounter did not start: %s" % vaultwing.get_bond_state().last_rejection_reason)
	player.global_position += Vector2(500.0, 0.0)
	await create_timer(0.2).timeout
	if vaultwing.get_bond_state().peaceful_feed_count != 1: _fail("interrupted feed advanced progress")
	if vaultwing.get_bond_stage() != BondState.OBSERVING: _fail("interrupted feed erased or changed stage")

	# Stage policy is semantic and visibly relaxes distance/escalation.
	var bond_state = vaultwing.get_bond_state()
	var wild_radius: float = bond_state.get_operator_tolerance_radius()
	var wild_delay: float = bond_state.get_escalation_delay()
	var feed_count := 1
	for expected_stage in [BondState.TOLERANT, BondState.TOLERANT, BondState.ACCEPTING]:
		if not await _peaceful_feed(vaultwing, player, feed_count + 1):
			_fail("separated peaceful encounter was not accepted")
		feed_count += 1
		if vaultwing.get_bond_stage() != expected_stage:
			_fail("feed %d expected %s, got %s" % [feed_count, expected_stage, vaultwing.get_bond_stage()])
		if feed_count == 2:
			if bond_state.get_operator_tolerance_radius() <= wild_radius: _fail("OBSERVING tolerance did not change")
			if bond_state.get_escalation_delay() <= wild_delay: _fail("OBSERVING escalation policy did not change")
	if vaultwing.get_bond_stage() != BondState.ACCEPTING: _fail("repeated separated feeding did not reach ACCEPTING")
	if bond_state.get_min_safe_approach_distance() >= wild_radius: _fail("stage policies do not permit progressively closer approach")

	# A trial starts behaviorally, lands voluntarily, observes, then allows close approach.
	player.global_position = vaultwing.global_position + Vector2(240.0, 0.0)
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	if not vaultwing.begin_bond_trial_with(player): _fail("valid voluntary bond trial did not start: %s stage=%s" % [bond_state.last_rejection_reason, bond_state.stage])
	if not bond_state.is_bond_trial_active(): _fail("trial did not become active")
	var trial_trace := ["start:%s@%s" % [vaultwing.get_state_name(), vaultwing.global_position]]
	for _i in range(7):
		await create_timer(0.45).timeout
		trial_trace.append("%s/%s@%s d=%.1f target=%s pending=%s" % [vaultwing.get_state_name(), vaultwing.get_altitude_band_name(), vaultwing.global_position, vaultwing.global_position.distance_to(player.global_position), str(vaultwing.behavior.target), vaultwing.behavior._pending_after_takeoff])
	if not bond_state.is_bond_trial_active(): _fail("trial cancelled before voluntary landing/observation (trace=%s)" % [trial_trace])
	if bond_state.trial_phase != &"guarded_observation": _fail("voluntary approach did not transition to guarded observation (phase=%s state=%s band=%s distance=%.1f trace=%s)" % [bond_state.trial_phase, vaultwing.get_state_name(), vaultwing.get_altitude_band_name(), vaultwing.global_position.distance_to(player.global_position), trial_trace])
	player.global_position = vaultwing.global_position + Vector2(45.0, 0.0)
	await create_timer(0.1).timeout
	if bond_state.is_bond_trial_active(): _fail("rushed approach did not interrupt trial")
	if vaultwing.get_bond_stage() != BondState.ACCEPTING: _fail("interrupted trial erased ACCEPTING stage")

	# Operator violence also cancels a live trial without erasing earned progress.
	player.global_position = vaultwing.global_position + Vector2(240.0, 0.0)
	if not vaultwing.begin_bond_trial_with(player): _fail("attack-interruption trial did not start")
	await create_timer(3.15).timeout
	if bond_state.trial_phase != &"guarded_observation": _fail("attack-interruption trial did not reach guarded observation")
	vaultwing.take_damage_from(1.0, 0, -1.0, player)
	if bond_state.is_bond_trial_active(): _fail("Operator attack did not interrupt bond trial")
	if vaultwing.get_bond_stage() != BondState.ACCEPTING: _fail("Operator attack erased ACCEPTING progress")

	# Repeat with a controlled approach and final direct feed.
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	player.global_position = vaultwing.global_position + Vector2(240.0, 0.0)
	if not vaultwing.begin_bond_trial_with(player): _fail("second valid trial did not start: %s stage=%s" % [bond_state.last_rejection_reason, bond_state.stage])
	await create_timer(3.15).timeout
	if bond_state.trial_phase != &"guarded_observation": _fail("second trial did not land for guarded observation")
	await create_timer(1.25).timeout
	if bond_state.trial_phase != &"final_feed_ready": _fail("guarded observation did not unlock final feed")
	player.global_position = vaultwing.global_position + Vector2(54.0, 0.0)
	var before_bond_health: float = vaultwing.health
	var seed_state_before_bond: int = vaultwing.behavior._rng.state
	if not vaultwing.complete_bond_trial(&"vaultwing_bait", player): _fail("valid final direct feed did not complete trial")
	if vaultwing.get_bond_stage() != BondState.BONDED: _fail("valid trial did not reach BONDED")
	if vaultwing.get_allegiance() != ActorAllegianceComponent.OPERATOR_ALLIED: _fail("bonded Vaultwing did not become Operator-allied")
	if vaultwing.get_instance_id() != actor_id or vaultwing.behavior.get_instance_id() != behavior_id: _fail("bonding replaced the actor or behavior controller")
	if vaultwing.health != before_bond_health or vaultwing.health > health_before: _fail("bonding unexpectedly reset or changed health")
	if vaultwing.behavior.target == player: _fail("bond completion retained Operator as hostile target")
	if vaultwing.behavior.target_position_valid or vaultwing.behavior._pending_after_takeoff != &"": _fail("bond completion retained pending Operator hostility intent")
	if vaultwing.behavior._rng.state != seed_state_before_bond or vaultwing.presentation.get_instance_id() != presentation_id: _fail("bond transition replaced seed or presentation authority")
	if vaultwing.is_in_group("enemy") or not vaultwing.is_in_group("ally"): _fail("bonded compatibility groups were not synchronized")
	if Relationship.can_target(player, vaultwing, &"player"): _fail("player still sees bonded Vaultwing as hostile target")

	# Actual source attribution: only a known hostile attacker becomes a threat.
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	vaultwing.take_damage_from(2.0, 0, -1.0, enemy)
	if vaultwing.behavior.target != enemy: _fail("hostile enemy damage did not establish attacker as threat")
	vaultwing.behavior._clear_target()
	vaultwing.take_damage(1.0)
	if vaultwing.behavior.target == player: _fail("unknown damage defaulted to Operator hostility")

	# Persistent identity is stable for durable provenance, not seed/creation order.
	var provenance_a := VAULTWING_SCENE.instantiate()
	var provenance_b := VAULTWING_SCENE.instantiate()
	root.add_child(provenance_a); root.add_child(provenance_b)
	await physics_frame
	provenance_a.set_spawn_provenance("contract-alpha", "vaultwing_common_spawn_00")
	provenance_b.set_spawn_provenance("contract-alpha", "vaultwing_common_spawn_01")
	if provenance_a.get_stable_creature_id() == provenance_b.get_stable_creature_id(): _fail("distinct spawn provenance produced duplicate stable IDs")
	var stable_id: StringName = vaultwing.get_stable_creature_id()
	var saved: Dictionary = vaultwing.to_save_dict()
	if saved.get("schema") != "custodian.vaultwing_bond.v1" or saved.get("species_id") != "vaultwing_common": _fail("save omitted version/species identity")
	if saved.get("stable_creature_id") != String(stable_id) or saved.get("health") != vaultwing.health: _fail("save omitted stable identity/health")
	var restored := VAULTWING_SCENE.instantiate()
	root.add_child(restored)
	await physics_frame
	restored.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	player.global_position = restored.global_position + Vector2(120.0, 0.0)
	if not restored.offer_bait(&"vaultwing_bait", player): _fail("restore fixture could not start transient feed attempt")
	restored.behavior._remember_target(player.global_position, player)
	if not restored.from_save_dict(saved): _fail("valid bond save did not restore")
	if restored.get_bond_stage() != BondState.BONDED or restored.get_allegiance() != ActorAllegianceComponent.OPERATOR_ALLIED: _fail("restored save lost stage/allegiance")
	if restored.health != vaultwing.health or restored.max_health != vaultwing.max_health: _fail("save restore did not preserve health values")
	if restored.get_bond_state().is_feed_attempt_active() or restored.get_bond_state().is_bond_trial_active(): _fail("restore retained transient feed/trial state")
	if restored.behavior.target == player or restored.behavior.target_position_valid: _fail("bonded restore retained Operator hostility")
	var malformed: Dictionary = saved.duplicate(true); malformed["stage"] = "bogus"
	if restored.from_save_dict(malformed): _fail("malformed bond save was accepted")
	malformed = saved.duplicate(true); malformed["health"] = "not-a-number"
	if restored.from_save_dict(malformed): _fail("malformed health data was accepted")

	# A bonded actor remains physical and does not consume or die with wild-world population.
	var ambient := Node2D.new(); ambient.name = "Ambient"; root.add_child(ambient)
	var spawner = SPAWNER_SCRIPT.new()
	spawner.max_active_vaultwings = 1
	spawner.vaultwing_container_path = NodePath("/root/Ambient")
	root.add_child(spawner)
	var managed: Vaultwing = spawner.spawn_at(Vector2(600.0, 0.0), 11, "contract-alpha", "spawn-managed")
	if managed == null: _fail("wild population fixture did not spawn")
	managed.from_save_dict(saved)
	if spawner.get_active_count() != 0: _fail("bonded actor consumed wild population cap")
	spawner.reset_for_world()
	if not is_instance_valid(managed) or managed.is_queued_for_deletion(): _fail("world reset deleted bonded persistent Vaultwing")
	var replacement: Vaultwing = spawner.spawn_at(Vector2(700.0, 0.0), 12, "contract-beta", "spawn-replacement")
	if replacement == null: _fail("bonded actor prevented replacement wild spawn")

	# Direct retained-target regression: the same live systems relinquish new allies.
	vaultwing.set_allegiance(ActorAllegianceComponent.HOSTILE)
	vaultwing.global_position = Vector2.ZERO
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.DIVE_WINDUP)
	var turret = TURRET_SCENE.instantiate()
	root.add_child(turret)
	turret.set_physics_process(false)
	await physics_frame
	turret._on_enemy_enter(vaultwing)
	turret.target = vaultwing
	if turret.target != vaultwing: _fail("turret failed to acquire hostile fixture")
	var drone = DRONE_SCENE.instantiate()
	root.add_child(drone)
	drone.set_physics_process(false)
	await physics_frame
	drone.set_command_target(vaultwing)
	vaultwing.set_allegiance(ActorAllegianceComponent.OPERATOR_ALLIED)
	turret.reconcile_relationship_targets()
	drone._refresh_target()
	if turret.target == vaultwing: _fail("turret retained newly allied Vaultwing")
	if drone.target == vaultwing or drone.command_target == vaultwing: _fail("drone retained newly allied Vaultwing")
	vaultwing.set_allegiance(ActorAllegianceComponent.HOSTILE)
	await physics_frame
	turret.reconcile_relationship_targets()
	if not turret.enemies_in_range.has(vaultwing): _fail("turret did not reacquire still-overlapping newly hostile Vaultwing")

	for node in [vaultwing, restored, provenance_a, provenance_b, managed, replacement, spawner, ambient, turret, drone, enemy, player]:
		if is_instance_valid(node): node.queue_free()

func _peaceful_feed(vaultwing: Node, feeder: Node2D, expected_count: int) -> bool:
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	feeder.global_position = vaultwing.global_position + Vector2(120.0, 0.0)
	if not vaultwing.offer_bait(&"vaultwing_bait", feeder):
		print("feed offer rejected count=%d expected=%d reason=%s state=%s distance=%.1f" % [vaultwing.get_bond_state().peaceful_feed_count, expected_count, vaultwing.get_bond_state().last_rejection_reason, vaultwing.get_state_name(), vaultwing.global_position.distance_to(feeder.global_position)])
		return false
	if int(vaultwing.get_bond_state().peaceful_feed_count) == expected_count: return false
	if vaultwing.is_bait_approach_complete(): return false
	for _i in range(210):
		if int(vaultwing.get_bond_state().peaceful_feed_count) == expected_count: break
		await physics_frame
	var count := int(vaultwing.get_bond_state().peaceful_feed_count)
	if count != expected_count:
		return false
	feeder.global_position += Vector2(420.0, 0.0)
	for _i in range(160):
		if vaultwing.get_bond_state()._encounter_cooldown <= 0.0 and not vaultwing.get_bond_state()._must_separate: break
		await physics_frame
	return true

func _fail(message: String) -> void:
	failures.append(message)
