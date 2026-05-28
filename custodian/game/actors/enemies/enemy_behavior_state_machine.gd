extends Node
class_name EnemyBehaviorStateMachine

const ENEMY_BEHAVIOR_PROFILE_SCRIPT := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")

const IDLE := &"idle"
const PATROL := &"patrol"
const INVESTIGATE := &"investigate"
const NOTICE := &"notice"
const ENGAGE_OPERATOR := &"engage_operator"
const SEEK_OBJECTIVE := &"seek_objective"
const OPEN_STORAGE := &"open_storage"
const STEAL_RESOURCES := &"steal_resources"
const ESCAPE_WITH_LOOT := &"escape_with_loot"
const FLEE := &"flee"
const STUNNED := &"stunned"
const DEAD := &"dead"

@export var enabled: bool = true
@export var profile_id: StringName = &"raider_grunt"
@export var notice_duration_sec: float = 0.35
@export var idle_rescore_interval_sec: float = 0.65
@export var storage_interact_range_px: float = 42.0
@export var exit_reached_range_px: float = 36.0
@export var debug_enabled: bool = false

var profile: Resource = null
var blackboard: Node = null
var perception: Node = null
var objective_sensor: Node = null
var loot_carrier: Node = null
var current_state: StringName = IDLE
var state_time: float = 0.0
var _rescore_timer: float = 0.0
var _storage_timer: float = 0.0
var _patrol_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	profile = ENEMY_BEHAVIOR_PROFILE_SCRIPT.create_profile(profile_id)
	_resolve_components()
	if blackboard != null:
		blackboard.home_position = (get_parent() as Node2D).global_position if get_parent() is Node2D else Vector2.ZERO
		blackboard.morale = profile.morale_max
	change_state(IDLE)


func setup_profile(id: StringName) -> void:
	profile_id = id
	profile = ENEMY_BEHAVIOR_PROFILE_SCRIPT.create_profile(profile_id)
	if blackboard != null:
		blackboard.morale = profile.morale_max


func physics_update(enemy: Node2D, delta: float) -> bool:
	if not enabled or enemy == null or profile == null:
		return false
	_resolve_components()
	if blackboard == null or perception == null or objective_sensor == null or loot_carrier == null:
		return false
	state_time += delta
	_rescore_timer -= delta
	if blackboard.investigation_timer > 0.0:
		blackboard.investigation_timer = maxf(0.0, blackboard.investigation_timer - delta)
	perception.update_perception(enemy, profile, blackboard, delta)
	blackboard.is_carrying_loot = loot_carrier.is_carrying_loot()
	blackboard.carried_resources = loot_carrier.carried_resources.duplicate(true)

	match current_state:
		IDLE:
			_update_idle(enemy, delta)
		PATROL:
			_update_patrol(enemy, delta)
		INVESTIGATE:
			_update_investigate(enemy, delta)
		NOTICE:
			_update_notice(enemy, delta)
		ENGAGE_OPERATOR:
			_update_engage_operator(enemy, delta)
		SEEK_OBJECTIVE:
			_update_seek_objective(enemy, delta)
		OPEN_STORAGE:
			_update_open_storage(enemy, delta)
		STEAL_RESOURCES:
			_update_steal_resources(enemy, delta)
		ESCAPE_WITH_LOOT:
			_update_escape_with_loot(enemy, delta)
		FLEE:
			_update_flee(enemy, delta)
		STUNNED:
			enemy.call("behavior_stop")
		DEAD:
			enemy.call("behavior_stop")
		_:
			change_state(IDLE)
	return true


func change_state(new_state: StringName) -> void:
	if current_state == new_state and state_time > 0.0:
		return
	current_state = new_state
	state_time = 0.0
	_storage_timer = 0.0
	if debug_enabled:
		print("[EnemyBehavior] %s -> %s" % [get_parent().name if get_parent() != null else "enemy", String(new_state)])


func on_damaged(enemy: Node, amount: float) -> void:
	if blackboard != null and profile != null:
		blackboard.morale = maxf(0.0, blackboard.morale - amount * 0.25)
	if loot_carrier != null and loot_carrier.is_carrying_loot() and profile != null:
		var roll := _stable_damage_roll(enemy)
		if roll < profile.drop_loot_on_hit_chance:
			loot_carrier.drop_payload(enemy)
			if blackboard != null:
				blackboard.is_carrying_loot = false
				blackboard.carried_resources.clear()
			change_state(FLEE)


func on_enemy_died(enemy: Node) -> void:
	change_state(DEAD)
	if loot_carrier != null:
		loot_carrier.drop_payload(enemy)


