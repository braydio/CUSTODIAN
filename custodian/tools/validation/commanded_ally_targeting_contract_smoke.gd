extends SceneTree

const DroneManagerScript := preload("res://game/systems/drone/drone_manager.gd")
const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const DroneTargetingScript := preload("res://game/systems/drone/drone_targeting.gd")
const ActorAllegianceScript := preload("res://game/actors/core/actor_allegiance_component.gd")
const AlliedDroidScene := preload("res://game/actors/allies/allied_infantry_droid.tscn")
const ShrumbScene := preload("res://game/actors/enemies/ambient_shrumb.tscn")


class SemanticTarget:
	extends Node2D

	const AllegianceScript := preload("res://game/actors/core/actor_allegiance_component.gd")

	var allegiance_component: ActorAllegianceComponent
	var health: float = 100.0
	var dead: bool = false
	var targetable: bool = true
	var passive: bool = false

	func _ready() -> void:
		allegiance_component = AllegianceScript.new()
		allegiance_component.name = "ActorAllegiance"
		add_child(allegiance_component)
		allegiance_component.configure(self, ActorAllegianceComponent.HOSTILE)

	func get_allegiance() -> StringName:
		return allegiance_component.get_allegiance() if allegiance_component != null else ActorAllegianceComponent.HOSTILE

	func set_allegiance(value: StringName) -> bool:
		return allegiance_component.set_allegiance(value) if allegiance_component != null else false

	func is_dead() -> bool:
		return dead

	func is_passive_enemy() -> bool:
		return passive

	func is_combat_targetable_by(_attacker: Node = null, _attacker_team: StringName = &"") -> bool:
		return targetable

	func take_damage(amount: float, _hit_strength: int = 0) -> void:
		health = maxf(0.0, health - amount)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var operator := Node2D.new()
	operator.name = "Operator"
	operator.add_to_group("player")
	world.add_child(operator)
	var allies := Node2D.new()
	allies.name = "Allies"
	world.add_child(allies)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	world.add_child(projectiles)

	var manager := DroneManagerScript.new()
	manager.name = "DroneManager"
	manager.spawn_on_ready = false
	manager.initial_active_drones = 0
	manager.drone_scene = AlliedDroidScene
	manager.announce_commands = false
	world.add_child(manager)
	await process_frame

	var drone := manager.spawn_drone(0) as CombatDrone
	_expect(drone != null, "Manager did not spawn an allied droid.")
	await process_frame
	_expect(drone is CombatDrone, "Allied droid did not inherit CombatDrone.")
	_expect(drone.get_allegiance() == ActorAllegianceComponent.OPERATOR_ALLIED, "CombatDrone lacks semantic operator_allied allegiance.")
	_expect(drone.is_in_group("ally") and not drone.is_in_group("enemy"), "Allegiance compatibility groups were not synchronized.")
	_expect(drone.is_in_group("allied_drone"), "CombatDrone lost its allied_drone discovery group.")
	_expect(not drone.is_in_group("defense") and not drone.is_in_group("turret"), "Allied droid changed its established projectile/defense groups.")

	var targeting := DroneTargetingScript.new()
	var neutral_passive := _new_target(world, "NeutralCommandTarget")
	neutral_passive.allegiance_component.set_allegiance(ActorAllegianceComponent.NEUTRAL)
	neutral_passive.passive = true
	neutral_passive.add_to_group("drone_command_target")
	_expect(targeting.is_valid_command_target(neutral_passive, drone), "Explicit opted-in neutral target was rejected.")
	_expect(not targeting.is_valid_autonomous_target(neutral_passive, drone), "Autonomous policy accepted an opted-in passive neutral target.")
	var navigation := Node.new()
	navigation.add_to_group("navigation")
	world.add_child(navigation)
	var shrumb := ShrumbScene.instantiate() as Node2D
	world.add_child(shrumb)
	await process_frame
	shrumb.set_physics_process(false)
	shrumb.global_position = drone.global_position + Vector2(24.0, 0.0)
	drone.call("_refresh_target")
	_expect(drone.target != shrumb, "Autonomous targeting acquired passive Shrumb.")
	_expect(not targeting.is_valid_autonomous_target(shrumb, drone), "Autonomous policy accepted passive Shrumb.")
	_expect(manager.call("_resolve_hostile_at_position", shrumb.global_position) == shrumb, "Manager did not resolve opted-in passive Shrumb for explicit selection.")
	manager.issue_target_order(shrumb)
	_expect(drone.command_target == shrumb and drone.target == shrumb, "Manager did not pass explicit Shrumb order to the drone.")
	var count_before := projectiles.get_child_count()
	_start_burst(drone)
	_expect(projectiles.get_child_count() == count_before + 1, "Explicit passive Shrumb command did not emit a real projectile.")
	var shrumb_bullet := projectiles.get_child(projectiles.get_child_count() - 1)
	_expect(shrumb_bullet.get("shooter") == drone and shrumb_bullet.get("team") == "defense", "Explicit Shrumb projectile lost drone shooter/team identity.")
	_expect(shrumb_bullet.call("_can_hit", shrumb), "Explicit passive Shrumb projectile is not accepted by live projectile qualification.")
	manager.return_to_operator_follow()

	var hostile := _new_target(world, "Hostile")
	hostile.global_position = drone.global_position + Vector2(80.0, 0.0)
	drone.call("_refresh_target")
	_expect(drone.target == hostile, "Autonomous scan did not acquire a live semantic hostile.")
	_expect(targeting.is_valid_autonomous_target(hostile, drone), "Live hostile failed autonomous eligibility.")
	manager.issue_target_order(hostile)
	count_before = projectiles.get_child_count()
	_start_burst(drone)
	_expect(projectiles.get_child_count() == count_before + 1, "Manager-issued hostile order did not emit a real projectile.")
	var hostile_bullet := projectiles.get_child(projectiles.get_child_count() - 1)
	var hostile_health_before: float = hostile.health
	_expect(hostile_bullet.call("_can_hit", hostile), "Emitted projectile rejected its eligible hostile.")
	hostile_bullet.call("_handle_body_hit", hostile, hostile.global_position, Vector2.ZERO)
	_expect(hostile.health < hostile_health_before, "Emitted projectile did not apply damage through the real bullet hit path.")

	var prefire_flip := _new_target(world, "PrefireFlipTarget")
	prefire_flip.global_position = drone.global_position + Vector2(85.0, 0.0)
	manager.issue_target_order(prefire_flip)
	count_before = projectiles.get_child_count()
	drone.set("_fire_cooldown_timer", 0.0)
	drone.call("_update_weapon") # queues the first burst round, but does not commit a projectile
	prefire_flip.set_allegiance(ActorAllegianceComponent.OPERATOR_ALLIED)
	drone.call("_update_weapon")
	_expect(projectiles.get_child_count() == count_before, "Target allegiance changed before the first projectile, but the drone still fired.")
	_expect(int(drone.get("_burst_remaining")) == 0, "Prefire allegiance change did not cancel the queued burst.")

	# A target that becomes allied after the first burst round cannot receive the
	# queued round. The manager also prunes its retained order on its next tick.
	manager.issue_target_order(hostile)
	_start_burst(drone)
	hostile.set_allegiance(ActorAllegianceComponent.OPERATOR_ALLIED)
	manager.call("_process", 0.0)
	count_before = projectiles.get_child_count()
	drone.call("_update_weapon")
	_expect(projectiles.get_child_count() == count_before, "Queued burst fired after the target became allied.")
	_expect(int(drone.get("_burst_remaining")) == 0, "Allegiance change did not cancel the queued burst.")
	_expect(manager.get("_command_target") == null, "Manager retained a newly allied command target.")
	# Direct actor setters obey the same policy as manager-issued orders.
	drone.call("set_command_target", hostile)
	_expect(drone.command_target == null and drone.target == null, "Direct set_command_target bypassed allied-target rejection.")

	var untargetable := _new_target(world, "Untargetable")
	untargetable.global_position = drone.global_position + Vector2(90.0, 0.0)
	manager.issue_target_order(untargetable)
	_start_burst(drone)
	count_before = projectiles.get_child_count()
	untargetable.targetable = false
	manager.call("_process", 0.0)
	drone.call("_update_weapon")
	_expect(projectiles.get_child_count() == count_before, "Queued burst fired after targetability was revoked.")
	_expect(int(drone.get("_burst_remaining")) == 0, "Targetability change did not cancel the queued burst.")

	var dead_target := _new_target(world, "DeadTarget")
	dead_target.global_position = drone.global_position + Vector2(100.0, 0.0)
	manager.issue_target_order(dead_target)
	_start_burst(drone)
	count_before = projectiles.get_child_count()
	dead_target.dead = true
	manager.call("_process", 0.0)
	drone.call("_update_weapon")
	_expect(projectiles.get_child_count() == count_before, "Queued burst fired after the target died.")
	_expect(int(drone.get("_burst_remaining")) == 0, "Death did not cancel the queued burst.")

	var freed_target := _new_target(world, "FreedTarget")
	freed_target.global_position = drone.global_position + Vector2(110.0, 0.0)
	manager.issue_target_order(freed_target)
	_start_burst(drone)
	count_before = projectiles.get_child_count()
	freed_target.free()
	manager.call("_process", 0.0)
	drone.call("_update_weapon")
	_expect(projectiles.get_child_count() == count_before, "Queued burst fired after its target was freed.")
	_expect(int(drone.get("_burst_remaining")) == 0, "Freed target did not cancel the queued burst.")

	var first_order_target := _new_target(world, "FirstOrderTarget")
	var replacement_order_target := _new_target(world, "ReplacementOrderTarget")
	first_order_target.global_position = drone.global_position + Vector2(90.0, 0.0)
	replacement_order_target.global_position = drone.global_position + Vector2(95.0, 0.0)
	manager.issue_target_order(first_order_target)
	_start_burst(drone)
	count_before = projectiles.get_child_count()
	manager.issue_target_order(replacement_order_target)
	drone.call("_update_weapon")
	_expect(projectiles.get_child_count() == count_before, "Queued burst continued after its explicit order changed.")
	_expect(int(drone.get("_burst_remaining")) == 0, "Order change did not cancel the queued burst.")
	_expect(drone.command_target == replacement_order_target, "Replacement explicit target was not retained.")

	var destroyed_id: String = drone.drone_id
	drone.call("take_damage", 999.0)
	var destroyed_summary: Dictionary = manager.get_squad_summary()
	_expect(int(destroyed_summary.get("live_count", -1)) == 0, "Destroyed drone remained in the active squad summary.")
	_expect((destroyed_summary.get("destroyed", []) as Array).has(destroyed_id), "Destroyed slot identity was not recorded.")
	var replacement := manager.spawn_drone(0) as CombatDrone
	_expect(replacement != null and replacement.drone_id == destroyed_id, "Replacement did not reuse the manager-scoped squad slot identity.")
	await process_frame
	var replacement_summary: Dictionary = manager.get_squad_summary()
	_expect((replacement_summary.get("active", []) as Array).has(destroyed_id), "Replacement was not registered in the active squad summary.")
	_expect((replacement_summary.get("destroyed", []) as Array).has(destroyed_id), "Squad summary lost the prior destruction record for its recycled slot.")

	game_root.queue_free()
	await process_frame
	print("[CommandedAllyTargetingContractSmoke] failures=%d" % _failure_count)
	quit(0 if _failure_count == 0 else 1)


var _failure_count: int = 0


func _new_target(parent: Node, target_name: String) -> SemanticTarget:
	var target := SemanticTarget.new()
	target.name = target_name
	parent.add_child(target)
	return target


func _start_burst(drone: CombatDrone) -> void:
	drone.set("_fire_cooldown_timer", 0.0)
	drone.set("_burst_remaining", 0)
	drone.set("_burst_gap_timer", 0.0)
	drone.call("_update_weapon")
	drone.call("_update_weapon")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