func force_steal() -> void:
	change_state(SEEK_OBJECTIVE)


func force_notice(operator: Node = null) -> void:
	if blackboard != null and operator is Node2D:
		blackboard.operator_ref = operator
		blackboard.last_known_operator_position = (operator as Node2D).global_position
		blackboard.has_seen_operator = true
		blackboard.is_alerted = true
	change_state(NOTICE)


func get_debug_snapshot() -> Dictionary:
	return {
		"enabled": enabled,
		"profile_id": String(profile_id),
		"state": String(current_state),
		"state_time": state_time,
		"detection": perception.detection_meter if perception != null else 0.0,
		"blackboard": blackboard.get_debug_snapshot() if blackboard != null else {},
	}


func _update_idle(enemy: Node2D, _delta: float) -> void:
	enemy.call("behavior_stop")
	if _evaluate_interrupts(enemy):
		return
	if _rescore_timer <= 0.0:
		_rescore_timer = idle_rescore_interval_sec
		var objective: Dictionary = objective_sensor.call("choose_objective", enemy, profile, blackboard)
		_apply_objective_choice(objective)


func _update_patrol(enemy: Node2D, _delta: float) -> void:
	if _evaluate_interrupts(enemy):
		return
	if _patrol_target == Vector2.ZERO or enemy.global_position.distance_to(_patrol_target) <= 18.0:
		_patrol_target = blackboard.home_position + Vector2(96.0, 0.0).rotated(float((Time.get_ticks_msec() / 500) % 8) * TAU / 8.0)
	enemy.call("behavior_move_toward", _patrol_target, profile.patrol_speed)
	if _rescore_timer <= 0.0:
		_rescore_timer = idle_rescore_interval_sec
		_apply_objective_choice(objective_sensor.call("choose_objective", enemy, profile, blackboard))


func _update_investigate(enemy: Node2D, _delta: float) -> void:
	if blackboard.is_alerted and blackboard.operator_ref != null:
		change_state(NOTICE)
		return
	var target_pos: Vector2 = blackboard.get("investigation_position")
	if target_pos == Vector2.ZERO:
		change_state(PATROL)
		return
	if enemy.global_position.distance_to(target_pos) > 22.0:
		enemy.call("behavior_move_toward", target_pos, profile.investigate_speed)
		return
	enemy.call("behavior_stop")
	if state_time >= 1.0:
		blackboard.is_suspicious = false
		change_state(PATROL)


func _update_notice(enemy: Node2D, _delta: float) -> void:
	enemy.call("behavior_stop")
	if state_time >= notice_duration_sec:
		if blackboard.morale <= profile.morale_panic_threshold:
			change_state(FLEE)
		else:
			change_state(ENGAGE_OPERATOR)


func _update_engage_operator(enemy: Node2D, _delta: float) -> void:
	if blackboard.is_carrying_loot and profile.self_preservation_weight >= profile.aggression_weight:
		change_state(ESCAPE_WITH_LOOT)
		return
	var operator := blackboard.operator_ref as Node2D
	if operator == null or not is_instance_valid(operator):
		if blackboard.investigation_position != Vector2.ZERO:
			change_state(INVESTIGATE)
		else:
			change_state(PATROL)
		return
	enemy.set("target", operator)
	if enemy.global_position.distance_to(operator.global_position) > 40.0:
		enemy.call("behavior_move_toward", operator.global_position, profile.engage_speed)
	else:
		enemy.call("behavior_attack_target")


func _update_seek_objective(enemy: Node2D, _delta: float) -> void:
	if _evaluate_operator_interrupt_for_storage():
		change_state(NOTICE)
		return
	var storage := blackboard.get("target_storage") as Node2D
	if storage == null or not is_instance_valid(storage):
		_apply_objective_choice(objective_sensor.choose_objective(enemy, profile, blackboard))
		return
	if storage.has_method("has_resources") and not bool(storage.call("has_resources")):
		change_state(IDLE)
		return
	if enemy.global_position.distance_to(storage.global_position) > storage_interact_range_px:
		enemy.call("behavior_move_toward", storage.global_position, profile.objective_speed)
	else:
		change_state(OPEN_STORAGE)


func _update_open_storage(enemy: Node2D, delta: float) -> void:
	enemy.call("behavior_stop")
	_storage_timer += delta
	var storage: Node = blackboard.get("target_storage")
	var open_time: float = float(profile.get("storage_open_seconds"))
	if storage != null and "open_seconds" in storage:
		open_time = float(storage.get("open_seconds"))
	if _storage_timer >= open_time:
		change_state(STEAL_RESOURCES)


func _update_steal_resources(enemy: Node2D, delta: float) -> void:
	enemy.call("behavior_stop")
	_storage_timer += delta
	if _storage_timer < profile.stealing_seconds:
		return
	var storage: Node = blackboard.get("target_storage")
	var manager := _get_vault_manager(enemy)
	if manager == null or storage == null:
		change_state(IDLE)
		return
	var payload = manager.call("steal_from_storage", storage, profile.max_resource_types_to_steal, profile.max_total_resource_units, enemy)
	if payload is Dictionary and not payload.is_empty():
		loot_carrier.set_payload(payload)
		blackboard.carried_resources = payload.duplicate(true)
		blackboard.is_carrying_loot = true
		change_state(ESCAPE_WITH_LOOT)
	else:
		change_state(IDLE)


func _update_escape_with_loot(enemy: Node2D, _delta: float) -> void:
	var manager := _get_vault_manager(enemy)
	if manager == null:
		change_state(FLEE)
		return
	if blackboard.target_exit == null or not is_instance_valid(blackboard.target_exit):
		blackboard.target_exit = manager.call("find_nearest_exit", enemy.global_position)
	var exit_node := blackboard.target_exit as Node2D
	if exit_node == null:
		change_state(FLEE)
		return
	if enemy.global_position.distance_to(exit_node.global_position) <= exit_reached_range_px:
		manager.call("commit_lost_resources", enemy, loot_carrier.carried_resources)
		loot_carrier.clear_payload()
		enemy.queue_free()
		return
	enemy.call("behavior_move_toward", exit_node.global_position, profile.objective_speed * profile.loot_escape_speed_mult)


func _update_flee(enemy: Node2D, _delta: float) -> void:
	if loot_carrier.is_carrying_loot() and profile.abandon_loot_on_panic:
		loot_carrier.drop_payload(enemy)
	var manager := _get_vault_manager(enemy)
	var exit_node: Node2D = manager.call("find_nearest_exit", enemy.global_position) if manager != null else null
	if exit_node == null:
		enemy.call("behavior_move_toward", blackboard.home_position, profile.flee_speed)
		return
	if enemy.global_position.distance_to(exit_node.global_position) <= exit_reached_range_px:
		enemy.queue_free()
		return
	enemy.call("behavior_move_toward", exit_node.global_position, profile.flee_speed)


func _evaluate_interrupts(enemy: Node2D) -> bool:
	if blackboard.is_alerted and blackboard.operator_ref != null:
		change_state(NOTICE)
		return true
	if blackboard.is_suspicious and blackboard.investigation_timer > 0.0:
		change_state(INVESTIGATE)
		return true
	var objective: Dictionary = objective_sensor.call("choose_objective", enemy, profile, blackboard)
	if float(objective.get("score", 0.0)) > 0.0:
		_apply_objective_choice(objective)
		return current_state != IDLE and current_state != PATROL
	return false


func _evaluate_operator_interrupt_for_storage() -> bool:
	if not blackboard.is_alerted or blackboard.operator_ref == null:
		return false
	return profile.aggression_weight >= profile.theft_weight or blackboard.morale <= profile.morale_panic_threshold


func _apply_objective_choice(objective: Dictionary) -> void:
	match StringName(str(objective.get("type", "none"))):
		&"exit":
			change_state(ESCAPE_WITH_LOOT)
		&"operator":
			change_state(NOTICE)
		&"storage":
			blackboard.current_objective_type = &"vault_storage"
			blackboard.current_objective = blackboard.target_storage
			change_state(SEEK_OBJECTIVE)
		&"investigate":
			change_state(INVESTIGATE)
		_:
			if current_state == IDLE:
				change_state(PATROL)


func _resolve_components() -> void:
	if blackboard == null:
		blackboard = get_parent().get_node_or_null("EnemyBlackboard")
	if perception == null:
		perception = get_parent().get_node_or_null("EnemyPerceptionComponent")
	if objective_sensor == null:
		objective_sensor = get_parent().get_node_or_null("EnemyObjectiveSensor")
	if loot_carrier == null:
		loot_carrier = get_parent().get_node_or_null("EnemyLootCarrier")


func _get_vault_manager(enemy: Node) -> Node:
	var manager := enemy.get_node_or_null("/root/VaultManager")
	if manager != null:
		return manager
	return enemy.get_tree().get_first_node_in_group("vault_manager")


func _stable_damage_roll(enemy: Node) -> float:
	var basis := "%s:%d:%d" % [enemy.name if enemy != null else "enemy", int(state_time * 1000.0), int(Time.get_ticks_msec() / 250)]
	var hash := basis.hash() & 0x7fffffff
	return float(hash % 1000) / 1000.0
