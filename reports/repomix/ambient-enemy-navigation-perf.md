This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.

<file_summary>
This section contains a summary of this file.

<purpose>
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.
</purpose>

<file_format>
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  - File path as an attribute
  - Full contents of the file
</file_format>

<usage_guidelines>
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.
</usage_guidelines>

<notes>
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: AGENTS.md, custodian/AGENTS.md, design/02_features/wave_spawning/WAVE_SPAWNING_SYSTEM.md, design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md, custodian/docs/ai_context/CURRENT_STATE.md, custodian/docs/ai_context/CONTEXT.md, custodian/docs/ai_context/FILE_INDEX.md, custodian/docs/ai_context/VALIDATION_RECIPES.md, custodian/game/systems/spawning/ambient_enemy_spawner.gd, custodian/game/systems/spawning/ambient_enemy_camp.gd, custodian/game/actors/enemies/enemy.gd, custodian/game/actors/enemies/enemy_grunt.tscn, custodian/game/actors/enemies/enemy_behavior_state_machine.gd, custodian/game/actors/enemies/components/enemy_perception_component.gd, custodian/game/actors/enemies/components/enemy_objective_sensor.gd, custodian/game/systems/core/systems/navigation_system.gd, custodian/game/systems/simulation/simulation_interest_manager.gd, custodian/game/enemies/procgen/grunt_animation_library.gd, custodian/scenes/game.tscn
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)
</notes>

</file_summary>

<directory_structure>
custodian/
  docs/
    ai_context/
      CONTEXT.md
      CURRENT_STATE.md
      FILE_INDEX.md
      VALIDATION_RECIPES.md
  game/
    actors/
      enemies/
        components/
          enemy_objective_sensor.gd
          enemy_perception_component.gd
        enemy_behavior_state_machine.gd
        enemy_grunt.tscn
        enemy.gd
    enemies/
      procgen/
        grunt_animation_library.gd
    systems/
      core/
        systems/
          navigation_system.gd
      simulation/
        simulation_interest_manager.gd
      spawning/
        ambient_enemy_camp.gd
        ambient_enemy_spawner.gd
  scenes/
    game.tscn
  AGENTS.md
design/
  02_features/
    combat_feel/
      RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md
    wave_spawning/
      WAVE_SPAWNING_SYSTEM.md
AGENTS.md
</directory_structure>

<files>
This section contains the contents of the repository's files.

<file path="custodian/game/actors/enemies/components/enemy_objective_sensor.gd">
extends Node
class_name EnemyObjectiveSensor


func choose_objective(enemy: Node2D, profile: Resource, blackboard: Node) -> Dictionary:
	var storage_objective := _score_storage_objective(enemy, profile, blackboard)
	var sabotage_objective := _score_sabotage_storage_objective(enemy, profile, blackboard)
	var scores := {
		"operator": score_operator(enemy, profile, blackboard),
		"storage": float(storage_objective.get("score", 0.0)),
		"sabotage_storage": float(sabotage_objective.get("score", 0.0)),
		"exit": score_exit_with_loot(enemy, profile, blackboard),
		"investigate": score_investigation(enemy, profile, blackboard),
	}
	blackboard.objective_debug_scores = scores.duplicate(true)
	var best_type := &"none"
	var best_score := 0.0
	for key in scores.keys():
		var score := float(scores[key])
		if score > best_score:
			best_score = score
			best_type = StringName(str(key))
	if best_type == &"storage":
		blackboard.set("target_storage", storage_objective.get("target"))
	elif best_type == &"sabotage_storage":
		blackboard.set("target_storage", sabotage_objective.get("target"))
	return {"type": best_type, "score": best_score}


func score_operator(enemy: Node2D, profile: Resource, blackboard: Node) -> float:
	var operator_ref: Node = blackboard.get("operator_ref")
	if operator_ref == null or not is_instance_valid(operator_ref):
		operator_ref = _find_operator(enemy)
	if operator_ref == null or not is_instance_valid(operator_ref):
		return 0.0
	var operator := operator_ref as Node2D
	if operator == null:
		return 0.0
	var distance := enemy.global_position.distance_to(operator.global_position)
	var awareness_radius := float(profile.get("operator_awareness_bubble_px"))
	if not bool(blackboard.get("is_alerted")) and not bool(blackboard.get("has_seen_operator")):
		if distance > awareness_radius:
			return 0.0
		_mark_operator_awareness(operator, blackboard)
		var bubble_proximity := clampf(1.0 - distance / maxf(1.0, awareness_radius), 0.0, 1.0)
		return float(profile.get("operator_awareness_score")) + bubble_proximity * 35.0
	var proximity := clampf(1.0 - distance / maxf(1.0, float(profile.get("vision_range_px"))), 0.0, 1.0)
	return float(profile.get("aggression_weight")) * 100.0 + proximity * 45.0


func score_storage(enemy: Node2D, profile: Resource, blackboard: Node) -> float:
	return float(_score_storage_objective(enemy, profile, blackboard).get("score", 0.0))


func _score_storage_objective(enemy: Node2D, profile: Resource, blackboard: Node) -> Dictionary:
	if not bool(profile.get("can_steal_resources")) or bool(blackboard.get("is_carrying_loot")):
		return {"score": 0.0, "target": null}
	var manager := _get_vault_manager(enemy)
	if manager == null or not manager.has_method("find_best_storage_for_enemy"):
		return {"score": 0.0, "target": null}
	var storage = manager.call("find_best_storage_for_enemy", enemy)
	if not (storage is Node2D):
		return {"score": 0.0, "target": null}
	var dist := enemy.global_position.distance_to((storage as Node2D).global_position)
	var distance_penalty := minf(45.0, dist / 32.0)
	return {
		"score": maxf(0.0, float(profile.get("theft_weight")) * 100.0 - distance_penalty),
		"target": storage,
	}


func score_sabotage_storage(enemy: Node2D, profile: Resource, blackboard: Node) -> float:
	return float(_score_sabotage_storage_objective(enemy, profile, blackboard).get("score", 0.0))


func _score_sabotage_storage_objective(enemy: Node2D, profile: Resource, blackboard: Node) -> Dictionary:
	if not bool(profile.get("can_sabotage_storage")) or bool(blackboard.get("is_carrying_loot")):
		return {"score": 0.0, "target": null}
	var manager := _get_vault_manager(enemy)
	if manager == null or not manager.has_method("find_best_damageable_storage_for_enemy"):
		return {"score": 0.0, "target": null}
	var storage = manager.call("find_best_damageable_storage_for_enemy", enemy)
	if not (storage is Node2D):
		return {"score": 0.0, "target": null}
	var dist := enemy.global_position.distance_to((storage as Node2D).global_position)
	var distance_penalty := minf(45.0, dist / 32.0)
	var stored_bonus := 15.0 if storage.has_method("has_resources") and bool(storage.call("has_resources")) else 0.0
	return {
		"score": maxf(0.0, float(profile.get("sabotage_weight")) * 100.0 + stored_bonus - distance_penalty),
		"target": storage,
	}


func score_exit_with_loot(enemy: Node2D, _profile: Resource, blackboard: Node) -> float:
	return 1000.0 if bool(blackboard.get("is_carrying_loot")) else 0.0


func score_investigation(_enemy: Node2D, profile: Resource, blackboard: Node) -> float:
	if not bool(blackboard.get("is_suspicious")) or float(blackboard.get("investigation_timer")) <= 0.0:
		return 0.0
	return float(profile.get("curiosity_weight")) * 100.0


func _get_vault_manager(enemy: Node) -> Node:
	if enemy == null or not enemy.is_inside_tree():
		return null
	var autoload := enemy.get_node_or_null("/root/VaultManager")
	if autoload != null:
		return autoload
	return enemy.get_tree().get_first_node_in_group("vault_manager")


func _find_operator(enemy: Node) -> Node2D:
	if enemy == null or not enemy.is_inside_tree():
		return null
	return enemy.get_tree().get_first_node_in_group("player") as Node2D


func _mark_operator_awareness(operator: Node2D, blackboard: Node) -> void:
	blackboard.operator_ref = operator
	blackboard.last_known_operator_position = operator.global_position
	blackboard.target_last_seen_position = operator.global_position
	blackboard.investigation_position = operator.global_position
	blackboard.has_seen_operator = true
	blackboard.is_alerted = true
	blackboard.is_suspicious = true
</file>

<file path="custodian/game/actors/enemies/enemy_behavior_state_machine.gd">
extends Node
class_name EnemyBehaviorStateMachine

const ENEMY_BEHAVIOR_PROFILE_SCRIPT := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")

const IDLE := &"idle"
const PATROL := &"patrol"
const AMBIENT_ACTIVITY := &"ambient_activity"
const INVESTIGATE := &"investigate"
const NOTICE := &"notice"
const ENGAGE_OPERATOR := &"engage_operator"
const SEARCH := &"search"
const RETURN_HOME := &"return_home"
const SEEK_OBJECTIVE := &"seek_objective"
const OPEN_STORAGE := &"open_storage"
const STEAL_RESOURCES := &"steal_resources"
const SABOTAGE_STORAGE := &"sabotage_storage"
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
@export var ambient_anchor_group: StringName = &"ambient_activity_anchor"

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
		AMBIENT_ACTIVITY:
			_update_ambient_activity(enemy, delta)
		INVESTIGATE:
			_update_investigate(enemy, delta)
		NOTICE:
			_update_notice(enemy, delta)
		ENGAGE_OPERATOR:
			_update_engage_operator(enemy, delta)
		SEARCH:
			_update_search(enemy, delta)
		RETURN_HOME:
			_update_return_home(enemy, delta)
		SEEK_OBJECTIVE:
			_update_seek_objective(enemy, delta)
		OPEN_STORAGE:
			_update_open_storage(enemy, delta)
		STEAL_RESOURCES:
			_update_steal_resources(enemy, delta)
		SABOTAGE_STORAGE:
			_update_sabotage_storage(enemy, delta)
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
	if current_state == AMBIENT_ACTIVITY and new_state != AMBIENT_ACTIVITY and get_parent() != null:
		_release_ambient_anchor(get_parent())
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


func setup_ambient_home(home_position: Vector2, camp_id: StringName, leash_radius_px: float) -> void:
	_resolve_components()
	if blackboard == null:
		return
	blackboard.home_position = home_position
	blackboard.camp_id = camp_id
	blackboard.leash_radius_px = maxf(64.0, leash_radius_px)


func force_ambient(anchor: Node) -> void:
	if blackboard == null or anchor == null:
		return
	if anchor.has_method("claim") and not bool(anchor.call("claim", get_parent())):
		return
	blackboard.ambient_anchor = anchor
	blackboard.ambient_activity_id = StringName(str(anchor.get("activity_id"))) if "activity_id" in anchor else &"ambient"
	blackboard.ambient_noncombat_first = bool(anchor.get("noncombat_first")) if "noncombat_first" in anchor else true
	change_state(AMBIENT_ACTIVITY)


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
		if _try_claim_nearby_ambient_anchor(enemy):
			return
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


func _update_ambient_activity(enemy: Node2D, delta: float) -> void:
	if blackboard.is_alerted and blackboard.operator_ref != null:
		change_state(NOTICE)
		return
	var anchor := blackboard.ambient_anchor as Node2D
	if anchor == null or not is_instance_valid(anchor):
		change_state(PATROL)
		return
	var anchor_pos := anchor.global_position
	if anchor.has_method("get_anchor_position"):
		anchor_pos = anchor.call("get_anchor_position")
	if enemy.global_position.distance_to(anchor_pos) > 18.0:
		enemy.call("behavior_move_toward", anchor_pos, profile.patrol_speed)
		return
	enemy.call("behavior_stop")
	blackboard.ambient_activity_timer += delta
	if blackboard.ambient_activity_timer >= profile.ambient_activity_duration_sec:
		change_state(PATROL)


func _try_claim_nearby_ambient_anchor(enemy: Node2D) -> bool:
	var roll_basis := "%s:%d:%d" % [enemy.name, int(state_time * 10.0), int(profile.ambient_activity_weight * 100.0)]
	var roll := float((roll_basis.hash() & 0x7fffffff) % 1000) / 1000.0
	if roll > profile.ambient_activity_weight:
		return false
	var best_anchor: Node2D = null
	var best_dist := INF
	for anchor in enemy.get_tree().get_nodes_in_group(ambient_anchor_group):
		if not (anchor is Node2D):
			continue
		if anchor.has_method("can_claim") and not bool(anchor.call("can_claim", enemy)):
			continue
		var dist := enemy.global_position.distance_to((anchor as Node2D).global_position)
		if dist <= profile.ambient_anchor_search_radius_px and dist < best_dist:
			best_dist = dist
			best_anchor = anchor
	if best_anchor == null:
		return false
	force_ambient(best_anchor)
	return current_state == AMBIENT_ACTIVITY


func _release_ambient_anchor(enemy: Node) -> void:
	if blackboard == null:
		return
	var anchor: Node = blackboard.ambient_anchor
	if anchor != null and is_instance_valid(anchor) and anchor.has_method("release"):
		anchor.call("release", enemy)
	blackboard.ambient_anchor = null
	blackboard.ambient_activity_id = &"none"
	blackboard.ambient_activity_timer = 0.0


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
	if not blackboard.target_visible:
		blackboard.pursuit_timer = maxf(0.0, blackboard.pursuit_timer - _delta)
		if enemy.global_position.distance_to(blackboard.home_position) > blackboard.leash_radius_px or blackboard.pursuit_timer <= 0.0:
			blackboard.search_timer = float(profile.get("investigation_memory_sec"))
			blackboard.search_point_index = 0
			change_state(SEARCH)
			return
		enemy.call("behavior_move_toward", blackboard.target_last_seen_position, profile.engage_speed)
		return
	enemy.set("target", operator)
	var attack_range := 40.0
	if enemy.has_method("get_behavior_attack_range"):
		attack_range = float(enemy.call("get_behavior_attack_range"))
	if enemy.global_position.distance_to(operator.global_position) > attack_range:
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
	var sabotaging: bool = blackboard.current_objective_type == &"vault_storage_sabotage"
	if sabotaging and storage.has_method("is_destroyed") and bool(storage.call("is_destroyed")):
		change_state(IDLE)
		return
	if not sabotaging and storage.has_method("has_resources") and not bool(storage.call("has_resources")):
		change_state(IDLE)
		return
	if enemy.global_position.distance_to(storage.global_position) > storage_interact_range_px:
		enemy.call("behavior_move_toward", storage.global_position, profile.objective_speed)
	elif sabotaging:
		change_state(SABOTAGE_STORAGE)
	else:
		change_state(OPEN_STORAGE)


func _update_open_storage(enemy: Node2D, delta: float) -> void:
	if _evaluate_operator_interrupt_for_storage():
		change_state(NOTICE)
		return
	enemy.call("behavior_stop")
	_storage_timer += delta
	var storage: Node = blackboard.get("target_storage")
	var open_time: float = float(profile.get("storage_open_seconds"))
	if storage != null and "open_seconds" in storage:
		open_time = float(storage.get("open_seconds"))
	if _storage_timer >= open_time:
		change_state(STEAL_RESOURCES)


func _update_steal_resources(enemy: Node2D, delta: float) -> void:
	if _evaluate_operator_interrupt_for_storage():
		change_state(NOTICE)
		return
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


func _update_sabotage_storage(enemy: Node2D, delta: float) -> void:
	if _evaluate_operator_interrupt_for_storage():
		change_state(NOTICE)
		return
	enemy.call("behavior_stop")
	_storage_timer += delta
	if _storage_timer < profile.sabotage_seconds:
		return
	var storage: Node = blackboard.get("target_storage")
	var manager := _get_vault_manager(enemy)
	if manager == null or storage == null:
		change_state(IDLE)
		return
	if manager.has_method("damage_storage"):
		manager.call("damage_storage", storage, profile.sabotage_damage, enemy)
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
	var operator := blackboard.operator_ref as Node2D
	if operator == null or not is_instance_valid(operator):
		operator = _find_operator()
	if operator == null:
		return false
	var distance := (get_parent() as Node2D).global_position.distance_to(operator.global_position) if get_parent() is Node2D else INF
	var close_enough := distance <= float(profile.get("operator_awareness_bubble_px"))
	if close_enough:
		blackboard.operator_ref = operator
		blackboard.last_known_operator_position = operator.global_position
		blackboard.target_last_seen_position = operator.global_position
		blackboard.has_seen_operator = true
		blackboard.is_alerted = true
		blackboard.is_suspicious = true
		return true
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
		&"sabotage_storage":
			blackboard.current_objective_type = &"vault_storage_sabotage"
			blackboard.current_objective = blackboard.target_storage
			change_state(SEEK_OBJECTIVE)
		&"investigate":
			change_state(INVESTIGATE)
		_:
			if current_state == IDLE:
				change_state(PATROL)


func _update_search(enemy: Node2D, delta: float) -> void:
	if blackboard.target_visible and blackboard.operator_ref != null:
		change_state(ENGAGE_OPERATOR)
		return
	blackboard.search_timer = maxf(0.0, blackboard.search_timer - delta)
	if blackboard.search_timer <= 0.0 or enemy.global_position.distance_to(blackboard.home_position) > blackboard.leash_radius_px:
		blackboard.is_alerted = false
		blackboard.operator_ref = null
		change_state(RETURN_HOME)
		return
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(48, 0), Vector2(-48, 0), Vector2(0, 48), Vector2(0, -48)]
	var index: int = int(blackboard.search_point_index) % offsets.size()
	var search_point: Vector2 = blackboard.target_last_seen_position + offsets[index]
	if enemy.global_position.distance_to(search_point) <= 18.0:
		blackboard.search_point_index += 1
		index = blackboard.search_point_index % offsets.size()
		search_point = blackboard.target_last_seen_position + offsets[index]
	enemy.call("behavior_move_toward", search_point, profile.investigate_speed)


func _update_return_home(enemy: Node2D, _delta: float) -> void:
	if blackboard.is_suspicious and blackboard.investigation_timer > 0.0:
		var heard_within_leash: bool = blackboard.home_position.distance_to(blackboard.investigation_position) <= blackboard.leash_radius_px
		if heard_within_leash:
			change_state(INVESTIGATE)
			return
	if enemy.global_position.distance_to(blackboard.home_position) <= 18.0:
		enemy.call("behavior_stop")
		blackboard.reset_alerts()
		change_state(PATROL)
		return
	enemy.call("behavior_move_toward", blackboard.home_position, profile.patrol_speed)


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


func _find_operator() -> Node2D:
	var parent := get_parent()
	if parent == null or not parent.is_inside_tree():
		return null
	return parent.get_tree().get_first_node_in_group("player") as Node2D


func _stable_damage_roll(enemy: Node) -> float:
	var basis := "%s:%d:%d" % [enemy.name if enemy != null else "enemy", int(state_time * 1000.0), int(Time.get_ticks_msec() / 250)]
	var hash := basis.hash() & 0x7fffffff
	return float(hash % 1000) / 1000.0
</file>

<file path="custodian/game/actors/enemies/components/enemy_perception_component.gd">
extends Node
class_name EnemyPerceptionComponent

signal became_suspicious(target_position: Vector2)
signal noticed_operator(operator: Node)
signal lost_operator(last_known_position: Vector2)
signal heard_noise(noise_position: Vector2, strength: float)

var detection_meter: float = 0.0
var last_known_position: Vector2 = Vector2.ZERO
var has_line_of_sight: bool = false
var _was_alerted := false
var _current_enemy: Node2D = null
var _current_profile: Resource = null
var _current_blackboard: Node = null


func _ready() -> void:
	var bus := get_node_or_null("/root/NoiseEventBus")
	if bus != null and bus.has_signal("noise_emitted") and not bus.noise_emitted.is_connected(_on_noise_emitted):
		bus.noise_emitted.connect(_on_noise_emitted)


func update_perception(enemy: Node2D, profile: Resource, blackboard: Node, delta: float) -> void:
	if enemy == null or profile == null or blackboard == null:
		return
	_current_enemy = enemy
	_current_profile = profile
	_current_blackboard = blackboard
	var operator := _find_operator(enemy)
	if operator == null:
		_decay(profile, delta)
		return

	var snapshot := _get_operator_snapshot(operator)
	var operator_position := snapshot.get("global_position", operator.global_position) as Vector2
	var distance := enemy.global_position.distance_to(operator_position)
	var visible: bool = distance <= float(profile.get("vision_range_px")) and _is_in_vision_arc(enemy, operator_position, profile) and _has_line_of_sight(enemy, operator)
	has_line_of_sight = visible
	blackboard.target_visible = visible

	if visible:
		last_known_position = operator_position
		blackboard.last_known_operator_position = operator_position
		blackboard.target_last_seen_position = operator_position
		blackboard.operator_ref = operator
		blackboard.pursuit_timer = float(profile.get("lost_sight_memory_sec"))
		var visibility_mult := float(snapshot.get("visibility_mult", 1.0))
		var distance_mult := _distance_detection_mult(distance, profile.vision_range_px)
		detection_meter = clampf(detection_meter + float(profile.get("detection_gain_per_sec")) * visibility_mult * distance_mult * delta, 0.0, 1.0)
	else:
		_decay(profile, delta)

	var noise_radius := float(snapshot.get("noise_radius_px", 0.0))
	if not visible and noise_radius > 0.0 and distance <= min(float(profile.get("hearing_range_px")) + noise_radius, float(profile.get("hearing_range_px")) * 2.5):
		last_known_position = operator_position
		blackboard.operator_ref = operator
		blackboard.investigation_position = operator_position
		blackboard.set("investigation_timer", float(profile.get("investigation_memory_sec")))
		blackboard.is_suspicious = true
		heard_noise.emit(operator_position, noise_radius)
		became_suspicious.emit(operator_position)

	if visible and detection_meter >= float(profile.get("detection_notice_threshold")) and not bool(blackboard.get("is_suspicious")):
		blackboard.is_suspicious = true
		blackboard.investigation_position = operator_position
		became_suspicious.emit(operator_position)

	if detection_meter >= float(profile.get("detection_alert_threshold")) and (visible or bool(blackboard.get("has_seen_operator"))):
		blackboard.has_seen_operator = true
		blackboard.is_alerted = true
		if not _was_alerted:
			noticed_operator.emit(operator)
		_was_alerted = true
	elif _was_alerted and detection_meter <= 0.01:
		blackboard.is_alerted = false
		_was_alerted = false
		lost_operator.emit(last_known_position)


func _on_noise_emitted(event: Variant) -> void:
	if _current_enemy == null or _current_profile == null or _current_blackboard == null or event == null:
		return
	if not is_instance_valid(_current_enemy) or event.get("source") == _current_enemy:
		return
	if event.get("source_team") != &"player" and event.get("source_team") != &"neutral":
		return
	if event.get("source_team") == &"player":
		var source_variant: Variant = event.get("source")
		if source_variant is Node and (source_variant as Node).is_in_group("player"):
			_current_blackboard.operator_ref = source_variant
		elif get_tree() != null:
			_current_blackboard.operator_ref = get_tree().get_first_node_in_group("player")
	var event_position: Vector2 = event.get("position")
	var distance: float = _current_enemy.global_position.distance_to(event_position)
	var effective_radius: float = float(event.get("radius_px"))
	if distance > effective_radius or effective_radius <= 0.0:
		return
	var distance_strength: float = 1.0 - distance / effective_radius
	var strength: float = maxf(0.05, float(event.get("threat_value")) * distance_strength)
	_current_blackboard.target_last_heard_position = event_position
	_current_blackboard.investigation_position = event_position
	_current_blackboard.investigation_timer = maxf(_current_blackboard.investigation_timer, float(_current_profile.get("investigation_memory_sec")))
	_current_blackboard.is_suspicious = true
	detection_meter = clampf(detection_meter + strength * (0.45 if bool(event.get("suppressed")) else 0.7), 0.0, 1.0)
	force_noise(event_position, float(_current_profile.get("investigation_memory_sec")), _current_blackboard)


func force_noise(noise_position: Vector2, strength: float, blackboard: Node) -> void:
	last_known_position = noise_position
	if blackboard != null:
		blackboard.investigation_position = noise_position
		blackboard.investigation_timer = maxf(blackboard.investigation_timer, strength)
		blackboard.is_suspicious = true
	heard_noise.emit(noise_position, strength)


func _decay(profile: Resource, delta: float) -> void:
	detection_meter = clampf(detection_meter - float(profile.get("detection_decay_per_sec")) * delta, 0.0, 1.0)


func _find_operator(enemy: Node) -> Node2D:
	var tree := enemy.get_tree()
	if tree == null:
		return null
	var player := tree.get_first_node_in_group("player")
	return player as Node2D


func _get_operator_snapshot(operator: Node2D) -> Dictionary:
	if operator.has_method("get_stealth_snapshot"):
		var snapshot = operator.call("get_stealth_snapshot")
		if snapshot is Dictionary:
			return snapshot
	return {
		"global_position": operator.global_position,
		"visibility_mult": 1.0,
		"noise_radius_px": 25.0,
		"velocity": Vector2.ZERO,
	}


func _is_in_vision_arc(enemy: Node2D, target_position: Vector2, profile: Resource) -> bool:
	var to_target := target_position - enemy.global_position
	if to_target.length_squared() <= 0.001:
		return true
	var facing := Vector2.DOWN
	if "velocity" in enemy and (enemy as CharacterBody2D).velocity.length_squared() > 0.001:
		facing = (enemy as CharacterBody2D).velocity.normalized()
	elif enemy.has_method("get_last_move_direction"):
		facing = Vector2(enemy.call("get_last_move_direction"))
	var angle: float = abs(rad_to_deg(facing.angle_to(to_target.normalized())))
	var cone_degrees := float(profile.get("vision_cone_degrees"))
	return angle <= cone_degrees * 0.5 or angle <= cone_degrees * float(profile.get("peripheral_vision_mult"))


func _has_line_of_sight(enemy: Node2D, target: Node2D) -> bool:
	var space := enemy.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(enemy.global_position, target.global_position)
	query.exclude = [enemy.get_rid(), target.get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)
	return hit.is_empty()


func _distance_detection_mult(distance: float, range_px: float) -> float:
	var alpha := distance / maxf(1.0, range_px)
	if alpha <= 0.25:
		return 1.25
	if alpha <= 0.75:
		return 1.0
	return 0.45
</file>

<file path="custodian/game/systems/simulation/simulation_interest_manager.gd">
extends Node

@export var active_radius: float = 900.0
@export var nearby_radius: float = 1600.0
@export var background_radius: float = 3000.0
@export_range(0.05, 1.0, 0.05) var update_interval_sec: float = 0.20

var player: Node2D = null
var _update_accum := 0.0
var _has_classified := false


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			return
	_update_accum += maxf(0.0, delta)
	if _has_classified and _update_accum < update_interval_sec:
		return
	_update_accum = 0.0
	_has_classified = true

	var counts := {
		"active": 0,
		"nearby": 0,
		"background": 0,
		"dormant": 0,
	}

	var active_sq := active_radius * active_radius
	var nearby_sq := nearby_radius * nearby_radius
	var background_sq := background_radius * background_radius
	for node in get_tree().get_nodes_in_group("interest_managed"):
		if not (node is Node2D):
			continue

		var distance_sq := player.global_position.distance_squared_to((node as Node2D).global_position)
		var tier := "dormant"
		if distance_sq <= active_sq:
			tier = "active"
		elif distance_sq <= nearby_sq:
			tier = "nearby"
		elif distance_sq <= background_sq:
			tier = "background"

		counts[tier] = int(counts.get(tier, 0)) + 1
		if node.has_method("set_simulation_tier"):
			node.call("set_simulation_tier", tier)

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		for key in counts.keys():
			observatory.call("set_gauge", "interest_%s" % key, counts[key])
</file>

<file path="custodian/game/systems/spawning/ambient_enemy_camp.gd">
extends Node2D
class_name AmbientEnemyCamp

@export var camp_id: StringName = &"camp"
@export var enemy_scene: PackedScene
@export var enemy_count_min: int = 2
@export var enemy_count_max: int = 4
@export var spawn_radius_px: float = 96.0
@export var leash_radius_px: float = 700.0
@export var activation_range_px: float = 650.0
@export var initially_active: bool = true
@export var respawn_enabled: bool = false
@export var faction_id: StringName = &"hostile"
@export var behavior_profile_id: StringName = &"raider_grunt"

var _spawned := false
var _spawned_enemies: Array[Node] = []


func _ready() -> void:
	add_to_group("ambient_enemy_camp")
	set_process(initially_active)


func _process(_delta: float) -> void:
	_prune_enemies()
	if _spawned and (not respawn_enabled or not _spawned_enemies.is_empty()):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > activation_range_px:
		return
	spawn_camp()


func spawn_camp() -> void:
	if enemy_scene == null:
		return
	var count_range := maxi(0, enemy_count_max - enemy_count_min)
	var stable_offset := int((String(camp_id).hash() & 0x7fffffff) % (count_range + 1)) if count_range > 0 else 0
	var count := maxi(0, enemy_count_min + stable_offset)
	var parent := get_parent()
	for index in count:
		var enemy := enemy_scene.instantiate() as Node2D
		if enemy == null:
			continue
		parent.add_child(enemy)
		var angle := TAU * float(index) / float(maxi(1, count))
		var radius := spawn_radius_px * (0.55 + 0.45 * float((index % 3) + 1) / 3.0)
		enemy.global_position = global_position + Vector2.RIGHT.rotated(angle) * radius
		var behavior := enemy.get_node_or_null("EnemyBehaviorStateMachine")
		if behavior != null:
			if behavior.has_method("setup_profile"):
				behavior.call("setup_profile", behavior_profile_id)
			if behavior.has_method("setup_ambient_home"):
				behavior.call("setup_ambient_home", global_position, camp_id, leash_radius_px)
		_spawned_enemies.append(enemy)
	_spawned = true
	set_process(false)


func _prune_enemies() -> void:
	for index in range(_spawned_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_enemies[index]):
			_spawned_enemies.remove_at(index)


func get_active_enemy_count() -> int:
	_prune_enemies()
	return _spawned_enemies.size()
</file>

<file path="custodian/game/systems/spawning/ambient_enemy_spawner.gd">
extends Node
class_name AmbientEnemySpawner

const CAMP_SCRIPT := preload("res://game/systems/spawning/ambient_enemy_camp.gd")

@export var enemy_scene: PackedScene
@export var marker_group: StringName = &"ambient_enemy_camp_marker"
@export var min_distance_from_player_start_px: float = 420.0
@export var min_camp_spacing_px: float = 700.0
@export var max_generated_camps: int = 3
@export var max_active_ambient_enemies: int = 12
@export_range(1, 8, 1) var enemies_per_camp_min: int = 2
@export_range(1, 8, 1) var enemies_per_camp_max: int = 2


func _ready() -> void:
	call_deferred("spawn_from_markers")


func spawn_from_markers() -> int:
	if enemy_scene == null:
		return 0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var accepted: Array[Vector2] = []
	var created := 0
	for marker in get_tree().get_nodes_in_group(marker_group):
		if created >= max_generated_camps:
			break
		if not (marker is Node2D) or (marker as Node).is_queued_for_deletion():
			continue
		if (created + 1) * maxi(1, enemies_per_camp_min) > max_active_ambient_enemies:
			break
		var position := (marker as Node2D).global_position
		if player != null and position.distance_to(player.global_position) < min_distance_from_player_start_px:
			continue
		var too_close := false
		for existing in accepted:
			if position.distance_to(existing) < min_camp_spacing_px:
				too_close = true
				break
		if too_close:
			continue
		var camp := CAMP_SCRIPT.new() as AmbientEnemyCamp
		camp.camp_id = StringName("generated_camp_%d" % created)
		camp.enemy_scene = enemy_scene
		camp.enemy_count_min = enemies_per_camp_min
		camp.enemy_count_max = maxi(enemies_per_camp_min, enemies_per_camp_max)
		camp.add_to_group("generated_procgen_ambient_camp")
		(marker as Node2D).add_child(camp)
		camp.global_position = position
		accepted.append(position)
		created += 1
	return created


func get_active_enemy_count() -> int:
	var total := 0
	for camp in get_tree().get_nodes_in_group("ambient_enemy_camp"):
		if camp.has_method("get_active_enemy_count"):
			total += int(camp.call("get_active_enemy_count"))
	return total
</file>

<file path="design/02_features/wave_spawning/WAVE_SPAWNING_SYSTEM.md">
# CUSTODIAN — Wave Spawning System Implementation Plan

**Created:** 2026-03-05
**Status:** ✅ IMPLEMENTED
**Godot-Native:** Yes
**Files:** `custodian/core/systems/wave_manager.gd`, `spawn_node.gd`

---

## 1. System Overview

The current runtime uses assault waves as a temporary delivery mechanism for hostile pressure, but the target feel is not arcade horde defense. Assaults should arrive as tactical incursions with short bursts of contact and meaningful lulls between them.

Current runtime slice:
- moderate threat budgets tuned upward from the first tactical-incursion pass
- short spawn bursts within a wave instead of a continuous stream
- recovery gating before the next assault timer arms

### Architecture

```
custodian/
 └─ core/
     └─ systems/
         ├─ wave_manager.gd      # Main wave orchestration
         ├─ spawn_node.gd         # Individual spawn point
         └─ enemy_factory.gd     # Enemy creation (optional, can be in wave_manager)
```

---

## 2. Spawn Nodes

### Purpose
Designated positions on the map where enemies spawn. Placed on map edges to create predictable assault lanes.

### Implementation: `spawn_node.gd`

**File:** `res://game/systems/spawning/spawn_node.gd`

```gdscript
extends Node2D
class_name SpawnNode

@export var lane: String = "default"
@export var spawn_weight: float = 1.0
@export var active: bool = true

func _ready():
    add_to_group("enemy_spawn")
    add_to_group("spawn_node_" + lane)
```

### Scene Setup

Create spawn node scenes:
- `res://game/systems/spawning/spawn_node.tscn` (instantiate for each spawn point)

### Lane Groups

Spawn nodes automatically join groups:
- `spawn_node_north`
- `spawn_node_east`  
- `spawn_node_south`
- `spawn_node_west`

---

## 3. Wave Manager

### Purpose
Controls assault timing, composition, and pacing.

### Pacing Direction
- keep enemy counts low enough that each attacker matters
- cluster spawns into small bursts
- require a recovery lull after the field is mostly clear before the next assault starts
- preserve lane/objective readability so the player can reposition and react

### Implementation: `wave_manager.gd`

**File:** `res://game/systems/spawning/wave_manager.gd`

```gdscript
extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

# Configuration
@export var wave_interval: float = 30.0
@export var base_points: int = 7
@export var growth_per_wave: int = 4
@export var max_wave: int = 20
@export var initial_delay: float = 5.0
@export var max_alive_enemies: int = 80

# Enemy Scene References (assign in inspector)
@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
@export var heavy_drone_scene: PackedScene

# Runtime State
var wave_number: int = 0
var timer: Timer = null
var spawn_nodes: Array = []
var active: bool = true

# Enemy Cost Table
var enemy_cost := {
    "drone": 1,
    "fast": 2,
    "heavy": 4
}

# Enemy Stats Modifiers (for scaling)
var hp_modifier: float = 1.0
var damage_modifier: float = 1.0

func _ready():
    _setup_timer()
    _collect_spawn_nodes()
    print("[WaveManager] Initialized with ", spawn_nodes.size(), " spawn nodes")
    
    # Start first wave after initial delay
    await get_tree().create_timer(initial_delay).timeout
    if active:
        start_next_wave()

func _setup_timer():
    timer = Timer.new()
    timer.wait_time = wave_interval
    timer.autostart = false
    timer.timeout.connect(_on_wave_timer)
    add_child(timer)

func _collect_spawn_nodes():
    spawn_nodes = get_tree().get_nodes_in_group("enemy_spawn")
    # Sort by lane for predictable spawning
    spawn_nodes.sort_custom(func(a, b): 
        return a.lane < b.lane
    )

func _on_wave_timer():
    start_next_wave()

func start_next_wave():
    if wave_number >= max_wave:
        print("[WaveManager] Max wave reached: ", max_wave)
        all_waves_completed.emit()
        return
    
    wave_number += 1
    
    var points = _calculate_points()
    var difficulty = _calculate_difficulty()
    
    print("[WaveManager] Starting Wave ", wave_number, " | Points: ", points, " | Difficulty: ", difficulty)
    
    wave_started.emit(wave_number)
    _spawn_wave(points, difficulty)
    
    wave_completed.emit(wave_number)

func _calculate_points() -> int:
    return base_points + wave_number * growth_per_wave

func _calculate_difficulty() -> float:
    return 1.0 + (wave_number * 0.25)

func _spawn_wave(points: int, difficulty: float):
    var remaining_points = points
    
    while remaining_points > 0:
        if _count_alive_enemies() >= max_alive_enemies:
            break
        var enemy_type = _choose_enemy(remaining_points)
        
        if enemy_type.is_empty():
            break
        
        _spawn_enemy(enemy_type, difficulty)
        remaining_points -= enemy_cost[enemy_type]

func _choose_enemy(available_points: int) -> String:
    var options: Array[String] = []
    
    # Always available
    if available_points >= enemy_cost["drone"]:
        options.append("drone")
    
    # Unlocks at wave 3
    if available_points >= enemy_cost["fast"] and wave_number >= 3:
        options.append("fast")
    
    # Unlocks at wave 6
    if available_points >= enemy_cost["heavy"] and wave_number >= 6:
        options.append("heavy")
    
    if options.is_empty():
        return ""
    
    return options.pick_random()

func _spawn_enemy(enemy_type: String, difficulty: float):
    if spawn_nodes.is_empty():
        push_warning("[WaveManager] No spawn nodes available!")
        return
    
    # Pick random spawn node
    var spawn_node = spawn_nodes.pick_random()
    
    var scene: PackedScene
    match enemy_type:
        "drone":
            scene = drone_scene
        "fast":
            scene = fast_drone_scene
        "heavy":
            scene = heavy_drone_scene
    
    if scene == null:
        push_warning("[WaveManager] Enemy scene not set: " + enemy_type)
        return
    
    var enemy = scene.instantiate()
    
    # Apply difficulty modifiers
    if enemy.has_method("apply_difficulty_modifiers"):
        enemy.apply_difficulty_modifiers(difficulty, difficulty)
    
    # Position at spawn node

The live implementation now uses the alive-enemy cap as a throttle on the pending spawn queue. When the battlefield reaches `max_alive_enemies`, the spawn timer keeps running but defers additional spawns until enemies die.
    enemy.global_position = spawn_node.global_position
    
    # Add to world
    var world = get_node_or_null("/root/GameRoot/World")
    if world:
        var enemies_container = world.find_child("Enemies", true, false)
        if enemies_container:
            enemies_container.add_child(enemy)
            return
    
    # Fallback
    get_tree().current_scene.add_child(enemy)

# Control Functions
func start_waves():
    active = true
    if timer and not timer.is_started():
        timer.start()

func stop_waves():
    active = false
    if timer:
        timer.stop()

func skip_wave():
    start_next_wave()

func reset():
    wave_number = 0
    stop_waves()
    # Clear existing enemies
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.queue_free()
```

---

## 4. Enemy Difficulty Modifiers

### Add to Existing Enemy Script

Modify `res://game/actors/enemies/enemy.gd` to support difficulty scaling:

```gdscript
# Add these functions to enemy.gd

func apply_difficulty_modifiers(hp_mult: float, damage_mult: float):
    max_health = max_health * hp_mult
    health = max_health
    damage = damage * damage_mult
    update_visuals()
```

---

## 5. Scene Setup Instructions

### Step 1: Add WaveManager to Scene

1. Open `test_map.tscn`
2. Add new Node → name it `WaveManager`
3. Attach script: `res://game/systems/spawning/wave_manager.gd`

### Step 2: Assign Enemy Scenes

In Inspector for WaveManager:
- `Drone Scene`: assign `res://game/actors/enemies/enemy.tscn`
- `Fast Drone Scene`: (create new scene or duplicate)
- `Heavy Drone Scene`: (create new scene or duplicate)

### Step 3: Place Spawn Nodes

1. Create Node2D instances around map edges
2. Attach `spawn_node.gd`
3. Set `Lane` property (north, east, south, west)
4. Place 3-5 spawn nodes per lane

### Example Scene Tree:

```
GameRoot
 ├── World
 │   ├── Sectors
 │   │   └── TileMap
 │   ├── Enemies
 │   ├── Projectiles
 │   ├── Operator
 │   ├── SpawnNodes
 │   │   ├── SpawnNode_North1 (lane: "north")
 │   │   ├── SpawnNode_North2 (lane: "north")
 │   │   ├── SpawnNode_East1 (lane: "east")
 │   │   └── ...
 │   └── Camera2D
 ├── WaveManager
 │   (assign enemy scenes in inspector)
 ├── Simulation
 ├── Combat
 ├── Power
 ├── UI
 └── PauseUI
```

---

## 6. Wave Configuration Reference

### Default Values

| Parameter | Value | Description |
|-----------|-------|-------------|
| wave_interval | 30.0 | Seconds between waves |
| base_points | 7 | Fallback starting points before director overrides |
| growth_per_wave | 4 | Fallback points added per wave |
| max_wave | 20 | Final wave |
| initial_delay | 5.0 | Time before first wave |
| max_alive_enemies | 80 | Live enemy cap before pending spawns defer |

### Wave Composition Examples

| Wave | Points | Possible Composition |
|------|--------|---------------------|
| 1 | 8 | 8 drones |
| 3 | 14 | 12 drones + fast |
| 5 | 20 | 16 drones + fast + fast |
|  | 208 | 29 drones + fast×4 + heavy |
| 12 | 41 | Mixed with multiple heavy |
| 20 | 65 | Maximum difficulty |

---

## 7. Testing Checklist

- [x] WaveManager node added to scene
- [x] Enemy scenes assigned in inspector
- [x] Spawn nodes placed on map edges
- [x] Spawn nodes have correct lane groups
- [x] First wave triggers after initial_delay
- [x] Enemies spawn at correct positions
- [x] Wave difficulty increases over time
- [x] Fast drones unlock at wave 3
- [x] Heavy drones unlock at wave 6
- [x] Max wave stops spawning

---

## 8. Future Integration Points

When connecting to Python strategic simulation:

1. **Replace wave timing:**
   ```gdscript
   # Instead of fixed timer
   func request_wave_from_simulation():
       var params = python_bridge.get_wave_parameters()
       _spawn_wave(params.points, params.difficulty)
   ```

2. **Lane-specific spawning:**
   ```gdscript
   # Target specific lanes
   func spawn_on_lane(lane_name: String, count: int):
       var nodes = get_tree().get_nodes_in_group("spawn_node_" + lane_name)
       # spawn at these nodes
   ```

3. **Difficulty from simulation:**
   ```gdscript
   # Use Python threat level
   func set_difficulty_from_threat(threat_level: float):
       hp_modifier = 1.0 + (threat_level * 0.1)
   ```

---

## 9. Related Systems to Implement Next

1. **Enemy Objective System** — Enemies target structures, not just player
2. **Sector Damage System** — Structures take persistent damage
3. **Repair Gameplay** — Player repairs damaged structures

See: `design/ENEMY_OBJECTIVE_SYSTEM.md` and `design/SECTOR_DAMAGE_SYSTEM.md`
</file>

<file path="custodian/game/systems/core/systems/navigation_system.gd">
extends Node
class_name NavigationSystem

## AStar2D-based navigation connected to floor tilemap.
## Provides pathfinding for enemies through the compound.

signal navigation_ready()
signal navigation_dirty()

@export var floor_tilemap_path: NodePath
@export var walls_tilemap_path: NodePath
@export var tile_size: Vector2i = Vector2i(32, 32)

var astar: AStar2D
var floor_tilemap: TileMapLayer
var walls_tilemap: TileMapLayer
var runtime_blocker_provider: Node
var _walkable_tiles: Dictionary = {}  # Vector2i -> bool
var _initialized: bool = false

var _init_deferred: bool = false

func _ready() -> void:
	add_to_group("navigation")
	# Defer initialization to allow procgen to finish
	call_deferred("_initialize_navigation_deferred")


func _exit_tree() -> void:
	astar = null
	floor_tilemap = null
	walls_tilemap = null
	runtime_blocker_provider = null
	_walkable_tiles.clear()
	_initialized = false
	_init_deferred = false


func _initialize_navigation_deferred() -> void:
	if _init_deferred:
		return
	_init_deferred = true
	
	# Wait a bit for procgen to complete
	await get_tree().create_timer(0.5).timeout
	_initialize_navigation()


func _initialize_navigation() -> void:
	var world_loader = get_tree().get_first_node_in_group("contract_world_loader")
	if world_loader != null:
		if world_loader.has_method("is_contract_activation_aborted") and bool(world_loader.call("is_contract_activation_aborted")):
			print("[NavigationSystem] Contract generation failed; navigation initialization skipped")
			return
		if world_loader.has_method("is_contract_world_pending") and bool(world_loader.call("is_contract_world_pending")):
			return

	if floor_tilemap_path != NodePath():
		floor_tilemap = get_node_or_null(floor_tilemap_path)
	
	if walls_tilemap_path != NodePath():
		walls_tilemap = get_node_or_null(walls_tilemap_path)
	
	# Try to find tilemaps automatically if not assigned
	if floor_tilemap == null:
		floor_tilemap = _find_floor_tilemap()
	
	if floor_tilemap == null:
		push_warning("[NavigationSystem] No floor tilemap found")
		return
	if runtime_blocker_provider == null:
		for provider in get_tree().get_nodes_in_group("procgen_walkability_provider"):
			if provider != null and provider.get("floor_tilemap") == floor_tilemap:
				runtime_blocker_provider = provider
				break
	
	astar = AStar2D.new()
	_walkable_tiles.clear()
	_build_navigation_graph()
	_initialized = true
	navigation_ready.emit()
	print("[NavigationSystem] Initialized with ", _walkable_tiles.size(), " walkable tiles")


func set_runtime_tilemaps(p_floor_tilemap: TileMapLayer, p_walls_tilemap: TileMapLayer, p_runtime_blocker_provider: Node = null) -> void:
	floor_tilemap = p_floor_tilemap
	walls_tilemap = p_walls_tilemap
	runtime_blocker_provider = p_runtime_blocker_provider


func _find_floor_tilemap() -> TileMapLayer:
	# Try to find from world loader / contract map
	var world_loader = get_tree().get_first_node_in_group("contract_world_loader")
	if world_loader and world_loader.has_method("get_active_map_instance"):
		var map_instance = world_loader.get_active_map_instance()
		if map_instance and "floor_tilemap" in map_instance:
			return map_instance.get("floor_tilemap")
	
	# Try direct child of world
	var world = get_tree().get_first_node_in_group("world")
	if world == null:
		world = get_node_or_null("/root/GameRoot/World")
	
	if world:
		# Look for ProcGenMap in world children
		for child in world.get_children():
			if child.has_method("get_floor_tilemap"):
				return child.get_floor_tilemap()
			if child.name.contains("ProcGen"):
				var ft = child.get_node_or_null("Floor")
				if ft is TileMapLayer:
					return ft
				# Check nested ProcGenTilemap
				for nested in child.get_children():
					if "floor_tilemap" in nested:
						return nested.get("floor_tilemap")
	
	# Look for tilemap in world directly
	if world:
		var tilemap = world.get_node_or_null("Floor")
		if tilemap is TileMapLayer:
			return tilemap
	
	return null


func _build_navigation_graph() -> void:
	if floor_tilemap == null:
		return
	
	var used_cells = floor_tilemap.get_used_cells()
	
	for cell in used_cells:
		if _is_walkable(cell):
			_walkable_tiles[cell] = true
			var world_pos = floor_tilemap.to_global(floor_tilemap.map_to_local(cell))
			astar.add_point(_cell_to_id(cell), world_pos, 1.0)
	
	# Connect adjacent points
	for cell in _walkable_tiles.keys():
		_connect_adjacent_cells(cell)


func _cell_to_id(cell: Vector2i) -> int:
	return (int(cell.x) << 32) | (int(cell.y) & 0xffffffff)


func _id_to_cell(id: int) -> Vector2i:
	return Vector2i(
		int(id >> 32),
		int(id & 0xffffffff)
	)


func _is_walkable(cell: Vector2i) -> bool:
	if floor_tilemap == null:
		return false
	
	var source_id = floor_tilemap.get_cell_source_id(cell)
	if source_id < 0:
		return false
	
	# Check walls tilemap
	if walls_tilemap != null:
		var wall_source = walls_tilemap.get_cell_source_id(cell)
		if wall_source >= 0:
			return false

	if runtime_blocker_provider != null \
			and is_instance_valid(runtime_blocker_provider) \
			and runtime_blocker_provider.has_method("is_runtime_walkable_after_props") \
			and not bool(runtime_blocker_provider.call("is_runtime_walkable_after_props", cell)):
		return false
	
	return true


func _connect_adjacent_cells(cell: Vector2i) -> void:
	var neighbors = [
		cell + Vector2i(0, -1),  # North
		cell + Vector2i(1, 0),   # East
		cell + Vector2i(0, 1),   # South
		cell + Vector2i(-1, 0),  # West
	]
	
	for neighbor in neighbors:
		if _walkable_tiles.has(neighbor):
			astar.connect_points(
				_cell_to_id(cell),
				_cell_to_id(neighbor),
				true
			)


func get_path_to_target(start: Vector2, target: Vector2) -> PackedVector2Array:
	if not _initialized or astar == null:
		return PackedVector2Array([start, target])
	
	var start_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(start)) if floor_tilemap else Vector2i()
	var target_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(target)) if floor_tilemap else Vector2i()
	
	# Clamp to walkable tiles
	start_cell = _get_nearest_walkable(start_cell)
	target_cell = _get_nearest_walkable(target_cell)
	
	if not _walkable_tiles.has(start_cell) or not _walkable_tiles.has(target_cell):
		return PackedVector2Array([start, target])
	
	var start_id = _cell_to_id(start_cell)
	var target_id = _cell_to_id(target_cell)
	
	if not astar.has_point(start_id) or not astar.has_point(target_id):
		return PackedVector2Array([start, target])
	
	var path_points = astar.get_point_path(start_id, target_id)
	
	if path_points.is_empty():
		return PackedVector2Array([start, target])
	
	return path_points


func _get_nearest_walkable(cell: Vector2i) -> Vector2i:
	if _walkable_tiles.has(cell):
		return cell
	
	# Search in expanding circles
	for radius in range(1, 10):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var check = cell + Vector2i(dx, dy)
				if _walkable_tiles.has(check):
					return check
	
	return cell


func is_in_walkable_area(position: Vector2) -> bool:
	if floor_tilemap == null:
		return true
	
	var cell = floor_tilemap.local_to_map(floor_tilemap.to_local(position))
	return _walkable_tiles.has(cell)


func get_random_walkable_position() -> Vector2:
	if _walkable_tiles.is_empty():
		return Vector2.ZERO
	
	var cells = _walkable_tiles.keys()
	cells.shuffle()
	
	for cell in cells:
		var world_pos = floor_tilemap.to_global(floor_tilemap.map_to_local(cell))
		if _is_position_clear(world_pos):
			return world_pos
	
	return Vector2.ZERO


func _is_position_clear(pos: Vector2) -> bool:
	var viewport := get_viewport()
	if viewport == null or viewport.world_2d == null:
		return true
	var space = viewport.world_2d.direct_space_state
	if space == null:
		return true
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1  # Default collision
	
	var results = space.intersect_point(query, 1)
	return results.is_empty()


func get_path_length(path: PackedVector2Array) -> float:
	var length = 0.0
	for i in range(1, path.size()):
		length += path[i].distance_to(path[i-1])
	return length


func rebuild() -> void:
	if astar != null:
		astar.clear()
	_walkable_tiles.clear()
	_initialized = false
	var world_loader = get_tree().get_first_node_in_group("contract_world_loader")
	if world_loader != null and world_loader.has_method("is_contract_activation_aborted") and bool(world_loader.call("is_contract_activation_aborted")):
		print("[NavigationSystem] Contract generation failed; navigation rebuild skipped")
		return
	_initialize_navigation()
	navigation_dirty.emit()


func get_navigation_authority_debug_snapshot() -> Dictionary:
	var authoritative_floor_count := 0
	if (
		runtime_blocker_provider != null
		and is_instance_valid(runtime_blocker_provider)
		and runtime_blocker_provider.has_method(
			"debug_get_generated_floor_cells"
		)
	):
		var authoritative: Dictionary = runtime_blocker_provider.call(
			"debug_get_generated_floor_cells"
		)
		authoritative_floor_count = authoritative.size()
	return {
		"authoritative_floor_count": authoritative_floor_count,
		"painted_floor_count": (
			floor_tilemap.get_used_cells().size()
			if floor_tilemap != null
			else 0
		),
		"navigation_point_count": _walkable_tiles.size(),
		"initialized": _initialized,
	}
</file>

<file path="AGENTS.md">
# CUSTODIAN Repository Router

This repository contains multiple eras of the project. For all active Godot work under `custodian/`, the mandatory local authority and workflow primer is:

1. `custodian/AGENTS.md`
2. the matching implementation spec under `design/`
3. `custodian/docs/ai_context/CURRENT_STATE.md`

Active Godot feature specifications live under `design/02_features/`. Do not add new work to the retired `design/20_features/` tree. The legacy Python simulation and its AI context are historical reference only.

Repository-root path equivalents used by the local primer are:

- active design: `design/`
- current state/context/index: `custodian/docs/ai_context/`
- active runtime: `custodian/game/`, `custodian/content/`, and `custodian/project.godot`
- validation: `custodian/docs/ai_context/VALIDATION_RECIPES.md` and `custodian/tools/validation/`
- deterministic micro-playtest review: route through `custodian/AGENTS.md`,
  `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`, and the Moment Forge
  section of `custodian/docs/ai_context/VALIDATION_RECIPES.md`

If root guidance conflicts with `custodian/AGENTS.md` for Godot runtime work, follow `custodian/AGENTS.md`.

For long-horizon wanted-feature tracking, use `design/90_codex/` and its tracker at `design/90_codex/TRACKER.md`; codex cards are idea inventory until graduated into active design authority.
</file>

<file path="custodian/game/enemies/procgen/grunt_animation_library.gd">
extends RefCounted
class_name GruntAnimationLibrary

const GRUNT_FRAME_SIZE := Vector2i(96, 96)
const MARINE_FRAME_SIZE := Vector2i(96, 96)
const MARINE_DASH_FRAME_SIZE := Vector2i(128, 128)
const MARINE_DASH_FX_FRAME_SIZE := Vector2i(156, 156)
const MARINE_IDLE_DIRECTIONS := [&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw"]

const ANIMATION_SPECS := {
	"idle_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__locomotion__idle_01__s__10f__96.png",
		"fps": 6.0,
		"loop": true,
	},
	"run_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__locomotion__run_01__e__10f__96.png",
		"fps": 10.0,
		"loop": true,
	},
	"run_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__locomotion__run_01__w__10f__96.png",
		"fps": 10.0,
		"loop": true,
	},
	"melee_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__e__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_se": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__se__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_sw": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__sw__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__w__11f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"stagger_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__stagger_01__s__8f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"stagger_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__stagger_01__e__11f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"stagger_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__stagger_01__w__11f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"special_windup_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__special_windup_01__e__6f__96.png",
		"fps": 18.0,
		"loop": false,
	},
	"special_windup_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__special_windup_01__w__6f__96.png",
		"fps": 18.0,
		"loop": false,
	},
	"special_inflight_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__special_inflight_01__e__6f__96.png",
		"fps": 18.0,
		"loop": false,
	},
	"special_inflight_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__special_inflight_01__w__6f__96.png",
		"fps": 18.0,
		"loop": false,
	},
	"special_recovery_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__special_recovery_01__e__6f__96.png",
		"fps": 18.0,
		"loop": false,
	},
	"special_recovery_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__special_recovery_01__w__6f__96.png",
		"fps": 18.0,
		"loop": false,
	},
	"crit_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__crit_01__s__8f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"critical_open_enter_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_enter_01__s__5f__96.png",
		"fps": 12.0,
		"loop": false,
		"required": true,
	},
	"critical_open_hold_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_hold_01__s__4f__96.png",
		"fps": 6.0,
		"loop": true,
		"required": true,
	},
	"critical_open_recover_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_recover_01__s__5f__96.png",
		"fps": 10.0,
		"loop": false,
		"required": true,
	},
	"critical_execution_victim_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__s__8f__96.png",
		"fps": 12.0,
		"loop": false,
		"required": true,
	},
	"critical_execution_victim_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__e__12f__96.png",
		"fps": 12.0,
		"loop": false,
		"required": true,
	},
	"critical_execution_victim_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__w__12f__96.png",
		"fps": 12.0,
		"loop": false,
		"required": true,
	},
	"crit_recovery_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__crit_recovery_01__s__5f__96.png",
		"fps": 8.0,
		"loop": false,
	},
	"death_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__death_01__e__8f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"flinch_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__flinch_01__s__6__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"flinch_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__flinch_01__e__5f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"flinch_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__flinch_01__w__5f__96.png",
		"fps": 12.0,
		"loop": false,
	},
}

const FX_ANIMATION_SPECS := {
	"melee_fx_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__e__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_fx_se": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__se__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_fx_sw": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__sw__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_fx_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__w__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"crit_fx_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__crit_01__s__8f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"flinch_fx_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__flinch_01__s__5f__96.png",
		"fps": 12.0,
		"loop": false,
	},
}

static var _cached_frames: SpriteFrames = null
static var _cached_fx_frames: SpriteFrames = null
static var _cached_marine_frames: SpriteFrames = null
static var _cached_marine_fx_frames: SpriteFrames = null


static func get_grunt_sprite_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames
	var frames := SpriteFrames.new()
	for animation_name in ANIMATION_SPECS.keys():
		_add_strip_animation(frames, String(animation_name), ANIMATION_SPECS[animation_name])
	_cached_frames = frames
	return _cached_frames


static func get_grunt_fx_sprite_frames() -> SpriteFrames:
	if _cached_fx_frames != null:
		return _cached_fx_frames
	var frames := SpriteFrames.new()
	for animation_name in FX_ANIMATION_SPECS.keys():
		_add_strip_animation(frames, String(animation_name), FX_ANIMATION_SPECS[animation_name])
	_cached_fx_frames = frames
	return _cached_fx_frames


static func get_marine_sprite_frames() -> SpriteFrames:
	if _cached_marine_frames != null:
		return _cached_marine_frames
	var frames := SpriteFrames.new()
	for direction in MARINE_IDLE_DIRECTIONS:
		var suffix := String(direction)
		var spec := {
			"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__idle_01__%s__4f__96.png" % suffix,
			"fps": 6.0,
			"loop": true,
			"frame_size": MARINE_FRAME_SIZE,
		}
		_add_strip_animation(frames, "marine_idle_%s" % suffix, spec)
	_add_strip_animation(frames, "marine_dash_charge_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_charge_01__e__5f__128.png",
		"fps": 12.0,
		"loop": false,
		"frame_size": MARINE_DASH_FRAME_SIZE,
	})
	_add_strip_animation(frames, "marine_dash_inflight_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_inflight_01__e__5f__128.png",
		"fps": 20.0,
		"loop": false,
		"frame_size": MARINE_DASH_FRAME_SIZE,
	})
	_add_strip_animation(frames, "marine_dash_recovery_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_recovery_01__e__5f__128.png",
		"fps": 12.0,
		"loop": false,
		"frame_size": MARINE_DASH_FRAME_SIZE,
	})
	_cached_marine_frames = frames
	return _cached_marine_frames


static func get_marine_fx_sprite_frames() -> SpriteFrames:
	if _cached_marine_fx_frames != null:
		return _cached_marine_fx_frames
	var frames := SpriteFrames.new()
	_add_strip_animation(frames, "marine_dash_attack_fx_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/fx/enemy_marine__fx__unarmed__dash_attack_01__e__8f__156.png",
		"fps": 13.0,
		"loop": false,
		"frame_size": MARINE_DASH_FX_FRAME_SIZE,
	})
	_cached_marine_fx_frames = frames
	return _cached_marine_fx_frames


static func get_move_animation(direction: Vector2) -> StringName:
	return &"run_w" if direction.x < 0.0 else &"run_e"


static func get_attack_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		if direction.y > 0.35:
			return &"melee_sw"
		return &"melee_w"
	if direction.y > 0.35 and direction.x >= 0.0:
		return &"melee_se"
	return &"melee_e"


static func get_stagger_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		return &"stagger_w"
	if direction.x > 0.2:
		return &"stagger_e"
	return &"stagger_s"


static func get_parry_critical_open_animation(phase: StringName) -> StringName:
	match phase:
		&"enter":
			return &"critical_open_enter_s"
		&"hold":
			return &"critical_open_hold_s"
		&"recover":
			return &"critical_open_recover_s"
		&"executing":
			return &"critical_execution_victim_s"
	return &""


static func get_parry_critical_execution_victim_animation() -> StringName:
	return &"critical_execution_victim_s"


static func get_attack_fx_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		if direction.y > 0.35:
			return &"melee_fx_sw"
		return &"melee_fx_w"
	if direction.y > 0.35:
		return &"melee_fx_se"
	return &"melee_fx_e"


static func get_marine_idle_animation(direction: Vector2) -> StringName:
	return StringName("marine_idle_%s" % _get_direction_suffix(direction))


static func get_marine_dash_attack_animation(_direction: Vector2) -> StringName:
	return &"marine_dash_inflight_e"


static func get_marine_dash_phase_animation(phase: StringName, _direction: Vector2 = Vector2.RIGHT) -> StringName:
	match phase:
		&"windup":
			return &"marine_dash_charge_e"
		&"dash":
			return &"marine_dash_inflight_e"
		&"impact_lock":
			return &"marine_dash_inflight_e"
		&"recovery":
			return &"marine_dash_recovery_e"
	return &"marine_dash_inflight_e"


static func get_grunt_falcon_punch_phase_animation(phase: StringName, direction: Vector2 = Vector2.RIGHT) -> StringName:
	match phase:
		&"windup":
			return &"special_windup_w" if direction.x < -0.05 else &"special_windup_e"
		&"leap", &"impact_lock":
			return &"special_inflight_w" if direction.x < -0.05 else &"special_inflight_e"
		&"recovery":
			return &"special_recovery_w" if direction.x < -0.05 else &"special_recovery_e"
	return &"special_inflight_w" if direction.x < -0.05 else &"special_inflight_e"


static func get_flinch_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		return &"flinch_w"
	if direction.x > 0.2:
		return &"flinch_e"
	return &"flinch_s"


static func get_marine_dash_attack_fx_animation(_direction: Vector2) -> StringName:
	return &"marine_dash_attack_fx_e"


static func _add_strip_animation(frames: SpriteFrames, animation_name: String, spec: Dictionary) -> void:
	var path := String(spec["path"])
	if not ResourceLoader.exists(path):
		if bool(spec.get("required", false)):
			push_error("[GruntAnimationLibrary] Required grunt sheet missing: %s" % path)
		else:
			push_warning("[GruntAnimationLibrary] Missing grunt sheet: %s" % path)
		return
	var texture := load(path)
	if not (texture is Texture2D):
		push_warning("[GruntAnimationLibrary] Grunt sheet is not a Texture2D: %s" % path)
		return
	var tex := texture as Texture2D
	var frame_size: Vector2i = spec.get("frame_size", GRUNT_FRAME_SIZE)
	var frame_width := frame_size.x
	var frame_height := frame_size.y
	var frame_count := int(tex.get_width() / frame_width)
	if frame_count <= 0 or tex.get_height() < frame_height:
		push_warning("[GruntAnimationLibrary] Grunt sheet has unexpected dimensions: %s" % path)
		return
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, bool(spec.get("loop", true)))
	frames.set_animation_speed(animation_name, float(spec.get("fps", 8.0)))
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float(frame_index * frame_width), 0.0, float(frame_width), float(frame_height))
		frames.add_frame(animation_name, atlas)


static func _get_direction_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector := int(round(angle / (PI / 4.0))) % 8
	var angle_to_suffix := [&"e", &"se", &"s", &"sw", &"w", &"nw", &"n", &"ne"]
	return angle_to_suffix[sector]
</file>

<file path="design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md">
# RANGED COMBAT BALANCE AND STEALTH SYSTEM

Status: implemented V1; tuning in progress  
Owner: gameplay/combat + enemy behavior  
Runtime target: Godot 4 (`custodian/`)  
Authority brief: `design/COMBAT_BALANCE.md`

## Purpose

Keep ranged weapons strong in deliberate bursts without allowing unlimited screen-clearing. The runtime combines finite carried ammunition, range and accuracy pressure, per-weapon heat, positional gunshot noise, sight/hearing perception, loss-of-contact search, and hostile ambient camps. Ammo is strategic scarcity; heat is immediate firing pressure; noise creates world consequences.

## Implemented In This Pass

- Ammo is stored by canonical type (`kinetic_light`, `kinetic_heavy`, `energy_cell`, `shell`, `scrap_charge`) with the legacy `kinetic` alias normalized to `kinetic_light`.
- Reserve and loaded state are separate. Loaded ammo is keyed by weapon ID, so weapon swaps do not refill magazines. Legacy standard/heavy fields and HUD keys remain adapter outputs.
- The active baseline is 72 light and 16 heavy reserve capacity. The carbine starts with a 24-round magazine and 48 reserve; the P-9 uses a 10-round magazine and shares the capped light-ammo pool.
- Ammo caches use tunable type/amount ranges and clamp through `Operator.add_ammo_type`. Main-scene caches and supply drops are substantially smaller.
- Projectiles track distance, apply weapon-owned linear damage falloff, and expire at max range.
- Standing, walking, sprinting, and sneaking apply weapon-data spread multipliers. Heat further scales spread and recoil.
- Heat is runtime state keyed by weapon ID, never shared `.tres` state. Shots add heat; cooling waits for a delay; overheat locks firing, cools faster, and releases at no more than 70% heat.
- `NoiseEventBus` is a generic autoload. Gunshots emit one event per trigger pull, including muzzle-obstructed shots. Suppression scales radius but never makes a shot silent.
- Operator stealth snapshots include sneak, sprint, firing, dodge, velocity, visibility, and movement-noise state. Gunshots use events rather than the ambient snapshot.
- Existing enemy perception retains raycast LOS and now consumes noise events. Enemies investigate the event position rather than receiving permanent knowledge of the Operator.
- Existing enemy behavior now tracks last seen/heard positions, pursuit memory, deterministic search offsets, home position, camp ID, and a leash. Hard leash applies after LOS is broken.
- `AmbientEnemyCamp` supports authored activation-limited camps; `AmbientEnemySpawner` supports procgen/authored marker groups. Successful contract generation deterministically places two separated walkable camp markers, each configured for two hostile grunts outside wave spawning. The Sundered Keep approach layout separately authors one grunt in each vista subregion.
- `get_weapon_status()` exposes canonical ammo, heat, overheat, noise, suppression, range values, and whether a ranged magazine is currently active while retaining legacy keys.
- `get_weapon_status()` also exposes reload/overheat progress, warning and overheat thresholds, decay delay, effective heat-per-shot, shots-to-overheat, and weapon-independent heat bands. Discrete `weapon_feedback_event` transitions drive presentation without polling sticky failure state.
- The compact HUD preserves magazine/reserve counts and adds one priority-driven pressure row for heat, hot/critical, reload, dry, and vent recovery. A child `WeaponFeedbackPresenter` owns local-only dry/reload/heat audio, critical tint, and procedural barrel vent VFX; none of these cues emit `NoiseEventBus` events.
- Primary/two-handed ranged-ready uses a composition split instead of baked ranged locomotion requirements. While moving, the lower body may remain movement-owned on reusable `unarmed_{idle,walk,run}` clips only when its direction stays within 100 degrees of the aim-owned upper body. At stationary speed (`velocity.length_squared() <= 16.0`) or beyond that twist limit, the lower body resolves from the upper-body aim direction so a stopped Operator cannot retain a stale locomotion facing. The upper body owns the modular ranged animation clock; the weapon layer is normalized-frame-slaved to it, and muzzle FX is action/frame-owned. The legacy full-body ranged sprite only appears when the modular ranged upper/weapon stack is unavailable. Accepted primary ranged shots can still play modular upper/weapon/FX fire layers when matching clips exist, with projectile emission, ammo, heat, range/falloff, and noise authority unchanged.

### Modular ranged pose and clock contract

- `upper body`: authoritative aim direction and animation clock.
- `weapon`: uses the upper body's normalized frame position every presentation tick; it must not advance on an independent clock.
- `muzzle FX`: starts from the accepted fire event and follows the authored fire frame contract.
- `lower body`: independently follows movement only while actually moving and within the allowed torso/leg twist; otherwise it follows the upper body.
- Directional socket layout is absolute. Runtime layout must assign from authored base/socket data and may not accumulate offsets with `+=`.
- Leaving ranged-ready resets retained rotation, scale, and modulation, then recomputes the absolute socket layout.

### Primary ranged direction and posture contract

The authored primary sequence is `relaxed -> raising -> ready -> firing -> recovering -> ready -> lowering -> relaxed`.

- Relaxed and ready continuously resolve the current cursor/aim direction.
- Raising and lowering may retarget to another directional `ranged_2h_aim_modular` clip without restarting normalized progress.
- Firing commits `_primary_ranged_action_direction` when the shot is accepted. Lower, upper, weapon, and fire FX remain coherent with that direction until the fire clip ends; a cursor reversal cannot twist the lower body 180 degrees during the shot.
- Recovering releases the committed direction and immediately resolves current aim into ready stance.
- Upper body remains the clock authority. Weapon frame sync also verifies the phase-appropriate directional animation name before copying normalized frame position.
- `get_weapon_status()` exposes `ranged_posture`, transition ratio, readiness, fire eligibility, and committed direction as read-only presentation/debug values.
- Normal-play readiness is conveyed by the procedural ranged reticle, not permanent HUD text. The HUD consumes the status snapshot and never owns readiness or firing rules.

## Phase Mapping

1. Ammo economy: typed reserve caps, persistent magazines, smaller pickups and drops.
2. Range/accuracy: max range, falloff, movement and heat spread.
3. Heat: per-weapon accumulation, delayed decay, overheat lockout.
4. Noise: generic event resource and autoload bus.
5. Stealth: stable Operator snapshot; no cover/light simulation yet.
6. Perception: ray LOS plus event hearing through the existing component.
7. Ambient placement: authored camps and marker-driven spawner bridge.
8. Noise integration: distance/threat response without global aggro.
9. Pursuit: last-known search, LOS loss, and return-home leash.
10. Status/feedback: canonical progress snapshot, debounced transition events, production compact pressure HUD, local audio, and procedural vent VFX.
11. Vehicle hook: contract documented below; runtime deferred.
12. Tuning: initial carbine, pistol, shotgun, sniper, and minigun data applied.
13. Validation: focused smoke plus headless parse/runtime checks.
14. Documentation: this spec and the active AI context are canonicalized to live paths.

## Runtime Files

- `custodian/game/actors/operator/operator.gd`
- `custodian/tools/validation/operator_primary_ranged_modular_fire_smoke.gd`
- `custodian/game/actors/operator/operator_weapon_definition.gd`
- `custodian/game/actors/operator/components/weapon_feedback_presenter.gd`
- `custodian/game/ui/hud/custodian_hud.gd`
- `custodian/game/vfx/weapons/weapon_overheat_vent_vfx.tscn`
- `custodian/game/actors/projectiles/bullet.gd`
- `custodian/content/weapons/weapon_schema.json`
- `custodian/content/weapons/data/*.json`
- `custodian/game/systems/stealth/noise_event.gd`
- `custodian/game/systems/stealth/noise_event_bus.gd`
- `custodian/game/actors/enemies/components/enemy_perception_component.gd`
- `custodian/game/actors/enemies/components/enemy_blackboard.gd`
- `custodian/game/actors/enemies/enemy_behavior_state_machine.gd`
- `custodian/game/systems/spawning/ambient_enemy_camp.gd`
- `custodian/game/systems/spawning/ambient_enemy_spawner.gd`
- `custodian/game/systems/core/systems/contract_world_loader.gd`
- `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.gd`
- `custodian/game/actors/items/ammo_cache.gd`
- `custodian/scenes/game.tscn`
- `custodian/tools/validation/combat_resource_feedback_smoke.gd`

The original brief's `custodian/assets/weapons/` path is stale. Live weapon data is under `custodian/content/weapons/`.

## Tuning Baseline

| Weapon | Magazine / reserve cap | Effective / max range | Heat per shot / decay | Noise radius |
|---|---:|---:|---:|---:|
| P-9 sidearm | 10 / 60 shared light pool | 110 / 220 | 8 / 34 | 260 |
| VX-3 carbine | 24 / 72 | 180 / 320 | 11 / 26 | 420 |
| Shotgun | 6 / 16 shells | 90 / 180 | 24 / 24 | 480 |
| Sniper | 5 / 12 heavy | 360 / 520 | 55 / 18 | 620 |
| Minigun | 72 / 96 light | 160 / 300 | 5 / 14 | 560 |

## Validation

- `env HOME=/tmp/custodian-godot-home godot --headless --script tools/validation/ranged_combat_balance_smoke.gd`
- `env HOME=/tmp/custodian-godot-home godot --headless --script tools/validation/combat_resource_feedback_smoke.gd`
- `env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd`
- `env HOME=/tmp/custodian-godot-home godot --headless --path . --editor --quit`
- The modular-primary smoke covers the south-move/east-aim stop regression and asserts upper/weapon normalized-frame agreement across 120 presentation ticks.
- Main-scene headless boot reaches generated-world initialization without new script parse/load or missing-animation errors; existing shutdown leak diagnostics remain non-fatal test-harness noise.
- Manual acceptance still required for feel: burst-to-overheat cadence, visible spread/recoil, camp investigation, corner LOS break/search/return, reload and sidearm switching, and melee/parry/dodge regression.

## Future: Vehicle-Mounted Weapon Firing

## Frame-aware Carbine socket contract

The live modular ranged presentation follows
`design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md`.
For the Carbine phase-1 sectors (`e`, `w`, `se`, `sw`), upper-body animation
name and frame select one grip/muzzle/ejection/draw-order record. Projectile
origin and muzzle presentation consume that record rather than the generic
forward-distance muzzle. The upper body is the master clock; weapon and fire FX
are slaves. Missing production metadata is an error, not a silent fallback.

## Ranged aim transition and camera contract

Primary two-handed ranged aim uses distinct timing: raise targets `0.22 s`,
lower targets `0.12 s`, and the aim-ready threshold is `0.70`. Movement remains
available under the existing ranged-ready multiplier. Fire held or pressed
during raise is accepted once the threshold is crossed; lowering is not played
at the raise speed.

The Operator exposes intent only. `custodian/game/world/camera.gd` owns
interpolation and composes ranged aim with contextual zoom, movement/threat
offsets, shake, push, map bounds, and follow smoothing. Initial targets are a
`1.07` zoom multiplier, `32 px` directional lead, `0.22 s` entry response, and
`0.13 s` exit response. Cancellation clears the camera target; camera runtime
state returns to `1.0` multiplier and zero lead. The reticle consumes the
read-only aim accuracy ratio and becomes tight at the ready threshold.

A future `VehicleWeaponDefinition` should own `weapon_id`, weapon data path, mount socket, fire arc, heat state, ammo source, noise radius, recoil/knockback, and occupant requirement. When an occupied vehicle owns an active weapon, primary fire routes to the vehicle before personal weapon logic. Vehicle ammo, heat, and noise belong to the mount; personal firing is disabled unless the vehicle explicitly supports firing ports. Vehicle weapons reuse `NoiseEventBus` and the heat schema, with a starting noise target of 700 px for light guns and 1000 px for heavy guns. No partial vehicle-fire hook is implemented in V1 because current occupant/input ownership does not expose a complete mount contract.

## Deferred

- Manual cue-mix/cadence review, bespoke P-9 reload/heat replacements, optional authored vent sprite strip, and optional pressure-state HUD icons
- Suppressor item/mod inventory
- Cover and lighting visibility modifiers
- Large-scale procedural enemy bases and streaming/pooling
- Advanced squad coordination and sector alarm networks
- Vehicle-mounted weapon firing

## Next Agent Slice

Goal: tune the completed feedback slice in play and replace shared V1 cues without changing its event/status contract.
Files: weapon feedback presenter, compact HUD, weapon JSON/audio, and optional vent/icon assets.
Constraints: do not move simulation authority into UI; retain deterministic search/spawn decisions; preserve canonical ammo adapters until all HUD consumers migrate.
Acceptance: manual scenario from `design/COMBAT_BALANCE.md` passes, feedback remains readable without held-input chatter, and no pre-existing combat controls or AI hearing behavior regress.
</file>

<file path="custodian/game/actors/enemies/enemy_grunt.tscn">
[gd_scene load_steps=9 format=3 uid="uid://enemy_grunt_001"]

[ext_resource type="Script" path="res://game/actors/enemies/enemy.gd" id="1_enemy"]
[ext_resource type="Script" path="res://game/actors/enemies/components/enemy_blackboard.gd" id="2_blackboard"]
[ext_resource type="Script" path="res://game/actors/enemies/components/enemy_perception_component.gd" id="3_perception"]
[ext_resource type="Script" path="res://game/actors/enemies/components/enemy_objective_sensor.gd" id="4_sensor"]
[ext_resource type="Script" path="res://game/actors/enemies/components/enemy_loot_carrier.gd" id="5_carrier"]
[ext_resource type="Script" path="res://game/actors/enemies/enemy_behavior_state_machine.gd" id="6_behavior"]
[ext_resource type="Script" path="res://game/actors/effects/blob_shadow.gd" id="7_blob_shadow"]
[ext_resource type="Texture2D" path="res://content/sprites/world/shadows/contact_shadow_character_64x32.png" id="8_contact_shadow"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_grunt"]
size = Vector2(26, 26)

[node name="EnemyGrunt" type="CharacterBody2D"]
z_index = 2
script = ExtResource("1_enemy")
enemy_name = "GRUNT"
speed = 84.0
health = 78.0
max_health = 78.0
damage = 13.0
base_tint = Color(0.72, 0.28, 0.22, 1)
attack_windup_duration = 0.42
material_drop_min = 1
material_drop_max = 3
loot_table_id = "practical_salvage_x_grunt"
loot_table = [{"resource_id": "ruin_scrap", "min": 1, "max": 3, "chance": 1.0, "label": "bent plating and stripped field brackets"}, {"resource_id": "spent_charge_cell", "min": 1, "max": 1, "chance": 0.35, "label": "cheap sidearm or chest-rig cell"}, {"resource_id": "frayed_signal_filament", "min": 1, "max": 1, "chance": 0.2, "label": "helmet comms conductor"}, {"resource_id": "cracked_field_tag", "min": 1, "max": 1, "chance": 0.15, "label": "scraped patrol identity tag"}, {"resource_id": "power_components", "min": 1, "max": 1, "chance": 0.1, "label": "tiny regulator or heat-warped relay"}, {"resource_id": "memory_glass_fragment", "min": 1, "max": 1, "chance": 0.04, "label": "impossible patrol-order sliver"}, {"resource_id": "white_thread_knot", "min": 1, "max": 1, "chance": 0.01, "label": "clean white thread clue"}]
custom_enemy_animation_set = "enemy_grunt"
custom_enemy_animation_scale = Vector2(1, 1)
custom_enemy_fx_scale = Vector2(1, 1)
grunt_parry_critical_operator_offset = Vector2(0, 0)
grunt_falcon_punch_enabled = true
grunt_falcon_punch_windup_time = 0.75
grunt_falcon_punch_leap_time = 0.28
grunt_falcon_punch_impact_lock_time = 0.08
grunt_falcon_punch_recovery_time = 0.7
grunt_falcon_punch_distance_px = 96.0
grunt_falcon_punch_damage_multiplier = 1.35
grunt_falcon_punch_cooldown = 2.1
grunt_falcon_punch_launch_band_min = 88.0
grunt_falcon_punch_launch_band_max = 184.0
grunt_falcon_punch_hit_active_start_ratio = 0.38
grunt_falcon_punch_hit_active_end_ratio = 0.76
grunt_falcon_punch_hit_forward_reach_px = 42.0
grunt_falcon_punch_hit_lateral_reach_px = 30.0
grunt_falcon_punch_windup_speed_multiplier = 0.15
grunt_falcon_punch_recovery_speed = 0.0
grunt_falcon_punch_stop_short_px = 28.0
behavior_state_machine_enabled = true
behavior_profile_id = &"raider_grunt"

[node name="Visual" type="ColorRect" parent="."]
offset_left = -13.0
offset_top = -13.0
offset_right = 13.0
offset_bottom = 13.0
color = Color(0.72, 0.28, 0.22, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_grunt")

[node name="HealthBar" type="ProgressBar" parent="."]
offset_left = -16.0
offset_top = -32.0
offset_right = 16.0
offset_bottom = -26.0
value = 100.0
show_percentage = false

[node name="BlobShadow" type="Node2D" parent="."]
position = Vector2(0, 12)
script = ExtResource("7_blob_shadow")
shadow_texture = ExtResource("8_contact_shadow")
base_radius = Vector2(13, 6.5)
shadow_alpha = 0.28

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
position = Vector2(0, -18)
scale = Vector2(1, 1)

[node name="CustomEnemyFxSprite" type="AnimatedSprite2D" parent="."]
visible = false
position = Vector2(0, -18)
scale = Vector2(1, 1)

[node name="CriticalExecutionAnchor" type="Marker2D" parent="."]
position = Vector2(0, 0)

[node name="EnemyBlackboard" type="Node" parent="."]
script = ExtResource("2_blackboard")

[node name="EnemyPerceptionComponent" type="Node" parent="."]
script = ExtResource("3_perception")

[node name="EnemyObjectiveSensor" type="Node" parent="."]
script = ExtResource("4_sensor")

[node name="EnemyLootCarrier" type="Node" parent="."]
script = ExtResource("5_carrier")

[node name="EnemyBehaviorStateMachine" type="Node" parent="."]
script = ExtResource("6_behavior")
</file>

<file path="custodian/AGENTS.md">
# CUSTODIAN AGENTS PRIMER

Mandatory entrypoint for any agent or developer working inside `custodian/`.

If you entered from the repository root, stop here first before changing runtime code, docs, assets, pipelines, or design references.

## Mission

This primer exists to route all work through one consistent authority chain, one current-state summary, and one repeatable process for:

- finding the right active docs quickly
- checking adjacent files before editing
- detecting documentation drift
- remediating drift before it compounds
- executing migrations without leaving stale references behind

## First-Read Order

Read these in order before making changes:

1. `../design/` for active Godot-native implementation specs
2. `docs/ai_context/CURRENT_STATE.md` for the latest runtime and documentation state
3. `docs/ai_context/CONTEXT.md` for project rules and handoff context
4. `docs/ai_context/FILE_INDEX.md` for high-signal file ownership and entrypoints
5. `docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` and any relevant packet in `docs/ai_context/task_packets/` when the packet-selection rules below call for one
6. `docs/ai_context/VALIDATION_RECIPES.md` and relevant prompt templates in `docs/ai_context/prompts/`
7. Relevant runtime/docs files for the feature or asset area you are touching

If a conflict appears, prefer this authority order:

1. `../design/`
2. `../python-sim/design/MASTER_DESIGN_DOCTRINE.md`
3. `docs/*`
4. legacy Python-era design or AI docs only as historical reference

## Current Design And Development State

- Active runtime authority is the Godot 4.x project in `custodian/`
- Active implementation specs live in `../design/`, with feature work normalized under `../design/02_features/`; do not add new specs under the retired `../design/20_features/` tree
- Active AI-facing context pack lives in `docs/ai_context/`
- Legacy Python runtime and Python AI context are historical reference only
- Deterministic fixed-step simulation remains a hard constraint
- Rendering/UI logic should not silently absorb simulation authority

## Routing Map

Use this map to land on the right material fast:

| Need | Read First | Then Check |
|---|---|---|
| Runtime feature behavior | `../design/` matching feature/system doc | `game/` scripts and `docs/ai_context/*` |
| Architecture or ownership | `docs/ai_context/FILE_INDEX.md` | `docs/ARCHITECTURE.md`, `docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md`, `../design/04_architecture/` |
| Current implementation status | `docs/ai_context/CURRENT_STATE.md` | `../design/TRACKING.md`, active feature docs |
| Asset layout or content placement | `docs/ASSET_LAYOUT_CONVENTION.md` | nearby `README.md` files in `content/` |
| Scene/runtime structure | `docs/SCENE_HIERARCHY.md` | `scenes/`, `game/`, `project.godot` |
| Migration or drift cleanup | `docs/AGENT_MIGRATION_PLAYBOOK.md` | this primer, `docs/ai_context/*` |
| Validation command selection | `docs/ai_context/VALIDATION_RECIPES.md` | task packet acceptance checks when a packet exists |
| Reusable agent prompts | `docs/ai_context/prompts/README.md` | task-specific prompt template |
| Agent workflow automation | `docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` | `tools/agent/` when scripts exist |

## Tooling And Scripts

Use the indexed scripts before inventing one-off commands. `docs/ai_context/FILE_INDEX.md` is the high-signal map for tool ownership, and `docs/ai_context/VALIDATION_RECIPES.md` is the command-selection authority.

- Search/read: prefer `rg`, `rg --files`, and targeted `sed`/`nl` reads. Use RTK wrappers only where the validation recipe recommends them or compact command output matters.
- Godot validation: use focused `custodian/tools/validation/*_smoke.gd` scripts for behavior checks; do not treat `godot --headless --quit` or import alone as sufficient for gameplay/presentation changes.
- Sprite and asset pipeline: start with `custodian/tools/pipelines/ingest.py`, `generate_inbox_manifests.py`, and the relevant validation recipe. For modular Operator work, `custodian/tools/operator/operator_ingest.sh` is the thin wrapper; default is dry-run, `--apply` runs rebuild/import/resource update/smoke/report.
- Operator animation reports: use `custodian/tools/validation/operator_animation_contract_report.py` for required/optional/missing/suspicious asset coverage. Reports belong under `reports/`, not active runtime folders.
- Preview/review helpers: use `custodian/tools/pipelines/operator_action_preview.py` and the review tools listed in `docs/ai_context/AGENT_TOOLING_BY_ASK.md`; generated preview output is review-only.
- Agent memory: check `agentmemory status`, start the worker with `agentmemory` when needed, and use it selectively for durable cross-session decisions or handoffs while keeping repository docs authoritative.

## Moment Forge Selection

Use Moment Forge for repeatable 2–8 second gameplay moments whose acceptance
depends on timing, audiovisual synchronization, movement/displacement,
readability, camera composition, or game feel.

1. After changing combat timing, animation playback or assets, VFX, SFX,
   healing presentation, attack movement, camera behavior, or curated vista
   presentation, run:

   ```bash
   python3 custodian/tools/iteration/run_moment.py --changed
   ```

2. Treat selection output as advice. Run the smallest relevant scenario
   explicitly; do not invoke every suggestion or use `--execute-suggested`
   without reviewing the matched paths and reasons.

3. Use:

   * `--capture-mode none` for deterministic assertions and fingerprints;
   * `--capture-mode evidence` for telemetry and authored-tick keyframes;
   * `--capture-mode full` when acceptance depends on audiovisual timing,
     readability, feel, or baseline comparison.

4. Focused smoke tests remain required for stable logic contracts. Moment Forge
   is additional experiential and regression evidence, not a replacement for
   narrow validation.

5. Moment Forge may be skipped for docs-only changes, tooling-only work,
   generated review artifacts, or refactors with no plausible runtime or
   presentation effect. State `Moment Forge: not run — <reason>` in the
   completion report.

6. When a repeatable high-value regression lacks a scenario, propose or add the
   narrowest stable scenario when it belongs to the task. Do not block unrelated
   work solely because scenario coverage is absent.

7. Never approve or replace a baseline automatically. Baseline acceptance
   requires explicit developer judgment.

8. Record scenario IDs, capture mode, pass/fail status, and report path under
   task completion or handoff. Reports belong under `reports/moment_forge/`,
   never runtime content.

## Reusable Context Fetch Pipeline

Before editing, run this retrieval pipeline:

1. Define the work surface.
   Identify the exact runtime area, doc area, or asset area being changed.
2. Pull the active authority.
   Read the matching file in `../design/` first.
3. Pull current state.
   Read `docs/ai_context/CURRENT_STATE.md` and `docs/ai_context/FILE_INDEX.md`.
4. Decide whether a task packet adds value.
   Skip it for narrow, low-risk, single-session work. Use the compact template when scope, acceptance, or deferred work needs a durable record. Expand it for high-risk, multi-session, architecture, ownership, migration, or substantial handoff work.
5. Pull validation and prompt guidance.
   Read `docs/ai_context/VALIDATION_RECIPES.md` and any matching prompt template in `docs/ai_context/prompts/`.
6. Pull adjacent context.
   Read neighboring docs, scene files, READMEs, and directly related scripts/assets.
7. Pull historical context only if still unresolved.
   Use `../python-sim/` or archived docs only to explain intent, not to override active authority.
8. Record any mismatch immediately.
   If names, paths, behavior, or ownership disagree, treat that as drift and remediate before or alongside the main change.

Minimum adjacency check:

- the file you will edit
- one upstream authority doc
- one downstream runtime or content consumer
- one neighboring doc or index that would become stale if ignored
- the relevant task packet when the work requires one
- the validation recipe and prompt template when the work matches one

## Agent Task Packets

Task packets are optional risk-control and handoff records, not mandatory ceremony.

Choose the lightest useful level:

- Skip: narrow, low-risk, single-session fixes; obvious validation; small documentation corrections.
- Compact packet: ordinary non-trivial work where scope, constraints, acceptance, or deferred work should survive the current session.
- Full packet: multi-session work; architecture or ownership changes; migrations; high-risk runtime or asset-pipeline changes; reviews producing substantial follow-up implementation.

Do not create a packet merely because a task touches several files.

Task packet workflow:

1. Select skip, compact, or full based on risk and handoff value.
2. When using a packet, copy `docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` into `docs/ai_context/task_packets/` and name it after the task.
3. Fill the compact fields first; add full-packet sections only when their information is useful.
4. Keep the packet current when scope, blockers, acceptance, or deferred work materially changes.
5. Mark it `complete` only after implementation, required documentation, feasible validation, and completion notes are done.

Task packets do not replace design docs. Use `../design/` as implementation authority, and use task packets to make the current agent slice explicit.

## Prompt Templates And Validation

Reusable prompts live in `docs/ai_context/prompts/`.

Use these agent work modes:

- Design Audit: compare active design docs, AI context, and runtime files for drift before implementation.
- Implementation: make the scoped change, update active docs, and run feasible validation.
- Review: inspect diffs for behavior regressions, determinism risks, stale paths, missing validation, and unsafe workflow assumptions.

Use these prompts to standardize recurring agent work:

- runtime feature implementation
- runtime change review
- docs-drift review
- sprite pipeline updates
- procgen handoff inspection
- combat feel tuning
- git state and commit preparation

Validation recipes live in `docs/ai_context/VALIDATION_RECIPES.md`.

Use the recipes to choose the narrowest command that proves the change. Prefer RTK subcommands for compact output when they support the command shape, such as `rtk git status`, `rtk grep ...`, and `rtk find ...`. Do not treat `rtk` as a blind prefix for arbitrary commands; use `rtk proxy <command> ...` only when RTK has no matching subcommand and token tracking is still useful. Use raw commands when RTK argument rewriting would hide or alter needed output.

When editing a design doc that will drive follow-up implementation, add or refresh a `Next Agent Slice` section with goal, files, constraints, and acceptance checks. This keeps design docs usable as executable work queues without replacing task packets.

Planned automation for these workflows is tracked in `docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`. Add scripts only when they support a listed check or update the backlog with the new rationale.

## Docs Drift Review

Treat any of the following as documentation drift:

- a path moved but indexes still point to the old location
- implementation status changed but `docs/ai_context/` was not updated
- runtime behavior changed but design/docs still describe the old behavior
- a migration created duplicate instructions with no clear primary source
- asset layout changed but submission/layout conventions were left behind

Drift review checklist:

1. Does the active design doc still describe the current implementation target?
2. Does `docs/ai_context/CURRENT_STATE.md` still describe the live state?
3. Does `docs/ai_context/FILE_INDEX.md` still point to the right entry files?
4. Does any README or local guide still route newcomers to deprecated paths?
5. Did this change create a new local authority that needs to be indexed?

## Drift Remediation Procedure

When you detect drift, do this automatically unless the user explicitly says not to:

1. Update the primary authority doc first.
2. Update `docs/ai_context/CURRENT_STATE.md` if runtime state, ownership, or workflow changed.
3. Update `docs/ai_context/CONTEXT.md` if the working model or guardrails changed.
4. Update `docs/ai_context/FILE_INDEX.md` if entry files, locations, or ownership changed.
5. Update the relevant task packet, when one exists, if scope, acceptance, status, or deferred work changed.
6. Update local routing docs such as `README.md` or folder `README.md` files if discoverability changed.
7. Note any intentionally deferred cleanup explicitly so the drift is tracked, not hidden.

## Migration Execution Instructions

Use this whenever you are restructuring docs, moving asset guidance, consolidating primers, or changing canonical paths.

1. Define the new canonical destination.
   Example: `custodian/AGENTS.md` becomes the local entrypoint for all work under `custodian/`.
2. Add the destination before deleting or de-emphasizing old routes.
3. Add prominent routing from every high-probability entrypoint.
   Typical entrypoints: repository `AGENTS.md`, local `README.md`, AI context indexes, and directory `README.md` files.
4. Migrate current state into the new destination.
   Do not create an empty shell that only links elsewhere.
5. Update the indexes and context pack.
6. Validate that old entrypoints now forward clearly to the new canonical location.
7. Leave historical docs in place unless removal is explicitly requested.

## Expected Behavior For Agents

- Ask concise clarification questions when ambiguity would risk wrong work.
- State temporary assumptions when you proceed under uncertainty.
- Keep deterministic gameplay logic separate from presentation logic.
- Do not silently promote legacy Python docs back into active authority.
- When changing behavior or architecture, update docs as part of the same task.
- Dear ImGui and Better Terrain are retired from this repository. Use the Godot `Control`-based F12 debug screen, `DebugBus`, `DebugSnapshotCollector`, and `DevObservatory`; do not reintroduce either plugin without a new active design decision.
- Debug surfaces must consume read-only snapshots from `DebugBus`. Mutation must go through debug overrides or queued commands that gameplay systems drain at safe boundaries, never direct per-frame UI writes into deterministic systems.
- New debug instrumentation should route through `DevObservatory` (`/root/DevObservatory`), not raw `print()` or ad-hoc labels. Use `log_event` for state transitions, `increment`/`set_counter` for counts, `set_gauge` for live values, and `mark_warning` for anomalies. Keep it observability-only — never let observatory state influence simulation, generation, AI, collision, navigation, combat, or saves. See `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md` for the full pattern and examples.

## Design Codex Governance

`../design/90_codex/` is the project's idea inventory and design memory layer.

Use it for:

- preserving wanted features
- comparing future-system candidates
- maintaining long-term design continuity
- deciding what should graduate next

Do not treat codex cards as active implementation authority. Before building from a codex card, graduate the idea into the active design authority under `../design/02_features/`, `../design/04_architecture/`, or another appropriate active design location.

Codex tracker:

- `../design/90_codex/TRACKER.md`

Codex validation:

```bash
python tools/validate_design_codex.py
```

Optional local hook install from repository root:

```bash
bash tools/install_git_hooks.sh
```

When touching `../design/90_codex/`, agents should:

1. update `../design/90_codex/00_index.md`
2. update `../design/90_codex/TRACKER.md` when governance, status semantics, or graduation rules change
3. run `python tools/validate_design_codex.py`
4. avoid implementing directly from codex cards unless explicitly instructed
5. add active-spec/runtime links when a codex card graduates

## Migration Shortcut

If the task is “where do I start?” or “what do I read first?”, the answer for `custodian/` work is:

1. `custodian/AGENTS.md`
2. `custodian/docs/ai_context/CURRENT_STATE.md`
3. the relevant file in `design/`

## Agentmemory Note

- Check worker health with `agentmemory status`; if it is not running, start it with `agentmemory` and verify status again.
- Use agentmemory when durable cross-session context, recurring decisions, or handoff continuity would be helpful. It supplements rather than replaces `design/`, `docs/ai_context/`, task packets, and live runtime inspection.
- Start the worker service before running `agentmemory demo`.
- `agentmemory demo` is a smoke test for a live worker on `http://localhost:3111`.
- The demo prints a cleanup command for `/tmp/agentmemory-demo` sessions when it finishes.
</file>

<file path="custodian/scenes/game.tscn">
[gd_scene format=3 uid="uid://c0x7mhq5n2kd8"]

[ext_resource type="Script" uid="uid://c4e4i6nkboriy" path="res://game/systems/core/systems/simulation.gd" id="1_simulation"]
[ext_resource type="PackedScene" uid="uid://d3xbaxlif3364" path="res://game/actors/operator/operator.tscn" id="2_operator"]
[ext_resource type="Script" uid="uid://cyoadqv7g5hc6" path="res://game/world/camera.gd" id="3_camera"]
[ext_resource type="PackedScene" path="res://game/actors/sector/sector.tscn" id="4_sector"]
[ext_resource type="Script" uid="uid://dv1vtc24ktkdi" path="res://game/systems/core/systems/combat.gd" id="5_combat"]
[ext_resource type="PackedScene" uid="uid://dgtvm5ncnayht" path="res://game/actors/enemies/enemy.tscn" id="6_enemy"]
[ext_resource type="Script" uid="uid://bmm250f700v61" path="res://game/systems/core/systems/power.gd" id="7_power"]
[ext_resource type="Script" uid="uid://b8du6y5b0ppbh" path="res://game/ui/hud/ui.gd" id="8_ui"]
[ext_resource type="Script" uid="uid://bewgosi1uu3qj" path="res://game/ui/hud/pause_ui.gd" id="9_pause"]
[ext_resource type="PackedScene" path="res://game/actors/items/ammo_cache.tscn" id="10_cache"]
[ext_resource type="Script" uid="uid://citwrr55dyx86" path="res://game/systems/core/systems/spawn_node.gd" id="13_spawn_node"]
[ext_resource type="Script" uid="uid://bvwvd7qwsk7tk" path="res://game/systems/core/systems/wave_manager.gd" id="14_wave_manager"]
[ext_resource type="Script" uid="uid://cwmil77ydatus" path="res://game/systems/core/systems/enemy_director.gd" id="15_enemy_director"]
[ext_resource type="PackedScene" path="res://game/actors/enemies/fast_drone.tscn" id="16_fast_enemy"]
[ext_resource type="PackedScene" path="res://game/actors/enemies/heavy_drone.tscn" id="17_heavy_enemy"]
[ext_resource type="PackedScene" path="res://game/actors/enemies/enemy_grunt.tscn" id="18_grunt_enemy"]
[ext_resource type="PackedScene" path="res://game/actors/enemies/enemy_marine.tscn" id="18_marine_enemy"]
[ext_resource type="PackedScene" path="res://game/actors/enemies/enemy_savage.tscn" id="18_savage_enemy"]
[ext_resource type="PackedScene" uid="uid://chxttfh575v5i" path="res://game/actors/sector/turret_gunner.tscn" id="19_turret_gunner"]
[ext_resource type="PackedScene" path="res://game/actors/sector/turret_blaster.tscn" id="20_turret_blaster"]
[ext_resource type="PackedScene" path="res://game/actors/sector/turret_repeater.tscn" id="21_turret_repeater"]
[ext_resource type="PackedScene" path="res://game/actors/sector/turret_sniper.tscn" id="22_turret_sniper"]
[ext_resource type="Script" uid="uid://bv666t3wt6ofa" path="res://game/actors/sector/power_node.gd" id="24_power_node"]
[ext_resource type="Script" uid="uid://c1cs5ipx8lxnp" path="res://game/systems/core/systems/supply_drop_manager.gd" id="25_supply_drop"]
[ext_resource type="PackedScene" uid="uid://lp5kk4al1nnv" path="res://game/world/procgen/custodian_contract_map.tscn" id="26_contract_map"]
[ext_resource type="PackedScene" uid="uid://dqle6bbgblr2o" path="res://game/actors/terminal/command_terminal.tscn" id="27_command_terminal"]
[ext_resource type="Script" uid="uid://bvqagq17ro1u6" path="res://game/systems/core/systems/contract_world_loader.gd" id="28_contract_loader"]
[ext_resource type="Script" uid="uid://xjdny30dgrp6" path="res://content/tiles/debug/debug_controller.gd" id="29_debug_controller"]
[ext_resource type="PackedScene" path="res://content/tiles/debug/dev_ui.tscn" id="30_dev_ui"]
[ext_resource type="Script" uid="uid://cg1kmf7hdh3s2" path="res://content/tiles/debug/debug_draw.gd" id="31_debug_draw"]
[ext_resource type="Script" uid="uid://jp87rnpxqgdt" path="res://content/tiles/debug/inspector_probe.gd" id="32_inspector_probe"]
[ext_resource type="Script" uid="uid://xj0cr1hc5c46" path="res://content/tiles/debug/debug_collector.gd" id="33_debug_collector"]
[ext_resource type="Script" uid="uid://bi11w51uaudmj" path="res://game/systems/core/systems/ambient_critter_manager.gd" id="34_ambient_critters"]
[ext_resource type="PackedScene" uid="uid://dn7go36qvrw6x" path="res://game/actors/enemies/ambient_shrumb.tscn" id="35_ambient_shrumb"]
[ext_resource type="Script" uid="uid://by380p21nbchx" path="res://game/actors/ui/terminal_background.gd" id="36_terminal_background"]
[ext_resource type="Script" uid="uid://bg78eihw40m6g" path="res://game/systems/core/systems/navigation_system.gd" id="40_navigation"]
[ext_resource type="Script" uid="uid://din0buhray3ph" path="res://content/tiles/debug/navigation_debug.gd" id="41_nav_debug"]
[ext_resource type="Script" uid="uid://bqt6lkdd6nniw" path="res://game/systems/core/player_controller.gd" id="42_player_controller"]
[ext_resource type="PackedScene" uid="uid://b2nvudqe2mljd" path="res://game/actors/vehicles/light_buggy.tscn" id="43_light_buggy"]
[ext_resource type="PackedScene" path="res://game/systems/core/systems/wall_build_system.tscn" id="99_wall_build_system"]
[ext_resource type="PackedScene" path="res://game/systems/core/systems/wall_placer.tscn" id="99_wall_placer"]
[ext_resource type="Script" uid="uid://cm60nou56jgt7" path="res://game/systems/core/systems/weapon_definition_factory.gd" id="99_weapon_factory"]
[ext_resource type="Script" uid="uid://bxpa63ls5ihkq" path="res://game/systems/core/systems/turret_placement.gd" id="100_turret_placement"]
[ext_resource type="Texture2D" uid="uid://6y4pj114mk8m" path="res://content/sprites/misc/crosshair_64x64.png" id="101_crosshair"]
[ext_resource type="Script" uid="uid://brs7i5frcn2w5" path="res://game/systems/core/systems/terminal_deployment.gd" id="101_terminal_deployment"]
[ext_resource type="PackedScene" path="res://game/ui/hud/components/ranged_reticle.tscn" id="102_ranged_reticle"]
[ext_resource type="PackedScene" path="res://game/ui/minimap/minimap_panel.tscn" id="200_minimap"]
[ext_resource type="PackedScene" path="res://game/ui/inventory/inventory_ui.tscn" id="201_inventory_ui"]
[ext_resource type="Script" uid="uid://brku67e23m54l" path="res://game/systems/drone/drone_manager.gd" id="206_drone_manager"]
[ext_resource type="Script" path="res://game/systems/spawning/ambient_enemy_spawner.gd" id="207_ambient_spawner"]
[ext_resource type="PackedScene" path="res://scenes/debug/dev_observatory_overlay.tscn" id="208_observatory_overlay"]
[ext_resource type="PackedScene" path="res://game/actors/allies/allied_infantry_droid.tscn" id="209_allied_droid"]
[ext_resource type="Script" path="res://game/world/lighting/world_lighting_director.gd" id="210_lighting_director"]
[ext_resource type="Resource" path="res://content/lighting/profiles/sundered_keep_exterior.tres" id="211_lighting_profile"]
[ext_resource type="PackedScene" path="res://game/world/lighting/world_atmosphere_2d.tscn" id="212_world_atmosphere"]
[ext_resource type="PackedScene" path="res://game/world/lighting/light_rig_2d.tscn" id="213_light_rig"]
[ext_resource type="PackedScene" path="res://game/infrastructure/structures/field_fabricator_mk1.tscn" id="214_field_fabricator"]
[ext_resource type="Script" path="res://game/world/levels/level_loader.gd" id="215_level_loader"]
[ext_resource type="Script" path="res://game/world/routes/route_traversal_manager.gd" id="216_route_manager"]

[node name="GameRoot" type="Node2D" unique_id=593578645]
metadata/_edit_vertical_guides_ = [-1047.0]

[node name="DebugController" type="Node" parent="." unique_id=744681739]
script = ExtResource("29_debug_controller")

[node name="DebugCollector" type="Node" parent="." unique_id=599804427]
script = ExtResource("33_debug_collector")

[node name="DevUI" parent="." unique_id=227687621 instance=ExtResource("30_dev_ui")]

[node name="DevObservatoryOverlay" parent="." unique_id=1030058335 instance=ExtResource("208_observatory_overlay")]

[node name="World" type="Node2D" parent="." unique_id=932635855]

[node name="LevelLoader" type="Node" parent="World"]
script = ExtResource("215_level_loader")

[node name="RouteTraversalManager" type="Node" parent="World"]
script = ExtResource("216_route_manager")

[node name="CanvasModulate" type="CanvasModulate" parent="World"]
color = Color(0.23, 0.25, 0.29, 1)

[node name="DirectionalLight2D" type="DirectionalLight2D" parent="World"]
rotation_degrees = -32.0
color = Color(0.78, 0.84, 0.96, 1)
energy = 0.55

[node name="WorldLightingDirector" type="Node2D" parent="World"]
script = ExtResource("210_lighting_director")
canvas_modulate_path = NodePath("../CanvasModulate")
directional_light_path = NodePath("../DirectionalLight2D")
default_profile = ExtResource("211_lighting_profile")

[node name="DebugDraw" type="Node2D" parent="World" unique_id=1320630577 groups=["world_origin_branch"]]
script = ExtResource("31_debug_draw")

[node name="InspectorProbe" type="Node2D" parent="World" unique_id=1619477561 groups=["world_origin_branch"]]
script = ExtResource("32_inspector_probe")

[node name="NavigationDebug" type="Node2D" parent="World" unique_id=1619477562 groups=["world_origin_branch"]]
script = ExtResource("41_nav_debug")

[node name="Sectors" type="Node2D" parent="World" unique_id=800988395 groups=["world_origin_branch"]]

[node name="NORTH_TRANSIT" parent="World/Sectors" unique_id=1229477064 instance=ExtResource("4_sector")]
position = Vector2(-312, -480)
sector_name = "NORTH TRANSIT"
sector_type = "TRANSIT"
size_tiles = Vector2i(24, 16)
door_sides = PackedStringArray("W", "E")

[node name="POWER" parent="World/Sectors" unique_id=305107457 instance=ExtResource("4_sector")]
position = Vector2(1728, -890)
script = ExtResource("24_power_node")
node_name = "Power Node"
power_output = 120.0
sector_name = "POWER"
sector_type = "POWER"
size_tiles = Vector2i(28, 26)
door_sides = PackedStringArray("W", "S")

[node name="PowerNodeLightRig" parent="World/Sectors/POWER" instance=ExtResource("213_light_rig")]
position = Vector2(0, -18)
light_color = Color(0.96, 0.7, 0.3, 1)
energy = 1.15
pulse_enabled = true
pulse_speed = 2.1
pulse_amount = 0.12
glow_scale = 1.55

[node name="DEFENSE" parent="World/Sectors" unique_id=1371060751 instance=ExtResource("4_sector")]
position = Vector2(1800, 312)
sector_name = "DEFENSE"
sector_type = "DEFENSE"
size_tiles = Vector2i(30, 28)
door_sides = PackedStringArray("N", "W")

[node name="TurretGunner" parent="World/Sectors/DEFENSE" unique_id=1973721001 instance=ExtResource("19_turret_gunner")]
position = Vector2(100, -36)

[node name="TurretBlaster" parent="World/Sectors/DEFENSE" unique_id=1973721002 instance=ExtResource("20_turret_blaster")]
position = Vector2(-120, 24)

[node name="TurretBlaster2" parent="World/Sectors/DEFENSE" unique_id=247143122 instance=ExtResource("20_turret_blaster")]
position = Vector2(-180, -72)

[node name="TurretRepeater" parent="World/Sectors/DEFENSE" unique_id=1973721003 instance=ExtResource("21_turret_repeater")]
position = Vector2(40, 132)

[node name="TurretSniper" parent="World/Sectors/DEFENSE" unique_id=1973721004 instance=ExtResource("22_turret_sniper")]
position = Vector2(-42, -156)

[node name="ARCHIVE" parent="World/Sectors" unique_id=1258512870 instance=ExtResource("4_sector")]
position = Vector2(-1200, -480)
sector_name = "ARCHIVE"
sector_type = "ARCHIVE"
size_tiles = Vector2i(30, 28)
door_sides = PackedStringArray("E")

[node name="STORAGE" parent="World/Sectors" unique_id=1668407586 instance=ExtResource("4_sector")]
position = Vector2(-312, 288)
sector_name = "STORAGE"
sector_type = "STORAGE"
size_tiles = Vector2i(28, 24)
door_sides = PackedStringArray("N", "E")

[node name="SOUTH_TRANSIT" parent="World/Sectors" unique_id=2063248664 instance=ExtResource("4_sector")]
position = Vector2(720, 288)
sector_name = "SOUTH TRANSIT"
sector_type = "TRANSIT"
size_tiles = Vector2i(24, 16)
door_sides = PackedStringArray("N", "W")

[node name="Enemies" type="Node2D" parent="World" unique_id=1365669343 groups=["world_origin_branch"]]

[node name="SpawnNodes" type="Node2D" parent="World" unique_id=1079383596 groups=["world_origin_branch"]]

[node name="NorthSpawn" type="Node2D" parent="World/SpawnNodes" unique_id=594161002]
position = Vector2(700, -980)
script = ExtResource("13_spawn_node")
lane = "north"

[node name="EastSpawn" type="Node2D" parent="World/SpawnNodes" unique_id=1197471513]
position = Vector2(2220, -220)
script = ExtResource("13_spawn_node")
lane = "east"

[node name="SouthSpawn" type="Node2D" parent="World/SpawnNodes" unique_id=223677011]
position = Vector2(700, 760)
script = ExtResource("13_spawn_node")
lane = "south"

[node name="WestSpawn" type="Node2D" parent="World/SpawnNodes" unique_id=1311720741]
position = Vector2(-1620, -120)
script = ExtResource("13_spawn_node")
lane = "west"

[node name="Projectiles" type="Node2D" parent="World" unique_id=1418877711 groups=["world_origin_branch"]]

[node name="Allies" type="Node2D" parent="World" unique_id=1418877712 groups=["world_origin_branch"]]

[node name="Items" type="Node2D" parent="World" unique_id=1390419870 groups=["world_origin_branch"]]

[node name="AmmoCacheA" parent="World/Items" unique_id=1977245667 instance=ExtResource("10_cache")]
position = Vector2(-920, -520)
standard_ammo = 8

[node name="AmmoCacheB" parent="World/Items" unique_id=892279798 instance=ExtResource("10_cache")]
position = Vector2(420, 300)
standard_ammo = 8
heavy_ammo = 2

[node name="AmmoCacheC" parent="World/Items" unique_id=228248645 instance=ExtResource("10_cache")]
position = Vector2(1600, -140)
standard_ammo = 12
heavy_ammo = 2

[node name="AmmoCacheD" parent="World/Items" unique_id=655756500 instance=ExtResource("10_cache")]
position = Vector2(40, -520)

[node name="ContractMap" parent="World" unique_id=1103719919 groups=["world_origin_branch"] instance=ExtResource("26_contract_map")]
visible = false

[node name="Operator" parent="World" unique_id=2047803984 instance=ExtResource("2_operator")]
position = Vector2(717.45905, -485.33954)
muzzle_offset = 24.0
aim_crosshair_color = Color(0.9, 0.9, 0.9, 1)
ammo_standard = 48
ammo_heavy = 12
ammo_standard_max = 72
ammo_heavy_max = 16
interaction_range = 84.0
repair_rate = 15.0
sprint_multiplier = 1.7
stamina_max = 100.0
stamina_drain_per_second = 32.0
stamina_regen_per_second = 22.0
stamina_sprint_gate = 10.0
move_acceleration = 1200.0
move_deceleration = 1500.0
movement_turn_response = 14.0
heavy_attack_stamina_cost = 14.0
heavy_attack_blocked_while_sprinting = true
block_move_multiplier = 0.6
block_stamina_cost_per_hit = 12.0
combat_target_range = 360.0
use_tiny_rpg_placeholder_soldier = true
idle_main_sheet_path = "res://content/sprites/operator/runtime/idle/operator_idle_main.png"
ranged_2h_stance_sheet_path = "res://content/sprites/operator/runtime/body/ranged_2h/operator__body__ranged__stance_01__e__12f__96.png"
ranged_2h_aim_sheet_path = "res://content/sprites/operator/runtime/body/ranged_2h/operator_body_ranged_2h_aim_raise.png"
idle_long_loop_threshold = 20
placeholder_sprite_position = Vector2(0, -18)
placeholder_sprite_offset = Vector2(0, 0)
right_hand_socket_position = Vector2(10, -16)
left_hand_socket_position = Vector2(12, -28)
primary_weapon_socket_position = Vector2(12, -28)
primary_weapon_sprite_position = Vector2(0, 0)
primary_weapon_sprite_scale = Vector2(1, 1)
primary_weapon_muzzle_socket_position = Vector2(20, 2)
placeholder_collision_offset = Vector2(0, 12)
placeholder_collision_radius = 7.0
placeholder_collision_height = 22.0
placeholder_melee_hitbox_radius = 22.0
placeholder_healthbar_top = -54.0
placeholder_healthbar_bottom = -48.0

[node name="PlayerController" type="Node" parent="World" unique_id=2047803985]
script = ExtResource("42_player_controller")
operator_path = NodePath("../Operator")

[node name="LightBuggy" parent="World" unique_id=2047803986 groups=["world_origin_branch"] instance=ExtResource("43_light_buggy")]
position = Vector2(872, -486)

[node name="WallPlacer" parent="World" unique_id=1022301411 groups=["world_origin_branch"] instance=ExtResource("99_wall_placer")]

[node name="WallBuildSystem" parent="World" unique_id=1989965356 groups=["world_origin_branch"] instance=ExtResource("99_wall_build_system")]

[node name="TurretPlacement" type="Node" parent="World" unique_id=1022301412 groups=["world_origin_branch"]]
script = ExtResource("100_turret_placement")

[node name="TerminalDeployment" type="Node" parent="World" unique_id=1022301413 groups=["world_origin_branch"]]
script = ExtResource("101_terminal_deployment")

[node name="DroneManager" type="Node" parent="World" unique_id=1022301414 groups=["world_origin_branch"]]
script = ExtResource("206_drone_manager")
drone_scene = ExtResource("209_allied_droid")

[node name="CommandTerminal" parent="World" unique_id=2021499921 groups=["world_origin_branch"] instance=ExtResource("27_command_terminal")]
position = Vector2(804, -492)

[node name="FieldFabricatorMk1" parent="World" groups=["world_origin_branch"] instance=ExtResource("214_field_fabricator")]
position = Vector2(1120, -480)

[node name="Camera2D" type="Camera2D" parent="World" unique_id=1332183342]
position = Vector2(720, -480)
script = ExtResource("3_camera")

[node name="WorldAtmosphere2D" parent="." instance=ExtResource("212_world_atmosphere")]

[node name="Simulation" type="Node" parent="." unique_id=262550242]
script = ExtResource("1_simulation")

[node name="Combat" type="Node" parent="." unique_id=780370146]
script = ExtResource("5_combat")

[node name="Power" type="Node" parent="." unique_id=986267273]
script = ExtResource("7_power")

[node name="WaveManager" type="Node" parent="." unique_id=987111452]
script = ExtResource("14_wave_manager")
wave_interval = 25.0
initial_delay = 4.0
drone_scene = ExtResource("6_enemy")
fast_drone_scene = ExtResource("16_fast_enemy")
heavy_drone_scene = ExtResource("17_heavy_enemy")
grunt_scene = ExtResource("18_grunt_enemy")
marine_scene = ExtResource("18_marine_enemy")
savage_scene = ExtResource("18_savage_enemy")
debug_spawn_grunt_on_start = true

[node name="EnemyDirector" type="Node" parent="." unique_id=987111453]
script = ExtResource("15_enemy_director")

[node name="NavigationSystem" type="Node" parent="." unique_id=987111455]
script = ExtResource("40_navigation")

[node name="WeaponDefinitionFactory" type="Node" parent="." unique_id=987111456]
script = ExtResource("99_weapon_factory")

[node name="SupplyDropManager" type="Node" parent="." unique_id=987111454]
script = ExtResource("25_supply_drop")
drop_interval = 35.0
initial_delay = 25.0

[node name="ContractWorldLoader" type="Node" parent="." unique_id=1201129447]
script = ExtResource("28_contract_loader")

[node name="AmbientEnemySpawner" type="Node" parent="."]
script = ExtResource("207_ambient_spawner")
enemy_scene = ExtResource("18_grunt_enemy")
max_generated_camps = 1
max_active_ambient_enemies = 2
enemies_per_camp_min = 2
enemies_per_camp_max = 2

[node name="AmbientCritterManager" type="Node" parent="." unique_id=292901155]
script = ExtResource("34_ambient_critters")
critter_scene = ExtResource("35_ambient_shrumb")
min_distance_from_spawn_tiles = 10

[node name="UI" type="CanvasLayer" parent="." unique_id=2053415447]
layer = 20
script = ExtResource("8_ui")
terminal_contract_node_path = NodePath("../World/ContractMap")

[node name="Minimap" parent="UI" unique_id=999000001 instance=ExtResource("200_minimap")]

[node name="PowerDisplay" type="Panel" parent="UI" unique_id=449160537]
offset_left = 360.0
offset_top = 20.0
offset_right = 770.0
offset_bottom = 60.0

[node name="Label" type="Label" parent="UI/PowerDisplay" unique_id=1591291188]
layout_mode = 0
offset_left = 10.0
offset_top = 5.0
offset_right = 400.0
offset_bottom = 35.0
text = "POWER: 500/500"

[node name="PowerBar" type="ProgressBar" parent="UI/PowerDisplay" unique_id=1933106435]
layout_mode = 0
offset_left = 10.0
offset_top = 20.0
offset_right = 400.0
offset_bottom = 32.0
value = 100.0
show_percentage = false

[node name="ContractPhaseLabel" type="Label" parent="UI" unique_id=934551200]
offset_left = 20.0
offset_top = 68.0
offset_right = 340.0
offset_bottom = 92.0
text = "CONTRACT PHASE: BRIEFING"

[node name="LivesLabel" type="Label" parent="UI" unique_id=1512345678]
offset_left = 20.0
offset_top = 44.0
offset_right = 260.0
offset_bottom = 68.0
text = "HEALTH: 100/100"

[node name="FieldPatchPrompt" type="Label" parent="UI"]
visible = false
offset_left = 20.0
offset_top = 68.0
offset_right = 300.0
offset_bottom = 92.0
text = "+ FIELD PATCH READY [P]"

[node name="CameraFollowLabel" type="Label" parent="UI" unique_id=170044321]
offset_left = 20.0
offset_top = 96.0
offset_right = 300.0
offset_bottom = 120.0
text = "CAMERA: TRACKING (C)"

[node name="CameraZoomLabel" type="Label" parent="UI" unique_id=771662881]
offset_left = 20.0
offset_top = 120.0
offset_right = 300.0
offset_bottom = 144.0
text = "ZOOM: AUTO (Z)"

[node name="TimeScaleLabel" type="Label" parent="UI" unique_id=177033776]
offset_left = 20.0
offset_top = 144.0
offset_right = 320.0
offset_bottom = 168.0
text = "TIME SCALE: 1.0X (Y)"

[node name="AimModeLabel" type="Label" parent="UI" unique_id=177033777]
offset_left = 20.0
offset_top = 168.0
offset_right = 360.0
offset_bottom = 192.0
text = "AIM: MOUSE (V TOGGLE, ARROWS)"

[node name="WeaponLabel" type="Label" parent="UI" unique_id=179173991]
offset_left = 20.0
offset_top = 192.0
offset_right = 520.0
offset_bottom = 216.0
text = "LOADOUT: HOLSTERED (Q RANGED, E MELEE) | ATTACK: F/M1 | BLOCK: R/M2 | RELOAD: X"

[node name="PrimaryWeaponButton" type="Button" parent="UI" unique_id=179173992]
offset_left = 20.0
offset_top = 216.0
offset_right = 180.0
offset_bottom = 244.0
text = "EQUIP CARBINE"

[node name="AmmoLabel" type="Label" parent="UI" unique_id=1735120534]
offset_left = 20.0
offset_top = 68.0
offset_right = 300.0
offset_bottom = 92.0
text = "CARBINE  MAG 0/0  RES 0"

[node name="CooldownBar" type="ProgressBar" parent="UI" unique_id=129306331]
offset_left = 20.0
offset_top = 274.0
offset_right = 260.0
offset_bottom = 290.0
show_percentage = false

[node name="CooldownLabel" type="Label" parent="UI" unique_id=105988336]
offset_left = 268.0
offset_top = 270.0
offset_right = 420.0
offset_bottom = 294.0
text = "COOLDOWN: READY"

[node name="StaminaBar" type="ProgressBar" parent="UI" unique_id=120306331]
offset_left = 20.0
offset_top = 34.0
offset_right = 260.0
offset_bottom = 42.0
value = 100.0
show_percentage = false

[node name="StaminaLabel" type="Label" parent="UI" unique_id=120988336]
offset_left = 20.0
offset_top = 14.0
offset_right = 300.0
offset_bottom = 34.0
text = "STAMINA: 100% (JOG, CTRL)"

[node name="DirectorLabel" type="Label" parent="UI" unique_id=120988337]
offset_left = 20.0
offset_top = 318.0
offset_right = 640.0
offset_bottom = 342.0
text = "DIRECTOR W0 | TH 0.0 | NONE | NONE"

[node name="SupplyDropLabel" type="Label" parent="UI" unique_id=120988338]
offset_left = 20.0
offset_top = 342.0
offset_right = 360.0
offset_bottom = 366.0
text = "SUPPLY DROP: --"

[node name="Crosshair" type="TextureRect" parent="UI" unique_id=111706062]
offset_left = 640.0
offset_top = 360.0
offset_right = 704.0
offset_bottom = 424.0
texture = ExtResource("101_crosshair")

[node name="RangedReticle" parent="UI" instance=ExtResource("102_ranged_reticle")]

[node name="InteractionLabel" type="Label" parent="UI" unique_id=466777138]
modulate = Color(0.86, 0.93, 0.9, 0.82)
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -280.0
offset_top = 112.0
offset_right = 280.0
offset_bottom = 140.0
horizontal_alignment = 1

[node name="TerminalPanel" type="Panel" parent="UI" unique_id=760134112]
visible = false
z_index = 10
offset_left = 32.0
offset_top = 32.0
offset_right = 1248.0
offset_bottom = 688.0

[node name="Header" type="Panel" parent="UI/TerminalPanel" unique_id=1714410557]
layout_mode = 0
offset_left = 8.0
offset_top = 8.0
offset_right = 1214.0
offset_bottom = 56.0

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Header"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 5.0
offset_right = -10.0
offset_bottom = -5.0
grow_horizontal = 2
grow_vertical = 2

[node name="HeaderRow" type="HBoxContainer" parent="UI/TerminalPanel/Header/Margin"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="Eyebrow" type="Label" parent="UI/TerminalPanel/Header/Margin/HeaderRow" unique_id=1814410557]
custom_minimum_size = Vector2(172, 0)
layout_mode = 2
text = "CUSTODIAN NODE"
vertical_alignment = 1

[node name="Title" type="Label" parent="UI/TerminalPanel/Header/Margin/HeaderRow" unique_id=103289056]
custom_minimum_size = Vector2(148, 0)
layout_mode = 2
size_flags_horizontal = 3
text = "OVERVIEW"
vertical_alignment = 1

[node name="StatusChips" type="HBoxContainer" parent="UI/TerminalPanel/Header/Margin/HeaderRow"]
layout_mode = 2
theme_override_constants/separation = 5

[node name="TimeChip" type="Label" parent="UI/TerminalPanel/Header/Margin/HeaderRow/StatusChips"]
custom_minimum_size = Vector2(82, 0)
layout_mode = 2
text = "T:--:--"
horizontal_alignment = 1
vertical_alignment = 1

[node name="ThreatChip" type="Label" parent="UI/TerminalPanel/Header/Margin/HeaderRow/StatusChips"]
custom_minimum_size = Vector2(112, 0)
layout_mode = 2
text = "THREAT:STABLE"
horizontal_alignment = 1
vertical_alignment = 1

[node name="PhaseChip" type="Label" parent="UI/TerminalPanel/Header/Margin/HeaderRow/StatusChips"]
custom_minimum_size = Vector2(154, 0)
layout_mode = 2
text = "PHASE:FREE ROAM"
horizontal_alignment = 1
vertical_alignment = 1

[node name="GridChip" type="Label" parent="UI/TerminalPanel/Header/Margin/HeaderRow/StatusChips"]
custom_minimum_size = Vector2(128, 0)
layout_mode = 2
text = "GRID:STABLE"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Body" type="HBoxContainer" parent="UI/TerminalPanel" unique_id=1510856963]
layout_mode = 0
offset_left = 8.0
offset_top = 72.0
offset_right = 1214.0
offset_bottom = 612.0
theme_override_constants/separation = 10

[node name="NavRail" type="VBoxContainer" parent="UI/TerminalPanel/Body" unique_id=-2137803084]
custom_minimum_size = Vector2(204, 0)
layout_mode = 2
theme_override_constants/separation = 8

[node name="NavTitle" type="Label" parent="UI/TerminalPanel/Body/NavRail" unique_id=-2137803083]
layout_mode = 2
text = "PAGES"

[node name="PageButtonsScroll" type="ScrollContainer" parent="UI/TerminalPanel/Body/NavRail"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
mouse_filter = 0
horizontal_scroll_mode = 0
vertical_scroll_mode = 1

[node name="PageButtons" type="VBoxContainer" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll" unique_id=-2137803082]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4

[node name="OverviewButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803081]
layout_mode = 2
text = "OVERVIEW"

[node name="StatusButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803080]
layout_mode = 2
text = "STATUS"

[node name="SectorsButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803079]
layout_mode = 2
text = "SECTORS"

[node name="PowerButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803078]
layout_mode = 2
text = "POWER"

[node name="DefenseButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803077]
layout_mode = 2
text = "DEFENSE"

[node name="SensorsButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803076]
layout_mode = 2
text = "SENSORS"

[node name="IncidentsButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803075]
layout_mode = 2
text = "INCIDENTS"

[node name="ArchiveButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803074]
layout_mode = 2
text = "ARCHIVE"

[node name="ReconButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803073]
layout_mode = 2
text = "RECON"

[node name="ContractsButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803072]
layout_mode = 2
text = "CONTRACTS"

[node name="HistoryButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803071]
layout_mode = 2
text = "HISTORY"

[node name="SettingsButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons" unique_id=-2137803070]
layout_mode = 2
text = "SETTINGS"

[node name="MoreButton" type="Button" parent="UI/TerminalPanel/Body/NavRail"]
custom_minimum_size = Vector2(0, 22)
layout_mode = 2
focus_mode = 2
text = "MORE / SYSTEMS"

[node name="ContextSpacer" type="Control" parent="UI/TerminalPanel/Body/NavRail" unique_id=-2137803069]
custom_minimum_size = Vector2(0, 12)
layout_mode = 2

[node name="ActionTitle" type="Label" parent="UI/TerminalPanel/Body/NavRail" unique_id=-2137803068]
layout_mode = 2
text = "ACTIONS"

[node name="ActionButtons" type="VBoxContainer" parent="UI/TerminalPanel/Body/NavRail" unique_id=-2137803067]
layout_mode = 2
theme_override_constants/separation = 4

[node name="WaitButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/ActionButtons" unique_id=-2137803066]
layout_mode = 2
text = "WAIT"

[node name="Wait10xButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/ActionButtons" unique_id=-2137803062]
layout_mode = 2
text = "WAIT 10X"

[node name="FocusButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/ActionButtons" unique_id=-2137803065]
layout_mode = 2
text = "FOCUS"

[node name="HardenButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/ActionButtons" unique_id=-2137803064]
layout_mode = 2
text = "HARDEN"

[node name="ResetButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/ActionButtons" unique_id=-2137803061]
layout_mode = 2
text = "RESET"

[node name="RebootButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/ActionButtons" unique_id=-2137803060]
layout_mode = 2
text = "REBOOT"

[node name="HelpButton" type="Button" parent="UI/TerminalPanel/Body/NavRail/ActionButtons" unique_id=-2137803063]
layout_mode = 2
text = "HELP"

[node name="MapColumn" type="VBoxContainer" parent="UI/TerminalPanel/Body" unique_id=1561351348]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="MapTitle" type="Label" parent="UI/TerminalPanel/Body/MapColumn" unique_id=492283667]
layout_mode = 2
text = "OVERVIEW"

[node name="PageSummary" type="Label" parent="UI/TerminalPanel/Body/MapColumn" unique_id=492283668]
layout_mode = 2
text = "TACTICAL SUMMARY // LIVE CONTRACT SNAPSHOT"
autowrap_mode = 3

[node name="PlanetPreviewTitle" type="Label" parent="UI/TerminalPanel/Body/MapColumn" unique_id=1034419010]
layout_mode = 2
text = "CONTRACTED GLOBE"

[node name="PlanetPreview" type="TextureRect" parent="UI/TerminalPanel/Body/MapColumn" unique_id=111001529]
custom_minimum_size = Vector2(0, 144)
layout_mode = 2
expand_mode = 1
stretch_mode = 5

[node name="MapPreviewTitle" type="Label" parent="UI/TerminalPanel/Body/MapColumn" unique_id=1250833323]
layout_mode = 2
text = "TACTICAL MINIMAP"

[node name="MapPreview" parent="UI/TerminalPanel/Body/MapColumn" unique_id=1591864208 instance=ExtResource("200_minimap")]
custom_minimum_size = Vector2(0, 220)
layout_mode = 2
mouse_filter = 0
enable_expand_toggle = false

[node name="WidgetStack" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn" unique_id=-2137803059]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="OverviewWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137803058]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="OverviewTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets" unique_id=-2137803057]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="OverviewOperationalPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow" unique_id=-2137803056]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.5

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewOperationalPanel" unique_id=-2137803055]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewOperationalPanel/Margin" unique_id=-2137803054]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewOperationalPanel/Margin/Content" unique_id=-2137803053]
layout_mode = 2
text = "OPERATIONAL SUMMARY"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewOperationalPanel/Margin/Content" unique_id=-2137803052]
custom_minimum_size = Vector2(0, 84)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="OverviewPowerPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow" unique_id=-2137803051]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewPowerPanel" unique_id=-2137803050]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewPowerPanel/Margin" unique_id=-2137803049]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewPowerPanel/Margin/Content" unique_id=-2137803048]
layout_mode = 2
text = "POWER SUMMARY"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewPowerPanel/Margin/Content" unique_id=-2137803047]
custom_minimum_size = Vector2(0, 84)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="OverviewAssaultPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow" unique_id=-2137803046]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewAssaultPanel" unique_id=-2137803045]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewAssaultPanel/Margin" unique_id=-2137803044]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewAssaultPanel/Margin/Content" unique_id=-2137803043]
layout_mode = 2
text = "ASSAULT SUMMARY"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewAssaultPanel/Margin/Content" unique_id=-2137803042]
custom_minimum_size = Vector2(0, 84)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="OverviewMapSlot" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4

[node name="OverviewBottomRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets" unique_id=-2137803041]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="OverviewPriorityPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow" unique_id=-2137803040]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewPriorityPanel" unique_id=-2137803039]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewPriorityPanel/Margin" unique_id=-2137803038]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewPriorityPanel/Margin/Content" unique_id=-2137803037]
layout_mode = 2
text = "PRIORITY SECTORS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewPriorityPanel/Margin/Content" unique_id=-2137803036]
custom_minimum_size = Vector2(0, 72)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="OverviewIncidentPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewIncidentPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewIncidentPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewIncidentPanel/Margin/Content"]
layout_mode = 2
text = "ACTIVE INCIDENTS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewIncidentPanel/Margin/Content"]
custom_minimum_size = Vector2(0, 58)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="OverviewContractPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow" unique_id=-2137803035]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewContractPanel" unique_id=-2137803034]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewContractPanel/Margin" unique_id=-2137803033]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewContractPanel/Margin/Content" unique_id=-2137803032]
layout_mode = 2
text = "RECOMMENDED ATTENTION"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewContractPanel/Margin/Content" unique_id=-2137803031]
custom_minimum_size = Vector2(0, 58)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="SectorsWidgets" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137803030]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="SectorListPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets" unique_id=-2137803029]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorListPanel" unique_id=-2137803028]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorListPanel/Margin" unique_id=-2137803027]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorListPanel/Margin/Content" unique_id=-2137803026]
layout_mode = 2
text = "SECTOR LIST"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorListPanel/Margin/Content" unique_id=-2137803025]
custom_minimum_size = Vector2(0, 224)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false
autowrap_mode = 0

[node name="SectorDetailPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets" unique_id=-2137803024]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorDetailPanel" unique_id=-2137803023]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorDetailPanel/Margin" unique_id=-2137803022]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorDetailPanel/Margin/Content" unique_id=-2137803021]
layout_mode = 2
text = "SECTOR DETAIL"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorDetailPanel/Margin/Content" unique_id=-2137803020]
custom_minimum_size = Vector2(0, 224)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="PowerWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137803019]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="PowerTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets" unique_id=-2137803018]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="PowerGlobalPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow" unique_id=-2137803017]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerGlobalPanel" unique_id=-2137803016]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerGlobalPanel/Margin" unique_id=-2137803015]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerGlobalPanel/Margin/Content" unique_id=-2137803014]
layout_mode = 2
text = "GLOBAL POWER"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerGlobalPanel/Margin/Content" unique_id=-2137803013]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="PowerPresetPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow" unique_id=-2137803012]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerPresetPanel" unique_id=-2137803011]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerPresetPanel/Margin" unique_id=-2137803010]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerPresetPanel/Margin/Content" unique_id=-2137803009]
layout_mode = 2
text = "ROUTING PRESETS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerPresetPanel/Margin/Content" unique_id=-2137803008]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="PowerAllocationPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets" unique_id=-2137803007]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerAllocationPanel" unique_id=-2137803006]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerAllocationPanel/Margin" unique_id=-2137803005]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerAllocationPanel/Margin/Content" unique_id=-2137803004]
layout_mode = 2
text = "SECTOR ALLOCATION"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerAllocationPanel/Margin/Content" unique_id=-2137803003]
custom_minimum_size = Vector2(0, 214)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="DefenseWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137803002]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="DefenseTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets" unique_id=-2137803001]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="DefenseReadinessPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow" unique_id=-2137803000]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseReadinessPanel" unique_id=-2137802999]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseReadinessPanel/Margin" unique_id=-2137802998]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseReadinessPanel/Margin/Content" unique_id=-2137802997]
layout_mode = 2
text = "READINESS SUMMARY"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseReadinessPanel/Margin/Content" unique_id=-2137802996]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="DefenseModesPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow" unique_id=-2137802995]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseModesPanel" unique_id=-2137802994]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseModesPanel/Margin" unique_id=-2137802993]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseModesPanel/Margin/Content" unique_id=-2137802992]
layout_mode = 2
text = "ENGAGEMENT MODES"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseModesPanel/Margin/Content" unique_id=-2137802991]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="DefenseCoveragePanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets" unique_id=-2137802990]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseCoveragePanel" unique_id=-2137802989]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseCoveragePanel/Margin" unique_id=-2137802988]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseCoveragePanel/Margin/Content" unique_id=-2137802987]
layout_mode = 2
text = "SECTOR COVERAGE"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseCoveragePanel/Margin/Content" unique_id=-2137802986]
custom_minimum_size = Vector2(0, 214)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="SensorsWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802985]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="SensorsTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets" unique_id=-2137802984]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="SensorsFidelityPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow" unique_id=-2137802983]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsFidelityPanel" unique_id=-2137802982]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsFidelityPanel/Margin" unique_id=-2137802981]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsFidelityPanel/Margin/Content" unique_id=-2137802980]
layout_mode = 2
text = "FIDELITY SUMMARY"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsFidelityPanel/Margin/Content" unique_id=-2137802979]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="SensorsPredictionPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow" unique_id=-2137802978]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsPredictionPanel" unique_id=-2137802977]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsPredictionPanel/Margin" unique_id=-2137802976]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsPredictionPanel/Margin/Content" unique_id=-2137802975]
layout_mode = 2
text = "PREDICTION STRIP"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsPredictionPanel/Margin/Content" unique_id=-2137802974]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="SensorsActivityPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets" unique_id=-2137802973]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsActivityPanel" unique_id=-2137802972]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsActivityPanel/Margin" unique_id=-2137802971]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsActivityPanel/Margin/Content" unique_id=-2137802970]
layout_mode = 2
text = "ACTIVITY TAGS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsActivityPanel/Margin/Content" unique_id=-2137802969]
custom_minimum_size = Vector2(0, 214)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="IncidentsWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802968]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="IncidentsFilterPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets" unique_id=-2137802967]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsFilterPanel" unique_id=-2137802966]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsFilterPanel/Margin" unique_id=-2137802965]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsFilterPanel/Margin/Content" unique_id=-2137802964]
layout_mode = 2
text = "FILTERS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsFilterPanel/Margin/Content" unique_id=-2137802963]
custom_minimum_size = Vector2(0, 86)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="IncidentsTablePanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets" unique_id=-2137802962]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsTablePanel" unique_id=-2137802961]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsTablePanel/Margin" unique_id=-2137802960]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsTablePanel/Margin/Content" unique_id=-2137802959]
layout_mode = 2
text = "INCIDENT TABLE"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsTablePanel/Margin/Content" unique_id=-2137802958]
custom_minimum_size = Vector2(0, 246)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ArchiveWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802957]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="ArchiveTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets" unique_id=-2137802956]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="ArchiveIntegrityPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow" unique_id=-2137802955]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveIntegrityPanel" unique_id=-2137802954]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveIntegrityPanel/Margin" unique_id=-2137802953]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveIntegrityPanel/Margin/Content" unique_id=-2137802952]
layout_mode = 2
text = "ARCHIVE INTEGRITY"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveIntegrityPanel/Margin/Content" unique_id=-2137802951]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ArchiveCategoriesPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow" unique_id=-2137802950]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveCategoriesPanel" unique_id=-2137802949]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveCategoriesPanel/Margin" unique_id=-2137802948]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveCategoriesPanel/Margin/Content" unique_id=-2137802947]
layout_mode = 2
text = "KNOWLEDGE CATEGORIES"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveCategoriesPanel/Margin/Content" unique_id=-2137802946]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ArchiveDetailPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets" unique_id=-2137802945]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveDetailPanel" unique_id=-2137802944]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveDetailPanel/Margin" unique_id=-2137802943]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveDetailPanel/Margin/Content" unique_id=-2137802942]
layout_mode = 2
text = "NODE DETAIL"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveDetailPanel/Margin/Content" unique_id=-2137802941]
custom_minimum_size = Vector2(0, 214)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ReconWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802940]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="ReconHypothesisPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets" unique_id=-2137802939]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconHypothesisPanel" unique_id=-2137802938]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconHypothesisPanel/Margin" unique_id=-2137802937]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconHypothesisPanel/Margin/Content" unique_id=-2137802936]
layout_mode = 2
text = "CURRENT HYPOTHESIS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconHypothesisPanel/Margin/Content" unique_id=-2137802935]
custom_minimum_size = Vector2(0, 138)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ReconTargetsPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets" unique_id=-2137802934]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconTargetsPanel" unique_id=-2137802933]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconTargetsPanel/Margin" unique_id=-2137802932]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconTargetsPanel/Margin/Content" unique_id=-2137802931]
layout_mode = 2
text = "AVAILABLE TARGETS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconTargetsPanel/Margin/Content" unique_id=-2137802930]
custom_minimum_size = Vector2(0, 214)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ContractsWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802929]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="ContractsTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets" unique_id=-2137802928]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="ContractsSlotPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow" unique_id=-2137802927]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsSlotPanel" unique_id=-2137802926]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsSlotPanel/Margin" unique_id=-2137802925]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsSlotPanel/Margin/Content" unique_id=-2137802924]
layout_mode = 2
text = "SCENARIO SLOT"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsSlotPanel/Margin/Content" unique_id=-2137802923]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ContractsCouplingPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow" unique_id=-2137802922]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsCouplingPanel" unique_id=-2137802921]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsCouplingPanel/Margin" unique_id=-2137802920]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsCouplingPanel/Margin/Content" unique_id=-2137802919]
layout_mode = 2
text = "WORLD COUPLING"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsCouplingPanel/Margin/Content" unique_id=-2137802918]
custom_minimum_size = Vector2(0, 118)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="HistoryWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802917]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="HistoryLogPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/HistoryWidgets" unique_id=-2137802916]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/HistoryWidgets/HistoryLogPanel" unique_id=-2137802915]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/HistoryWidgets/HistoryLogPanel/Margin" unique_id=-2137802914]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/HistoryWidgets/HistoryLogPanel/Margin/Content" unique_id=-2137802913]
layout_mode = 2
text = "COMMAND LOG"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/HistoryWidgets/HistoryLogPanel/Margin/Content" unique_id=-2137802912]
custom_minimum_size = Vector2(0, 286)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="StatusWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802911]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="StatusTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets" unique_id=-2137802910]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="StatusRawPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow" unique_id=-2137802909]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusRawPanel" unique_id=-2137802908]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusRawPanel/Margin" unique_id=-2137802907]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusRawPanel/Margin/Content" unique_id=-2137802906]
layout_mode = 2
text = "STATUS RAW"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusRawPanel/Margin/Content" unique_id=-2137802905]
custom_minimum_size = Vector2(0, 138)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="StatusParsedPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow" unique_id=-2137802904]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusParsedPanel" unique_id=-2137802903]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusParsedPanel/Margin" unique_id=-2137802902]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusParsedPanel/Margin/Content" unique_id=-2137802901]
layout_mode = 2
text = "PARSED MIRROR"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusParsedPanel/Margin/Content" unique_id=-2137802900]
custom_minimum_size = Vector2(0, 138)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="StatusFidelityPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets" unique_id=-2137802899]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusFidelityPanel" unique_id=-2137802898]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusFidelityPanel/Margin" unique_id=-2137802897]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusFidelityPanel/Margin/Content" unique_id=-2137802896]
layout_mode = 2
text = "FIDELITY NOTES"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusFidelityPanel/Margin/Content" unique_id=-2137802895]
custom_minimum_size = Vector2(0, 186)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="FabricationWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack"]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="TopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="FabStatusPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabStatusPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabStatusPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabStatusPanel/Margin/Content"]
layout_mode = 2
text = "FAB STATUS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabStatusPanel/Margin/Content"]
custom_minimum_size = Vector2(0, 82)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="FabSelectedRecipePanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabSelectedRecipePanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabSelectedRecipePanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabSelectedRecipePanel/Margin/Content"]
layout_mode = 2
text = "SELECTED WORK ORDER"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/TopRow/FabSelectedRecipePanel/Margin/Content"]
custom_minimum_size = Vector2(0, 82)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="MainRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="FabCategoryPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow"]
custom_minimum_size = Vector2(132, 0)
layout_mode = 2

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCategoryPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCategoryPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCategoryPanel/Margin/Content"]
layout_mode = 2
text = "FILTER"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCategoryPanel/Margin/Content"]
custom_minimum_size = Vector2(0, 172)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="FabRecipeListPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabRecipeListPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabRecipeListPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabRecipeListPanel/Margin/Content"]
layout_mode = 2
text = "WORK ORDERS"

[node name="RecipeScroll" type="ScrollContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabRecipeListPanel/Margin/Content"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
horizontal_scroll_mode = 0

[node name="Rows" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabRecipeListPanel/Margin/Content/RecipeScroll"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4

[node name="FabCostPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCostPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCostPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCostPanel/Margin/Content"]
layout_mode = 2
text = "COST / OUTPUT"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/MainRow/FabCostPanel/Margin/Content"]
custom_minimum_size = Vector2(0, 190)
layout_mode = 2
size_flags_vertical = 3
bbcode_enabled = true
fit_content = true
scroll_active = true

[node name="BottomRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="FabProgressPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabProgressPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabProgressPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabProgressPanel/Margin/Content"]
layout_mode = 2
text = "IN PROGRESS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabProgressPanel/Margin/Content"]
custom_minimum_size = Vector2(0, 20)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="FabReadyBuildPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabReadyBuildPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabReadyBuildPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabReadyBuildPanel/Margin/Content"]
layout_mode = 2
text = "READY BUILDS"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/BottomRow/FabReadyBuildPanel/Margin/Content"]
custom_minimum_size = Vector2(0, 20)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="ActionRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="CraftOneButton" type="Button" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/ActionRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "CRAFT 1"

[node name="CraftToMaxButton" type="Button" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/ActionRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "CRAFT TO MAX"

[node name="PlaceReadyBuildButton" type="Button" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/ActionRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "PLACE READY BUILD"

[node name="CancelQueueButton" type="Button" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/FabricationWidgets/ActionRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "CANCEL QUEUE"

[node name="SettingsWidgets" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack" unique_id=-2137802894]
visible = false
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="SettingsTopRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets" unique_id=-2137802893]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="SettingsDisplayPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow" unique_id=-2137802892]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsDisplayPanel" unique_id=-2137802891]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsDisplayPanel/Margin" unique_id=-2137802890]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsDisplayPanel/Margin/Content" unique_id=-2137802889]
layout_mode = 2
text = "DISPLAY"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsDisplayPanel/Margin/Content" unique_id=-2137802888]
custom_minimum_size = Vector2(0, 138)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="SettingsInputPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow" unique_id=-2137802887]
layout_mode = 2
size_flags_horizontal = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsInputPanel" unique_id=-2137802886]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsInputPanel/Margin" unique_id=-2137802885]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsInputPanel/Margin/Content" unique_id=-2137802884]
layout_mode = 2
text = "INPUT"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsInputPanel/Margin/Content" unique_id=-2137802883]
custom_minimum_size = Vector2(0, 138)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="SettingsMapPanel" type="PanelContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets" unique_id=-2137802882]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Margin" type="MarginContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsMapPanel" unique_id=-2137802881]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Content" type="VBoxContainer" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsMapPanel/Margin" unique_id=-2137802880]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Title" type="Label" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsMapPanel/Margin/Content" unique_id=-2137802879]
layout_mode = 2
text = "MAP"

[node name="Body" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsMapPanel/Margin/Content" unique_id=-2137802878]
custom_minimum_size = Vector2(0, 186)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="MapOutput" type="RichTextLabel" parent="UI/TerminalPanel/Body/MapColumn" unique_id=194127337]
custom_minimum_size = Vector2(0, 104)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
bbcode_enabled = true
text = "NO DATA"
fit_content = true

[node name="CommandColumn" type="VBoxContainer" parent="UI/TerminalPanel/Body" unique_id=1757164212]
custom_minimum_size = Vector2(340, 0)
layout_mode = 2
theme_override_constants/separation = 8

[node name="CommandTitle" type="Label" parent="UI/TerminalPanel/Body/CommandColumn" unique_id=1757164213]
layout_mode = 2
text = "TRANSCRIPT"

[node name="ActivityScroll" type="ScrollContainer" parent="UI/TerminalPanel/Body/CommandColumn" unique_id=1905084263]
custom_minimum_size = Vector2(0, 0)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
horizontal_scroll_mode = 0
vertical_scroll_mode = 1

[node name="TerminalOutput" type="RichTextLabel" parent="UI/TerminalPanel/Body/CommandColumn/ActivityScroll" unique_id=668276365]
custom_minimum_size = Vector2(0, 0)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
focus_mode = 2
bbcode_enabled = true
fit_content = false
scroll_active = false
selection_enabled = true

[node name="InputRow" type="HBoxContainer" parent="UI/TerminalPanel/Body/CommandColumn" unique_id=1322626681]
custom_minimum_size = Vector2(0, 48)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 8
theme_override_constants/separation = 6

[node name="Prompt" type="Label" parent="UI/TerminalPanel/Body/CommandColumn/InputRow" unique_id=86849026]
custom_minimum_size = Vector2(18, 42)
layout_mode = 2
size_flags_vertical = 4
text = ">"

[node name="TerminalInput" type="LineEdit" parent="UI/TerminalPanel/Body/CommandColumn/InputRow" unique_id=140366070]
visible = true
custom_minimum_size = Vector2(220, 44)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
focus_mode = 2
placeholder_text = "ENTER COMMAND"

[node name="Status" type="Label" parent="UI/TerminalPanel/Body/CommandColumn" unique_id=1839776512]
custom_minimum_size = Vector2(0, 28)
layout_mode = 2
text = "READY"

[node name="Hint" type="Label" parent="UI/TerminalPanel" unique_id=1026997078]
layout_mode = 0
offset_left = 16.0
offset_top = 624.0
offset_right = 1198.0
offset_bottom = 648.0
text = "Command line accepts typed orders. SECTORS: click sector links or minimap markers to focus. Esc closes."

[node name="TerminalBackground" type="TextureRect" parent="UI" unique_id=999999999]
visible = false
z_index = 5
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 0
stretch_mode = 1
script = ExtResource("36_terminal_background")

[node name="TerminalCommandRequest" type="HTTPRequest" parent="UI" unique_id=1546700661]

[node name="TerminalSnapshotRequest" type="HTTPRequest" parent="UI" unique_id=286853618]

[node name="TerminalPollTimer" type="Timer" parent="UI" unique_id=928815458]
wait_time = 2.0

[node name="InventoryUI" parent="UI" unique_id=999000002 instance=ExtResource("201_inventory_ui")]
layout_mode = 3

[node name="PauseUI" type="CanvasLayer" parent="." unique_id=1301628053]
script = ExtResource("9_pause")
metadata/logic_bricks_graph = {
"connections": [],
"next_id": 0,
"nodes": []
}
metadata/logic_bricks_frames = []

[node name="PausePanel" type="Panel" parent="PauseUI" unique_id=2092493330]
visible = false
offset_left = 300.0
offset_top = 150.0
offset_right = 700.0
offset_bottom = 500.0

[node name="Title" type="Label" parent="PauseUI/PausePanel" unique_id=242961927]
layout_mode = 0
offset_left = 20.0
offset_top = 20.0
offset_right = 380.0
offset_bottom = 50.0
text = "== COMMAND INTERFACE =="

[node name="MenuContainer" type="VBoxContainer" parent="PauseUI/PausePanel" unique_id=140312117]
layout_mode = 0
offset_left = 20.0
offset_top = 60.0
offset_right = 380.0
offset_bottom = 330.0
</file>

<file path="custodian/game/actors/enemies/enemy.gd">
extends CharacterBody2D
class_name Enemy

signal enemy_died(enemy: Enemy)

const CombatConstants = preload("res://game/systems/combat/combat_constants.gd")
const DAMAGE_POPUP_SCENE := preload("res://game/actors/ui/damage_popup.tscn")
const WOLF_ANIMATION_LIBRARY := preload("res://game/enemies/procgen/wolf_animation_library.gd")
const GRUNT_ANIMATION_LIBRARY := preload("res://game/enemies/procgen/grunt_animation_library.gd")
const SAVAGE_ANIMATION_LIBRARY := preload("res://game/enemies/procgen/savage_animation_library.gd")
const ENEMY_PALETTE_SHADER := preload("res://game/enemies/procgen/enemy_palette_tint.gdshader")
const ENEMY_BLACKBOARD_SCRIPT := preload("res://game/actors/enemies/components/enemy_blackboard.gd")
const ENEMY_PERCEPTION_SCRIPT := preload("res://game/actors/enemies/components/enemy_perception_component.gd")
const ENEMY_OBJECTIVE_SENSOR_SCRIPT := preload("res://game/actors/enemies/components/enemy_objective_sensor.gd")
const ENEMY_LOOT_CARRIER_SCRIPT := preload("res://game/actors/enemies/components/enemy_loot_carrier.gd")
const ENEMY_CORPSE_LOOT_SCRIPT := preload("res://game/actors/enemies/components/enemy_corpse_loot.gd")
const ENEMY_DEATH_SOUND: AudioStream = preload("res://content/audio/sfx/combat/enemy_death_01.wav")
const ENEMY_BEHAVIOR_STATE_MACHINE_SCRIPT := preload("res://game/actors/enemies/enemy_behavior_state_machine.gd")
const CRITICAL_BREACH_MARKER_VFX_SCENE := preload("res://game/vfx/combat/critical_breach_marker_vfx.tscn")
const CRITICAL_WINDOW_RING_VFX_SCENE := preload("res://game/vfx/combat/critical_window_ring_vfx.tscn")
const POSTURE_BREAK_FLASH_VFX_SCENE := preload("res://game/vfx/combat/posture_break_flash_vfx.tscn")
const CRITICAL_WINDOW_EXPIRE_VFX_SCENE := preload("res://game/vfx/combat/critical_window_expire_vfx.tscn")
const AXUL_DIRECTIONAL_SHEET_PATH := "res://content/sprites/additional-charsets/Small-8-Direction-Characters_by_AxulArt/Small-8-Direction-Characters_by_AxulArt.png"
const DIRECTIONAL_SUFFIXES := [&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw"]
const DIRECTIONAL_ANIMATION_PREFIX := "red_walk"
const WOLF_IDLE_ANIMATION := &"idle_east"
const WOLF_MOVE_ANIMATION := &"run_east"
const WOLF_ATTACK_ANIMATION := &"bite_east"
const WOLF_DEATH_ANIMATION := &"death_east"
const WOLF_SPECIAL_ANIMATION := &"howl_east"
const CUSTOM_ENEMY_GRUNT := &"enemy_grunt"
const CUSTOM_ENEMY_MARINE := &"enemy_marine"
const CUSTOM_ENEMY_SAVAGE := &"enemy_savage"
const GRUNT_IDLE_ANIMATION := &"idle_s"
const GRUNT_MOVE_ANIMATION := &"run_w"
const GRUNT_ATTACK_ANIMATION := &"melee_e"
const GRUNT_ATTACK_FX_ANIMATION := &"melee_fx_e"
const GRUNT_STAGGER_ANIMATION := &"stagger_s"
const GRUNT_CRIT_ANIMATION := &"crit_s"
const GRUNT_CRIT_RECOVERY_ANIMATION := &"crit_recovery_s"
const GRUNT_CRITICAL_OPEN_ENTER_ANIMATION := &"critical_open_enter_s"
const GRUNT_CRITICAL_OPEN_HOLD_ANIMATION := &"critical_open_hold_s"
const GRUNT_CRITICAL_OPEN_RECOVER_ANIMATION := &"critical_open_recover_s"
const GRUNT_CRITICAL_EXECUTION_VICTIM_ANIMATIONS := {
	&"s": &"critical_execution_victim_s",
	&"e": &"critical_execution_victim_e",
	&"w": &"critical_execution_victim_w",
}
const GRUNT_CRIT_FX_ANIMATION := &"crit_fx_s"
const GRUNT_FLINCH_FX_ANIMATION := &"flinch_fx_s"
const GRUNT_DEATH_ANIMATION := &"death_e"
const GRUNT_FLINCH_ANIMATION := &"flinch_s"
const CUSTOM_AMBIENT_EAST_ANIMATION := &"ambient_slink_east"
const CUSTOM_AMBIENT_NORTH_ANIMATION := &"ambient_slink_north"
const CUSTOM_AMBIENT_SOUTH_ANIMATION := &"ambient_slink_south"
const CUSTOM_AMBIENT_KO_ANIMATION := &"ambient_knockout"

enum AssaultState {
	STAGING,
	PROBING,
	COMMIT,
	REGROUP,
}

enum ParryCriticalPhase {
	NONE,
	ENTER,
	HOLD,
	RECOVER,
	EXECUTING,
}

enum VisualBackend {
	AUTHORED_FRAMES,
	HUMANOID_CUTOUT,
}

enum LifeState {
	ALIVE,
	DYING,
	LOOTABLE_CORPSE,
	EMPTY_CORPSE,
}

@export var enemy_name: String = "SCOUT"
@export var speed: float = 80.0
@export var health: float = 50.0
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var base_tint: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var structure_attack_range: float = 58.0
@export var detection_range: float = 420.0
@export var retarget_interval: float = 0.25
@export var team: String = "enemy"
@export var strong_attack_multiplier: float = 3.0
@export var attack_objective: String = "breach_command"
@export var attack_windup_duration: float = 0.10
@export var hit_recoil_duration: float = 0.12
@export var melee_hit_range_grace_multiplier: float = 1.15
@export var melee_hit_range_grace_px: float = 10.0
@export var melee_hit_arc_degrees: float = 95.0
@export var stagger_duration: float = 0.35
@export var stagger_damage_threshold: float = 24.0
@export var crit_damage_threshold: float = 48.0
@export var resists_light_flinch: bool = false
@export_enum("body", "robot_metal", "scorched", "shrumb", "hallway_reverb")
var melee_impact_audio_profile: String = "body"
@export var crit_hit_duration: float = 0.8
@export var crit_recovery_duration: float = 0.625
@export var assault_staging_duration_min: float = 1.25
@export var assault_staging_duration_max: float = 2.75
@export var assault_probe_duration_min: float = 2.5
@export var assault_probe_duration_max: float = 4.5
@export var assault_regroup_duration: float = 2.2
@export var assault_probe_speed_multiplier: float = 0.72
@export var assault_regroup_speed_multiplier: float = 0.82
@export var assault_damage_commit_threshold: float = 8.0
@export var assault_commit_detection_multiplier: float = 0.72
@export var passive: bool = false
@export var counts_as_wave_enemy: bool = true
@export var material_drop_min: int = 0
@export var material_drop_max: int = 0
@export var material_drop_fallback_enabled: bool = true
@export var loot_table_id: String = ""
@export var loot_table: Array[Dictionary] = []
@export var empty_corpse_min_lifetime_sec: float = 8.0
@export var corpse_offscreen_margin_px: float = 96.0
@export var empty_corpse_hard_lifetime_sec: float = 45.0
@export var corpse_loot_pickup_radius_px: float = 22.0
@export var corpse_loot_marker_offset := Vector2(0.0, -8.0)
@export var passive_wander_radius: float = 72.0
@export var passive_wander_interval_min: float = 0.8
@export var passive_wander_interval_max: float = 2.6
@export var passive_alert_radius: float = 96.0
@export var passive_flee_speed_multiplier: float = 1.9
@export var passive_flee_cooldown: float = 1.25
@export var passive_flee_retarget_interval: float = 0.35
@export var ambient_critter_target_range: float = 120.0
@export var stuck_reroute_enabled: bool = true
@export var stuck_reroute_delay: float = 0.28
@export var stuck_progress_ratio_threshold: float = 0.18
@export var stuck_repath_cooldown: float = 0.35
@export var uses_directional_charset: bool = false
@export_file("*.png") var directional_charset_sheet_path: String = AXUL_DIRECTIONAL_SHEET_PATH
@export var directional_charset_row_start: int = 2
@export var directional_charset_frame_size: int = 16
@export var directional_charset_fps: float = 8.0
@export var directional_charset_scale: Vector2 = Vector2(1.75, 1.75)
@export var directional_animation_prefix: String = DIRECTIONAL_ANIMATION_PREFIX
@export var custom_enemy_animation_set: String = ""
@export var custom_enemy_animation_scale: Vector2 = Vector2.ONE
@export var custom_enemy_fx_scale: Vector2 = Vector2.ONE
@export var visual_backend: VisualBackend = VisualBackend.AUTHORED_FRAMES
@export var health_bar_vertical_offset: float = -28.0
@export var grunt_parry_critical_window_min_sec: float = 0.8
@export var grunt_parry_critical_capture_range_px: float = 72.0
@export var grunt_parry_critical_operator_offset: Vector2 = Vector2.ZERO
@export var grunt_critical_breach_marker_offset: Vector2 = Vector2(0.0, -62.0)
@export var grunt_critical_window_ring_offset: Vector2 = Vector2.ZERO
@export var grunt_optional_critical_vfx_enabled: bool = true
@export var grunt_falcon_punch_enabled: bool = false
@export var grunt_falcon_punch_windup_time: float = 0.75
@export var grunt_falcon_punch_leap_time: float = 0.28
@export var grunt_falcon_punch_impact_lock_time: float = 0.08
@export var grunt_falcon_punch_recovery_time: float = 0.70
@export var grunt_falcon_punch_distance_px: float = 96.0
@export var grunt_falcon_punch_damage_multiplier: float = 1.35
@export var grunt_falcon_punch_cooldown: float = 2.1
@export var grunt_falcon_punch_launch_band_min: float = 88.0
@export var grunt_falcon_punch_launch_band_max: float = 184.0
@export var grunt_falcon_punch_hit_active_start_ratio: float = 0.38
@export var grunt_falcon_punch_hit_active_end_ratio: float = 0.76
@export var grunt_falcon_punch_hit_forward_reach_px: float = 42.0
@export var grunt_falcon_punch_hit_lateral_reach_px: float = 30.0
@export var grunt_falcon_punch_windup_speed_multiplier: float = 0.15
@export var grunt_falcon_punch_recovery_speed: float = 0.0
@export var grunt_falcon_punch_stop_short_px: float = 28.0
@export var grunt_falcon_punch_knockback_px: float = 58.0
@export var grunt_falcon_punch_victim_hitstop: float = 0.06
@export var grunt_falcon_punch_attacker_hitstop: float = 0.035
@export var grunt_falcon_punch_camera_shake_strength: float = 0.22
@export var grunt_falcon_punch_camera_shake_duration: float = 0.10
@export_range(0.0, 1.0, 0.01) var grunt_falcon_punch_chance: float = 0.35
@export var grunt_falcon_punch_recent_parry_lockout_sec: float = 3.0
@export var grunt_falcon_punch_requires_clear_lane: bool = true
@export var grunt_falcon_punch_ally_lane_radius_px: float = 34.0
@export var grunt_falcon_punch_after_normal_attacks_min: int = 1
@export var enemy_body_separation_px: float = 28.0
@export var enemy_spacing_radius_px: float = 34.0
@export var enemy_spacing_strength: float = 0.65
@export var savage_chain_enabled: bool = false
@export var savage_chain_gap_time: float = 0.10
@export var savage_chain_second_windup_time: float = 0.16
@export var savage_chain_second_damage: float = 12.0
@export var savage_chain_recovery_time: float = 0.55
@export var savage_chain_first_guard_stamina_damage: float = 10.0
@export var savage_chain_second_guard_stamina_damage: float = 22.0
@export var savage_pounce_enabled: bool = false
@export var savage_pounce_windup_time: float = 0.28
@export var savage_pounce_leap_time: float = 0.18
@export var savage_pounce_recovery_time: float = 0.55
@export var savage_pounce_distance_px: float = 64.0
@export var savage_pounce_damage: float = 18.0
@export var savage_pounce_knockback_px: float = 52.0
@export var savage_pounce_cooldown: float = 1.8
@export var savage_pounce_launch_band_min: float = 44.0
@export var savage_pounce_launch_band_max: float = 132.0
@export var savage_pounce_hit_active_start_ratio: float = 0.20
@export var savage_pounce_hit_active_end_ratio: float = 0.86
@export var savage_pounce_hit_forward_reach_px: float = 30.0
@export var savage_pounce_hit_lateral_reach_px: float = 22.0
var simulation_tier: String = "active"
@export var marine_dash_enabled: bool = false
@export var marine_dash_windup_time: float = 0.32
@export var marine_dash_time: float = 0.18
@export var marine_dash_impact_lock_time: float = 0.08
@export var marine_dash_recovery_time: float = 0.42
@export var marine_dash_distance_px: float = 150.0
@export var marine_dash_damage: float = 28.0
@export var marine_dash_poise_damage: float = 55.0
@export var marine_dash_knockback_px: float = 95.0
@export var marine_dash_attacker_hitstop: float = 0.045
@export var marine_dash_victim_hitstop: float = 0.09
@export var marine_dash_camera_shake_strength: float = 0.45
@export var marine_dash_camera_shake_duration: float = 0.16
@export var marine_dash_cooldown: float = 1.25
@export var marine_dash_hit_radius: float = 24.0
@export var marine_dash_hit_active_start_ratio: float = 0.28
@export var marine_dash_hit_active_end_ratio: float = 0.9
@export var marine_dash_hit_forward_reach_px: float = 30.0
@export var marine_dash_hit_lateral_reach_px: float = 22.0
@export var marine_dash_launch_band_min: float = 96.0
@export var marine_dash_launch_band_max: float = 240.0
@export var marine_dash_charge_extra_windup: float = 0.56
@export var marine_dash_charge_distance_bonus: float = 0.72
@export var marine_dash_charge_damage_bonus: float = 0.66
@export var marine_dash_prediction_time: float = 0.3
@export var marine_dash_reset_time: float = 0.48
@export var marine_dash_reset_speed: float = 100.0
@export var custom_ambient_animation_enabled: bool = false
@export_file("*.png") var custom_ambient_east_sheet_path: String = ""
@export var custom_ambient_east_frame_size: Vector2i = Vector2i(64, 83)
@export var custom_ambient_east_fps: float = 10.0
@export var custom_ambient_east_scale: Vector2 = Vector2(0.42, 0.42)
@export_file("*.png") var custom_ambient_north_south_sheet_path: String = ""
@export_file("*.png") var custom_ambient_north_sheet_path: String = ""
@export_file("*.png") var custom_ambient_south_sheet_path: String = ""
@export var custom_ambient_north_south_frame_size: Vector2i = Vector2i(384, 512)
@export var custom_ambient_north_south_columns: int = 4
@export var custom_ambient_north_south_fps: float = 8.0
@export var custom_ambient_north_south_scale: Vector2 = Vector2(0.20, 0.20)
@export_file("*.png") var custom_ambient_knockout_sheet_path: String = ""
@export var custom_ambient_knockout_frame_size: Vector2i = Vector2i(384, 512)
@export var custom_ambient_knockout_columns: int = 4
@export var custom_ambient_knockout_rows: int = 2
@export var custom_ambient_knockout_fps: float = 12.0
@export var custom_ambient_knockout_scale: Vector2 = Vector2(0.20, 0.20)
@export var behavior_state_machine_enabled: bool = false
@export var behavior_profile_id: StringName = &"raider_grunt"

var target: Node2D = null
var dead := false
var life_state: LifeState = LifeState.ALIVE
var _pending_corpse_payload: Dictionary = {}
var _corpse_loot: EnemyCorpseLoot = null
var _empty_corpse_age_sec := 0.0
var _corpse_cleanup_timer_sec := 0.0
var damage_timer := 0.0
var damage_interval := 1.0  # Damage every 1 second
var target_refresh_timer := 0.0
var used_strong_attack := false
var _attack_windup_timer: float = 0.0
var _pending_attack_damage: float = 0.0
var _stagger_timer: float = 0.0
var _recoil_timer: float = 0.0
var _crit_timer: float = 0.0
var _crit_recovery_timer: float = 0.0
var _parry_critical_window_timer: float = 0.0
var _parry_critical_phase: int = ParryCriticalPhase.NONE
var _parry_critical_target: Node2D = null
var _parry_critical_phase_timer: float = 0.0
var _parry_critical_execution_token: int = 0
var _parry_critical_execution_damage_applied: bool = false
var _parry_critical_execution_root: Vector2 = Vector2.ZERO
var _parry_critical_execution_direction: StringName = &"s"
var _parry_critical_standalone_root: Vector2 = Vector2.ZERO
var _parry_critical_standalone_root_valid: bool = false
var _parry_critical_execution_body_original_position: Vector2 = Vector2.ZERO
var _parry_critical_execution_body_position_captured: bool = false
var _critical_breach_marker_vfx: Node2D = null
var _critical_window_ring_vfx: Node2D = null
var _windup_attack_is_strong: bool = false
var _pending_attack_forward: Vector2 = Vector2.DOWN
var _pending_attack_range_px: float = 0.0
var _pending_attack_arc_degrees: float = 95.0
var _attack_sequence: int = 0
var _pending_attack_id: String = ""
var _threat_highlight_enabled: bool = false
var _threat_highlight_time: float = 0.0
var _base_sprite_scale: Vector2 = Vector2.ONE
var _last_move_direction: Vector2 = Vector2.DOWN
var _custom_animation_presentation_sector: StringName = &"s"
var _spawn_position: Vector2 = Vector2.ZERO
var _passive_home_initialized: bool = false
var _passive_target_position: Vector2 = Vector2.ZERO
var _passive_wander_timer: float = 0.0
var _passive_flee_timer: float = 0.0
var _passive_flee_retarget_timer: float = 0.0
var _assault_state: int = AssaultState.STAGING
var _assault_state_timer: float = 0.0
var _assault_probe_destination: Vector2 = Vector2.ZERO
var _custom_ambient_knockout_flip_h: bool = false
var _variant_profile: Resource = null
var _variant_behavior_id: String = ""
var _variant_attack_profile_id: String = ""
var _variant_special_profile_id: String = ""
var _uses_procedural_variant_visuals: bool = false
var _last_movement_probe_position: Vector2 = Vector2.ZERO
var _stuck_reroute_timer: float = 0.0
var _stuck_repath_cooldown_timer: float = 0.0
var _marine_dash_phase: StringName = &""
var _marine_dash_timer: float = 0.0
var _marine_dash_direction: Vector2 = Vector2.RIGHT
var _marine_dash_start_position: Vector2 = Vector2.ZERO
var _marine_dash_hit_targets: Array[int] = []
var _marine_dash_warning_line: Line2D = null
var _marine_dash_attacker_hitstop_timer: float = 0.0
var _marine_dash_charge_ratio: float = 0.0
var _marine_dash_distance_share: float = 0.5
var _marine_dash_current_distance: float = 150.0
var _marine_dash_current_damage: float = 28.0
var _marine_dash_target_lock_done: bool = false
var _marine_dash_last_attack_hit: bool = false
var _marine_dash_reset_timer: float = 0.0
var _marine_dash_reset_direction: Vector2 = Vector2.UP
var _marine_dash_reset_side: float = 1.0
var _grunt_falcon_punch_phase: StringName = &""
var _grunt_falcon_punch_timer: float = 0.0
var _grunt_falcon_punch_direction: Vector2 = Vector2.RIGHT
var _grunt_falcon_punch_start_position: Vector2 = Vector2.ZERO
var _grunt_falcon_punch_hit_targets: Array[int] = []
var _grunt_falcon_punch_current_distance: float = 0.0
var _grunt_falcon_punch_cooldown_timer: float = 0.0
var _grunt_falcon_punch_recent_parry_timer: float = 0.0
var _grunt_falcon_punch_attacker_hitstop_timer: float = 0.0
var _grunt_falcon_punch_normal_attacks_since_special: int = 0
var _grunt_falcon_punch_decision_credit: float = 0.0
var _grunt_falcon_punch_attack_id: String = ""
var _grunt_falcon_punch_result: StringName = &""
var _grunt_falcon_punch_impact_confirmed: bool = false
var _grunt_falcon_punch_launch_distance: float = -1.0
var _grunt_falcon_punch_active_start_target_distance: float = -1.0
var _grunt_falcon_punch_closest_approach: float = INF
var _grunt_falcon_punch_lateral_error: float = 0.0
var _grunt_falcon_punch_collision_obstructed: bool = false
var _savage_chain_phase: StringName = &""
var _savage_chain_timer: float = 0.0
var _savage_chain_direction: Vector2 = Vector2.RIGHT
var _savage_pounce_phase: StringName = &""
var _savage_pounce_timer: float = 0.0
var _savage_pounce_cooldown_timer: float = 0.0
var _savage_pounce_direction: Vector2 = Vector2.RIGHT
var _savage_pounce_start_position: Vector2 = Vector2.ZERO
var _savage_pounce_hit_targets: Array[int] = []

# Pathfinding
var navigation_system: Node = null
var current_path: PackedVector2Array = []
var path_follow_index: int = 0
var path_refresh_timer: float = 0.0
var path_refresh_interval: float = 0.5
var use_pathfinding: bool = true
var path_tolerance: float = 16.0

const TARGET_PRIORITY := {
	"command_post": 1,
	"power_node": 2,
	"turret": 3,
	"player": 4,
}

const OBJECTIVE_GROUPS := {
	"harass_player": ["player", "turret", "power_node", "command_post"],
	"destroy_power": ["power_node", "turret", "command_post", "player"],
	"destroy_turrets": ["turret", "power_node", "command_post", "player"],
	"breach_command": ["command_post", "turret", "power_node", "player"],
}

@onready var health_bar = $HealthBar
@onready var visual = $Visual
@onready var animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var custom_enemy_fx_sprite = $CustomEnemyFxSprite if has_node("CustomEnemyFxSprite") else null
@onready var humanoid_cutout_rig: HumanoidCutoutRig2D = get_node_or_null("HumanoidCutoutRig2D") as HumanoidCutoutRig2D
@onready var behavior_state_machine = $EnemyBehaviorStateMachine if has_node("EnemyBehaviorStateMachine") else null
var _visual_backend_fallbacks_reported: Dictionary = {}

func _ready():
	add_to_group("enemies")
	add_to_group("enemy")
	add_to_group("interest_managed")
	if behavior_state_machine_enabled:
		add_to_group("enemy_behavior_agent")
		_ensure_behavior_components()
	if passive:
		add_to_group("ambient_critter")
	_configure_visual_backend()
	if _uses_directional_animation_set():
		if not _uses_humanoid_cutout_backend():
			_ensure_directional_animations()
			_ensure_custom_enemy_fx_animations()
		if visual:
			visual.visible = false
		if animated_sprite:
			if _uses_custom_enemy_animation_set():
				animated_sprite.scale = custom_enemy_animation_scale
			else:
				animated_sprite.scale = _get_custom_ambient_scale_for_animation(CUSTOM_AMBIENT_SOUTH_ANIMATION) if _uses_custom_ambient_animation_set() else directional_charset_scale
			_base_sprite_scale = animated_sprite.scale
		_update_directional_animation(_last_move_direction, false)
	if animated_sprite:
		_base_sprite_scale = animated_sprite.scale
	if custom_enemy_fx_sprite:
		custom_enemy_fx_sprite.visible = false
		var fx_finished := Callable(self, "_on_custom_enemy_fx_finished")
		if not custom_enemy_fx_sprite.animation_finished.is_connected(fx_finished):
			custom_enemy_fx_sprite.animation_finished.connect(fx_finished)
	set_passive_home_position(global_position)
	_assault_probe_destination = global_position
	_last_movement_probe_position = global_position
	_schedule_next_passive_wander()
	_enter_assault_state(AssaultState.STAGING)
	damage_timer = damage_interval
	_grunt_falcon_punch_current_distance = grunt_falcon_punch_distance_px
	_grunt_falcon_punch_decision_credit = maxf(0.0, 1.0 - clampf(grunt_falcon_punch_chance, 0.0, 1.0))
	_refresh_target()
	_initialize_navigation()
	if behavior_state_machine_enabled and behavior_state_machine != null and behavior_state_machine.has_method("setup_profile"):
		behavior_state_machine.call("setup_profile", behavior_profile_id)
	_setup_health_bar_style()
	update_visuals()


func _setup_health_bar_style() -> void:
	if health_bar == null:
		return
	
	health_bar.custom_minimum_size = Vector2(48, 8)
	health_bar.offset_left = -24.0
	health_bar.offset_top = health_bar_vertical_offset
	health_bar.offset_right = 24.0
	health_bar.offset_bottom = health_bar_vertical_offset + 8.0
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0.3, 0.3, 0.3, 0.9)
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	health_bar.add_theme_stylebox_override("fill", fill_style)


func _initialize_navigation() -> void:
	# Find navigation system
	if navigation_system == null:
		navigation_system = get_tree().get_first_node_in_group("navigation")
	
	if navigation_system == null:
		for node in get_tree().get_nodes_in_group("navigation"):
			if node.has_method("get_path_to_target"):
				navigation_system = node
				break
	
	if navigation_system != null:
		print("[Enemy] ", enemy_name, " connected to navigation system")
	else:
		push_warning("[Enemy] ", enemy_name, " no navigation system found, using direct movement")

func _physics_process(delta):
	if dead:
		_update_empty_corpse_cleanup(delta)
		return
	_update_threat_highlight_visual(delta)
	_savage_pounce_cooldown_timer = maxf(0.0, _savage_pounce_cooldown_timer - delta)
	_grunt_falcon_punch_cooldown_timer = maxf(0.0, _grunt_falcon_punch_cooldown_timer - delta)
	_grunt_falcon_punch_recent_parry_timer = maxf(0.0, _grunt_falcon_punch_recent_parry_timer - delta)
	if _update_savage_attack(delta):
		return
	if _update_grunt_falcon_punch_attack(delta):
		return
	if _update_marine_dash_attack(delta):
		return
	if _update_reaction_timers(delta):
		return
	if _update_attack_windup(delta):
		return
	if behavior_state_machine_enabled and behavior_state_machine != null and behavior_state_machine.has_method("physics_update"):
		if bool(behavior_state_machine.call("physics_update", self, delta)):
			return
	if passive:
		_update_passive_behavior(delta)
		return
	if _update_assault_state(delta):
		return

	target_refresh_timer -= delta
	if target_refresh_timer <= 0.0 or target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		target_refresh_timer = retarget_interval
		_refresh_target()

	if target:
		var target_pos = target.global_position
		var dist = global_position.distance_to(target_pos)
		var attack_range = _get_attack_range(target)
		
		if dist > attack_range:
			var direction: Vector2
			
			# Use pathfinding if available and target is far enough
			if use_pathfinding and navigation_system != null and navigation_system.has_method("get_path_to_target"):
				direction = _get_pathfinding_direction(target_pos, delta)
			else:
				# Direct movement (fallback)
				direction = (target_pos - global_position).normalized()
			
			direction = _apply_enemy_spacing_to_direction(direction)
			velocity = direction * speed
			_limit_pursuit_inward_velocity(target_pos, attack_range, delta)
			move_and_slide()
			_update_stuck_reroute(target_pos, delta)
			_last_move_direction = direction if direction.length_squared() > 0.0001 else _last_move_direction
			if _uses_directional_animation_set():
				_update_directional_animation(_last_move_direction, true)
		else:
			velocity = Vector2.ZERO
			var direction = (target_pos - global_position).normalized()
			if direction.length_squared() > 0.0001:
				_last_move_direction = direction
			if _uses_directional_animation_set():
				_update_directional_animation(_last_move_direction, false)
			_attack_target(delta)
		
func _attack_target(delta: float):
	if _should_use_savage_attacks():
		if _attack_savage_pounce_target():
			return
		if _savage_chain_phase.is_empty():
			damage_timer += delta
			if damage_timer >= damage_interval:
				damage_timer = 0.0
				_start_savage_chain()
		return
	if _should_use_grunt_falcon_punch_attack():
		if _attack_grunt_falcon_punch_target(delta):
			return
	if _should_use_marine_dash_attack():
		_attack_marine_dash_target(delta)
		return
	if _attack_windup_timer > 0.0:
		return
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0
		if target and target.has_method("take_damage"):
			var dealt_damage := damage
			var is_strong := false
			if not used_strong_attack:
				used_strong_attack = true
				dealt_damage = damage * strong_attack_multiplier
				is_strong = true
			_start_attack_windup(dealt_damage, is_strong)


func _should_use_marine_dash_attack() -> bool:
	return marine_dash_enabled and custom_enemy_animation_set == String(CUSTOM_ENEMY_MARINE)


func _should_use_grunt_falcon_punch_attack() -> bool:
	return grunt_falcon_punch_enabled and custom_enemy_animation_set == String(CUSTOM_ENEMY_GRUNT)


func _should_use_savage_attacks() -> bool:
	return custom_enemy_animation_set == String(CUSTOM_ENEMY_SAVAGE) and (savage_chain_enabled or savage_pounce_enabled)


func _attack_savage_pounce_target() -> bool:
	if not savage_pounce_enabled or _savage_pounce_cooldown_timer > 0.0:
		return false
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target) or not target.is_in_group("player"):
		return false
	var target_node := target as Node2D
	if target_node == null:
		return false
	var distance := global_position.distance_to(target_node.global_position)
	if distance < savage_pounce_launch_band_min or distance > savage_pounce_launch_band_max:
		return false
	var direction := global_position.direction_to(target_node.global_position)
	_start_savage_pounce(direction)
	return true


func _start_savage_pounce(direction: Vector2) -> void:
	_savage_pounce_phase = &"windup"
	_savage_pounce_timer = maxf(0.01, savage_pounce_windup_time)
	_savage_pounce_cooldown_timer = maxf(0.0, savage_pounce_cooldown)
	_savage_pounce_direction = direction.normalized() if direction.length_squared() > 0.0001 else _last_move_direction.normalized()
	if _savage_pounce_direction.length_squared() <= 0.0001:
		_savage_pounce_direction = Vector2.RIGHT
	_savage_pounce_start_position = global_position
	_savage_pounce_hit_targets.clear()
	_last_move_direction = _savage_pounce_direction
	velocity = Vector2.ZERO
	clear_path()
	set_threat_highlight(true)
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_savage_pounce_direction, false, true)
	_log_savage_event(&"savage_pounce_windup")


func _update_savage_attack(delta: float) -> bool:
	if not _savage_pounce_phase.is_empty():
		_update_savage_pounce(delta)
		return true
	if not _savage_chain_phase.is_empty():
		_update_savage_chain(delta)
		return true
	return false


func _update_savage_pounce(delta: float) -> void:
	_savage_pounce_timer = maxf(0.0, _savage_pounce_timer - delta)
	match _savage_pounce_phase:
		&"windup":
			velocity = Vector2.ZERO
			if _savage_pounce_timer <= 0.0:
				_savage_pounce_phase = &"leap"
				_savage_pounce_timer = maxf(0.01, savage_pounce_leap_time)
				_savage_pounce_start_position = global_position
				set_threat_highlight(false)
				_log_savage_event(&"savage_pounce_leap")
		&"leap":
			var leap_speed := savage_pounce_distance_px / maxf(0.01, savage_pounce_leap_time)
			velocity = _savage_pounce_direction * leap_speed
			move_and_slide()
			_try_apply_savage_pounce_hit()
			var traveled := global_position.distance_to(_savage_pounce_start_position)
			if get_slide_collision_count() > 0 or traveled >= savage_pounce_distance_px or _savage_pounce_timer <= 0.0:
				_start_savage_pounce_recovery()
		&"recovery":
			velocity = Vector2.ZERO
			if _savage_pounce_timer <= 0.0:
				_finish_savage_pounce()
		_:
			_finish_savage_pounce()


func _try_apply_savage_pounce_hit() -> void:
	if _savage_pounce_phase != &"leap" or target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		return
	var leap_progress := clampf(1.0 - (_savage_pounce_timer / maxf(0.01, savage_pounce_leap_time)), 0.0, 1.0)
	if leap_progress < savage_pounce_hit_active_start_ratio or leap_progress > savage_pounce_hit_active_end_ratio:
		return
	var target_node := target as Node2D
	if target_node == null:
		return
	var target_id := int(target_node.get_instance_id())
	if _savage_pounce_hit_targets.has(target_id):
		return
	var to_target := target_node.global_position - global_position
	var forward_distance := to_target.dot(_savage_pounce_direction)
	var lateral_distance := absf(to_target.cross(_savage_pounce_direction))
	if forward_distance < -5.0 or forward_distance > savage_pounce_hit_forward_reach_px or lateral_distance > savage_pounce_hit_lateral_reach_px:
		return
	_savage_pounce_hit_targets.append(target_id)
	var hit_result := _apply_enemy_hit_to_target(target_node, savage_pounce_damage, &"savage_pounce")
	if bool(hit_result.get("parried", false)):
		return
	if float(hit_result.get("applied_damage", 0.0)) > 0.0 and not bool(hit_result.get("blocked", false)):
		if target_node.has_method("apply_enemy_dash_impact"):
			target_node.call("apply_enemy_dash_impact", _savage_pounce_direction, savage_pounce_knockback_px, 0.04)
	_log_savage_event(&"savage_pounce_hit", hit_result)
	_start_savage_pounce_recovery()


func _start_savage_pounce_recovery() -> void:
	_savage_pounce_phase = &"recovery"
	_savage_pounce_timer = maxf(0.01, savage_pounce_recovery_time)
	velocity = Vector2.ZERO
	_log_savage_event(&"savage_pounce_recovery")


func _finish_savage_pounce() -> void:
	_savage_pounce_phase = &""
	_savage_pounce_timer = 0.0
	_savage_pounce_hit_targets.clear()
	velocity = Vector2.ZERO
	set_threat_highlight(false)


func _start_savage_chain() -> void:
	if not savage_chain_enabled:
		return
	_savage_chain_phase = &"windup_1"
	_savage_chain_timer = maxf(0.01, attack_windup_duration)
	_savage_chain_direction = global_position.direction_to((target as Node2D).global_position) if target is Node2D else _last_move_direction
	if _savage_chain_direction.length_squared() <= 0.0001:
		_savage_chain_direction = Vector2.RIGHT
	_savage_chain_direction = _savage_chain_direction.normalized()
	_last_move_direction = _savage_chain_direction
	velocity = Vector2.ZERO
	clear_path()
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_savage_chain_direction, false, true)
	_log_savage_event(&"savage_chain_windup_1")


func _update_savage_chain(delta: float) -> void:
	_savage_chain_timer = maxf(0.0, _savage_chain_timer - delta)
	velocity = Vector2.ZERO
	if _savage_chain_timer > 0.0:
		return
	match _savage_chain_phase:
		&"windup_1":
			_resolve_savage_chain_hit(damage, &"savage_chain_1", savage_chain_first_guard_stamina_damage)
			if _savage_chain_phase != &"windup_1":
				return
			_savage_chain_phase = &"gap"
			_savage_chain_timer = maxf(0.01, savage_chain_gap_time)
		&"gap":
			_savage_chain_phase = &"windup_2"
			_savage_chain_timer = maxf(0.01, savage_chain_second_windup_time)
			_log_savage_event(&"savage_chain_windup_2")
		&"windup_2":
			_resolve_savage_chain_hit(savage_chain_second_damage, &"savage_chain_2", savage_chain_second_guard_stamina_damage)
			if _savage_chain_phase != &"windup_2":
				return
			_savage_chain_phase = &"recovery"
			_savage_chain_timer = maxf(0.01, savage_chain_recovery_time)
			_log_savage_event(&"savage_chain_recovery")
		&"recovery":
			_finish_savage_chain()
		_:
			_finish_savage_chain()


func _resolve_savage_chain_hit(hit_damage: float, hit_kind: StringName, guard_stamina_damage: float) -> void:
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target) or not (target is Node2D):
		_log_savage_event(&"savage_chain_whiff")
		return
	var target_node := target as Node2D
	var grace_range := 40.0 * melee_hit_range_grace_multiplier + melee_hit_range_grace_px
	var to_target := target_node.global_position - global_position
	if to_target.length() > grace_range or _savage_chain_direction.dot(to_target.normalized()) < cos(deg_to_rad(melee_hit_arc_degrees * 0.5)):
		_log_savage_event(&"savage_chain_whiff")
		return
	var hit_result := _apply_enemy_hit_to_target(target_node, hit_damage, hit_kind, guard_stamina_damage)
	_log_savage_event(&"savage_chain_hit", hit_result)


func _finish_savage_chain() -> void:
	_savage_chain_phase = &""
	_savage_chain_timer = 0.0
	velocity = Vector2.ZERO


func _cancel_savage_attack() -> void:
	if _savage_chain_phase.is_empty() and _savage_pounce_phase.is_empty():
		return
	_savage_chain_phase = &""
	_savage_chain_timer = 0.0
	_savage_pounce_phase = &""
	_savage_pounce_timer = 0.0
	_savage_pounce_hit_targets.clear()
	velocity = Vector2.ZERO
	set_threat_highlight(false)
	_log_savage_event(&"savage_attack_interrupted")


func _log_savage_event(event_name: StringName, result: Dictionary = {}) -> void:
	_obs_log(event_name, {
		"enemy": enemy_name,
		"chain_phase": String(_savage_chain_phase),
		"pounce_phase": String(_savage_pounce_phase),
		"position": global_position,
		"target": target.name if target != null and is_instance_valid(target) else "",
		"result": String(result.get("result", "")),
	})


func _attack_grunt_falcon_punch_target(_delta: float) -> bool:
	if not _grunt_falcon_punch_phase.is_empty():
		return true
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		return false
	var target_node := target as Node2D
	if target_node == null or not _should_start_grunt_falcon_punch_now(target_node):
		return false
	var direction := (target_node.global_position - global_position).normalized()
	_start_grunt_falcon_punch_windup(direction)
	return true


func _should_start_grunt_falcon_punch_now(target_node: Node2D) -> bool:
	if not _should_use_grunt_falcon_punch_attack() or target_node == null or not target_node.is_in_group("player"):
		return false
	var distance := global_position.distance_to(target_node.global_position)
	if distance < grunt_falcon_punch_launch_band_min or distance > grunt_falcon_punch_launch_band_max:
		return false
	if _grunt_falcon_punch_cooldown_timer > 0.0 or _grunt_falcon_punch_recent_parry_timer > 0.0:
		return false
	if _grunt_falcon_punch_normal_attacks_since_special < max(0, grunt_falcon_punch_after_normal_attacks_min):
		return false
	var chance := clampf(grunt_falcon_punch_chance, 0.0, 1.0)
	if chance <= 0.0 or _grunt_falcon_punch_decision_credit < 1.0:
		return false
	if grunt_falcon_punch_requires_clear_lane and not _is_grunt_falcon_punch_lane_clear(target_node):
		return false
	return true


func _is_grunt_falcon_punch_lane_clear(target_node: Node2D) -> bool:
	var to_target := target_node.global_position - global_position
	var lane_length := maxf(0.0, to_target.length() - grunt_falcon_punch_stop_short_px)
	if lane_length <= 0.0:
		return false
	var lane_direction := to_target.normalized()
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if candidate == self or not (candidate is Node2D):
			continue
		var other := candidate as Node2D
		if _is_target_destroyed(other):
			continue
		var offset := other.global_position - global_position
		var forward := offset.dot(lane_direction)
		if forward <= 0.0 or forward >= lane_length:
			continue
		if absf(offset.cross(lane_direction)) < grunt_falcon_punch_ally_lane_radius_px:
			return false
	return true


func _start_grunt_falcon_punch_windup(direction: Vector2) -> void:
	_attack_sequence += 1
	_grunt_falcon_punch_attack_id = "%s:falcon:%s" % [get_instance_id(), _attack_sequence]
	_grunt_falcon_punch_result = &"pending"
	_grunt_falcon_punch_impact_confirmed = false
	_grunt_falcon_punch_launch_distance = global_position.distance_to((target as Node2D).global_position) if target is Node2D and is_instance_valid(target) else -1.0
	_grunt_falcon_punch_active_start_target_distance = -1.0
	_grunt_falcon_punch_closest_approach = _grunt_falcon_punch_launch_distance if _grunt_falcon_punch_launch_distance >= 0.0 else INF
	_grunt_falcon_punch_lateral_error = 0.0
	_grunt_falcon_punch_collision_obstructed = false
	_grunt_falcon_punch_phase = &"windup"
	_grunt_falcon_punch_timer = maxf(0.01, grunt_falcon_punch_windup_time)
	_grunt_falcon_punch_cooldown_timer = maxf(0.0, grunt_falcon_punch_cooldown)
	_grunt_falcon_punch_normal_attacks_since_special = 0
	_grunt_falcon_punch_decision_credit = 0.0
	_grunt_falcon_punch_direction = direction.normalized() if direction.length_squared() > 0.0001 else _last_move_direction.normalized()
	if _grunt_falcon_punch_direction.length_squared() <= 0.0001:
		_grunt_falcon_punch_direction = Vector2.RIGHT
	_grunt_falcon_punch_start_position = global_position
	_grunt_falcon_punch_hit_targets.clear()
	_last_move_direction = _grunt_falcon_punch_direction
	clear_path()
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_grunt_falcon_punch_direction, true, false)
	_obs_increment(&"falcon_punch_attempts")
	_log_grunt_falcon_punch_event(&"grunt_falcon_punch_windup")


func _update_grunt_falcon_punch_attack(delta: float) -> bool:
	if _grunt_falcon_punch_phase.is_empty():
		return false
	if _grunt_falcon_punch_attacker_hitstop_timer > 0.0:
		_grunt_falcon_punch_attacker_hitstop_timer = maxf(0.0, _grunt_falcon_punch_attacker_hitstop_timer - delta)
		velocity = Vector2.ZERO
		return true
	_grunt_falcon_punch_timer = maxf(0.0, _grunt_falcon_punch_timer - delta)
	match _grunt_falcon_punch_phase:
		&"windup":
			_retarget_grunt_falcon_punch_windup()
			velocity = _grunt_falcon_punch_direction * speed * grunt_falcon_punch_windup_speed_multiplier
			move_and_slide()
			_last_move_direction = _grunt_falcon_punch_direction
			if _uses_custom_enemy_animation_set():
				_update_custom_enemy_animation(_grunt_falcon_punch_direction, true, false)
			if _grunt_falcon_punch_timer <= 0.0:
				_start_grunt_falcon_punch_leap()
		&"leap":
			_update_grunt_falcon_punch_leap(delta)
		&"impact_lock":
			velocity = Vector2.ZERO
			if _grunt_falcon_punch_timer <= 0.0:
				_start_grunt_falcon_punch_recovery()
		&"recovery":
			velocity = Vector2.ZERO
			if _uses_custom_enemy_animation_set():
				_update_custom_enemy_animation(_grunt_falcon_punch_direction, false, false)
			if _grunt_falcon_punch_timer <= 0.0:
				_finish_grunt_falcon_punch_attack()
		_:
			_finish_grunt_falcon_punch_attack()
	return true


func _start_grunt_falcon_punch_leap() -> void:
	_retarget_grunt_falcon_punch_windup()
	_grunt_falcon_punch_phase = &"leap"
	_grunt_falcon_punch_timer = maxf(0.01, grunt_falcon_punch_leap_time)
	_grunt_falcon_punch_start_position = global_position
	_grunt_falcon_punch_current_distance = grunt_falcon_punch_distance_px
	if target is Node2D and is_instance_valid(target):
		var desired_contact_point := (target as Node2D).global_position - _grunt_falcon_punch_direction * grunt_falcon_punch_stop_short_px
		var projected_distance := maxf(0.0, (desired_contact_point - global_position).dot(_grunt_falcon_punch_direction))
		_grunt_falcon_punch_current_distance = minf(grunt_falcon_punch_distance_px, projected_distance)
	_log_grunt_falcon_punch_event(&"grunt_falcon_punch_leap")
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_grunt_falcon_punch_direction, false, true)


func _retarget_grunt_falcon_punch_windup() -> void:
	# Track only during the readable tell. Once leap begins, direction remains
	# committed so a deliberate lateral dodge still defeats the attack.
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target) or not (target is Node2D):
		return
	var to_target := (target as Node2D).global_position - global_position
	if to_target.length_squared() <= 0.0001:
		return
	_grunt_falcon_punch_direction = to_target.normalized()
	_last_move_direction = _grunt_falcon_punch_direction


func _update_grunt_falcon_punch_leap(delta: float) -> void:
	var active_end := clampf(grunt_falcon_punch_hit_active_end_ratio, 0.01, 1.0)
	var travel_time := maxf(0.01, grunt_falcon_punch_leap_time * active_end)
	var leap_speed := _grunt_falcon_punch_current_distance / travel_time
	velocity = _grunt_falcon_punch_direction * leap_speed
	move_and_slide()
	if target is Node2D and is_instance_valid(target):
		var to_target := (target as Node2D).global_position - global_position
		_grunt_falcon_punch_closest_approach = minf(_grunt_falcon_punch_closest_approach, to_target.length())
		_grunt_falcon_punch_lateral_error = absf(to_target.cross(_grunt_falcon_punch_direction))
		if _grunt_falcon_punch_active_start_target_distance < 0.0 and _is_grunt_falcon_punch_hit_window_active():
			_grunt_falcon_punch_active_start_target_distance = to_target.length()
	var traveled := global_position.distance_to(_grunt_falcon_punch_start_position)
	var reached_contact := traveled >= _grunt_falcon_punch_current_distance or get_slide_collision_count() > 0
	_grunt_falcon_punch_collision_obstructed = _grunt_falcon_punch_collision_obstructed or get_slide_collision_count() > 0
	_try_apply_grunt_falcon_punch_hit(reached_contact)
	if _grunt_falcon_punch_phase != &"leap":
		return
	if get_slide_collision_count() > 0 or traveled >= _grunt_falcon_punch_current_distance or _grunt_falcon_punch_timer <= 0.0:
		var miss_reason := &"blocked_by_collision" if get_slide_collision_count() > 0 else _get_grunt_falcon_punch_miss_reason()
		_resolve_grunt_falcon_punch_whiff(miss_reason)


func _start_grunt_falcon_punch_impact_lock() -> void:
	if not _grunt_falcon_punch_impact_confirmed:
		return
	_grunt_falcon_punch_phase = &"impact_lock"
	_grunt_falcon_punch_timer = maxf(0.01, grunt_falcon_punch_impact_lock_time)
	velocity = Vector2.ZERO
	_log_grunt_falcon_punch_event(&"grunt_falcon_punch_impact_lock")
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_grunt_falcon_punch_direction, false, true)


func _start_grunt_falcon_punch_recovery() -> void:
	_grunt_falcon_punch_phase = &"recovery"
	_grunt_falcon_punch_timer = maxf(0.01, grunt_falcon_punch_recovery_time)
	velocity = Vector2.ZERO
	_separate_from_target_after_contact(target as Node2D if target is Node2D else null)
	_log_grunt_falcon_punch_event(&"grunt_falcon_punch_recovery")
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_grunt_falcon_punch_direction, false, false)


func _finish_grunt_falcon_punch_attack(result_override: StringName = &"") -> void:
	if _grunt_falcon_punch_phase.is_empty():
		return
	if not result_override.is_empty():
		_grunt_falcon_punch_result = result_override
	if _grunt_falcon_punch_result == &"pending":
		_grunt_falcon_punch_result = &"interrupted"
		_obs_increment(&"falcon_punch_cancelled")
	_log_grunt_falcon_punch_event(&"grunt_falcon_punch_finished")
	_grunt_falcon_punch_phase = &""
	_grunt_falcon_punch_timer = 0.0
	_grunt_falcon_punch_attacker_hitstop_timer = 0.0
	_grunt_falcon_punch_hit_targets.clear()
	_grunt_falcon_punch_current_distance = grunt_falcon_punch_distance_px
	_grunt_falcon_punch_attack_id = ""
	_grunt_falcon_punch_impact_confirmed = false
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _try_apply_grunt_falcon_punch_hit(force_contact_check: bool = false) -> void:
	if not force_contact_check and not _is_grunt_falcon_punch_hit_window_active():
		return
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		return
	var target_node := target as Node2D
	if target_node == null:
		return
	var target_id := int(target_node.get_instance_id())
	if _grunt_falcon_punch_hit_targets.has(target_id):
		return
	var to_target := target_node.global_position - global_position
	var forward_distance := to_target.dot(_grunt_falcon_punch_direction)
	if forward_distance < -6.0 or forward_distance > grunt_falcon_punch_hit_forward_reach_px:
		return
	var lateral_distance := absf(to_target.cross(_grunt_falcon_punch_direction))
	if lateral_distance > grunt_falcon_punch_hit_lateral_reach_px:
		return
	_grunt_falcon_punch_hit_targets.append(target_id)
	var hit_result := _apply_enemy_hit_to_target(
		target_node,
		damage * grunt_falcon_punch_damage_multiplier,
		&"falcon_punch",
		-1.0,
		_grunt_falcon_punch_attack_id
	)
	var result_name := StringName(str(hit_result.get("result", &"unknown")))
	_grunt_falcon_punch_result = result_name
	_obs_increment(&"grunt_falcon_punch_hits_resolved", 1)
	_obs_increment(StringName("enemy_attack_result_%s" % String(result_name)), 1)
	match result_name:
		&"damaged":
			_obs_increment(&"falcon_punch_result_damaged")
		&"dodged":
			_obs_increment(&"falcon_punch_result_iframe_dodged")
		&"blocked":
			_obs_increment(&"falcon_punch_result_blocked")
		&"parried":
			_obs_increment(&"falcon_punch_result_parried")
	var resolved_event := _get_grunt_falcon_punch_telemetry()
	resolved_event.merge({
		"enemy": enemy_name,
		"attack_id": _grunt_falcon_punch_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": target_node.get_instance_id(),
		"attack_type": "falcon_punch",
		"phase": String(_grunt_falcon_punch_phase),
		"position": global_position,
		"target": target_node.name,
		"target_position": target_node.global_position,
		"result": String(hit_result.get("result", "")),
		"applied_damage": float(hit_result.get("applied_damage", 0.0)),
		"dodged": bool(hit_result.get("dodged", false)),
		"blocked": bool(hit_result.get("blocked", false)),
		"parried": bool(hit_result.get("parried", false)),
	}, true)
	_obs_log(&"grunt_falcon_punch_hit_resolved", resolved_event)
	if bool(hit_result.get("parried", false)):
		_obs_increment(&"falcon_punch_parried")
		_obs_increment(&"enemy_attack_interrupted_by_parry")
		_separate_from_target_after_contact(target_node)
		if _grunt_falcon_punch_recent_parry_timer <= 0.0:
			apply_parry_stagger(-_grunt_falcon_punch_direction, stagger_duration, 70.0)
		return
	if not bool(hit_result.get("dodged", false)) and not bool(hit_result.get("blocked", false)) and float(hit_result.get("applied_damage", 0.0)) > 0.0:
		_grunt_falcon_punch_impact_confirmed = true
		_grunt_falcon_punch_result = &"damaged"
		_obs_increment(&"falcon_punch_hits")
		if target_node.has_method("apply_enemy_falcon_punch_impact"):
			target_node.call("apply_enemy_falcon_punch_impact", _grunt_falcon_punch_direction, grunt_falcon_punch_knockback_px, grunt_falcon_punch_victim_hitstop)
		_trigger_grunt_falcon_punch_camera_feedback()
		_apply_grunt_falcon_punch_hitstop(maxf(grunt_falcon_punch_victim_hitstop, grunt_falcon_punch_attacker_hitstop))
		_grunt_falcon_punch_attacker_hitstop_timer = maxf(_grunt_falcon_punch_attacker_hitstop_timer, grunt_falcon_punch_attacker_hitstop)
		_separate_from_target_after_contact(target_node)
		_start_grunt_falcon_punch_impact_lock()
		return
	_separate_from_target_after_contact(target_node)
	_start_grunt_falcon_punch_recovery()


func _resolve_grunt_falcon_punch_whiff(reason: StringName) -> void:
	if _grunt_falcon_punch_phase != &"leap":
		return
	_grunt_falcon_punch_result = reason
	_obs_increment(&"falcon_punch_whiffed")
	_obs_increment(&"falcon_punch_result_whiffed")
	_obs_increment(&"enemy_attack_whiffs")
	_obs_increment(&"enemy_attack_result_whiffed")
	if reason == &"blocked_by_collision":
		_obs_increment(&"enemy_attack_blocked_by_collision")
	elif reason == &"target_out_of_arc":
		_obs_increment(&"enemy_attack_whiffed_out_of_arc")
	else:
		_obs_increment(&"enemy_attack_whiffed_out_of_range")
	var whiff_event := _get_grunt_falcon_punch_telemetry()
	whiff_event.merge({
		"attack_id": _grunt_falcon_punch_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": target.get_instance_id() if target != null and is_instance_valid(target) else 0,
		"attack_type": "falcon_punch",
		"phase": "leap",
		"result": "whiffed",
		"reason": String(reason),
		"position": global_position,
	}, true)
	_obs_log(&"grunt_falcon_punch_hit_resolved", whiff_event)
	_start_grunt_falcon_punch_recovery()


func _get_grunt_falcon_punch_miss_reason() -> StringName:
	if not target is Node2D or not is_instance_valid(target) or _is_target_destroyed(target):
		return &"target_out_of_range"
	var to_target := (target as Node2D).global_position - global_position
	var lateral_distance := absf(to_target.cross(_grunt_falcon_punch_direction))
	if lateral_distance > grunt_falcon_punch_hit_lateral_reach_px:
		return &"target_out_of_arc"
	return &"target_out_of_range"


func _separate_from_target_after_contact(target_node: Node2D) -> void:
	if target_node == null or not is_instance_valid(target_node):
		return
	var separation := maxf(0.0, enemy_body_separation_px)
	var away := global_position - target_node.global_position
	if away.length_squared() <= 0.001:
		away = -_grunt_falcon_punch_direction
	if away.length_squared() <= 0.001:
		away = Vector2.LEFT
	if global_position.distance_to(target_node.global_position) < separation:
		global_position = target_node.global_position + away.normalized() * separation


func _trigger_grunt_falcon_punch_camera_feedback() -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null:
		return
	if camera.has_method("on_attack_impact"):
		camera.call("on_attack_impact", _grunt_falcon_punch_direction, true)
	if camera.has_method("shake"):
		camera.call("shake", grunt_falcon_punch_camera_shake_strength * 10.0, grunt_falcon_punch_camera_shake_duration)


func _apply_grunt_falcon_punch_hitstop(duration: float) -> void:
	if duration <= 0.0 or Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.1
	var tree := get_tree()
	if tree == null:
		Engine.time_scale = 1.0
		return
	await tree.create_timer(duration, true, false, true).timeout
	if Engine.time_scale < 1.0:
		Engine.time_scale = 1.0


func _is_grunt_falcon_punch_hit_window_active() -> bool:
	if _grunt_falcon_punch_phase != &"leap":
		return false
	var leap_time := maxf(0.01, grunt_falcon_punch_leap_time)
	var progress := clampf(1.0 - (_grunt_falcon_punch_timer / leap_time), 0.0, 1.0)
	var active_start := clampf(grunt_falcon_punch_hit_active_start_ratio, 0.0, 1.0)
	var active_end := clampf(grunt_falcon_punch_hit_active_end_ratio, active_start, 1.0)
	return progress >= active_start and progress <= active_end


func _log_grunt_falcon_punch_event(event_name: StringName) -> void:
	_obs_log(event_name, _get_grunt_falcon_punch_telemetry())


func _get_grunt_falcon_punch_telemetry() -> Dictionary:
	var dodge_phase := "unknown"
	if target != null and is_instance_valid(target) and target.has_method("get_dodge_telemetry_phase"):
		dodge_phase = String(target.call("get_dodge_telemetry_phase"))
	return {
		"attack_id": _grunt_falcon_punch_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": target.get_instance_id() if target != null and is_instance_valid(target) else 0,
		"attack_type": "falcon_punch",
		"enemy": enemy_name,
		"phase": String(_grunt_falcon_punch_phase),
		"result": String(_grunt_falcon_punch_result),
		"position": global_position,
		"direction": _grunt_falcon_punch_direction,
		"target": target.name if target != null and is_instance_valid(target) else "",
		"damage": damage * grunt_falcon_punch_damage_multiplier,
		"launch_distance": _grunt_falcon_punch_launch_distance,
		"target_distance_at_active_start": _grunt_falcon_punch_active_start_target_distance,
		"closest_approach": _grunt_falcon_punch_closest_approach if is_finite(_grunt_falcon_punch_closest_approach) else -1.0,
		"lateral_error": _grunt_falcon_punch_lateral_error,
		"player_dodge_phase": dodge_phase,
		"collision_obstructed": _grunt_falcon_punch_collision_obstructed,
		"stop_short_distance": grunt_falcon_punch_stop_short_px,
	}


func _attack_marine_dash_target(delta: float) -> void:
	if not _marine_dash_phase.is_empty():
		return
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		return
	var target_node := target as Node2D
	if target_node == null:
		return
	var distance := global_position.distance_to(target_node.global_position)
	if distance < marine_dash_launch_band_min:
		_start_marine_dash_reset(true)
		return
	damage_timer += delta
	if damage_timer < marine_dash_cooldown:
		return
	damage_timer = 0.0
	var direction := (target_node.global_position - global_position).normalized() if target_node != null else _last_move_direction
	_start_marine_dash_windup(direction, distance)


func _start_marine_dash_windup(direction: Vector2, target_distance: float = -1.0) -> void:
	_configure_marine_dash_charge(target_distance)
	_marine_dash_phase = &"windup"
	_log_marine_dash_event(&"marine_dash_windup")
	_marine_dash_timer = maxf(0.01, marine_dash_windup_time + marine_dash_charge_extra_windup * _marine_dash_charge_ratio)
	_marine_dash_direction = direction.normalized() if direction.length_squared() > 0.0001 else _last_move_direction.normalized()
	if _marine_dash_direction.length_squared() <= 0.0001:
		_marine_dash_direction = Vector2.RIGHT
	_marine_dash_start_position = global_position
	_marine_dash_hit_targets.clear()
	_marine_dash_target_lock_done = false
	_marine_dash_last_attack_hit = false
	_last_move_direction = _marine_dash_direction
	velocity = Vector2.ZERO
	clear_path()
	_show_marine_dash_telegraph(true)
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_marine_dash_direction, false, true)
		_set_marine_dash_animation_speed(maxf(0.45, marine_dash_windup_time / maxf(marine_dash_windup_time, _marine_dash_timer)))


func _configure_marine_dash_charge(target_distance: float) -> void:
	var resolved_distance := target_distance
	if resolved_distance < 0.0 and target is Node2D:
		resolved_distance = global_position.distance_to((target as Node2D).global_position)
	if resolved_distance < 0.0:
		resolved_distance = marine_dash_distance_px
	var distance_need := clampf((resolved_distance - marine_dash_distance_px * 0.66) / maxf(1.0, marine_dash_launch_band_max - marine_dash_distance_px * 0.66), 0.0, 1.0)
	var target_velocity := _get_marine_dash_target_velocity()
	var approach_direction := ((target as Node2D).global_position - global_position).normalized() if target is Node2D else _last_move_direction
	var retreat_factor := clampf(target_velocity.dot(approach_direction) / 180.0, 0.0, 1.0)
	_marine_dash_charge_ratio = clampf(maxf(distance_need, 0.52 if not _marine_dash_last_attack_hit else 0.0), 0.0, 1.0)
	_marine_dash_distance_share = clampf(0.28 + distance_need * 0.42 + retreat_factor * 0.22, 0.25, 0.82)
	var damage_share := 1.0 - _marine_dash_distance_share
	_marine_dash_current_distance = marine_dash_distance_px * (1.0 + marine_dash_charge_distance_bonus * _marine_dash_charge_ratio * _marine_dash_distance_share)
	_marine_dash_current_damage = marine_dash_damage * (1.0 + marine_dash_charge_damage_bonus * _marine_dash_charge_ratio * damage_share)


func _get_marine_dash_target_velocity() -> Vector2:
	if target is CharacterBody2D:
		return (target as CharacterBody2D).velocity
	if target != null and "velocity" in target:
		var target_velocity: Variant = target.get("velocity")
		if target_velocity is Vector2:
			return target_velocity as Vector2
	return Vector2.ZERO


func _update_marine_dash_attack(delta: float) -> bool:
	if _marine_dash_phase.is_empty():
		return _update_marine_dash_reset(delta)
	if _marine_dash_attacker_hitstop_timer > 0.0:
		_marine_dash_attacker_hitstop_timer = maxf(0.0, _marine_dash_attacker_hitstop_timer - delta)
		velocity = Vector2.ZERO
		return true
	_marine_dash_timer = maxf(0.0, _marine_dash_timer - delta)
	match _marine_dash_phase:
		&"windup":
			velocity = Vector2.ZERO
			_update_marine_dash_target_lock()
			_update_marine_dash_telegraph()
			if _marine_dash_timer <= 0.0:
				_start_marine_dash_travel()
		&"dash":
			_update_marine_dash_travel(delta)
		&"impact_lock":
			velocity = Vector2.ZERO
			if _marine_dash_timer <= 0.0:
				_start_marine_dash_recovery()
		&"recovery":
			velocity = Vector2.ZERO
			if _marine_dash_timer <= 0.0:
				_finish_marine_dash_attack()
				_start_marine_dash_reset(false)
		_:
			_finish_marine_dash_attack()
	return true


func _start_marine_dash_travel() -> void:
	_marine_dash_phase = &"dash"
	_log_marine_dash_event(&"marine_dash_travel")
	_marine_dash_timer = maxf(0.01, marine_dash_time)
	_marine_dash_start_position = global_position
	_show_marine_dash_telegraph(false)
	_set_marine_dash_animation_speed(1.0)
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_marine_dash_direction, false, true)


func _update_marine_dash_travel(delta: float) -> void:
	var dash_speed := _marine_dash_current_distance / maxf(0.01, marine_dash_time)
	velocity = _marine_dash_direction * dash_speed
	move_and_slide()
	_try_apply_marine_dash_hit()
	var traveled := global_position.distance_to(_marine_dash_start_position)
	if get_slide_collision_count() > 0 or traveled >= _marine_dash_current_distance or _marine_dash_timer <= 0.0:
		_start_marine_dash_impact_lock()


func _start_marine_dash_impact_lock() -> void:
	_marine_dash_phase = &"impact_lock"
	_log_marine_dash_event(&"marine_dash_impact_lock")
	_marine_dash_timer = maxf(0.01, marine_dash_impact_lock_time)
	velocity = Vector2.ZERO


func _start_marine_dash_recovery() -> void:
	_marine_dash_phase = &"recovery"
	_log_marine_dash_event(&"marine_dash_recovery")
	_marine_dash_timer = maxf(0.01, marine_dash_recovery_time)
	velocity = Vector2.ZERO


func _finish_marine_dash_attack() -> void:
	_log_marine_dash_event(&"marine_dash_finished")
	_marine_dash_phase = &""
	_marine_dash_timer = 0.0
	_marine_dash_attacker_hitstop_timer = 0.0
	_marine_dash_hit_targets.clear()
	_marine_dash_charge_ratio = 0.0
	_marine_dash_distance_share = 0.5
	_marine_dash_current_distance = marine_dash_distance_px
	_marine_dash_current_damage = marine_dash_damage
	_marine_dash_target_lock_done = false
	_show_marine_dash_telegraph(false)
	_set_marine_dash_animation_speed(1.0)
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _try_apply_marine_dash_hit() -> void:
	if not _is_marine_dash_hit_window_active():
		return
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		return
	var target_node := target as Node2D
	if target_node == null:
		return
	var target_id := int(target_node.get_instance_id())
	if _marine_dash_hit_targets.has(target_id):
		return
	var to_target := target_node.global_position - global_position
	var charge_multiplier := 1.0 + 0.22 * _marine_dash_charge_ratio
	var forward_distance := to_target.dot(_marine_dash_direction)
	if forward_distance < -4.0 or forward_distance > marine_dash_hit_forward_reach_px * charge_multiplier:
		return
	var lateral_distance := absf(to_target.cross(_marine_dash_direction))
	if lateral_distance > marine_dash_hit_lateral_reach_px * (1.0 + 0.15 * _marine_dash_charge_ratio):
		return
	_marine_dash_hit_targets.append(target_id)
	_apply_marine_dash_hit(target_node)


func _is_marine_dash_hit_window_active() -> bool:
	if _marine_dash_phase != &"dash":
		return false
	var dash_time := maxf(0.01, marine_dash_time)
	var progress := clampf(1.0 - (_marine_dash_timer / dash_time), 0.0, 1.0)
	var active_start := clampf(marine_dash_hit_active_start_ratio, 0.0, 1.0)
	var active_end := clampf(marine_dash_hit_active_end_ratio, active_start, 1.0)
	return progress >= active_start and progress <= active_end


func _apply_marine_dash_hit(hit_node: Node2D) -> void:
	var hit_result := _apply_enemy_hit_to_target(hit_node, _marine_dash_current_damage, &"dash")

	if bool(hit_result.get("dodged", false)) or bool(hit_result.get("parried", false)) or bool(hit_result.get("block_hitreact", false)):
		_marine_dash_last_attack_hit = false
		return

	_marine_dash_last_attack_hit = true

	var knockback_direction := _marine_dash_direction.normalized()
	if hit_node.has_method("apply_enemy_dash_impact"):
		hit_node.call("apply_enemy_dash_impact", knockback_direction, marine_dash_knockback_px, marine_dash_victim_hitstop)
	_trigger_marine_dash_camera_feedback()
	_apply_marine_dash_hitstop(maxf(marine_dash_victim_hitstop, marine_dash_attacker_hitstop))
	_marine_dash_attacker_hitstop_timer = maxf(_marine_dash_attacker_hitstop_timer, marine_dash_attacker_hitstop)
	_start_marine_dash_impact_lock()


func _trigger_marine_dash_camera_feedback() -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null:
		return
	var shake_power := marine_dash_camera_shake_strength * 10.0
	if camera.has_method("on_attack_impact"):
		camera.call("on_attack_impact", _marine_dash_direction, true)
	if camera.has_method("shake"):
		camera.call("shake", shake_power, marine_dash_camera_shake_duration)


func _apply_marine_dash_hitstop(duration: float) -> void:
	if duration <= 0.0 or Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.1
	var tree := get_tree()
	if tree == null:
		Engine.time_scale = 1.0
		return
	await tree.create_timer(duration, true, false, true).timeout
	if Engine.time_scale < 1.0:
		Engine.time_scale = 1.0


func _show_marine_dash_telegraph(p_visible: bool) -> void:
	if not p_visible:
		if _marine_dash_warning_line != null:
			_marine_dash_warning_line.visible = false
		if animated_sprite != null:
			animated_sprite.modulate = Color.WHITE
		return
	if _marine_dash_warning_line == null:
		_marine_dash_warning_line = Line2D.new()
		_marine_dash_warning_line.name = "MarineDashWarningLine"
		_marine_dash_warning_line.width = 2.0
		_marine_dash_warning_line.default_color = Color(1.0, 0.55, 0.12, 0.42)
		_marine_dash_warning_line.z_index = 20
		add_child(_marine_dash_warning_line)
	_marine_dash_warning_line.visible = true
	_marine_dash_warning_line.width = 2.0
	_marine_dash_warning_line.default_color = Color(1.0, 0.55, 0.12, 0.42)
	_update_marine_dash_telegraph()
	if animated_sprite != null:
		animated_sprite.modulate = Color(1.0, 0.64, 0.28, 1.0)


func _update_marine_dash_telegraph() -> void:
	if _marine_dash_warning_line == null:
		return
	_marine_dash_warning_line.clear_points()
	_marine_dash_warning_line.add_point(Vector2.ZERO)
	_marine_dash_warning_line.add_point(_marine_dash_direction * _marine_dash_current_distance)


func _update_marine_dash_target_lock() -> void:
	if _marine_dash_target_lock_done or target == null or not is_instance_valid(target) or not (target is Node2D):
		return
	var total_windup := maxf(0.01, marine_dash_windup_time + marine_dash_charge_extra_windup * _marine_dash_charge_ratio)
	var progress := clampf(1.0 - (_marine_dash_timer / total_windup), 0.0, 1.0)
	if progress < 0.62:
		return
	var target_node := target as Node2D
	var predicted_position := target_node.global_position + _get_marine_dash_target_velocity() * (marine_dash_prediction_time + 0.14 * _marine_dash_charge_ratio)
	var predicted_direction := (predicted_position - global_position).normalized()
	if predicted_direction.length_squared() > 0.0001:
		_marine_dash_direction = predicted_direction
		_last_move_direction = predicted_direction
		_marine_dash_target_lock_done = true
		if _marine_dash_warning_line != null:
			_marine_dash_warning_line.width = 3.0
			_marine_dash_warning_line.default_color = Color(1.0, 0.32, 0.08, 0.78)


func _start_marine_dash_reset(back_away: bool) -> void:
	if target == null or not is_instance_valid(target) or not (target is Node2D):
		return
	var to_target := ((target as Node2D).global_position - global_position).normalized()
	if to_target.length_squared() <= 0.0001:
		to_target = _last_move_direction.normalized()
	_marine_dash_reset_side *= -1.0
	var lateral := Vector2(-to_target.y, to_target.x) * _marine_dash_reset_side
	_marine_dash_reset_direction = (lateral * 0.82 - to_target * (0.58 if back_away else 0.18)).normalized()
	_marine_dash_reset_timer = maxf(_marine_dash_reset_timer, marine_dash_reset_time * (0.75 if back_away else 1.0))


func _update_marine_dash_reset(delta: float) -> bool:
	if _marine_dash_reset_timer <= 0.0 or _stagger_timer > 0.0 or _recoil_timer > 0.0:
		return false
	_marine_dash_reset_timer = maxf(0.0, _marine_dash_reset_timer - delta)
	velocity = _marine_dash_reset_direction * marine_dash_reset_speed
	move_and_slide()
	_last_move_direction = _marine_dash_reset_direction
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, true)
	return true


func _set_marine_dash_animation_speed(speed_scale: float) -> void:
	if animated_sprite != null:
		animated_sprite.speed_scale = speed_scale
	if custom_enemy_fx_sprite != null:
		custom_enemy_fx_sprite.speed_scale = speed_scale


func get_marine_dash_debug_state() -> Dictionary:
	return {
		"phase": String(_marine_dash_phase),
		"charge_ratio": _marine_dash_charge_ratio,
		"distance_share": _marine_dash_distance_share,
		"damage_share": 1.0 - _marine_dash_distance_share,
		"distance": _marine_dash_current_distance,
		"damage": _marine_dash_current_damage,
		"target_locked": _marine_dash_target_lock_done,
		"reset_timer": _marine_dash_reset_timer,
	}


func _log_marine_dash_event(event_name: StringName) -> void:
	var data := get_marine_dash_debug_state()
	data["enemy"] = enemy_name
	data["position"] = global_position
	data["target"] = target.name if target != null and is_instance_valid(target) else ""
	if target is Node2D:
		data["target_position"] = (target as Node2D).global_position
	_obs_log(event_name, data)

func _refresh_target():
	if passive:
		target = null
		return
	if _assault_state == AssaultState.STAGING or _assault_state == AssaultState.REGROUP:
		target = null
		return
	target = _find_best_target()

func _find_best_target() -> Node2D:
	var best: Node2D = null
	var best_priority := 999
	var best_distance := INF
	var groups: Array = OBJECTIVE_GROUPS.get(attack_objective, OBJECTIVE_GROUPS["breach_command"])
	for group_name in groups:
		var priority = int(TARGET_PRIORITY.get(group_name, 999))
		for candidate in get_tree().get_nodes_in_group(group_name):
			if not (candidate is Node2D):
				continue
			var node = candidate as Node2D
			if _is_target_destroyed(node):
				continue
			var dist = global_position.distance_to(node.global_position)
			if group_name != "player" and dist > detection_range:
				continue
			if priority < best_priority or (priority == best_priority and dist < best_distance):
				best = node
				best_priority = priority
				best_distance = dist
	if best == null:
		best = _find_nearest_ambient_critter_target()
	return best


func _find_nearest_ambient_critter_target() -> Node2D:
	if passive:
		return null
	var nearest: Node2D = null
	var nearest_dist := ambient_critter_target_range
	for candidate in get_tree().get_nodes_in_group("ambient_critter"):
		if not (candidate is Node2D):
			continue
		var node := candidate as Node2D
		if node == self or _is_target_destroyed(node):
			continue
		var dist := global_position.distance_to(node.global_position)
		if dist <= nearest_dist:
			nearest = node
			nearest_dist = dist
	return nearest

func _is_target_destroyed(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return true
	if node.has_method("is_dead"):
		return bool(node.is_dead())
	return false

func _get_attack_range(node: Node2D) -> float:
	if _variant_profile != null:
		return float(_variant_profile.get("attack_range"))
	if _should_use_grunt_falcon_punch_attack() and _should_start_grunt_falcon_punch_now(node):
		return grunt_falcon_punch_launch_band_max
	if _should_use_marine_dash_attack() and node.is_in_group("player"):
		return marine_dash_launch_band_max
	if node.is_in_group("player"):
		return 40.0
	return structure_attack_range


func _limit_pursuit_inward_velocity(target_position: Vector2, stop_distance: float, delta: float) -> void:
	# Character bodies own their movement. Cap only the inward component so a
	# pursuit step cannot cross the attack boundary and press into a locked target.
	var to_target := target_position - global_position
	var distance := to_target.length()
	if distance <= 0.0001 or delta <= 0.0:
		velocity = Vector2.ZERO
		return
	var toward_target := to_target / distance
	var inward_speed := velocity.dot(toward_target)
	if inward_speed <= 0.0:
		return
	var max_inward_speed := maxf(0.0, (distance - maxf(0.0, stop_distance)) / delta)
	if inward_speed > max_inward_speed:
		velocity -= toward_target * (inward_speed - max_inward_speed)


func get_behavior_attack_range() -> float:
	if _should_use_savage_attacks():
		return savage_pounce_launch_band_max if savage_pounce_enabled and _savage_pounce_cooldown_timer <= 0.0 else 40.0
	if _should_use_grunt_falcon_punch_attack() and target is Node2D and _should_start_grunt_falcon_punch_now(target as Node2D):
		return grunt_falcon_punch_launch_band_max
	if _should_use_marine_dash_attack():
		return marine_dash_launch_band_max
	return 40.0


func apply_variant(profile: Resource) -> void:
	if profile == null:
		return
	_variant_profile = profile
	_variant_behavior_id = String(profile.get("behavior_id"))
	_variant_attack_profile_id = String(profile.get("attack_profile_id"))
	_variant_special_profile_id = String(profile.get("special_profile_id"))
	enemy_name = String(profile.get("display_name"))
	max_health = float(profile.get("max_health"))
	health = max_health
	speed = float(profile.get("move_speed"))
	damage = float(profile.get("attack_damage"))
	damage_interval = float(profile.get("attack_cooldown"))
	structure_attack_range = float(profile.get("attack_range"))
	detection_range = float(profile.get("detection_radius"))
	base_tint = Color(profile.get("primary_tint"))
	if profile.get("archetype_id") == "wolf":
		_apply_wolf_variant_visuals(profile)
	_apply_variant_collision(profile)
	update_visuals()


func get_variant_summary() -> Dictionary:
	if _variant_profile == null:
		return {}
	if _variant_profile.has_method("get_debug_summary"):
		return _variant_profile.call("get_debug_summary")
	return {
		"display_name": enemy_name,
		"behavior_id": _variant_behavior_id,
		"attack_profile_id": _variant_attack_profile_id,
		"special_profile_id": _variant_special_profile_id,
	}


func _apply_wolf_variant_visuals(profile: Resource) -> void:
	_uses_procedural_variant_visuals = true
	uses_directional_charset = false
	custom_ambient_animation_enabled = false
	if visual == null and has_node("Visual"):
		visual = get_node("Visual")
	if visual:
		visual.visible = false
	if animated_sprite == null and has_node("AnimatedSprite2D"):
		animated_sprite = get_node("AnimatedSprite2D")
	if animated_sprite == null:
		return
	animated_sprite.visible = true
	animated_sprite.sprite_frames = WOLF_ANIMATION_LIBRARY.get_wolf_sprite_frames()
	animated_sprite.position = Vector2(0.0, -12.0)
	animated_sprite.scale = Vector2(profile.get("body_scale"))
	animated_sprite.speed_scale = float(profile.get("animation_speed_scale"))
	animated_sprite.flip_h = false
	_base_sprite_scale = animated_sprite.scale
	var material := ShaderMaterial.new()
	material.shader = ENEMY_PALETTE_SHADER
	material.set_shader_parameter("primary_tint", Color(profile.get("primary_tint")))
	material.set_shader_parameter("glow_tint", Color(profile.get("glow_color")))
	material.set_shader_parameter("glow_strength", float(profile.get("glow_strength")))
	material.set_shader_parameter("contrast_boost", float(profile.get("contrast_boost")))
	animated_sprite.material = material
	_play_animation(String(WOLF_IDLE_ANIMATION), false)


func _apply_variant_collision(profile: Resource) -> void:
	var collision_radius := float(profile.get("collision_radius"))
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = collision_radius
	collision_shape.shape = circle


func _get_pathfinding_direction(target_pos: Vector2, delta: float) -> Vector2:
	# Refresh path periodically
	path_refresh_timer -= delta
	_stuck_repath_cooldown_timer = maxf(0.0, _stuck_repath_cooldown_timer - delta)
	if path_refresh_timer <= 0.0 or current_path.is_empty():
		path_refresh_timer = path_refresh_interval
		_refresh_path(target_pos)
	
	# If no valid path, move directly toward target
	if current_path.is_empty():
		return (target_pos - global_position).normalized()
	
	# Follow path waypoints
	return _get_direction_along_path(target_pos)


func _update_stuck_reroute(target_pos: Vector2, delta: float) -> void:
	if not stuck_reroute_enabled or not use_pathfinding or navigation_system == null:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var attempted_distance := velocity.length() * delta
	if attempted_distance <= 0.01:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var moved_distance := global_position.distance_to(_last_movement_probe_position)
	_last_movement_probe_position = global_position
	var blocked_by_collision := get_slide_collision_count() > 0
	var stalled := moved_distance < attempted_distance * stuck_progress_ratio_threshold
	if blocked_by_collision or stalled:
		_stuck_reroute_timer += delta
	else:
		_stuck_reroute_timer = 0.0
	if _stuck_reroute_timer < stuck_reroute_delay:
		return
	if _stuck_repath_cooldown_timer > 0.0:
		return
	_stuck_reroute_timer = 0.0
	_stuck_repath_cooldown_timer = stuck_repath_cooldown
	current_path = PackedVector2Array()
	path_follow_index = 0
	path_refresh_timer = path_refresh_interval
	_refresh_path(target_pos)


func _update_passive_obstacle_recovery(delta: float) -> void:
	if not stuck_reroute_enabled:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var attempted_distance := velocity.length() * delta
	if attempted_distance <= 0.01:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var moved_distance := global_position.distance_to(_last_movement_probe_position)
	_last_movement_probe_position = global_position
	var blocked_by_collision := get_slide_collision_count() > 0
	var stalled := moved_distance < attempted_distance * stuck_progress_ratio_threshold
	if blocked_by_collision or stalled:
		_stuck_reroute_timer += delta
	else:
		_stuck_reroute_timer = 0.0
	if _stuck_reroute_timer >= stuck_reroute_delay:
		_stuck_reroute_timer = 0.0
		_choose_next_passive_destination()


func _refresh_path(target_pos: Vector2) -> void:
	if navigation_system == null:
		current_path = PackedVector2Array()
		return
	
	var path = navigation_system.get_path_to_target(global_position, target_pos)
	
	# Filter out points too close to current position
	if not path.is_empty():
		# Skip first point if it's behind us
		while path.size() > 1 and global_position.distance_squared_to(path[0]) < path_tolerance * path_tolerance:
			path.remove_at(0)
	
	current_path = path
	path_follow_index = 0


func _get_direction_along_path(target_pos: Vector2) -> Vector2:
	if current_path.is_empty():
		return (target_pos - global_position).normalized()
	
	# Find the next reachable waypoint
	while path_follow_index < current_path.size() - 1:
		var waypoint = current_path[path_follow_index]
		if global_position.distance_to(waypoint) <= path_tolerance:
			path_follow_index += 1
		else:
			break
	
	# Get target waypoint
	var target_waypoint: Vector2
	if path_follow_index < current_path.size():
		target_waypoint = current_path[path_follow_index]
	else:
		target_waypoint = target_pos
	
	var direction = (target_waypoint - global_position).normalized()
	
	# If close to final waypoint and has direct line to actual target, switch to direct
	if path_follow_index >= current_path.size() - 1:
		var dist_to_target = global_position.distance_to(target_pos)
		if dist_to_target < path_tolerance * 3.0:
			current_path = PackedVector2Array()  # Clear path, go direct
	
	return direction


func has_valid_path() -> bool:
	return not current_path.is_empty()


func get_path_remaining() -> int:
	return max(0, current_path.size() - path_follow_index)


func get_current_path() -> PackedVector2Array:
	return current_path


func get_navigation_target() -> Node:
	return target


func clear_path() -> void:
	current_path = PackedVector2Array()
	path_follow_index = 0

func apply_difficulty_modifiers(hp_scale: float, damage_scale: float):
	max_health = max(1.0, max_health * hp_scale)
	health = max(1.0, health * hp_scale)
	damage = max(1.0, damage * damage_scale)
	update_visuals()

func take_damage(
	amount: float,
	hit_strength: int = CombatConstants.HitStrength.LIGHT,
	reaction_damage: float = -1.0
) -> Dictionary:
	var health_before := maxf(0.0, health)
	if dead or health_before <= 0.0:
		return _damage_result(0.0, false)

	var applied_damage := minf(maxf(0.0, amount), health_before)
	if applied_damage <= 0.0:
		return _damage_result(0.0, true)
	health = maxf(0.0, health_before - applied_damage)
	_cancel_savage_attack()
	if behavior_state_machine != null and behavior_state_machine.has_method("on_damaged"):
		behavior_state_machine.call(
			"on_damaged",
			self,
			applied_damage
		)
	_on_assault_damage_taken(applied_damage)
	_apply_reaction(
		reaction_damage if reaction_damage >= 0.0 else applied_damage,
		hit_strength
	)
	update_visuals()
	_spawn_damage_popup(applied_damage)
	
	if visual:
		visual.modulate = Color(1, 1, 1)  # Flash white
		get_tree().create_timer(0.1).timeout.connect(
			func() -> void:
				if is_instance_valid(self) and not dead:
					update_visuals()
		)
	
	if health <= 0:
		die()
	return _damage_result(applied_damage, true)


func get_melee_impact_audio_profile(_hit_strength: int) -> StringName:
	return StringName(melee_impact_audio_profile)


func _damage_result(
	applied_damage: float,
	target_was_alive: bool
) -> Dictionary:
	var safe_applied := maxf(0.0, applied_damage)
	var health_after := maxf(0.0, health)
	return {
		"applied_damage": safe_applied,
		"damage_applied": safe_applied,
		"target_was_alive": target_was_alive,
		"target_health_before": health_after + safe_applied,
		"target_health_after": health_after,
		"lethal": dead or health <= 0.0,
		"blocked": false,
		"eligible_hostile": (
			team == "enemy"
			and not passive
		),
		"passive": passive,
		"structure": false,
		"deflected": false,
		"invulnerable": false,
	}

func update_visuals():
	if health_bar:
		health_bar.value = (health / max_health) * 100.0
		
		var health_pct = health / max_health
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style:
			if health_pct > 0.6:
				fill_style.bg_color = Color(0.2, 0.85, 0.3, 1.0)
			elif health_pct > 0.3:
				fill_style.bg_color = Color(0.85, 0.7, 0.2, 1.0)
			else:
				fill_style.bg_color = Color(0.9, 0.25, 0.2, 1.0)
	
	if visual:
		var health_pct = health / max_health
		if health_pct > 0.5:
			visual.modulate = base_tint
		elif health_pct > 0.2:
			visual.modulate = base_tint.lerp(Color(1.0, 0.65, 0.25, 1.0), 0.35)
		else:
			visual.modulate = base_tint.darkened(0.35)

func die():
	if life_state != LifeState.ALIVE:
		return
	life_state = LifeState.DYING
	dead = true
	velocity = Vector2.ZERO
	_pending_corpse_payload = _build_corpse_payload_once()
	_play_enemy_death_sfx()
	_cancel_pending_attack_with_result(&"cancelled_by_death", &"death")
	_clear_grunt_critical_open_vfx(false)
	_release_parry_critical_execution_owner()
	_parry_critical_phase = ParryCriticalPhase.NONE
	_parry_critical_standalone_root_valid = false
	if not _grunt_falcon_punch_phase.is_empty():
		_obs_increment(&"enemy_attack_interrupted_by_death")
		_obs_increment(&"falcon_punch_cancelled")
	_finish_grunt_falcon_punch_attack(&"cancelled_by_death")
	if behavior_state_machine != null and behavior_state_machine.has_method("on_enemy_died"):
		behavior_state_machine.call("on_enemy_died", self)
	set_threat_highlight(false)
	_disable_live_enemy_runtime()
	var camera = get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera and camera.has_method("on_enemy_killed"):
		camera.call("on_enemy_killed")
	var game_stats := get_node_or_null("/root/GameStats")
	if game_stats != null and game_stats.has_method("record_enemy_destroyed"):
		game_stats.call("record_enemy_destroyed", enemy_name)
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		_obs_increment(&"enemies_destroyed", 1)
		_obs_log(&"enemy_killed", {
			"enemy": enemy_name,
			"position": global_position,
		})
	_report_material_contact(
		global_position,
		&"enemy_death",
		{"enemy": enemy_name}
	)
	var world_history := get_node_or_null("/root/WorldHistory")
	if world_history != null:
		world_history.call("record", "", "enemy_killed", global_position, {
			"enemy": enemy_name,
		})
	print("ENEMY DESTROYED: ", enemy_name)
	enemy_died.emit(self)
	if _uses_humanoid_cutout_backend() and humanoid_cutout_rig.has_state(&"death"):
		call_deferred("_play_humanoid_cutout_death")
		return
	if _uses_procedural_variant_animation_set() and _has_animation(String(WOLF_DEATH_ANIMATION)):
		call_deferred("_play_procedural_variant_death")
		return
	if _uses_custom_ambient_animation_set() and _has_animation(String(CUSTOM_AMBIENT_KO_ANIMATION)):
		call_deferred("_play_custom_ambient_knockout")
		return
	if custom_enemy_animation_set == String(CUSTOM_ENEMY_GRUNT) and _has_animation(String(GRUNT_DEATH_ANIMATION)):
		call_deferred("_play_grunt_death")
		return
	call_deferred("_finalize_corpse_state")


func _play_humanoid_cutout_death() -> void:
	if humanoid_cutout_rig == null or not humanoid_cutout_rig.has_state(&"death"):
		_finalize_corpse_state()
		return
	humanoid_cutout_rig.play_state(&"death", true)
	await humanoid_cutout_rig.state_finished
	if is_instance_valid(self):
		_finalize_corpse_state()


func is_passive_enemy() -> bool:
	return passive


func _get_dev_observatory() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/DevObservatory")


func _report_material_contact(
	position: Vector2,
	contact_kind: StringName,
	data: Dictionary = {}
) -> void:
	var material_intelligence := get_node_or_null(
		"/root/MaterialIntelligence"
	)
	if material_intelligence != null \
	and material_intelligence.has_method("report_contact"):
		material_intelligence.call(
			"report_contact",
			position,
			contact_kind,
			data
		)


func _obs_log(kind: StringName, data: Dictionary = {}) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", String(kind), data)
	_record_heatmap_event(kind, data)


func _record_heatmap_event(kind: StringName, data: Dictionary) -> void:
	var event_position := data.get("position", global_position) as Vector2
	if kind == &"enemy_killed":
		_heatmap_add(&"enemy_killed", 3.0, event_position)
		return

	if kind == &"enemy_attack_whiff":
		_heatmap_add(&"enemy_attack_whiff", 0.5, event_position)
		return

	if kind not in [
		&"enemy_attack_resolved",
		&"grunt_falcon_punch_hit_resolved",
	]:
		return

	var result := StringName(str(data.get("result", "")))
	if result == &"whiffed":
		_heatmap_add(&"enemy_attack_whiff", 0.5, event_position)
	elif result == &"damaged":
		_heatmap_add(
			&"enemy_attack_hit",
			maxf(float(data.get("applied_damage", 0.0)), 1.0),
			event_position
		)
	elif result in [&"blocked", &"parried", &"dodged"]:
		_heatmap_add(
			StringName("enemy_attack_%s" % String(result)),
			1.0,
			event_position
		)


func _heatmap_add(
	event_type: StringName,
	weight: float = 1.0,
	position: Vector2 = global_position
) -> void:
	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap != null and heatmap.has_method("add"):
		heatmap.call("add", position, event_type, weight)


func _obs_increment(counter_name: StringName, amount: int = 1) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("increment"):
		observatory.call("increment", String(counter_name), amount)


func _assault_state_name(state: int) -> String:
	match state:
		AssaultState.STAGING:
			return "staging"
		AssaultState.PROBING:
			return "probing"
		AssaultState.COMMIT:
			return "commit"
		AssaultState.REGROUP:
			return "regroup"
		_:
			return "unknown"


func set_simulation_tier(tier: String) -> void:
	if simulation_tier == tier:
		return
	simulation_tier = tier
	if simulation_tier == "dormant":
		velocity = Vector2.ZERO
		set_physics_process(false)
	else:
		set_physics_process(true)
	_obs_log(&"enemy_simulation_tier_changed", {
		"enemy": enemy_name,
		"position": global_position,
		"tier": simulation_tier,
		"behavior_profile": String(behavior_profile_id),
		"passive": passive,
	})
	_obs_increment(StringName("enemy_sim_tier_%s" % simulation_tier), 1)


func counts_for_wave_cap() -> bool:
	return counts_as_wave_enemy and not passive


func set_behavior_profile(profile_id: Variant) -> void:
	behavior_profile_id = StringName(str(profile_id))
	behavior_state_machine_enabled = true
	add_to_group("enemy_behavior_agent")
	_ensure_behavior_components()
	if behavior_state_machine != null and behavior_state_machine.has_method("setup_profile"):
		behavior_state_machine.call("setup_profile", behavior_profile_id)
	_obs_log(&"enemy_behavior_profile_set", {
		"enemy": enemy_name,
		"profile_id": String(behavior_profile_id),
		"position": global_position,
	})


func get_behavior_snapshot() -> Dictionary:
	if behavior_state_machine != null and behavior_state_machine.has_method("get_debug_snapshot"):
		return behavior_state_machine.call("get_debug_snapshot")
	return {
		"enabled": behavior_state_machine_enabled,
		"profile_id": String(behavior_profile_id),
		"state": "legacy",
		"carrying_loot": false,
	}


func is_carrying_stolen_resources() -> bool:
	var carrier := get_node_or_null("EnemyLootCarrier")
	return carrier != null and carrier.has_method("is_carrying_loot") and bool(carrier.call("is_carrying_loot"))


func force_behavior_notice() -> void:
	_ensure_behavior_components()
	if behavior_state_machine != null and behavior_state_machine.has_method("force_notice"):
		behavior_state_machine.call("force_notice", get_tree().get_first_node_in_group("player"))
	_obs_log(&"enemy_behavior_force_notice", {
		"enemy": enemy_name,
		"profile_id": String(behavior_profile_id),
		"position": global_position,
	})


func force_behavior_steal() -> void:
	_ensure_behavior_components()
	if behavior_state_machine != null and behavior_state_machine.has_method("force_steal"):
		behavior_state_machine.call("force_steal")
	_obs_log(&"enemy_behavior_force_steal", {
		"enemy": enemy_name,
		"profile_id": String(behavior_profile_id),
		"position": global_position,
	})


func get_last_move_direction() -> Vector2:
	return _last_move_direction


func behavior_stop() -> void:
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func behavior_move_toward(target_position: Vector2, desired_speed: float) -> void:
	var direction := Vector2.ZERO
	if use_pathfinding and navigation_system != null and navigation_system.has_method("get_path_to_target"):
		direction = _get_pathfinding_direction(target_position, get_physics_process_delta_time())
	else:
		direction = (target_position - global_position).normalized()
	if direction.length_squared() <= 0.0001:
		behavior_stop()
		return
	direction = _apply_enemy_spacing_to_direction(direction)
	velocity = direction * desired_speed
	move_and_slide()
	_update_stuck_reroute(target_position, get_physics_process_delta_time())
	_last_move_direction = direction
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, true)


func _apply_enemy_spacing_to_direction(direction: Vector2) -> Vector2:
	if direction.length_squared() <= 0.0001 or enemy_spacing_radius_px <= 0.0 or enemy_spacing_strength <= 0.0:
		return direction
	var separation := _get_enemy_separation_vector(enemy_spacing_radius_px)
	if separation.length_squared() <= 0.0001:
		return direction
	return (direction.normalized() + separation * enemy_spacing_strength).normalized()


func _get_enemy_separation_vector(radius_px: float = 34.0) -> Vector2:
	var push := Vector2.ZERO
	var radius := maxf(0.01, radius_px)
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if candidate == self or not (candidate is Node2D):
			continue
		var other := candidate as Node2D
		if _is_target_destroyed(other):
			continue
		var delta := global_position - other.global_position
		var distance := delta.length()
		if distance > radius:
			continue
		if distance <= 0.001:
			var self_path := String(get_path())
			var other_path := String(other.get_path())
			delta = Vector2.LEFT if self_path < other_path else Vector2.RIGHT
			distance = 0.0
		push += delta.normalized() * ((radius - distance) / radius)
	return push


func behavior_attack_target() -> void:
	if target == null:
		behavior_stop()
		return
	behavior_stop()
	var direction := ((target as Node2D).global_position - global_position).normalized() if target is Node2D else Vector2.ZERO
	if direction.length_squared() > 0.0001:
		_last_move_direction = direction
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)
	_attack_target(get_physics_process_delta_time())


func _ensure_behavior_components() -> void:
	if get_node_or_null("EnemyBlackboard") == null:
		var blackboard: Node = ENEMY_BLACKBOARD_SCRIPT.new()
		blackboard.name = "EnemyBlackboard"
		add_child(blackboard)
	if get_node_or_null("EnemyPerceptionComponent") == null:
		var perception: Node = ENEMY_PERCEPTION_SCRIPT.new()
		perception.name = "EnemyPerceptionComponent"
		add_child(perception)
	if get_node_or_null("EnemyObjectiveSensor") == null:
		var sensor: Node = ENEMY_OBJECTIVE_SENSOR_SCRIPT.new()
		sensor.name = "EnemyObjectiveSensor"
		add_child(sensor)
	if get_node_or_null("EnemyLootCarrier") == null:
		var carrier: Node = ENEMY_LOOT_CARRIER_SCRIPT.new()
		carrier.name = "EnemyLootCarrier"
		add_child(carrier)
	if get_node_or_null("EnemyBehaviorStateMachine") == null:
		var state_machine: Node = ENEMY_BEHAVIOR_STATE_MACHINE_SCRIPT.new()
		state_machine.name = "EnemyBehaviorStateMachine"
		add_child(state_machine)
	behavior_state_machine = get_node_or_null("EnemyBehaviorStateMachine")


func set_passive_home_position(home_position: Vector2) -> void:
	_spawn_position = home_position
	_passive_home_initialized = true
	_passive_target_position = home_position
	clear_path()


func _update_passive_behavior(delta: float) -> void:
	target = null
	if not _passive_home_initialized:
		set_passive_home_position(global_position)
	_passive_wander_timer -= delta
	_passive_flee_timer = max(0.0, _passive_flee_timer - delta)
	_passive_flee_retarget_timer = max(0.0, _passive_flee_retarget_timer - delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		var away_from_player := global_position - player.global_position
		var player_distance := away_from_player.length()
		if player_distance <= passive_alert_radius and (_passive_flee_timer <= 0.0 or _passive_flee_retarget_timer <= 0.0):
			var flee_direction := away_from_player.normalized() if player_distance > 0.001 else Vector2.RIGHT.rotated(randf() * TAU)
			var flee_radius: float = max(passive_wander_radius, passive_alert_radius * 1.25)
			_passive_target_position = _pick_passive_destination_near_home(flee_direction, flee_radius)
			_passive_flee_timer = passive_flee_cooldown
			_passive_flee_retarget_timer = passive_flee_retarget_interval
	var to_target := _passive_target_position - global_position
	if to_target.length() > 6.0:
		var move_direction := to_target.normalized()
		var move_speed := speed * (passive_flee_speed_multiplier if _passive_flee_timer > 0.0 else 1.0)
		velocity = move_direction * move_speed
		move_and_slide()
		_update_passive_obstacle_recovery(delta)
		_last_move_direction = move_direction
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, true)
		return

	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)
	if _passive_flee_timer > 0.0:
		return
	if _passive_wander_timer <= 0.0:
		_choose_next_passive_destination()


func _schedule_next_passive_wander() -> void:
	_passive_wander_timer = randf_range(
		min(passive_wander_interval_min, passive_wander_interval_max),
		max(passive_wander_interval_min, passive_wander_interval_max)
	)


func _choose_next_passive_destination() -> void:
	_schedule_next_passive_wander()
	if passive_wander_radius <= 1.0:
		_passive_target_position = _spawn_position
		return
	_passive_target_position = _pick_passive_destination_near_home()


func _pick_passive_destination_near_home(preferred_direction: Vector2 = Vector2.ZERO, preferred_distance: float = -1.0) -> Vector2:
	var fallback: Vector2 = _spawn_position
	var sample_count: int = 10
	for i in range(sample_count):
		var direction: Vector2 = preferred_direction
		if direction.length_squared() <= 0.0001 or i > 0:
			direction = Vector2.RIGHT.rotated(randf() * TAU)
		else:
			direction = direction.normalized().rotated(randf_range(-0.45, 0.45))
		var max_distance: float = maxf(12.0, passive_wander_radius)
		var distance: float = preferred_distance if preferred_distance > 0.0 and i == 0 else randf_range(12.0, max_distance)
		distance = clampf(distance, 12.0, max_distance)
		var candidate: Vector2 = _spawn_position + direction * distance
		if _is_passive_destination_valid(candidate):
			return candidate
		if i == 0:
			fallback = candidate
	return fallback


func _is_passive_destination_valid(destination: Vector2) -> bool:
	if navigation_system != null and navigation_system.has_method("is_in_walkable_area"):
		return bool(navigation_system.call("is_in_walkable_area", destination))
	return true


func _roll_legacy_material_payload() -> int:
	var drop_min: int = max(0, material_drop_min)
	var drop_max: int = max(drop_min, material_drop_max)
	if drop_max <= 0:
		return 0
	return randi_range(drop_min, drop_max)


func _roll_loot_table_payload() -> Dictionary:
	var rolled := {}
	if loot_table.is_empty():
		return rolled
	for entry in loot_table:
		if not (entry is Dictionary):
			continue
		var resource_id := str(entry.get("resource_id", entry.get("id", ""))).strip_edges()
		if resource_id.is_empty():
			continue
		var chance := clampf(float(entry.get("chance", 1.0)), 0.0, 1.0)
		if chance < 1.0 and randf() > chance:
			continue
		var min_amount: int = max(0, int(entry.get("min", entry.get("amount", 0))))
		var max_amount: int = max(min_amount, int(entry.get("max", min_amount)))
		if max_amount <= 0:
			continue
		var amount := randi_range(min_amount, max_amount)
		if amount <= 0:
			continue
		var key := StringName(resource_id)
		rolled[key] = int(rolled.get(key, 0)) + amount
	if not rolled.is_empty():
		print("ENEMY LOOT ROLLED: ", enemy_name, " table=", loot_table_id, " drops=", rolled)
	return rolled


func _build_corpse_payload_once() -> Dictionary:
	var resource_payload := _roll_loot_table_payload()
	var vault_payload := {}
	var carrier := get_node_or_null("EnemyLootCarrier")
	if carrier != null and carrier.has_method("take_payload"):
		vault_payload = carrier.call("take_payload") as Dictionary
	var legacy_materials := 0
	# Preserve the previous fallback rule: a configured typed table suppresses
	# generic PARTS even when this particular roll produces no entries.
	if loot_table.is_empty() and material_drop_fallback_enabled:
		legacy_materials = _roll_legacy_material_payload()
	return {
		"resource_ledger": resource_payload,
		"vault_recovery": vault_payload,
		"legacy_materials": legacy_materials,
		"items": [],
	}


func _disable_live_enemy_runtime() -> void:
	target = null
	clear_path()
	use_pathfinding = false
	set_threat_highlight(false)
	remove_from_group("enemies")
	remove_from_group("enemy")
	remove_from_group("enemy_behavior_agent")
	remove_from_group("ambient_critter")
	remove_from_group("interest_managed")
	if health_bar != null:
		health_bar.visible = false
	if custom_enemy_fx_sprite != null:
		custom_enemy_fx_sprite.stop()
		custom_enemy_fx_sprite.visible = false
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if behavior_state_machine != null:
		behavior_state_machine.set_process(false)
		behavior_state_machine.set_physics_process(false)
	for component_name in ["EnemyPerceptionComponent", "EnemyObjectiveSensor", "EnemyBlackboard"]:
		var component := get_node_or_null(component_name)
		if component != null:
			component.set_process(false)
			component.set_physics_process(false)


func _finalize_corpse_state() -> void:
	if life_state != LifeState.DYING:
		return
	if _structured_payload_has_loot(_pending_corpse_payload):
		life_state = LifeState.LOOTABLE_CORPSE
		_corpse_loot = ENEMY_CORPSE_LOOT_SCRIPT.new() as EnemyCorpseLoot
		_corpse_loot.name = "CorpseLoot"
		_corpse_loot.pickup_radius_px = corpse_loot_pickup_radius_px
		_corpse_loot.marker_offset = corpse_loot_marker_offset
		add_child(_corpse_loot)
		_corpse_loot.loot_collected.connect(_on_corpse_loot_collected)
		_corpse_loot.activate(_pending_corpse_payload, _get_corpse_visual_owner())
	else:
		_enter_empty_corpse_state()
	_pending_corpse_payload.clear()


func _on_corpse_loot_collected(_payload: Dictionary) -> void:
	_enter_empty_corpse_state()


func _enter_empty_corpse_state() -> void:
	life_state = LifeState.EMPTY_CORPSE
	_empty_corpse_age_sec = 0.0
	_corpse_cleanup_timer_sec = 0.0


func _update_empty_corpse_cleanup(delta: float) -> void:
	if life_state != LifeState.EMPTY_CORPSE:
		return
	_empty_corpse_age_sec += delta
	_corpse_cleanup_timer_sec -= delta
	if _empty_corpse_age_sec >= empty_corpse_hard_lifetime_sec:
		queue_free()
		return
	if _empty_corpse_age_sec < empty_corpse_min_lifetime_sec or _corpse_cleanup_timer_sec > 0.0:
		return
	_corpse_cleanup_timer_sec = 0.5
	if _is_outside_active_camera(corpse_offscreen_margin_px):
		queue_free()


func _is_outside_active_camera(margin: float) -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	var camera := viewport.get_camera_2d()
	if camera == null:
		return false
	var half_size := viewport.get_visible_rect().size * 0.5 / camera.zoom
	var camera_rect := Rect2(camera.get_screen_center_position() - half_size, half_size * 2.0)
	return not camera_rect.grow(maxf(0.0, margin)).has_point(global_position)


func _structured_payload_has_loot(payload: Dictionary) -> bool:
	return not (payload.get("resource_ledger", {}) as Dictionary).is_empty() \
		or not (payload.get("vault_recovery", {}) as Dictionary).is_empty() \
		or int(payload.get("legacy_materials", 0)) > 0 \
		or not (payload.get("items", []) as Array).is_empty()


func _get_corpse_visual_owner() -> CanvasItem:
	if _uses_humanoid_cutout_backend() and humanoid_cutout_rig != null:
		return humanoid_cutout_rig
	if animated_sprite != null and animated_sprite.visible:
		return animated_sprite
	if visual != null:
		return visual
	return self


func _hold_animated_sprite_final_frame(animation_name: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	animated_sprite.stop()
	if frame_count > 0:
		animated_sprite.frame = frame_count - 1
		animated_sprite.frame_progress = 1.0


func _start_attack_windup(queued_damage: float, is_strong: bool) -> void:
	if _should_use_grunt_falcon_punch_attack() and target is Node2D and target.is_in_group("player"):
		_grunt_falcon_punch_normal_attacks_since_special += 1
		_grunt_falcon_punch_decision_credit = minf(2.0, _grunt_falcon_punch_decision_credit + clampf(grunt_falcon_punch_chance, 0.0, 1.0))
	_pending_attack_damage = queued_damage
	_attack_sequence += 1
	_pending_attack_id = "%s:%s" % [get_instance_id(), _attack_sequence]
	_attack_windup_timer = max(0.01, attack_windup_duration)
	_windup_attack_is_strong = is_strong
	_capture_pending_attack_context()
	_obs_increment(&"enemy_attack_windups", 1)
	_obs_log(&"enemy_attack_windup", {
		"enemy": enemy_name,
		"position": global_position,
		"damage": queued_damage,
		"attack_id": _pending_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": target.get_instance_id() if target != null and is_instance_valid(target) else 0,
		"is_strong": is_strong,
		"attack_objective": attack_objective,
		"target": target.name if target != null and is_instance_valid(target) else "",
		"range_px": _pending_attack_range_px,
		"arc_degrees": _pending_attack_arc_degrees,
	})
	velocity = Vector2.ZERO
	if _uses_humanoid_cutout_backend():
		humanoid_cutout_rig.set_facing_vector(_last_move_direction)
		_play_cutout_presentation_state(&"attack_light", true)
	elif _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(_last_move_direction, false, true)
	elif _uses_procedural_variant_animation_set():
		_update_procedural_variant_animation(_last_move_direction, false, true)
	elif _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _capture_pending_attack_context() -> void:
	_pending_attack_range_px = 40.0
	_pending_attack_arc_degrees = melee_hit_arc_degrees

	if target is Node2D:
		var target_node := target as Node2D
		_pending_attack_range_px = _get_attack_range(target_node)

		var to_target := target_node.global_position - global_position
		if to_target.length_squared() > 0.0001:
			_pending_attack_forward = to_target.normalized()
			return

	if _last_move_direction.length_squared() > 0.0001:
		_pending_attack_forward = _last_move_direction.normalized()
	else:
		_pending_attack_forward = Vector2.DOWN


func _update_attack_windup(delta: float) -> bool:
	if _attack_windup_timer <= 0.0:
		return false
	_attack_windup_timer = max(0.0, _attack_windup_timer - delta)
	velocity = Vector2.ZERO
	if _attack_windup_timer > 0.0:
		return true
	_execute_queued_attack()
	return true


func _execute_queued_attack() -> void:
	if dead:
		_cancel_pending_attack_with_result(&"cancelled_by_death", &"death")
		return
	_obs_log(&"enemy_attack_active", {
		"attack_id": _pending_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": target.get_instance_id() if target != null and is_instance_valid(target) else 0,
		"attack_type": "melee",
		"phase": "active",
		"enemy": enemy_name,
	})
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		_obs_increment(&"enemy_attack_cancelled_no_target", 1)
		_obs_log(&"enemy_attack_cancelled", {
			"attack_id": _pending_attack_id,
			"attacker_id": get_instance_id(),
			"target_id": 0,
			"attack_type": "melee",
			"phase": "active",
			"result": "interrupted",
			"enemy": enemy_name,
			"reason": "no_target",
			"position": global_position,
		})
		_clear_pending_attack_context()
		return

	var target_node := target as Node2D if target is Node2D else null
	if target_node == null:
		_obs_increment(&"enemy_attack_cancelled_no_target", 1)
		_obs_log(&"enemy_attack_cancelled", {
			"attack_id": _pending_attack_id,
			"attacker_id": get_instance_id(),
			"target_id": 0,
			"attack_type": "melee",
			"phase": "active",
			"result": "interrupted",
			"enemy": enemy_name,
			"reason": "target_not_node2d",
			"position": global_position,
		})
		_clear_pending_attack_context()
		return

	var miss_reason := _get_pending_attack_miss_reason(target_node)
	if not miss_reason.is_empty():
		_obs_increment(&"enemy_attack_whiffs", 1)
		_obs_increment(&"enemy_attack_result_whiffed", 1)
		var whiff_counter_suffix := "out_of_range" if miss_reason == &"target_out_of_range" else "out_of_arc"
		_obs_increment(StringName("enemy_attack_whiffed_%s" % whiff_counter_suffix), 1)
		_obs_log(&"enemy_attack_whiff", {
			"attack_id": _pending_attack_id,
			"attacker_id": get_instance_id(),
			"target_id": target_node.get_instance_id(),
			"enemy": enemy_name,
			"attack_type": "melee",
			"phase": "active",
			"result": "whiffed",
			"reason": String(miss_reason),
			"position": global_position,
			"target": target_node.name,
			"target_position": target_node.global_position,
			"queued_damage": _pending_attack_damage,
			"range_px": _pending_attack_range_px,
			"arc_degrees": _pending_attack_arc_degrees,
		})
		_clear_pending_attack_context()
		return

	var hit_result := _apply_enemy_hit_to_target(target_node, _pending_attack_damage, &"melee")
	_obs_increment(&"enemy_attacks_resolved", 1)
	_obs_log(&"enemy_attack_resolved", {
		"attack_id": _pending_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": target_node.get_instance_id(),
		"enemy": enemy_name,
		"attack_type": "melee",
		"phase": "resolved",
		"position": global_position,
		"target": target_node.name,
		"target_position": target_node.global_position,
		"result": String(hit_result.get("result", "")),
		"hit_kind": String(hit_result.get("hit_kind", "")),
		"applied_damage": float(hit_result.get("applied_damage", 0.0)),
		"damage_attempted": _pending_attack_damage,
		"target_health_before": hit_result.get("target_health_before", null),
		"target_health_after": hit_result.get("target_health_after", null),
		"dodged": bool(hit_result.get("dodged", false)),
		"blocked": bool(hit_result.get("blocked", false)),
		"parried": bool(hit_result.get("parried", false)),
	})
	var result_name := String(hit_result.get("result", "unknown"))
	_obs_increment(StringName("enemy_attack_result_%s" % result_name), 1)
	if bool(hit_result.get("dodged", false)) or bool(hit_result.get("parried", false)):
		pass  # clean whiff
	elif bool(hit_result.get("blocked", false)):
		pass  # blocked, handled by receiver
	elif float(hit_result.get("applied_damage", 0.0)) > 0.0:
		print("Enemy hit ", target.name, " for ", hit_result.get("applied_damage", 0.0), " damage!")
	_clear_pending_attack_context()


func _clear_pending_attack_context() -> void:
	_pending_attack_damage = 0.0
	_windup_attack_is_strong = false
	_pending_attack_forward = Vector2.DOWN
	_pending_attack_range_px = 0.0
	_pending_attack_arc_degrees = melee_hit_arc_degrees
	_pending_attack_id = ""


func _cancel_pending_attack_with_result(result: StringName, reason: StringName) -> void:
	if _pending_attack_id.is_empty():
		_clear_pending_attack_context()
		return
	_obs_log(&"enemy_attack_resolved", {
		"attack_id": _pending_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": target.get_instance_id() if target != null and is_instance_valid(target) else 0,
		"attack_type": "melee",
		"phase": "cancelled",
		"result": String(result),
		"reason": String(reason),
		"enemy": enemy_name,
		"position": global_position,
	})
	_obs_increment(StringName("enemy_attack_result_%s" % String(result)), 1)
	if result == &"cancelled_by_death":
		_obs_increment(&"enemy_attack_interrupted_by_death")
	elif reason == &"parry":
		_obs_increment(&"enemy_attack_interrupted_by_parry")
	_clear_pending_attack_context()


func _can_pending_attack_connect(target_node: Node2D) -> bool:
	return _get_pending_attack_miss_reason(target_node).is_empty()


func _get_pending_attack_miss_reason(target_node: Node2D) -> StringName:
	if _pending_attack_range_px <= 0.0:
		_pending_attack_range_px = _get_attack_range(target_node)

	var grace_range := _pending_attack_range_px * melee_hit_range_grace_multiplier + melee_hit_range_grace_px
	var distance := global_position.distance_to(target_node.global_position)
	if distance > grace_range:
		return &"target_out_of_range"

	var to_target := (target_node.global_position - global_position).normalized()
	var dot := _pending_attack_forward.dot(to_target)
	var angle_rad := deg_to_rad(_pending_attack_arc_degrees * 0.5)
	if dot < cos(angle_rad):
		return &"target_out_of_arc"

	return &""


func _apply_enemy_hit_to_target(
	hit_node: Node,
	amount: float,
	hit_kind: StringName = &"melee",
	guard_stamina_cost_override: float = -1.0,
	attack_id_override: String = ""
) -> Dictionary:
	if hit_node == null or not is_instance_valid(hit_node):
		return {
			"result": &"no_target",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"parried": false,
			"applied_damage": 0.0,
		}

	var hit_direction := Vector2.ZERO
	if hit_node is Node2D:
		hit_direction = global_position.direction_to((hit_node as Node2D).global_position)

	var attack_context := {
		"attack_id": attack_id_override if not attack_id_override.is_empty() else _pending_attack_id,
		"attacker_id": get_instance_id(),
		"target_id": hit_node.get_instance_id(),
		"damage_attempted": amount,
		"hit_strength": _resolve_hit_strength_for_attack(hit_kind, amount),
		"damage_type": CombatConstants.DamageType.PHYSICAL,
	}

	if not hit_node.has_method("receive_enemy_hit") and hit_node.has_method("try_parry_incoming_attack"):
		var parry_result: Variant = hit_node.call("try_parry_incoming_attack", self, hit_direction, {"damage": amount, "hit_kind": hit_kind})
		if bool(parry_result):
			return {
				"result": &"parried",
				"hit_kind": hit_kind,
				"dodged": false,
				"blocked": false,
				"parried": true,
				"applied_damage": 0.0,
			}

	if hit_node.has_method("receive_enemy_hit"):
		var result: Variant
		var supports_attack_context := _method_argument_count(hit_node, &"receive_enemy_hit") >= 7
		if supports_attack_context and guard_stamina_cost_override >= 0.0:
			result = hit_node.call("receive_enemy_hit", amount, hit_kind, team, self, hit_direction, guard_stamina_cost_override, attack_context)
		elif supports_attack_context:
			result = hit_node.call("receive_enemy_hit", amount, hit_kind, team, self, hit_direction, -1.0, attack_context)
		elif guard_stamina_cost_override >= 0.0:
			result = hit_node.call("receive_enemy_hit", amount, hit_kind, team, self, hit_direction, guard_stamina_cost_override)
		else:
			result = hit_node.call("receive_enemy_hit", amount, hit_kind, team, self, hit_direction)
		if result is Dictionary:
			return result as Dictionary

	if hit_node.has_method("is_dodge_invulnerable") and bool(hit_node.call("is_dodge_invulnerable")):
		return {
			"result": &"dodged",
			"hit_kind": hit_kind,
			"dodged": true,
			"blocked": false,
			"parried": false,
			"applied_damage": 0.0,
		}

	if hit_node.has_method("take_damage"):
		hit_node.call("take_damage", amount)
		return {
			"result": &"damaged",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"parried": false,
			"applied_damage": max(0.0, amount),
		}

	return {
		"result": &"no_receiver",
		"hit_kind": hit_kind,
		"dodged": false,
		"blocked": false,
		"parried": false,
		"applied_damage": 0.0,
	}


func _method_argument_count(object: Object, method_name: StringName) -> int:
	for method_variant in object.get_method_list():
		var method := method_variant as Dictionary
		if StringName(str(method.get("name", ""))) == method_name:
			return (method.get("args", []) as Array).size()
	return 0


## Resolve hit strength from attack kind and damage amount.
## This is the enemy-side resolver — Operator attacks use their own resolver.
func _resolve_hit_strength_for_attack(hit_kind: StringName, amount: float) -> int:
	match hit_kind:
		&"falcon_punch":
			return CombatConstants.HitStrength.HEAVY
		&"dash":
			return CombatConstants.HitStrength.HEAVY
		&"savage_pounce":
			return CombatConstants.HitStrength.HEAVY
		&"savage_chain_heavy":
			return CombatConstants.HitStrength.HEAVY
		&"parry":
			return CombatConstants.HitStrength.INTERRUPT
		_:
			# Normal melee — use damage threshold as heuristic
			if amount >= stagger_damage_threshold:
				return CombatConstants.HitStrength.HEAVY
			return CombatConstants.HitStrength.LIGHT


func _apply_reaction(amount: float, hit_strength: int = CombatConstants.HitStrength.LIGHT) -> void:
	if _parry_critical_phase != ParryCriticalPhase.NONE:
		return

	# INTERRUPT hits always cause hit-recoil regardless of damage amount
	if hit_strength == CombatConstants.HitStrength.INTERRUPT:
		_start_hit_recoil_reaction()
		_obs_increment(&"enemy_reactions_interrupt", 1)
		return

	# Crit/stagger thresholds still apply for heavy hits and high-damage light hits
	if amount >= crit_damage_threshold:
		_start_crit_reaction()
		_obs_increment(&"enemy_reactions_crit", 1)
	elif hit_strength == CombatConstants.HitStrength.HEAVY:
		# Attack commitment, not raw damage, guarantees the heavy stagger.
		_start_stagger_reaction()
		_obs_increment(&"enemy_reactions_stagger", 1)
	elif amount >= stagger_damage_threshold:
		_start_stagger_reaction()
		_obs_increment(&"enemy_reactions_stagger", 1)
	elif resists_light_flinch:
		# Armor-deflect presentation: visual cue but no movement interruption
		_play_armor_deflect_fx()
		_obs_increment(&"enemy_reactions_armor_deflect", 1)
	else:
		_start_hit_recoil_reaction()
		_obs_increment(&"enemy_reactions_flinch", 1)


func _play_armor_deflect_fx() -> void:
	"""Visual-only spark/deflect effect when a light hit is resisted by armor."""
	if visual:
		var original_modulate = visual.modulate
		visual.modulate = Color(1.5, 1.5, 1.5, 1.0)
		await get_tree().create_timer(0.06).timeout
		if is_instance_valid(visual):
			visual.modulate = original_modulate


func apply_melee_impact(attack_kind: String, knockback_direction: Vector2, knockback_force: float) -> void:
	if dead or _parry_critical_phase != ParryCriticalPhase.NONE:
		return
	_custom_ambient_knockout_flip_h = knockback_direction.x > 0.0
	_last_move_direction = knockback_direction if knockback_direction.length_squared() > 0.0001 else _last_move_direction
	if attack_kind == "heavy":
		_stagger_timer = max(_stagger_timer, stagger_duration * 1.2)
		_recoil_timer = 0.0
	else:
		_recoil_timer = max(_recoil_timer, hit_recoil_duration * 1.2)
	velocity = knockback_direction.normalized() * knockback_force
	move_and_slide()
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func apply_parry_stagger(knockback_direction: Vector2, duration: float, knockback_force: float) -> void:
	if dead:
		return
	var interrupted_falcon_punch := not _grunt_falcon_punch_phase.is_empty()
	_cancel_pending_attack_with_result(&"interrupted", &"parry")
	_cancel_savage_attack()
	_finish_grunt_falcon_punch_attack()
	if interrupted_falcon_punch:
		_grunt_falcon_punch_recent_parry_timer = maxf(_grunt_falcon_punch_recent_parry_timer, grunt_falcon_punch_recent_parry_lockout_sec)
	_finish_marine_dash_attack()
	_stagger_timer = 0.0
	_recoil_timer = 0.0
	_crit_timer = 0.0
	_crit_recovery_timer = 0.0
	if _uses_grunt_critical_window():
		var critical_window_duration := _get_grunt_parry_critical_window_duration(duration)
		_parry_critical_window_timer = critical_window_duration
		_clear_grunt_standard_hit_fx()
		_spawn_grunt_critical_open_vfx(_parry_critical_window_timer)
		_enter_parry_critical_phase(ParryCriticalPhase.ENTER)
		_obs_increment(&"enemy_parry_vulnerable_opened")
		_obs_log(&"enemy_parry_vulnerable_opened", {
			"enemy_id": get_instance_id(),
			"position": global_position,
			"window_sec": critical_window_duration,
		})
	var resolved_direction := knockback_direction.normalized() if knockback_direction.length_squared() > 0.0001 else -_last_move_direction.normalized()
	if resolved_direction.length_squared() <= 0.0001:
		resolved_direction = Vector2.RIGHT
	_last_move_direction = resolved_direction
	velocity = resolved_direction * knockback_force
	move_and_slide()
	if _parry_critical_phase == ParryCriticalPhase.ENTER:
		# The requested parry impulse is the only root displacement allowed before
		# reservation. Standalone open/recover clips keep this independent root.
		_parry_critical_standalone_root = global_position
		_parry_critical_standalone_root_valid = true
	if behavior_state_machine != null and behavior_state_machine.has_method("on_damaged"):
		behavior_state_machine.call("on_damaged", self, 0.0)
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _uses_grunt_critical_window() -> bool:
	return custom_enemy_animation_set == String(CUSTOM_ENEMY_GRUNT) \
		and _has_animation(String(GRUNT_CRITICAL_OPEN_ENTER_ANIMATION)) \
		and _has_animation(String(GRUNT_CRITICAL_OPEN_HOLD_ANIMATION)) \
		and _has_animation(String(GRUNT_CRITICAL_OPEN_RECOVER_ANIMATION)) \
		and _has_directional_grunt_execution_animations()


func _is_grunt_parry_critical_window_active() -> bool:
	return _uses_grunt_critical_window() \
		and _parry_critical_window_timer > 0.0 \
		and _parry_critical_phase in [ParryCriticalPhase.ENTER, ParryCriticalPhase.HOLD]


func can_receive_parry_critical_from(attacker: Node2D) -> bool:
	if dead or attacker == null or not is_instance_valid(attacker):
		return false
	if not _is_grunt_parry_critical_window_active() or _parry_critical_target != null:
		return false
	return global_position.distance_to(attacker.global_position) <= grunt_parry_critical_capture_range_px


func get_parry_critical_rejection_reason(
	attacker: Node2D
) -> StringName:
	if _parry_critical_phase not in [
		ParryCriticalPhase.ENTER,
		ParryCriticalPhase.HOLD,
	]:
		return &""
	if dead:
		return &"target_dead"
	if _parry_critical_target != null:
		return &"already_reserved"
	if _parry_critical_window_timer <= 0.0:
		return &"window_expired"
	if attacker == null or not is_instance_valid(attacker):
		return &"invalid_attacker"
	if (
		global_position.distance_to(attacker.global_position)
		> grunt_parry_critical_capture_range_px
	):
		return &"out_of_capture_range"
	return &""


func reserve_parry_critical(attacker: Node2D) -> Dictionary:
	if not can_receive_parry_critical_from(attacker):
		return {}
	_parry_critical_execution_token += 1
	_parry_critical_target = attacker
	_parry_critical_execution_damage_applied = false
	_parry_critical_window_timer = 0.0
	_parry_critical_phase = ParryCriticalPhase.EXECUTING
	_parry_critical_phase_timer = 0.0
	_parry_critical_standalone_root_valid = false
	_parry_critical_execution_direction = _resolve_parry_critical_execution_direction(attacker)
	_parry_critical_execution_root = get_parry_critical_execution_anchor()
	global_position = _parry_critical_execution_root
	_clear_grunt_critical_open_vfx(false)
	velocity = Vector2.ZERO
	_obs_increment(&"enemy_parry_vulnerable_consumed")
	_obs_log(&"enemy_parry_vulnerable_consumed", {
		"enemy_id": get_instance_id(),
		"attacker_id": attacker.get_instance_id(),
		"execution_token": _parry_critical_execution_token,
	})
	return {
		"token": _parry_critical_execution_token,
		"anchor": get_parry_critical_execution_anchor(),
		"operator_offset": get_parry_critical_operator_offset(),
		"facing": get_parry_critical_facing(),
		"direction": _parry_critical_execution_direction,
	}


func begin_parry_critical_execution(attacker: Node2D, execution_data: Dictionary) -> bool:
	if not _is_valid_parry_critical_execution_owner(attacker, int(execution_data.get("token", -1))):
		return false
	velocity = Vector2.ZERO
	global_position = _parry_critical_execution_root
	var victim_animation := _get_parry_critical_execution_animation()
	_play_animation(String(victim_animation), false)
	if animated_sprite != null:
		_parry_critical_execution_body_original_position = animated_sprite.position
		_parry_critical_execution_body_position_captured = true
		animated_sprite.position = Vector2.ZERO
		animated_sprite.stop()
		animated_sprite.set_frame_and_progress(0, 0.0)
	return true


func set_parry_critical_execution_frame(attacker: Node2D, token: int, frame_index: int) -> bool:
	if not _is_valid_parry_critical_execution_owner(attacker, token):
		return false
	global_position = _parry_critical_execution_root
	velocity = Vector2.ZERO
	if animated_sprite == null or animated_sprite.animation != String(_get_parry_critical_execution_animation()):
		return false
	animated_sprite.stop()
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(
		animated_sprite.animation
	)
	animated_sprite.set_frame_and_progress(
		clampi(frame_index, 0, maxi(frame_count - 1, 0)),
		0.0
	)
	return true


func apply_parry_critical_execution_damage(attacker: Node2D, damage_amount: float, hit_data: Dictionary = {}) -> Dictionary:
	var token := int(hit_data.get("execution_token", _parry_critical_execution_token))
	if not _is_valid_parry_critical_execution_owner(attacker, token) or _parry_critical_execution_damage_applied:
		return {"critical": false, "consumed": false, "damage_applied": 0.0, "lethal": dead}
	_parry_critical_execution_damage_applied = true
	var health_before := maxf(0.0, health)
	var applied_damage := minf(
		maxf(0.0, damage_amount),
		health_before
	)
	health = maxf(0.0, health_before - applied_damage)
	if behavior_state_machine != null and behavior_state_machine.has_method("on_damaged"):
		behavior_state_machine.call("on_damaged", self, applied_damage)
	_on_assault_damage_taken(applied_damage)
	_spawn_damage_popup(applied_damage)
	update_visuals()
	var lethal := health <= 0.0
	if lethal:
		die()
	var result := _damage_result(applied_damage, health_before > 0.0)
	result.merge({
		"critical": true,
		"consumed": true,
		"damage_applied": applied_damage,
		"lethal": lethal,
	}, true)
	return result


func finish_parry_critical_execution(attacker: Node2D, result: Dictionary = {}) -> void:
	var token := int(result.get("execution_token", _parry_critical_execution_token))
	if not _is_valid_parry_critical_execution_owner(attacker, token):
		return
	_release_parry_critical_execution_owner()
	if dead:
		return
	_parry_critical_phase = ParryCriticalPhase.NONE
	_crit_recovery_timer = maxf(_crit_recovery_timer, crit_recovery_duration)
	_update_custom_enemy_animation(_last_move_direction, false)


func cancel_parry_critical_execution(attacker: Node2D, _reason: StringName) -> void:
	if _parry_critical_phase != ParryCriticalPhase.EXECUTING:
		return
	if attacker != null and is_instance_valid(attacker) and attacker != _parry_critical_target:
		return
	_release_parry_critical_execution_owner()
	if dead:
		return
	_parry_critical_phase = ParryCriticalPhase.NONE
	_crit_recovery_timer = maxf(_crit_recovery_timer, crit_recovery_duration)
	_update_custom_enemy_animation(_last_move_direction, false)


func _release_parry_critical_execution_owner() -> void:
	if animated_sprite != null and _parry_critical_execution_body_position_captured:
		animated_sprite.position = _parry_critical_execution_body_original_position
	_parry_critical_execution_body_position_captured = false
	_parry_critical_target = null
	_parry_critical_phase_timer = 0.0
	_parry_critical_window_timer = 0.0
	_parry_critical_execution_damage_applied = false
	_parry_critical_execution_direction = &"s"
	_clear_grunt_critical_open_vfx(false)


func _is_valid_parry_critical_execution_owner(attacker: Node2D, token: int) -> bool:
	return _parry_critical_phase == ParryCriticalPhase.EXECUTING \
		and not dead \
		and attacker != null \
		and is_instance_valid(attacker) \
		and attacker == _parry_critical_target \
		and token == _parry_critical_execution_token


func get_parry_critical_execution_anchor() -> Vector2:
	var anchor := get_node_or_null("CriticalExecutionAnchor") as Marker2D
	return anchor.global_position if anchor != null else global_position


func get_parry_critical_operator_offset() -> Vector2:
	return grunt_parry_critical_operator_offset


func get_parry_critical_facing() -> Vector2:
	match _parry_critical_execution_direction:
		&"e":
			return Vector2.RIGHT
		&"w":
			return Vector2.LEFT
		_:
			return Vector2.DOWN


func _resolve_parry_critical_execution_direction(attacker: Node2D) -> StringName:
	if attacker == null or not is_instance_valid(attacker):
		return &"s"
	var approach := attacker.global_position.direction_to(global_position)
	if absf(approach.x) > absf(approach.y):
		return &"e" if approach.x > 0.0 else &"w"
	# The authored set intentionally has no north strip. Vertical approaches use
	# the south composition rather than mirroring or inventing layer offsets.
	return &"s"


func _get_parry_critical_execution_animation() -> StringName:
	return GRUNT_CRITICAL_EXECUTION_VICTIM_ANIMATIONS.get(
		_parry_critical_execution_direction,
		GRUNT_CRITICAL_EXECUTION_VICTIM_ANIMATIONS[&"s"]
	) as StringName


func _has_directional_grunt_execution_animations() -> bool:
	for animation_name: StringName in GRUNT_CRITICAL_EXECUTION_VICTIM_ANIMATIONS.values():
		if not _has_animation(String(animation_name)):
			return false
	return true


func debug_apply_spawn_mode(mode: StringName, attacker: Node2D = null) -> bool:
	if custom_enemy_animation_set != String(CUSTOM_ENEMY_GRUNT):
		return mode == &"normal"
	var normalized_mode := StringName(String(mode).strip_edges().to_lower())
	if normalized_mode.is_empty():
		normalized_mode = &"normal"
	if normalized_mode == &"normal":
		_obs_log(&"debug_enemy_spawn_mode_applied", {"enemy": enemy_name, "mode": String(normalized_mode)})
		return true
	if normalized_mode == &"falcon":
		if attacker == null or not is_instance_valid(attacker):
			return false
		target = attacker
		var direction := global_position.direction_to(attacker.global_position)
		_start_grunt_falcon_punch_windup(direction)
		_obs_log(&"debug_enemy_spawn_mode_applied", {
			"enemy": enemy_name,
			"mode": String(normalized_mode),
			"position": global_position,
		})
		return true
	if normalized_mode not in [&"critical_enter", &"critical_hold", &"critical_recover", &"execution_ready", &"execution_lethal"]:
		return false
	var knockback_direction := Vector2.LEFT
	if attacker != null and is_instance_valid(attacker):
		knockback_direction = attacker.global_position.direction_to(global_position)
		if knockback_direction.length_squared() <= 0.0001:
			knockback_direction = Vector2.RIGHT
	apply_parry_stagger(knockback_direction, grunt_parry_critical_window_min_sec, 0.0)
	if _parry_critical_phase != ParryCriticalPhase.ENTER:
		return false
	match normalized_mode:
		&"critical_hold", &"execution_ready", &"execution_lethal":
			_enter_parry_critical_phase(ParryCriticalPhase.HOLD)
		&"critical_recover":
			_parry_critical_window_timer = 0.0
			_clear_grunt_critical_open_vfx(false)
			_enter_parry_critical_phase(ParryCriticalPhase.RECOVER)
	if normalized_mode == &"execution_lethal":
		health = minf(health, 1.0)
		update_visuals()
	_obs_log(&"debug_enemy_spawn_mode_applied", {
		"enemy": enemy_name,
		"mode": String(normalized_mode),
		"position": global_position,
	})
	return true


func receive_parry_critical(attacker: Node2D, damage_amount: float, hit_data: Dictionary = {}) -> Dictionary:
	var execution_data := reserve_parry_critical(attacker)
	if execution_data.is_empty() or not begin_parry_critical_execution(attacker, execution_data):
		return {"critical": false, "consumed": false, "damage_applied": 0.0}
	hit_data["execution_token"] = int(execution_data.get("token", -1))
	var result := apply_parry_critical_execution_damage(attacker, damage_amount, hit_data)
	finish_parry_critical_execution(attacker, {"execution_token": int(execution_data.get("token", -1))})
	return result


func has_active_critical_target_reticle() -> bool:
	return _is_grunt_parry_critical_window_active() \
		and _critical_window_ring_vfx != null \
		and is_instance_valid(_critical_window_ring_vfx)


func suppresses_normal_targeting_presentation() -> bool:
	return _parry_critical_phase in [
		ParryCriticalPhase.ENTER,
		ParryCriticalPhase.HOLD,
		ParryCriticalPhase.RECOVER,
		ParryCriticalPhase.EXECUTING,
	]


func _preserve_parry_critical_standalone_root() -> void:
	if not _parry_critical_standalone_root_valid:
		_parry_critical_standalone_root = global_position
		_parry_critical_standalone_root_valid = true
	if OS.is_debug_build():
		assert(
			global_position.is_equal_approx(_parry_critical_standalone_root),
			"Critical-open standalone state changed the enemy world root."
		)
	global_position = _parry_critical_standalone_root
	velocity = Vector2.ZERO


func _get_grunt_parry_critical_window_duration(duration: float) -> float:
	return maxf(maxf(duration, grunt_parry_critical_window_min_sec), _get_animation_duration(String(GRUNT_CRITICAL_OPEN_ENTER_ANIMATION)))


func _enter_parry_critical_phase(phase: int) -> void:
	_parry_critical_phase = phase
	velocity = Vector2.ZERO
	var animation_name := &""
	match phase:
		ParryCriticalPhase.ENTER:
			animation_name = GRUNT_CRITICAL_OPEN_ENTER_ANIMATION
		ParryCriticalPhase.HOLD:
			animation_name = GRUNT_CRITICAL_OPEN_HOLD_ANIMATION
		ParryCriticalPhase.RECOVER:
			animation_name = GRUNT_CRITICAL_OPEN_RECOVER_ANIMATION
		_:
			_parry_critical_phase_timer = 0.0
			return
	_parry_critical_phase_timer = _get_animation_duration(String(animation_name))
	_play_animation(String(animation_name), false)


func _start_hit_recoil_reaction() -> void:
	_recoil_timer = max(_recoil_timer, hit_recoil_duration)
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _start_stagger_reaction() -> void:
	_stagger_timer = max(_stagger_timer, stagger_duration)
	_recoil_timer = 0.0
	_attack_windup_timer = 0.0
	_cancel_pending_attack_with_result(&"interrupted", &"stagger")
	_finish_grunt_falcon_punch_attack()
	_finish_marine_dash_attack()
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _start_crit_reaction() -> void:
	_crit_timer = max(_crit_timer, crit_hit_duration)
	_crit_recovery_timer = 0.0
	_parry_critical_window_timer = 0.0
	_clear_grunt_critical_open_vfx(false)
	_recoil_timer = 0.0
	_stagger_timer = 0.0
	_attack_windup_timer = 0.0
	_cancel_pending_attack_with_result(&"interrupted", &"critical_hit")
	_finish_grunt_falcon_punch_attack()
	_finish_marine_dash_attack()
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)
	_play_custom_enemy_crit_fx()


func _spawn_damage_popup(amount: float) -> void:
	var popup := DAMAGE_POPUP_SCENE.instantiate()
	popup.text = str(int(amount))
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-10, 10), -20)


func _update_reaction_timers(delta: float) -> bool:
	if _parry_critical_phase == ParryCriticalPhase.EXECUTING:
		velocity = Vector2.ZERO
		global_position = _parry_critical_execution_root
		if _parry_critical_target == null or not is_instance_valid(_parry_critical_target):
			cancel_parry_critical_execution(null, &"owner_invalid")
		return true
	if _parry_critical_phase in [ParryCriticalPhase.ENTER, ParryCriticalPhase.HOLD]:
		_preserve_parry_critical_standalone_root()
		_parry_critical_window_timer = maxf(0.0, _parry_critical_window_timer - delta)
		_parry_critical_phase_timer = maxf(0.0, _parry_critical_phase_timer - delta)
		velocity = Vector2.ZERO
		if _parry_critical_window_timer <= 0.0:
			_obs_increment(&"enemy_parry_vulnerable_expired")
			_obs_log(&"enemy_parry_vulnerable_expired", {
				"enemy_id": get_instance_id(),
				"position": global_position,
			})
			_clear_grunt_critical_open_vfx(true)
			_enter_parry_critical_phase(ParryCriticalPhase.RECOVER)
		elif _parry_critical_phase == ParryCriticalPhase.ENTER and _parry_critical_phase_timer <= 0.0:
			_enter_parry_critical_phase(ParryCriticalPhase.HOLD)
		_update_custom_enemy_animation(_last_move_direction, false)
		return true
	if _parry_critical_phase == ParryCriticalPhase.RECOVER:
		_preserve_parry_critical_standalone_root()
		_parry_critical_phase_timer = maxf(0.0, _parry_critical_phase_timer - delta)
		velocity = Vector2.ZERO
		if _parry_critical_phase_timer <= 0.0:
			_parry_critical_phase = ParryCriticalPhase.NONE
			_parry_critical_standalone_root_valid = false
			_update_custom_enemy_animation(_last_move_direction, false)
		else:
			_update_custom_enemy_animation(_last_move_direction, false)
		return true
	if _crit_timer > 0.0:
		_crit_timer = max(0.0, _crit_timer - delta)
		velocity = Vector2.ZERO
		if _crit_timer <= 0.0:
			_crit_recovery_timer = max(_crit_recovery_timer, crit_recovery_duration)
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, false)
		return true
	if _crit_recovery_timer > 0.0:
		_crit_recovery_timer = max(0.0, _crit_recovery_timer - delta)
		velocity = Vector2.ZERO
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, false)
		return true
	if _stagger_timer > 0.0:
		_stagger_timer = max(0.0, _stagger_timer - delta)
		velocity = Vector2.ZERO
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, false)
		return true
	if _recoil_timer > 0.0:
		_recoil_timer = max(0.0, _recoil_timer - delta)
		velocity = Vector2.ZERO
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, false)
		return true
	return false


func _update_assault_state(delta: float) -> bool:
	_assault_state_timer = max(0.0, _assault_state_timer - delta)
	match _assault_state:
		AssaultState.STAGING:
			return _update_staging_state()
		AssaultState.PROBING:
			if _assault_state_timer <= 0.0:
				_enter_assault_state(AssaultState.COMMIT)
			return _update_probing_state()
		AssaultState.REGROUP:
			if _assault_state_timer <= 0.0:
				_enter_assault_state(AssaultState.PROBING)
			return _update_regroup_state()
		_:
			return false


func _update_staging_state() -> bool:
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)
	if _assault_state_timer <= 0.0:
		_enter_assault_state(AssaultState.PROBING)
	return true


func _update_probing_state() -> bool:
	var sensed_target := _find_best_target_in_range(detection_range * assault_commit_detection_multiplier)
	if sensed_target != null:
		target = sensed_target
		_enter_assault_state(AssaultState.COMMIT)
		return false
	if _assault_probe_destination.distance_to(_spawn_position) <= 1.0:
		_refresh_probe_destination()
	var move_direction := (_assault_probe_destination - global_position).normalized()
	if global_position.distance_to(_assault_probe_destination) <= path_tolerance:
		_refresh_probe_destination()
		move_direction = (_assault_probe_destination - global_position).normalized()
	velocity = move_direction * speed * assault_probe_speed_multiplier if move_direction.length_squared() > 0.0001 else Vector2.ZERO
	move_and_slide()
	if move_direction.length_squared() > 0.0001:
		_last_move_direction = move_direction
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, velocity.length_squared() > 0.0001)
	return true


func _update_regroup_state() -> bool:
	target = null
	clear_path()
	var fallback_target := _spawn_position
	var retreat_direction := (fallback_target - global_position).normalized()
	velocity = retreat_direction * speed * assault_regroup_speed_multiplier if retreat_direction.length_squared() > 0.0001 else Vector2.ZERO
	move_and_slide()
	if retreat_direction.length_squared() > 0.0001:
		_last_move_direction = retreat_direction
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, velocity.length_squared() > 0.0001)
	return true


func _enter_assault_state(next_state: int) -> void:
	var previous_state := _assault_state
	_assault_state = next_state
	if previous_state != next_state:
		_obs_log(&"enemy_assault_state_changed", {
			"enemy": enemy_name,
			"position": global_position,
			"from": _assault_state_name(previous_state),
			"to": _assault_state_name(next_state),
			"health": health,
			"max_health": max_health,
			"target": target.name if target != null and is_instance_valid(target) else "",
			"attack_objective": attack_objective,
		})
		_obs_increment(StringName("enemy_assault_state_%s" % _assault_state_name(next_state)), 1)
	match _assault_state:
		AssaultState.STAGING:
			target = null
			clear_path()
			_assault_state_timer = randf_range(
				min(assault_staging_duration_min, assault_staging_duration_max),
				max(assault_staging_duration_min, assault_staging_duration_max)
			)
		AssaultState.PROBING:
			target = null
			clear_path()
			_assault_state_timer = randf_range(
				min(assault_probe_duration_min, assault_probe_duration_max),
				max(assault_probe_duration_min, assault_probe_duration_max)
			)
			_refresh_probe_destination()
		AssaultState.COMMIT:
			_assault_state_timer = 0.0
		AssaultState.REGROUP:
			target = null
			clear_path()
			_assault_state_timer = max(0.1, assault_regroup_duration)


func _refresh_probe_destination() -> void:
	var offset := Vector2(
		randf_range(-96.0, 96.0),
		randf_range(-96.0, 96.0)
	)
	_assault_probe_destination = _spawn_position + offset


func _find_best_target_in_range(max_range: float) -> Node2D:
	var best: Node2D = null
	var best_priority := 999
	var best_distance := INF
	var groups: Array = OBJECTIVE_GROUPS.get(attack_objective, OBJECTIVE_GROUPS["breach_command"])
	for group_name in groups:
		var priority = int(TARGET_PRIORITY.get(group_name, 999))
		for candidate in get_tree().get_nodes_in_group(group_name):
			if not (candidate is Node2D):
				continue
			var node := candidate as Node2D
			if _is_target_destroyed(node):
				continue
			var dist := global_position.distance_to(node.global_position)
			if dist > max_range:
				continue
			if priority < best_priority or (priority == best_priority and dist < best_distance):
				best = node
				best_priority = priority
				best_distance = dist
	return best


func _on_assault_damage_taken(amount: float) -> void:
	if passive or dead:
		return
	if _assault_state == AssaultState.STAGING or _assault_state == AssaultState.PROBING:
		if amount >= assault_damage_commit_threshold:
			_enter_assault_state(AssaultState.COMMIT)
		return
	if _assault_state == AssaultState.COMMIT and health > 0.0 and health <= max_health * 0.35:
		_enter_assault_state(AssaultState.REGROUP)

func is_dead() -> bool:
	return dead


func _uses_directional_animation_set() -> bool:
	if _uses_humanoid_cutout_backend():
		return true
	return (uses_directional_charset or _uses_custom_enemy_animation_set() or _uses_custom_ambient_animation_set() or _uses_procedural_variant_animation_set()) and animated_sprite != null


func _uses_humanoid_cutout_backend() -> bool:
	return visual_backend == VisualBackend.HUMANOID_CUTOUT and humanoid_cutout_rig != null


func _configure_visual_backend() -> void:
	if visual_backend == VisualBackend.HUMANOID_CUTOUT and humanoid_cutout_rig == null:
		_report_visual_backend_fallback_once(
			&"missing_humanoid_cutout_rig",
			"HumanoidCutoutRig2D child is missing; preserving authored-frame presentation."
		)
		return
	if _uses_humanoid_cutout_backend():
		humanoid_cutout_rig.visible = true
		if visual != null:
			visual.visible = false
		if animated_sprite != null:
			animated_sprite.visible = false
		humanoid_cutout_rig.set_facing_vector(_last_move_direction)
		humanoid_cutout_rig.play_state(&"idle", true)
		if grunt_falcon_punch_enabled or savage_chain_enabled or savage_pounce_enabled or marine_dash_enabled:
			_report_visual_backend_fallback_once(
				&"unsupported_cutout_specials",
				"Enabled bespoke specials have no cutout choreography; use authored frames or an explicit authored fallback."
			)
	elif humanoid_cutout_rig != null:
		humanoid_cutout_rig.visible = false


func _play_cutout_presentation_state(state: StringName, restart: bool = false) -> void:
	if not _uses_humanoid_cutout_backend():
		return
	if humanoid_cutout_rig.has_state(state):
		humanoid_cutout_rig.play_state(state, restart)
		return
	_report_visual_backend_fallback_once(
		StringName("missing_cutout_state_%s" % String(state)),
		"Cutout state '%s' is unsupported; holding the generic idle pose." % String(state)
	)
	if humanoid_cutout_rig.has_state(&"idle"):
		humanoid_cutout_rig.play_state(&"idle", false)


func _report_visual_backend_fallback_once(key: StringName, message: String) -> void:
	if _visual_backend_fallbacks_reported.has(key):
		return
	_visual_backend_fallbacks_reported[key] = true
	push_warning("[EnemyVisualBackend] %s: %s" % [enemy_name, message])
	_obs_log(&"enemy_visual_backend_fallback", {
		"enemy": enemy_name,
		"fallback": String(key),
		"message": message,
		"position": global_position,
	})


func _uses_procedural_variant_animation_set() -> bool:
	return _uses_procedural_variant_visuals and animated_sprite != null


func _uses_custom_enemy_animation_set() -> bool:
	return [String(CUSTOM_ENEMY_GRUNT), String(CUSTOM_ENEMY_MARINE), String(CUSTOM_ENEMY_SAVAGE)].has(custom_enemy_animation_set) and animated_sprite != null


func _uses_custom_ambient_animation_set() -> bool:
	return custom_ambient_animation_enabled and passive and animated_sprite != null


func _has_animation(name: String) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	return animated_sprite.sprite_frames.has_animation(name)


func _get_animation_duration(name: String) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0
	if not animated_sprite.sprite_frames.has_animation(name):
		return 0.0
	var speed: float = animated_sprite.sprite_frames.get_animation_speed(name)
	if speed <= 0.0:
		return 0.0
	return float(animated_sprite.sprite_frames.get_frame_count(name)) / speed


func _play_animation(name: String, allow_restart: bool = true) -> void:
	if not _has_animation(name):
		return
	if not allow_restart and animated_sprite.animation == name and animated_sprite.is_playing():
		return
	if allow_restart and animated_sprite.animation == name:
		if animated_sprite.is_playing():
			animated_sprite.set_frame_and_progress(0, 0.0)
		else:
			animated_sprite.play(name)
		return
	animated_sprite.play(name)


func _ensure_directional_animations() -> void:
	if animated_sprite == null or _has_directional_animation_assets():
		return
	if _uses_custom_enemy_animation_set():
		_ensure_custom_enemy_animations()
		return
	if _uses_procedural_variant_animation_set():
		animated_sprite.sprite_frames = WOLF_ANIMATION_LIBRARY.get_wolf_sprite_frames()
		return
	if _uses_custom_ambient_animation_set():
		_ensure_custom_ambient_animations()
		return
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()
	if not ResourceLoader.exists(directional_charset_sheet_path):
		return
	var texture := load(directional_charset_sheet_path)
	if not (texture is Texture2D):
		return
	var tex := texture as Texture2D
	var safe_frame_size: int = max(1, directional_charset_frame_size)
	var safe_row_start: int = max(0, directional_charset_row_start)
	var sheet_rows := int(tex.get_height() / safe_frame_size)
	var sheet_cols := int(tex.get_width() / safe_frame_size)
	if sheet_rows < safe_row_start + 4 or sheet_cols < DIRECTIONAL_SUFFIXES.size():
		return

	var frames: SpriteFrames = animated_sprite.sprite_frames
	for dir_index in range(DIRECTIONAL_SUFFIXES.size()):
		var suffix: String = String(DIRECTIONAL_SUFFIXES[dir_index])
		var anim_name := _get_directional_animation_name(StringName(suffix))
		if frames.has_animation(anim_name):
			frames.remove_animation(anim_name)
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, directional_charset_fps)
		for frame_index in range(4):
			frames.add_frame(anim_name, _build_directional_atlas(tex, dir_index, safe_row_start + frame_index, safe_frame_size))


func _build_directional_atlas(texture: Texture2D, dir_index: int, row_index: int, frame_size: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(dir_index * frame_size), float(row_index * frame_size), float(frame_size), float(frame_size))
	return atlas


func _update_directional_animation(direction: Vector2, is_moving: bool) -> void:
	if _uses_humanoid_cutout_backend():
		humanoid_cutout_rig.set_facing_vector(direction)
		if _recoil_timer > 0.0 or _stagger_timer > 0.0 or _crit_timer > 0.0:
			_play_cutout_presentation_state(&"hit_react", false)
		else:
			_play_cutout_presentation_state(&"run" if is_moving else &"idle", false)
		return
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if _uses_custom_enemy_animation_set():
		_update_custom_enemy_animation(direction, is_moving)
		return
	if _uses_procedural_variant_animation_set():
		_update_procedural_variant_animation(direction, is_moving)
		return
	if _uses_custom_ambient_animation_set():
		_update_custom_ambient_animation(direction, is_moving)
		return
	var anim_name := _get_directional_animation_name(_get_directional_charset_suffix(direction))
	if not _has_animation(anim_name):
		return
	if is_moving:
		_play_animation(anim_name, false)
		return
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
	animated_sprite.stop()
	animated_sprite.set_frame_and_progress(0, 0.0)


func _get_directional_charset_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector := int(round(angle / (PI / 4.0))) % DIRECTIONAL_SUFFIXES.size()
	var angle_to_index := [2, 3, 4, 5, 6, 7, 0, 1]
	return DIRECTIONAL_SUFFIXES[angle_to_index[sector]]


func _get_directional_animation_name(suffix: StringName) -> String:
	return "%s_%s" % [directional_animation_prefix, String(suffix)]


func _has_directional_animation_assets() -> bool:
	if _uses_custom_enemy_animation_set():
		if custom_enemy_animation_set == String(CUSTOM_ENEMY_MARINE):
			return _has_animation("marine_idle_s")
		return _has_animation(String(GRUNT_IDLE_ANIMATION)) and _has_animation(String(GRUNT_MOVE_ANIMATION))
	if _uses_custom_ambient_animation_set():
		return _has_animation(String(CUSTOM_AMBIENT_EAST_ANIMATION)) and _has_animation(String(CUSTOM_AMBIENT_NORTH_ANIMATION)) and _has_animation(String(CUSTOM_AMBIENT_SOUTH_ANIMATION))
	for suffix in DIRECTIONAL_SUFFIXES:
		if _has_animation(_get_directional_animation_name(suffix)):
			return true
	return false


func _ensure_custom_enemy_animations() -> void:
	if animated_sprite == null:
		return
	if custom_enemy_animation_set == String(CUSTOM_ENEMY_GRUNT):
		animated_sprite.sprite_frames = GRUNT_ANIMATION_LIBRARY.get_grunt_sprite_frames()
	elif custom_enemy_animation_set == String(CUSTOM_ENEMY_MARINE):
		animated_sprite.sprite_frames = GRUNT_ANIMATION_LIBRARY.get_marine_sprite_frames()
	elif custom_enemy_animation_set == String(CUSTOM_ENEMY_SAVAGE):
		animated_sprite.sprite_frames = SAVAGE_ANIMATION_LIBRARY.get_savage_sprite_frames()


func _ensure_custom_enemy_fx_animations() -> void:
	if custom_enemy_fx_sprite == null:
		return
	if custom_enemy_animation_set == String(CUSTOM_ENEMY_GRUNT):
		custom_enemy_fx_sprite.sprite_frames = GRUNT_ANIMATION_LIBRARY.get_grunt_fx_sprite_frames()
	elif custom_enemy_animation_set == String(CUSTOM_ENEMY_MARINE):
		custom_enemy_fx_sprite.sprite_frames = GRUNT_ANIMATION_LIBRARY.get_marine_fx_sprite_frames()
	else:
		return
	custom_enemy_fx_sprite.scale = custom_enemy_fx_scale
	custom_enemy_fx_sprite.visible = false


func _ensure_custom_ambient_animations() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()
	var frames: SpriteFrames = animated_sprite.sprite_frames
	_build_custom_ambient_east_animation(frames)
	_build_custom_ambient_north_south_animations(frames)
	_build_custom_ambient_knockout_animation(frames)


func _build_custom_ambient_east_animation(frames: SpriteFrames) -> void:
	var texture: Texture2D = _load_enemy_texture(custom_ambient_east_sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, custom_ambient_east_frame_size.x)
	var frame_height: int = max(1, custom_ambient_east_frame_size.y)
	var frame_count: int = max(1, texture.get_width() / frame_width)
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_EAST_ANIMATION), frame_count, true, custom_ambient_east_fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, 0, frame_width, frame_height)
	)


func _build_custom_ambient_north_south_animations(frames: SpriteFrames) -> void:
	if not custom_ambient_north_sheet_path.is_empty() and not custom_ambient_south_sheet_path.is_empty():
		_build_custom_ambient_strip_animation(
			frames,
			CUSTOM_AMBIENT_NORTH_ANIMATION,
			custom_ambient_north_sheet_path,
			custom_ambient_north_south_frame_size,
			custom_ambient_north_south_fps
		)
		_build_custom_ambient_strip_animation(
			frames,
			CUSTOM_AMBIENT_SOUTH_ANIMATION,
			custom_ambient_south_sheet_path,
			custom_ambient_north_south_frame_size,
			custom_ambient_north_south_fps
		)
		return
	var texture: Texture2D = _load_enemy_texture(custom_ambient_north_south_sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, custom_ambient_north_south_frame_size.x)
	var frame_height: int = max(1, custom_ambient_north_south_frame_size.y)
	var columns: int = max(1, custom_ambient_north_south_columns)
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_NORTH_ANIMATION), columns, true, custom_ambient_north_south_fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, 0, frame_width, frame_height)
	)
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_SOUTH_ANIMATION), columns, true, custom_ambient_north_south_fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, frame_height, frame_width, frame_height)
	)


func _build_custom_ambient_strip_animation(frames: SpriteFrames, animation_name: StringName, sheet_path: String, frame_size: Vector2i, fps: float) -> void:
	var texture: Texture2D = _load_enemy_texture(sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, frame_size.x)
	var frame_height: int = max(1, frame_size.y)
	var frame_count: int = max(1, texture.get_width() / frame_width)
	_rebuild_animation(frames, String(animation_name), frame_count, true, fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, 0, frame_width, frame_height)
	)


func _build_custom_ambient_knockout_animation(frames: SpriteFrames) -> void:
	var texture: Texture2D = _load_enemy_texture(custom_ambient_knockout_sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, custom_ambient_knockout_frame_size.x)
	var frame_height: int = max(1, custom_ambient_knockout_frame_size.y)
	var columns: int = max(1, custom_ambient_knockout_columns)
	var rows: int = max(1, custom_ambient_knockout_rows)
	var frame_count: int = columns * rows
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_KO_ANIMATION), frame_count, false, custom_ambient_knockout_fps, func(frame_index: int) -> AtlasTexture:
		var col: int = frame_index % columns
		var row: int = frame_index / columns
		return _build_custom_region_atlas(texture, col * frame_width, row * frame_height, frame_width, frame_height)
	)


func _rebuild_animation(frames: SpriteFrames, animation_name: String, frame_count: int, loop: bool, fps: float, atlas_builder: Callable) -> void:
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, fps)
	for frame_index in range(frame_count):
		var atlas_variant: Variant = atlas_builder.call(frame_index)
		if atlas_variant is AtlasTexture:
			frames.add_frame(animation_name, atlas_variant as AtlasTexture)


func _build_custom_region_atlas(texture: Texture2D, x: int, y: int, width: int, height: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(x), float(y), float(width), float(height))
	return atlas


func _load_enemy_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is Texture2D:
		return resource as Texture2D
	return null


func _update_custom_ambient_animation(direction: Vector2, is_moving: bool) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var animation_name := CUSTOM_AMBIENT_SOUTH_ANIMATION
	var flip_h := false
	if absf(direction.x) >= absf(direction.y) and direction.length_squared() > 0.0001:
		animation_name = CUSTOM_AMBIENT_EAST_ANIMATION
		flip_h = direction.x < 0.0
	elif direction.y < 0.0:
		animation_name = CUSTOM_AMBIENT_NORTH_ANIMATION
	animated_sprite.flip_h = flip_h
	animated_sprite.scale = _get_custom_ambient_scale_for_animation(animation_name)
	_base_sprite_scale = animated_sprite.scale
	if not _has_animation(String(animation_name)):
		return
	if is_moving:
		_play_animation(String(animation_name), false)
		return
	if animated_sprite.animation != String(animation_name):
		animated_sprite.play(String(animation_name))
	animated_sprite.stop()
	animated_sprite.set_frame_and_progress(0, 0.0)


func _update_custom_enemy_animation(direction: Vector2, is_moving: bool, force_attack: bool = false) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if custom_enemy_animation_set == String(CUSTOM_ENEMY_SAVAGE):
		_update_savage_enemy_animation(direction, is_moving)
		return
	if custom_enemy_animation_set == String(CUSTOM_ENEMY_MARINE):
		_update_marine_enemy_animation(direction, force_attack)
		return
	var facing := direction
	if facing.length_squared() <= 0.0001:
		facing = _last_move_direction
	animated_sprite.scale = custom_enemy_animation_scale
	_base_sprite_scale = animated_sprite.scale
	if not _grunt_falcon_punch_phase.is_empty():
		var special_animation := GRUNT_ANIMATION_LIBRARY.get_grunt_falcon_punch_phase_animation(_grunt_falcon_punch_phase, _grunt_falcon_punch_direction)
		if _has_animation(String(special_animation)):
			animated_sprite.flip_h = false
			_play_animation(String(special_animation), false)
		return
	if _parry_critical_phase != ParryCriticalPhase.NONE:
		var critical_phase_name := &""
		match _parry_critical_phase:
			ParryCriticalPhase.ENTER:
				critical_phase_name = GRUNT_CRITICAL_OPEN_ENTER_ANIMATION
			ParryCriticalPhase.HOLD:
				critical_phase_name = GRUNT_CRITICAL_OPEN_HOLD_ANIMATION
			ParryCriticalPhase.RECOVER:
				critical_phase_name = GRUNT_CRITICAL_OPEN_RECOVER_ANIMATION
			ParryCriticalPhase.EXECUTING:
				critical_phase_name = _get_parry_critical_execution_animation()
		if not critical_phase_name.is_empty() and _has_animation(String(critical_phase_name)):
			animated_sprite.flip_h = false
			_play_animation(String(critical_phase_name), false)
		return
	if _crit_timer > 0.0:
		if _has_animation(String(GRUNT_CRIT_ANIMATION)):
			animated_sprite.flip_h = false
			_play_animation(String(GRUNT_CRIT_ANIMATION), false)
		return
	if _crit_recovery_timer > 0.0:
		if _has_animation(String(GRUNT_CRIT_RECOVERY_ANIMATION)):
			animated_sprite.flip_h = false
			_play_animation(String(GRUNT_CRIT_RECOVERY_ANIMATION), false)
			return
	if _recoil_timer > 0.0:
		var flinch_animation := GRUNT_ANIMATION_LIBRARY.get_flinch_animation(facing)
		if not _has_animation(String(flinch_animation)):
			flinch_animation = GRUNT_FLINCH_ANIMATION
		if _has_animation(String(flinch_animation)):
			animated_sprite.flip_h = false
			_play_animation(String(flinch_animation), false)
			_play_grunt_flinch_fx()
			return
	if _stagger_timer > 0.0:
		var stagger_animation := _get_grunt_stagger_animation()
		if _has_animation(String(stagger_animation)):
			animated_sprite.flip_h = false
			_play_animation(String(stagger_animation), false)
			return
	if force_attack:
		var attack_animation := GRUNT_ANIMATION_LIBRARY.get_attack_animation(facing)
		if not _has_animation(String(attack_animation)):
			attack_animation = GRUNT_ATTACK_ANIMATION
		if _has_animation(String(attack_animation)):
			animated_sprite.flip_h = false
			_play_animation(String(attack_animation), false)
			_play_custom_enemy_attack_fx(facing)
		return
	if is_moving:
		var move_animation := GRUNT_ANIMATION_LIBRARY.get_move_animation(facing)
		if not _has_animation(String(move_animation)):
			move_animation = GRUNT_MOVE_ANIMATION
		if _has_animation(String(move_animation)):
			animated_sprite.flip_h = false
			_play_animation(String(move_animation), false)
			return
	animated_sprite.flip_h = false
	if not _has_animation(String(GRUNT_IDLE_ANIMATION)):
		return
	if animated_sprite.animation != String(GRUNT_IDLE_ANIMATION):
		animated_sprite.play(String(GRUNT_IDLE_ANIMATION))
	animated_sprite.stop()
	animated_sprite.set_frame_and_progress(0, 0.0)


func _update_savage_enemy_animation(direction: Vector2, is_moving: bool) -> void:
	var facing := direction if direction.length_squared() > 0.0001 else _last_move_direction
	# Savage action/reaction/death presentation has higher ownership than
	# locomotion. Until those authored clips are present, preserve the current
	# presentation rather than allowing movement/idle selection to overwrite it.
	if dead \
	or _parry_critical_phase != ParryCriticalPhase.NONE \
	or _crit_timer > 0.0 \
	or _crit_recovery_timer > 0.0 \
	or _stagger_timer > 0.0 \
	or _recoil_timer > 0.0 \
	or not _savage_pounce_phase.is_empty() \
	or not _savage_chain_phase.is_empty():
		return
	var animation_name := &""
	if is_moving:
		animation_name = SAVAGE_ANIMATION_LIBRARY.get_movement_animation(
			facing,
			_custom_animation_presentation_sector
		)
	if animation_name.is_empty() or not _has_animation(String(animation_name)):
		animation_name = SAVAGE_ANIMATION_LIBRARY.get_idle_animation(facing)
	if not _has_animation(String(animation_name)):
		animation_name = &"idle_s"
	if not _has_animation(String(animation_name)):
		return
	animated_sprite.scale = custom_enemy_animation_scale
	_base_sprite_scale = animated_sprite.scale
	animated_sprite.flip_h = false
	_play_animation(String(animation_name), false)
	var animation_text := String(animation_name)
	var separator := animation_text.rfind("_")
	if separator >= 0:
		_custom_animation_presentation_sector = StringName(
			animation_text.substr(separator + 1)
		)


func _get_grunt_stagger_animation() -> StringName:
	if custom_enemy_animation_set == String(CUSTOM_ENEMY_GRUNT):
		var stagger_animation := GRUNT_ANIMATION_LIBRARY.get_stagger_animation(_last_move_direction)
		if _has_animation(String(stagger_animation)):
			return stagger_animation
	return GRUNT_STAGGER_ANIMATION


func _update_marine_enemy_animation(direction: Vector2, force_attack: bool = false) -> void:
	var facing := direction
	if facing.length_squared() <= 0.0001:
		facing = _last_move_direction
	animated_sprite.scale = custom_enemy_animation_scale
	_base_sprite_scale = animated_sprite.scale
	animated_sprite.flip_h = false
	if force_attack:
		var dash_animation := GRUNT_ANIMATION_LIBRARY.get_marine_dash_phase_animation(_marine_dash_phase, facing)
		if _has_animation(String(dash_animation)):
			animated_sprite.flip_h = facing.x < -0.05
			_play_animation(String(dash_animation), true)
			_play_custom_enemy_attack_fx(facing)
			return
	var animation_name := GRUNT_ANIMATION_LIBRARY.get_marine_idle_animation(facing)
	if not _has_animation(String(animation_name)):
		animation_name = &"marine_idle_s"
	if _has_animation(String(animation_name)):
		_play_animation(String(animation_name), false)


func _play_custom_enemy_attack_fx(facing: Vector2) -> void:
	if custom_enemy_fx_sprite == null or custom_enemy_fx_sprite.sprite_frames == null:
		return
	var fx_animation := GRUNT_ANIMATION_LIBRARY.get_attack_fx_animation(facing)
	if custom_enemy_animation_set == String(CUSTOM_ENEMY_MARINE):
		fx_animation = GRUNT_ANIMATION_LIBRARY.get_marine_dash_attack_fx_animation(facing)
	elif not custom_enemy_fx_sprite.sprite_frames.has_animation(String(fx_animation)):
		fx_animation = GRUNT_ATTACK_FX_ANIMATION
	if not custom_enemy_fx_sprite.sprite_frames.has_animation(String(fx_animation)):
		return
	custom_enemy_fx_sprite.visible = true
	custom_enemy_fx_sprite.scale = custom_enemy_fx_scale
	custom_enemy_fx_sprite.flip_h = facing.x < -0.05 and custom_enemy_animation_set == String(CUSTOM_ENEMY_MARINE)
	custom_enemy_fx_sprite.play(String(fx_animation))


func _play_custom_enemy_crit_fx() -> void:
	if custom_enemy_fx_sprite == null or custom_enemy_fx_sprite.sprite_frames == null:
		return
	if not custom_enemy_fx_sprite.sprite_frames.has_animation(String(GRUNT_CRIT_FX_ANIMATION)):
		return
	custom_enemy_fx_sprite.visible = true
	custom_enemy_fx_sprite.scale = custom_enemy_fx_scale
	custom_enemy_fx_sprite.flip_h = false
	custom_enemy_fx_sprite.play(String(GRUNT_CRIT_FX_ANIMATION))


func _play_grunt_flinch_fx() -> void:
	if custom_enemy_fx_sprite == null or custom_enemy_fx_sprite.sprite_frames == null:
		return
	if not custom_enemy_fx_sprite.sprite_frames.has_animation(String(GRUNT_FLINCH_FX_ANIMATION)):
		return
	custom_enemy_fx_sprite.visible = true
	custom_enemy_fx_sprite.scale = custom_enemy_fx_scale
	custom_enemy_fx_sprite.flip_h = false
	custom_enemy_fx_sprite.play(String(GRUNT_FLINCH_FX_ANIMATION))


func _clear_grunt_standard_hit_fx() -> void:
	if custom_enemy_fx_sprite == null:
		return
	custom_enemy_fx_sprite.stop()
	custom_enemy_fx_sprite.visible = false


func _spawn_grunt_critical_open_vfx(duration: float) -> void:
	_clear_grunt_critical_open_vfx(false)

	_critical_breach_marker_vfx = CRITICAL_BREACH_MARKER_VFX_SCENE.instantiate() as Node2D
	if _critical_breach_marker_vfx == null:
		push_error("[CombatVfx] Required BREACH marker scene could not instantiate.")
	else:
		_critical_breach_marker_vfx.position = grunt_critical_breach_marker_offset
		add_child(_critical_breach_marker_vfx)
		if _critical_breach_marker_vfx.has_method("configure_duration"):
			_critical_breach_marker_vfx.call("configure_duration", duration)

	_critical_window_ring_vfx = CRITICAL_WINDOW_RING_VFX_SCENE.instantiate() as Node2D
	if _critical_window_ring_vfx == null:
		push_error("[CombatVfx] Required critical-window ring scene could not instantiate.")
	else:
		_critical_window_ring_vfx.position = grunt_critical_window_ring_offset
		add_child(_critical_window_ring_vfx)
		if _critical_window_ring_vfx.has_method("configure_duration"):
			_critical_window_ring_vfx.call("configure_duration", duration)

	if grunt_optional_critical_vfx_enabled:
		var posture_flash := POSTURE_BREAK_FLASH_VFX_SCENE.instantiate() as Node2D
		if posture_flash != null:
			posture_flash.position = grunt_critical_breach_marker_offset
			add_child(posture_flash)


func _clear_grunt_critical_open_vfx(expired: bool) -> void:
	if _critical_breach_marker_vfx != null and is_instance_valid(_critical_breach_marker_vfx):
		_critical_breach_marker_vfx.queue_free()
	_critical_breach_marker_vfx = null
	if _critical_window_ring_vfx != null and is_instance_valid(_critical_window_ring_vfx):
		_critical_window_ring_vfx.queue_free()
	_critical_window_ring_vfx = null
	if expired and grunt_optional_critical_vfx_enabled:
		var expire_effect := CRITICAL_WINDOW_EXPIRE_VFX_SCENE.instantiate() as Node2D
		if expire_effect != null:
			expire_effect.position = grunt_critical_window_ring_offset
			add_child(expire_effect)


func _on_custom_enemy_fx_finished() -> void:
	if custom_enemy_fx_sprite != null:
		custom_enemy_fx_sprite.visible = false


func _update_procedural_variant_animation(direction: Vector2, is_moving: bool, force_attack: bool = false) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var direction_suffix := _get_procedural_variant_direction_suffix(direction)
	animated_sprite.flip_h = direction_suffix == "west"
	var animation_name := "idle_%s" % direction_suffix
	if force_attack:
		animation_name = "bite_%s" % direction_suffix
	elif is_moving:
		animation_name = "run_%s" % direction_suffix
	if not _has_animation(animation_name):
		animation_name = String(WOLF_ATTACK_ANIMATION if force_attack else (WOLF_MOVE_ANIMATION if is_moving else WOLF_IDLE_ANIMATION))
		if not _has_animation(animation_name):
			return
	if is_moving or force_attack:
		_play_animation(animation_name, false)
		return
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	animated_sprite.stop()
	animated_sprite.set_frame_and_progress(0, 0.0)


func _get_procedural_variant_direction_suffix(direction: Vector2) -> String:
	var facing := direction
	if facing.length_squared() <= 0.0001:
		facing = _last_move_direction
	if facing.length_squared() <= 0.0001:
		return "east"
	if absf(facing.x) >= absf(facing.y):
		return "west" if facing.x < 0.0 else "east"
	return "north" if facing.y < 0.0 else "south"


func _play_procedural_variant_death() -> void:
	if animated_sprite == null or not _has_animation(String(WOLF_DEATH_ANIMATION)):
		_finalize_corpse_state()
		return
	animated_sprite.play(String(WOLF_DEATH_ANIMATION))
	await animated_sprite.animation_finished
	_hold_animated_sprite_final_frame(StringName(WOLF_DEATH_ANIMATION))
	_finalize_corpse_state()


func _play_grunt_death() -> void:
	if animated_sprite == null or not _has_animation(String(GRUNT_DEATH_ANIMATION)):
		_finalize_corpse_state()
		return
	animated_sprite.stop()
	animated_sprite.flip_h = _last_move_direction.x < -0.05
	animated_sprite.play(String(GRUNT_DEATH_ANIMATION))
	await animated_sprite.animation_finished
	_hold_animated_sprite_final_frame(GRUNT_DEATH_ANIMATION)
	_finalize_corpse_state()


func _play_enemy_death_sfx() -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = ENEMY_DEATH_SOUND
	player.volume_db = -2.0
	player.max_distance = 480.0
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		player.free()
		return
	parent.add_child(player)
	player.global_position = global_position
	player.finished.connect(player.queue_free)
	player.play()


func _get_custom_ambient_scale_for_animation(animation_name: StringName) -> Vector2:
	if animation_name == CUSTOM_AMBIENT_EAST_ANIMATION:
		return custom_ambient_east_scale
	if animation_name == CUSTOM_AMBIENT_KO_ANIMATION:
		return custom_ambient_knockout_scale
	return custom_ambient_north_south_scale


func _play_custom_ambient_knockout() -> void:
	if animated_sprite == null or not _has_animation(String(CUSTOM_AMBIENT_KO_ANIMATION)):
		_finalize_corpse_state()
		return
	animated_sprite.flip_h = _custom_ambient_knockout_flip_h
	animated_sprite.scale = _get_custom_ambient_scale_for_animation(CUSTOM_AMBIENT_KO_ANIMATION)
	_base_sprite_scale = animated_sprite.scale
	animated_sprite.play(String(CUSTOM_AMBIENT_KO_ANIMATION))
	await animated_sprite.animation_finished
	_hold_animated_sprite_final_frame(CUSTOM_AMBIENT_KO_ANIMATION)
	_finalize_corpse_state()


func set_threat_highlight(enabled: bool) -> void:
	_threat_highlight_enabled = enabled
	if humanoid_cutout_rig != null and not _threat_highlight_enabled:
		humanoid_cutout_rig.set_visual_modulate(Color.WHITE)
	if not _threat_highlight_enabled and animated_sprite:
		animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		animated_sprite.scale = _base_sprite_scale


func _update_threat_highlight_visual(delta: float) -> void:
	if animated_sprite == null and humanoid_cutout_rig == null:
		return
	if not _threat_highlight_enabled:
		return
	_threat_highlight_time += delta
	var pulse: float = 0.5 + 0.5 * sin(_threat_highlight_time * 7.5)
	var intensity: float = lerp(1.0, 1.2, pulse)
	if _uses_humanoid_cutout_backend():
		humanoid_cutout_rig.set_visual_modulate(Color(intensity, 0.72, 0.72, 1.0))
		return
	animated_sprite.modulate = Color(intensity, 0.72, 0.72, 1.0)
	animated_sprite.scale = _base_sprite_scale * lerp(1.0, 1.06, pulse)
</file>

<file path="custodian/docs/ai_context/CONTEXT.md">
# PROJECT CONTEXT PRIMER — CUSTODIAN

Last updated: 2026-08-01

## Purpose

Operational handoff summary for active Godot implementation work.
Use this directory as the current AI-facing context pack, not `python-sim/ai/`.
Use `custodian/AGENTS.md` as the first local stop before using this pack.

## One-Paragraph Summary

CUSTODIAN is a Godot-native tactical base-defense game with an embodied operator, deterministic runtime simulation, contract-driven deployment, and an in-world command terminal. The active game lives in `custodian/`, the active implementation specs live in `design/`, and the old Python simulation/terminal stack remains preserved only as migration and design history.

## Current Lore Canon

The Severing is no longer framed as a collapse caused by lost shared context. The internal root cause is the Unnarrival: a supernatural/cosmic provenance wound that damaged reality's ability to maintain shared cause, memory, witness, and origin. Shared-context collapse, contradictory archives, and fragmented histories are symptoms. Knowledge recovery should be treated as provenance stabilization across object, origin, witness, time, use, and meaning.

> **Terminology note:** "Great Severance" is an obsolete variant (appears only in corrupted or earlier faction records). The canonical spelling is "the Severing" for the public catastrophe and "the Unnarrival" (double n) for the impossible root cause. See `design/03_world/lore/CORE_LORE.md` for the full terminology ladder.

## Canonical Runtime Facts

- Engine: Godot 4.x
- Main scene: `res://scenes/game.tscn`
- Beginning/Home scene: `res://scenes/home_custodian_begin.tscn` implements Objective 01, tracing the Custodian-band frequency to a damaged Field Terminal and establishing witness contact; it is a dedicated scene and not yet the application main scene.
- Runtime authority: Godot only
- Active command shell: HUD terminal in `custodian/game/ui/hud/ui.gd`, with terminal helper modules under `custodian/game/ui/terminal/`
- Current gameplay HUD style: compact Black Reliquary gothic/brass UI. Assets live in `custodian/content/ui/black_reliquary/`; reusable theme/components/HUD scenes live under `custodian/game/ui/`. Prompt text must be real Godot labels, not baked into images, the minimap frame should embed the shared live tactical minimap renderer rather than static marker art, authored-map-specific HUD content must only show inside its owning map, debug diagnostics should live in the dedicated F12/`debug_hud` debug screen instead of normal HUD labels, and terminal focus must mask gameplay overlays without re-showing inactive map-local HUDs.
- Command-terminal typography is a shipped two-font system: IBM Plex Sans Condensed owns display hierarchy, IBM Plex Mono owns data/input hierarchy, and the vendored TTF/OFL files live under `content/ui/fonts/`. Theme/page switches must preserve semantic fonts and sizes; bounded text ellipsizes instead of enabling horizontal scroll.
- Contract/runtime coupling: contract planet generation feeds procgen world generation through a shared world profile. `CustodianContractMap` disables child `ProcGen` ready-time auto-generation before tree entry and evaluates candidates with structural TileMap output but without final prop/nav work. The accepted candidate is promoted in place: its terrain, roads, regions, semantic dictionaries, and streaming state are preserved while only skipped final decoration, audits, shadows, and navigation refresh run. Candidate evaluation is not yet semantics-only. Streaming reveal defers foliage but ruin/interior props remain synchronous. Navigation still derives from painted TileMap cells and exposes authoritative/painted/AStar counts for lifecycle validation. Floor-value clustering is a logged no-op until at least two variant sources are registered.
- Input prompts: interaction UI should derive from `InputMap`, not hardcoded keys
- Operator combat selection: Fists/unarmed is a first-class `OperatorWeaponDefinition` profile selected with `toggle_unarmed`; normal weapon cycling excludes Fists and only cycles armed profiles. The offhand secondary button (`aim_hold` / `attack_secondary`, right mouse or LT) contextually selects primary ranged-ready, equipped sidearm-ready, or tap parry / held guard. Two-handed raise/lower clips may retarget without restarting, use separate 0.22s/0.12s targets and a 0.70 ready threshold, and shots commit direction through recoil. The read-only procedural reticle reflects exposed aim accuracy/fire readiness. `Shift+primary` remains the melee/unarmed heavy chord; movement supports WASD/left stick, mouse/right-stick aim, and movement-first dodge with idle aiming backstep. The Carbine phase-1 hybrid contract in `design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md` uses generated `e/w/se/sw` frame sockets for placement, muzzle/ejection, and draw order while existing modular weapon strips remain compatibility art. Camera aim zoom/lead is camera-controller presentation state and must remain additive with shake/bounds rather than becoming Operator-owned final framing.
- Parry-critical ownership is split across standalone vulnerability and paired execution contracts: the grunt owns enter/hold/recover at its independent post-knockback world root and suppresses normal targeting through recovery. Atomic reservation begins the separate shared-root execution; the Operator then owns alignment, the shared nonuniform eight-frame body/FX/victim timeline, source-frame-5 damage, the 110ms paired contact freeze, impact feedback, final settle, and unified cleanup. Matched S/E/W exports use grunt `melee__` names and a zero Operator offset because all paired full-cell exports preserve one canvas origin; vertical approaches use south until north art exists.
- Ranged balance authority: typed reserve caps, persistent weapon magazines, projectile falloff/range, weapon heat, positional gunshot noise, enemy search/leash behavior, and ambient hostile camps are defined by `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`. `NoiseEventBus` is the shared autoload boundary for gunfire and future explosion/door/vehicle noise; emitters must not call enemy scripts directly.
- Combat resource/readability integration authority: `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` tracks cross-system current state and remaining milestones. Completed V1 behavior stays authoritative in its permanent feature spec and Godot runtime home; the umbrella must link rather than restate ownership. Its current order is combat-pressure feedback, Field Patch healing, hit taxonomy/full riposte, durability, then traps and drone logistics.
- Operator Integrity Reclaim authority: `design/02_features/combat_feel/OPERATOR_INTEGRITY_RECLAIM.md` and the Operator-owned `combat/operator_integrity_reclaim.gd` helper own deterministic packet conversion/hold/decay/expiry math. Only actual nonfatal unblocked incoming damage creates packets; only confirmed direct Operator damage removed from living non-passive hostiles restores health. Enemy results clamp overkill, Field Patch healing clamps without refreshing packets, and the Black Reliquary health bar presents reclaim as a cyan trailing segment rather than a second meter.
- Fallen Star Katana fast-chain authority: `design/02_features/combat_feel/OPERATOR_MELEE_FAST_CHAIN.md`, `fallen_star_katana_definition.tres`, and the Operator melee state own the three distinct `7/7/8` clips, 18 FPS playback, first-valid single command slot, frame `5/5/6` contact/commit markers, `7/8/10` stamina, integrated stance recovery, Fast 03 feel hierarchy, post-contact final-frame dodge branch, and 75-degree link retarget clamp. The verified `3432x96` master is source-only; duplicate standalone candidates must not be wired.
- Forest Shrumb cognitive drops now have a v1 foundation through `InventoryManager`, `CognitiveState`, `cognitive_pickup`, `shrumb_dropper`, and the live `ambient_shrumb.tscn` actor. Ambient spawning now uses this shrumb actor directly; the former scav droid scene path is removed.
- Enemy rewards are corpse-bound: `Enemy` owns roll-once lifecycle state and final-frame persistence, while `EnemyCorpseLoot` exclusively delivers structured `resource_ledger`, `vault_recovery`, and `legacy_materials` channels on proximity collection. Lootable corpses cannot be cleaned up; empty corpses use low-frequency offscreen/hard-lifetime cleanup. Corpse payload persistence across scene unload/save remains unsupported.
- Procedural ruin prop variants have a v1 visual-only foundation under `custodian/content/props/ruins/`, using seeded layer assembly from authored sprites, overlays, rubble pieces, and a conservative palette shader. Collision remains authored and stable through `PropDefinition.collision_scene`.
- Procgen terrain construction now has a dedicated metadata-first `TerrainBuilder` pass under `game/world/procgen/terrain/`; elevation/cliff visuals remain separate from `ElevationMap` height/traversal rules and resolve through registered terrain sources in `procgen_world_tileset.tres`.
- Procgen world progression now has a route-first Intent Graph / Ascent V1 layer. `ProcGenTilemap.world_shape_mode` defaults to `ASCENT_FIELD`, which does not use the old BSP/corridor/cellular cave mask as the base world substrate. It builds a deterministic ascent spine, broad exterior route, terraces, branch pockets, sparse cliff/ruin blockers, and story/faction reservations from the world profile, then exports the graph/summary/reserved regions in level data. `LEGACY_CAVE` keeps the old generator path available. TerrainBuilder consumes intent required cells and reserved regions for guarded height/traversal metadata. Elevation traversal query API is live; actor/enemy pathfinding enforcement is deferred.
- Sundered Keep production access is `@world_origin -> vista_approach -> front_gate`. Procgen owns the generated playable frontage, floor/collision/navigation, shore boundary, props/enemies, clipped distant Keep reveal, and `procgen_landmark_terminal` ingress at the generated gate anchor. A normal short fade isolates that world and enters the authored Vista Approach / Shore Parish, which owns the near-Keep route, local ocean/storm/fortress presentation, mapper boundary rails, enemies, and set dressing; a second fade enters Front Gate. The procgen vista is presentation-only, absolute-depth below gameplay, clipped outside playable-floor bounds, and owns no collision/navigation. Return or failed entry restores procgen, Operator, camera-follow, and presentation-bounds state. Return Causeway stays `causeway_only`.
- Enemy marine dash is now a documented heavy commitment attack, not just forced sprite playback: windup/telegraph locks direction, dash travel owns the only active hit window, impact/recovery enforce a punish window, and feel comes from hitstop, knockback, camera shake, and Operator impact-lock feedback. Current runtime uses the east body/FX strip as fallback while directional dash body/FX sheets and the dash audio stack are tracked in `REQUIRED_ASSETS.md`.
- Enemy Savage is a low-discipline rushdown role, not a stronger grunt. `enemy_savage.tscn` uses the no-theft `raider_savage` profile, low durability/poise thresholds, a two-hit guard-pressure chain, and a distinct interruptible pounce with locked travel and punishable recovery. `enemy.gd` owns its fixed-step combat timing; current directional idle art remains presentation fallback until dedicated action sheets arrive.

## Active Architecture Snapshot

- Contract layer: contract map generation plus promoted runtime metadata
- World layer: procgen tilemap/runtime world systems
- Simulation layer: deterministic Godot runtime systems
- Cognitive layer: autoloaded inventory ledger and cognitive state values expose drop/combat modifier getters, with only pickup/drop feedback wired in v1
- UI layer: HUD + command terminal pages/widgets; terminal command parsing, authoritative snapshot projection, fidelity policy, canonical STATUS formatting, ranked Overview diagnosis, map preview, and planet preview helpers live under `game/ui/terminal/`. Terminal sector truth comes only from `Sector` instances in the dedicated `sector` group, while power telemetry uses explicit per-second generation/consumption/net keys without UI-side frame conversion. Physics-frame time and simulation state remain upstream truth; terminal modules only project read-only information.
- Black Reliquary UI layer: `game/ui/theme/` centralizes palette/styles/assets, `game/ui/components/` owns reusable compact panels/prompts/minimap/icon labels, and `game/ui/hud/custodian_hud.tscn` is the first local gameplay HUD shell used by Sundered Keep and Home. The Black Reliquary minimap component wraps `game/ui/minimap/minimap_panel.tscn` so it stays live while using gothic/brass chrome.
- Debug UI layer: `game/ui/hud/debug_screen.tscn` owns F12/`debug_hud` diagnostics as a read-only tabbed overlay fed by `game/ui/hud/ui.gd`. The former Dear ImGui Director Console and plugin are removed; player and developer surfaces use Godot `Control` UI.
- Debug data flow: gameplay systems expose read-only snapshots or group membership, `DebugSnapshotCollector` copies them after normal runtime updates, and `DebugBus` stores bounded stats/events/overrides/commands for Godot-native consumers. Dev mutations must use `DebugBus.queue_command(...)` or debug overrides and be applied by runtime owners at safe boundaries.
- Terminal overlay policy: `game/ui/hud/ui.gd` owns terminal-open suppression for legacy HUD labels, minimap/crosshair, `gameplay_overlay` HUD scenes, and the debug screen; a full-viewport dark scrim blocks pointer input beneath the terminal while keeping the terminal panel above it. Context-aware overlays such as the Sundered Keep HUD preserve their map-local active state when terminal suppression is removed. OVERVIEW prioritizes compact diagnosis cards and the shared live tactical map; the planet globe remains contextual to STATUS/CONTRACTS/ARCHIVE.
- Home beginning layer: `game/world/home/` owns the first Field Terminal witness-contact slice, using the Road of Witnesses prototype map and Black Reliquary HUD as the current presentation shell.
- Actor layer: operator, enemies, structures, defenses, ambient entities
- Authored-level layer: `AuthoredLevel2D` owns local content, named spawns, route-state hooks, and generic exit requests; `WorldIngressSite` owns origin capture/isolation/restoration; world-local `RouteTraversalManager` owns intra-campaign graph/session/profile/history/rollback/state/cache authority; `LevelLoader` owns one staged/active instance boundary; and `WorldIngressSpawner` deterministically combines route and level ingress definitions. See `design/04_architecture/{AUTHORED_LEVEL_AUTHORING_PIPELINE,ROUTE_TRAVERSAL_SYSTEM}.md`.
- Enemy dash layer: `enemy_marine.tscn` enables the shared enemy phased dash values; `enemy.gd` owns the generic marine dash phases and impact feedback; `operator.gd` exposes `apply_enemy_dash_impact(...)`; Sundered Keep's local hallway ambush mirrors the same heavy dash tuning.
- Stealth/perception layer: Operator movement exposes a read-only stealth snapshot, discrete loud actions publish through `NoiseEventBus`, enemy perception owns LOS/hearing, and the existing enemy behavior state machine owns investigate/pursue/search/return-home transitions. UI remains a read-only consumer of weapon status.

## Architecture Organization Status

An explicit architecture organization pass is now documented and tracked.
- `custodian/docs/ARCHITECTURE.md` defines 9 runtime layers with ownership boundaries
- `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md` answers "who owns what" for every major runtime concern
- `custodian/docs/ai_context/task_packets/ARCHITECTURE_ORGANIZATION_PASS.md` defines 6 migration phases and extraction candidates
- Large files (`proc_gen_tilemap.gd`, `custodian_contract_map.gd`, `contract_world_loader.gd`, `enemy.gd`, `game_state.gd`) should be treated as coordinator/facade candidates rather than permanent dumping grounds
- No runtime code has been moved yet — the organization pass is currently documentation and scaffold only
- The `docs/ai_context/VALIDATION_RECIPES.md` now includes architecture documentation validation commands

## Working Rules

- Treat `custodian/` and `design/` as the active implementation surface.
- Put active feature specs under `design/02_features/`; `design/20_features/` is retired and must not receive new work.
- Treat root `REQUIRED_ASSETS.md` as the sole asset-tracker authority; the design-tree file is a deprecated pointer, not a synchronized copy.
- Start all local work by reading `custodian/AGENTS.md`, then this context pack.
- Use task packets as optional risk-control and handoff records: skip narrow low-risk work, use the compact template when durable scope or acceptance helps, and expand it only for high-risk or multi-session work.
- When a task packet exists, keep it current as scope, blockers, acceptance, or deferred work materially changes.
- Use `custodian/docs/ai_context/VALIDATION_RECIPES.md` for validation command selection.
- Use `custodian/docs/ai_context/prompts/` for reusable task prompts, and confirm prompt paths before acting.
- Keep deterministic simulation separate from rendering/UI logic.
- High-value repeatable combat and presentation regressions should retain focused
  logic smoke coverage and may receive a Moment Forge scenario for deterministic
  audiovisual and game-feel evidence.
- When runtime behavior changes materially, update this directory alongside the relevant design/runtime docs.
- Do not silently shift authority back to Python-era systems or docs.

## Immediate Priorities

### Tier 1 — High-impact gameplay gaps

1. **Hit taxonomy and riposte (Milestone C).** Normalize hit-strength metadata at the damage boundary, add differentiated enemy/Operator reactions with heavy-enemy resistance, add explicit guard-break presentation, and implement the enemy-opened state plus unique riposte action after successful parry. Players currently cannot distinguish hurt/deflect/stagger/parry-opened/guard-impact/guard-break; this is the most impactful remaining combat readability gap. See `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` Milestone C and `PARRY_CRITICAL_BRANCHING_AND_VFX.md` for execution ownership.

2. **Enemy marine heavy dash art and audio.** Ingest or create the directional body sheets (minimum E/W/NE/NW/SE/SW), matching FX overlays, and five-part audio stack (windup, travel, impact, armor, recovery) tracked in `REQUIRED_ASSETS.md`. V1 gameplay is live with east-only fallback; production coverage is the single largest art gap blocking enemy combat readability.

3. **Melee profile consolidation.** Finish centralizing light/fast/heavy timing, active frames, recovery, range, arc, damage, knockback, hit-stop, camera impulse, and movement profile values into `MeleeAttackProfile` resources. The old operator melee exports remain deprecated fallbacks; completing this removes hidden per-weapon magic numbers and makes new enemy melee types cheaper to author.

### Tier 2 — World and systems depth

4. **Sundered Keep follow-up.** Encounter composition tuning, save/load persistence for gate/key state, and production labyrinth wall/void-edge/dressing art (currently `PLACEHOLDER_sundered_keep_labyrinth_*`). If the JSON-driven Sprite2D authored map becomes hard to maintain, begin the TileSet/TileMapLayer authoring migration documented in the level design spec.

5. **Home beginning scene transition decision.** Decide when `home_custodian_begin.tscn` becomes the boot/default entry, then wire it into the world-transition/campaign-flow spine without regressing the current contract/procgen sandbox. This is a content-flow milestone, not just an asset milestone — it requires the transition chain to handle first-run versus return.

6. **Terminal page extraction and richness.** Follow up on the decursification pass: extract remaining page renderers from `ui.gd` into dedicated scripts under `game/ui/terminal/`, deepen pages with richer live runtime data, and tighten layout polish. Terminal is the primary non-combat interaction surface and still has placeholder content on several pages.

7. **Elevation and terrain pathing enforcement.** The metadata-first TerrainBuilder and ElevationMap have traversal query APIs but do not yet enforce Operator, vehicle, or enemy path traversal. Wire enforcement for at least one enemy type and Operator movement so elevation has gameplay meaning beyond visuals and contract scoring.

8. **Compound infrastructure follow-up.** Powered Fabricator Milestone 1 is live: explicit grid components coexist with sector power, the Field Fabricator scales fabrication service output, and a fabricated Capacitor Bank moves through placement, construction, commissioning, damage-scaled storage, destruction, and versioned registry restoration. Next, connect registry state to the future project-wide save authority and extract the temporary placement compatibility path from `TurretPlacement`; preserve the existing Turret/Light Barricade bridge and do not expand into unrestricted base editing.

### Tier 3 — Integration and polish

9. **Forest Shrumb cognitive surface.** Wire true Forest Shrumbs into the intended spawning/procgen path and decide which cognitive readout belongs in HUD versus debug. The v1 runtime foundation (InventoryManager, CognitiveState, cognitive_pickup, shrumb_dropper) is live but the player-facing feedback loop is still open.

10. **Ruin prop production assets.** Author additional `PropDefinition` resources, overlay/rubble artwork, and chip/dirt/vine/highlight overlays under `custodian/content/props/ruins/`. The procedural prop variant foundation and procgen placement are live; what's missing is enough authored art variety to make the system feel intentional rather than sparse.

11. **Architecture organization pass execution.** The 9-layer ownership model and extraction candidates are documented but no runtime code has been moved yet. Prioritize the largest coordinator/facade files (`proc_gen_tilemap.gd`, `custodian_contract_map.gd`, `contract_world_loader.gd`, `enemy.gd`, `game_state.gd`) when a natural feature boundary creates a safe extraction window — do not move code for its own sake.

### Cross-cutting

- **Keep Sundered Keep/Home prompts and normal-play status surfaces on the compact Black Reliquary HUD API.** Route diagnostics to the dedicated debug screen; do not reintroduce giant panels or debug labels during normal gameplay.
- **Preserve and extend planet-to-runtime world coupling** as procgen evolves. Contract planet data must keep driving world profile variation without silent coupling breaks.
- **Clean deprecated `attack_light` compatibility** remnants from animation-state documentation and any surviving asset references.

## Update Expectation

On significant architecture or behavior changes, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/CONTEXT.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- relevant files under `custodian/docs/ai_context/task_packets/`
- relevant files under `custodian/docs/ai_context/prompts/`
- `custodian/AGENTS.md` when local routing, migration flow, or operating rules change

Optionally also update legacy changelog/devlog material for historical continuity.
</file>

<file path="custodian/docs/ai_context/VALIDATION_RECIPES.md">
# VALIDATION RECIPES

Canonical validation guide for CUSTODIAN agent work.

Use the narrowest recipe that proves the change, then broaden only when the change affects shared runtime behavior, scenes, imports, or workflow routing.

## Route Traversal V1

From `custodian/`, run the complete directed-route suite:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path . --import --quit
bash tools/validation/run_route_pipeline_suite.sh
```

The runner covers registry failures and disconnected enabled topology, forward/back authority, profile resolution, node and post-commit initial-entry rollback, world exfil, the single-level wrapper, all cache/state policies, physics-driven exit binding, the real Sundered graph/nested-state/authored-exit/no-direct-authority contracts, and route-aware scaffold create/append with full pre-write validation and failure immutability. For lifecycle changes also run the authored ingress/re-entry/rollback/single-authority smokes and `sundered_keep_ingress_smoke.gd`. Runtime `persistent` route state is process-local; save serialization is not claimed.

Prefer RTK subcommands for compact output when they support the command shape. RTK is not a blind prefix: use `rtk git status`, `rtk grep ...`, `rtk find ...`, etc. For unsupported commands where token tracking still helps, use `rtk proxy <command> ...`. Use the raw command when RTK changes argument ordering or hides information needed for debugging.

## Selection Rules

- Doc-only change: validate paths, links, status labels, and discoverability.
- Agent workflow change: validate `AGENTS.md`, `custodian/AGENTS.md`, `docs/ai_context/*`, any affected task packets, and prompt indexes.
- Runtime GDScript change: run a Godot headless check when feasible.
- Scene or asset import change: run Godot import before headless boot when feasible.
- Sprite pipeline change: run dry-run ingest first, then targeted ingest only when outputs are intended.
- Generic runtime-ready asset intake: run the persistent drop router in dry-run mode before apply.
- Tile pipeline change: run Python syntax checks plus the relevant tile generator command.
- Commit/staging task: inspect status with RTK, but do not stage or commit without explicit user approval.

## Common Commands

Run from the repository root unless the recipe says otherwise.

```bash
rtk git status
rtk git diff
rtk grep "pattern" path
rtk find path -maxdepth 3 -type f
```

Correction examples:

```bash
# Git status goes through the git subcommand:
rtk git status

# Exact porcelain status should stay raw:
git status --short

# Raw ripgrep can stay raw or go through proxy:
rg -n "pattern" path
rtk proxy rg -n "pattern" path
```

RTK grep argument order:

```bash
rtk grep "pattern" path --glob "*.md"
```

For complex ripgrep expressions, use raw `rg` or pass the raw command through `rtk proxy`:

```bash
rtk proxy rg -n --glob "*.md" "pattern" path
```

## Architecture / Documentation Organization Validation

Use for architecture docs, ownership map, task packet, and folder scaffold changes.

```bash
python custodian/tools/validation/architecture_ownership_smoke.py
```

This validates:

- new architecture docs exist (`ARCHITECTURE.md`, `ARCHITECTURE_OWNERSHIP_MAP.md`, `ARCHITECTURE_ORGANIZATION_PASS.md`)
- scaffold README.md files exist
- no stale `design/03_architecture` references remain inside `design/04_architecture/`
- reports line counts for overburdened coordinator files (warning only)

## Idea Codex Index Validation

Use after adding, removing, or graduating cards from `design/90_codex/`.

```bash
python tools/validate_design_codex.py
```

This validates:

- every `.md` card file under `design/90_codex/` has a matching row in `00_index.md`
- every index row has a corresponding card file on disk
- every card declares non-empty `Status`, `Category`, `Priority`, `Maturity`, and `Cost` metadata
- index status, priority, maturity, and runtime status match their card fields
- graduated cards point to an existing active spec with `Graduated to:` or an existing implementation with `Runtime path:`
- live runtime paths exist and no packaging directory such as `Cards-Wave-3/` remains under the Codex

## Doc-Only Validation

Use for markdown, routing, task packet, and context-pack edits.

```bash
rtk grep "referenced/path" AGENTS.md custodian/AGENTS.md custodian/docs/ai_context
rtk find custodian/docs/ai_context -maxdepth 3 -type f
```

Check:

- referenced files exist or are explicitly described as future work
- `CURRENT_STATE.md` reflects meaningful workflow/status changes
- `FILE_INDEX.md` indexes new docs, prompts, task packets, and ownership changes
- task packet status and completion notes match the actual work state when a packet exists

## Godot Runtime Validation

Use for runtime GDScript, scene wiring, autoload, input, or gameplay behavior changes.

```bash
cd custodian
godot --headless --quit
```

For turret placement resource and dismantle behavior:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/turret_placement_smoke.gd
```

For token-driven Light Barricade fabrication and placement, including Basic Turret regression:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/build_structure_placement_smoke.gd
```

Use import first when scenes/assets/resources changed:

```bash
cd custodian
godot --headless --import --quit
godot --headless --quit
```

Known caveat: current headless validation may exit with existing object/resource leak warnings. Treat new parse errors, missing resources, broken script loads, or changed fatal errors as blockers.

### Moment Forge — Selection And Evidence

```bash
# Select scenarios for current worktree changes
python3 custodian/tools/iteration/run_moment.py --changed

# Select scenarios for committed branch changes
python3 custodian/tools/iteration/run_moment.py --changed --base origin/main

# Deterministic gameplay assertions only
python3 custodian/tools/iteration/run_moment.py <scenario-id> \
  --capture-mode none

# Telemetry and authored-tick keyframes
python3 custodian/tools/iteration/run_moment.py <scenario-id> \
  --capture-mode evidence

# Full audiovisual review
python3 custodian/tools/iteration/run_moment.py <scenario-id> \
  --capture-mode full

# Repeatability proof
python3 custodian/tools/iteration/run_moment.py <scenario-id> \
  --capture-mode none \
  --repeat 2 \
  --require-identical-stable-fingerprint

# Complete focused suite
bash custodian/tools/validation/run_moment_forge_suite.sh
```

Full captures are not a default CI requirement. Advisory pixel and audio
differences must not fail CI — only stable assertions and deterministic metrics
are validation authority.

For Operator combat-resource feedback, compact HUD pressure state, and weapon-local presentation isolation:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home godot --headless --path . --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/ranged_combat_balance_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/combat_resource_feedback_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/combat_impact_audio_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_weapon_socket_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_ranged_ready_input_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_charged_long_roll_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_dodge_charge_feedback_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_dodge_flow_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_dodge_overlap_telemetry_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_modular_fast_attack_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_visual_anchor_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/codex_task_fixes_smoke.gd
```

For universal initiative, Vanguard Seal, relic equipment, and equipment-save
persistence:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home godot --headless --path . --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/initiative_vanguard_seal_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/inventory_ui_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/sundered_keep_vanguard_seal_acquisition_smoke.gd
```

The Sundered Keep acquisition smoke validates the authored East Command Cache
marker and interaction, dormant/contested lock states, secured activation,
single manual award, equipped-item duplicate protection, route persistence,
Gatehouse Core traversal, and independent P-9 locker availability.

The focused feedback smoke validates progress fields, dry/reload priority, held-input debounce, hot/critical/overheat/recovery transitions, monotonic reload transfer, per-weapon persistence, zero presentation `NoiseEventBus` emissions, and read-only HUD consumption. The impact-audio smoke validates the three ordered fast-melee swing renders and positional player plus all authored contact renders, ordered Return Causeway playlist retention and advancement, target profile assignments, light/heavy body selection, and Shrumb variant cycling. The modular fire and ready-input smokes additionally validate raise/lower direction retargeting without progress reset, committed shot direction, recovery-to-current-aim, posture/readiness status, upper/weapon direction plus frame-clock synchronization, missed-parry silence, and exactly one positional `parry_success_01.wav` cue on confirmed parry success. The charged-roll smoke validates tier selection, proportional speed, longer vulnerable recovery, stamina, invariant iframes, vulnerable charge, and hold/release input; the dodge-charge-feedback smoke validates asset/frame contracts, delayed ratio-driven presentation, compression/latch/release/rejection behavior, and temporary stamina-label copy. The Dodge Flow smoke validates active/late input windows, charge-derived Flow, directional retention, uncapped links, fixed iframe clocks, speed/travel/recovery modifiers, atlas entry frames, final cooldown, exit carry/decay, stamina constraints, signals, and telemetry. The overlap and modular-fast smokes preserve iframe/recovery classification and tap roll-exit compatibility. The socket smoke validates generated Carbine phase-1 metadata, socket-derived muzzle/draw order, transition timing, and camera-owned zoom/lead cancellation. Missing optional authored vent/HUD art warns without failing because the V1 presenter supplies a procedural vent and label fallback.

For allied drone fire/formation/guard-anchor commands:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/drone_follower_commands_smoke.gd
godot --headless --path . --script res://tools/validation/main_scene_allied_droid_smoke.gd
godot --headless --path . --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd
```

These checks cover Operator/order-point anchor state, close/far/roam goals around guard points, guard return limits,
marker and replacement-drone inheritance, `K` restoring both Operator anchor and tactical FOLLOW, manager-owned InputMap actions, hold-fire cancellation, and suppression
of accidental Operator primary fire while issuing an order. The follower smoke also frees a live explicit command target
and verifies the drone clears that stale reference before entering typed targeting code.

For Developer Observatory telemetry and JSON session export:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/dev_observatory_smoke.gd
godot --headless --path . --script res://tools/validation/dev_observatory_audit_smoke.gd
godot --headless --path . --script res://tools/validation/dev_observatory_director_population_smoke.gd
godot --headless --path . --script res://tools/validation/operator_ammo_reconciliation_smoke.gd
godot --headless --path . --script res://tools/validation/operator_dodge_overlap_telemetry_smoke.gd
godot --headless --path . --script res://tools/validation/dev_mode_smoke.gd
godot --headless --path . --script res://tools/validation/sector_heatmap_smoke.gd
godot --headless --path . --script res://tools/validation/material_intelligence_smoke.gd
godot --headless --path . --script res://tools/validation/power_grid_component_registration_smoke.gd
```

This proves bounded telemetry storage, F9/F10 action registration, stable and timestamped JSON output, JSON-safe Variant
conversion, event-buffer retention, success-event logging, failure-warning routing, numeric accumulation, and basic heatmap accumulation.
The audit smoke additionally proves hidden Observatory processing performs no recursive runtime scans, visible sampling performs one consolidated scan, export forces a current snapshot, reconciles a shared enemy attack ID through incoming-hit/player-damage events, proves a
live bullet owns a projectile-classified collision shape, and checks cumulative damage/healing/chip amounts, ranged
failure/cancellation categories, performance/leak peaks, last-live post-death context, Field Patch prompt
severity/ignored-on-death accounting, and the structured player-death snapshot. The Falcon and paired-critical smokes
cover detailed special terminals plus vulnerable-window open/consume/expire and critical start/hit telemetry. The
procgen stuck-pocket smoke checks structured remediation warning context. The ammo smoke emits 18 real projectiles and reconciles a fresh carbine from 24/48 to 6/48 without a weapon
swap. The dodge smoke classifies 20 deliberate overlaps one-for-one across iframe, late-active, and recovery phases.
The director-population smoke deliberately enables two profile-managed enemies beside one legacy enemy and reconciles
the split population gauges plus the director behavior-sample surface.
The DevMode smoke proves release-default-off, debug/feature/project/command-line
resolution, explicit-only heavy diagnostics, negative overrides, load order
before debug consumers, F6/F7/F8 playtest bindings, free-camera state
restoration, and the Operator resource-override hook.
The Material Intelligence smoke proves safe unknown fallback, typed profile
lookup, explicit cell overrides, cumulative material-contact aggregation,
low-weight Heatmap tagging, and Observatory export. The power-grid registration
smoke additionally proves repeated stable allocations do not duplicate
`infrastructure_power_tier_changed`.

For modular visual-fit next-action reporting:

```bash
python3 -m py_compile custodian/tools/operator/modular_combo_check.py custodian/tools/operator/operator_next_actions_report.py
python3 custodian/tools/validation/operator_next_actions_report_smoke.py
python3 custodian/tools/operator/modular_combo_check.py ne --check-dir /tmp/custodian_combo_check_ne --clean
bash custodian/tools/operator/refresh_combo_check_src.sh
python3 custodian/tools/operator/modular_combo_check.py \
  --src /tmp/custodian_combo_check_src \
  --check-dir .ai/operator_modular_combo_check \
  --fit-report-only --fit-debug --next-actions
```

The smoke validates the versioned generated-artifact schema, contract-group join, fast-attack phase grouping, canonical/actionable source and runtime paths, commands, acceptance criteria, Markdown, and HTML loader. The `ne` command proves positional direction selection stages all matching runtime sheets, combines exact lower/upper action and loadout counterparts, and reports one-sided coverage without unrelated action fan-out. The report-only command proves existing previews can gain refreshed fit evidence and recommendations without rebuilding PNG/GIF outputs.

For the local exported-session report tool, run from the repository root:

```bash
python3 -m py_compile custodian/tools/analysis/analyze_dev_observatory_session.py
python3 custodian/tools/analysis/analyze_dev_observatory_session.py /path/to/latest_session.json
```

After sourcing the repo aliases, `obsreport` runs the same analyzer and discovers
the stable latest-session export when no path is supplied.

Omit the path to analyze the stable export in the standard Godot user-data location when it exists.

For authored parry critical-open phases and paired execution:

```bash
cd custodian
godot --headless --path . --import --quit
godot --headless --path . --script res://tools/validation/grunt_falcon_punch_smoke.gd
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/debug_grunt_spawn_modes_smoke.gd
godot --headless --path . --script res://tools/validation/grunt_animation_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
godot --headless --path . --script res://tools/validation/operator_knockdown_animation_smoke.gd
```

The Falcon smoke validates stop-short travel, body/enemy separation, dedicated Operator impact, zero-drift recovery,
hard parry cancel/lockout, deterministic eligibility, ally-lane rejection, terminal diagnostic fields, and seven stationary
connection samples at each of 96, 136, and 176 pixels. The focused reaction smoke validates required S/E/W asset dimensions, independent post-knockback roots through enter/hold/recover, normal target-ring suppression through recovery, BREACH/ring lifetime, posture-break/expiry frame timing, offsets, auto-free, and toggle suppression, atomic reservation, approach-owned directional selection with vertical-to-south fallback, zero-offset shared execution roots, zero-local paired layers plus transform restoration, same-tick semantic playback through the nonuniform eight-frame duration table, source-frame-5 exactly-once damage, the 110ms paired contact freeze, final-settle ownership, lethal/nonlethal resolution, and cancellation cleanup. The debug-spawn smoke validates each critical-open/execution-ready preset, opportunity presentation, one-health lethal setup, and unknown-mode rejection. Paired/open and optional-bookend runtime scenes are preloaded and fail loudly if their scene or strip contract is missing; the optional toggle controls playback rather than resource availability.

For Sundered Keep asset wiring specifically:

For the production Sundered Keep generated frontage, Shore Parish / Outer Wall,
and Front Gate correction:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/sundered_keep_procgen_frontage_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_world_vista_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_approach_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_approach_outskirts_mapper_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_parish_route_correction_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_large_layout_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_route_graph_smoke.gd
godot --headless --path . --script res://tools/validation/route_profile_selection_smoke.gd
bash tools/validation/run_procgen_validation_suite.sh
bash tools/validation/run_route_pipeline_suite.sh
```

These smokes prove protected procgen floor/corridor authority, exactly one
world-side camera reveal, fade-only production edges, production Parish mapper
authority, supplied ground/detail/local-fog wiring, continuous eastward rails,
the Front Gate arrival apron and 144 px guard, deterministic frontage output,
and route/profile connectivity.

Graphical evidence requires an active X11/Wayland renderer; Godot's `headless`
display driver is dummy-only and cannot export viewport pixels:

```bash
godot --display-driver x11 --rendering-method gl_compatibility --path . \
  --script res://tools/validation/sundered_keep_procgen_frontage_seed_review.gd \
  -- --output-dir res://../reports/sundered_keep_route_correction --seeds 1
godot --display-driver x11 --rendering-method gl_compatibility --path . \
  --script res://tools/validation/sundered_keep_route_correction_review.gd \
  -- --output-dir res://../reports/sundered_keep_route_correction
```

Review frames must be 2560×1440 and require human approval. A successful image
export does not promote the task packet beyond `review`.

For the reusable authored-level scaffold and registry ingress pipeline:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/level_named_spawn_smoke.gd
godot --headless --path . --script res://tools/validation/level_registry_contract_smoke.gd
godot --headless --path . --script res://tools/validation/level_collision_poi_mapper_smoke.gd
godot --headless --path . --script res://tools/validation/world_ingress_spawner_smoke.gd
godot --headless --path . --script res://tools/validation/level_scaffold_generator_smoke.gd
godot --headless --path . --script res://tools/validation/authored_level_ingress_return_smoke.gd
godot --headless --path . --script res://tools/validation/authored_level_reentry_smoke.gd
godot --headless --path . --script res://tools/validation/level_presentation_profile_smoke.gd
godot --headless --path . --script res://tools/validation/level_entry_rollback_smoke.gd
godot --headless --path . --script res://tools/validation/world_ingress_physics_reentry_smoke.gd
godot --headless --path . --script res://tools/validation/level_return_single_authority_smoke.gd
godot --headless --path . --script res://tools/validation/level_return_rejected_smoke.gd
godot --headless --path . --script res://tools/validation/level_origin_destroyed_smoke.gd
godot --headless --path . --script res://tools/validation/level_camera_rebind_smoke.gd
```

These checks prove named-spawn success/failure without actor mutation, every registered entry scene's spawn/presentation/lifecycle and mapper boundary contract, generic mapper dynamic schema and Sundered compatibility, deterministic multi-ingress spacing/identity, alternate-root scaffold dry-run/creation/duplicate rejection/managed regeneration/unmanaged rejection/registry sorting, exact procgen/connected branch and camera restoration, loader/ingress cleanup, real physics-driven repeat entry, profile selection, atomic actor/camera/UI rollback, immediate outgoing-level deactivation, fail-closed rejected returns, and non-committing destroyed-origin failure. The existing `sundered_keep_ingress_smoke.gd` exercises `ContractWorldLoader`'s registry-driven placement path rather than the deprecated Sundered-specific helper.

For Sundered Keep production ingress and return acceptance:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/sundered_keep_ingress_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_procgen_vista_layering_smoke.gd
godot --headless --path . --script res://tools/validation/route_registry_contract_smoke.gd
godot --headless --path . --script res://tools/validation/authored_level_ingress_return_smoke.gd
```

The retired `sundered_keep_approach_route.tscn` and its
`sundered_keep_approach_route_smoke.gd` / `_visual_smoke.gd` tests are
legacy/debug-only historical comparison surfaces. They are excluded from
production acceptance. In particular, their old `configure_connection()`
expectation must not be added to the current Front Gate map.

```bash
cd custodian
godot --headless --script tools/validation/sundered_keep_asset_smoke.gd
```

This instantiates the authored Sundered Keep connected map and fails if any `Sprite2D` in the slice has a missing texture.

For the walkable Sundered Keep underlay-only gameplay debug scene:

```bash
cd custodian
godot --headless --script tools/validation/sundered_keep_underlay_gameplay_debug_smoke.gd
godot --headless --script tools/validation/sundered_keep_mapper_smoke.gd
```

The underlay debug smoke retains the focused underlay-only runtime check.
The unified mapper smoke proves the tool previews the actual production Keep,
owns the level and collision documents, retains 127 rails and the 01–99
palette/stamp/undo toolset, exposes on-map selection/movement/creation for
complete spatial and siege placement authority, and keeps Return Mooring's
linked records aligned under one bundle operation.

For the Sundered Keep overlay-authoring guide pipeline:

```bash
python custodian/tools/levels/generate_sundered_keep_overlay_authoring.py
cd custodian
godot --headless --script tools/validation/sundered_keep_overlay_authoring_smoke.gd
```

This regenerates the deterministic tile-space guide from the master overlay and verifies the standalone review scene plus the live map linkage still load cleanly.

For fabrication terminal readability / work-order translation changes:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/terminal_stylebox_rendering_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_typography_smoke.gd
godot --headless --path . --script res://tools/validation/fabrication_terminal_layout_smoke.gd
godot --headless --script tools/validation/fabrication_terminal_readability_smoke.gd
godot --headless --script tools/validation/fabrication_terminal_command_smoke.gd
godot --headless --path . --script res://tools/validation/fabrication_terminal_clickable_smoke.gd
```

This validates crisp terminal `StyleBoxTexture` rendering with border-only tile-fit frames and stretched single-center controls, the shipped display/mono font hierarchy and disciplined sizes, flat Fabrication row labels, selected-row/detail synchronization, structured resource rows, collapsed empty build status, fixed-width/no-page-scroll FABRICATION layout, the scrollable page rail, the live terminal translation layer, readable next-action text, the `BUILD PLACE <ready_build_id>` placement alias against runtime autoloads, and the dedicated clickable `FabricationWidgets` page in the main scene.

For command-terminal Overview hierarchy, header/nav fit, or modal containment changes:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/terminal_status_fidelity_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_snapshot_sector_identity_smoke.gd
godot --headless --path . --script res://tools/validation/power_rate_units_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_overview_semantics_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_overview_live_snapshot_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_overview_layout_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_defense_semantics_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_overlay_visibility_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_typography_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_stylebox_rendering_smoke.gd
godot --headless --path . --script res://tools/validation/fabrication_terminal_layout_smoke.gd
```

This validates deterministic simulation-clock STATUS output and elapsed header formatting, all four fidelity omission levels, command/field asymmetry, sector-only identity despite broader turret/structure membership, delta-independent per-second power rates, weighted and stable Overview diagnosis, live deficit recommendation routing, health-first Defense readiness, honest unavailable engagement controls, the 1366×768 safe Overview composition, container-based status chips, collapsed secondary nav and reduced default actions, dominant shared tactical map, all diagnosis cards, actionable attention feed, command/transcript containment, visible-pointer modal behavior, a real GUI-routed page-button click through the full-viewport input-blocking scrim, gameplay-overlay suppression/restoration, typography, terminal skin rendering, and Fabrication layout compatibility.

For Field Patch healing or restock changes:

```bash
cd custodian
godot --headless --script tools/validation/field_patch_smoke.gd
```

This validates input binding, timed commit healing, interruption semantics, capped restock helpers, terminal fabrication restock, cap-blocked no-spend behavior, and emergency-cache fallback materials.

For Operator Integrity Reclaim changes:

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/operator_integrity_reclaim_smoke.gd
godot --headless --path . \
  --script res://tools/validation/field_patch_smoke.gd
godot --headless --path . \
  --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd
godot --headless --path . \
  --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
```

The focused smoke proves exact reclaim math, independently expiring packets,
second-hit forfeiture, eligible-source filtering, overkill and health ceilings,
fatal clearing, healing clamp without timer refresh, HUD trailing-fill
composition, and repeat-run fixed-step determinism. Adjacent smokes preserve
Field Patch, projectile delivery, and paired-critical behavior.

For Vigil-Pattern Dagger, Sword-Cleaver, or generic melee attack-drive changes:

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/operator_vigil_dagger_smoke.gd
godot --headless --path . \
  --script res://tools/validation/operator_sword_cleaver_smoke.gd
godot --headless --path . \
  --script res://tools/validation/operator_melee_fast_chain_smoke.gd
godot --headless --path . --quit \
  --scene res://scenes/game.tscn
```

The dagger smoke validates the default definition, three-link resources,
contact/commit timing, synchronized E/W body/weapon/FX playback, bounded
movement, input filtering, wall truncation, no snapback, and interruption
cancellation. The cleaver smoke validates its explicit override, independent
per-link profiles, synchronized provisional Chain 01 reuse, bounded finisher
drive, and the unchanged dagger default. The Katana smoke remains the separate
later-weapon regression.

For Fallen Star Katana fast-chain changes:

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/operator_melee_fast_chain_smoke.gd
godot --headless --path . \
  --script res://tools/validation/operator_modular_fast_attack_smoke.gd
godot --headless --path . \
  --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . \
  --script res://tools/validation/operator_charged_long_roll_smoke.gd
```

The focused smoke validates the verified `3432x96` master and distinct
`7/7/8` runtime slices, 18 FPS non-looping registration, `1 -> 2 -> 3 -> 1`
command order, frame `5/5/6` contact/commit authority, first-valid buffering,
stamina, heavy and final-stance dodge branches, whiff continuation, one-hit
dedupe, integrated recovery, Fast 03 feel hierarchy, reset causes, and the
75-degree retarget limit. Adjacent smokes preserve legacy modular Fists,
paired-critical, and dodge behavior.

For the native Godot lighting layer:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home \
  godot --headless --path . \
  --script res://tools/validation/lighting_system_smoke.gd

env HOME=/tmp/custodian-godot-home \
  godot --headless --path . \
  --script res://tools/validation/world_atmosphere_smoke.gd
```

The first command instantiates the standalone lighting playground plus the shadowed gatehouse reference room and checks
the `WorldLightingDirector`, `CanvasModulate`, `DirectionalLight2D`, authored light cookies, shadow/height/asymmetric
rig settings, darker `LightingZone2D`, major-geometry `LightOccluder2D` polygons, animated dust, and transient additive
flash pool. The second command checks live `game.tscn` lighting/profile/atmosphere wiring, UI layer separation, runtime
fog/cosmic propagation, the combined foliage wind/occlusion shader contract, and representative persistent light rigs.

For TerrainBuilder/procgen connectivity changes:

```bash
cd custodian
godot --headless --script res://tools/validation/terrain_builder_smoke.gd
godot --headless --script res://tools/validation/terrain_ballistics_smoke.gd
godot --headless --script res://tools/validation/procgen_terrain_required_cells_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_playability_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_route_clearance_smoke.gd
godot --headless --path . --script res://tools/validation/terrain_gameplay_art_usage_smoke.gd
godot --headless --path . --script res://tools/validation/floor_value_clusters_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_combat_readability_smoke.gd
```

These commands validate TerrainBuilder determinism, ballistics/traversal
metadata, bounded required-cell connectivity, playability distance/pocket
classification, production route presentation and post-decoration clearance,
gameplay-pack art mappings, floor-value clustering, and combat readability.
They are part of the default procgen suite.
For production-sized contract rescue diagnostics, use the slow suite mode from the repository root:

```bash
RUN_SLOW_PROCGEN=1 bash custodian/tools/validation/run_procgen_validation_suite.sh
```

This includes `procgen_contract_rescue_diagnostic_smoke.gd`, which generates fixed production-sized candidate attempts
at `176x176`, `208x224`, and `224x224`, prints required-cell source/reason classification, compares layout walkability,
TerrainBuilder baseline floor/wall walkability, and semantic required walkability, reports component/bridge diagnostics,
and fails if baseline rescue, pre-terrain required connectivity, candidate acceptance, or forced failure-safe emission
regresses. The expected production rescue baseline is no TerrainBuilder baseline rescue for the selected seeds; authority
repair should happen through `game/world/procgen/diagnostics/` before TerrainBuilder receives the floor/wall graph, with
`ProcGenTilemap` acting as the context/state façade.

For a batch run that captures per-step exit codes while teeing a timestamped log, use:

```bash
custodian/tools/validation/run_procgen_validation_suite.sh
```

This wrapper fails the shell command if any included smoke fails, so assertion or script failures are not hidden by log piping.
Pass `--full` or set `RUN_SLOW_PROCGEN=1` to include the production contract rescue diagnostic; the default suite skips it
to stay quick.

For foliage extraction / deferred spawn changes:

```bash
cd custodian
godot --headless --script res://tools/validation/procgen_foliage_spawner_smoke.gd
godot --headless --script res://tools/validation/procgen_deferred_foliage_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_combat_readability_smoke.gd
godot --headless --path . --script res://tools/validation/prop_collision_alignment_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_stuck_pocket_smoke.gd
```

The first command validates the extracted foliage service's deterministic generate/remove/clear lifecycle and shared same-kind material ownership. The second
checks that final-visual foliage queues batch into placed nodes over subsequent frames. The third validates combat-aware
canopy occlusion profile switching and readability clearance hooks. The fourth audits every ruin prop definition against
the bottom-contact collision contract and verifies per-instance collision debug. The fifth proves collision-owner blocker
lifecycle, definition-footprint rejection before instantiation, existing-blocker rejection, corrected global
prop-footprint registration, local escape detection/remediation, and required-route clearance without relying on a full
contract generation. Run `procgen_authored_scene_authority_smoke.gd` after placement-policy changes to confirm a full
seed produces no protected-zone backup warnings after portal routes are finalized.

For compact runtime-wall collision ownership:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/runtime_wall_collision_compaction_smoke.gd
godot --headless --path . --script res://tools/validation/compound_wall_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_authored_scene_authority_smoke.gd
```

The compaction smoke proves a representative generated map owns materially fewer chunk bodies than per-tile shapes,
then destroys one wall through impact-position resolution and verifies an adjacent wall retains visual and collision
authority. The existing smokes guard tile-scoped destruction and authored footprint clearing.

## Manual Godot Validation

Use when behavior requires play, input, camera, animation, UI, collision, or visual confirmation.

```bash
cd custodian
godot
```

Check the specific acceptance path from the task packet when one exists; otherwise use the active spec and task request. For runtime gameplay changes, include deterministic concerns in the result notes: fixed-step simulation ownership, input mapping, and whether UI/rendering stayed out of simulation authority.

## Sprite Pipeline Validation

Use for sprite intake, runtime animation slices, and curated operator resources.

For the high-resolution source-art preparation command:

```bash
python3 -m py_compile custodian/tools/art/source_to_pixel_art.py custodian/tools/validation/source_to_pixel_art_smoke.py
python3 custodian/tools/validation/source_to_pixel_art_smoke.py
bash -n tools/custodian_aliases.sh
```

After sourcing `tools/custodian_aliases.sh`, run `pixelart source.png [output.png]` for the interactive
three-candidate review. Use `--choose crisp`, `--choose balanced`, or `--choose clustered` for reproducible
non-interactive conversion.

Read first:

- `custodian/content/sprites/_pipeline/README.md`
- `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`
- `custodian/docs/ASSET_LAYOUT_CONVENTION.md`

Typical dry-run shape:

```bash
cd custodian
python tools/pipelines/ingest.py --dry-run <manifest_or_source>
```

Only run non-dry-run ingest when generated files are intended. Ingest writes and archives files but does not stage or commit them; inspect `git status --short` afterward.

For a mixed canonical inbox batch (including enemy, curated Operator, cape, and ranged-weapon modular sheets), generate manifests and ingest through the combined entrypoint so every declared post-process runs:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run --remove-superseded
python custodian/tools/pipelines/generate_inbox_manifests.py --remove-superseded
```

For the current roll-exit/parry/execution/relaxed-carbine batch, follow the applied ingest with `operator_modular_fast_attack_smoke.gd`, `operator_modular_defense_ranged_smoke.gd`, `operator_primary_ranged_modular_fire_smoke.gd`, and `grunt_parry_crit_reaction_smoke.gd`.

For modular Operator naming/routing and generic action module generation:

```bash
python -m py_compile custodian/tools/pipelines/generate_inbox_manifests.py custodian/tools/pipelines/build_actor_spriteframes.py
python custodian/tools/validation/non_operator_actor_pipeline_smoke.py
python custodian/tools/validation/operator_modular_pipeline_smoke.py
godot --headless --path custodian \
  --script res://tools/validation/sprite_directional_mirror_pipeline_smoke.gd
```

The directional mirror smoke proves default `e↔w`, `ne↔nw`, and `se↔sw` path generation for Operator,
enemy, allied/simple-character, and generic owner domains; authored counterpart precedence; the no-mirror
opt-out; and per-frame horizontal pixel flipping. The other smokes cover modular-head inbox routing and the
`head/actions/<profile>/<action>/` runtime module contract.
After rebuilding curated resources, `operator_modular_layers_smoke.gd` verifies the hooded south-idle animation is
registered, visible with modular unarmed idle, frame-synchronized to the upper body, and hidden when directional
head coverage is unavailable.

For modular Operator contract coverage, suspicious filename/frame metadata, and next-batch reporting:

```bash
python custodian/tools/validation/operator_animation_contract_report.py
python custodian/tools/validation/operator_animation_contract_report.py --strict
python custodian/tools/validation/operator_animation_contract_report_smoke.py
```

`--strict` is expected to fail while required art coverage or required metadata is incomplete. Treat that as a
production coverage report, not as a reason to fake missing assets.

For live modular Operator defense/ranged presentation wiring:

```bash
cd custodian
godot --headless --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```

This instantiates the Operator and verifies east-facing parry recovery resolves to modular lower/upper recovery
clips, and east two-handed ranged-ready stance uses the modular upper/weapon stack instead of falling through to
legacy full-body presentation.

For live modular Operator fast-attack playback wiring:

```bash
cd custodian
godot --headless --script res://tools/validation/operator_modular_fast_attack_smoke.gd
```

This checks existing fast-attack source/runtime PNG coverage against the lower-body, upper-body, and upper-FX
`SpriteFrames` resources, then instantiates the Operator and verifies windup, strike, and recovery helpers play the
modular layers for every direction where body coverage exists while preserving legacy fallback/timing ownership. It
also proves that fast primary can buffer during active dodge without cancelling iframes, consumes at roll exit,
preserves dodge cooldown, skips the ordinary unarmed windup, and selects the ingested combined body/FX/cape
presentation when those runtime sheets are present.

For the active Savage first runtime slice:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/savage_runtime_smoke.gd
```

This validates mixed frame-size idle strips, direction fallbacks, scene activation, and factory/wave/main-scene wiring.

For the Savage rushdown gameplay contract:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/enemy_savage_smoke.gd
```

This validates the approved stats and `raider_savage` profile, no-theft behavior, chain/pounce activation, both chain
hits, the stronger second-hit guard cost, and the pounce hit contract.

For the focused modular Operator ingest loop, use the thin repo-root wrapper. It defaults to dry-run; `--apply` runs
shared-inbox manifest generation, rebuilds modular Operator runtime sheets, runs Godot import, refreshes curated
SpriteFrames, runs the modular layer smoke, and writes an animation contract JSON report.

```bash
custodian/tools/operator/operator_ingest.sh --dry-run
custodian/tools/operator/operator_ingest.sh --apply
```

After sourcing `tools/custodian_aliases.sh`, the same focused wrapper is available as
`opingest --dry-run` or `opingest --apply`. For a generic inbox ingest that must also rebuild already-authored
Operator modular source, use:

```bash
python custodian/tools/pipelines/ingest.py --build-operator-runtime --remove-superseded
```

`--build-operator-runtime` runs only after successful ingest and also respects `--dry-run`.

For modular Operator action QA previews:

```bash
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --action block_loop_01 --directions e,w --include-fx
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --sequence fast_windup_01,fast_strike_01,fast_recovery_01 --include-fx
python custodian/tools/validation/operator_action_preview_smoke.py
```

Preview output under `custodian/animation_review/` is review-only and should not become runtime authority.

For new modular-compatible character production planning:

```bash
python custodian/tools/pipelines/scaffold_character_contract.py --owner enemy_ritualist --template humanoid_combat --frame-size 96 --directions s,se,e,ne,n,nw,w,sw
python custodian/tools/validation/scaffold_character_contract_smoke.py
```

For modular Operator asset inventory and visual review tool selection, read:

- `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md`

For opt-in superseded-animation cleanup:

```bash
python custodian/tools/validation/sprite_superseded_cleanup_smoke.py
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run --remove-superseded
```

## Runtime-Ready Asset Drop Validation

Use for already-runtime-ready assets that do not require specialized sprite processing:

```bash
python custodian/tools/pipelines/runtime_ready_assets.py --dry-run
python custodian/tools/validation/runtime_ready_asset_pipeline_smoke.py
python custodian/tools/pipelines/runtime_ready_assets.py --apply --godot-import
```

The apply command rejects different existing targets unless `--replace` is intentionally supplied.

## Tile Pipeline Validation

Use for wall tile extraction, composition, and procgen wall atlas bridge work.

```bash
python3 -m py_compile tools/tiles/extract_wall_parts.py tools/tiles/compose_wall_variants.py tools/tiles/build_procgen_wall_atlas.py
```

Then run the specific generator command documented in the relevant design or README file.

## Terrain Gameplay Pack Pipeline Validation

Use for terrain gameplay pack ingest, TileSet registration, and pack integrity checks.

```bash
# Ingest all three packs (connector, ascent, chasm+bridge) from source sheets
python custodian/tools/tiles/ingest_generated_terrain_packs.py

# Register runtime PNGs into procgen_world_tileset.tres
python custodian/tools/tiles/register_terrain_gameplay_packs.py --dry-run

# Validate packs, registration report, and active TileSet atlas-source resolution
cd custodian
godot --headless --script res://tools/validation/terrain_gameplay_packs_smoke.gd
godot --headless --path . --script res://tools/validation/terrain_gameplay_art_usage_smoke.gd
```

Validates:
- All runtime PNGs exist in `runtime/{connector,ascent,chasm_bridge}/`
- All PNGs are 32×32 RGBA with valid alpha
- Manifests reference every runtime file
- Symbolic IDs in `terrain_tile_ids.gd` match runtime filenames
- Non-walkable tiles (chasm void/edge/corner, broken gap) resolve correctly
- `procgen_world_tileset.tres` loads and resolves every registered connector/ascent/chasm_bridge runtime PNG as a TileSetAtlasSource
- `ProcGenTilemap.TERRAIN_TILESET_SOURCES` resolves all 62 gameplay-pack IDs and representative tiles paint the expected floor/wall source
- Expected atlas source ID ranges exist: connector `60..77`, ascent `80..99`, chasm_bridge `100..123`
- Each registered source uses `32x32` texture regions and contains atlas coord `(0, 0)`
- `reports/terrain_pack_ingest/terrain_gameplay_tileset_sources.json` has expected counts and no duplicate source IDs
- No checkerboard artifacts in runtime images

Ingest reports are written to `reports/terrain_pack_ingest/terrain_pack_ingest_report.md`.
TileSet source maps are written to `reports/terrain_pack_ingest/terrain_gameplay_tileset_sources.json`.
Direction/corner review notes belong in `reports/terrain_pack_ingest/terrain_direction_review.md`.

Current terrain gameplay pack status:

- Connector, Ascent, and Chasm+Bridge are registered as TileSet atlas sources, not as Godot TileSet terrain/autotile terrain sets.
- Connector centerlines and authority-repair/rescue floors use deterministic Connector visuals; existing industrial/compound ramps use directional Ascent wide-ramp visuals.
- Existing chasm/drop visuals may resolve to Chasm Pack void/gap art without changing drop semantics. New chasm topology, directional stair selection without direction metadata, and bridge placement remain deferred.

The smoke test runs in the default procgen validation suite:
```bash
custodian/tools/validation/run_procgen_validation_suite.sh
```

The slow production rescue diagnostic remains opt-in:

```bash
RUN_SLOW_PROCGEN=1 custodian/tools/validation/run_procgen_validation_suite.sh
custodian/tools/validation/run_procgen_validation_suite.sh --full
```

## Fabrication Balance Pipeline Validation

Use for the offline fabrication/resource economy simulator and proposal generator.

```bash
python -m py_compile custodian/tools/balance/fabrication_balance_pipeline.py
python custodian/tools/balance/fabrication_balance_pipeline.py --seeds 100
```

Check:

- `reports/fabrication_balance/fabrication_balance_report.md` exists and lists affordability, optimality, bottlenecks, and lore-drop review.
- `reports/fabrication_balance/proposed_changes.json` is proposal-only JSON and does not imply runtime data was applied.
- Lore violations are understood before using `--strict-lore` in automated checks.

## Compound Infrastructure Powered Fabricator Validation

Use after changes to infrastructure definitions/components, power registration, fabrication service scaling, construction placement, or registry persistence.

```bash
cd custodian
godot --headless --path . --script res://tools/validation/power_grid_component_registration_smoke.gd
godot --headless --path . --script res://tools/validation/construction_placement_contract_smoke.gd
godot --headless --path . --script res://tools/validation/powered_fabricator_slice_smoke.gd
godot --headless --path . --script res://tools/validation/infrastructure_save_restore_smoke.gd
godot --headless --path . --script res://tools/validation/power_rate_units_smoke.gd
godot --headless --path . --script res://tools/validation/turret_placement_smoke.gd
```

The save/restore smoke proves the versioned `InfrastructureRegistry` boundary. It does not imply project-wide save-manager integration.

## Review Validation

Use for code review, docs drift review, or handoff review.

```bash
rtk git status
rtk git diff
rtk grep "changed_symbol_or_path" custodian design
```

Findings should prioritize:

- behavior regressions
- determinism risks
- simulation/UI authority leaks
- stale paths or docs drift
- missing validation
- unsafe staging or commit assumptions

## When Validation Is Deferred

## Elevated Procgen World

From `custodian/`:

```bash
godot --headless --path . --script res://tools/validation/elevated_world_asset_contract_smoke.gd
godot --headless --path . --script res://tools/validation/elevated_world_seed_review.gd
godot --headless --path . --script res://tools/validation/procgen_terrain_required_cells_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_road_surface_roles_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_route_clearance_smoke.gd
```

The asset smoke proves the source/archive exclusion and stable TileSet semantics. The seed review prints five deterministic geometry summaries; it does not replace renderer-backed visual review.

If a feasible validation step cannot run, record it in the task packet completion notes when a packet exists, or in the final handoff otherwise:

- command that was skipped or failed
- reason
- risk left behind
- exact next validation command
</file>

<file path="custodian/docs/ai_context/FILE_INDEX.md">
# FILE INDEX — CUSTODIAN

Last updated: 2026-07-26

## Local Entry And Workflow

- `custodian/AGENTS.md` — mandatory local primer for routing, context retrieval, docs-drift review, and migration execution
- `custodian/docs/AGENT_MIGRATION_PLAYBOOK.md` — detailed migration and drift-remediation workflow
- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` — compact-by-default optional task packet template with full-packet expansion guidance for high-risk or multi-session work
- `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` — prioritized automation/script backlog for agent workflow validation and safety checks
- `custodian/docs/ai_context/task_packets/AUTHORED_LEVEL_AUTHORING_PIPELINE.md` — implementation record for the shared production/playtest/authoring scaffold, named-spawn loader boundary, generic mapper, and registry-driven ingress placement
- `custodian/docs/ai_context/task_packets/ROUTE_TRAVERSAL_V1.md` — implementation/validation record for directed intra-campaign traversal and the Sundered Keep migration
- `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md` — ask-specific tooling router for agent work, currently covering modular Operator asset audit/review scripts and their caveats
- `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md` — compact agent-facing ownership map answering who owns persistent state, campaign state, world lifecycle, procgen, authored maps, combat, actors, UI, and debug; lists overburdened coordinator files and extraction targets
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — canonical validation command selection guide for docs, Godot, asset pipeline, tile pipeline, architecture organization, and review work
- `custodian/docs/ai_context/prompts/README.md` — reusable agent prompt index and usage rules
- `custodian/docs/ai_context/task_packets/README.md` — task packet workflow and active packet index
- `REQUIRED_ASSETS.md` — project-level tracker for missing or partial production art, audio, animation, and content assets that implementation work depends on
- `custodian/tools/agent/change_control_bundle.py` — utility that bundles current git-changed files into `custodian/docs/change_control/<TASK_PACKET_NAME>.md` and copies the markdown bundle to the clipboard when a clipboard command is available
- `custodian/asset_drop/runtime_ready/README.md` — persistent intake contract for already-runtime-ready assets before they become Godot content authority
- `custodian/tools/pipelines/runtime_ready_assets.py` — conflict-safe router from the persistent runtime-ready inbox into organized `res://content/` targets, with archives and receipts
- `custodian/tools/pipelines/watch_runtime_ready_assets.sh` — optional inotify watcher that applies completed runtime-ready drops continuously
- `custodian/tools/validation/runtime_ready_asset_pipeline_smoke.py` — focused validation for dry-run, routing, archiving, conflict protection, and explicit replacement
- `custodian/tools/balance/fabrication_balance_pipeline.py` — deterministic offline fabrication/resource simulation pipeline that reads live fab recipes plus scenario JSON and writes a Markdown balance report with JSON-only proposed changes.
- `custodian/content/balance/scenarios/default_fabrication_run.json` — default 30-minute fabrication/resource balance scenario covering build priorities, drop-rate profiles, resource-node inflows, lore-specced grunt drops, and sabotage-story drop rules.
- `reports/fabrication_balance/` — generated fabrication balance reports, summaries, and proposal-only JSON outputs from the balance pipeline.
- `custodian/docs/ai_context/task_packets/AGENT_WORKFLOW_AUTOMATION.md` — completed packet for task-packet next steps, ownership rules, and automation backlog
- `custodian/docs/ai_context/task_packets/VALIDATION_RECIPES.md` — completed packet for canonical validation recipes and prompt-template cleanup
- `custodian/docs/ai_context/task_packets/GAME_OVER_FLOW.md` — active packet for the first runtime game-over UX slice, including modal display, stats snapshot, restart/menu behavior, and validation.
- `custodian/docs/ai_context/task_packets/BLACK_RELIQUARY_UI.md` — completed packet for the Black Reliquary gothic/brass HUD component and Sundered Keep prompt integration slice.
- `custodian/docs/ai_context/task_packets/UI_COMPACT_DEBUG_GATING.md` — completed packet for compacting normal-play Black Reliquary HUD surfaces and gating unformatted diagnostics behind debug HUD visibility.
- `custodian/docs/ai_context/task_packets/DEBUG_SCREEN_UI.md` — completed packet for the dedicated F12/DevConsole debug screen and normal-HUD diagnostic cleanup.
- `custodian/docs/ai_context/task_packets/TERMINAL_OVERLAY_SUPPRESSION.md` — completed packet for hiding gameplay HUD/debug overlays while the terminal interface is open.
- `custodian/docs/ai_context/task_packets/ENEMY_MARINE_DASH_ATTACK.md` — completed packet for hardening the enemy marine dash into a heavy commitment attack and tracking required directional body/FX/audio assets.
- `custodian/docs/ai_context/task_packets/BLACK_RELIQUARY_LIVE_MINIMAP.md` — completed packet for making the Black Reliquary HUD minimap compact and live by embedding the shared tactical minimap renderer and exporting Sundered Keep authored minimap data.
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_HUD_SCOPE.md` — completed packet for restricting Sundered Keep-specific HUD content to the active keep map and preserving that state through terminal overlay suppression.
- `custodian/docs/ai_context/task_packets/SIDEARM_UNLOCK.md` — completed packet for progression-locking the P-9 sidearm fallback and granting it from the Sundered Keep Great Hall field-retention locker.
- `custodian/docs/ai_context/task_packets/OPERATOR_DODGE_RANGED_MODULAR_WIRING.md` — completed packet for live N/S 9-frame full-dodge playback and partial E/N/W modular two-handed ranged-ready stance wiring.
- `custodian/docs/ai_context/task_packets/CUSTODIAN_HOME_BEGINNING.md` — active packet for moving the beginning/Field Terminal design into the Home architecture docs and implementing the first witness-contact scene.
- `custodian/docs/ai_context/task_packets/archived/COMPOUND_ROOM_ASSEMBLY_CONTRACT.md` — completed packet for deterministic compound room graph, loader, and layout assembler contract hardening
- `custodian/docs/ai_context/task_packets/archived/COMPOUND_ROOM_GRAPH_WALK_LAYOUT.md` — completed packet for the first graph-walk, door-aligned compound room layout pass
- `custodian/docs/ai_context/task_packets/PORTAL_COLLISION_DEBUG_TUNING.md` — completed packet for visualizing portal prop collision and correcting portal-ring side blocker positions
- `custodian/docs/ai_context/task_packets/ENEMY_VARIANT_SYSTEM.md` — completed packet for the first procedural wolf enemy variant runtime slice
- `custodian/docs/ai_context/task_packets/INDOOR_OUTDOOR_PROCGEN_REGIONS.md` — completed packet for the first region-aware indoor/outdoor procgen slice
- `custodian/docs/ai_context/task_packets/PROCGEN_WALL_PASSAGE_VISIBILITY.md` — completed packet for generated wall passage visibility on normal horizontal procgen wall runs
- `custodian/docs/ai_context/task_packets/PROCGEN_WALL_TOP_SOURCE_PREPROCESSING.md` — completed packet for wall-top preprocessing support in the atlas builder
- `custodian/docs/ai_context/task_packets/ASH_BELL_FORLORN_RITUALANT.md` — packet for the first authored Ash-Bell / Forlorn-Ritualant event implementation slice and deferred production asset/procgen integration work
- `custodian/docs/ai_context/task_packets/SEVERANCE_UNARRIVAL_LORE_REVISION.md` — completed packet for the Severance root-cause canon revision and Forlorn-Ritualant rename pass
- `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md` — complete V3 allied combat drone authority, including manager-owned fire discipline, close/far/free-roam formation behavior, and Operator/order-point guard anchors
- `custodian/docs/ai_context/task_packets/ARRN_RUNTIME_IMPLEMENTATION.md` — completed packet for the first Automated Relay Routing Network runtime implementation
- `custodian/docs/ai_context/task_packets/RESOURCE_ID_CANONICALIZATION.md` — completed packet for making CUSTODIAN-flavored resource IDs canonical across node drops, ledger storage, recipes, UI, and docs
- `custodian/docs/ai_context/task_packets/ENEMY_GRUNT_RUNTIME_WIRING.md` — completed packet for verifying `enemy_grunt` asset usage and wiring it as a live wave-spawned enemy type
- `custodian/docs/ai_context/task_packets/ENEMY_GRUNT_SPRITE_INGEST_2026_05_17.md` — completed packet for ingesting pending `enemy_grunt` sheets, fixing generated compatibility manifest layout, and expanding directional grunt playback
- `custodian/docs/ai_context/task_packets/OPERATOR_MODULAR_FAST_ACTION_RUNTIME.md` — completed packet for the dedicated operator action-runtime folder and modular-derived unarmed fast strike wiring
- `custodian/docs/ai_context/task_packets/OPERATOR_RANGED_READY_INPUT.md` — completed packet for the held ranged-ready input contract where right mouse readies/aims and primary fires only while ready
- `custodian/docs/ai_context/task_packets/OPERATOR_FRAME_AWARE_WEAPON_SOCKETS.md` — completed Carbine phase-1 frame-socket, asymmetric aim transition, camera lead/zoom, exporter, and validation packet
- `custodian/docs/ai_context/task_packets/PARRY_CRITICAL_BRANCHING_AND_VFX.md` — active packet for explicit grunt critical-open phases and the reserved, synchronized Operator/enemy paired execution
- `custodian/docs/ai_context/task_packets/OPERATOR_FIELD_PATCH_V1.md` — completed packet for limited, timed, interruptible Operator Field Patch healing, compact HUD readout, input binding, and smoke coverage
- `custodian/docs/ai_context/task_packets/OPERATOR_TWIN_STICK_DODGE_INPUT.md` — completed packet for keyboard/mouse plus Xbox twin-stick movement/aim bindings, ranged-ready aliases, and movement-first dodge/backstep behavior
- `custodian/docs/ai_context/task_packets/OPERATOR_MODULAR_LOWER_BODY_RUNTIME.md` — packet for the modular operator lower-body runtime module folder, builder, default Fists movement wiring, and missing source-art tracking
- `custodian/docs/ai_context/task_packets/OPERATOR_MODULAR_IDLE_AND_INGEST.md` — completed packet for fixing Fists modular idle upper/lower layer precedence and routing modular Operator sprite inbox files into the live module rebuild path
- `custodian/docs/ai_context/task_packets/AUTHORED_VAULT_GRUNT_LOOT_MARINE_WIRING.md` — completed packet for authored gothic vault placement, grunt typed salvage drops, and first enemy_marine idle runtime wiring
- `custodian/docs/ai_context/task_packets/archived/GOTHIC_COMPOUND_CONNECTED_MAP.md` — completed packet for the first connected gothic compound destination reachable from the generated main map
- `custodian/docs/ai_context/task_packets/archived/GOTHIC_COMPOUND_PERIMETER_AND_READABILITY_PASS.md` — completed packet for the focused gothic compound perimeter, gate, plaza, decal, and exterior cluster readability pass
- `custodian/docs/ai_context/task_packets/GOTHIC_COMPOUND_OCCLUSION_AND_SCALE.md` — completed packet for gothic compound player/building occlusion, larger map bounds, and service-path complexity
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_GAMEPLAY_ELEVATION_OCCLUSION.md` — completed packet for the `design/GAMEPLAY.md` Sundered Keep elevation/readability slice: authored underpass/shore/interior metadata, visual underpass shadows/supports, data-driven roof cutaway, and smoke coverage
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_CHEATSHEET_RELAYOUT.md` — completed packet for the non-destructive deterministic V1 front-gate cheat-sheet relayout, preservation copy, placeholder registration, validation, and documentation pass
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_ROUTE_MASTER_APPROACH.md` — route-master Sundered Keep Approach implementation packet covering one authored approach scene, support-layer wiring, marker/controller behavior, segment-rail collision, asset audit, and smoke validation
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_APPROACH_AS_PLAYABLE_MAP.md` — historical completed packet for the earlier approach promotion; its gate/key/enemy-marker placement was later corrected because those semantics belong to the actual Keep entrance, not Vista Approach
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_PROCGEN_FRONTAGE.md` — historical implementation packet for the generated-frontage foundation
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_PARISH_ROUTE_CORRECTION.md` — active review packet for generated frontage, clipped distant reveal, authored Shore Parish, and Front Gate handoff
- `design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md` — active generated playable-frontage, terminal-ingress, and clipped distant-reveal authority
- `custodian/docs/ai_context/task_packets/ELEVATION_SUITE_V1.md` — packet for metadata-first elevation support, procgen elevation stamping, traversal validation, existing elevation/cliff tile audit, TileSet source wiring, and remaining movement/pathing follow-up
- `custodian/docs/ai_context/task_packets/TERRAIN_BUILDER_ELEVATION_INTEGRATION.md` — completed packet for the dedicated terrain builder, elevation metadata, blocked terrain, and connectivity validation pass
- `custodian/docs/ai_context/task_packets/CONTENT_DIRECTORY_STABILIZATION.md` — active packet for content-root layout documentation, duplicate audit coverage, and deferred asset path migration planning
- `custodian/docs/ai_context/task_packets/FABRICATION_BALANCE_PIPELINE.md` — completed packet for the repeatable 30-minute fabrication/resource simulation, report, and JSON-only proposal pipeline.
- `custodian/docs/ai_context/task_packets/OBSERVATORY_WORLD_TELEMETRY_FOUNDATION.md` — active packet for the first F9 observability and world-memory foundation: overlay, telemetry autoloads, heatmaps, and initial gameplay hooks.

## Active Runtime Entry

- `custodian/project.godot` — Godot project config and input map
- `custodian/scenes/game.tscn` — active game scene and terminal layout, including the authored `PageButtonsScroll` with pinned `MoreButton`/terminal actions; no longer auto-spawns the Forlorn-Ritualant dev encounter, and still includes scene-mounted `DroneManager` for allied combat drone V1 spawning plus a temporary grunt startup debug spawn gated by Operator distance from the initial spawn zone
- `custodian/scenes/home_custodian_begin.tscn` — dedicated Home beginning scene for Objective 01, tracing a Custodian-band signal across the Road of Witnesses to the damaged Field Terminal; not yet the application main scene.
- `custodian/scenes/debug/home_custodian_begin_mapper.tscn` — live Home beginning collision/POI mapper for authored perimeter rails, Custodian wake spawn, and Field Terminal placement; Enter/`U` persists script authority, updates the preview, and mirrors marker positions into the target scene.
- `custodian/scenes/twin_solaria_backdrop_test.tscn` — development-only playable preview of the largest current Twin Solaria composite as a gameplay backdrop; uses perimeter collision only and does not replace the main scene.

## Active Runtime Systems

- `custodian/game/world/procgen/custodian_contract_map.gd` — contract generation and planet-linked world profile creation, including deterministic map size/room bands, ambient Shrumb trait profile fields, contract-owned candidate generation, layout plus terrain fallback/connectivity acceptance logging, terrain-fallback candidate rejection/preference rules, and in-place promotion of the accepted structural candidate
- `custodian/game/world/procgen/proc_gen_tilemap.gd` — runtime procgen façade and state host: world generation, planet profile application, intent/reservation carving, interiors, semantic zones, roads/parking/connectors, wall/collision authority, collision-owner runtime prop blocker overlay, deterministic local escape validation/remediation, stuck diagnostics and rescue-target queries, TerrainBuilder orchestration, terrain visual/result export, final deterministic floor-value clustering, fine-grained structural timing, accepted-candidate promotion, combat/readability floor skips and source debug reporting, elevation queries, terrain-ballistics provider/context and generated-terrain collider classification, candidate/evaluation mode, foliage/prop orchestration, combat-aware canopy occlusion, portals, and authored-scene floor claims. Candidate mode still paints structural TileMaps; promotion preserves those structures and streaming visibility while completing skipped final work. Its runtime terrain visual source map preserves sources 32–59 and includes gameplay-pack sources 60–123, with opt-in live source-usage reporting. It assembles contexts for focused services instead of owning their algorithms.
- `custodian/game/world/procgen/proc_gen_map.tscn` — active procgen map scene; currently keeps source-10 floor authority while disabling source-9/full-grid alternate floor patchwork for first-pass combat readability.
- `custodian/game/world/procgen/presentation/procgen_depth_backdrop.gd` — non-colliding procgen depth presenter; the live compatibility path cover-scales one far-haze, canopy, and near-wall-growth stack from authoritative generated-world bounds, while retaining a localized explicit-chasm API for later reliable abyss semantics.
- `custodian/content/backgrounds/procgen/endless_forest/` — active runtime owner for the three 1536×1024 depth compositions; `source/` contains the unwired contact-shadow master pending local chasm-edge decal extraction. Older `content/backgrounds/procgen_world/forest_underlay_*` files are stale/source-only.
- `design/features/implementation/TILE_VALUE_CLUSTERS.md` and `TILE_VALUE_CLUSTERS_CODE.md` — visual-only cluster design authority and implementation/completion packet, including safe-cell policy, deterministic cluster contract, current two-family proxy registry, and deferred production floor families
- `custodian/game/world/procgen/diagnostics/procgen_required_cell_classifier.gd` — deterministic semantic required-cell collection, source classification, sampling, deduplication, and entry-to-cell conversion.
- `custodian/game/world/procgen/diagnostics/procgen_preterrain_diagnostics.gd` — three-graph pre-TerrainBuilder connectivity comparison, missing-required aggregation/sample export, graph disagreement reporting, and compatible diagnostic result assembly.
- `custodian/game/world/procgen/diagnostics/procgen_component_analyzer.gd` — baseline floor component analysis and deterministic capped bridge-candidate selection for disconnected required components.
- `custodian/game/world/procgen/diagnostics/procgen_preturn_authority_repair.gd` — bounded pre-TerrainBuilder authority repair loop that promotes missing required cells and applies deterministic component bridges through host callbacks.
- `custodian/game/world/procgen/foliage/procgen_foliage_spawner.gd` — foliage generation policy service for deterministic spawn/clear/remove logic, fruit/trunk collision helpers, protected-lane collision suppression, runtime blocker registration/unregistration, combat/readability clearance filtering, deferred queue draining, and shared shrub/tree wind/occlusion material ownership used by `ProcGenTilemap`
- `custodian/game/world/procgen/runtime_wall_chunk.gd` — compact runtime-wall physics body that owns exact per-tile collision shapes and resolves projectile impact positions back to destructible wall tiles
- `custodian/game/world/procgen/foliage_life.gdshader` — combined visual-only foliage wind and eight-slot combat-readability occlusion-bubble shader; canopy vertices move while the authored sprite base and collision remain planted
- `custodian/game/systems/core/systems/navigation_system.gd` — AStar navigation consumer for active painted floor/wall TileMaps plus the optional `ProcGenTilemap` runtime prop-blocker overlay; exposes authoritative-floor, painted-floor, and navigation-point diagnostics for streaming lifecycle validation.
- `custodian/game/world/procgen/foliage/README.md` — foliage ownership and migration note; facade/service split plus authority boundaries
- `custodian/game/world/procgen/terrain/terrain_builder.gd` — deterministic terrain-construction pass that emits baseline metadata, guarded worldgen reserved-region elevation metadata, mountain blockers, industrial elevation platform metadata, final cardinal ballistic edge profiles/counts, symbolic tile IDs for explicit features only, flood-fill connectivity validation, candidate-aware warning/result summaries, baseline/final required-cell corridor rescue counts before fallback, and spawn-valid traversal helpers
- `custodian/game/world/procgen/terrain/terrain_ballistics.gd` — deterministic projectile tile trace and directional terrain-boundary classifier; separates movement traversal from projectile permission so elevated ledges permit high-to-low fire while low-to-high ledges, hard walls, and drops block
- `custodian/game/world/procgen/terrain/terrain_tile_ids.gd` — centralized symbolic terrain tile IDs for industrial elevation, mountain/cliff art, connector/ascent/chasm/bridge gameplay pack atlas IDs, and placeholder constants; baseline visual no-op is owned by TerrainBuilder, not this file
- `custodian/game/world/procgen/terrain/terrain_region.gd` — terrain region descriptor for baseline, mountain wall, chasm, and industrial platform debug/validation output
- `custodian/game/world/procgen/terrain/terrain_debug_overlay.gd` — optional debug draw helper that visualizes terrain height/traversal metadata from a TerrainBuilder result
- `custodian/game/world/lighting/lighting_profile.gd` — `Resource` data object for ambient color, directional light color/energy/rotation, cosmic-underlay alpha, fog alpha, and transition timing
- `custodian/game/world/lighting/world_lighting_director.gd` — Godot-native lighting coordinator for `CanvasModulate`, `DirectionalLight2D`, lighting profile tweens, zone-priority profile pushes, contract-world fog/cosmic overrides, and temporary ambient flashes
- `custodian/game/world/lighting/lighting_zone_2d.gd` — `Area2D` lighting volume that applies a `LightingProfile` when the Operator/player enters and restores the active/default profile on exit
- `custodian/game/world/lighting/light_rig_2d.tscn` and `.gd` — reusable persistent local light rig with `PointLight2D`, additive glow `Sprite2D`, authored light/glow cookie overrides, shadow/height/asymmetric-scale settings, generated radial fallback, and optional pulse settings
- `custodian/game/world/lighting/transient_light_pool.gd` — pooled additive `Sprite2D` flash system for short-lived muzzle, impact, parry, boot, and explosion flashes without spawning per-shot lights
- `custodian/game/world/lighting/world_atmosphere_2d.tscn`, `.gd`, and `shaders/world_atmosphere.gdshader` — live fullscreen world-only atmosphere pass for world-space haze, restrained profile grading/cosmic energy, vignette, and pixel-stable grain; camera and lighting profile values are supplied by one controller below UI
- `custodian/content/lighting/profiles/sundered_keep_exterior.tres` — default live-game exterior lighting profile used until a contract planet or authored lighting zone supplies a runtime override
- `custodian/content/lighting/profiles/{sundered_keep_shadowed_courtyard,sundered_keep_gatehouse_interior,return_causeway_moonlit,ash_bell_ember_dark,severance_anomaly}.tres` — authored localized-contrast profiles ready for explicit `LightingZone2D` placement
- `custodian/content/sprites/world/lighting/` and `custodian/content/sprites/world/shadows/` — authored PointLight2D cookie pack, eight-frame dust shaft, and painted multiply-blended contact/cast shadows
- `custodian/game/systems/intel/intel_projector.gd` — pure intel-fidelity projection helper that maps one deterministic sector truth dictionary into FULL, DEGRADED, FRAGMENTED, or LOST player-facing views without mutating simulation state.
- `custodian/game/systems/intel/intel_demo_state.gd` — isolated deterministic dev incident state used by the intel-fidelity demo scene to prove truth/projection separation before runtime integration.
- `custodian/debug/debug_bus.gd` — active F3 developer debug bus autoload for bounded stats, events, overlays, selected-entity snapshots, debug overrides, and queued debug commands; this supersedes the older `content/tiles/debug/debug_bus.gd` path as the project autoload target.
- `custodian/debug/debug_snapshot_collector.gd` — read-only developer snapshot autoload that samples world/procgen, sector, combat, actor, and DevObservatory state after normal runtime updates and writes it into `DebugBus`.
- `custodian/game/systems/debug/dev_mode.gd` — release-safe developer capability authority plus F6 free-camera, F7 infinite-health, and F8 infinite-stamina playtest controls and active-state overlay
- `custodian/game/world/camera.gd` — shared gameplay camera controller; developer mode can temporarily suspend follow/framing/bounds for arrow/MMB pan and wheel zoom, then restore the prior camera state
- `custodian/game/systems/debug/dev_observatory.gd` — F9 developer telemetry autoload plus F10 stable/timestamped JSON session export, JSON-safe Variant conversion, bounded storage with cumulative/dropped/saturation accounting, consolidated runtime ownership gauges, and Performance-page-only bounded frame-time sampling.
- `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md` — active observatory authority for the existing DevObservatory autoload, runtime telemetry surfaces, and instrumentation extensions.
- `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md` — implemented authority for curated deterministic micro-scenario capture, stable assertions, advisory visual/audio comparison, output confinement, and the boundary from arbitrary Developer Replay.
- `custodian/tools/iteration/` — Moment Forge CLI, report builder, changed-file router/rules, schema, six first-pack scenarios, and invocation-only Godot runner/capture/action/audio support; generated evidence belongs under root `reports/moment_forge/`.
- `custodian/tools/validation/moment_forge_schema_smoke.py`, `moment_forge_changed_router_smoke.py`, `moment_forge_report_smoke.py`, `moment_forge_smoke.py`, `moment_forge_runtime_smoke.gd`, and `run_moment_forge_suite.sh` — split schema/routing/report checks, compatibility runner, fixed-tick Godot proof, and focused suite entry point.
- `custodian/tools/validation/operator_visual_anchor_smoke.gd` — direct `operator.tscn` regression across idle, walk, attacks, hit reaction, block/parry, dodge, Field Patch, and ranged presentation; protects the gameplay root and canonical `(0, -18)` visual stack.
- `custodian/docs/ai_context/task_packets/MOMENT_FORGE_V1.md` — implementation status, exact validation, known fixture calibration gaps, and next slice for the active Moment Forge authority.
- `design/02_features/debug_ui/NAVIGATION_COMBAT_HEATMAP_REPORTING.md` — active authority for the developer-only SectorHeatmap aggregation, Observatory export, and session-reporting slice.
- `design/02_features/world/MATERIAL_INTELLIGENCE_SYSTEM.md` — active authority for observability-first world-position material profiles, contacts, exports, and non-authoritative future response metadata.
- `custodian/tools/analysis/analyze_dev_observatory_session.py` — standard-library-only CLI for compact reports from exported Developer Observatory JSON sessions; accepts an explicit path or discovers the stable Godot user-data export, discloses warning/event-tail truncation, derives terminal attack outcomes/interruption/lifecycle by unique attack ID, reports overheat diagnostics and signal-quality flags, prints Material Intelligence contacts, and decodes top/danger/combat heatmap cells into world-pixel bounds.
- `custodian/game/resources/world/material_profile.gd` — typed material identity and prospective footstep/noise/impact response metadata; v1 consumers do not apply these values to gameplay.
- `custodian/game/resources/world/material_profile_library.gd` — canonical MaterialProfile lookup with safe `unknown` fallback.
- `custodian/game/systems/world/material_intelligence.gd` — observability-only autoload for 64 px material overrides, typed position queries, cumulative contact aggregation, Observatory events, and low-weight Heatmap tags.
- `custodian/tools/validation/material_intelligence_smoke.gd` — focused autoload/API/profile/contact/Heatmap/Observatory-export validation.
- `custodian/game/systems/world/world_state_graph.gd` — keyed reactive world-state autoload with explicit dependency evaluation and telemetry mirroring for repair/power/world logic.
- `custodian/game/systems/world/world_history.gd` — in-memory sector-scoped world-event journal for player, sector, and enemy telemetry events.
- `custodian/game/systems/world/sector_heatmap.gd` — bounded 64 px spatial event accumulator and player-presence sampler with JSON-safe snapshot/summary APIs plus legacy channel queries for diagnostic route/combat analysis.
- `custodian/game/systems/simulation/simulation_interest_manager.gd` — 5 Hz squared-distance tier classifier for `interest_managed` nodes; enemies suppress local physics only in `dormant`, while background remains full simulation until an abstract tick exists.
- `custodian/game/actors/projectiles/bullet.gd` and `.tscn` — generic physical projectile with swept collision, terrain-ballistics checks, range/falloff authority, configurable animated travel presentation, a generic impact-spark default for shared drone/turret callers, and data-driven one-shot impact scene overrides.
- `custodian/game/vfx/one_shot_animated_vfx.gd` — reusable one-shot `AnimatedSprite2D` VFX script that plays an animation on ready, optionally orients to impact direction/normal, and frees on `animation_finished`.
- `custodian/game/vfx/weapons/carbine_mk1/carbine_mk1_impact_hard_vfx.tscn` — Carbine MK1 hard-surface impact VFX scene using the shared one-shot script.
- `custodian/assets/resources/vfx/weapons/carbine_mk1/carbine_mk1_projectile_travel_loop_01_frames.tres` and `carbine_mk1_impact_hard_01_frames.tres` — Carbine MK1 projectile travel and hard-impact `SpriteFrames` resources; current PNGs are dimension-drift placeholders under `content/sprites/effects/weapons/carbine_mk1/`.
- `design/02_features/combat_feel/PROJECTILE_VFX_SYSTEM.md` — active projectile VFX implementation spec covering visual-only travel animation, one-shot impacts, Carbine MK1 paths, and future impact-family extension.
- `custodian/tools/validation/carbine_projectile_vfx_smoke.gd` — focused validation for Carbine projectile SpriteFrames, bullet scene visual type, impact scene configuration, weapon-data assignment, alpha presence, and current PNG dimension drift warnings.
- `custodian/content/procgen/world_profiles/sundered_keep_ascent.json` — distance-band profile for procgen style transition, elevation pressure, faction presence, and story-room chance
- `custodian/game/world/procgen/progression/world_style_band.gd` — data model for one distance/style/elevation band
- `custodian/game/world/procgen/progression/world_progress_profile.gd` — deterministic profile loader and cell progress sampler
- `custodian/game/world/procgen/progression/ascent_route_planner.gd` — connectivity-safe gradual ascent field and selected visual ascent-route planner
- `custodian/game/world/procgen/intent/worldgen_intent_node.gd` — route-first procgen intent node model for spawn, ascent beats, branches, faction sites, story rooms, vistas, resources, shortcuts, and exits
- `custodian/game/world/procgen/intent/worldgen_intent_edge.gd` — route-first procgen edge model for main ascent paths, branches, story approaches, faction approaches, and shortcuts
- `custodian/game/world/procgen/intent/worldgen_intent_graph.gd` — deterministic graph container exported through procgen level data
- `custodian/game/world/procgen/intent/ascent_spine_builder.gd` — deterministic ascent-spine generator driven by map size, seed, origin, and world progression profile
- `custodian/game/world/procgen/intent/ascent_field_builder.gd` — exterior ascent-field substrate builder that converts the intent graph into broad route floor mass, terraces, side pockets, sparse blockers, vista cells, and shape-readability summary data
- `custodian/game/world/procgen/intent/region_footprint_reserver.gd` — converts intent graph nodes/edges into floor reservations and region footprints
- `custodian/game/world/procgen/intent/worldgen_intent_debug_overlay.gd` — optional debug visualization for intent graph nodes, edges, and reserved regions
- `custodian/game/world/procgen/factions/faction_activity_site.gd` — data model for non-combat faction activity sites
- `custodian/game/world/procgen/factions/faction_site_placer.gd` — deterministic faction ambient site selector
- `custodian/game/world/procgen/factions/faction_site_geometry_stamper.gd` — V1 faction-site geometry reservation stamper using the shared procgen authored-scene claim API
- `custodian/game/world/procgen/story/story_room_template.gd` — story-room metadata template model
- `custodian/game/world/procgen/story/story_room_placer.gd` — deterministic environmental story-room candidate placer
- `custodian/game/world/procgen/story/story_room_geometry_stamper.gd` — V1 story-room geometry reservation stamper using the shared procgen authored-scene claim API
- `custodian/game/actors/enemies/ambient/ambient_activity_anchor.gd` — claimable non-combat activity anchor used by behavior-driven enemies
- `custodian/tools/tiles/ingest_generated_terrain_packs.py` — unified wrapper that runs per-pack normalize scripts for connector, ascent, and chasm+bridge terrain gameplay packs; writes combined ingest report to `reports/terrain_pack_ingest/`
- `custodian/tools/tiles/register_terrain_gameplay_packs.py` — registers runtime terrain gameplay pack PNGs as TileSetAtlasSource entries in `procgen_world_tileset.tres`; writes source-ID mapping report to `reports/terrain_pack_ingest/terrain_gameplay_tileset_sources.json`
- `custodian/tools/tiles/normalize_connector_pack_tiles.py` — per-pack normalize script for connector tiles (connected-component detection, 32×32 crop/pad, runtime/manifest/preview exports)
- `custodian/tools/tiles/normalize_ascent_pack_sheet.py` — per-pack normalize script for ascent tiles
- `custodian/tools/tiles/normalize_chasm_bridge_pack_sheet.py` — per-pack normalize script for chasm+bridge tiles
- `custodian/tools/validation/terrain_gameplay_packs_smoke.gd` — validates terrain pack manifests, runtime PNG dimensions/alpha/checkerboard, symbolic ID agreement, chasm non-walkable resolution, committed registration-report counts/ranges/collisions, direct `procgen_world_tileset.tres` TileSetAtlasSource registration, and `ProcGenTilemap` runtime visual-map resolution for connector/ascent/chasm_bridge art
- `custodian/tools/validation/terrain_gameplay_art_usage_smoke.gd` — focused paint-path smoke proving all 62 gameplay-pack IDs resolve, representative connector/ascent/chasm/bridge tiles paint the expected source/layer, stable old sources remain mapped, and runtime pack-usage counting works
- `custodian/tools/validation/floor_value_clusters_smoke.gd` — focused visual-only floor cluster smoke proving same-seed determinism, different-seed variation, safe semantic skips including combat/readability regions, unchanged floor/wall membership and gameplay dictionaries, and missing-variant no-op behavior
- `custodian/tools/validation/procgen_combat_readability_smoke.gd` — focused procgen readability smoke for floor source debug reporting, readability-region cluster skips, and combat foliage profile switching while preserving floor authority
- `custodian/tools/validation/procgen_stuck_pocket_smoke.gd` — focused runtime blocker smoke proving registration/unregistration, projected pre-spawn ruin-prop footprint rejection for protected routes and existing blockers, corrected global footprint authority, false-walkable pocket detection/remediation, two-exit recovery, and Observatory anomaly telemetry.
- `custodian/tools/validation/dev_observatory_audit_smoke.gd` — focused audit-remediation smoke for shared attack IDs, enemy range-whiff reasons, live projectile collision ownership, split collision gauges, ranged failure categories, Field Patch prompt transitions, ignored-on-death accounting, and structured death snapshots.
- `custodian/tools/validation/dev_observatory_director_population_smoke.gd` — deliberate mixed-population smoke proving two profile-managed agents and one legacy enemy reconcile through Observatory population and behavior-sample gauges.
- `reports/terrain_pack_ingest/terrain_gameplay_tileset_sources.json` — committed registration report mapping connector/ascent/chasm_bridge runtime tile IDs to TileSet atlas source IDs 60–123
- `reports/terrain_pack_ingest/terrain_direction_review.md` — manual visual review queue for connector inner/outer corners, ascent ramp/stair directions, chasm edge/corner directions, and bridge starts before runtime gameplay placement
- `custodian/tools/validation/procgen_intent_graph_smoke.gd` — deterministic intent graph and reservation validation
- `custodian/tools/validation/procgen_worldgen_shape_smoke.gd` — integrated procgen shape validation for intent graph export and reserved-region generation
- `custodian/tools/validation/procgen_ascent_style_smoke.gd` — smoke validation for world profile loading and uphill ascent metadata
- `custodian/tools/validation/faction_story_sites_smoke.gd` — smoke validation for faction ambient site, story-room candidate, and activity-anchor behavior
- `custodian/game/world/elevation/elevation_map.gd` — script-owned elevation metadata map for cell height, traversal type, ramp/stair direction, builder-result ingestion, serialization, spawn validity, and directional cardinal traversal checks
- `custodian/game/world/procgen/portal_teleporter.gd` — Area2D trigger component used by procgen portal-ring props to teleport the player to their linked endpoint with a physics-frame cooldown, one runtime-built `PortalStateSprite` for idle/activation/arrival playback, delayed destination arrival playback, and a 2.5D stair/platform impostor for top-only portal access plus mirrored north-side dual approach when enabled
- `custodian/game/world/prop_operator_depth_sort.gd` — reusable authored-prop depth component that compares the operator Y position against a prop baseline and flips the prop between behind/in-front z indices without owning gameplay state
- `custodian/game/world/procgen/gothic_compound/` — deterministic gothic compound blueprint generator modules: metadata asset definitions, legacy path registry, config, result, validator, generator, and Sprite2D adapter used by the connected-map prototype; current generation uses logical asset definitions, flat-layer top-left anchoring for terrain/roads/decals, base-rooted dynamic wall/prop/gatehouse occluders under `DepthSortLayer`, footprint-aware placement/collision, render/depth metadata, operator-relative prop depth sorting, wall/post/gatehouse perimeter grammar, keep-plaza exclusion, service paths, zone-specific decals/grates, clustered exterior scatter, and perimeter topology validation
- `custodian/game/world/gothic_compound/gothic_compound_map.gd` — authored connected gothic compound destination map that runs the larger gothic blueprint generator, exposes camera bounds, updates player-relative depth sorting, places the return gate, and now adds an `AuthoredVaultRoom` with three `VaultStorage` caches plus `VaultEnemyExit`
- `custodian/game/world/gothic_compound/gothic_compound_travel_gate.gd` — interactable gate used to enter the gothic compound from the main map and return from the compound to the main map; Sundered Keep normal access now uses `WorldIngressSite` instead, with this gate retained for the optional debug direct gateway
- `custodian/game/world/procgen/ingress/world_ingress_site.gd` — generic procgen-to-authored Area2D boundary; resolves presentation from registry data, snapshots both world branches plus actor/camera/UI state, optionally awaits a surface-side entry presentation after snapshot capture, supports opt-in explicit interaction without changing generic body-entry routes, restores atomically on failure/return, and resets for re-entry
- `custodian/game/world/approaches/ash_bell/ash_bell_lift_ingress_{presentation,site}.{gd,tscn}` — surface-side derelict-lift descent/ascent with explicit interaction, exterior-only parked state, traversal-revealed irregularly clipped shaft, threshold-aligned lift, restrained dust, detached Operator rider puppet, staged cave-lip occlusion, and specialized ingress selected for `forlorn_ritualant_underground`; runtime sprite components live under `custodian/assets/sprites/world/ingress/ash_bell/` with original generations under `source/generated/`
- `custodian/game/actors/operator/presentation/operator_presentation_rig_2d.{gd,tscn}` — reusable collision-free visual-only Operator snapshot rig for authored traversal presentation; copies visible body/equipment leaves, current frames/transforms/modulates/material/Z, supplies a restrained rigid lift-braced pose, and restores source visibility on every cleanup path.
- `custodian/scenes/debug/forlorn_ritualant_underground_mapper.tscn` — authored-room rail/marker mapper for the single-authority descent landing, return exit, and Ritualant encounter origin
- `custodian/tools/validation/ash_bell_lift_ingress_presentation_smoke.gd` — focused asset, animation, exterior-idle/shaft-reveal, threshold, cave-mask occlusion, descent/reset, snapshot-order, and specialized-versus-generic spawner validation for the Empty Bell surface ingress
- `custodian/tools/iteration/scenarios/traversal/ash_bell_lift_exterior_descent.json` and `custodian/tools/validation/fixtures/ash_bell_lift_moment.{gd,tscn}` — deterministic Moment Forge exterior/descent/reset comparison for the Ash Bell lift, routed automatically from lift runtime or art changes
- `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.tscn` and `.gd` — authored production Vista Approach / Shore Parish entered from an ordinary procgen-ground ingress by a short fade and connected to Front Gate by another; it exclusively owns ocean/storm, fortress, route-master, reveal, collision, enemies, and dressing and exposes boundary-shape validation
- `custodian/game/world/approaches/sundered_keep/soft_rect_feather.gdshader` — local CanvasItem shader used by the Sundered Keep approach to soften fitted matte sprite edges so panorama/fog/sea/keep plates do not read as raw rectangles
- `custodian/game/world/approaches/sundered_keep/sundered_keep_vista_controller.gd` — retained approach presentation adapter; production disables the historical second-camera envelope and Grand Vista weights so semantic markers cannot claim camera authority
- `custodian/game/world/approaches/sundered_keep/sundered_keep_reveal_director.gd` — optional prompt/signal/light/accent bookkeeping with no production camera or route authority
- `custodian/content/backgrounds/sundered_keep/README.md` — role-based layout authority for shared, Approach, Grand Vista, World Vista, and Causeway Approach painterly plates plus the mirrored Aseprite-source rule
- `custodian/content/backgrounds/sundered_keep/approach/underlay/first_vista_base_storm_horizon.png`, `approach/fog/first_vista_reveal_veil.png`, and `shared/landmarks/distant_sundered_keep_landmark_v2.png` — Camera 1 visual ownership split: opaque continuous storm/ocean, alpha fog veil, and alpha Keep/island landmark
- `custodian/content/backgrounds/sundered_keep/approach/light/first_vista_moonlight_sweep_01__6f__1024x512.png` and `custodian/content/_aseprite/backgrounds/sundered_keep/approach/light/first_vista_moonlight_sweep_01.aseprite` — six-frame 15 FPS non-looping cold stone-edge exposure sweep, aligned to the live First Vista Keep silhouette for low-opacity additive/screen presentation
- `custodian/tools/validation/sundered_keep_first_vista_continuity_smoke.gd` — focused proof that Camera 1 never crossfades the base world, delays landmark readability, retains atmospheric fog, respects the 80–140 px peel budget, keeps later layers hidden, and preserves the Keep after handback
- `custodian/game/world/approaches/sundered_keep/sundered_keep_vista_debug_probe.gd` — debug-only live probe for route identity, both cameras' physical enter/return progress and weights, derived phase, presentation-anchor/follow ownership, zoom, and per-plane fortress alphas
- `custodian/game/world/approaches/sundered_keep/sundered_keep_parallax_layer.gd` — reusable camera-relative layer used by the first-vista, Labyrinth, and local fortress far/mid/near roots; supports subtle drift and explicit rebasing while leaving gameplay roots fixed
- `custodian/game/world/approaches/sundered_keep/sundered_keep_fortress_vista.gd` — deterministic presentation-only composer that loads and instantiates only the approved 17-piece primary shot across four readable precincts and three implied labyrinth routes in local far/mid/near layers; unused composition-kit textures remain on disk but do not enter production memory
- `custodian/game/world/approaches/sundered_keep/procedural_fog_ribbon_2d.gd` and `procedural_fog_ribbon_band.gdshader` — texture-free local checkpoint fog band using a 1×1 runtime carrier, feathered edges, two drifting FBM fields, restrained tint alpha, and no gameplay authority; replaces the retired 9216×384 animated sheet.
- `custodian/tools/validation/sundered_keep_procedural_fog_ribbon_smoke.gd` — focused regression proving the checkpoint ribbon uses its procedural shader, 1×1 carrier, authored coverage/depth/alpha, no collision authority, and no retired sheet resource.
- `custodian/game/world/presentation/authored_underlay_plate_loader.gd` — camera-aware streamed presentation loader for manifest-authored core-plus-bleed underlay plates; owns visual plate loading only, never collision, navigation, markers, or gameplay state.
- `custodian/tools/content/slice_authored_underlay.py` and `custodian/tools/content/tests/test_slice_authored_underlay.py` — deterministic external-master slicer and unit coverage for plate PNGs, manifest generation, runtime/preview scene generation, and exact core-pixel verification.
- `custodian/tools/validation/authored_underlay_plate_pipeline_smoke.gd` — generated-build smoke for manifest/runtime-scene agreement, plate resources, streaming contract, and gameplay-authority separation.
- `design/02_features/world/AUTHORED_UNDERLAY_PLATE_PIPELINE.md` — active source/runtime authority and acceptance contract for large authored underlay plate generation and streaming.
- `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH_PARALLAX.md` — companion specification for a Vista-local, feature-gated decorative depth rig; runtime integration is gated on complete alpha-valid painterly plates
- `custodian/tools/validation/validate_sundered_keep_parallax_assets.py` — Pillow preflight for the eight shared parallax PNGs, including format, alpha, transparent-canvas, fog-gradation, known-rejected-source hashes, and optional red/green/black/white review-sheet generation
- `custodian/game/world/approaches/sundered_keep/route_master_occlusion_mask.gdshader` — three-rect UV cutout shader that removes Labyrinth roof regions from the base route-master draw so cropped overlays can fade independently
- `custodian/game/world/common/roof_occluder_2d.gd` — reusable player-filtered `Area2D` roof/facade fade component with multi-occupant tracking and exact target-alpha restoration
- `custodian/game/world/sundered_keep/return_causeway/ReturnCausewayApproach.tscn` and `return_causeway_layout.gd` — quarantined `causeway_only` route node with local presentation/geometry/state, scene-authored generic `continue`/`backtrack` exits, and named forward/reverse spawns
- `custodian/scenes/debug/level_collision_poi_mapper.tscn`, `.gd`, and `_overlay.gd` — generic target-configured boundary/POI mapper with dynamic marker schemas, target-owned authoring/runtime coordinate conversion, compatibility state aliases, and recoverable verified script writes
- `custodian/content/levels/sundered_keep/sundered_keep_underlay_collision.json` — canonical reviewed capsule rails and gameplay placement markers shared by the Sundered Keep mapper, underlay debug scene, and production Front Gate map
- `custodian/content/levels/sundered_keep/archive/sundered_keep_front_gate_legacy_visual_ops.json` — non-runtime archive of retired Front Gate static fill/paint/wall/prop/prefab ops removed so the production PNG underlay remains the visual base
- `custodian/scenes/debug/sundered_keep_mapper.tscn`, `.gd`, and `_overlay.gd` — production Main Keep mapper; previews the actual Front Gate runtime map and combines collision rails, exact markers, 01–99 tile palette, underlay stamps, drag painting, undo/redo, on-map selection/movement/creation for every functional spatial record, linked Return Mooring bundle placement, and inline siege authoring; only deliberate visual edits serialize to `mapper_placements`
- `custodian/scenes/debug/sundered_keep_approach_mapper.tscn`, `.gd`, and `_overlay.gd` — production Approach/Outskirts mapper; previews the real authored approach and writes route-floor, collision, marker, subregion, roof, and handoff-occlusion authority to `sundered_keep_approach_{outskirts,collision,occlusion}.json`; its `Z` mode edits existing feature-zone/subregion rectangles in place. `custodian/content/levels/sundered_keep/sundered_keep_approach_mapper_preview.json` independently toggles expensive mapper-only presentation, AI, animation, probes, and processing without changing production behavior.
- `custodian/game/world/routes/level_stage.gd` — base `LevelStage` class for route-level stage organization; defines `configure_stage()`, `get_entry_spawn()`, `get_camera_bounds()`, `complete_stage()`, and the `stage_complete` signal
- `custodian/game/world/routes/level_route.gd` — base `LevelRoute` controller with `register_stage()`, `_load_stage()`, `_on_stage_complete()` stage advancement, and `final_target_scene` instantiation via `_enter_front_gate()`
- `custodian/game/world/routes/sundered_keep/sundered_keep_approach_route.gd` — route controller registering vista_one, pre_level, grand_vista, and causeway_approach stages with `sundered_keep_map.tscn` as final target
- `custodian/game/world/routes/sundered_keep/sundered_keep_approach_route.tscn` — legacy/debug-only pre-registry staged-route wrapper retained for historical comparison; excluded from production traversal and acceptance
- `custodian/game/world/levels/level_definition.gd`, `level_registry.gd`, `level_loader.gd`, and `world_ingress_definition.gd` — shared authored-level data contract, optional non-ingress definitions, declared spawns/policies, duplicate-safe registry, and low-level staged instance service
- `custodian/game/world/levels/level_exit_2d.gd` / `.tscn` — dumb collision-backed local route request source with exit identity and duplicate-request lock only
- `custodian/game/world/routes/{route_definition,route_node_definition,route_edge_definition,route_profile_definition,route_registry,route_session,route_transition_context,route_state_store,route_traversal_manager}.gd` — live directed route contracts, enabled-topology connectivity validation, serializable session boundary, runtime state store, synchronous post-commit rollback cleanup, and world-local transaction authority
- `custodian/game/world/levels/authored_level_2d.gd` and `level_playtest_bootstrap.gd` — production level base contract plus standalone-wrapper activation helper; production levels own content/markers/collision/camera bounds and loader-mediated return but never a persistent Operator
- `custodian/tools/validation/{authored_level_ingress_return_smoke,authored_level_reentry_smoke,level_presentation_profile_smoke,level_entry_rollback_smoke,world_ingress_physics_reentry_smoke,level_return_single_authority_smoke,level_return_rejected_smoke,level_origin_destroyed_smoke,level_camera_rebind_smoke,world_origin_branch_contract_smoke}.gd` — focused authored lifecycle coverage for exact grouped-origin branch/camera restoration, leaking-sector isolation, static main-scene classification, loader/ingress cleanup, private-method-free physics re-entry, registry-selected presentation, atomic failed-spawn rollback, same-frame single authority, fail-closed rejected returns, and destroyed-origin rollback
- `.github/workflows/godot-level-pipeline.yml` — repository-root CI workflow pinned to Godot 4.7 that imports the project and runs the authored-level lifecycle, registry, named-spawn, and Sundered regressions
- `custodian/game/world/levels/world_ingress_spawner.gd` and `world_ingress_placement_resolver.gd` — deterministic registry-driven procgen ingress creation and spatial policy; production `ContractWorldLoader` delegates authored destination placement here, and the spawner selects the Ash Bell lift specialization only for the Forlorn Ritualant Underground identity
- `custodian/game/world/procgen/landmarks/sundered_keep/{sundered_keep_landmark_intent_builder,sundered_keep_frontage_builder,sundered_keep_frontage_validator}.gd` — deterministic V1 landmark intent, irregular route/terrace/side-pocket/cliff generation, and structural/reachability/camera-order validation
- `custodian/game/world/procgen/landmarks/sundered_keep/{sundered_keep_frontage_visual_spawner,sundered_keep_frontage_camera_director}.gd` — production generated-frontage presentation spawn and camera-envelope helpers
- `custodian/game/world/vistas/sundered_keep/sundered_keep_procgen_vista_presentation.tscn` and `.gd` — production collision-free distant ocean/storm/fortress presentation, clipped outside playable frontage and rendered below generated gameplay
- `custodian/game/world/vistas/sundered_keep/sundered_keep_world_vista.tscn` and `.gd` — superseded presentation-only overlook implementation retained as historical reference
- `custodian/tools/validation/sundered_keep_procgen_frontage_smoke.gd` — 24-seed structural/determinism/variation smoke plus integrated generated-map checks for route width, reachability, dressing/site exclusion, terminal ingress, border-wall pruning, and forbidden authored authority
- `custodian/tools/validation/sundered_keep_procgen_vista_layering_smoke.gd` — production authority/layering smoke for generated frontage route placement, collision-free clipped vista hierarchy, negative presentation depth, and non-overlap with playable-floor bounds
- `custodian/tools/validation/sundered_keep_world_vista_smoke.gd` — semantic presentation smoke proving both forward/reverse camera envelopes, 2560×1440 storm/void coverage, behind-gameplay fortress layers, procgen/Operator continuity, and no collision, cliff-lip, fixed stage, or rectangular authority
- `custodian/tools/validation/sundered_keep_procgen_frontage_seed_review.gd` — renderer-backed eight-seed 2560×1440 review tool writing overview, first-reveal, frontage-apex, and gate-approach PNGs plus `manifest.json` under `reports/sundered_keep_procgen_frontage/`; the old World Vista reviewer path is a compatibility entry point
- `custodian/tools/level_authoring/` — CLI scaffold request/generator/entry script, `route_validation_registry_view.gd`, and templates for managed production/playtest/authoring levels, collision-backed exits, transactional route create/append, and full proposed-graph validation before writes
- `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`, `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`, and `design/02_features/level_authoring/AUTHORED_LEVEL_AUTHORING_PIPELINE_CODE.md` — active level and route ownership/implementation contracts
- `custodian/content/levels/levels.json` and `custodian/content/levels/sundered_keep/{vista_approach,return_causeway,front_gate}.json` — distinct registered Sundered node definitions; Vista Approach and Front Gate are production while Return Causeway is debug-only
- `custodian/content/routes/routes.json` and `custodian/content/routes/sundered_keep/sundered_keep_route.json` — route registry with production world-origin → normal fade → Shore Parish / Outer Wall Approach → normal fade → Front Gate topology plus isolated debug profiles
- `custodian/game/world/routes/sundered_keep/stages/sundered_keep_vista_one.gd` / `.tscn` — auto-advance first vista presentation with horizon sky, far sea, distant keep, vista fog band, explicit camera bounds, and bottommost `BackdropVoidFill`
- `custodian/game/world/routes/sundered_keep/stages/sundered_keep_pre_level.gd` / `.tscn` — gameplay preamble stub with EntrySpawn, ExitToGrandVistaTrigger, explicit camera bounds, and bottommost `BackdropVoidFill`
- `custodian/game/world/routes/sundered_keep/stages/sundered_keep_grand_vista.gd` / `.tscn` — auto-advance/skippable panorama presentation with graceful missing-texture handling for grand vista textures, explicit camera bounds, and bottommost `BackdropVoidFill`
- `custodian/game/world/routes/sundered_keep/stages/sundered_keep_causeway_approach.gd` / `.tscn` — LevelStage-converted approach scene with full underlay/path/occlusion/collision/VistaController logic, exit trigger replaced with `ExitToFrontGate` Area2D emitting `stage_complete`; keeps `UnderlayRoot` alpha fixed at 1.0, avoids binding `VistaController.vista_root_path` to the underlay, adds `BackdropVoidFill`, and overrides camera bounds in script
- `custodian/tools/validation/sundered_keep_approach_route_smoke.gd` — legacy/debug-only self-test for the retired staged `LevelRoute`; its obsolete Front Gate `configure_connection()` expectation is not production authority
- `custodian/tools/validation/sundered_keep_approach_smoke.gd` — active Shore Parish scene-contract smoke covering supplied overlays, 45 mapper rails, local fog limits, removed full-route fog/mist layers, reduced procedural lights, disabled authored vista enemies/second-camera authority, and the extended route exit
- `custodian/tools/validation/sundered_keep_approach_lean_smoke.gd` — focused production-workload contract for 17 instantiated fortress pieces, visibility-gated hidden parallax, removed invisible/full-route overlays, 256px procedural lights, disabled vista grunts, and route-master mipmaps
- `custodian/tools/validation/sundered_keep_vista_polish_smoke.gd` — historical Grand Vista/Camera 2 regression artifact; it does not define the current production Parish camera contract
- `custodian/tools/validation/sundered_keep_parish_route_correction_smoke.gd` — focused production correction smoke for fade-only edges, supplied asset dimensions/alpha, mapper overlay metadata, local fog, camera retirement, extended Parish exit, and Front Gate arrival protection
- `custodian/tools/validation/sundered_keep_route_correction_review.gd` — graphical 2560×1440 Parish and Front Gate capture exporter used with the procgen seed review under `reports/sundered_keep_route_correction/`; exported frames require human approval
- `custodian/tools/validation/sundered_keep_approach_route_visual_smoke.gd` — legacy/debug-only visual comparison for retired Sundered Keep route stages; excluded from production acceptance
- `custodian/tools/validation/run_route_pipeline_suite.sh` and the `route_*` / `sundered_keep_*` route smokes — directed registry/connectivity, traversal, initial-entry and node rollback, exfil, profile, cache/state, exit binding, production physics traversal, symmetric Front Gate state, authored Sundered exits, ownership, and generator immutability validation
- `custodian/tools/validation/sundered_keep_approach_control_return_smoke.gd` — instantiates the production Approach and asserts its visual-readiness contract, visible route master, mapper collision/near-vista trigger, approach HUD mode, and shared-camera runtime-map/Operator-follow/non-presentation state at gameplay control return
- `custodian/tools/validation/sundered_keep_underlay_gameplay_debug_smoke.gd` — standalone underlay-gameplay debug smoke proving `res://scenes/debug/sundered_keep_production_underlay_debug.tscn` uses only the active Sundered Keep main underlay texture, does not instantiate `SunderedKeepMap` or tile sprites, spawns the real Operator on the authored spawn tile, keeps projectiles/controller/camera runtime paths available, and uses gameplay camera zoom/bounds instead of review zoom
- `custodian/tools/maintenance/strip_sundered_keep_legacy_visual_ops.py` — guarded, idempotent migration that classifies every Front Gate op, archives retired static visual ops, refuses non-empty mapper placements or unknown op types, and preserves retained functional ops in order
- `custodian/tools/validation/sundered_keep_underlay_visual_authority_smoke.gd` — validates production underlay authority, retired-op absence, retained gameplay contracts/collision, headless map and mapper loading, and temporary mapper placement serialize/reload/removal without changing production data
- `custodian/tools/validation/sundered_keep_mapper_smoke.gd` — validates sole-mapper ownership, actual runtime preview, production level/collision data paths, 127 rails, seven exact markers, zero initial manual placements, 01–99 palette, stamp/drag/undo tools, spatial feature selection/creation, linked Return Mooring relocation, and retained gameplay-feature coverage
- `custodian/game/world/sundered_keep/sundered_keep_map.tscn` — production Front Gate route scene with authored `backtrack` and `exfil` `LevelExit2D` nodes
- `custodian/game/world/sundered_keep/sundered_keep_map.gd` — authored connected Sundered Keep destination map that builds the production PNG underlay as visual base, applies retained functional ops plus explicit mapper placements, and preserves Return Mooring, local gate key, animated/collision-gated Main Gate, Vanguard Seal cache, animated Great Hall doorway, marine ambush, route-state restoration, elevation/underpass/shore/interior-occlusion helpers, roof cutaway, minimap projection, map-local HUD, camera bounds, debug state, and gatehouse siege behavior
- `custodian/game/world/sundered_keep/sundered_keep_overlay_authoring_debug.gd` — review-only overlay debug renderer that reads the generated Sundered Keep authoring-mask JSON and draws suggested footprint / border-void / enclosed-void rects over the live map
- `custodian/game/world/sundered_keep/sundered_keep_marine_ambush.gd` — Sundered Keep-local encounter controller that keeps the Great Hall marine idle until the player approaches, uses the heavy marine dash, and captures/restores idle/active/completed encounter state without respawning or replaying completion
- `custodian/game/world/sundered_keep/sundered_keep_siege_objective.gd` — local Sundered Keep `Damageable` objective marker with side-effect-free route-state capture/validation/restoration for integrity state
- `custodian/game/world/sundered_keep/sundered_keep_tilemap_loader.gd` — small JSON loader for `custodian.sundered_keep.level_tilemap.v1` level data used by the Sundered Keep Sprite2D tilemap build path
- `custodian/game/world/sundered_keep/sundered_keep_interactable.gd` — small InputMap-aware interactable bridge used by the Sundered Keep Return Mooring, gate key pickup, Main Gate, and Great Hall door interaction nodes
- `custodian/game/world/home/custodian_home_begin.gd` — local controller for the first Home beginning slice, including signal-band objective state, Black Reliquary HUD updates, prompt routing, and witness-contact completion state.
- `custodian/scenes/debug/level_collision_poi_mapper.gd` — shared collision/POI authoring runtime used by Sundered Keep, Forlorn Ritualant Underground, and Home beginning mappers; saved edits update the live preview, script constants, and target-scene marker positions.
- `custodian/game/world/home/field_terminal_interactable.gd` — reusable Field Terminal interactable that participates in the existing `interactable` group, plays existing terminal fallback activation art, and emits witness/access signals.
- `custodian/game/world/compound/rooms/room_graph.gd` — deterministic compound room graph loader/validator with room count clamps, sorted type lookup, seeded template selection, and directional connection-rule checks
- `custodian/game/world/compound/rooms/room_loader.gd` — deterministic `.tmj` Tiled room-template loader with normalized door metadata, marker/stair extraction, template duplication, and door compatibility checks
- `custodian/game/world/compound/rooms/layout_assembler.gd` — deterministic compound room layout assembler with stable room IDs, graph-walk door-aligned placement, fixed-grid fallback, graph-rule-enforced compatible door connections, resolved endpoint tiles, intensity estimates, actual tile bounds, and placed-room state
- `custodian/game/world/compound/rooms/graphs/default_compound.json` — default compound room graph referencing command post, hangar, corridor, storage, and landing pad template names
- `custodian/game/world/compound/rooms/templates/` — Tiled `.tmj` compound room template directory; currently only `command_post.tmj` exists, with additional templates tracked in `REQUIRED_ASSETS.md`
- `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn` — partial authored Ash-Bell special-room scene with an AnimatedSprite2D Forlorn-Ritualant, placeholder bell/fountain/thread/procession stagecraft, south doorway, overlapping interaction triggers, and debug-style local dialogue presentation
- `custodian/game/world/events/ash_bell/forlorn_ritualant_site.gd` — Ash-Bell encounter controller for silence pressure, thread/fountain state, dialogue/item/knowledge signals, apparition/procession placeholders, and completion state
- `custodian/game/world/events/ash_bell/ash_bell_event_state.gd` — local Resource state model for Ash-Bell silence pressure, thread tension, fountain state, resolution, and knowledge flags
- `custodian/game/world/events/ash_bell/forlorn_ritualant_npc.gd` — partial Forlorn-Ritualant NPC controller with kneeling/hostile phases and pin-strike/thread-pull hooks; directional locomotion, a locked frame-synchronized combat action machine, full four-attack identity, and authored violent/nonviolent conclusions remain open
- `custodian/game/world/events/ash_bell/white_thread_hazard.gd` — soft thread hazard Area2D that increments thread tension and optionally applies player slow hooks
- `custodian/game/world/events/ash_bell/ash_bell_interactable.gd` — operator interaction bridge for ritualant, thread, clapper, fountain, and silence-ringing actions
- `custodian/game/world/events/ash_bell/ash_bell_trigger.gd` — Area2D trigger bridge for intro, fountain occupancy, exit, and procession-lane pressure
- `custodian/game/world/events/ash_bell/ash_bell_dev_spawner.gd` — opt-in temporary live-review spawner for reserving the canonical `35x27` authored-room footprint through the active procgen map, then placing the Ash-Bell site north of the operator for an outside-in doorway approach; not mounted by normal `scenes/game.tscn` startup
- `custodian/game/world/procgen/special_rooms/special_room_runtime_inserter.gd` — generic deterministic special-room insertion path used by `CustodianContractMap` after an accepted generated map is selected; loads `res://content/procgen/special_rooms/*.json`, claims authored floor authority, instances scenes, and reports inserted `special_room_sites`
- `custodian/scenes/debug/forlorn_ritualant_site_debug.tscn` — standalone Forlorn-Ritualant gameplay/debug launch scene with the authored site, real Operator spawn at the south entrance, `PlayerController`, gameplay `CameraController`, projectiles root, and note; kept separate from normal game startup
- `custodian/scenes/debug/sundered_keep_production_underlay_debug.tscn` and `.gd` — standalone playable underlay-only review scene showing only `res://content/masters/sundered_keep/sundered_keep_main_overlay.png` fitted to the live `112x80` gameplay rect, with real Operator, `PlayerController`, gameplay `CameraController` at normal `0.84` base zoom, runtime roots, and the canonical JSON-backed mapped rails under `MappedUnderlayBounds`; it intentionally has no `SunderedKeepMap`, tile sprites, or vista layers
- `custodian/scenes/environment/cosmic_underlay.tscn` and `custodian/scripts/environment/cosmic_underlay.gd` — reusable world-space cosmic void underlay with subtle drift/pulse controls, kept as a base environment component without collision or gameplay authority
- `custodian/scenes/environment/forlorn_ritualant_shader_fx.tscn` and `custodian/scripts/environment/forlorn_ritualant_shader_fx.gd` — Forlorn-Ritualant visual-only FX layer combining the cosmic underlay, room-edge shadow/rim mask sprites, and temporal haze with exported `ShaderMaterial` intensity controls
- `custodian/game/world/events/ash_bell/shaders/` and `custodian/game/world/events/ash_bell/materials/` — encounter-local CanvasItem shaders/materials for void-ocean drift, room-edge haze, and temporal overlap haze
- `custodian/content/masks/forlorn_ritualant/room_silhouette_mask.png` — presentation-only alpha mask derived from current room art for edge shadow/rim rendering; not collision or gameplay authority
- `design/02_features/enemy_objective/FORLORN_RITUALANT_COSMIC_UNDERLAY.md` — scene-layering note for the Forlorn-Ritualant underlay, transparent-edge room-art requirement, and reuse contract
- `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md` — shader FX design note for the Forlorn-Ritualant void-ocean, edge shadow/rim, temporal haze, and mask contracts
- `custodian/tools/validation/procgen_authored_scene_authority_smoke.gd` — focused generated-map smoke proving authored footprint claims remove wall visuals, generated/runtime wall authority, blocked elevation, and stale road authority while forcing floor metadata
- `custodian/game/systems/core/systems/ambient_critter_manager.gd` — ambient critter spawning, tint, pacing, scale, speed, naming, and trait metadata linked to world profile
- `custodian/game/systems/core/systems/inventory_manager.gd` — stack-count ledger plus constrained sidearm/relic equipment ownership with versioned equipment persistence and legacy flat carried-item load compatibility
- `custodian/game/systems/combat/engagement_tracker.gd` — player-owned fixed-step engagement boundary, universal initiative resolution, and Vanguard Seal duration/break authority
- `custodian/game/systems/core/systems/vault_manager.gd` — vault storage authority autoload for registering storage, reporting totals, stealing resources, recovering dropped stolen bundles, committing escaped loot loss, fallback debug vault placement, and enemy exit discovery
- `custodian/game/systems/cognitive/cognitive_state_system.gd` — `CognitiveState` autoload tracking Forest Shrumb recollection/instinct/bearing values, decay, dominant state, and v1 modifier getters
- `custodian/game/systems/core/systems/arrn/arrn_manager.gd` — ARRN autoload authority for relay state, scans, stabilization tasks, packet sync, knowledge progression, decay/drift, dormancy pressure, and benefit query APIs
- `custodian/game/systems/core/systems/arrn/relay_data.gd` — relay state resource schema and status/risk formatting helpers
- `custodian/game/systems/core/systems/arrn/stabilization_task.gd` — tick-counted field relay stabilization task state
- `custodian/game/systems/core/systems/arrn/knowledge_system.gd` — knowledge track constants and sync-gain calculation
- `custodian/game/systems/core/systems/arrn/benefits_manager.gd` — ARRN knowledge-level benefit activation and labels
- `custodian/game/systems/core/systems/contract_world_loader.gd` — contract-world handoff and placement bridge; repositions runtime anchors, places vehicles and ARRN relays, instantiates the connected gothic compound, delegates registered ingress placement, creates the Sundered Keep world Vista beside its real direct-to-Front-Gate ingress, keeps the optional spawn-adjacent debug gateway disabled, and places procgen tutorial/expedition resources
- `custodian/game/vehicles/vehicle_definition.gd` — vehicle archetype data loader, display-name generator, tag/mobility helpers, and core definition validation for registry-backed vehicles
- `custodian/game/vehicles/vehicle_registry.gd` — registry store for `res://content/vehicles/vehicle_archetypes.json`, including ID lookup and faction/domain/chassis/role/tier/pilotable queries
- `custodian/game/vehicles/vehicle_spawn_resolver.gd` — registry ID to live scene resolver; validates runtime support, instantiates scenes, applies definitions, and assigns vehicle groups
- `custodian/game/vehicles/pilotable_vehicle.gd` — pilotable `CharacterBody2D` base that owns vehicle movement response, enter/exit state, terrain multiplier lookup with `actor_kind = "vehicle"`, pilot visibility/collision handoff, and interaction prompts
- `custodian/game/vehicles/vehicle_input_adapter.gd` — guarded InputMap reader used by `PlayerController` for vehicle movement/action intent
- `custodian/game/vehicles/vehicle_seat.gd` — small seat/entry bridge used by pilotable vehicle scenes
- `custodian/game/vehicles/scenes/pilotable_vehicle_base.tscn` — reusable base scene layout for registry-backed pilotable vehicles
- `custodian/content/vehicles/*.json` — vehicle taxonomy, archetypes, movement profiles, hardpoint profiles, loadouts, visual kits, and registry schema data
- `custodian/tools/validate_vehicle_registry.gd` — headless registry validator for taxonomy values, required fields, referenced profiles/loadouts/kits, runtime scenes, pilotable seat/profile requirements, and unsupported spawnable domains
- `custodian/game/actors/relay/relay.tscn` — placeholder in-world relay entity scene used by procgen contract handoff
- `custodian/game/actors/relay/relay.gd` — interactable relay entity that mirrors ARRN state, shows scan/stabilization prompts, and starts stabilization through `ARRNManager`
- `custodian/game/actors/relay/signal_indicator.gd` — primitive signal-strength visual for relay placeholder scenes
- `custodian/game/actors/relay/relay_interaction.gd` — relay interaction area bridge for future scene-level interaction expansion
- `custodian/game/actors/allies/combat_drone.tscn` — base allied combat drone scene with health bar, collision, muzzle marker, and fallback ColorRect visual
- `custodian/game/actors/allies/combat_drone.gd` — fragile allied combat drone actor with Operator/order-point anchor resolution, close/far formation bands, deterministic local patrol, guard-centered targeting/return limits, freed-target pruning plus Observatory telemetry, FOLLOW/HOLD/INTERCEPT/RECALL modes, shared terrain-aware projectile fire, independent HP, and manager-controlled command state
- `custodian/game/actors/effects/drone_guard_order_marker.tscn` — lightweight pulsing world-space ring/cross marker for the active ordered guard point
- `custodian/game/vfx/combat/parry_contact_spark_vfx.tscn` — non-looping world-space six-frame parry contact spark that auto-frees at animation completion
- `custodian/game/vfx/combat/critical_breach_marker_vfx.tscn` — enemy-attached floating BREACH marker held visibly for the gameplay-owned critical window
- `custodian/game/vfx/combat/critical_window_ring_vfx.tscn` — enemy-attached twelve-frame countdown reticle scaled to the supplied critical-window duration
- `custodian/game/vfx/combat/parry_success_burst_vfx.gd` / `.tscn` — independently owned world-space parry-success one-shot that reuses the validated six-frame contact strip and survives Operator modular-layer transitions
- `custodian/content/audio/sfx/combat/parry_success_01.wav` — 0.61-second positional confirmation cue spawned exactly once at the resolved contact point by Operator parry-success authority
- `custodian/content/spriteframes/effects/combat/` — compact SpriteFrames resources slicing the required contact, BREACH, and countdown runtime strips
- `custodian/game/actors/allies/allied_infantry_droid.tscn` — active main-scene allied droid presentation with animated SpriteFrames, muzzle marker, health bar, status label, and inherited combat behavior
- `custodian/game/actors/allies/allied_infantry_droid.gd` — animated `CombatDrone` subclass with facing-aware idle/run/destroyed playback, hold-fire dimming, and fire/follow status label; no raw squad command input
- `custodian/game/systems/drone/drone_manager.gd` — scene-mounted drone squad manager that owns fire/formation/guard/return input, resolves hostile hover during the guard-order chord, exposes command-reticle state, converts hostile clicks to explicit target orders, owns the guard marker, and makes `K` restore Operator anchoring plus tactical `FOLLOW` without changing formation distance or fire discipline
- `custodian/game/systems/drone/drone_command_profile.gd` — drone tuning and mode constants for HP, speed, range, burst cadence, retreat threshold, tactical modes, follow-distance bands, separation, free-roam patrol timing, and leash behavior
- `custodian/game/systems/drone/drone_targeting.gd` — deterministic local target selection helper for non-passive enemies near the Custodian or hold point, with optional range override for free roam
- `custodian/game/systems/drone/drone_squad_state.gd` — lightweight resource tracking active/destroyed drone IDs, current tactical mode, fire discipline, current follow distance, reserve, and max active count
- `custodian/tools/validation/main_scene_allied_droid_smoke.gd` — focused smoke proving `game.tscn` routes `DroneManager` to the animated allied droid scene and manager-owned T/G/J+click/K actions
- `custodian/tools/validation/drone_follower_commands_smoke.gd` — focused V3 smoke for squad state, Operator/guard anchor transitions, close/far/roam guard goals, return limits, marker lifecycle, propagation, replacement inheritance, complete return-to-Operator-follow behavior, recall compatibility, and hold-fire burst cancellation
- `custodian/game/systems/core/state/game_state.gd` — fail-state and phase authority autoload; now pauses and mounts the game-over modal on `trigger_game_over(...)`, preserves the existing debug fields, and exposes `reset_run_state(...)` for restart flows.
- `custodian/game/systems/core/state/game_stats.gd` — run-stat autoload for waves survived, enemies destroyed, power failures, and turrets lost snapshots used by the game-over modal.
- `custodian/game/ui/game_over/game_over_modal.tscn` — centered pause-safe game-over modal showing fail reason, stats, Restart Facility, and Return to Menu.
- `custodian/game/ui/game_over/game_over_modal.gd` — modal controller that reads configured stats, restarts via `GameState.reset_run_state()`, and falls back to the configured main scene when no production menu scene exists.
- `custodian/autoload/resource_ledger.gd` — fabrication resource accounting autoload for canonical CUSTODIAN-flavored resource totals and payment checks, with legacy generic inputs normalized forward to flavored IDs
- `custodian/autoload/build_inventory.gd` — completed build-token inventory autoload used by fabrication outputs and token-gated turret/Light Barricade placement
- `custodian/autoload/fab_pipeline.gd` — recipe loading, resource payment, queued fabrication jobs, and output completion autoload; supports `build_token`, `unlock`, `resource`, and bounded `operator_consumable` outputs such as Lattice Field Patch by checking carry cap before payment and granting through `Operator.add_field_patches(...)`
- `custodian/game/fabrication/fab_job.gd` — lightweight queued fabrication job state with elapsed/duration/progress helpers
- `custodian/game/fabrication/fab_recipe_database.gd` — reusable JSON recipe database node for fabrication UI/world bridges
- `custodian/game/fabrication/fabricator_terminal.gd` — Area2D bridge for starting allowed fabrication recipes through `FabPipeline`
- `custodian/game/systems/core/systems/turret_placement.gd` — scene-wired placement compatibility surface for material/redeploy turrets plus token-driven `turret_basic` and `barricade_light` Ready Builds, shared ghost/site validation, token-safe confirmation, and placement feedback signals
- `custodian/game/actors/structures/light_barricade.gd`, `light_barricade_collision.gd`, and `.tscn` — 80-HP damageable Light Barricade with scene-native placeholder visuals, projectile-forwarding static collision, damage-state presentation, and structure/obstacle groups
- `custodian/game/resources/resource_node.gd` — harvestable interactable resource node that depletes through operator interaction, deposits primary/secondary yields into `ResourceLedger`, and can build optional looped or harvest-state `AnimatedSprite2D` strips from exported sheet paths or default per-kind 96px harvesting-node sheets; harvest-state nodes show static body frames and flash matching strike FX frames per harvest step when FX strips exist
- `custodian/game/resources/resource_node.tscn` — reusable visual/collision scene for V1 generated or authored resource nodes, with optional `NodeSprite`, `FxSprite`, and impact FX children used by resource-specific node strip playback
- `custodian/content/resources/resource_defs.json` — metadata for canonical CUSTODIAN-flavored fabrication resources
- `custodian/content/fabrication/fab_recipes.json` — starter fabrication recipes that consume canonical flavored resource IDs directly and output build tokens, unlocks, resources, or bounded Operator consumables; `lattice_field_patch` costs `resin_clot` x2, `signal_filament` x1, and `capacitor_dust` x1 and outputs `operator_consumable`
- `custodian/content/items/consumables/lattice_field_patch_01.game32.json` — consumable metadata for `lattice_field_patch` (`restore_fraction` 0.35, `use_duration` 1.25, `max_stack_carried` 2)
- `custodian/game/actors/enemies/ambient_shrumb.tscn` — live ambient Forest Shrumb actor path with shrumb slink animations, cognitive dropper, and no ruin-scrap material drops
- `custodian/game/actors/enemies/ambient_shrumb.gd` — ambient Forest Shrumb death hook that invokes the cognitive dropper before inherited enemy cleanup
- `custodian/game/actors/storage/vault_storage.gd` — enemy-openable and enemy-damageable vault storage Area2D with resource add/remove/scoring helpers, integrity state, and runtime texture-state selection used by theft/sabotage behavior
- `custodian/game/actors/storage/vault_storage.tscn` — vault storage scene used by debug fallback vault placement, now rendering stable runtime storage sprites instead of a ColorRect placeholder
- `custodian/game/actors/items/stolen_resource_pickup.gd` — recoverable stolen-resource bundle that returns payloads to `VaultManager` when picked up by the player
- `custodian/game/actors/items/stolen_resource_pickup.tscn` — placeholder pickup scene for dropped stolen vault resources
- `custodian/game/actors/enemies/enemy.gd` — shared active enemy actor, including combat behavior, explicit alive/dying/lootable/empty corpse lifecycle, roll-once structured corpse payload construction, final-death-frame persistence and empty-corpse cleanup, plus the opt-in presentation-only `AUTHORED_FRAMES`/`HUMANOID_CUTOUT` backend boundary
- `custodian/game/actors/enemies/visuals/humanoid_cutout_rig_{2d,skin,profile}.gd` and `humanoid_cutout_rig_2d.tscn` — reusable nearest-filtered rigid Node2D/Sprite2D humanoid paper-doll rig, data-only directional skin, inspector-editable 96×96 pivot/draw-order profile, fixed 20-cell atlas slicing, stable cardinal selection, and visual-only semantic animation API
- `custodian/game/actors/enemies/visuals/animations/humanoid_cutout_default_animation_library.tres` — generic pivot-only idle, run, light-attack, hit-react, and death motion library
- `custodian/game/actors/enemies/dev/{enemy_humanoid_cutout_test,humanoid_cutout_rig_review}.tscn` — isolated geometric-dev-skin enemy plus keyboard/button review scene with gameplay-size and 3× nearest previews
- `custodian/tools/aseprite/{new_humanoid_rig_source,export_humanoid_rig_atlas}.lua` — non-destructive 96×96 named-layer source creation and exact 480×384 atlas export
- `custodian/tools/assets/scaffold_humanoid_rig_skin.py` — dry-run-by-default canonical enemy rig directory/resource/README scaffold with explicit apply, placeholder, and replacement gates
- `custodian/tools/validation/humanoid_cutout_rig_smoke.gd` — focused 27-contract validation for rig structure, atlas map/regions, direction/mirroring, animation loops, visual-only ownership, filtering, dev skin, default authored backend, and grunt compatibility
- `custodian/game/systems/combat/combat_constants.gd` — shared `HitStrength` and `DamageType` enums for the hit taxonomy system, used by all damage sources and reaction logic
- `custodian/content/audio/sfx/combat/hit_*.wav` and `shrumb_hit_*.wav` — authored positional Operator melee-contact renders for body strength, target material, Great Hall acoustics, and Shrumb variation
- `custodian/tools/validation/combat_impact_audio_smoke.gd` — focused asset/profile/strength/variant contract for combat impact audio plus ordered two-track Return Causeway playlist playback
- `custodian/tools/validation/operator_knockdown_animation_smoke.gd` — focused Operator HEAVY-hit presentation check for the directional 12-frame bodyslam-knockdown body/FX strips, reaction selection, and overlay cleanup
- `custodian/game/actors/enemies/enemy_grunt.tscn` — live grunt scene using canonical runtime body/FX strips, a `CriticalExecutionAnchor`, opt-in behavior/vault-theft components, and the lore-specced typed loot table
- `custodian/game/actors/enemies/enemy_marine.tscn` — first live marine enemy scene using the `enemy_marine` custom animation set, 8-direction idle runtime strips, the east dash attack body/FX strips, and exported heavy dash tuning enabled by default, with full movement/combat/death directional coverage plus directional dash body/FX/audio still tracked as missing production assets
- `custodian/game/actors/enemies/components/enemy_behavior_profile.gd` — inspectable profile resource factory for raider, iconoclast looter, and zealot behavior variables, including theft and storage-sabotage weights/timing
- `custodian/game/actors/enemies/components/enemy_blackboard.gd` — enemy-local behavior memory for Operator sightings, objective target, carried loot, morale, patrol, and investigation state
- `custodian/game/actors/enemies/components/enemy_perception_component.gd` — Operator vision/noise detection accumulator with suspicion, notice, and lost-target signals
- `custodian/game/actors/enemies/components/enemy_objective_sensor.gd` — transparent objective scoring for Operator engagement, vault storage theft, loot escape, and investigation
- `custodian/game/actors/enemies/components/enemy_loot_carrier.gd` — carried stolen-resource payload component; `take_payload()` transfers ownership into a corpse payload at death, while detached drops remain compatibility behavior for hit/panic paths
- `custodian/game/actors/enemies/components/enemy_corpse_loot.gd` — corpse-bound structured reward owner, proximity collection guard, ResourceLedger/VaultManager/GameState delivery boundary, marker controller, and per-corpse hue restoration
- `custodian/game/vfx/loot/loot_corpse_marker.{gd,tscn}` / `loot_corpse_marker_frames.tres` / `loot_corpse_hue.gdshader` — separate reveal, persistent beacon/ring, collection-collapse, and highlight-only corpse tint presentation
- `custodian/game/actors/enemies/enemy_behavior_state_machine.gd` — compact finite state controller for idle, patrol, investigate, notice, engage, seek/open/steal storage, escape with loot, flee, stunned, and dead behavior
- `custodian/game/actors/enemies/states/` — plain enemy state script surface matching the behavior state names for future state-specific expansion
- `custodian/game/enemies/procgen/enemy_variant_profile.gd` — data-only procedural enemy profile resource generated from seed, biome, threat, family, tier, and affixes
- `custodian/game/enemies/procgen/enemy_variant_factory.gd` — deterministic procedural wolf profile composer with separate RNG streams, family/tier/affix rolls, palettes, safety clamps, and DPS normalization
- `custodian/game/enemies/procgen/wolf_animation_library.gd` — runtime `SpriteFrames` builder that slices the current wolf PNG sheets into idle/run/bite/death/howl animations
- `custodian/game/enemies/procgen/grunt_animation_library.gd` — runtime `SpriteFrames` builder and directional selector for canonical `enemy_grunt` idle/run/melee/stagger/crit/crit_recovery and direction-matched 8/12-frame execution-victim body strips, death and flinch body strips, grunt melee FX overlay strips, the `enemy_marine` 8-direction idle suite, and marine east dash body/FX strips
- `design/02_features/enemy_objective/ENEMY_MARINE_DASH_ATTACK.md` — implementation design for the enemy marine heavy dash attack contract, timing values, animation/FX/audio direction, and validation expectations.
- `custodian/game/enemies/procgen/enemy_palette_tint.gdshader` — palette/glow/contrast shader used by procedural enemy visuals
- `custodian/game/systems/core/systems/enemy_factory.gd` — wave composition factory with deterministic local composition rolls and `"wolf"`, `"grunt"`, and late-unlock `"marine"` type support
- `custodian/game/systems/core/systems/enemy_director.gd` — live directed-wave planner that scales threat into assault budget, chooses lane/objective, passes a deterministic composition queue into `WaveManager`, and forwards optional behavior-profile/debug scene references including marine
- `custodian/game/systems/core/systems/wave_manager.gd` — wave spawning system that applies procedural wolf variant profiles to spawned enemies when `"wolf"` entries are selected, can spawn dedicated `EnemyGrunt` and `EnemyMarine` scenes for `"grunt"` / `"marine"` entries, owns fallback point/burst tuning, records survived waves to `GameStats`, and exposes behavior-profile-aware debug spawn helpers used by DevConsole/startup review; startup review grunt spawning is gated by `debug_start_grunt_trigger_distance` from the initial Operator position
- `custodian/game/actors/items/cognitive_pickup.tscn` — generic pickup scene for cognitive item drops
- `custodian/game/actors/items/cognitive_pickup.gd` — pickup flow that increments `InventoryManager`, applies `CognitiveState`, animates the 4-frame item sheet, and emits popup/log feedback
- `custodian/game/actors/items/consumables/lattice_field_patch_pickup.tscn` and `.gd` — sealed emergency Field Patch cache pickup; grants +1 carried patch below Operator cap and grants fallback `ResourceLedger` materials when already full
- `custodian/game/actors/items/shrumb_dropper.gd` — reusable Forest Shrumb cognitive drop table component
- `custodian/game/ui/hud/ui.gd` — active command terminal HUD integration, semantic IBM Plex display/mono typography hierarchy, clickable OVERVIEW diagnosis/map/attention-feed composition with collapsed boot chatter, compact chip header, explicit wheel/focus-aware primary/secondary nav grouping, protected reboot routing, clickable FABRICATION flat-row/detail-grid rendering and actions, missing-terminal-asset warnings plus layout-open telemetry routed to `DevObservatory`, full-scrim terminal modal suppression, page orchestration, and dedicated debug screen feeding; FABRICATION uses a translation layer for player-readable recipe, ready-build, and placement commands
- `custodian/content/ui/fonts/` — shipped IBM Plex Sans Condensed/Mono terminal fonts with SIL OFL provenance, stable runtime aliases, and guarded default-font fallback
- `custodian/tools/validation/terminal_typography_smoke.gd` — focused font import, semantic hierarchy, Fabrication density, ellipsis, and horizontal-scroll policy validation
- `custodian/tools/validation/terminal_overview_layout_smoke.gd` — focused 1366×768 Overview contract proving compact chip-header fit, explicit scroll hierarchy, pinned More/actions, wheel and hidden-focus behavior, compact summaries, live-map fill, clickable diagnosis cards, boot collapse, command/transcript containment, full modal scrim, and no page-level/horizontal scrolling
- `custodian/game/ui/terminal/fabrication_terminal_view_model.gd` — player-facing fabrication translation layer that turns raw recipe/resource/build-token state into work orders, structured resource need/have/missing rows, selected detail, queue summaries, ready builds, and command help for the terminal HUD
- `custodian/game/ui/hud/debug_screen.tscn` and `.gd` — dedicated read-only tabbed debug screen opened by F12 or `debug_hud`, with runtime/player/combat/world/systems/inventory snapshots.
- `custodian/scenes/debug/dev_observatory_overlay.tscn` / `custodian/scripts/debug/dev_observatory_overlay.gd` — F9 developer observatory overlay mounted in the main scene; Tab/Shift+Tab cycles Overview, Performance, Warnings, Events, and World/Procgen without owning simulation logic.
- `custodian/game/ui/intel_demo/intel_fidelity_demo.tscn` and `.gd` — dev-only playable/readable intel-fidelity demo scene that shows actual sector truth beside the player-facing projection at different fidelity levels; not wired into the live terminal, minimap, combat, enemies, or main scene.
- `custodian/game/ui/theme/black_reliquary_palette.gd` — shared Black Reliquary HUD palette constants.
- `custodian/game/ui/theme/black_reliquary_styles.gd` — reusable Black Reliquary UI style helpers, NinePatch configuration, texture loading, and fallback panel styles.
- `custodian/game/ui/theme/black_reliquary_asset_catalog.gd` — centralized `res://content/ui/black_reliquary/` asset paths for panels, icons, prompt plaques, minimap art, and markers.
- `custodian/game/ui/components/black_reliquary_panel.tscn` and `.gd` — reusable NinePatch-backed dark/brass panel with StyleBox fallback.
- `custodian/game/ui/components/black_reliquary_prompt.tscn` and `.gd` — styled interaction prompt plaque that renders title/body/key hint as Godot labels.
- `custodian/game/ui/components/black_reliquary_icon_label.tscn` and `.gd` — reusable icon-only, label-only, or icon+label status row component.
- `custodian/game/ui/components/black_reliquary_minimap_frame.tscn` and `.gd` — compact Black Reliquary tactical minimap plate that embeds the shared live `minimap_panel.tscn` renderer with nested chrome hidden and tighter marker sizing.
- `custodian/game/ui/hud/custodian_hud.tscn` and `.gd` — reusable compact Black Reliquary gameplay HUD shell currently instanced locally by Sundered Keep and Home, with persistent magazine/reserve counts, a read-only heat/reload/dry/vent pressure row, layered actual/recoverable health presentation plus transient reclaim feedback, context-active visibility, and separately composed `gameplay_overlay` terminal suppression.
- `custodian/game/ui/minimap/minimap_panel.tscn` — shared live tactical minimap panel instanced by the legacy HUD, terminal tactical map, and compact Black Reliquary minimap wrapper.
- `custodian/game/ui/minimap/minimap_controller.gd` — discovers runtime procgen or authored map providers plus player/enemy/objective/utility nodes, feeds live minimap data to the view, and switches the embedded terminal instance into Overview presentation mode.
- `custodian/game/ui/minimap/minimap_view.gd` — data-driven minimap renderer that caches procgen/authored floor-wall terrain, supports actor-bounds fallback maps, draws tactical pips, and exposes an explicit 72%-fill Overview map rect shared by rendering and local-to-world conversion.
- `custodian/game/ui/inventory/inventory_ui.tscn` — hidden live-game Black Reliquary inventory overlay instanced under `UI` and opened with the inventory input action; now the primary status/history/ledger surface with tabbed pages
- `custodian/game/ui/inventory/inventory_ui.gd` — live `InventoryManager`-backed field-ledger overlay with persistent Status/Equipment/Ledger/History pages, Archive Glass backdrop integration, responsive container-laid 2-4-column cards, hover identity/class/quantity/description tooltips, independent selection/focus presentation, contained Status layout, dedicated footer, available-equipment register, constrained sidearm/relic equip controls, and compatibility support for isolated local `Inventory` callers
- `custodian/game/ui/inventory/inventory_asset_catalog.gd` — canonical production inventory UI/item-icon resolver that automatically prefers assets under `content/ui/inventory/runtime/` and falls back to existing Black Reliquary/legacy textures
- `custodian/game/ui/inventory/shaders/inventory_ember_spark.gdshader` and `materials/blackwood_ember_spark_material.tres` — reusable alpha-bounded inventory ember/spark effect and the blackwood-only default material instance
- `custodian/game/ui/inventory/shaders/reliquary_inventory_backdrop.gdshader` and `materials/reliquary_inventory_backdrop_material.tres` — full-screen Black Reliquary Archive Glass shader/material that suppresses, desaturates, cold-tints, and softly compresses live-world highlights beneath the sharp inventory
- `custodian/game/ui/inventory/inventory_item_catalog.gd` — deterministic carried-item metadata resolver for known item JSON definitions plus readable fallback records for future/unknown ledger IDs
- `custodian/content/ui/inventory/runtime/inventory_ui_asset_manifest.json` — exact production inventory asset drop-in contract for panels, slots, icons, and ornaments
- `custodian/content/ui/inventory/runtime/README.md` — inventory production asset naming, placement, and replacement workflow
- `custodian/tools/validation/inventory_ui_smoke.gd` — validates the live ledger-backed inventory scene, Archive Glass material contract, register/footer surfaces, fixed contained card icons, persistent selection versus focus corners, equipment columns, close behavior, and asset-manifest fallback contract
- `custodian/tools/validation/initiative_vanguard_seal_smoke.gd` — validates initiative modifiers and no-retrigger rules, quiet-window reset, Vanguard activation/break behavior, relic equipment persistence/legacy saves, catalog definition, and exact icon/VFX contracts
- `custodian/tools/validation/inventory_ui_responsive_smoke.gd` — validates 2048x1152, 1920x1080, 1600x900, 1280x720, and 1152x648 column policy, card bounds, supported Status/footer containment, keyboard/controller prompts, and optional graphical Status/Ledger/Equipment captures
- `custodian/tools/ui/normalize_inventory_icons.py` — alpha-crops and nearest-neighbor repads existing inventory icons to canonical centered 128x128 runtime canvases
- `design/02_features/ui/INVENTORY_PAUSE_MENU_REFINEMENT.md` — implemented Field Ledger hierarchy, Archive Glass grading, responsive register/Status layout, fixed icon containment, independent selection/focus, footer/equipment structure, controls, prompts, inspection scrolling, and icon-normalization contract
- `custodian/docs/ai_context/task_packets/archived/CUSTODIAN_INVENTORY_UI.md` — completed packet for the live professional inventory overlay and production-asset drop-in contract
- `custodian/docs/ai_context/task_packets/FAB_TERMINAL_READABILITY_PASS.md` — completed packet for the FABRICATION work-order readability pass, including the terminal translation layer and build-placement alias
- `custodian/game/ui/terminal/terminal_command_router.gd` — command parsing, validation, refresh policy, and dispatch boundary for the HUD terminal
- `custodian/game/ui/terminal/terminal_snapshot.gd` — read-only terminal snapshot aggregation from runtime groups/autoloads/systems, including deterministic physics-frame time, physical-terminal command authority, sector-only Operator location and system counts, vault totals, and enemy diagnostic signals; broad `structure` membership is never used as sector authority
- `custodian/game/ui/terminal/terminal_fidelity_policy.gd` — pure command/field plus communications-state policy for FULL, DEGRADED, FRAGMENTED, and LOST information quality
- `custodian/game/ui/terminal/terminal_status_formatter.gd` — sole deterministic canonical STATUS formatter shared by page rendering and typed STATUS commands
- `custodian/game/ui/terminal/terminal_overview_view_model.gd` — pure weighted sector diagnosis, stable incident/recommendation IDs, and offline/cold-start summary model
- `custodian/tools/validation/terminal_status_fidelity_smoke.gd` and `terminal_overview_semantics_smoke.gd` — focused semantic validation for fidelity omissions, simulation-clock/header ownership, and ranked Overview diagnosis
- `custodian/tools/validation/terminal_snapshot_sector_identity_smoke.gd` — proves six sectors remain six terminal sector records even when five turrets also belong to the broader `structure` group
- `custodian/tools/validation/power_rate_units_smoke.gd` — proves generation, consumption, net rate, and one-second energy integration remain delta-independent at 30/60/120 Hz
- `custodian/tools/validation/terminal_overview_live_snapshot_smoke.gd` — full-game integration check for sector-only snapshots, authoritative negative net rate, deficit recommendation copy, and `open_power` routing
- `custodian/tools/validation/terminal_defense_semantics_smoke.gd` — full-game semantic check for health-first Defense readiness and honest unavailable engagement controls
- `custodian/game/ui/terminal/terminal_map_preview.gd` — compatibility texture-preview boundary with 256px ordinary and 448px Overview fallback sizing; the live terminal map renders and converts coordinates through the shared minimap controller/view
- `custodian/game/ui/terminal/terminal_planet_preview.gd` — terminal globe viewport, rotation, zoom, and preview input handling
- `custodian/game/actors/operator/operator.gd` — Operator simulation and health authority plus authoritative incoming/outgoing Integrity Reclaim gateways, fixed-step reclaim advancement, generic profile-owned collision-safe melee attack drive, weapon-owned body/overlay installation, authored-frame chain command/commit/reset ownership, and presentation hooks for directional dodge/Flow and atomic modular reactions
- `custodian/game/actors/operator/combat/operator_integrity_reclaim.gd` — Operator-owned deterministic RefCounted for independently expiring recoverable-damage packets, second-hit forfeiture, health ceilings, source efficiencies, healing clamp, and read-only event/status output
- `custodian/tools/validation/operator_integrity_reclaim_smoke.gd` — focused reclaim smoke covering exact conversion/recovery values, independent light/heavy packet windows, decay, re-hit forfeiture, passive/allied/structure/DoT rejection, overkill clamp, fatal clearing, Field Patch-compatible clamp, HUD layering, and repeated fixed-step determinism
- `custodian/game/actors/operator/operator.tscn` — Operator scene with body/weapon layers, exact weapon sockets, collision/hitbox roots, health bar, and presentation-only weapon/dodge-charge feedback children
- `custodian/game/vfx/combat/dodge_charge_feedback.gd` / `.tscn` — non-authoritative charge presentation consumer for ratio-selected ring art, compression, latch, origin burst, trail, one maximum afterimage, controller pulse, rejection contraction, and tiny camera impulse
- `custodian/game/actors/operator/operator_weapon_definition.gd` — weapon/combat profile resource schema and JSON accessor boundary, including independent held/body/melee-overlay `SpriteFrames`, ammo/heat/noise/projectile/sound values, intents, combat multipliers, melee profiles, and data-driven fast-chain keys/commit frames/stamina/recovery flags
- `custodian/game/actors/operator/vigil_pattern_dagger_{definition,frames,body_frames,melee_overlay_frames,fx_frames}.tres` and `attacks/vigil_pattern_dagger_fast_{01,02,03}.tres` — default dagger fast chain with synchronized 10-frame body/weapon/FX resources and per-link 7/9/11 px drive
- `custodian/game/actors/operator/sword_cleaver_{definition,held_frames,body_frames,weapon_overlay_frames,fx_frames}.tres` and `attacks/sword_cleaver_fast_{01,02,03}.tres` — optional cleaver fast chain using the provisional shared Chain 01 motion, weapon-specific overlays, and per-link 9/11/14 px drive; held/heavy art remains deferred
- `custodian/game/actors/operator/fallen_star_katana_definition.tres` — separate later Katana profile with the authored `melee_fast_1/2/3` chain, zero-based `5/5/6` damage/commit frames, `7/8/10` stamina progression, looping back to Fast 01, integrated recovery, and zero drive pending Katana-specific tuning
- `design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md` — universal bounded CharacterBody2D attack-momentum ownership, input filtering, collision, cancellation, and limitations
- `design/02_features/weapons/{VIGIL_PATTERN_DAGGER,FALLEN_STAR_KATANA}.md` — weapon-specific baseline and later-weapon contracts
- `design/02_features/combat_feel/OPERATOR_MELEE_FAST_CHAIN.md` — implemented Katana three-link authority for source/runtime asset ownership, command buffering, authored-frame commitment, direction, recovery, resets, and validation
- `custodian/game/actors/operator/animations/operator_weapon_socket_library.gd` — strict generated-JSON loader, eight-way aim-sector resolver, and typed frame-socket decoder for Operator ranged weapon placement
- `custodian/content/data/operator/generated/operator_weapon_sockets.generated.json` — generated Carbine phase-1 `e/w/se/sw` per-frame grip/support/muzzle/ejection/angle/draw-order authority
- `custodian/tools/aseprite/export_operator_weapon_sockets.lua` — Aseprite named-slice exporter for operator-local per-tag/per-frame socket JSON
- `custodian/game/actors/operator/components/weapon_feedback_presenter.gd` — presentation-only consumer of Operator weapon feedback events; plays configured local audio, flashes the weapon sprite, and spawns barrel vent VFX while logging missing assets loudly and never touching gameplay state or `NoiseEventBus`
- `custodian/game/actors/operator/carbine_rifle_mk1_definition.tres` — starter ranged weapon definition; secondary intent is `ranged_ready`, while primary fire is requested only during held ranged-ready
- `custodian/game/systems/combat/melee_attack_profile.gd` — reusable melee attack physics profile for damage, range, arc, knockback, timing, input movement, bounded attack drive, hit-stop, camera shake, animation fallback, and hit-window data
- `custodian/game/actors/operator/attacks/*.tres` — default operator melee/Fists attack profile resources wired into weapon definitions
- `custodian/game/actors/operator/unarmed_definition.tres` — Fists/unarmed combat profile used by `toggle_unarmed`, now referencing unarmed fast/heavy attack profiles
- `custodian/project.godot` — canonical runtime input bindings, including WASD/left-stick movement, mouse/right-stick aim, `fire_primary` / compatibility `attack_primary` on left mouse / Xbox RT, context-sensitive offhand secondary `aim_hold` / compatibility `attack_secondary` on right mouse / Xbox LT for ranged-ready, sidearm-ready, or guard-ready by slot context, `dodge` on Space / Xbox B, `interact` on E / Xbox A, `reload` on R / Xbox X, inventory on Tab/I / Xbox Y, `use_field_patch` on keyboard P, quick item and item cycling, pause, map, `toggle_unarmed`, and `build` on keyboard B
- `custodian/game/actors/operator/animations/animation_state_machine.gd` — deterministic operator animation state transition manager with priorities, elapsed time, and same-state re-entry support
- `custodian/game/actors/operator/animations/states/attack_light_state.gd` — default unmodified melee attack animation state
- `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md` — active combat feel doctrine, including animation-driven attack loop, profile-relative attack intents, context-sensitive offhand secondary routing, twin-stick ranged-ready/sidearm-ready/parry-guard control contract, and movement-first dodge/backstep rules
- `design/02_features/combat_feel/FIRST_STRIKE_AND_INITIATIVE.md` — implemented authority for universal stagger-only initiative, engagement boundaries, Vanguard Seal eligibility/timing, constrained relic equipment, and presentation
- `design/02_features/operator/DODGE_CHARGED_LONG_ROLL.md` — implemented bounded tap/long/committed dodge authority; distance and recovery scale while the active/iframe clock remains fixed and charge remains vulnerable
- `design/02_features/operator/DODGE_CHARGE_FEEDBACK.md` — implemented additive world-space/HUD presentation contract; ordinary dodge art remains intact and the feedback component never owns simulation values
- `design/02_features/operator/DODGE_FLOW.md` — implemented deterministic chain-buffer, directional retention, fixed-iframe link, atlas slicing, final cooldown, exit carry, decay, presentation, telemetry, and validation contract
- `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md` — active authority for guard/parry branching, explicit enemy critical-open phases, atomic reservation, paired alignment, nonuniform execution timing, source-frame-5 damage/contact freeze, and cleanup ownership
- `design/02_features/combat_feel/CRITICAL_OPEN_OPTIONAL_VFX.md` — implemented optional-polish contract for the posture-break opening flash and unconsumed critical-window closure effect
- `design/02_features/combat_feel/COMBAT_FEEL_UPGRADE.md` — ordered combat feel implementation lane after sprite pipeline cleanup
- `design/02_features/animation/ENEMY_GRUNT_RUNTIME_WIRING.md` — implementation note documenting the `enemy_grunt` scene, current partial art coverage, and wave wiring acceptance
- `design/02_features/enemy_objective/GRUNT_LOOT_TABLE.md` — practical salvage/provenance table for baseline grunts; successful rolls remain corpse-bound until collection
- `design/02_features/loot/LOOTABLE_CORPSE_BEACON_SYSTEM.md` — lifecycle, payload delivery, VFX, cleanup, persistence limitation, asset contract, and validation authority for lootable corpses
- `custodian/tools/validation/authored_vault_grunt_loot_marine_smoke.gd` — focused headless smoke check for typed grunt loot, marine 8-direction idle frame wiring, heavy dash tuning/export availability, and gothic compound authored vault-room placement
- `custodian/tools/validation/lootable_corpse_beacon_smoke.gd` — focused roll-once/deliver-once corpse payload, marker phase, duplicate-collection, cleanup immunity, and typed/carried reward destination smoke
- `custodian/tools/validation/fabrication_terminal_readability_smoke.gd` — focused headless smoke check for the FABRICATION translation layer, structured cost rows, consumable category, ready-build placement alias, and readable next-action output
- `custodian/tools/validation/fabrication_terminal_command_smoke.gd` — focused headless smoke check for uppercase terminal fabrication commands resolving to lowercase recipe/resource ids before pipeline and ledger lookups.
- `custodian/tools/validation/fabrication_terminal_clickable_smoke.gd` — focused headless smoke check for flat work-order composition, highlighted selection/detail synchronization, structured detail, collapsed empty status, and Craft-button job start
- `custodian/tools/validation/build_structure_placement_smoke.gd` — focused end-to-end smoke for Light Barricade fabrication completion, deployable Ready Build state, ghost mode, invalid-site token preservation, valid placement/token consumption, damage/destruction, and Basic Turret regression
- `custodian/tools/validation/fabrication_terminal_layout_smoke.gd` — focused headless smoke check that FABRICATION disables horizontal and page-level scrolling, keeps its action row inside the viewport, and reserves vertical scrolling for work orders and the page rail
- `custodian/tools/validation/terminal_stylebox_rendering_smoke.gd` — focused headless smoke check that terminal panel/map/widget `StyleBoxTexture` frames use small border-only tile-fit margins, header/nav/action/input controls use stretched single centers, and compact Fabrication status UI uses the intentional flat-style exception
- `custodian/tools/validation/gothic_compound_occlusion_smoke.gd` — focused headless smoke check for gothic compound wall/gatehouse base-rooted occlusion sorting and flat floor/road/decal layer separation
- `custodian/tools/validation/intel_projector_smoke.gd` — focused headless smoke check proving FULL, DEGRADED, FRAGMENTED, and LOST intel projections all derive from the same unmodified sector truth.
- `custodian/tools/validation/dev_observatory_smoke.gd` — focused headless smoke check for bounded observatory storage, F9/F10 actions, stable/timestamped JSON export, JSON-safe Variant conversion, buffer retention, success events, failure warnings, and basic heatmap accumulation.
- `custodian/tools/validation/sector_heatmap_smoke.gd` — focused headless smoke for the autoload API, cell aggregation, event weights, JSON-safe keys, timestamps, summary ranking, legacy query compatibility, and clearing.
- `custodian/tools/validation/world_telemetry_foundation_smoke.gd` — focused headless smoke check for derived world-state evaluation, sector-history recording, immediate/5 Hz interest-tier classification, and dormant enemy physics suppression/reactivation.
- `custodian/tools/validation/operator_ranged_ready_input_smoke.gd` — focused headless smoke check for ranged-ready/twin-stick input bindings, offhand secondary mode resolution, parry/guard handshake, successful-parry counter queue/release timing, held-block release/repress guard gating after parry success, carbine secondary intent, operator ranged-ready helper state, and dodge/backstep direction rules
- `custodian/tools/validation/field_patch_smoke.gd` — focused headless smoke for Field Patch input binding, no pre-commit heal, commit restore/count consumption, damage/input interruption before commit, count preservation on interrupt, capped restock helper behavior, terminal fabrication restock, cap-blocked no-spend behavior, and emergency-cache fallback materials
- `custodian/tools/validation/grunt_parry_crit_reaction_smoke.gd` — focused headless smoke proving independent-root enter/hold/recover, normal-target suppression, BREACH/ring and optional opening/expiry VFX ownership/toggle/auto-free, atomic reservation, zero-offset shared execution roots, synchronized semantic clips, nonuniform holds, source-frame-5 exactly-once damage/contact freeze, final settle, and cleanup
- `custodian/tools/validation/grunt_falcon_punch_smoke.gd` — focused headless smoke proving Falcon Punch tracking tell, natural stationary-target contact, 21 distance-band connection samples, launch/active-start/closest/lateral/dodge/obstruction telemetry, stop-short travel, body/enemy separation, hit-confirmed impact lock, direct whiff recovery/reason telemetry, dedicated victim impact, zero-impact-lock parry cancel/lockout, deterministic eligibility, and ally-lane rejection
- `custodian/tools/validation/operator_ammo_reconciliation_smoke.gd` — controlled 18-projectile carbine ledger test proving fresh 24/48 ammo reconciles to 6/48 and active weapon context reaches Observatory gauges.
- `custodian/tools/validation/operator_dodge_overlap_telemetry_smoke.gd` — 20-hit overlap test proving exactly one canonical iframe/late/recovery classification per attack ID.
- `custodian/tools/validation/operator_charged_long_roll_smoke.gd` — focused tier-boundary, speed/recovery/stamina, fixed-iframe, charge-vulnerability, attack-commitment, and hold/release input validation for charged rolls
- `custodian/tools/validation/operator_dodge_charge_feedback_smoke.gd` — focused runtime asset, scene ownership, ratio-frame, visual-delay, compression/latch/release/rejection, and temporary stamina-label validation
- `custodian/tools/validation/operator_dodge_flow_smoke.gd` — focused opener Flow, input window, turn retention, dedicated clean/90-degree link art, full-atlas reverse pivot, fixed clocks/modifiers, late grace, cooldown, exit carry/decay, stamina, signals, and telemetry validation
- `custodian/tools/validation/operator_dodge_presentation_smoke.gd` — ratio-frame charge, nearest-direction fallback, four-frame link-cycle, hard-pivot, no-neutral-link, and iframe-invariance validation
- `custodian/tools/validation/operator_modular_idle_hitreact_smoke.gd` — synchronized required lower/upper and optional head reaction, N/S fallback, atomic legacy fallback, priority, locomotion lockout, and cleanup validation
- `custodian/tools/validation/operator_modular_layers_smoke.gd` — focused modular operator presentation smoke covering unarmed locomotion, ranged-ready lower/upper ownership split, and clean legacy fallback when the modular ranged upper stack is unavailable
- `custodian/tools/validation/operator_primary_ranged_modular_fire_smoke.gd` — focused headless smoke for raise/lower direction retargeting with preserved progress, committed fire direction, recovery resolution, posture sequence, upper/weapon direction and frame synchronization, muzzle alignment, and cleanup
- `custodian/tools/validation/operator_weapon_socket_smoke.gd` — focused Carbine socket/camera smoke covering eight-way resolution, phase-1 art and frame metadata coverage, socket-derived muzzle, direction-aware draw order, asymmetric transition timing, additive aim camera lead/zoom/shake, and exact cancellation return
- `custodian/game/ui/hud/components/ranged_reticle.gd` / `.tscn` — procedural read-only ranged posture reticle driven by canonical `get_weapon_status()` values
- `custodian/tools/validation/wave_manager_debug_grunt_spawn_gate_smoke.gd` — focused WaveManager smoke proving the startup debug grunt stays despawned inside the Operator spawn threshold and appears once after the Operator crosses it
- `design/02_features/operator/UNARMED_TOGGLE.md` — unarmed/Fists selection behavior, state rules, and acceptance tests
- `design/02_features/operator/UNARMED_TOGGLE_CODE.md` — implementation notes for the unarmed/Fists profile selection system
- `design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md` — hybrid authored-body + socketed-weapon design: static directional weapon sprites positioned at per-frame sockets with procedural rotation, replacing baked weapon animation strips; includes deprecation path for legacy weapon SpriteFrames and phased implementation plan
- `design/02_features/minimap/MINIMAP_SYSTEM.md` — custom data-driven tactical minimap implementation spec
- `design/02_features/minimap/MINIMAP_SYSTEM_CODE.md` — minimap runtime code plan and integration notes
- `design/02_features/procgen/GOTHIC_COMPOUND_PROCGEN.md` — active implementation note and migrated review for constraint-first gothic compound blueprint generation
- `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md` — active route-authoritative playability contract for clearance bands, visible road treatment, critical pads, pocket roles, dressing density, constrained floor cleanup, and final blocker-aware reachability/minimum-width validation
- `custodian/game/world/procgen/playability/route_distance_field.gd` — deterministic floor-constrained multi-source route distance builder
- `custodian/game/world/procgen/playability/playable_pocket_classifier.gd` — translates intent reservations into arrival, exit, safe, combat, resource, vista, story, branch, and travel roles plus critical/encounter clear cells
- `custodian/game/world/procgen/playability/route_playability_field.gd` — composes route bands and pockets, performs protected exterior cleanup, and audits post-decoration blockers, reachability, and minimum route width
- `design/02_features/terminal/TERMINAL_DESIGN_AUDIT.md` — source/design audit of the command terminal (has factual errors — verify against runtime before implementing)
- `design/02_features/terminal/TERMINAL_AUDIT_VERIFICATION.md` — runtime verification correcting the audit: fidelity policy, status formatter, overview view model, and validation smokes already exist; corrected page maturity matrix and implementation sequence
- `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md` — canonical thirteen-page terminal implementation authority (supersedes `design/01_systems/TERMINAL_COMMAND_INTERFACE.md` and `design/01_systems/ROADMAP_COMMAND_TERMINAL.md`)

## Active Interaction/UI Files

- `custodian/game/actors/defense/turret.gd` — turret interaction prompt reads actual interact binding
- `custodian/game/actors/base/vehicle_base.gd` — legacy/compatibility vehicle base retained for older scenes and references
- `custodian/game/actors/vehicles/light_buggy.tscn` — first production vehicle scene, now backed by `PilotableVehicle` and registry ID `custodian_ground_buggy_scout_light`
- `custodian/game/systems/core/player_controller.gd` — input router for Operator vs vehicle control, including guarded vehicle actions and camera follow-target handoff
- `custodian/game/world/camera.gd` — world camera controller with `set_follow_target(target)` for Operator/vehicle follow switching, map-bound clamping, manual middle-mouse panning, and movement-input recovery back to Operator follow
- `custodian/game/actors/terminal/command_terminal.gd` — in-world `command_terminal` prop interaction and activation/deactivation animation, with fallback compatibility to the older `computer_terminal` sheets and the authored `builder_terminal` pickup/deploy sheet
- `custodian/game/systems/core/systems/terminal_deployment.gd` — deployable terminal pickup/redeploy runtime for the in-world command terminal prop
- `custodian/docs/TERMINAL_VIEW_LOCAL_MODE.md` — terminal-related runtime doc reference

## Active Asset Pipeline

- `custodian/tools/art/source_to_pixel_art.py` — deterministic high-resolution source-art prep utility, exposed as `pixelart` by `tools/custodian_aliases.sh`; generates crisp nearest, balanced area/palette, and bold clustered candidates, presents a comparison, and writes the interactively or explicitly selected PNG
- `custodian/tools/pipelines/ingest.py` and `ingest_runtime.gd` — manifest-driven sprite ingest that writes into live runtime sprite domains, automatically emits frame-flipped `e↔w`/`ne↔nw`/`se↔sw` counterparts unless explicitly authored or opted out with `--no-mirror`/`"auto_mirror": false`, runs post-process rebuilds including modular Operator runtime refreshes, archives processed intake, and cleans source PNG `.import` sidecars without staging Git changes
- `custodian/tools/pipelines/generate_inbox_manifests.py` — deterministic inbox manifest generator that infers JSON sidecars from canonical filenames and image dimensions, routes enemy/drone sheets to domain-owned `enemies/<actor>/runtime/<layer>/<action_group>/` paths without loose-root outputs, retains owner-first allied routing plus legacy compatibility outputs, supports flat items, harvesting nodes, modular Operator layers including `cape` and `modular_ranged_weapon`, and hover buggy vehicle filenames, then runs the ingest pipeline
- `custodian/tools/pipelines/aseprite_inbox.py` — staging helper that moves aseprite PNG exports into the sprite inbox, prompts for incomplete canonical filename blocks, and can chain manifest generation / ingest
- `custodian/tools/pipelines/reload_assets.py` — direct operator curated-resource rebuild entrypoint
- `custodian/tools/pipelines/update_operator_curated_resources.gd` — rebuilds operator runtime `SpriteFrames` from curated/source sheets, including modular unarmed fast windup/strike/recovery lower/upper/FX registrations and separate modular lower/upper body locomotion frame resources
- `custodian/tools/pipelines/build_operator_modular_runtime.py` — builds stable runtime sheets from `content/sprites/operator/new_operator/modular/`, including lower/upper locomotion, generic cape actions, weapon-specific relaxed-carbine normalization, legacy source compatibility, modular unarmed fast-attack phases, preserved `melee_1h` action modules (including Katana chain FX), and baked body/FX strips with fallback/canvas normalization
- `custodian/tools/pipelines/build_actor_spriteframes.py` — generic non-Operator actor `SpriteFrames` builder that recursively scans domain-owned `content/sprites/enemies/<owner>/runtime/<layer>/<action_group>/` strips for enemies without a loose-root fallback, retains compatibility-root merging for allied actors, and writes `<owner>_body_frames.tres` / `<owner>_fx_frames.tres` under `game/actors/<domain>/<owner>/`
- `custodian/tools/pipelines/ingest.py` — Python launcher for the Godot sprite ingest runtime; `--build-operator-runtime` explicitly rebuilds already-authored Operator modular source after successful ingest and respects dry-run/superseded-cleanup flags
- `custodian/tools/operator/operator_ingest.sh` — thin Operator modular ingest wrapper, also exposed as `opingest` by `tools/custodian_aliases.sh`; dry-run by default, `--apply` runs inbox manifest generation, modular runtime build, Godot import, curated SpriteFrames update, modular layer smoke, and contract-report output
- `custodian/tools/operator/split_operator_melee_fast_chain.py` — guarded one-time splitter for the verified `3432x96` Katana chain master; rejects wrong dimensions or identical Fast 01/Fast 02 source ranges and writes the canonical `7/7/8` runtime strips
- `custodian/tools/validation/contracts/operator_modular_core.json` — editable Operator modular animation coverage contract for required/optional locomotion, combat, defense, dodge, sidearm, ranged, and optional layer coverage
- `custodian/tools/validation/operator_animation_contract_report.py` — read-only Operator modular production report for missing, optional, suspicious, extra, source/runtime drift, and next-batch animation coverage
- `custodian/tools/pipelines/operator_action_preview.py` — generalized Operator modular/action-runtime preview compositor that writes review-only strips/grids to `custodian/animation_review/`
- `custodian/tools/pipelines/scaffold_character_contract.py` — new-character checklist/contract/expected-filename scaffold helper that writes planning files under `content/sprites/_pipeline/requests/<owner>/`
- `custodian/tools/operator/check_operator_modular_assets.py`, `custodian/tools/operator/refresh_combo_check_src.sh`, `custodian/tools/operator/modular_combo_check.py`, `custodian/tools/operator/operator_next_actions_report.py`, `custodian/tools/operator/review_modular_body_pairs.py`, and `custodian/tools/operator/review_modular_flat_png_pairs.py` — modular Operator asset audit/review helpers; the combo checker supports positional animation-domain and all-runtime-direction selection, combo records retain canonical resolved sources, and the next-actions helper joins visual fit to the production contract/report for grouped ranked implementation guidance. See `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md` before choosing one.
- `custodian/game/systems/debug/dev_mode.gd` and `design/02_features/debug_ui/DEV_MODE_SYSTEM.md` — central runtime developer-capability authority deriving cheap UI/Observatory and explicit heavy-diagnostic eligibility from build, export feature, project setting, and command-line overrides
- `custodian/tools/validation/dev_mode_smoke.gd` — focused capability-resolution and debug-autoload-order smoke
- `custodian/tools/validation/operator_next_actions_report_smoke.py` — offline smoke proving grouped fast-attack recommendations, actionable paths/commands, generated-artifact metadata, Markdown output, and HTML embedding
- `custodian/tools/validation/source_to_pixel_art_smoke.py` — focused Pillow smoke proving all three source-art conversion modes, 96×96 RGBA output, distinct results, named selection, and retained comparison artifacts
- `custodian/tools/validation/sprite_directional_mirror_pipeline_smoke.gd` — focused ingest smoke for canonical and simple-character direction pairing, authored-counterpart precedence, no-mirror opt-out, and per-frame horizontal pixel flipping across Operator, enemy, allied, and generic owner paths
- `custodian/docs/ai_context/task_packets/MODULAR_NEXT_ACTIONS_AND_DEV_MODE.md` — completed implementation record for central runtime development eligibility and contract-aware modular review recommendations
- `custodian/content/sprites/operator/runtime/modules/new_operator/` — runtime home for new operator modular parts; lower/upper locomotion module strips feed the first layered Fists idle/walk/run rig, and lower/upper/upper-FX fast-attack modules feed windup/strike/recovery playback when coverage exists
- `design/02_features/animation/OPERATOR_MODULAR_HEAD_PIPELINE.md` — modular head naming, cosmetic-profile routing, runtime ownership, synchronization, fallback, and validation contract
- `custodian/game/actors/operator/operator_modular_head_frames.tres` — generated modular head animation resource consumed by `ModularHeadSprite`; current authored coverage is hooded south idle
- `custodian/content/sprites/operator/runtime/actions/unarmed/fast_attack/` — runtime-dedicated baked action body/overlay strips generated from `new_operator/modular/fast_attack/` for hidden legacy timing and fallback fast-attack playback
- `custodian/tools/validation/operator_modular_fast_attack_smoke.gd` — focused Godot smoke proving existing modular fast-attack runtime PNGs are registered in SpriteFrames, Operator windup/strike/recovery helpers play the modular layers per direction, and fast primary from explicit dodge recovery skips unarmed windup while preserving dodge cooldown
- `custodian/tools/validation/operator_melee_fast_chain_smoke.gd` — focused Katana smoke proving the master/slices are distinct and correctly sized, three non-looping clips register at 18 FPS, frame `5/5/6` commits produce `1 -> 2 -> 3 -> 1`, first input wins, stamina progresses, heavy/dodge branches respect contact/final stance, whiffs link, hits dedupe, integrated recovery skips the legacy clip, and reset/retarget/feel rules hold
- `custodian/tools/validation/operator_vigil_dagger_smoke.gd` — focused default-dagger smoke for three-link resource ownership, synchronized E/W body/weapon/FX playback, drive, collision, and cancellation
- `custodian/tools/validation/operator_sword_cleaver_smoke.gd` — focused optional-cleaver smoke for loadout isolation, three per-link profiles, 10-frame synchronization, bounded finisher drive, retained dagger default, and Katana separation
- `custodian/docs/ai_context/task_packets/VIGIL_PATTERN_DAGGER_ATTACK_DRIVE.md` — implementation/handoff packet for the dagger bootstrap, generic drive boundary, validation, drift repair, and deferred art/actions
- `design/02_features/animation/ENEMY_SAVAGE_RUNTIME_WIRING.md` — active first-slice Savage runtime authority and next art-wiring queue
- `custodian/game/actors/enemies/enemy_savage.tscn` — active Savage actor scene using the shared Enemy simulation/behavior owner
- `custodian/game/actors/enemies/components/enemy_behavior_profile.gd` — shared behavior-profile factory, including the high-aggression, no-theft `raider_savage` profile
- `custodian/tools/validation/enemy_savage_smoke.gd` — focused Savage stats/profile plus two-hit-chain and pounce contract validation
- `custodian/game/systems/presentation/directional_animation_fallback.gd` — shared presentation-only eight-sector nearest-art resolver with previous-sector tie stability
- `custodian/tools/validation/directional_animation_fallback_smoke.gd` — exact, diagonal, tie, previous-sector, and empty-coverage fallback validation
- `custodian/game/enemies/procgen/savage_animation_library.gd` — explicit mixed-frame-size directional Savage idle plus E/W movement `SpriteFrames` builder
- `custodian/tools/validation/savage_runtime_smoke.gd` — focused Savage idle/movement frames, nearest fallback, presentation priority, actor, factory, wave, and main-scene wiring smoke
- `custodian/content/sprites/environment/props/vault_storage/runtime/` — permanent runtime home for vault construction/resource-storage prop state sprites consumed by `VaultStorage`
- `custodian/tools/pipelines/update_vehicle_runtime_resources.gd` — rebuilds hover buggy vehicle `SpriteFrames` from canonical runtime sheets with current hover buggy source/runtime fallbacks
- `custodian/tools/validation/enemy_behavior_vault_smoke.gd` — targeted smoke check for vault storage resource removal/recovery/damage, behavior profile defaults, and stolen-resource loot carrier drop behavior
- `custodian/tools/validation/content_asset_audit.py` — read-only content-root audit for loose files, unregistered quarantine files, and exact duplicate groups
- `custodian/tools/art/build_reference_samplesheet.py` — Pillow-based utility that samples active runtime-facing tiles, walls, floors, ruin props, and environment prop sheets into a labeled design-reference PNG
- `custodian/content/README.md` — stable content-root domain map and duplicate policy for runtime/source/legacy/quarantine asset placement
- `custodian/content/levels/hub/Road_of_Witnesses_Tilemap.png` — level-owned source map image for the Road of Witnesses prototype scene
- `custodian/content/levels/hub/twin_solaria/development/twin_solaria_rebuilt_upscaled.png` — project-local development copy of the largest current Twin Solaria composite used by the dedicated backdrop test scene
- `custodian/content/props/gothic/vault_dressing/source/unregistered/` — vault-owned source quarantine for unregistered vault prop art pending manifest/runtime promotion
- `custodian/content/tiles/source/ashen_forum/`, `custodian/content/tiles/source/compound_ashen/`, `custodian/content/tiles/source/gothic_compound/`, and `custodian/content/tiles/source/roads_paths/` — source/master tile-sheet homes for previously loose top-level tile art
- `custodian/content/reference/active_art_samplesheet.png` — generated design-reference sheet containing deterministic samples from active art directories; regenerate with `python3 custodian/tools/art/build_reference_samplesheet.py`
- `tools/tiles/extract_wall_parts.py` — offline wall module extractor that reads canonical wall source art, writes per-part PNGs, a packed source atlas, and JSON metadata
- `tools/tiles/compose_wall_variants.py` — offline deterministic wall-run composer that reads generated wall part metadata/atlas and writes composed wall variant sheets
- `tools/tiles/build_procgen_wall_atlas.py` — bridge builder that slices extracted wall modules into fixed `32x32` procgen TileMap cells and semantic coordinate buckets
- `custodian/tools/tiles/register_interior_floor_tiles.py` — convention-based registrar for `content/tiles/interiors/runtime/floor_*_32.png`, non-corner `wall_*_32.png`, and `wall_*corner*_32.png` TileSet sources plus procgen source arrays
- `tools/tiles/procgen_wall_semantics.json` — optional curated role override file for generated wall module semantics
- `custodian/content/tiles/walls/source/procgen_wall_modules_source.png` — canonical reviewed source sheet for generated procgen wall modules
- `custodian/content/tiles/walls/source/wall_passages/` — optional `32px`-tall wall passage strips sliced directly into procgen passage/hole buckets
- `custodian/content/tiles/walls/Wall_Tops.png` — wall-top source sheet that is alpha-split by the atlas builder with `--top-source`
- `custodian/content/tiles/tilesets/procgen_world_tileset.tres` — canonical active world/procgen TileSet used by procgen and test-map TileMapLayer scenes; source IDs `32..59` register industrial elevation and mountain-cliff runtime PNGs, while terrain gameplay packs are currently registered as atlas sources `60..77` connector, `80..99` ascent, and `100..123` chasm_bridge. These are not yet Godot TileSet terrain/autotile terrain sets.
- `custodian/content/tiles/roads_paths/README.md` — local road/path asset layout, regeneration commands, and runtime/source split
- `custodian/content/tiles/roads_paths/source/Pathways.json` — road/path role metadata used by the game32 normalizer and procgen surface mapping
- `custodian/content/tiles/roads_paths/source/road_piece_exports/road_piece_manifest.json` — raw procgen road-piece metadata; maps variable-size stamp PNGs by connection bitmask before game-grid normalization
- `custodian/content/tiles/roads_paths/runtime/placeholders/roads/PLACEHOLDER_road_piece_manifest.game32.json` — active temporary road stamp manifest used for main-map road and parking-zone overlays while production road art is reviewed; includes the 32x32 lane-role contract `center`, `left_1`, `left_2`, `right_1`, and `right_2`
- `custodian/content/tiles/roads_paths/runtime/placeholders/paths/PLACEHOLDER_path_piece_manifest.game32.json` — active temporary footpath/degraded-transition stamp manifest used for `soft_path` overlays while production path art is reviewed
- `custodian/content/tiles/roads_paths/runtime/placeholders/` — current active road/path placeholder decal pack; all runtime images are intentionally named `PLACEHOLDER_*`
- `custodian/content/tiles/roads_paths/runtime/roads/standard/manifest.json`, `custodian/content/tiles/roads_paths/runtime/roads/gothic/manifest.json`, and `custodian/content/tiles/roads_paths/runtime/paths/path_piece_manifest.game32.json` — generated/candidate production road and path packs retained for replacement review, not active procgen defaults
- `custodian/content/tiles/roads_paths/tools/normalize_road_pieces_game32.py` — pads raw road/path stamps to 32px game-grid canvases and emits separate road/path runtime manifests
- `custodian/content/tiles/roads_paths/source/ancient_ruined_roads_and_paths.png` — source road/path sheet preserved as the visual source/reference for the runtime exports
- `custodian/content/sundered_keep_manifest.game32.json` — master game32 manifest for the Sundered Keep asset set; indexes terrain, traversal, props, floors, gothic walls, great hall walls, ramparts, and the registered temporary placeholder readability kit
- `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json` — unified-mapper-owned data source for the active `112x80` Sundered Keep; the production PNG is visual base authority, `mapper_placements` is the sole editable visual overlay, and retained ops/interactables/markers/elevation/occlusion/stateful blockers/inline siege remain functional authority
- `custodian/content/levels/sundered_keep/sundered_keep_overlay_authoring.json` — generated deterministic authoring-guide JSON derived from the Sundered Keep master overlay alpha; records suggested floor footprint, border void, enclosed void, and centroid anchors in tile space
- `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.before_cheatsheet_relayout.json` — exact preservation copy of the working V1 front-gate JSON taken before the cheat-sheet migration
- `custodian/tools/levels/generate_sundered_keep_overlay_authoring.py` — deterministic authoring-guide generator that samples the Sundered Keep master overlay into the live tile grid and emits suggested footprint/void JSON for review
- `custodian/content/ui/black_reliquary/` — current gothic/brass HUD asset kit: panels, icons, markers, minimap frame/fill, prompt plaques, and dividers.
- `custodian/content/levels/sundered_keep/sundered_keep_assets.json` — level-pack asset reference index for Sundered Keep tile/proxy asset IDs
- `custodian/content/runtime/sundered_keep/sundered_keep_game32_assets.gd` — generated Sundered Keep runtime catalog used by `sundered_keep_map.gd` for terrain, traversal, and prop texture paths
- `custodian/content/runtime/sundered_keep/` and `custodian/content/tiles/sundered_keep/` — runtime Sundered Keep game32 asset pack for terrain, traversal, props, floors, gothic walls, great hall walls, ramparts, Return Mooring tile overlays, and the live cosmic-ocean remap used for the keep's ocean/backdrop layer
- `custodian/content/tiles/sundered_keep/entrance/` — entrance/causeway runtime tiles, including walkable causeway floors, blocked broken-gap continuation, and entrance/gatehouse overlays
- `custodian/content/tiles/sundered_keep/entrance/causeway_floors/` — available curated cobblestone causeway floor and stair-detail palette assets; no longer auto-painted by production legacy ops
- `custodian/content/tiles/sundered_keep/entrance/causeway_surfaces/` — available `32x32` directional causeway surface/edge palette assets; no longer auto-painted by production legacy ops
- `custodian/content/tiles/sundered_keep/entrance/causeway_walls/` — available causeway wall/parapet/tall-face visual dressing for deliberate mapper placement; canonical collision remains in the underlay collision document
- `custodian/content/tiles/sundered_keep/placeholders/walls/` — registered temporary `PLACEHOLDER_sundered_keep_labyrinth_*` assets retained in the palette/catalog but no longer automatically placed over the production underlay
- `custodian/content/tiles/sundered_keep/entrance/cliffs/` — entrance-local cliff/support dressing used visually by the authored Sundered Keep front-gate layout
- `custodian/content/tiles/sundered_keep/entrance/overlays/` — entrance-local wall overlay dressing such as banners and shields used visually by the authored Sundered Keep front-gate layout
- `custodian/content/tiles/sundered_keep/entrance/props/` — entrance-local visual prop dressing resolved through explicit Sundered Keep level-data categories, including `causeway_lit_brazier_flicker_01.png` consumed as a 9-frame brazier `AnimatedSprite2D` strip; gameplay collision/interactability and animation frame metadata still require manifests
- `custodian/content/tiles/sundered_keep/entrance/prefabs/` — entrance-local large prefab structures and animation strips, including `gateway_prefab_structure.png`, `gateway_prefab_spritesheet_open_gate.png`, and `open_great_doors_prefab_sheet.png` used by `sundered_keep_map.gd` for the stateful Main Gate and Great Hall doorway while interaction/collision remains authored in script and level blockers
- `custodian/content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_01__e__8f__156.png` and `custodian/content/sprites/enemies/enemy_marine/runtime/fx/enemy_marine__fx__unarmed__dash_attack_01__e__8f__156.png` — runtime marine east dash attack body/FX fallback strips used by the Great Hall hallway ambush and shared heavy marine dash playback while directional body/FX variants remain required assets
- `custodian/content/props/sundered_keep/causeway/` — stable runtime home for curated Sundered Keep causeway dressing props promoted from `causeway_curated/props/` and resolved by the authored Sundered Keep map prop path list
- `custodian/content/backgrounds/sundered_keep/grand_vista/` — generated grand-vista presentation assets for the production approach `GrandVistaRoot`; panorama/fog/vignette, alpha-bearing parapet/ocean-spray overlays, and saved glue overlays for horizon seams/path contact/foreground edge/edge spray are fitted by rect and never own collision; underlay correction patch candidates are optional future polish, not required runtime assets
- `custodian/content/backgrounds/sundered_keep/world_vista/sundered_keep_world_vista_cliff_lip.png` — dedicated 2048×512 alpha-bearing world-Vista separator with heavier ruined masses at both corners and a broken center opening; presentation-only, linear-filtered, and never collision authority
- `custodian/content/backgrounds/sundered_keep/approach/parallax/` — painterly Sundered Keep depth plates shared by Vista Approach and Return Causeway; ocean and near mist are runtime-composed left/right pairs rather than stitched outputs
- `custodian/game/world/sundered_keep/presentation/sundered_keep_parallax_rig.gd` — shared presentation-only `Parallax2D` stack with Vista/Return profiles, exported per-layer review gates defaulting unsafe supplementary plates off, compatibility-preserving distant Keep paths, conservative inactive tuning, explicit linear filtering, and bounded split-mist `scroll_offset` drift
- `custodian/tools/validation/sundered_keep_parallax_depth_smoke.gd` — cross-level contract smoke proving review-blocked plates are not constructed, compatibility roots remain present, Return Causeway keeps its distant landmark, and `ParallaxRoot` contains no collision/navigation authority
- `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_PARALLAX_DEPTH.md` — compact implementation record and intake blocker for the shared painterly depth stack
- `custodian/content/tiles/sundered_keep/return_mooring/` — Return Mooring runtime floor ring/corner/center tiles plus glow, active, and prompt overlays
- `custodian/content/props/sundered_keep/return_mooring/` — Return Mooring beacon and ruined console prop PNGs plus game32 sidecars
- `custodian/content/runtime/sundered_keep/return_mooring/return_mooring_module.game32.json` and `custodian/content/metadata/game32/return_mooring.game32.json` — Return Mooring module and metadata manifests referenced by the Sundered Keep asset set
- `custodian/tools/validation/sundered_keep_asset_smoke.gd` — validates Sundered Keep map Sprite2D textures resolve to live assets and that the authored level-shape underlay sprite is present
- `custodian/tools/validation/sundered_keep_approach_asset_audit.py` — validates Sundered Keep route-master approach PNG dimensions, required alpha on route/overlay assets, fog-strip folder placement, and retained grand-vista overlay alpha contracts
- `custodian/tools/validation/sundered_keep_overlay_authoring_smoke.gd` — validates the generated overlay-authoring JSON and review scene load cleanly and stay linked from the live Sundered Keep map
- `custodian/tools/validation/codex_task_fixes_smoke.gd` — focused scrap pickup cue, louder low-health warning, guaranteed heavy stagger, and critical-hit camera-shake coverage
- `custodian/tools/validation/black_reliquary_ui_smoke.gd` — validates required Black Reliquary UI assets plus reusable HUD/component scene loading, including the shared live minimap panel scene.
- `custodian/tools/validation/black_reliquary_live_minimap_smoke.gd` — validates the compact Black Reliquary minimap frame mounts the shared live minimap scene and receives player/enemy/objective data.
- `custodian/tools/validation/sundered_keep_hud_scope_smoke.gd` — validates Sundered Keep HUD is hidden on the main map, shown inside the keep, hidden after return, and not re-shown by terminal-style overlay restoration.
- `custodian/tools/validation/sundered_keep_sidearm_unlock_smoke.gd` — validates the Sundered Keep P-9 locker begins available, grants the sidearm once, preserves melee selection, and persists its opened/non-interactable state.
- `custodian/tools/validation/sundered_keep_vanguard_seal_acquisition_smoke.gd` — validates the Gatehouse Core East Command Cache authored placement, siege lock/activation sequence, one-time and equipped-item-safe Vanguard Seal recovery, route persistence, nearby traversal, and independent Great Hall P-9 locker availability.
- `custodian/tools/validation/debug_screen_smoke.gd` — validates the dedicated debug screen scene load, API, visibility toggle, and snapshot update path.
- `custodian/tools/validation/terminal_overlay_visibility_smoke.gd` — validates that opening the terminal hides gameplay overlay HUD scenes and masks the debug screen, then restores them on close.
- `custodian/tools/validation/sundered_keep_layout_smoke.gd` — validates the Sundered Keep Return Mooring, key, portcullis, Great Hall door, blockers, and texture basics
- `custodian/tools/validation/sundered_keep_large_layout_smoke.gd` — validates the large JSON functional layout, production underlay, absence of retired static visual placements, retained Return Mooring/module presentation, elevation transitions, underpass/roof regions, stateful gate and Great Hall presentation/blockers, marine ambush, minimap conversion, siege activation/objectives/repair/turret, and missing asset count
- `custodian/tools/validation/custodian_home_begin_smoke.gd` — validates the Home beginning scene, Field Terminal interactable API, Road of Witnesses map, and Black Reliquary HUD scene load.
- `custodian/tools/validation/operator_authored_melee_fx_smoke.gd` — validates
  authored Operator melee FX suppress the legacy procedural gold swing while
  attacks without authored FX retain it as a fallback.
- `custodian/tools/validation/procgen_road_surface_roles_smoke.gd` — validates connected procgen road/parking generation, exact filled-surface role classification, one 32×32 base decal per road tile, manifest coverage, separate path rendering, streaming reconstruction, and no wall/impassable authority on roads; `procgen_placeholder_roads_smoke.gd` remains a compatibility entrypoint.
- `custodian/content/tiles/roads_paths/runtime/roads/surface/road_surface_piece_manifest.game32.json` — active 15-piece road base-decal contract for center, cardinal edge, outer-corner, and inner-corner surface roles.
- `custodian/tools/validation/procgen_playability_smoke.gd` — focused unit smoke for route distance bands, pocket clearance, and blocker-aware audit failure/success
- `custodian/tools/validation/procgen_route_clearance_smoke.gd` — production-map smoke proving primary-route road presentation, hard-clearance foliage rejection, required reachability, and seven-tile post-decoration minimum width
- `custodian/content/tiles/interiors/runtime/` — runtime-ready `32x32` constructed-interior floor and military wall tiles registered into procgen source lists by naming convention
- `custodian/content/tiles/interiors/source/` — oversized/reference interior tile source art preserved for slicing or replacement
- `custodian/content/tiles/interiors/README.md` — interior tile folder layout, runtime/source split, and remaining art needs
- `custodian/assets/tiles/walls/generated/procgen_wall_source_parts.json` — stable intermediate metadata for extracted procgen wall source modules
- `custodian/assets/tiles/walls/generated/procgen_wall_source_atlas.png` — stable intermediate packed atlas for extracted procgen wall source modules
- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.png` — generated fixed-grid wall atlas used by procgen TileSet source ID `12`
- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.mapping.json` — generated semantic bucket mapping used to populate procgen wall coordinate arrays
- `custodian/assets/tiles/walls/generated/README.md` — regeneration and Godot import notes for generated wall tile assets
- `design/02_features/procgen/WALL_TILE_PIPELINE.md` — implementation spec for the offline wall tile extraction and composition pipeline
- `design/02_features/procgen/PROCGEN_WALL_TILE_BRIDGE.md` — implementation spec for integrating generated wall tiles into the procgen TileMap runtime
- `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md` — first runtime slice for single-map indoor/outdoor region-aware procgen
- `custodian/content/sprites/_pipeline/README.md` — intake contract, canonical sprite naming, and manifest examples
- `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md` — short operator-facing pipeline guide for checking needed assets, validating drops, ingesting/building into runtime, and proving outputs
- `custodian/tools/validation/operator_modular_pipeline_smoke.py` — focused Python smoke for modular Operator inbox routing, weapon-specific Vigil/cleaver layers, canonical full-canvas melee outputs, compatibility naming, post-process selection, and stable generic modules
- `custodian/tools/validation/non_operator_actor_pipeline_smoke.py` — focused Python smoke proving domain-owned enemy routing without loose-root outputs, owner-first allied compatibility routing, recursive action-group discovery, and canonical precedence during SpriteFrames rebuilds
- `custodian/tools/validation/operator_animation_contract_report_smoke.py` — pure-Python smoke for the Operator animation contract report and strict-mode success on synthetic strips
- `custodian/tools/validation/operator_action_preview_smoke.py` — pure-Python smoke for generalized Operator action preview compositing on synthetic lower/upper/FX strips
- `custodian/tools/validation/scaffold_character_contract_smoke.py` — pure-Python smoke for new-character scaffold output creation and expected filename content
- `custodian/tools/validation/sprite_superseded_cleanup_smoke.py` — end-to-end dry-run/apply smoke for opt-in canonical replacement cleanup and `.import` sidecar removal
- `custodian/content/sprites/_pipeline/aseprite/` — raw aseprite PNG staging folder before normalization into inbox
- `custodian/content/sprites/props/harvesting_nodes/blackwood_deadfall/` — runtime 96px idle/depleted harvesting-node sheets for blackwood nodes
- `custodian/content/sprites/props/harvesting_nodes/exposed_alloy_vein/` — runtime 96px idle/depleted harvesting-node sheets for structural alloy nodes
- `custodian/content/sprites/props/harvesting_nodes/collapsed_machine_shell/` — runtime 96px idle/depleted harvesting-node sheets for ruin-scrap wreckage nodes
- `custodian/content/sprites/props/harvesting_nodes/fungal_resin_pod/` — runtime 96px idle/depleted harvesting-node sheets for resin/fiber nodes
- `custodian/content/sprites/props/harvesting_nodes/broken_signal_relay/` — runtime 96px idle/depleted harvesting-node sheets for `broken_signal_relay`
- `custodian/content/sprites/props/harvesting_nodes/ruptured_capacitor_bank/` — runtime 96px idle/depleted harvesting-node sheets for `ruptured_capacitor_bank`
- `custodian/content/sprites/props/harvesting_nodes/shattered_archive_terminal/` — runtime 96px idle/depleted harvesting-node sheets for `shattered_archive_terminal`
- `custodian/docs/ASSET_LAYOUT_CONVENTION.md` — project-wide runtime asset layout and canonical sprite filename convention
- `custodian/content/sprites/environment/props/portal_ring/runtime/fx/` — canonical portal-ring prop FX runtime strips used by `PortalTeleporter` for idle, activation, and arrival playback
- `custodian/content/sprites/effects/runtime/portal_ring/` — legacy compatibility copies of portal-ring teleport FX strips
- `custodian/content/items/shrumb_drops/shrumb_drops.json` — v1 cognitive item definitions for Faint Recollection, Residual Instinct, and Ancient Bearing
- `custodian/content/dialogue/ash_bell/forlorn_ritualant_dialogue.json` — Ash-Bell Forlorn-Ritualant dialogue data using Ninth Bell, Dry Fountain, white thread, black banners, and Unarrived Saint motifs without explicit alternate-continuity language
- `custodian/content/items/lore/ash_bell_items.json` — lore item definitions for Bell-Clapper Without a Bell, White Thread Knot, and Prayer to the Unarrived Saint
- `custodian/content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json` — retired and intentionally absent; the Forlorn-Ritualant now loads through the fixed authored Underground route, and focused smokes fail if this procgen definition returns
- `custodian/content/sprites/items/faint_recollection.png` — animated 4-frame pickup sheet for Faint Recollection
- `custodian/content/sprites/items/faded_instinct.png` — animated 4-frame pickup sheet currently used for `residual_instinct`
- `custodian/content/sprites/items/ancient_bearing.png` — animated 4-frame pickup sheet for Ancient Bearing
- `custodian/content/ui/terminal/README.md` — intended terminal PNG asset paths for frames, overlays, icons, pips, and button skins

## Active Prop Content

- `custodian/content/props/ruins/scenes/ProceduralProp.tscn` — reusable Node2D assembly scene for deterministic visual ruin prop variants
- `custodian/content/props/ruins/scripts/ProceduralProp.gd` — seeded visual variant generation, intensity modes, editor regeneration, palette material application, overlay/rubble placement, root-local/global collision alignment reports, per-instance collision-debug override, optional inline collision footprints, occlusion bounds, and player-relative depth sorting
- `custodian/content/props/ruins/scripts/PropDefinition.gd` — per-prop resource schema for base texture, bottom-contact anchor, palette bounds, overlay/rubble inputs, spawn regions, root-local collision scene/footprint fields, explicit below-anchor exception, optional occlusion bounds, and optional depth-sort settings
- `custodian/content/props/ruins/scripts/PropVariantLayer.gd` — structured overlay/rubble layer resource with type, spawn chance, spawn rect, alpha range, z-index, and flip rules
- `custodian/content/props/ruins/scripts/PropVariantGenerator.gd` — deterministic helper for deriving seeds from world cells or positions
- `custodian/content/props/ruins/scripts/WeightedPropEntry.gd` — weighted prop spawn entry resource
- `custodian/content/props/ruins/scripts/PropSpawnSet.gd` — weighted set of prop definitions used by scatterers/procgen
- `custodian/content/props/ruins/scripts/PropScatterer.gd` — reusable tile-based deterministic prop scatterer with seeded candidate shuffling, definition-aware pre-instantiation validation, and source-tile recording for downstream systems such as portal pairing
- `custodian/content/props/ruins/shaders/prop_palette_variation.gdshader` — conservative HSV brightness/saturation/hue adjustment shader for prop sprites
- `custodian/content/props/ruins/data/ruin_prop_spawn_set.tres` — default weighted procgen spawn set for ruin props
- `custodian/tools/validation/prop_collision_alignment_smoke.gd` — audits every ruin `PropDefinition` for bottom-contact alignment, visual-bound containment, suspicious positive offsets, global/local report agreement, and forced collision-debug rendering
- `custodian/content/props/ruins/data/prop_definitions/obelisk.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres` — starter test definition using available moss/crack overlays and rubble, including the raised platform impostor tuning, visual-frame `(80,60)` platform horizon/trigger anchor, mirrored north-side approach flag, and static-base hiding flag used by the animated portal state sprite
- `custodian/content/props/ruins/scenes/portal_ring_collision.tscn` — authored side-block collision scene used by `portal_ring_01`
- `custodian/content/props/ruins/data/prop_definitions/rotunda_01.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/data/prop_definitions/slab_01.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/README.md` — ruin prop folder layout, padding commands for cropped PNGs, import settings, and pixel-art transform constraints
- `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md` — active implementation spec and runtime ownership note for the ruin prop variant system
- `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md` — implemented-v1 authority for harvesting, resource ledger, fabrication work orders, Ready Builds, and the current token-gated Basic Turret/Light Barricade placement bridge
- `design/02_features/infrastructure/COMPOUND_INFRASTRUCTURE_SYSTEM.md` — active authority for the bounded construction economy; Powered Fabricator Milestone 1 is live with component grid registration, hybrid Capacitor Bank construction, typed fabrication service output, and a versioned persistence boundary
- `design/02_features/infrastructure/INFRASTRUCTURE_IMPLEMENTATION_PLAN.md` — implemented Milestone 1 compatibility decisions, transaction order, runtime file list, and validation record
- `custodian/autoload/infrastructure_registry.gd` — structure/service registry, terminal snapshot authority, and versioned capture/restore boundary
- `custodian/game/infrastructure/` — reusable structure definition/base, power and service components, and Field Fabricator/Capacitor Bank scenes
- `custodian/content/infrastructure/definitions/` — definition resources for the first Field Fabricator and Capacitor Bank structures
- `custodian/tools/validation/{power_grid_component_registration,construction_placement_contract,powered_fabricator_slice,infrastructure_save_restore}_smoke.gd` — focused Milestone 1 registration, transaction, full-loop, and persistence validation
- `design/02_features/power/POWER_SYSTEMS_GODOT.md` — current sector-oriented power implementation summary and compatibility boundary for future infrastructure-grid work
- `design/04_architecture/SIMPLIFIED_POWER_IN_ROOMS.md` — superseded room-marker proposal retained as historical reference; its conduit-to-generator mapping must not be implemented
- `design/02_features/arrn/implementation.md` — ARRN implementation roadmap; runtime V1 is implemented with primitive relay visuals and deferred production polish

## Active Documentation

- `custodian/docs/ai_context/CURRENT_STATE.md` — current implementation state
- `custodian/docs/ai_context/CONTEXT.md` — project primer and working rules
- `custodian/docs/ai_context/FILE_INDEX.md` — this file
- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` — reusable task packet template
- `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` — recommended automation scripts and implementation order
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — validation command recipes and selection rules
- `custodian/docs/ai_context/prompts/` — reusable prompt templates for common agent tasks
- `custodian/docs/ai_context/task_packets/` — active and completed task-scoped agent packets
- `design/90_codex/` — non-authoritative idea inventory and graduation audit trail; `tools/validate_design_codex.py` validates index coverage, metadata, graduation/runtime links, and packaging residue
- `custodian/tools/validation/contract_resource_node_smoke.gd` — headless smoke test that loads `game.tscn`, verifies scarce generated tutorial resource nodes include blackwood/alloy/wreckage, verifies the far-field expedition patch covers every compatible resource-node kind, and checks generated/default node sprites build frames
- `custodian/tools/validation/sundered_keep_asset_smoke.gd` — headless smoke test that instantiates the Sundered Keep connected map and fails if any slice `Sprite2D` has a missing texture or if the authored level-shape underlay is missing
- `custodian/scenes/debug/sundered_keep_overlay_authoring_review.tscn` and `.gd` — standalone review scene that instances the live Sundered Keep map and draws generated overlay-authoring guidance over it for manual silhouette/layout comparison
- `custodian/tools/validation/sundered_keep_layout_smoke.gd` — headless smoke test for Return Mooring, Sundered Gate Key pickup, closed-gate blocker, blocked no-key gate interaction, Great Hall door blocker, and blocker removal after opening the Main Gate and Great Hall door
- `custodian/tools/validation/sundered_keep_large_layout_smoke.gd` — headless smoke for preserved functional metadata, underlay authority, retired-overlay absence, retained Return Mooring presentation, elevation/underpass/roof behavior, stateful gate/door contracts, marine ambush, minimap conversion, and siege behavior
- `custodian/tools/validation/sundered_keep_overlay_authoring_smoke.gd` — headless smoke test that opens the Sundered Keep overlay-authoring review scene, checks the generated mask schema/counts, and verifies the live map still points at the authoring-guide JSON
- `custodian/tools/validation/black_reliquary_live_minimap_smoke.gd` — headless smoke test for the compact Black Reliquary live minimap wrapper.
- `custodian/tools/validation/grunt_animation_smoke.gd` — targeted smoke check for loading the current `enemy_grunt` body/FX SpriteFrames, including crit/crit-recovery/crit-FX coverage, and selector mappings
- `custodian/tools/validation/debug_grunt_spawn_modes_smoke.gd` — focused validation for DevConsole grunt critical-open/execution-ready presets, one-health lethal setup, opportunity presentation, and unsupported-mode rejection
- `custodian/tools/validation/operator_primary_ranged_modular_fire_smoke.gd` — focused modular primary-ranged validation including stationary aim-owned lower-body direction and 120-tick upper-body/weapon normalized-frame synchronization
- `custodian/tools/validation/elevation_map_smoke.gd` — targeted smoke check for raised-platform elevation metadata, ramp traversal, blocked edges, and serialized cells
- `custodian/tools/validation/terrain_builder_smoke.gd` — targeted smoke check for TerrainBuilder determinism, connectivity, elevated access, Ascent Pack ramp visual selection, spawn-valid filtering, baseline visual no-op behavior, directional ramp validation, and registered elevation/cliff TileSet sources
- `custodian/tools/validation/terrain_ballistics_smoke.gd` — focused dictionary and TerrainBuilder integration smoke for deterministic tile tracing, hard walls, directional ledge fire, ramp/stair exceptions, drop/bridge rules, diagonal blockers, ballistic edge export, and preserved movement blocking
- `custodian/tools/validation/procgen_terrain_required_cells_smoke.gd` — candidate-mode procgen smoke check that verifies TerrainBuilder required-cell counts stay bounded, connectivity remains true, and terrain fallback is not used for representative seeds
- `custodian/tools/validation/procgen_contract_rescue_diagnostic_smoke.gd` — slow production-sized contract candidate diagnostic for `176x176`, `208x224`, and `224x224` maps; prints per-attempt required-cell source/reason, three pre-terrain walkability ratios, baseline/final terrain rescue, and aggregate acceptance/rescue counts, and validates the contract failure-safe emission path
- `custodian/tools/validation/procgen_foliage_spawner_smoke.gd` — focused headless smoke for the extracted foliage service's deterministic generate/remove/clear lifecycle and shared same-kind material ownership
- `custodian/tools/validation/procgen_deferred_foliage_smoke.gd` — final-visual procgen smoke check that disables streaming reveal, enables deferred foliage spawning, and verifies the deterministic foliage queue drains into placed foliage nodes
- `custodian/tools/validation/procgen_candidate_promotion_smoke.gd` — proves accepted candidate promotion does not invoke a second structural generation, alter accepted terrain/floor/wall fingerprints, or expose additional streamed tiles
- `custodian/tools/validation/lighting_playground.tscn` and `.gd` — standalone native 2D lighting playground with CanvasModulate, DirectionalLight2D, three light rigs, a lighting zone, an occluder wall, a placeholder player, and debug profile/flash controls
- `custodian/tools/validation/gatehouse_lighting_test.tscn` and `.gd` — localized-contrast reference room with a shaped window shaft, two broken-radial braziers, darker zone, pillar/gate occluders, prop contact shadows, animated dust, and bright objective
- `custodian/tools/validation/lighting_system_smoke.gd` — headless smoke for the Lighting System playground and gatehouse reference room, including profile switching, custom cookie/height/scale application, major occluders, animated dust, and transient flash pool
- `custodian/tools/validation/world_atmosphere_smoke.gd` — headless smoke for live `game.tscn` lighting/atmosphere/UI wiring, contract-profile shader propagation, combined foliage wind/occlusion uniforms, and representative terminal/power light rigs
- `custodian/game/vfx/combat/{posture_break_flash_vfx,critical_window_expire_vfx}.tscn` with matching scripts and `content/spriteframes/effects/combat/` resources — optional-gated, preloaded one-shot critical-open bookend effects using the supplied 128px strips
- `custodian/tools/validation/runtime_wall_collision_compaction_smoke.gd` — representative procgen smoke proving many per-tile wall shapes occupy materially fewer chunk bodies and exact-contact destruction preserves neighboring wall collision
- `design/02_features/lighting/CUSTODIAN_LIGHTING_SYSTEM.md` — active implementation note for native Godot 2D lighting direction, authored rigs, zones, and transient flashes
- `design/02_features/visuals/WORLD_ATMOSPHERE_SHADER_SYSTEM.md` — authoritative V1 contract for combined foliage life, restrained live-world atmosphere, planet-profile inputs, persistent local light selection, and validation boundaries
- `design/02_features/procgen/TERRAIN_BUILDER_ELEVATION_INTEGRATION.md` — implementation spec and completion notes for dedicated terrain builder elevation/cliff integration
- `custodian/AGENTS.md` — first-stop local operating guide for all work under `custodian/`
- `custodian/docs/ARCHITECTURE.md` — comprehensive runtime architecture reference: 9-layer model, layer boundaries, overburdened coordinator file list, determinism rules, current and target boot flow, migration status per layer
- `custodian/docs/SCENE_HIERARCHY.md` — scene organization reference
- `custodian/docs/ai_context/task_packets/ARCHITECTURE_ORGANIZATION_PASS.md` — architecture organization task packet: target organization, migration phases, extraction candidates, acceptance criteria, validation commands, rollback plan
- `custodian/docs/GDSCRIPT_STANDARDS.md` — scripting standards
- `custodian/docs/AGENT_MIGRATION_PLAYBOOK.md` — migration and docs-drift cleanup procedure
- `design/` — active Godot feature/system implementation specs
- `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md` — implemented V1 authority for typed/capped ammunition, projectile range/falloff, weapon heat and production feedback, positional noise, enemy perception/search/leash behavior, ambient hostile camps, and the deferred vehicle-weapon contract
- `custodian/game/systems/stealth/noise_event.gd` and `noise_event_bus.gd` — generic positional noise payload and autoload signal authority used by gunfire and future loud world actions
- `custodian/game/systems/spawning/ambient_enemy_camp.gd` and `ambient_enemy_spawner.gd` — activation-limited authored hostile camps and marker-driven generated-placement bridge
- `custodian/tools/validation/ranged_combat_balance_smoke.gd` — focused weapon data, heat/noise contract, projectile falloff, and noise-signal smoke coverage
- `custodian/tools/validation/combat_resource_feedback_smoke.gd` — focused status/progress, debounced transition, reload transfer, heat-band, recovery, per-weapon persistence, presentation-noise isolation, and read-only HUD smoke coverage
- `custodian/docs/ai_context/task_packets/COMBAT_RESOURCE_FEEDBACK.md` — compact implementation record for the completed Milestone A status/event, compact HUD, local audio/VFX, data-schema, and validation slice
- `custodian/docs/ai_context/task_packets/HIT_TAXONOMY_AND_RIPOSTE.md` — active task packet for Milestone C: hit taxonomy Phases 1-2 complete (metadata plumbing, differentiated enemy reactions, armor-deflect), remaining Phase 3-5 (Operator stagger, guard-break, riposte)
- `custodian/docs/ai_context/task_packets/PROCGEN_STUCK_POCKET_AUTHORITY.md` — completed implementation record for collision-owner blocker authority, escape remediation, navigation consumption, stuck diagnostics/rescue, and Observatory instrumentation.
- `custodian/docs/ai_context/task_packets/RUNTIME_STUTTER_PERFORMANCE_PASS.md` — implementation record for hidden Observatory gating, rebuild coalescing, spatial/shared foliage work, distance-tier workload control, target-scan throttles, compact wall bodies, and reduced atmosphere FBM.
- `custodian/tools/validation/field_patch_smoke.gd` — focused Field Patch health-restore validation for Operator commit timing, interruption, input binding, terminal restock, emergency-cache fallback, and restock cap helper
- `custodian/docs/ai_context/task_packets/RANGED_COMBAT_BALANCE_AND_STEALTH.md` — completed high-risk implementation record for the ranged balance, stealth/noise, perception, and ambient-camp slice
- `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` — in-progress cross-system authority that records completed combat-resource/readability slices by durable owner and queues manual feedback tuning, Field Patch production presentation, hit taxonomy/riposte, durability, traps, and drone logistics
- `design/02_features/combat_feel/OPERATOR_INTEGRITY_RECLAIM.md` — completed V1 authority for temporary recoverable integrity, confirmed hostile-damage recovery, packet timing/eligibility, health-bar presentation, observability, and tuning
- `custodian/docs/ai_context/task_packets/archived/COMBAT_RESOURCE_READABILITY_SPEC_NORMALIZATION.md` — completed migration record for retiring the root draft, routing completed V1 slices to permanent feature authorities, and establishing the current in-progress umbrella
- `design/03_world/GAME_PROTOCOLS_AND_WORLD_LORE.md` — canonical lore, faction, and game-protocol authority
- `design/03_world/lore/CRECHE_AND_LOCKER_LORE.md` — active lore for Custodian crèches and designation-keyed crèche lockers (P-9 sidearm assignment, continuity of assignment vs. personhood); SECTION 2 refinement takes precedence over SECTION 1 draft
- `design/03_world/PROCEDURAL_LORE_GENERATION.md` — procedural lore payload, inspect, machine-language, and faction mapping target
- `design/03_world/THE_DISPERSED_FLEETS.md` — historical lore reference: the first post-Severance military expeditions that vanished without trace; design-shaping material, not an implementation target
- `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md` — canonical Ash-Bell / Forlorn-Ritualant implementation spec (includes merged Toll Count appendix from deleted companion doc)
- `design/02_features/procgen/SPECIAL_ROOM_INSERTION.md` — live V1 design note for generated-map special-room definitions, deterministic placement, authored-footprint claiming, and validation
- `design/02_features/events/LAST_ROUTEKEEPER_EVENT.md` — design spec for The Last Routekeeper: rare, one-time residual-system event inside Sundered Keep
- `design/02_features/events/LAST_ROUTEKEEPER_EVENT_CODE.md` — drop-in GDScript, map patches, autoload config, and REQUIRED_ASSETS.md entries for The Last Routekeeper

## Legacy Reference Only

## Elevated Procgen Presentation

- `design/02_features/procgen/ELEVATED_WORLD_PRESENTATION.md` — upper-plane, cliff, void, forest-depth, streaming, and determinism authority.
- `custodian/game/world/procgen/presentation/procgen_depth_backdrop.gd` — global non-repeating forest depth stack derived from authoritative generated-floor bounds, with a retained localized chasm-region API.
- `custodian/content/tiles/procgen/elevated_world/source/` — reference-only concept montages; never runtime atlases.
- `custodian/content/tiles/procgen/elevated_world/archive/pre_elevated_world_v1/` — pre-pass runtime art archive; never runtime-loaded.
- `custodian/tools/validation/elevated_world_asset_contract_smoke.gd` — image, alpha, TileSet semantic-ID, scene, and no-collision contract.
- `custodian/tools/validation/elevated_world_seed_review.gd` — fixed-seed presentation geometry and route summary.

- `python-sim/game/` — legacy simulation
- `python-sim/custodian-terminal/` — legacy terminal UI
- `python-sim/ai/` — historical AI context pack, superseded by `custodian/docs/ai_context/`
- `python-sim/design/archive/` — historical design/archive material
</file>

<file path="custodian/docs/ai_context/CURRENT_STATE.md">
# CURRENT STATE — CUSTODIAN

Last updated: 2026-08-01

Documentation updates this session:
- Created `design/02_features/factions/FACTION_EXPRESSION_SYSTEM.md` — full implementation spec from Faction Continuity Audit findings, covering taxonomy lock, canonical IDs, gameplay boundaries, roster reduction, data model, migration order, and Sundered Keep vertical slice.
- Remediated terminology drift in 6 documents: fixed "Great Severance" → "the Severing", "The Unarrival" → "the Unnarrival", "Penitents of Static" → "Pale Bell Penitents", `penitent_of_static` → `pale_bell_penitent`, and obsolete directory paths (`03_content/` → `03_world/`, `00_canon/` → `03_world/lore/`).
- Reduced faction bible in GAME_PROTOCOLS_AND_WORLD_LORE.md to summary+links (canon now in `design/03_world/factions/`, implementation spec in `design/02_features/factions/FACTION_EXPRESSION_SYSTEM.md`, lore authority in `design/03_world/lore/CORE_LORE.md`).

## Runtime Status

- The live procgen `DepthBackdrop` uses three 1536×1024 runtime compositions from `content/backgrounds/procgen/endless_forest/`: far haze, canopy mass, and near-wall growth. The general-world compatibility path uses authoritative generated-floor cells to place one cover-scaled stack behind the complete world; opaque terrain hides it and gaps reveal it. The localized `configure_from_chasm_cells()` API remains available but is not live until procgen exports reliable complete abyss semantics. Linear filtering has no mipmaps, repeat is disabled, and canopy-dominant opacity is `0.30/0.90/0.48`. The former repeating 512×512 pair is no longer scene-wired. The 1536×1024 chasm contact-shadow composition is source-only under `endless_forest/source/` pending local 512×256 edge decals. Older `content/backgrounds/procgen_world/forest_underlay_*` files are stale/source-only, not live runtime authority.
- Contract startup now promotes the accepted procgen candidate in place instead of clearing and regenerating its structural output in `FINAL_VISUAL`. Promotion preserves generated floor/wall dictionaries, terrain, roads, regions, and streaming visibility, then performs only skipped floor-value decoration, final props/foliage work, playability audit, shadows/overlays, and navigation refresh. Fine-grained timings split terrain application/repair/refresh/capture and every second-road-pass operation, while promotion separately reports ruin and interior prop costs. Candidate mode still paints structural TileMaps and is not yet a semantics-only evaluator; streaming reveal defers foliage but not ruin/interior props. Navigation remains painted-TileMap authoritative and now exposes authoritative-floor, painted-floor, and AStar point counts for explicit reveal-lifecycle testing. Floor-value clustering remains inert when fewer than two variant sources are registered.
- Better Terrain and Dear ImGui have been removed from `addons/`, their editor-plugin/autoload registrations are gone, and the retired ImGui Director Console integration/smoke were deleted. Godot-native terrain generation remains authoritative; F12 `debug_hud`, `DebugBus`, `DebugSnapshotCollector`, and `DevObservatory` remain the supported diagnostics stack.
- World ingress return guards now survive both the brief empty-overlap window and synthetic `body_exited` signals caused by re-enabling Area2D monitoring after a disabled origin branch is restored. The guard follows the restored Operator's actual distance from the ingress, so returning from the Empty Bell remains on the procgen surface until the Operator physically leaves instead of immediately replaying descent.
- The shared authored collision/POI mapper now applies saved rails and markers to its live preview and mirrors marker positions into the target `.tscn` while retaining script constants as runtime authority. The Forlorn Ritualant mapper therefore visibly and persistently updates its authored Underground level. `home_custodian_begin_mapper.tscn` provides the same workflow for the Home beginning perimeter, Custodian wake spawn, and Field Terminal.
- The production Sundered Keep mapper now owns runtime `_input` directly and freezes its instantiated gameplay preview after visual construction, preventing the preview HUD/controllers from swallowing authoring clicks. Palette tiles and sampled underlay stamps render immediately on absolute mapper preview layers before JSON save/rebuild.

- Lootable Corpse Beacon is in implementation review. Enemy death now determines a structured reward payload exactly once without touching `ResourceLedger`, `VaultManager`, or `GameState`; the final death pose persists and `EnemyCorpseLoot` becomes the single proximity-collection boundary for typed loot, carried stolen resources, and legacy materials. Lootable corpses are exempt from cleanup, while collected/empty corpses use minimum/offscreen/hard lifetime cleanup. Reveal, persistent beacon/ring, collection collapse, corpse hue, and a focused smoke are wired. The persistent marker now splits the existing beacon strip into corpse-depth `GroundRing`/`BeamLower` presentation plus a small absolute-depth `BeamTip`, allowing the Operator to occlude the lower shaft without losing the readability indicator. The runtime sheets now resolve cleanly as reveal 8/768x96, beacon 9/432x160, collapse 8/768x160, and ring 6/576x96; collapse references the accurately named `8f` asset and the obsolete duplicate falsely named `6f` is retired. Scene-unload persistence is not supported. The requested 1536x1024 source sheets remain absent, so exact 8/6 production normalization remains an explicit art-intake blocker.

- First Strike and Initiative V1 is live. The first eligible direct
  Operator hit in an engagement adds 20% stagger/breach pressure with no
  health-damage bonus. The player-owned fixed-step engagement tracker resolves
  initiative once across joining/ambush hostiles and ends an engagement after
  four seconds without living hostile target/pursue/attack/investigate intent.
  The Vanguard Seal combat relic occupies one constrained `relic` slot and,
  after a successful claim, grants 8% direct damage plus 15% stagger damage for
  eight seconds or until direct hostile damage. Inventory saves now persist
  both sidearm and relic equipment while loading the legacy flat carried-item
  shape. The Seal is recovered manually from the Gatehouse Core, East Command
  Cache after the Sundered Keep gatehouse siege reaches `secured`; its opened
  state persists, equipped ownership blocks duplicate awards, and recovery
  never auto-equips it. The activation uses a restrained six-frame brass-white
  closure VFX; a HUD indicator remains conditional on playtest readability.
- CUSTODIAN Moment Forge is live as a developer-only deterministic
  micro-playtest workbench. Six curated JSON scenarios cover light/heavy combat,
  Marine deflect, parry, Field Patch, and the Sundered Keep first reveal.
  `custodian/tools/iteration/run_moment.py` supports list, ranked changed-file
  suggestions, authored runs, compatible baseline comparison/acceptance,
  repeatability fingerprints, and none/evidence/full capture; it invokes a fixed-tick
  Godot runner only through `--moment-forge` and adds no autoload or production
  simulation authority. Review artifacts stay under `reports/moment_forge/`
  and include telemetry, stable metrics/assertions, contact sheets, optional
  Movie Maker audio/video, advisory visual diffs, and a dependency-free HTML report.
  The original light-hit full capture passed the then-current root-position
  assertions while exposing a legacy/full-body visual-anchor jump. The
  contaminated Operator sprite transforms are now normalized to `(0, -18)`,
  a direct-scene transition smoke protects every visual layer, and light/heavy
  scenarios fail when any visible layer exceeds `0.5 px` anchor delta. The
  `visual-anchor-fix-final` full rerun measured `0.0 px` at every
  authored contact-sheet tick, including legacy-body ticks 34 and 40. Marine
  deflect, deterministic enemy parry initiation, and the production-sized
  first-vista traversal still require narrow public fixture calibration before
  their presentation claims become stable event assertions. This
  is curated scenario capture, not the broader arbitrary Developer Replay
  System.
- The Ash-Bell Forlorn-Ritualant remains a partial encounter foundation, not a
  finished encounter. Its current authority-reservation packet is complete only
  for the procgen footprint claim slice. Live presentation uses south-facing
  128×128 `AnimatedSprite2D` sheets for idle/rise/pin/thread actions, but
  directional locomotion, robust action-state timing, the full attack and
  resolution set, authored silence/audio, persistent rewards, and production
  death/dissolve presentation remain open. `REQUIRED_ASSETS.md` now records
  those live partial contracts instead of the stale 48×64 ColorRect claim.
- The authored First Vista moonlight sweep asset is production-ready at
  `content/backgrounds/sundered_keep/approach/light/first_vista_moonlight_sweep_01__6f__1024x512.png`
  with a six-frame, 15 FPS editable source at
  `content/_aseprite/backgrounds/sundered_keep/approach/light/first_vista_moonlight_sweep_01.aseprite`.
  It uses the exact live Keep silhouette as its
  alpha/edge authority, peaks as a restrained cold additive exposure lift,
  and settles nearly transparent. Runtime controller wiring remains the next
  vista slice.
- Sundered Keep painterly backgrounds now use a role-based layout documented by
  `content/backgrounds/sundered_keep/README.md`: shared underlays, horizons,
  and landmarks; Approach underlay, fog, light, occlusion, parallax, playable,
  and legacy plates; Grand Vista atmosphere, components, landmarks, and
  underlay; plus World Vista and Causeway Approach. Live texture UIDs and all
  runtime/tool/design references moved with the files; background art remains
  presentation-only.
- Operator melee hit audio now resolves at each confirmed contact position from
  a target-owned presentation profile without changing damage authority.
  Armed fast-chain starts now also emit one positional air-movement cue per
  link from the supplied Fast 01/02/03 renders; misses retain the swing while
  confirmed hits layer the target-specific contact sound. Unarmed attacks do
  not consume the blade-swing set.
  Ordinary humanoids distinguish authored light/medium body impacts, drones
  and Marines use robot/metal, Savage uses scorched, the Great Hall Marine uses
  the hallway-reverb render, and Shrumbs round-robin their two authored takes.
  No runtime pitch randomization is applied while these families have fewer
  than three authored variants. Return Causeway now plays an ordered looping
  playlist: the two-minute `return_causeway_01.ogg`, followed by the
  169.4-second `hall_still_answers.ogg` runtime encode of
  `hall_still_answers_01.wav`. The level delegates to the shared MusicManager
  when available so local and global players do not double the music.
- Humanoid enemies now have an opt-in rigid cutout presentation backend. `HumanoidCutoutRig2D` slices static, absolute-positioned 96×96 parts from fixed 480×384 directional atlases and animates only Node2D pivots; replaceable skin/profile resources own atlas selection, pivots, per-direction offsets, and explicit z order. S/N/E are required and W may mirror east only when no authored W is assigned. Generic idle/run/light-attack/hit/death states, an isolated review scene, Aseprite source/export scripts, dry-run scaffold command, geometric dev-only validation skin, and a focused 27-contract smoke are present. `Enemy.visual_backend` remains `AUTHORED_FRAMES` by default, so grunt, savage, marine, wolf, and ambient presentation is unchanged; Falcon Punch, critical execution, and other bespoke special strips remain authored-frame-only.
- Vigil-Pattern Dagger remains the Operator scene default, and Sword-Cleaver is an explicit optional loadout override. The Operator modular pipeline mirrors authored E layers to W and emits full 156×96 body/weapon/FX runtime strips. Vigil Fast 02 now uses its dedicated synchronized eight-frame Chain 02 lower-body, upper-body, dagger, and upper-FX art at 18 FPS; Fast 01 and provisional Fast 03 retain the shared 10-frame Chain 01 presentation. Each semantic link keeps independent profiles, stamina, and `7/9/11` px drive. Contact remains zero-based frame 5 and commit frame 6. Cleaver remains on its existing provisional shared chain presentation. The generic definition/runtime owns body, weapon-overlay, FX, and per-link profiles without dagger branches in `operator.gd`.
- Fallen Star Katana remains a separate later equippable definition with its authored-frame-controlled three-step chain: distinct primary presses advance `Fast 01 -> Fast 02 -> Fast 03 -> Fast 01`, one queued command slot uses first-valid-input wins, and visible commit indices `5/5/6` grant fast/heavy transitions only after each link's single light-damage contact. A post-contact dodge waits for the final stance frame; whiffs remain chainable. The verified `3432x96` master is split into non-looping `7/7/8` body/weapon runtime strips at 18 FPS. Attack VFX is not baked: directional E/W `10/7/8` `modular_upper_fx` pipeline outputs are dynamically registered and synchronized through the Katana definition. Stamina costs remain `7/8/10`; Katana-specific attack drive is deferred and its profiles retain zero displacement.
- Operator Integrity Reclaim V1 is live. Eligible unblocked nonfatal damage converts 55% into independently expiring packets capped at 30% max health; light/heavy windows are 2.1/3.0 seconds with a 0.6-second full-value hold, another hit forfeits 25% of the existing pool before adding its packet, and fixed-step decay never refreshes older damage. Confirmed direct melee/unarmed, critical, and player-projectile damage restores at 45%, 55%, and 20% efficiency using the target health actually removed. Passive enemies, allied/turret sources, structures, damage over time, deflection/invulnerability, dead targets, guard chip, and overkill are rejected. Field Patch healing only clamps the pool, fatal damage clears it, Observatory exposes reclaim events/gauges, and the Black Reliquary health bar uses a cyan trailing segment plus meaningful `RECLAIM +N` feedback.
- DevMode now provides three release-safe playtest toggles: F6 enables a free inspection camera with arrow/Shift panning, middle-mouse drag, wheel zoom, and temporary suspension of follow/framing/bounds; F7 ignores Operator damage; F8 prevents stamina spending and clears sprint exhaustion. All controls default off, require debug-UI eligibility, display their active state in a small overlay, and restore ordinary camera/resource authority when disabled.
- Procgen Playability Pass V1 now turns `AscentFieldBuilder`'s primary route footprint and new deterministic centerline into downstream clearance authority before terrain and dressing. `RoutePlayabilityField` exports hard (`0–2`), shoulder (`3–5`), sparse (`6–9`), and deep (`10+`) bands, classifies reserved arrival/exit/safe/combat/resource/vista/story roles, protects larger critical pads and 70%-clear combat interiors, and performs constrained tendril/hole cleanup without removing route or reserved cells. Existing road/path presentation visibly stamps the route while preserving authored-role and ramp/stair visuals. Foliage density follows the bands, all foliage and ruin props reject hard-clearance cells, large trees remain five tiles from the centerline and four tiles apart, and ascent encounter spawn candidates come from combat-pocket edges rather than legacy cave corridors. A final wall/prop-blocker audit verifies required reachability and a seven-tile minimum route width and is exported in level data; it remains validation-only and cannot influence simulation.
- Operator dodge input now uses bounded tap/hold profiles: release below `0.12s` preserves the fixed 480-speed, 0.20-second tap dodge and its existing roll-exit attack cancel; `0.12s` selects a 1.30× long roll with 1.25× recovery and 20 stamina cost; `0.30s` selects a 1.55× committed roll with 1.60× recovery and 26 stamina cost. All profiles retain the same 0.16-second iframe ceiling. Charge has no invulnerability, cancels on incoming hits/runtime locks, and now holds a dedicated five-frame directional windup by charge ratio. Deterministic Dodge Flow connects released openers to uncapped stamina-limited tap chains: inputs buffer from `0.10–0.20s` or within `0.06s` late recovery, direction retains `100/75/40/0%` Flow across the four turn bands, maximum Flow grants `+12%` peak chain speed, `+18%` integrated travel, and `-35%` recovery without changing active/iframe clocks, and the final link blends explicit exit carry into run/sprint before Flow decays. Clean turns through 90 degrees use the dedicated four-frame link strip over the fixed 0.20-second clock; turns over 90 degrees retain the nine-frame full-dodge pivot, and final settle retains existing exit art. E/S/W charge and link body coverage uses deterministic nearest-sector presentation fallback without changing gameplay direction. Additive charge feedback remains opener-only, while chain links retain the thin Flow-scaled continuation streak.
- Authored destinations now have a reusable CLI-first level pipeline with hardened lifecycle and live route traversal. World-local `RouteTraversalManager` owns directed profiles, transactional node handoff/rollback, history, generic exit binding, world-origin exfil, cache/state policies, and route-owned fade transactions; post-commit entry rollback synchronously clears target loader authority so failure is immediately retryable. `LevelLoader` remains the low-level stage/activate/deactivate/release service. Registry ingress starts route sessions, and level-only ingress uses an internal `@world_origin → node → @world_origin` route. `WorldIngressSpawner` combines route- and level-owned ingress definitions deterministically. Sundered Keep production is generated playable frontage plus clipped distant reveal and terminal ingress → normal fade → authored Vista Approach / Shore Parish → normal fade → Front Gate, preserving the Operator and shared camera while only Return Causeway remains isolated under `causeway_only`. Front Gate unload/revisit restores scalar, siege-objective, and Great Hall ambush state without replaying one-shot side effects. Profile validation rejects disconnected enabled participants. Runtime `persistent` route state survives later sessions through `RouteStateStore`, but save-file persistence remains deferred.
- The queued feedback fixes are live: scrap-part pickups play `pickup_collect_01.wav`; the critical low-health warning is raised from -4 dB to -1 dB; enemy-side `HEAVY` hit strength guarantees stagger below the critical threshold; paired critical contact applies dedicated camera shake plus its directional kick; and inventory cards expose hover tooltips with item identity, class, quantity, and description.
- Sundered Keep presentation is split by location: procgen owns the generated playable frontage and clipped distant ocean/storm/fortress reveal; the authored Vista Approach owns Shore Parish, near-Keep presentation, mapper route ground/boundary rails, local reveal, enemies, and dressing. The procgen `VistaPresentationRoot` is absolute-depth behind gameplay, clipped at the exterior side of the generated gate, and has no collision/navigation descendants.
- The older `SunderedKeepApproachRoute` staged `LevelRoute` and its two dedicated smokes are explicitly legacy/debug-only. They are not part of the registry-driven production transport pipe or production acceptance, and their obsolete `configure_connection()` expectation must not be added to the current Front Gate map. Production gates on registered ingress, procgen-vista layering, route-registry, authored ingress/return lifecycle, and renderer review instead.
- `WorldIngressSite` isolates `ProcGenRuntime` and the other `world_origin_branch` nodes while the authored approach is active, then restores visibility, process mode, Operator position, Operator-follow camera, and cleared presentation bounds on return or failed entry. Ocean/storm sprites own no physics; mapper-authored perimeter rails prevent leaving the top-down route.
- Developer Observatory exports now disclose event-ring capacity, cumulative logged events, dropped events, and
  saturation; the analyzer also flags legacy full 300-event exports as potentially wrapped. Projectile roots own their
  collision shapes through the `projectiles` group. Ammo gauges carry active weapon ID/state key, capacity, and
  per-shot cost; a controlled 18-shot `carbine_mk1` smoke reconciles 24/48 to 6/48. Enemy attack reporting derives
  mutually exclusive terminal outcomes and lifecycle counts by `attack_id`, while interruption causes remain separate.
  Dodge overlap telemetry emits one canonical classification per attack, and Falcon Punch terminal events include
  launch/active-start/closest-approach/lateral/dodge/obstruction diagnostics; the focused Falcon smoke samples seven
  stationary attempts at each of 96, 136, and 176 pixels without changing balance values. A separate mixed-population
  smoke deliberately enables two director/profile agents beside one legacy enemy and reconciles both population gauges.
- Observatory signal quality now treats stable infrastructure power tiers as
  gauge/state rather than repeated events: the existing consumer transition
  gate is regression-tested against duplicate emissions. Ranged overheat
  failures carry threshold, decay/delay, lockout, ammunition, cooldown, and
  held/tapped trigger context without changing heat tuning. The session
  analyzer reports retained overheat statistics, independently limits Heatmap
  rankings, decodes cells to world-pixel bounds, and flags buffer wrapping,
  retained-event domination, unexplained damage/death, overheat-dominated
  failures, and dodges without observed iframe avoids.
- Material Intelligence Runtime v1 adds the gameplay-safe
  `MaterialIntelligence` autoload plus typed `MaterialProfile` and
  `MaterialProfileLibrary` resources. Untagged positions resolve to
  `unknown`; explicit 64 px cell overrides provide canonical material
  metadata only. Actual projectile impacts, muzzle-blocked shots, confirmed
  player melee impacts, and enemy deaths emit `material_contact` telemetry and
  low-weight Heatmap tags. Observatory exports cumulative material/contact
  summaries and samples the current player material. Profiles expose future
  footstep, impact, and stealth response data, but v1 changes no audio, VFX,
  damage, movement, stealth, AI, procgen, collision, or world-state behavior.
- Combat observability now records Field Patch prompt/ignored-on-death transitions and a structured death snapshot; parry started/active/expired/success/miss-feedback/failed-hitreact transitions; enemy critical opportunity open/consume/expire; paired critical starts/hits; and mutually exclusive Falcon Punch terminal details. The HUD exposes a pulsing `[P]` Field Patch prompt below 50% health and intensifies it below 25% without auto-healing. Observatory reports explicitly separate retained terminal events, retained unique IDs, cumulative incoming results, and whiffs, while procgen remediation warnings identify the pocket, center cell, blocker source, and action.
- Operator unblocked HEAVY-hit presentation now uses the ingested directional E/W 12-frame `bodyslam_knockdown_01` full-body and combat-FX strips. The reaction preserves the authored one-second launch/fall/recovery playback, resolves direction from incoming hit metadata, suppresses modular/weapon layers for the full-body clip, and leaves LIGHT hits on the existing 0.22-second recoil. The focused `operator_knockdown_animation_smoke.gd` validates both body/FX pairs and runtime cleanup.
- `enemy_savage` is a distinct cost-3, wave-4 rushdown enemy at `res://game/actors/enemies/enemy_savage.tscn`: 104 speed, 64 HP, 10 base damage, 16 stagger threshold, and 38 critical threshold. Its `raider_savage` profile is more aggressive and less self-preserving than `raider_grunt`, cannot steal resources, and retains crude sabotage. Shared `Enemy` fixed-step combat owns its two-hit chain and telegraphed pounce. `SavageAnimationLibrary` consumes mixed-canvas E/N/S/SE/SW/W idle plus E/W eight-frame run strips. Missing idle/movement directions resolve through deterministic nearest-sector presentation fallback with previous-sector tie stability and never change velocity or AI direction. Authored E/W pounce body/FX strips are present but remain unwired; chain, reaction, and death art/playback remain missing as recorded in root `REQUIRED_ASSETS.md`.
- Grunt presentation now uses dedicated directional 6-frame Falcon-punch windup/inflight/recovery strips, improved 11-frame E/W staggers, directional 5-frame E/W flinches, and the newer 8-frame east death clip. Superseded E/W 8-frame stagger runtime copies were removed through the sprite pipeline.
- Parry/critical branching is authoritative in `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`. Successful parries drive enemy-owned `critical_open_enter_s -> critical_open_hold_s -> critical_open_recover_s`; after the one requested parry knockback step, these standalone phases preserve the enemy's independent world root, leave the Operator independent, and suppress the ordinary target ring through recover. The hold strip was realigned 16 pixels right inside each uncropped 96×96 cell to match enter-final/recover-first placement. Optional one-shot posture-break and unconsumed-window-expiry scenes now bookend BREACH/countdown presentation, use the marker/ring offsets, auto-free on animation completion, and are jointly gated by `grunt_optional_critical_vfx_enabled`. Valid follow-up input selects the nearest enemy-owned opportunity inside its capture range without reapplying the ordinary melee aim cone, atomically reserves it, and only then begins the zero-offset shared-root paired execution. The reservation locks a matched S/E/W Operator-body/FX/victim triplet: dominant horizontal approaches select E/W, while vertical approaches deliberately use S because no north pair exists. South advances through the authored eight-frame 90/130/160/220/50/150/150/250ms schedule; east/west advance through all twelve frames at 12 FPS. All directions apply enemy-authoritative damage once on source frame 5 (index 4), freeze both paired actors there for 110ms, and restore control only after the final settle; nonlethal, lethal, and cancellation paths retain unified cleanup and compatibility aliases.
- DevConsole `spawn_grunt` now accepts `normal`, `falcon`, `critical_enter`, `critical_hold`, `critical_recover`, `execution_ready`, and `execution_lethal` presentation presets plus `spawn_grunt modes`; the legacy numeric-offset form remains valid. `falcon` stages the special against the Operator at a useful default distance, while the other modes remain presentation presets. Modes are applied by the spawned grunt after ordinary instantiation/difficulty setup, keep normal runtime authority intact, and emit Developer Observatory events.
- Modular two-handed ranged presentation resolves a stationary lower body from the aim-owned upper direction, permits movement-owned strafing only within a 100-degree twist, and slaves both modular weapon direction and normalized frame position to the upper body. Raise/lower clips retarget with preserved progress; fire locks visible layers to a committed shot direction and recovery immediately resolves the current cursor. The Carbine phase-1 `e/w/se/sw` vertical slice now loads generated per-animation/per-frame grip, support, muzzle, ejection, angle, and draw-order metadata through `operator_weapon_socket_library.gd`; projectile and muzzle-flash origins share the resolved muzzle. Existing 96px modular weapon strips remain compatibility art while static directional exports are deferred. Raise/lower timing is asymmetric (`0.22s`/`0.12s`) with a `0.70` readiness threshold. Camera-owned aim feedback composes a 1.07 zoom multiplier and 32px directional lead with existing shake, bounds, and framing, while the reticle consumes read-only aim accuracy.
- If an enemy hit lands during a committed parry attempt that does not validate as a successful parry, the Operator now cancels the failed attempt, plays the existing blocking hit-react animation, and still takes the incoming damage. Marine dash respects this result flag so dash impact recoil does not overwrite the block-hit presentation. Marine impact now delegates knockback exclusively through the Operator-owned impact API, and pursuit caps inward velocity at the attack boundary instead of overshooting into sustained body pressure.
- Removed `ranged_2h_aim_cape` animation block from `operator_modular_cape_frames.tres` — no production `operator__modular_wardrobe_cape__ranged_2h__*` source sheets exist, so the entry was wired to a wrong unarmed fast-recovery cape. The operator now gracefully hides the cape layer during ranged aim instead of playing mismatched art.
- Fixed `operator.tscn` default `ModularCapeSprite` animation from the removed `ranged_2h_aim_cape` to the existing directional `unarmed_run_cape_up`; the defense smoke still expects the cape to stay hidden during ranged aim.
- Doc-drift remediation: swept all `design/20_features/` references across design docs under `02_features/` and change-control docs, updating 8 files to point to the active `02_features/` paths. Archived/historical references left in place. Only intentional historical/retired references remain.
- Operator parry-success readability no longer depends on `ModularUpperFxSprite` surviving the 0.03-second success-to-neutral transition. Successful parries now spawn a dedicated world-space one-shot burst and one positional `parry_success_01.wav` cue at the captured contact point; misses and failed/expired attempts remain silent. Modular `PLACEHOLDER_unarmed_parry_success_fx*` remains optional motion dressing with missing-direction warnings. Enemy grunt BREACH/ring timing and all parry simulation timings are unchanged.
- Allied combat-drone guard commands support hostile and selected Shrumb designation. While `J` is held, a valid hostile or `drone_command_target` Shrumb under the pointer receives a red command reticle; clicking assigns it as the explicit squad target and anchors the order at its position. Empty-ground clicks retain ordinary guard placement, automatic fire-at-will acquisition still skips passive Shrumbs, and explicit targets remain constrained by guard engagement/return/leash rules. `K` now performs a complete return-to-Operator-follow command: it clears guard/target/marker state and restores tactical `FOLLOW`, while preserving fire discipline and close/far/free-roam formation distance.
- Sundered Keep is the first destination wrapped by the shared `LevelDefinition` / `LevelRegistry` / `LevelLoader` contract. Procgen builds the playable `sundered_keep_frontage`, applies its floor/collision/clearance authority, spawns its clipped distant reveal, and places the registered `procgen_landmark_terminal` ingress at the generated gate anchor. Crossing that ingress uses a short fade into the mapper-authored Vista Approach / Shore Parish. `sundered_keep_approach_outskirts.json`, `_collision.json`, and `_occlusion.json` own the authored route overlays, 45 collision rails, markers, subregions, roof cutaways, and local environmental fog. The outskirts layout JSON is the authority for all 19 authored-approach markers; the mapper rejects duplicate node names or positions before saving. Mapper preview toggles avoid loading disabled expensive layers while production remains full fidelity. Its east checkpoint threshold uses a short fade into Front Gate `EntrySpawn`; reverse travel also uses a short fade. `return_causeway` remains `causeway_only`.
- The production Approach now applies a conservative presentation trim: only the approved seventeen fortress-component textures/nodes are instantiated, hidden parallax layers skip processing, the invisible parapet and four route-wide translucent fog/mist overlays are not built, procedural approach lights use `256x256` radial textures, route-master mipmaps are disabled, and authored vista grunts default off behind an explicit production-performance export. The ocean underlay and remaining visible Grand Vista stack are retained; lazy Grand Vista construction remains deferred.
- The authored-underlay plate pipeline is installed from `custodian_authored_underlay_pipeline/`: `slice_authored_underlay.py` slices an external large master into verified core-plus-bleed plates, writes a deterministic manifest plus streamed runtime/static preview scenes, and is consumed by `AuthoredUnderlayPlateLoader`. Its isolated `.venv` supplies the pinned Pillow dependency without altering system Python. Installation/unit/parse checks pass; no production plate set has been generated yet because the external source master is a separate input.
- Active runtime: Godot 4.x project in `custodian/`.
- Active main scene: `res://scenes/game.tscn`.
- Authority model: Godot-authoritative runtime with no external gameplay authority.
- Timing model: fixed-step deterministic simulation.
- State root: `GameState` and `GameStats` autoloads plus world/system nodes under `GameRoot`.
- First observability foundation is live as a developer-facing runtime layer: `DevObservatory` toggles from `F9` in the main game scene, `SectorHeatmap` samples player presence and accumulates damage/death channels, `WorldHistory` journals sector-scoped runtime events in memory, `WorldStateGraph` exposes keyed reactive world truth, and `SimulationInterestManager` classifies opt-in nodes by squared distance at 5 Hz without taking gameplay authority away from their owners. Enemy `dormant` tier now suppresses local physics and is reactivated by the always-running manager; active, nearby, and background remain full simulation until an authoritative background tick exists. Screen visibility remains presentation-only.
- Developer Observatory instrumentation expands the existing `res://game/systems/debug/dev_observatory.gd` autoload rather than adding a duplicate. Ranged trigger/request/shot/failure metrics now use stable failure reasons and empty/state/internal categories; enemy-to-Operator melee events share attack IDs and damage/health reconciliation fields. Dodge timing, Field Patch attempts/rejections/low-health availability, stamina causes/exhaustion, world-state metadata, procgen rescue forensics, and node ownership/performance gauges are captured without changing gameplay balance. Director-profile and legacy combat populations are reported separately. The analyzer labels total versus displayed warnings honestly.
- Navigation Combat Heatmap Reporting v1 extends the existing `SectorHeatmap` autoload into a bounded, exportable developer-analysis artifact. It samples 64 px player-presence cells, aggregates damage, death, ranged, dodge, Field Patch, enemy-kill, and resolved incoming/enemy-attack outcomes by event type, and embeds a JSON-safe snapshot plus cell/sample gauges in Developer Observatory exports. The session analyzer reports top, danger, and combat cells. Legacy F9 channel queries remain compatible, and no heatmap data influences combat, movement, AI, director, collision, or world-state authority.
- Developer Observatory session export is live on the same autoload. `F10` / `debug_observatory_export`, `DevObservatory.export_session_json()`, and `export_timestamped_session_json()` write bounded JSON playtest artifacts to `user://dev_observatory/latest_session.json` and `user://dev_observatory/session_YYYYMMDD_HHMMSS.json`. Payloads contain schema/export metadata, project and engine metadata, current scene, uptime/session counts, events, counters, gauges, and warnings with JSON-safe Variant conversion. Export preserves the event buffer, logs `observatory_session_exported` on success, prints the absolute path, retains it in the F9 overlay, and routes directory/open/write failures through `mark_warning(...)`. Hidden F9 state performs no periodic recursive runtime sampling; visible sampling consolidates ownership/root counts into one tree walk, and export forces one current snapshot.
- The F9 Observatory now has Tab/Shift+Tab Overview, Performance, Warnings, Events, and World/Procgen pages. Only the visible Performance page retains a bounded 600-frame delta-time buffer; its 0.25-second summaries report current/average/P95/P99/worst frame time, hitch counts, draw calls, rendered objects, node/physics/collision counts, combat populations, procgen reveal backlog, and loaded roots. F10 embeds the performance summary while preserving the hidden-overlay no-scan contract.
- `DevMode` is the central runtime development authority and loads before the debug stack. Debug-build, `custodian_dev` export-feature, project-setting, and command-line inputs resolve `enabled`, `debug_ui`, `observatory_sampling`, and explicit-only `heavy_diagnostics` capabilities. DebugBus input, snapshot collection, ImGui-console connection, Observatory overlay/sampling, and Observatory telemetry accumulation are gated accordingly; offline Python/Aseprite/HTML tools remain invocation-gated and do not depend on runtime state. Native ImGui conditional instantiation remains a future `DevBootstrap` slice.
- Modular combination review can now produce contract-aware prioritized work. `custodian/tools/operator/modular_combo_check.py` accepts either an animation domain such as `idle` or a direction such as `ne`/`south`; direction selection stages every matching runtime sheet and reviews exact lower/upper action-loadout counterparts while reporting one-sided coverage. It records resolved canonical pair/chain sources, evaluates gap and center thresholds, supports report-only refresh, and invokes `custodian/tools/operator/operator_next_actions_report.py`. The helper joins fit severity to `operator_modular_core.json` and the existing production coverage reporter, groups whole direction/phase approval units, and emits generated `next_actions.json`, `NEXT_ACTIONS.md`, and HTML recommendations with repo-relative/absolute paths, runtime destinations, commands, validation, timestamp, commit SHA, and a non-authority notice.
- `custodian/tools/analysis/analyze_dev_observatory_session.py` reads those exports with Python 3 and no third-party packages. It accepts an explicit JSON path or discovers the stable export in standard Godot user-data locations, validates the root payload, tolerates unknown schema revisions, and prints compact session/scene metadata, top event kinds, warnings, nonzero counters, gauges, combat signals, and damage observed before each captured player death without mutating the source file. Sourcing `tools/custodian_aliases.sh` exposes the same tool as `obsreport`.
- High-resolution source art now has a deterministic pre-ingest converter at `custodian/tools/art/source_to_pixel_art.py`, exposed as `pixelart` after sourcing `tools/custodian_aliases.sh`. One command generates crisp nearest-neighbor, balanced box/palette, and bold clustered 96×96 candidates, presents a labeled comparison when a viewer is available, prompts for the selected output, warns on non-integer reduction ratios, and supports explicit non-interactive selection for repeatable automation. Converted PNGs remain cleanup masters and do not become runtime authority until reviewed and passed through the existing sprite intake pipeline.
- Terminal `REBOOT` now repopulates the typed `Array[String]` transcript in place, avoiding the Godot runtime error caused by assigning an untyped duplicated boot-line array.
- Active UI shell: in-game command terminal embedded in the Godot HUD. Its SECTORS page now uses a tactical-management hierarchy: larger shared minimap with focused-sector labeling/highlight, one-line aligned sector table, authoritative `NAME // STATE` selected-sector detail card, aligned command-link actions, smaller secondary event log with compressed focus-shift spam, explicit grid-deficit top status formatting, and clean dark text panels while preserving the industrial terminal frame.
- Current gothic/brass gameplay HUD style: compact Black Reliquary UI, with runtime assets under `res://content/ui/black_reliquary/` and reusable Godot UI components under `res://game/ui/`; the Black Reliquary minimap frame embeds the shared live tactical minimap renderer instead of static marker art, Sundered Keep-specific quest/status/prompt/minimap surfaces only show while the player is inside Sundered Keep, normal-play diagnostics route to the dedicated F12/`debug_hud` debug screen instead of scattered HUD labels, and terminal focus masks gameplay overlays/debug surfaces without re-showing inactive map-local HUDs.
- Current beginning/home slice: `res://scenes/home_custodian_begin.tscn`, an authored Road of Witnesses scene where the Custodian awakens beneath a repeating institutional command (RETURN TO POST), tracks its source through grand ruins to a damaged Field Terminal, and establishes witness contact at a post the terminal already recognizes from a converging continuity.
- Mandatory local agent/developer entrypoint: `custodian/AGENTS.md`.
- Godot 4.7 startup maintenance now uses explicit GDScript types in strict-warning paths, complete SpriteFrames
  `loop` metadata, current resource UIDs, and canonical/noncanonical import regeneration guidance documented in
  `design/00_meta/UID_DUPLICATE_FIX.md`.
- Procgen-triggered navigation rebuilds now explicitly bind the active `ProcGenTilemap` floor/wall `TileMapLayer`
  references plus its runtime prop-blocker overlay before rebuilding. Floor/wall TileMaps remain base structural authority;
  collision-bearing tree trunks and ruin props register only their physical footprints, participate in walkability and
  deterministic two-exit pocket validation, and unregister with streaming/cleanup. Required routes and structure mouths
  keep three-tile blocker clearance, combat/readability zones keep four, and tree canopies may remain visual when trunk
  collision is suppressed. Remediation, `stuck_report`, and debug-only Operator rescue are loud and mirrored into Developer
  Observatory; they do not move generation authority into navigation, UI, or telemetry.
- Procedural ruin props now share an explicit bottom-contact coordinate contract: the prop root is the floor anchor, the
  base sprite uses `-anchor_offset`, and inline collision offsets are root-local centers. The obelisk, rotunda, and slab
  footprints end at local `y=0`; `ProceduralProp` exposes local/global visual/collision reports and a per-instance forced
  debug overlay. Procgen registers inline blocker cells from the generated global collision rectangle while preserving
  individual shapes for authored multi-shape scenes, and reports alignment or
  protected-clear-zone anomalies loudly and through Developer Observatory counters/gauges/warnings. Collision-bearing
  scatter candidates are now selected and rejected against their complete jittered `PropDefinition` footprint before
  instantiation; late portal-path reservations receive a second actual-instance footprint check before blocker
  registration. Candidate order uses the scatterer's seeded RNG rather than the global shuffle. Post-spawn collision
  disable/unregister and stuck-pocket repair remain loud backup paths. Rejection/warning payloads include definition,
  source tile, global rect/tile footprint, protected-zone type, remediation action, and generation seed, with per-generation
  gauges for rejection, pocket, and alignment-warning totals. Telemetry remains diagnostic and has no gameplay authority.
- Enemy melee and Falcon Punch telemetry now keeps stable lifecycle attack IDs and explicit terminal outcomes. Ordinary
  melee whiffs distinguish range from arc failures; cancellation distinguishes parry interruption and death. Falcon Punch
  exposes attempt/hit/parry/whiff/cancel counters, carries its attack ID through the Operator incoming-hit result, and only
  enters ordinary impact lock after confirmed damage. Parry hard-cancels without impact lock, while collision/range misses
  enter recovery with a reason.
- Developer Observatory node statistics now split collision-shape ownership for runtime walls, foliage, ruin props,
  enemies, and projectiles, plus physics-body ownership for runtime walls, foliage, and ruin props.
- Return Causeway now has a visual-only distant Sundered Keep parallax landmark using
  `res://content/backgrounds/sundered_keep/shared/landmarks/distant_sundered_keep.png`, plus a simple far-mist band. The layer has no
  collision, navigation, interactables, or TileMap authority and is covered by `return_causeway_parallax_smoke.gd`.
  Its Vista-arrival spawn is five tiles north of the southern backtrack exit; the exit's 192 px arrival guard suppresses
  automatic body-entry requests until the Operator clears the staging radius, eliminating the activation bounce while
  preserving ordinary physical backtracking afterward.
- The production profile enters the registered Shore Parish / Outer Wall
  Approach at `res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn`,
  then resolves generic `continue` to Front Gate. The approach mapper owns 45
  collision rails, semantic markers, subregions, occlusion records, and four
  visual overlay records. Supplied northbound/eastbound ground overlays make the
  route readable; a close checkpoint-detail overlay and a lightweight procedural
  local fog ribbon provide the only checkpoint reveal treatment. The former
  `9216x384` six-frame fog sheet is removed. `GrandVistaRoot` is hidden,
  the full-screen final-gate veil is not built, and all historical Camera 2
  weights are zero. Gate/key/siege authority remains in the actual Front Gate.
- The Sundered Keep has two production authoring tools. The Approach/Outskirts
  mapper previews the continuous exterior and owns its three JSON documents.
  Its saved `EntrySpawn` now drives the named runtime spawn used by the route
  loader, including the approach's authoring-to-runtime vertical offset. `Z`
  opens the Approach-only feature-zone editor for cycling, reshaping, and saving
  the existing authored subregions directly on the map.
  `res://scenes/debug/sundered_keep_mapper.tscn` previews the actual
  `SunderedKeepMap`, writes the production level document and canonical
  collision document, and combines rail/marker editing, the stable 01–99
  palette, underlay stamps, drag painting, undo/redo, and generic relocation
  for every authored spatial record plus siege offsets. Features mode now
  draws every spatial record, supports on-map hit selection, `Shift+Left`
  relocation, and `N` creation from the selected record type; singleton
  authorities relocate instead of duplicating. Return Mooring is exposed as
  one linked bundle so its module, markers, shore/zone records, and relative
  siege behavior remain aligned. Saving rebuilds the actual production preview
  from the written JSON. Production consumes
  the same 127 reviewed capsule rails and seven exact runtime markers. Rails
  own all permanent static collision; PNG alpha owns none, and per-wall,
  per-prop, procedural-fallback collision is suppressed. The two stateful
  gate/door blockers use mapper-authored rectangles.
- Front Gate visual authority now begins with
  `sundered_keep_main_overlay.png`. The retired static `fill_rect`,
  `fill_weighted_rect`, `paint_cells`, `stamp_wall`, `stamp_prop`, and
  `stamp_prefab` ops are preserved only in
  `content/levels/sundered_keep/archive/sundered_keep_front_gate_legacy_visual_ops.json`
  and are not runtime authority. The production document keeps an explicit
  empty `mapper_placements`; this array is the sole editable visual-overlay
  channel and is populated only by deliberate palette or underlay-stamp edits.
  Collision rails, semantic markers, elevation/occlusion regions,
  interactions, siege data, stateful gate/door blockers, and the retained
  Return Mooring module remain independent functional authority.
- Sundered Keep production access follows ordinary procgen terrain → compact
  north-edge `WorldIngressSite` → short fade → authored Vista / Outer Wall
  Approach → short fade → Front Gate. The approach may reverse directly to
  world origin; Front Gate backtracking returns to the approach after its
  144px arrival guard has cleared. Return Causeway remains behind
  `causeway_only`. The playable-blackout bridge remains an experimental
  transition implementation but is not enabled by the production profile.
  Route commits remain fail-closed until route identity, approach visual
  readiness, shared-camera ownership, Operator follow, cleared presentation
  framing, and procgen-objective suppression all validate. Zero-influence
  Vista envelopes explicitly release camera authority. The six
  authored-ingress smokes plus route,
  state, and authored-exit suites validate the current production chain.
- Current Severing canon: The world did not collapse because shared context merely faded. The Severing is rooted in a supernatural/cosmic provenance wound caused by the Unnarrival; information collapse and fragmented history are the observable symptoms, and knowledge recovery is provenance stabilization across object, origin, witness, time, use, and meaning. See `design/03_world/lore/CORE_LORE.md` for the canon terminology ladder.

## Current Implemented Slice

- Combat resource/readability planning is normalized under `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`. The in-progress umbrella records verified live state without duplicating completed feature authority: ranged ammo/heat/noise, equipment-gated sidearm behavior, core stamina/parry/guard, Field Patch healing/restock, Integrity Reclaim, vault theft, portable turrets, and allied drone V1 route to their permanent specs and Godot runtime homes. Active follow-up is production combat-pressure feedback, richer Field Patch presentation, hit taxonomy/full riposte, durability, traps, and drone logistics. The former root-level `design/COMBAT_RESOURCE_READABILITY.md` draft and its nonexistent `design/20_features/in_progress/` target are retired.

- Ranged combat balance and stealth V1 is live from `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`. Operator ranged state now uses capped typed reserves and persistent per-weapon magazines, carbine/P-9 data has materially smaller ammunition supply, all ranged weapon JSON supports max range/falloff, handling, heat, and noise, projectiles expire and lose damage over distance, and sustained fire builds per-weapon heat through overheat lockout. `NoiseEventBus` is a generic autoload; gunshots publish positional events consumed by the existing enemy perception component. Behavior-enabled enemies investigate heard positions, pursue only with sight/memory, search deterministic offsets after LOS loss, and return to an authored home/leash. The main scene includes two activation-limited hostile ambient camps outside wave spawning, with a marker-driven spawner bridge available for procgen/authored maps. Canonical weapon status exposes ammo, active ranged context, heat, noise, and range while retaining legacy HUD keys. Normal-play HUDs now show an active weapon icon plus magazine/reserve count under health/stamina, falling back to melee-ready text when no ranged magazine is active. Vehicle weapons, production heat UI/audio, cover/light modifiers, and large procedural bases remain deferred.

- Procgen Intent Graph / Ascent V1 is live as the first route-first worldgen correction layer. `ProcGenTilemap.world_shape_mode` defaults to `ASCENT_FIELD`, which skips the legacy BSP/corridor/cellular cave mask as base substrate and instead builds exterior floor/wall authority from `WorldgenIntentGraph` plus `AscentFieldBuilder`: broad ascent route, switchback terraces, side pockets, sparse cliff/ruin/border blockers, vistas, and story/faction reservations. `LEGACY_CAVE` keeps the old generator path available. `get_level_data()` exports `world_shape_mode`, `worldgen_intent_graph`, `ascent_field_summary`, `main_route_cells`, `vista_cells`, and reserved regions. TerrainBuilder receives intent required cells and reserved regions, applies guarded runtime height/traversal metadata, then preserves connectivity before layering the existing ascent route, mountain, and platform passes. Faction and story reservations now claim actual floor footprints through the shared authored-scene reservation API before their placeholder markers/anchors are used. Elevation traversal query APIs are live on `ProcGenTilemap`; full Operator/enemy/vehicle pathing enforcement remains deferred.
- CUSTODIAN Lighting System V1 is live in `res://scenes/game.tscn` as a Godot-native presentation layer under `res://game/world/lighting/`, documented in `design/02_features/lighting/CUSTODIAN_LIGHTING_SYSTEM.md` and `design/02_features/visuals/WORLD_ATMOSPHERE_SHADER_SYSTEM.md`. The main scene now owns `CanvasModulate`, `DirectionalLight2D`, `WorldLightingDirector`, the `sundered_keep_exterior` default profile, and a fullscreen world-atmosphere pass below the UI. Contract planet profiles flow through `ContractWorldLoader` into duplicated runtime lighting profiles. Generated foliage shares shrub/tree wind/visibility-bubble materials, derives spatial phase from world position, updates uniforms per shared material, and limits z-order inspection to a tile window around the player; current motion tuning is 0.70 local px for shrubs, 1.35 local px for trees, and 0.42 gust contribution. The atmosphere pass uses three fog FBM octaves, two optional cosmic octaves, and skips cosmic noise entirely at zero strength. `LightRig2D` now supports authored light/glow cookies, shadows, light height, and asymmetric scaling while retaining its generated radial fallback. Six cookies, five painted contact/cast shadows, five additional localized-contrast profiles, and an eight-frame dust shaft are live under `res://content/`; the gatehouse reference scene exercises a cold window slash, two warm braziers, three pillar casters, a gate caster, contact shadows, a darker zone, and a bright objective. Operator and grunt blob-shadow presentation consumes the painted character contact texture. The standalone `lighting_system_smoke.gd` validates both the original playground and gatehouse reference room; `world_atmosphere_smoke.gd` verifies live scene wiring, shader/profile propagation, shared foliage uniforms, UI ordering, and representative light rigs. Production placement of the new profiles/occluders beyond the reference room and manual visual/performance tuning remain deferred.
- The first Home beginning slice is implemented from `design/03_architecture/HOME_CUSTODIAN_FIELD_TERMINAL.md`. It lives at `res://scenes/home_custodian_begin.tscn`, with objective/signal control in `res://game/world/home/custodian_home_begin.gd` and the reusable `FieldTerminalInteractable` in `res://game/world/home/field_terminal_interactable.gd`. The scene uses the existing Road of Witnesses map, Operator, camera, Black Reliquary HUD, and command-terminal fallback art to present Objective 01, “RETURN TO POST”: the Custodian awakens in a grand institutional ruin, tracks a repeating command to its source, and discovers a damaged Field Terminal whose state shows continuity convergence with a version of events where this post was already restored. Signal/command status advances by distance, the terminal is discovered through the normal `interactable` group, and witness contact updates the HUD into a partial terminal-stabilization state without opening the HUD debug overlay. This scene is not yet the project `run/main_scene`; `res://scenes/game.tscn` remains the active main scene until boot-flow ownership is changed deliberately. Production Field Terminal art, signal FX/audio, and terminal-chamber dressing are tracked in `REQUIRED_ASSETS.md`.
- Contract generation is live and produces a contracted planet plus a linked tactical runtime world. Contract-owned procgen attempts now disable child `ProcGen` ready-time auto-generation before adding candidate maps to the tree, run candidate attempts in metric/evaluation mode, log explicit layout validity/connected-room/compound-ingress and terrain fallback/connectivity/rescue metrics, reject TerrainBuilder fallback/disconnected/excessive-rescue candidates for acceptance through `terrain_rescue_reject_threshold`, and regenerate only an accepted map once in full visual mode before contract emission. Attempt-loop logging now reports `attempts_run`, `max_attempts`, and `accepted_attempt` instead of implying the max attempt count always ran. Candidate evaluation now distinguishes layout validity, pre-TerrainBuilder required-cell connectivity, TerrainBuilder rescue health, candidate validity, and final acceptance; logs use `layout_valid`/`candidate_valid` instead of a broad `valid=true` that could imply accepted health. Contract layout diagnostics now include spawn tile, reachable tile count, room/ingress totals, represented room anchors, exact walkability, pre-terrain required connectivity/missing required samples with source and reason, TerrainBuilder baseline rescue, terrain rescue value/limit/ok status, rejection reasons, and up to 10 unreachable room samples; `ASCENT_FIELD` room-distance metrics use semantic ascent/objective anchors instead of legacy cave room centers, and `ASCENT_FIELD` player spawn resolves to the intent graph origin so layout scoring and TerrainBuilder start from the same authority. Huge baseline rescue now means upstream generated floor/required-cell connectivity is bad before TerrainBuilder, not that the candidate is healthy. Successful contracts now place two deterministic ambient-camp markers on separated walkable vista/route cells and the mounted `AmbientEnemySpawner` creates two-grunt camps from them; failed contracts continue to disable ambient camps. If every candidate is rejected, `CustodianContractMap` emits an explicit `contract_generation_failed` result and `ContractWorldLoader` aborts runtime world activation instead of allowing a no-map combat session; the loader disables wave spawning, enemy spawn nodes, ambient enemy camps, supply drops, ambient critter spawning, current/future enemy actors, navigation initialization, and map-bound camera setup for the failed session. The optional `allow_degraded_best_candidate_fallback` flag is disabled by default and only permits a loud development fallback when layout/ingress and terrain connectivity are otherwise sane. Streaming reveal no longer collapses hidden generated floor/wall authority back to only currently painted TileMap cells, so contract connected-room scoring aligns with TerrainBuilder connectivity instead of rejecting connected candidates. The Sundered Keep visual approach also consumes two authored grunt records from its mapper layout, one centered in each vista subregion. The Katana fast-chain body and FX clips now play at 17 FPS, and the runtime `melee_stance` placeholder is the single first frame of Fast 01. The tuning attempt count remains 12 while ascent/terrain profiles stabilize.
- Main-scene observability now has a first bounded telemetry path: Operator damage/death, sector damage/repair, enemy kills, player-presence heat sampling, and power-node world-state sync all feed the new observability systems. The existing F12 debug screen remains the broader structured diagnostics surface; the F9 observatory is a faster recent-events/counters/gauges view rather than a replacement inspector.
- The fabrication terminal command path now normalizes resource ids, recipe ids, and ready-build ids back to lowercase before ledger/pipeline lookups. This fixes live terminal cases where `FAB START TURRET_BASIC` or `FAB GRANT BLACKWOOD 10` failed even though the fabrication JSON and autoload state were valid.
- Contract planet data now feeds runtime procgen through a shared world profile so the player is actually deployed onto a world shaped by the contracted planet.
- Procgen runtime consumes planet-linked variation for map size, room count bands, layout openness, compound footprint, foliage density, fruit chance, and world tinting. The generated tactical world now uses larger deterministic profile ranges, currently spanning about `144x144` to `240x240` tiles instead of the old `100x100` default. Random foliage placement now rejects authored-scene, story-room, faction-site, Ash-Bell, and Forlorn-Ritualant reservation metadata before spawning, including streaming reveal placement. `custodian/game/world/procgen/foliage/procgen_foliage_spawner.gd` owns the foliage policy, while `ProcGenTilemap` stays the facade and queue host. `FINAL_VISUAL` foliage can queue valid deterministic foliage candidates and spawn nodes over multiple frames with `foliage_deferred_spawn_enabled` / `foliage_spawn_batch_size`, keeping terrain/nav generation from blocking on thousands of foliage sprites while preserving the synchronous path when deferred spawning is disabled. Procgen timing now reports foliage queue/spawn cost separately from decorative ruin/interior prop cost via `props_foliage` and `props_visual`.
- Procgen now emits semantic gameplay-feel intent zones from `ProcGenTilemap`: `spawn_clearing`, `soft_path`, `portal_plaza`, `compound_approach`, `cover_anchor`, room-zoned `interior_floor`, `foliage_cover`, and `destroyed_wall_floor`. Streaming reveal prioritizes these regions, destroyed walls emit `destroyed_wall_floor` minimap updates, interior props carry `region_zone` metadata, and downstream systems can query `get_intensity_at_tile(tile)` for normalized encounter/loot/hazard pacing.
- Main contract-map procgen retains its deterministic `main_road` connectivity, parking/staging apron, vehicle placement, foliage exclusion, wall cleanup, and Operator/vehicle speed-surface semantics. Road presentation now uses the filled `_main_road_tiles` mask: every road tile is classified as center, cardinal edge, exterior corner, or interior corner and receives exactly one 32×32 decal from `res://content/tiles/roads_paths/runtime/roads/surface/road_surface_piece_manifest.game32.json`. The generated centerline remains generation/connectivity authority but no longer assigns lane-offset art. Narrow `soft_path` routes remain independent and continue using the connection-bitmask placeholder path manifest. Streaming removal/reveal deterministically reconstructs the same surface role. The former lane-role manifest under `runtime/roads/lane/` and road placeholder manifest are reference/fallback assets, not active defaults. Road enforcement still refuses impassable ascent-field blockers, terrain blocked/drop/ledge cells, mountain-wall authority, and compound connector wall rails. `procgen_road_surface_roles_smoke.gd` validates one decal per road tile, exact role agreement, asset coverage, path separation, connectivity, blocker exclusions, and streaming reconstruction; the historical placeholder-road smoke path delegates to it.
- Terrain Builder / elevation V1 is metadata-first. Baseline terrain metadata is visual no-op and preserves existing procgen floor/wall art; only explicit elevation/cliff feature cells stamp terrain art. Elevation currently affects terrain generation, feature visual stamping, level-data export, connectivity validation, contract candidate scoring, spawn/prop filtering, and query-only actor traversal/cost APIs. It does not yet enforce operator, vehicle, or enemy path traversal. `TerrainBuilder` under `res://game/world/procgen/terrain/` can add guarded worldgen reserved-region metadata, a deterministic mountain-wall blocker, and one raised industrial platform with directional ramp validation, while `ProcGenTilemap` applies metadata into `ElevationMap` and resolves explicit feature tile IDs through registered `procgen_world_tileset.tres` sources for `custodian/content/tiles/elevation/industrial/` and `custodian/content/tiles/mountain_cliffs/`. Terrain required cells are semantic anchors: spawn, ascent anchors/objectives/vistas, interior thresholds, compound ingress, compound connector road samples, intent graph required cells, authored claims, and deterministic connected road/parking samples after road graph repair/prune. Missing required diagnostics distinguish `spawn`, `room_center`, `interior_threshold`, `compound_ingress`, `road_sample`, `parking_sample`, `compound_connector_road`, `ascent_anchor`, `ascent_vista`, `ascent_objective`, `intent_graph_required`, `authored_claim`, and `unknown` sources, with reasons for unreachable, non-walkable, missing floor authority, or wall-blocked authority. The three pre-TerrainBuilder connectivity views, missing samples, graph disagreements, component/bridge analysis, and bounded authority-repair loop now live under `res://game/world/procgen/diagnostics/`; `ProcGenTilemap` remains the façade/state host that assembles service contexts and exports compatible level data. Pre-terrain authority repair still happens before TerrainBuilder receives floor/wall authority, preserves `pre_terrain_before_repair`, and exports `pre_terrain_authority_repair_carved_cells`. The slow production-sized rescue diagnostic covers fixed `176x176`, `208x224`, and `224x224` candidates, acceptance and rescue limits, diagnostic fields, and forced generation-failure abort behavior. Current representative production diagnostics expect `pre_terrain_connected_required_ratio=1.0`, `baseline_rescue=0`, `terrain_rescue=0`, `terrain_fallback=false`, and at least one accepted candidate per fixed contract seed. `TerrainBuilder` still validates and rescues baseline connectivity before applying reserved-region, ascent, mountain, and platform passes, but contract candidate scoring rejects poor pre-terrain required connectivity, terrain fallback, failed terrain connectivity, and excessive terrain rescue carving above `terrain_rescue_reject_threshold` so TerrainBuilder cannot silently become the route generator. Candidate-evaluation rollback warnings stay in the result and summary instead of being pushed immediately unless fallback/fatal conditions occur; final visual generation still warns loudly. Debug summary exports generation mode, required/missing required counts, connectivity/fallback status, total rescue-carved cell count, baseline rescue-carved cell count, region count, blocked cells, elevated cells, and ramp/stair cells. An `_debug_print_connectivity_map()` helper can dump an ASCII grid behind the `DEBUG_CONNECTIVITY_MAP` compile-time flag.
- Final-visual procgen now applies deterministic tile value clusters after terrain/road visuals and before streaming reveal, props, and foliage, following `design/features/implementation/TILE_VALUE_CLUSTERS.md`. The pass uses 12–35 seeded, irregular falloff clusters to group the two currently registered exterior floor families (grass/moss source 9 and stone/worn source 10). It skips evaluation candidates entirely, plus walls, elevation access, drops, special terrain tiles, roads/paths/connectors/parking, spawn/portal/interior/authored/objective/required cells, and changes only existing floor source/atlas/alternative visual fields. It never changes floor/wall membership, terrain metadata, collision, navigation, ballistics, rescue, or candidate acceptance. `floor_value_clusters_enabled`, `floor_value_cluster_strength`, an optional explicit source registry, and `floor_value_cluster_debug` expose control; scenes with fewer than two valid registered floor variants log a safe skip. Dedicated dark/light/cracked/damp/ash production sources remain deferred.
- Terrain/elevation now has its first combat-facing directional boundary semantics. Final TerrainBuilder results export cardinal `edge_profile_by_cell` metadata and ballistic edge counts. Movement-blocking platform/ledge cells remain non-enterable, while `ledge_fire_over` allows high-to-low projectile travel and blocks low-to-high travel in the first pass; ramps/stairs permit either direction, and `wall_high`/`drop` block. `ProcGenTilemap` exposes the live result through the `terrain_ballistics_provider` group. The shared swept bullet consults metadata before generated terrain collision and only bypasses generated floor/wall collision for an allowed step; actors, structures, and generic static props remain physics blockers. Sector and defense turrets reject terrain-blocked targets, and Operator/defense/drone spawners pass the provider into the shared projectile. This is directional terrain-edge ballistics, not full cover, ricochet, or 3D height math.
- Enemy behavior variables / vault theft V1 is now wired as an opt-in layer for human-style enemies. `EnemyGrunt` carries behavior components for profile data, blackboard memory, perception, objective scoring, loot carrying, and a compact finite state machine that can idle/patrol, investigate Operator noise, notice/engage the Operator, seek/open vault storage, steal resources, sabotage/damage storage, escape with loot, flee, and drop recoverable stolen-resource pickups on death/interruption. Behavior profiles now expose a close `operator_awareness_bubble_px`; if the Custodian enters that bubble while a grunt is choosing or executing a storage objective, the blackboard marks Operator awareness, runs the normal notice frame, and switches focus to engage instead of ignoring the player for the loot pile. `VaultManager` is an autoload authority for debug vault storage, resource theft/recovery/loss events, sabotage damage/destruction events, and fallback enemy exits. `VaultStorage` now tracks integrity, empty/stored/open/damaged visual state, and uses the permanent runtime asset home `res://content/sprites/environment/props/vault_storage/runtime/` instead of placeholder ColorRects or scattered source prop paths. Operator stealth now exposes a read-only snapshot for detection/noise; `sneak` is currently bound to `Ctrl` so `Z`/`C` can own item cycling. Terminal snapshots and minimap markers expose enemies searching storage or carrying stolen resources. Existing wave/debug grunt spawning remains compatible and can pass behavior profiles such as `raider_grunt`, `iconoclast_looter`, or `zealot_wanderer`.
- Grunt death rewards use the lore-specced `practical_salvage_x_grunt` table documented in `design/02_features/enemy_objective/GRUNT_LOOT_TABLE.md`. Death rolls poor practical salvage and rare provenance clues once into a corpse payload; collection, not death, delivers the typed channel through `ResourceLedger`. Generic material fallback is likewise corpse-bound for enemies without a configured typed table.
- Fabrication/resource balance now has an offline deterministic report pipeline at `custodian/tools/balance/fabrication_balance_pipeline.py`. It reads live recipe/resource JSON plus `custodian/content/balance/scenarios/default_fabrication_run.json`, simulates 30-minute runs across build priorities and drop-rate profiles, checks lore-aware drop-table rules, and writes proposal-only outputs under `reports/fabrication_balance/` instead of mutating runtime data.
- `enemy_marine` has a first runtime scene at `res://game/actors/enemies/enemy_marine.tscn` and consumes the full 8-direction idle suite from `res://content/sprites/enemies/enemy_marine/runtime/body/` through `GruntAnimationLibrary`. Its dash attack is now a tuned tactical heavy commitment move in `res://game/actors/enemies/enemy.gd`: the marine seeks a launch band, chooses quick or charged commits deterministically from range/target motion/previous result, spends a bounded charge budget between extra distance and extra damage, performs one predictive target lock during the final windup third, then commits without steering. The latest tuning pass raised the base impact to 32 damage / 105 knockback, widened the active hit window and contact reach, and nudged prediction/reset timing so the dash connects more often without becoming homing. Hit contact remains limited to the middle travel frames and a body-contact lane; impact/recovery are followed by an alternating lateral reset, preventing immediate dash trampling. The Great Hall ambush now wakes and hands control to this shared tactical runtime instead of maintaining a separate dash-spam controller. The move applies chunky damage plus poise/knockback feel through victim hitstop, forced slide/stagger hooks on the Operator, attacker hitstop, and camera feedback instead of relying only on HP loss. An east-facing 8-frame dash attack body strip and matching FX strip now live under `res://content/sprites/enemies/enemy_marine/runtime/{body,fx}/` and are used by the Sundered Keep Great Hall ambush plus generic marine combat playback. Directional body/FX variants and the servo/armor/impact/recovery audio stack remain required production assets tracked in `REQUIRED_ASSETS.md`. `WaveManager`, `EnemyDirector`, `EnemyFactory`, and `scenes/game.tscn` expose `marine_scene` / `"marine"` as a late-unlock enemy type. Until full directional movement/combat/death sheets are supplied, marine movement still uses directional idle as a visual fallback outside scripted dash moments.
- The first game-over UX slice is implemented from `design/02_features/game_over/GAME_OVER_FLOW.md`. `GameState` remains the fail-state authority, pauses the tree, emits `game_over_triggered`, and mounts `res://game/ui/game_over/game_over_modal.tscn` when `trigger_game_over(...)` is called. `GameStats` tracks waves survived, enemies destroyed, power failures, and turrets lost; `WaveManager` records completed waves, and enemy death records destroyed enemies. The modal is now a full-screen loss overlay with stats, a clear Restart button that resets run state and reloads the current scene, and a Return-to-Menu fallback that uses the configured main scene until a production menu exists. Custodian death is immediate game over (`total_lives = 1`) with Custodian-facing defeat copy, and Sundered Keep siege objective collapse routes through the same global game-over modal. Direct smoke coverage lives at `res://tools/validation/game_over_flow_smoke.gd`, with Sundered Keep collapse coverage in `res://tools/validation/sundered_keep_large_layout_smoke.gd`.
- A first connected-map slice is live for the gothic compound: contract world handoff places an interactable main-map gate near the generated compound ingress, instantiates an authored gothic compound map east of the main tactical map, and provides a return gate back to the main map. The authored submap uses the gothic compound blueprint generator under `res://game/world/procgen/gothic_compound/`, which reserves a compound rect, fills continuous terrain, builds a wall/post/gatehouse-dominant perimeter, cuts a readable south gate, carves approach/internal roads, places command keep/terminal/utility structures, protects a keep-plaza negative-space zone, adds secondary gate defenses/resources/hidden markers, clusters exterior ruin scatter, and validates required walkable routes before accepting the layout. The map now adds an explicit `AuthoredVaultRoom` node inside the accepted compound rect with three `VaultStorage` caches (`gothic_vault_ruin_scrap`, `gothic_vault_alloy_cache`, and `gothic_vault_power_cache`) plus a `VaultEnemyExit` marker, so the actual vault exists in the connected compound instead of only as a manager debug fallback. The latest layout-grammar passes add `gothic_compound_asset_defs.gd` metadata, flat-layer top-left anchoring for terrain/roads/decals, base-rooted dynamic wall/prop/gatehouse occluders under `DepthSortLayer`, footprint-aware placement/collision, chunked long-road placement, calmer macro terrain patches, zone-specific grates/decals, placement flags/errors, perimeter topology validation, larger connected-map/compound bounds, service-path complexity, and Custodian-relative depth sorting so occluding walls/props render behind the Custodian when the Custodian feet are below their base line and in front when the Custodian feet are above it. Runtime art comes from `res://content/procgen/special_rooms/gothic_compound/`.
- The Sundered Keep phase-1 slice is live as a directed authored route. The
  front-gate layout is mapper-owned through
  `sundered_keep_front_gate_large.json`; intentional `mapper_placements`,
  inline siege configuration, interactable/region records, stateful blocker
  specs, semantic markers, and the Return Mooring module share that production
  document. Legacy static tile/prop ops are archive-only. The retired
  approach-collision mapper, underlay-collision mapper, gameplay-tile mapper,
  separate gameplay-placement JSON, separate siege JSON, and deterministic
  relayout generator are no longer runtime or authoring authorities.
- Sundered Keep also acts as an authored minimap data provider: `get_level_data()`, `global_to_minimap_tile(...)`, and `minimap_tile_to_global(...)` let the compact Black Reliquary HUD minimap render live keep floor/wall cells and actor pips instead of static placeholder markers. Overlapping authored interior regions now cut away all matching roof occluders together, so the Great Hall/right-turn hallway overlap cannot leave a roof section covering the Operator.
- Sundered Keep now has a playable underlay-only debug launch scene at `res://scenes/debug/sundered_keep_production_underlay_debug.tscn`. It uses the active main underlay texture (`sundered_keep_main_overlay.png`) fitted to the `112x80` gameplay rect, includes the real Operator, `PlayerController`, `Projectiles` root, invisible perimeter walk bounds, and `CameraController`, and deliberately does not instantiate `SunderedKeepMap` or any authored tile sprites. Validation lives at `res://tools/validation/sundered_keep_underlay_gameplay_debug_smoke.gd`.
- Live Black Reliquary minimap coverage is checked by `res://tools/validation/black_reliquary_live_minimap_smoke.gd`, while `sundered_keep_large_layout_smoke.gd` asserts Sundered Keep minimap data and tile/world conversion.
- Current Sundered Keep causeway elevation is a connected single-height-cell approximation: the bridge deck is height 1, lower side/shore lanes are height 0, south/west/east stairs are explicit ramp/stair transitions, parapet wall runs have collision except at stair openings, and the large prefab gatehouse visual now owns the main gate closed/open state through `gateway_prefab_structure.png` plus the 8-frame `gateway_prefab_spritesheet_open_gate.png` strip. True same-tile stacked traversal, where a height-0 actor walks under the same coordinate occupied by a height-1 bridge deck with foliage/occlusion-style reveal, is not yet supported by `ElevationMap` and remains a follow-up runtime model change.
- `design/GAMEPLAY.md` is implemented for the current Sundered Keep elevation/readability slice. `sundered_keep_front_gate_large.json` declares authored `underpass_regions`, `shore_walk_regions`, and `interior_occlusion_regions`; `SunderedKeepMap` retains visual-only underpass shadow regions, keeps traversal authority in `ElevationMap`, exposes region debug/query helpers, and uses the existing `RoofOccluders` layer to fade Great Hall roof/ceiling overlays when the Operator enters authored interior rectangles. The retired cliff-support stamps are no longer production visual authority. This is still a single-height-cell V1, not true same-coordinate stacked bridge traversal.
- Sundered Keep V1 retains its pre-relayout preservation JSON for historical
  comparison, but no generator rewrites the active level. All future spatial
  edits route through the unified production mapper.
- Great Hall doors remain unchanged, but the post-door Great Hall route now turns right through a carpeted, collision-walled hallway. `res://game/world/sundered_keep/sundered_keep_marine_ambush.gd` stages a local `enemy_marine` in that hallway; it idles until the player approaches, advances toward the player, then uses the heavy dash timing/impact values with the current east dash attack body/FX strip as a close-range armored lunge.
- Compound room assembly now has a hardened deterministic contract across `RoomGraph`, `RoomLoader`, and `LayoutAssembler`: graph and loader RNGs are seeded from the layout seed, `.tmj` directory traversal and room types are sorted, graph JSON and room counts are validated, door metadata is normalized with `tile_position` plus kind/elevation/key fields, connection creation enforces graph rules and chooses compatible door pairs, room instances receive stable IDs/intensity, connection records include resolved endpoint tiles, bounds report actual assembled tile spans, and `_placed_rooms` mirrors the generated layout. `LayoutAssembler` now attempts graph-walk, door-aligned placement first: it roots required/start-like rooms at origin, walks graph-allowed compatible-door connections outward, aligns child room origins from parent/child door tiles, rejects overlapping placements, and only uses fixed-grid fallback for unresolved assignments.
- Procgen wall presentation is tile-only again: wall visuals come from the active TileSet wall atlas, runtime overlay/endcap passes are disabled, and per-tile runtime collision now matches the visible wall tile footprint.
- The canonical active world/procgen TileSet path is `res://content/tiles/tilesets/procgen_world_tileset.tres`; older `dungeon_tileset.tres` and `custodian_world_tileset.tres` names are retired.
- The legacy placeholder 0x72 atlas sources used by `procgen_world_tileset.tres` now live at `res://content/tiles/source/placeholder-tileset/`; they must remain inside `custodian/` so Godot can resolve them as `res://` resources.
- Procgen wall selection now routes exposed horizontal wall surfaces through dedicated top coordinates and allows visual passage cells on ordinary exposed wall runs, making authored wall-top and passage art visible without changing collision or walkability.
- Procgen now has a first region-aware indoor/outdoor slice: `ProcGenTilemap` can stamp one constructed interior region into the natural map, carve hallway/room/bay floors, connect threshold openings, expose region metadata, and block outdoor foliage/ruin prop scatter from indoor tiles.
- Indoor region outdoor-dressing exclusion now includes a small clearance radius around indoor tiles so large trees/ruin props cannot visually overhang room-border interior cells from an adjacent outdoor anchor tile.
- Tree trunk collision is now probabilistic in dense foliage: isolated/sparse trees still collide normally, while forest clusters deterministically thin trunk `StaticBody2D` creation based on local tree density so movement is less snag-prone. Final-visual foliage spawning is also batched/deferred by default so the map becomes playable after terrain/nav generation while foliage fills in over subsequent frames.
- Foliage canopy occlusion now supports multiple visual fade bubbles: the player remains the priority occluder, and nearby enemy, ambient Shrumb, or mob-group actors within a configurable player range can also fade tree/shrub canopies when hidden behind them. Combat readability adds a presentation-only profile that temporarily widens/softens the canopy bubble when a live enemy/mob is near the player, while foliage and ruin-prop placement avoid core spawn, faction, story-room, portal-plaza, and compound-ingress readability pockets.
- Procgen combat-floor readability now keeps floor/navigation authority intact while reducing visual noise: the active `proc_gen_map.tscn` first-pass profile no longer uses the source-9/full-grid alternate checker patchwork, floor value clusters explicitly skip combat/readability regions, and `ProcGenTilemap` exposes `debug_get_floor_tile_report(...)` plus `debug_print_floor_tile_at_global(...)` for source/atlas/region/generated/spawn-state inspection.
- Constructed interiors now have a dedicated visual tile family: runtime `32x32` military/concrete floor, threshold, doorway, and wall tiles live under `res://content/tiles/interiors/runtime/`, are registered into `procgen_world_tileset.tres` by `tools/tiles/register_interior_floor_tiles.py`, and are selected deterministically from `interior_floor_source_ids`, `interior_threshold_source_ids`, `interior_doorway_source_ids`, and `interior_wall_source_ids`; floor selection uses patch/accent variation plus stable flip/transpose alternatives, and corner wall art is routed through `interior_wall_corner_source_id`.
- Constructed interiors now scatter decorative runtime prop sprites from `res://content/tiles/interiors/runtime/props_*.png` and `prop_*.png` under `NavigationRegion2D/PropLayer`; these are separate from outdoor ruin props, which remain excluded from indoor tiles, and placement prefers room-edge candidates with wider spacing so props read as intentional clutter instead of a central pile.
- Three terrain gameplay packs are registered and partially wired into live procgen visual selection without changing topology or connectivity semantics. Connector uses individual AI-generated tiles with cleanup already applied; Ascent and Chasm+Bridge use component-sliced AI source sheets that preserve black void pixels through alpha component detection. `ProcGenTilemap.TERRAIN_TILESET_SOURCES` resolves all 62 gameplay art IDs: Connector sources 60–77, Ascent sources 80–99, and Chasm+Bridge sources 100–123, while preserving stable sources 32–59. Existing industrial and compound-connector ramps use directional Ascent wide-ramp art; compound connector centerlines and pre-terrain/TerrainBuilder authority-repair floors use deterministic Connector art variants while remaining walkable. Existing `cliff_chasm_drop_32` placement can visually resolve to deterministic `chasm_void_32`/`collapsed_gap_32` replacements while retaining its prior non-walkable drop semantics; no new chasm topology is generated. Bridge art remains staged and resolvable but is not generated because there is no explicit bridge/crossing placement feature. Directional stair art also remains staged where stair direction is not authoritative. The dev-only `debug_log_terrain_source_usage` flag and `debug_dump_runtime_tileset_source_usage()` report live floor/wall source counts and gameplay-pack totals without default logging. These are plain TileSet atlas sources in `procgen_world_tileset.tres`, not Godot TileSet terrain/autotile terrain sets. `terrain_gameplay_packs_smoke.gd` distinguishes manifest/symbolic/TileSet registration from runtime visual-map resolution, and `terrain_gameplay_art_usage_smoke.gd` proves representative new and old sources paint the expected TileMap layers. No terrain rescue thresholds, pre-terrain repair behavior, candidate acceptance, movement semantics, or ballistics logic changed.
- Procgen prop generation now runs after streaming reveal setup, so the streaming clear pass no longer deletes generated outdoor ruin props or constructed-interior runtime prop sprites immediately after creating them.
- Ambient critter behavior also reads the same world profile so non-combat ambience matches the contracted planet.
- The command terminal has a multi-page shell with nav rail, pinned action rail, center content pane, transcript, and command line input. OVERVIEW is now an actionable diagnosis dashboard backed by `TerminalOverviewViewModel`: documented impact weights rank all sectors, active incidents and recommendations use stable semantic IDs, Operator location is resolved only from `Sector` instances in the dedicated `sector` group, and turrets remain separate `structure`/`turret` records. Offline/cold-start counts come from that same sector-only snapshot. Compact Operational/Power/Assault summaries lead into the shared live tactical map, followed by clickable Priority Sectors, Active Incidents, and Recommended Attention links. Power summaries consume the authoritative `generated_per_second`, `consumed_per_second`, and `net_per_second` rates directly; terminal rendering never applies a frame-rate multiplier. STATUS is generated only by `TerminalStatusFormatter` for both the page and typed commands; `TerminalSnapshot` projects authoritative `GameState.tick` at the simulation's fixed 60 Hz (with physics-frame fallback before GameState exists) instead of the OS clock and exposes actual simulation rate, physical-terminal command authority, command/field mode, fidelity, archive availability, and system counts. The bounded transcript and attention feed now use the same simulation timestamp, avoiding mixed clock domains, and the header renders elapsed time as `T+MM:SS` or `T+H:MM:SS`. `TerminalFidelityPolicy` applies FULL/DEGRADED/FRAGMENTED/LOST omission rules; a redeployed terminal no longer grants command authority. Defense readiness treats zero health as `DESTROYED`, and its unimplemented targeting control is labeled unavailable rather than presented as a selectable policy list. The large globe is contextual to STATUS/CONTRACTS/ARCHIVE instead of occupying Overview. A container-based chip header uses compact signed K/s grid formatting. The primary rail keeps OVERVIEW/SECTORS/POWER/DEFENSE/FABRICATION/SENSORS/ARCHIVE/RECON visible while lower-frequency pages expand inside an explicit wheel/focus-aware `PageButtonsScroll`; MORE / SYSTEMS and WAIT/FOCUS/HARDEN/HELP remain pinned outside it. Hidden pages lose focus eligibility and are skipped by keyboard traversal. The live `MinimapView` targets a 72% Overview fill ratio while preserving local-to-world conversion through the same map rect. Terminal open suppresses gameplay overlays behind a full-viewport input-blocking dark scrim. Focused identity, power-rate, STATUS fidelity, live Overview, Defense semantics, Overview semantics, and Overview layout smokes cover the semantic and 1366×768 contracts.
- The command terminal now skins its live HUD shell from the starter terminal UI PNG resources under `res://content/ui/terminal/`: panel and map 9-slice frames, header bars, nav tabs, action buttons, command-line frame, scanline/noise overlays, and page/action icons are applied through `game/ui/hud/ui.gd` without changing command routing. Terminal `StyleBoxTexture` frames use small 2px runtime margins with semantic stretch policy: large panel/map frames tile-fit only their borders with `draw_center=false`, while header/nav/action/input controls stretch a single clean center to avoid repeated interior motifs. Compact Fabrication status strips and work-order rows deliberately use `StyleBoxFlat` so empty/state UI does not inherit heavy button art. Scanline/noise overlays remain `TextureRect.STRETCH_TILE`.
- The command terminal decursification pass has started: HUD rendering still lives in `game/ui/hud/ui.gd`, while command parsing/dispatch boundary, snapshot aggregation, map preview state/conversion, and planet preview state now have dedicated scripts under `game/ui/terminal/`.
- All thirteen terminal pages are widget-backed: `OVERVIEW`, `STATUS`, `SECTORS`, `POWER`, `DEFENSE`, `FABRICATION`, `SENSORS`, `INCIDENTS`, `ARCHIVE`, `RECON`, `CONTRACTS`, `HISTORY`, and `SETTINGS`.
- ARRN now has a first runtime implementation: `ARRNManager` is an autoload that owns the default four-relay network, scan state, stabilization tasks, packet sync, knowledge index `RELAY_RECOVERY`, deterministic weak-relay sync failures, relay decay during ticks/assaults, dormancy pressure, knowledge drift, and benefit query APIs. Procgen contract handoff places `RelayNode` entities for `R_NORTH`, `R_SOUTH`, `R_ARCHIVE`, and `R_GATEWAY`; the HUD terminal supports `SCAN RELAYS`, `STATUS RELAY`, `STABILIZE RELAY <ID>`, and `SYNC`; field relay interaction uses the existing operator `interactable` flow and locks movement while stabilizing; minimap relay markers appear after scan. ARRN benefits currently hook into terminal fidelity display, emergency repair power cost, threat forecast copy, locked archive fabrication recipes, logistics query API, and dormancy pressure reduction. Production relay art/audio, save/load, and richer dedicated ARRN UI remain deferred.
- The HUD command terminal now exposes a dedicated clickable `FABRICATION` page inside the existing terminal shell. Its work orders are flat, left-aligned `StyleBoxFlat` rows with separate state/name/category/cost labels and a selected-row highlight; resolved selection is synchronized back to the runtime selection id and scrolled into view. The lower rail is truthfully labeled `TERMINAL ACTIONS`. Selected detail begins with the selected work-order name, then aligned state/category/result fields and the full need/have/missing cost grid; Lattice Field Patch also reports live `CARRY PATCH current/max`. The Fabrication Control transcript adds non-persistent idle guidance for selection, CRAFT 1, TO MAX, and closing whenever no command is queued. Empty progress/ready regions collapse into one compact strip, the Fabrication page disables page-level and horizontal scrolling, and the navigation page rail scrolls vertically so lower entries remain reachable. Typed `FAB START` / `BUILD PLACE` commands remain valid fallback paths.
- The in-world command terminal is now treated as a deployable prop: build interaction can pick it up, carry it as a ghost, and redeploy it without changing the HUD shell entrypoint.
- The terminal deploy visual now reuses the authored `builder_terminal` pickup animation sheet, playing forward on pickup and in reverse on redeploy.
- Terminal usability includes keyboard page/action navigation, transcript link jumps, command echo fallback, auto-following text panes, and a scrollable center content column.
- The in-world command terminal prop family is now named `command_terminal`, with compatibility fallback to the older `computer_terminal` sheets until the art rename lands.
- Interaction prompts for turret pickup and vehicle exit now reflect the actual `interact` input binding instead of stale hardcoded keys.
- Vehicle Registry V1 is live. Vehicle archetypes, taxonomy, movement profiles, hardpoints, loadouts, and visual kits live under `res://content/vehicles/`; runtime registry, spawn resolver, input adapter, seat bridge, and `PilotableVehicle` live under `res://game/vehicles/`. The first production ID is `custodian_ground_buggy_scout_light`, backed by the existing `LightBuggy` scene and hover buggy runtime frames. `PlayerController` routes vehicle intent, the camera can switch follow targets, and `res://tools/validate_vehicle_registry.gd` validates registry references.
- Allied combat drones now have V3 anchor orders. `DroneManager` is mounted in `game.tscn`, spawns up to two fragile animated allied droid companions, and remains the only squad input authority: `T` toggles fire discipline, `G` cycles close/far/free-roam, `J` plus primary click places a guard anchor, and `K` recalls to Operator escort. Anchor and formation are separate axes: close/far/free-roam use the same movement contract around either the Operator or clicked guard point. Guard targeting is centered on the ordered point, enemies outside the guard engage zone are ignored, and drones outside the guard return range clear targets and return instead of pursuing indefinitely. A world-space marker identifies the order point, replacement drones inherit it, and droid labels report `FOLLOW` or `GUARD` plus formation/fire state. The Operator suppresses firing while the guard-order chord is held. Freed active/command targets are pruned before targeting helpers run and emit bounded Developer Observatory cleanup telemetry. Drones use the shared swept terrain-aware projectile, retain independent HP, and have no respawn/repair, power routing, sector coordination, objective-solving authority, or independent scouting.
- Ambient shrumbs now participate in runtime world interaction: the buggy can launch or squish passive critters on collision depending on speed, and active enemies can attack nearby shrumbs as fallback targets.
- Ambient Shrumb passive wander is anchored to each critter's placed world position after procgen spawn, so Shrumbs meander locally around their habitat instead of drifting back toward the map origin.
- Ambient Shrumb flee animation is stabilized with a short flee-retarget cooldown, avoiding frame-to-frame direction thrash while the player remains inside alert range.
- Enemy movement now has a first wall-stuck recovery pass: pathfinding enemies detect repeated collision or near-zero movement progress and force a fresh route, while passive ambient critters pick a new local wander destination when blocked.
- A first procedural enemy variant slice is wired for wolves: `EnemyVariantFactory` generates deterministic data-only wolf profiles from seed, biome, threat level, tier, family, affixes, and palette, `WolfAnimationLibrary` slices the current wolf sheets into runtime `SpriteFrames`, and `WaveManager` can spawn `"wolf"` entries through the existing `Enemy` actor using `apply_variant(profile)`.
- Procedural wolf animation now reads the current 4-row wolf sheets as directional rows (`south`, `west`, `east`, `north`) instead of always slicing row 0; runtime movement chooses the dominant direction and preserves legacy east clip names as compatibility aliases.
- The `enemy_grunt` sprite set is a live active enemy type: `EnemyGrunt` builds canonical runtime strips through `GruntAnimationLibrary`, `scenes/game.tscn` assigns the scene to `WaveManager`, and wave/factory/debug paths expose `"grunt"`. Current coverage includes south idle; east/west run; east/southeast/west melee; improved 11-frame east/west plus legacy south stagger; east/west flinch plus south body/FX fallback; dedicated east/west Falcon-punch windup/inflight/recovery; east/west melee FX; and the active 8-frame east death mirrored for west. Grunt attack windup remains `0.42s`. Falcon Punch now uses a `0.75s` target-tracking tell followed by a direction-locked leap, deliberate normal-melee cadence, independent cooldown, recent-parry and ally-lane gates, forgiving contact grace, stop-short travel, contact separation, zero forward recovery drift, hard parry cancellation, and a dedicated Operator impact reaction while preserving the shared enemy-hit gateway. DevConsole command `spawn_grunt falcon` immediately stages the special at a useful test distance.
- Combat hit feedback has a first readability cleanup: damage popups now use a smaller shared external script with shorter upward drift, and the melee contact slash is shorter, lower-alpha, and muted away from the earlier red/orange bolt look.
- Enemy assault tuning is currently more aggressive than the first director pass: `EnemyDirector` scales threat to wave budget at `0.9` with a floor of `3`, `WaveManager` fallback waves use `base_points = 7`, `growth_per_wave = 4`, `spawn_burst_size = 3`, and `max_alive_enemies = 80`, and the active scout/raider/brute/grunt scenes have modestly higher base speed, health, and damage.
- Ambient Shrumb populations now inherit deterministic world-profile traits, including tint, count/pacing, name prefix, trait tags, size multiplier, and speed multiplier, so ambient critter procgen starts from the same planet settings as map generation.
- Ambient critter north/south slink playback uses cleaned `64x85` strip sources instead of the large `1536x1024` north/south master sheet to avoid frame-origin jitter.
- Ambient shrumb readability was increased: the live shrumb scene uses larger custom slink/knockout sprite scales, and ambient variant scale modifiers no longer shrink variants below readable size.
- Forest Shrumb lore/gameplay implementation has a v1 runtime foundation: `InventoryManager` and `CognitiveState` autoloads, stackable cognitive item definitions, a generic cognitive pickup, a reusable shrumb dropper, placeholder item sprites, and the live `ambient_shrumb.tscn` actor. The former scav droid scene path has been removed from ambient spawning.
- Ambient Shrumb death playback now uses the authored 8-frame `environment__ambient_critter__shrumb__death_01__8f__e__96.png` strip as its custom knockout animation source instead of the older placeholder knockout sheet.
- Shrumb cognitive pickups now render item-specific animated 4-frame horizontal sheets from `res://content/sprites/items/` with a lightweight procedural bob/pulse instead of the earlier colored placeholder square. `residual_instinct` currently maps to the authored `faded_instinct.png` sheet.
- Resource/fabrication now has a first build-token-first runtime spine: `ResourceLedger`, `BuildInventory`, and `FabPipeline` autoloads load CUSTODIAN-flavored resource/recipe JSON, spend resources immediately when a recipe starts, tick queued `FabJob`s, and grant completed build tokens, unlock outputs, resource outputs, or bounded Operator consumables. The first `ResourceNode` harvesting slice is also live: `ContractWorldLoader` generates up to three scarce base-map tutorial nodes per contract world (`blackwood_deadfall`, `alloy_vein`, and `machine_wreckage`) on valid floor tiles outside the compound, away from immediate spawn, and spaced apart so they teach resource existence without becoming the main economy. It now also places an export-controlled first expedition-scale patch in the current generated contract map: eight non-respawning far-field resource nodes outside compound/road/parking/interior lanes, covering the compatible blackwood, alloy, wreckage, resin, capacitor, signal, and archive node presets before a separate expedition destination UI exists. `ResourceNode` can optionally render runtime body/FX sprite strips; generated tutorial blackwood, alloy, and wreckage nodes now use resource-specific harvest-state sheets, and authored nodes can auto-resolve compatible 96px idle/depleted sheets for blackwood deadfall, exposed alloy vein, collapsed machine shell, fungal resin pod, ruptured capacitor bank, broken signal relay, and shattered archive terminal. Blackwood deadfalls also use strike/idle FX where each harvest keeps the current body state visible while the full strike FX plays, flashes the matching current-state idle FX frame, then advances to the next body state. Canonical ledger and recipe/provenance keys are the flavored resource IDs directly: `blackwood`, `structural_alloy`, `ruin_scrap`, `spent_charge_cell`, `frayed_signal_filament`, `cracked_field_tag`, `power_components`, `resin_clot`, `capacitor_dust`, `signal_filament`, `memory_glass_fragment`, `white_thread_knot`, and `fiber_moss`; legacy `timber`/`ore`/`scrap` inputs only alias forward to the flavored IDs. The player-facing FABRICATION page now has a clickable work-order interface: `FabricationTerminalViewModel` converts raw recipe/resource/build-token state into work orders, selected work-order detail, in-progress jobs, ready builds, and concrete next actions, while `ui.gd` renders those rows as buttons and routes action buttons to `FabPipeline` or ready-build placement. Full save/load, separate expedition travel/destination selection, broader buildables, and power scaling remain deferred.
- A first authored hub-space prototype now exists at `res://scenes/hub_road_of_witnesses_prototype.tscn`, using the Road of Witnesses PNG as a playable background with rough collision and foreground occlusion masks.
- A separate Twin Solaria fidelity preview now exists at `res://scenes/twin_solaria_backdrop_test.tscn`. It uses the largest current `3500x3000` development composite as a gameplay backdrop with the live Operator and shared camera, image-matched camera bounds, perimeter collision, and an explicit warning that internal collision is not authored; it does not replace the active main scene.
- The Ash-Bell / Forlorn-Ritualant encounter has a first authored runtime module at `res://game/world/events/ash_bell/forlorn_ritualant_site.tscn`: local event state tracks silence pressure, thread tension, fountain state, and resolution; the placeholder site supports proximity dialogue, Forlorn-Ritualant interaction, white-thread hazard/touch behavior, clapper pickup hooks, Dry Fountain apparition state changes, Unarrived apparition placeholders, and a south doorway. The encounter is no longer a procgen special room. Its fixed authored wrapper at `res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn` owns level lifecycle, named arrival, camera bounds, boundary rails, and `return_world` exfil through the authored route pipeline; procgen may place only the exterior cave ingress. The retired `res://content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json` must remain absent, and both the focused Underground smoke and generic special-room smoke enforce that ownership boundary. The room instances reusable world-space `res://scenes/environment/forlorn_ritualant_shader_fx.tscn` beneath its alpha-carrying floor/rubble art, using `res://content/backgrounds/forlorn_ritualant/cosmic-underlay.png`, a room-silhouette mask at `res://content/masks/forlorn_ritualant/room_silhouette_mask.png`, and encounter-local CanvasItem shader/material resources for slow void-ocean drift, edge shadow/rim separation, and faint temporal haze. These effects are presentation-only and add no collision, navigation, interactables, or simulation authority. Normal `scenes/game.tscn` startup still does not mount the temporary Ash-Bell dev spawner; manual visual review lives in `res://scenes/debug/forlorn_ritualant_site_debug.tscn`. Production Ash-Bell art/audio is intentionally tracked in `REQUIRED_ASSETS.md` rather than silently invented.
- The procgen surface entrance for that encounter selects `AshBellLiftIngressSite` only for route identity `forlorn_ritualant_underground` and attaches `ash_bell_lift_ingress_presentation.tscn`. Its exact explicit-interaction prompt is `TRAVERSE THE DERELICT LIFT`; entering the Area2D alone does not traverse. The parked landmark is now exterior-only: an irregular dark mouth, threshold-aligned 173 px lift, short chains, lamp, and authored rock/timber foreground mask remain visible while the scrolling shaft is hidden. Accepted traversal reveals the clipped shaft over the first 25 percent of travel, raises the cave mask over the descending puppet, and uses a restrained 96×58 px/34%-alpha dust burst behind the platform; ascent, cancellation, and reset hide the shaft again. This supersedes the exposed rectangular cutaway. `WorldIngressSite` captures the complete origin snapshot before presentation. Descent and return ascent use `OperatorPresentationRig2D`, a detached visual-only puppet that snapshots visible Operator body/equipment leaves while the live CharacterBody2D stays fixed with unchanged process/Z state. Completion, capture failure, cancellation, and teardown restore live visibility and free the puppet. The dedicated Underground mapper authors rails plus exactly three live records—descent landing, return exit, and encounter origin—and the exit itself replaces the former duplicate cave-mouth marker. Other ingress identities retain generic body-entry behavior.
- Moment Forge now includes `traversal/ash_bell_lift_exterior_descent`, a debug-fixture-backed six-keyframe comparison of the parked exterior, shaft reveal, cave-lip descent, deep travel, and restored parked state. Changed Ash Bell lift runtime, art, or design files route to this scenario through `--changed`.
- A Godot-native procedural ruin prop variant foundation now exists at `res://content/props/ruins/`: `ProceduralProp.tscn`, `PropDefinition`, `PropVariantLayer`, `PropVariantGenerator`, and a conservative palette shader assemble deterministic visual variants from authored base sprites, overlays, and rubble while keeping collision stable through authored collision scenes or simple authored collision footprints plus explicit occlusion bounds.
- Starter ruin prop definitions now exist for `obelisk`, `portal_ring_01`, `rotunda_01`, and `slab_01`, using the available moss/crack overlays and padded rubble/base sprites for immediate editor testing, with depth-sort, collision footprint, and explicit occlusion-footprint hooks enabled on the taller props.
- Procgen now has a decorative ruin prop placement slice: `ProcGenTilemap` spawns weighted `ProceduralProp` instances under `NavigationRegion2D/PropLayer` from `ruin_prop_spawn_set.tres`, using floor-cell filtering, wall/player/compound clearance, spacing checks, and deterministic tile seeds. Portal-ring ruin props now have a v1 paired teleport behavior: procgen guarantees two deterministic `portal_ring_01` endpoints when portal pairing is enabled, validates portal endpoints with a stricter clear-floor footprint, wall clearance, and local collision probe than normal decorative props, snaps portal endpoints to tile centers, and links them with cooldown-gated triggers inside the active tactical map. The portal ring’s front steps now use a raised platform-style collision and occlusion footprint so they read as a passable approach instead of a hard flat blocker. The current portal runtime also includes a 2.5D stair/platform impostor: the center lane remains walkable, the sides block, fake elevation ramps up toward the mouth, teleport only becomes valid at the top trigger, and the runtime can mirror that ramp for a north-side approach when the prop definition enables dual-sided access. Portal-ring collision now comes from a dedicated authored scene using the south-facing point-to-point side-zone rectangles converted from source-image pixel coordinates into bottom-center prop-local coordinates, and `ProceduralProp` can render an opt-in filled/outlined collision debug overlay from its rectangle collision shapes. `portal_ring_01` currently keeps that overlay disabled and uses a centered rectangular `161x24` platform trigger, with the ramp top width also expanded to `161`, so the top activation span covers the full visible portal frame instead of only the side-blocker gap. Portal occlusion now compares the portal source-image y=60 platform horizon against the operator's collision-foot y adjusted for fake visual elevation, so the operator remains in front until the visual feet cross the horizon. Tall non-portal ruin props still use explicit occlusion-footprint sorting based on their visual span.
- Ruin prop art prep is documented in `res://content/props/ruins/README.md`, including transparent ImageMagick padding commands for cropped PNGs and the bottom-center anchor convention needed after padding.
- Sprite ingest is routed through a manifest-driven intake pipeline at `res://content/sprites/_pipeline/`. Directional outputs now generate frame-by-frame horizontal counterparts by default for `e↔w`, `ne↔nw`, and `se↔sw` across all owner domains; explicitly authored counterparts win, while CLI `--no-mirror` and manifest `"auto_mirror": false` provide scoped opt-outs. Enemy and drone actors use the domain-owned canonical runtime tree `res://content/sprites/enemies/<owner>/runtime/<layer>/<action_group>/`; loose `res://content/sprites/<enemy>/` outputs are forbidden. Allied actors retain their owner-first runtime tree plus domain-prefixed compatibility outputs, while weapons, effects, vehicles, turrets, props, and items retain their specialized owner domains.
- A repo-local helper now exists at `custodian/tools/pipelines/generate_inbox_manifests.py`; it scans inbox PNGs, infers manifest JSON from canonical filenames and image dimensions, supports flat `items__<item_type>__<item_name>__<frames>f__<frame_size>.png` files, `props__harvesting_nodes__<node_type>__node__<state>__<frames>f__<frame_size>.png` files, enemy/drone/allied actor body/FX sheets, and hover buggy vehicle sheets, and then runs the existing ingest pipeline. `build_actor_spriteframes.py` recursively reads canonical domain-owned enemy strips without loose-root fallback, while allied builds may merge their compatibility roots, and writes actor resources under `res://game/actors/<domain>/<owner>/`.
- Hover buggy vehicle sheets are now pipeline-addressable from inbox filenames such as `hover_buggy__body__idle__omni__1f__256.png`, `hover_buggy__body__idle_start__omni__7f__256.png`, `hover_buggy__body__idle_loop__omni__6f__256.png`, and `hover_buggy__body__move__e__6f__256.png`; successful vehicle ingest writes to `res://content/sprites/vehicles/hover_buggy/runtime/` and runs `vehicle_runtime_import` to rebuild `res://game/actors/vehicles/hover_buggy_idle_frames.tres`.
- A dedicated aseprite staging path now exists at `custodian/content/sprites/_pipeline/aseprite/`, with `custodian/tools/pipelines/aseprite_inbox.py` moving exported PNGs into `_pipeline/inbox/`, normalizing incomplete filenames interactively, and optionally chaining manifest generation / ingest.
- Successful sprite ingests now archive the source PNG/JSON pair and delete the source PNG `.import` sidecar from the inbox so editor metadata does not linger as fake source art.
- The latest harvesting-node ingest pass populated compatible 96px runtime idle/depleted sheets for `blackwood_deadfall`, `exposed_alloy_vein`, `collapsed_machine_shell`, `fungal_resin_pod`, `broken_signal_relay`, `ruptured_capacitor_bank`, and `shattered_archive_terminal`; loose flat resource PNGs are retained as concept/source material until they are converted into runtime node strips.
- New sprite sheets should use the canonical `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png` naming convention, with manifests writing compatibility copies where legacy runtime paths still exist.
- Sprite ingest writes runtime outputs, normalized previews, logs, and archived intake files but does not stage or commit Git changes. Review the resulting worktree explicitly after non-dry-run ingest.
- Active art reference sampling now has a CLI utility at `custodian/tools/art/build_reference_samplesheet.py`; it scans runtime-facing tile, wall, floor, ruin prop, and environment prop PNG/WebP assets while skipping source/archive/pipeline/temp/preview folders, extracts deterministic non-transparent samples, and writes the current reference sheet to `custodian/content/reference/active_art_samplesheet.png` for design comparison.
- An offline wall tile extraction/composition pipeline now exists under `tools/tiles/`, using canonical source `custodian/content/tiles/walls/source/procgen_wall_modules_source.png` to generate procgen wall source modules, a packed source atlas, metadata, and composed previews under `custodian/assets/tiles/walls/generated/`.
- Procgen walls now use a generated fixed-grid wall bridge atlas: `tools/tiles/build_procgen_wall_atlas.py` converts extracted wall modules plus optional `32px`-tall passage strips from `custodian/content/tiles/walls/source/wall_passages/` and optional wall-top preprocessing from `custodian/content/tiles/walls/Wall_Tops.png` into `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.png` plus semantic mapping JSON, and `proc_gen_map.tscn` points wall rendering at TileSet source ID `12`. Passage-strip art is exported through `reference_passage_wall_coords` and can appear as deterministic visual variants on ordinary horizontal wall runs; this does not carve walkable openings or change wall collision.
- Destructible procgen wall collision removal is tile-scoped inside chunk bodies: breaking one wall removes only that tile's runtime shape, and full runtime collision rebuilds detach empty chunks before queue-free so replacements are not skipped.
- The generated Sundered Keep frontage remains production exploration and distant-destination presentation. A standard short fade enters the authored Shore Parish / Outer Wall Approach at `res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn`; another short fade crosses its readable checkpoint threshold into Front Gate, the first full Keep gameplay map. The playable-blackout bridge and full-screen occluded handoff are no longer production edge authority. Captured origin branches remain hidden and processing-disabled for the route session; failed entry restores the snapshot immediately, while successful traversal restores it only through the approach's world-return exit. Front Gate's authored backtrack exit uses a 144px arrival guard, and its mapper-authored `EntrySpawn` is approximately 137px inward from that exit.
- The older Route/Stage presentation prototype (`LevelStage`, `LevelRoute`, and `game/world/routes/sundered_keep/stages/`) remains disconnected and is not the live traversal authority. The live V1 authority is `route_traversal_manager.gd` plus registry JSON; the prototype must not regain destination instancing.
- Procgen wall collision authority is runtime-body based rather than TileSet-physics based: visible walls are grouped into deterministic `RuntimeWallChunk` bodies with exact per-tile shapes. Streaming reveal creates shapes incrementally, suppresses per-tile debug reconstruction, and coalesces full overlay/shadow/collision-safety/navigation rebuilds to a bounded interval or queue completion. Projectile contact position selects the exact destructible tile; the focused compaction fixture reduces 585 shapes to 28 bodies while retaining neighboring collision after one tile is destroyed.
- Operator combat is organized as profile-relative primary attacks plus a context-sensitive offhand secondary. Primary maps to fast melee/unarmed or ranged fire depending on loadout; the legacy `Shift+primary` secondary chord still requests heavy melee/unarmed. The actual offhand button (`aim_hold` / `attack_secondary`, right mouse or LT) now resolves by slot context: selected ranged primary holds primary ranged-ready, melee/unarmed plus equipped P-9 holds sidearm-ready, and melee/unarmed with empty or guard-focused offhand holds guard-ready so primary can parry from guard.
- A fast primary pressed during active dodge/roll movement buffers until the recovery boundary without cancelling movement or iframes. During explicit recovery it cancels recovery and skips the unarmed windup; ingested east/west `dodge_fast_attack_01` body/FX plus optional west cape then own the 11-frame combined presentation. Dodge cooldown is preserved and heavy/other attack gates retain normal timing. The transition emits `player_fast_attack_dodge_buffered`, `player_fast_attack_dodge_cancel`, and `player_fast_attacks_from_dodge_recovery` observability.
- Operator attacks now use `MeleeAttackProfile` resources for melee damage, range, arc, knockback, hit-stop, camera shake, cooldown, cancel timing, and phase movement; the old operator melee exports remain as deprecated fallbacks when a weapon profile is missing.
- Unarmed/Fists is now a first-class selectable combat profile at `res://game/actors/operator/unarmed_definition.tres`; it is selected with `F`, excluded from normal weapon cycling, toggles back to the last armed weapon, and owns canonical `unarmed_fast` / `unarmed_heavy` primary/secondary intents.
- Input bindings are intentionally split to support keyboard/mouse and Xbox twin-stick play: `WASD` / left stick move, mouse cursor / right stick aim, right mouse / LT offhand secondary, `M1` / RT primary fire or melee confirm, `Space` / B dodge, `E` / A interact, `Tab` or `I` / Y inventory, `R` / X reload, `Q` / D-pad up quick item, `Z`/`C` / D-pad left/right cycle items, `Esc` / Start pauses, and `M` / View opens map/objectives. Existing `attack_primary`/`attack_secondary` remain compatibility aliases for `fire_primary`/`aim_hold`; `Shift+M1` remains the melee/unarmed secondary chord. Runtime prompts should describe right mouse/LT as offhand secondary and derive concrete labels from `InputMap`.
- Operator selection state is simulation-owned (`using_unarmed`, `armed_weapon_index`, `last_armed_weapon_index`, `pending_weapon_selection`) and queued selection only applies from safe idle/walk/sprint states.
- The default HUD is essentials-first: operator health/stamina use compact header-style readouts, prompts/status plaques/minimap use reduced Black Reliquary footprints, and camera/aim/time/loadout/ammo/director/supply/button/power/cooldown diagnostics are consolidated into `res://game/ui/hud/debug_screen.tscn` instead of normal HUD labels. Opening the terminal suppresses legacy HUD labels, the minimap/crosshair, `gameplay_overlay` scenes such as `CustodianHUD`, and the debug screen until the terminal closes.
- The tactical minimap is now custom, live, and data-driven rather than addon-based: `ProcGenTilemap` and authored map providers such as `SunderedKeepMap` emit floor/wall terrain arrays and tile/world conversion methods, while `game/ui/minimap/minimap_panel.tscn` renders cached tactical geometry plus player/enemy/objective pips under the HUD `UI` CanvasLayer or inside the compact Black Reliquary frame.
- Minimap actor markers now separate hostile enemies from passive ambient creatures: hostiles remain red dots, while passive Shrumbs/ambient critters render with a distinct non-red marker on both HUD and terminal minimap instances.
- The legacy HUD minimap expands/collapses with `M` / `toggle_minimap_expand`; the embedded Black Reliquary HUD minimap stays compact and hides the nested minimap panel chrome. HUD, terminal, and Black Reliquary minimap instances render utility markers for command terminals, vehicles, and turrets from their runtime groups.
- The command terminal tactical map panel now reuses the same live custom minimap scene instead of the older contract-preview placeholder texture, while retaining terminal map hover/click conversion for placement workflows.
- The live inventory overlay under the HUD `UI` CanvasLayer is a compact Black Reliquary CUSTODIAN field ledger. `Tab` or `I` / Xbox `Y` opens a simplified `FIELD LEDGER` header with Status/Equipment/Ledger/History tabs and preserves the last-open page for the current play session. Black Reliquary Archive Glass now blurs, darkens, desaturates, cold-tints, and compresses highlights from the live world before the sharp menu frame renders. The Ledger has a counted `150px` classification rail, a lightly bordered smoked recovered-object register, and a `340px` inspection surface whose action stays pinned while only description/provenance may scroll; its `112px` art and identity text share a compact horizontal header. Real focusable filter and sort controls replace passive toolbar labels; Q/E or LB/RB cycle pages and prompt language follows the latest keyboard/mouse or controller input. Container-laid item cards use a responsive 2-4 column layout: `148x152` cards with `88px` art at desktop widths of at least `1500px`, `156x158`/`92px` at medium widths, and `164x164`/`96px` below `1152px`. At `1600x900`, eight ordinary records fit as four columns by two rows without register scrolling. Cards retain upper-right quantity badges, persistent gold selection, and separate cyan focus corners; selection scales art internally without moving its allocation. Status rows retain measurable initial content, its map contracts to 400x250 with a roughly 280px left panel at 1280x720, and all content remains above a dedicated 38px footer. Equipment is split between implemented active slots and Ledger-backed available equipment without speculative slots. Existing item art is alpha-cropped and nearest-neighbor repadded to canonical 128x128 runtime icons by `tools/ui/normalize_inventory_icons.py`. The Equipment page owns functional P-9 equip/unequip controls: a recovered sidearm remains carried and cannot claim the offhand action until equipped; unequipping returns it to the ledger and restores guard/parry. The UI reads `/root/InventoryManager` and refreshes from inventory/equipment signals; the older local `Inventory` resource remains compatibility-only. Resource/build-token simulation authority remains separate.
- Inventory item icons now render through dedicated `TextureRect` children so item-specific CanvasItem materials cannot affect button text or panel chrome. Blackwood alone uses the reusable `inventory_ember_spark.gdshader` through `blackwood_ember_spark_material.tres`: its amber pixels and nearby dark cracks pulse subtly, rare procedural sparks remain inside source alpha, and optional emission-mask support is available without requiring a mask. The inventory asset resolver now also finds existing resource icons under `content/ui/inventory/icons/resources/`.
- Operator visual testing now has a DevConsole-driven Knight skin override: `knight_skin on/off/status` swaps the body `SpriteFrames` to runtime slices built from `res://dev/test_sprites/Knight/*.png`, hides custom operator weapon/FX overlays while active, and leaves movement, collision, health, stamina, loadout, and combat simulation unchanged.
- `game.tscn` scene hygiene was tightened: `GameRoot` now starts at the world origin, the duplicate defense blaster is no longer stacked at the same local position, the HUD contract path points explicitly at `../World/ContractMap`, interaction prompts no longer overlap the supply-drop debug line, and the terminal scrim remains behind/before the panel so it blocks gameplay clicks without intercepting terminal controls.
- Debug console access: DevConsole addon (autoloaded at `/root/DevConsole`) toggles with `~` (tilde/backtick); commands include `debug_hud`, `show_cognitive`, `test_spawn`, `spawn_grunt`, `knight_skin`, `ui_status`, `toggle_minimap`, and `minimap_status`. `debug_hud` and F12 open the dedicated tabbed Godot-native debug screen. The former Dear ImGui F3 Director Console is removed; `DebugBus` and `DebugSnapshotCollector` remain read-only infrastructure.
- Operator animation state management is now deterministic enough for the combat baseline: the state machine tracks transition sequence and per-state elapsed time, attack states can explicitly re-enter, and attack completion is read from operator combat state instead of sprite playback.
- Operator light damage reaction now enters `hit_recoil` for a short `0.22s` stun window; while Fists are active, it resolves through the `unarmed_light_hitreact` profile animation.
- Operator Field Patch healing/restock V1 is live in `res://game/actors/operator/operator.gd`: `use_field_patch` is bound to keyboard `P`, starts with 1 carried patch out of a baseline max of 2, uses a 1.25s vulnerable commit window, slows movement to 35%, restores 35% max health only at commit, and preserves the patch if interrupted before commit. Damage, attack, dodge, reload, death, terminal/inventory/UI/runtime locks, and field-work input cancel the use before commit. Compact HUD health text reads `PATCH n/max` or `PATCHING x.xs` through `Operator.get_field_patch_status()`. Restock v1 is terminal/fabrication based: recipe `lattice_field_patch` costs `resin_clot` x2, `signal_filament` x1, and `capacitor_dust` x1, completes as an `operator_consumable` output after a short fabrication job, consumes resources only when the Operator is below carry cap, and grants through `add_field_patches(...)`; `res://game/actors/items/consumables/lattice_field_patch_pickup.tscn` provides rare emergency-cache pickup support that grants +1 patch below cap or fallback materials when full. Normal enemy health-potion drops and passive combat refill are not part of the live contract.
- Field Patch use presentation now has an explicit modular Operator runtime path. The modular builder can emit `field_patch_use_01` lower-body, upper-body, and upper-FX modules under `operator/runtime/modules/new_operator/*/actions/unarmed/field_patch_use_01/`; `update_operator_curated_resources.gd` registers them as `field_patch_use_{lower,upper,fx}` E/W animations, and `operator.gd` plays those layers only during the existing patch-use window. Healing timing, interruption, and count semantics remain unchanged, and missing generated SpriteFrames fall back to the previous locomotion presentation with a warning.
- Operator ordinary light hit recoil now atomically plays synchronized modular lower/upper five-frame N/S
  `idle_hitreact_01` layers, with the existing modular head joining when available. Facing at reaction start selects art;
  diagonals use nearest vertical art and E/W ties preserve the previous resolved vertical sector. Missing either required
  body layer falls back unchanged to the legacy full-body reaction, while heavy knockdown, death, and paired execution
  retain higher priority. Non-unarmed combat profiles still need dedicated reaction art.
- Fists/unarmed movement now defaults to modular lower-body runtime modules generated by `custodian/tools/pipelines/build_operator_modular_runtime.py` under `res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/`. The builder writes 8-way `idle_01`, `walk_01`, and `run_01` module strips and supports `action_01` as the preferred fallback source when authored idle/walk/run sheets are missing; because `action_01` source sheets do not exist yet, missing idle/walk directions currently fall through to available authored sheets or `run_01`, with the gaps tracked in `REQUIRED_ASSETS.md`.
- The operator scene now has a first layered modular rig for Fists movement/action separation: `ModularLowerBodySprite` and `ModularUpperBodySprite` use separate `operator_modular_lower_body_frames.tres` and `operator_modular_upper_body_frames.tres` resources generated from `res://content/sprites/operator/runtime/modules/new_operator/`. The lower body owns movement presentation (`idle_01`, `walk_01`, `run_01`) and resolves direction from movement; the upper body owns action/aim presentation and resolves direction from aim/action state, so the lower body can walk north while the upper body faces south. Fists idle prefers the modular lower/upper layer stack before the legacy authored-body stance fallback, so upper-body idle renders with lower-body idle. The legacy body sprite still runs as the timing/source-of-truth sprite for attack state, hit windows, portal arrival, ranged states, reloads, and non-modular fallbacks; it is hidden visually when modular layers cover the current unarmed state.
- Modular head presentation has a first live slice. Canonical `operator__modular_head__<head_profile>__<action>__<direction>__<frames>f__96.png` sheets route and build into `runtime/modules/new_operator/head/actions/<head_profile>/<action>/`; `operator_modular_head_frames.tres` feeds `ModularHeadSprite`. The default `hooded` profile currently has only five-frame south idle coverage, synchronized to the modular upper-body idle. Missing head action/direction coverage hides only the head layer and never invalidates body playback or gains simulation authority.
- Unarmed/offhand defense now uses the existing block state path for held guard and primary-from-guard parry. With no sidearm equipped, right mouse/LT enters guard-ready immediately and becomes fully active after a short delay; pressing primary while guard-ready starts the parry windup/active/recovery sequence. A successful front-facing parry cancels the enemy hit, staggers/shoves the attacker through `apply_parry_stagger(...)`, refunds stamina, and opens a short fast-attack counter window. Held guard drains stamina and reduces incoming damage to chip damage instead of fully negating it. Block entry/hold/hit reaction use the modular lower/upper body stack; parry now plays the generated `parry_01` lower/upper modules and paired upper-FX parry strip at 12 FPS before falling back to block clips if those curated entries are missing. East/west post-success recovery now plays dedicated `success_01` lower/upper/upper-FX modules, with west generated by frame-flipping the east source. Successful parries still route their burst through the clearly labeled `PLACEHOLDER_unarmed_parry_success_fx*` modular upper-FX animations until dedicated success FX art replaces the placeholder source.
- Modular sidearm source has a canonical four-layer action contract: `operator__modular_lower_body__sidearm__*`, `operator__modular_upper_body__sidearm__*`, `operator__weapon__sidearm_pistol__*`, and `operator__modular_upper_fx__sidearm__*`. Shared-inbox ingest routes all four through `operator_modular_runtime`, and `build_operator_modular_runtime.py` emits stable lower-body, upper-body, sidearm weapon-layer, and upper-FX action modules under `res://content/sprites/operator/runtime/modules/new_operator/`. Draw/fire are live for NE/NW/SE/SW, normalized into `5f__96` runtime strips; cardinal/recover/reload coverage remains required. The same builder now ingests the supplied two-handed ranged-ready E/N/W stance layers into stable upper-body and ranged-weapon modules while the reusable lower-body locomotion stack stays on the existing 8-way `unarmed_{idle,walk,run}` modules. The modular runtime builder also whitelists `modular_wardrobe_cape` source sheets instead of filtering them out with the other unarmed `fast_*` action sheets, so optional cape layers can flow into the runtime module tree. Primary two-handed ranged-ready now plays the modular `ranged_2h_aim_modular` lower/upper/weapon raise once on entry when coverage exists, with an optional `ModularCapeSprite` cape layer sourced from current wardrobe cape art, then returns to the looping `ranged_2h_stance_modular` upper/weapon stance while movement reuses lower-body locomotion. Ranged-ready composition is ownership-split: lower body is movement-owned and reusable across loadouts after the raise, upper body plus weapon layers are loadout-owned, FX/cape layers are action-owned optional presentation, and the legacy full-body ranged sprite only renders when the modular ranged upper/weapon stack is unavailable. Primary two-handed ranged fire remains presentation-only and preserves projectile/ammo/heat/noise behavior.
- Modular lower idle now consumes authored lower idle source for N/E/SE/S/SW/W, with NE/NW still falling back. Upper locomotion currently has true authored run sources for N/E/SE/S/SW/W; upper run NE/NW and all upper idle/walk clips are generated fallbacks until production upper-body sheets are supplied.
- Unarmed south fast attack is wired as `unarmed_attack_fast_down` from canonical `operator__body__unarmed__fast_01__s__6f__96.png`; this replaces the earlier temporary fallback to the clean melee-light body sheet.
- Unarmed east/right fast attack was refreshed to the canonical `5f` body strip `operator__body__unarmed__fast_01__e__5f__96.png`, and unarmed west/left fast attack is now wired as `unarmed_attack_fast_left` from `operator__body__unarmed__fast_01__w__5f__96.png`.
- Unarmed lower-body run now has 8-way module playback: `unarmed_run_{down,down_right,right,up_right,up,up_left,left,down_left}` all resolve through `runtime/modules/new_operator/lower_body/locomotion/run_01/`.
- Unarmed south fast recovery is wired as `unarmed_attack_fast_recovery_down` from canonical `operator__body__unarmed__fast_recovery_01__s__2f__96.png`.
- Unarmed north fast recovery is wired as `unarmed_attack_fast_recovery_up` plus `unarmed_attack_fast_recovery_fx_up`; east fast recovery was refreshed from a 3-frame source and now plays at `15 FPS` to keep the same short recovery timing.
- Operator melee impact presentation no longer layers the legacy procedural
  `melee_swing.tscn` gold bar over attacks with an active authored
  `MeleeFxOverlaySprite` or modular upper-FX animation. The generic swing
  remains a fallback for attacks that genuinely lack authored attack FX;
  contact sparks, damage, hitstop, camera response, and impact audio are
  unchanged.
- Unarmed east and west fast recoveries are wired from canonical 3-frame sheets; west uses dedicated `unarmed_attack_fast_recovery_left` playback instead of mirroring the east recovery.
- Unarmed lower-body walk and idle now also have 8-way module playback. Current true walk source coverage is east/west only, and true idle source coverage is south only; the generated module strips make defaults stable while the missing source art is requested.
- Unarmed west stance is wired as `unarmed_stance_left` from canonical `operator__body__unarmed__stance_01__w__6f__96.png`.
- Operator ranged east stance is refreshed as `ranged_2h_stance` from canonical `operator__body__ranged__stance_01__e__12f__96.png`.
- Operator idle facing now preserves the last movement direction after stopping; mouse motion or keyboard aim updates the visual idle facing explicitly, while attacks still resolve from combat aim.
- Unarmed heavy attacks are wired for all four cardinal directions: east/right body+FX, west/left body+FX, north/up body+FX, and south/down body+FX. North uses canonical 8-frame sheets at `11.5 FPS`; east, west, and south use canonical 7-frame sheets at `10 FPS`.
- Unarmed death is wired as `unarmed_death` from canonical `operator__body__unarmed__death_01__omni__6f__96.png`; the operator death handler uses it only while Fists are active and falls back to generic `death` otherwise.
- `AnimationResolver` now resolves authored `_left` clips before mirrored right fallbacks when facing west, and operator playback disables horizontal flip for authored-left melee animations.
- Sprite runtime directories should retain only the currently mapped sheet for a given owner/layer/action/variant/direction once the replacement has been ingested, imported, and verified; `_pipeline/archive/` keeps the older source/intake history.
- Melee target readability now prefers enemies inside the current melee/Fists strike range and facing arc, and the target ring switches to a thicker green pulse when the selected enemy is actually hittable by the current preview strike profile.
- Light attack has been removed from the live operator attack path; primary melee/Fists input now resolves to fast attack by default, and the old `attack_light` state/profile/runtime frame references were stripped.
- Fast melee/unarmed attacks use a shorter `0.22s` cancel start, `0.10s` recovery, `1.35x` playback scale, and clip-length-derived runtime duration so loaded fast attack sheets no longer wait on the old fixed `0.42s` timing.
- Fists/unarmed fast attack now keeps the legacy body `AnimatedSprite2D` as the hidden timing/hit-window source while the visible modular rig plays true lower/upper body phases when coverage exists. Windup maps to modular `fast_windup_01` lower+upper, strike maps to modular `fast_strike_01` lower+upper plus optional `upper_fx fast_strike_01`, and recovery maps to modular `fast_recovery_01` lower+upper. Missing required body coverage falls back per phase/direction to the previous legacy path; missing strike FX logs once and does not block modular body playback. Runtime-dedicated baked action sheets still live under `res://content/sprites/operator/runtime/actions/unarmed/fast_attack/`, while layered fast-attack modules now live under `res://content/sprites/operator/runtime/modules/new_operator/{lower_body,upper_body,upper_fx}/actions/unarmed/fast_attack/`. Source modular parts remain under `res://content/sprites/operator/new_operator/modular/fast_attack/`. Current source/runtime coverage includes all 8 directions for lower/upper windup, strike, recovery, and upper-FX strike; only optional south windup FX remains tracked in `REQUIRED_ASSETS.md`.
- Latest operator melee fast moving attack layer sheets have been ingested through the sprite pipeline as additive runtime assets: body, weapon, and FX outputs were preserved as corrected `9f` east-facing strips after source dimensions showed `864x96` despite `7f` inbox filenames. They are not yet wired into active modular playback.
- Additional sprite pipeline ingest added an `8f` east-facing operator melee moving-fast body/weapon layer pair, refreshed unarmed east fast FX, and added portal-ring teleport FX runtime sheets. Portal FX are now canonically prop-owned under `res://content/sprites/environment/props/portal_ring/runtime/fx/`, with legacy compatibility copies under `res://content/sprites/effects/runtime/portal_ring/`; portal idle is a `6f` `161x98` strip, while activation and arrival are `12f` `161x98` strips.
- Baked ranged 2H horizontal sprint/run strips remain available as legacy fallback assets, but primary ranged-ready movement no longer requires `ranged_run_*` or `ranged_walk_*` full-body clips. The active modular contract composes lower-body movement from the reusable `unarmed_{idle,walk,run}` lower-body modules while ranged upper-body and weapon layers follow aim direction; if that ranged upper/weapon modular stack is unavailable, the runtime hides modular lower legs and falls back to the legacy full-body ranged presentation.
- Portal-ring teleport animation playback is wired in `PortalTeleporter`: each paired procgen portal builds one `PortalStateSprite` from the prop-owned portal-ring idle, activation, and arrival strips. Portal definitions can hide their static base sprite so idle is the default visible state, activation replaces idle at the source, arrival replaces idle at the destination, and both portals return to idle without stacking a second portal render over the base art. The portal FX center remains prop-local `(0,-65)`, while `portal_ring_01` uses prop-local `(0,-54)` for the platform horizon and teleport trigger, matching visual pixel `(80,60)` in the `161x98` portal frame. Platform portal arrivals now use the authored local arrival offset below the destination trigger instead of rotating the landing point toward the source portal, preventing immediate re-teleport loops after arrival. Teleport resolves on activation frame 10 by default, locks the operator in place during the activation commitment window so they cannot walk out of the portal zone, uses a shorter `0.50s` destination arrival delay, and the portal platform impostor can mirror a north-side ramp for dual approach access when the prop definition enables it.
- Portal arrival now also cues the operator body: the ingested full-body `operator__full_body__unarmed__arrival_01__s__13f__96.png` sheet is rebuilt into `operator_runtime_frames.tres` as `unarmed_arrival` and `unarmed_arrival_down`, and `PortalTeleporter` calls `play_portal_arrival_animation()` after relocating the operator. The one-shot forces a south-facing unarmed full-body clip (arms baked in) and temporarily suppresses normal locomotion/input animation plus weapon overlays until the clip finishes. The superseded 9-frame body-only arrival sheet was removed from runtime; `_pipeline/archive/` retains both intake histories.
- Melee impact sparks resolve their contact point before enemy knockback and set world position after parenting, so hit feedback should land at the struck contact point instead of drifting with post-hit movement or parent transforms.
- Projectile impact sparks now follow the same rule: bullets, tracers, energy shots, and missiles snapshot the contact point before damage/knockback and assign FX world position after parenting.
- Generic projectile presentation is now configurable without duplicating projectile physics: `bullet.tscn` uses an `AnimatedSprite2D` travel visual while `bullet.gd` still owns deterministic movement, swept collision, terrain-ballistics checks, falloff, team filtering, and range expiry. Shared bullets default to the existing generic `impact_spark.tscn`, so drone/turret callers produce impact feedback even without weapon-specific data; weapon data can replace it with projectile travel `SpriteFrames`, animation name, scale, and a one-shot impact scene. `game/vfx/one_shot_animated_vfx.gd` owns animation-finished cleanup and optional impact orientation. Carbine MK1 now routes through the existing generic bullet scene with `res://assets/resources/vfx/weapons/carbine_mk1/carbine_mk1_projectile_travel_loop_01_frames.tres` and `res://game/vfx/weapons/carbine_mk1/carbine_mk1_impact_hard_vfx.tscn`, and `visual_effects.tracer` is corrected to true. The currently present Carbine VFX PNGs live under `res://content/sprites/effects/weapons/carbine_mk1/` and do not match the requested final dimensions (`96x32` travel and `576x96` impact currently, versus requested `144x16` and `384x64`), so validation warns until final production sheets are supplied. Flesh/shield/material-specific impact routing remains deferred.
- Ranged firing now has a physics-alignment and directional terrain pass: operator muzzle obstruction is checked before spawning a shot, blocked muzzles create an impact at the near wall instead of firing through it, bullets/tracers sweep their movement segment to avoid tunneling, and shared bullets consult terrain edge metadata before generated terrain collision is treated as authoritative. Elevated shooters can fire down/out over `ledge_fire_over`; low-to-high ledge fire, `wall_high`, and `drop` remain blocked. Generic world props and combat targets still use physics collision. Ranged weapon socket rotation remains clamped by aim-state band until full authored stance/socket assets exist. Modular primary two-handed fire and modular sidearm fire route projectile spawn, muzzle flash, obstruction, heat/noise origin, and debug checks through presentation-aware muzzle offsets instead of the hidden legacy barrel socket.
- Ranged-ready V1 keeps movement available and grants aim-direction facing to the active ranged presentation. The P-9 starts progression-locked and equipment-gated: the Sundered Keep locker adds `p9_sidearm` to carried inventory, but melee/unarmed offhand secondary continues to route to parry/guard until the player equips it in the Equipment page. Equip-time `Operator.grant_sidearm(...)` initializes pistol ammo and visuals; unequip-time `remove_sidearm()` disables the fallback. The inventory ledger resolves the production P-9 portrait/card art, and the HUD has a dedicated top-left loadout frame for the active primary plus a smaller P-9 badge. An actively selected ranged primary retains priority. Its four-diagonal modular draw/fire stack holds the final complete draw pose while ready. Right-stick aim preserves last aim direction at neutral. Selected two-handed ranged presentation uses `relaxed_01`, forward `aim_01`, held `stance_01`, repeated `fire_01`, return to stance, and faster reverse `aim_01` lowering. Primary fire no longer bypasses ranged-ready; held/pressed fire is accepted at the configured 70% raise threshold. Dodge interrupts and clears a raise/lower presentation instead of being visually blocked by it.
- Successful parry drops guard quickly (`parry_success_recovery_sec` is `0.03s`) and preserves the release/repress guard rule. Parried `enemy_grunt` presentation is explicit `critical_open_enter_s -> critical_open_hold_s -> critical_open_recover_s`, with BREACH/countdown owned through enter/hold and cleared on reservation or expiry. A valid primary follow-up atomically reserves the enemy, selects the matched S/E/W semantic Operator body, Operator FX, and victim animations from approach direction, aligns the pair on one shared root, and drives them from a direction-specific schedule: the south fallback remains eight nonuniform frames while east/west use the new matched twelve-frame strips. Vertical approaches fall back to the authored south composition; layers are never independently mirrored. Damage is enemy-authoritative and exactly once on source frame 5 (runtime index 4), followed by a 110ms paired contact freeze; nonlethal completion enters `crit_recovery_s`, lethal completion preserves death handling, and unified cancellation restores both actors after the authored final frame. Legacy critical animation names remain aliases only.
- Combat feel direction is locked around `INPUT -> ATTACK STATE -> FRAME WINDOW -> ARC/RANGE HIT RESOLUTION -> RECOVERY -> CONTROL RETURN`; fast/heavy primary-secondary parity is the next tuning baseline after sprite pipeline loose ends are closed.

## Active Agent Workflow

- Agent task packets are now risk-based, optional planning/handoff artifacts: skip narrow low-risk work, use the compact default when durable context helps, and expand it for high-risk or multi-session work.
- Required production asset requests are tracked only in root `REQUIRED_ASSETS.md`; `design/00_meta/REQUIRED_ASSETS.md` is a deprecated forwarding notice and must not contain mirrored entries.
- The command terminal now has a licensed two-font runtime hierarchy under `res://content/ui/fonts/`: IBM Plex Sans Condensed drives the 22px title plus 11/12px section/navigation/action labels, while IBM Plex Mono Regular/Bold drives 10-13px status, body, log, Fabrication, and 16px command-input text. `ui.gd` loads all three defensively, applies semantic label/button/rich-text helpers in both terminal theme passes, ellipsizes bounded buttons/labels, and keeps Fabrication horizontal scrolling disabled. Opening the terminal forces a visible mouse pointer, restores the prior mode on close, and orders the modal scrim before the panel for reliable button/link hit testing while still blocking gameplay input. Missing font assets use the default Godot font and emit a `DevObservatory.mark_warning` entry with the missing paths so the issue appears in the game-time log/session export. `terminal_typography_smoke.gd` verifies imported font ownership, hierarchy sizes, Fabrication row/detail/filter density, flat-row labels, ellipsis, and scroll policy.
- The Ash-Bell / Forlorn-Ritualant packet is `custodian/docs/ai_context/task_packets/ASH_BELL_FORLORN_RITUALANT.md`; its historical procgen-footprint lane is superseded by `design/05_levels/FORLORN_RITUALANT_UNDERGROUND_MIGRATION.md`. Follow-up encounter work must preserve authored-route ownership and must not restore generic special-room insertion.
- Autonomous combat drone runtime authority lives in `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md` and implementation notes live in `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES_CODE.md`; the older task packet is archived under `custodian/docs/ai_context/task_packets/archived/`. Runtime V3 is implemented with animated allied droids, Operator/order-point anchors, and deferred production acknowledgement audio/art expansion, repair/redeploy, and terminal command UI.
- Task packet template: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`.
- Active packet directory: `custodian/docs/ai_context/task_packets/`.
- Validation recipes now live at `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Reusable prompt templates now live under `custodian/docs/ai_context/prompts/`.
- Agent workflow automation candidates are prioritized in `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`.
- Ask-specific agent tool routing is tracked in `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md`; its first covered surface is modular Operator asset audit/review tooling.
- Operator modular production tooling now includes a JSON coverage contract, a report tool, a generalized action
  preview compositor, and a new-character scaffold/checklist helper. These tools inspect or plan existing
  pipeline assets; they do not create a second sprite hierarchy or register runtime playback states.
- First workflow packet: `custodian/docs/ai_context/task_packets/VALIDATION_RECIPES.md`, covering validation recipes and prompt-template cleanup.
- Fabrication/resource balance checks can be rerun with `python custodian/tools/balance/fabrication_balance_pipeline.py --seeds 100`; review `reports/fabrication_balance/proposed_changes.json` before applying any runtime recipe or drop-table changes.

## Current Runtime Focus

- Modular Operator facing is state-owned: ordinary locomotion keeps upper/lower facing together, while ranged-ready, sidearm-ready, parry/guard, or a directional action grants aim/action direction to the action stack. For primary two-handed ranged-ready, lower-body locomotion stays movement-owned on the reusable `unarmed_{idle,walk,run}` modular clips while upper-body and weapon layers follow aim direction independently. Modular sidearm draw/fire lower, upper, pistol, and FX layers are live for NE/NW/SE/SW. The Carbine phase-1 hybrid contract now loads generated per-animation/per-frame grip, support, muzzle, ejection, angle, and draw-order metadata through `operator_weapon_socket_library.gd`; directional aim sprites for all 8 directions are ingested and the reticle consumes read-only aim accuracy. Camera aim zoom/lead composes a 1.07 zoom multiplier and 32px directional lead with existing shake/bounds/framing.
- Sidearm primary input during draw/fire recovery is now buffered once and consumed after the held pose/cooldown becomes ready; held sampling no longer floods `sidearm_not_held`. Ranged requests now have explicit fired, muzzle-blocked, failed, cancelled, and pending accounting, including death/zero-direction/projectile-creation cancellation reasons. Observatory damage/healing/chip amounts are cumulative across event-buffer wrapping, and post-death exports retain last-live weapon/ammunition/stamina context. Procgen exports generation/map/wall-body/shape counts, global node/physics/collision peaks, and loaded branch/root counts. Runtime wall bodies are chunk-compacted with per-tile shape/destruction authority; merged rectangular shapes remain deferred.
- World atmosphere 2D shader is live: `world_atmosphere_2d.tscn` runs a fullscreen post-process pass under the UI, the `WorldLightingDirector` propagates contract planet profiles into runtime lighting, and `world_atmosphere_smoke.gd` verifies live scene wiring, shader/profile propagation, foliage uniforms, and representative light rigs. Additional authored level-specific profiles and manual visual/performance tuning remain deferred.
- Combat Resource Feedback Milestone A is complete-v1. Milestone C (hit taxonomy) Phases 1-2 are live: `CombatConstants.HitStrength`/`DamageType` enums are defined in `combat_constants.gd`, all damage sources (melee, projectiles, defense turrets, combat system) now pass `hit_strength` through `attack_context` or direct `take_damage()` params, and `enemy._apply_reaction()` branches on hit strength with INTERRUPT always causing flinch, heavy hits always flinching, and `resists_light_flinch` (marine only) presenting an armor-deflect visual instead of movement interruption. Phase 3 presentation is partially live: unblocked HEAVY hits use the authored E/W full-body knockdown plus synchronized FX, while LIGHT hits retain short recoil. Observability counters track light/heavy/interrupt player hits taken and flinch/stagger/crit/interrupt/armor-deflect enemy reactions. Remaining milestones: finish Phase 3 guard-break/cooldown feedback, then riposte and VFX/audio polish.
- Forest Shrumb v1 is wired into ambient spawning through `AmbientCritterManager`; the next decision is whether cognitive values should surface in HUD beyond pickup popups/logs.
- Previous immediate task: validate profile-backed Fists/melee fast/heavy combat in play after removing the deprecated light attack path.
- Terminal page coverage is largely complete; remaining work is richer live data, tighter layout polish, and code modularization.
- HUD/minimap stability pass: terminal input connection paths are null-guarded, the dedicated debug screen now toggles from `debug_toggle` or raw F12, and the custom minimap no longer redraws every frame or rebuilds its map texture on every individual tile change.
- Planet/runtime coupling is active and should be preserved when adjusting procgen or contract generation.
- Procgen runtime handoff wiring now explicitly snaps the world camera to the operator spawn and rebinds navigation to promoted procgen tilemaps. Camera clamping normally uses procgen bounds, but connected authored maps can now provide their own `get_camera_bounds()` override. Manual middle-mouse camera drag can temporarily disable follow, and the camera now restores Operator follow on normal movement input so play cannot remain stranded in pan mode without a bound follow-toggle action.
- Operator mouse aim now resolves through the active world camera path first, reducing procgen handoff desync risk.
- Procgen streaming now batches navigation rebuilds around reveal completion instead of rebuilding navigation every reveal frame during world bring-up.
- Vehicle enter/exit prompt authority now routes through `PlayerController` first so the HUD can surface vehicle interaction prompts without depending on the operator node alone. While piloted, `PlayerController` sends movement/actions to `PilotableVehicle`; while unpiloted, the Operator keeps native control.

## Legacy Scope

- `python-sim/game/` and `python-sim/custodian-terminal/` remain preserved legacy reference only.
- Legacy Python terminal contracts are not runtime authority.
- Legacy AI tracker files under `python-sim/ai/` are historical reference, not the active update target.

## Active Gaps

- Enemy marine heavy dash still needs production directional body strips, matching directional FX overlays, and a five-part sound stack. V1 gameplay is live with the east body/FX fallback, but `REQUIRED_ASSETS.md` now tracks the full `N/NE/E/SE/S/SW/W/NW` asset target plus minimum `E/W/NE/NW/SE/SW` coverage.
- FABRICATION now deploys both `turret_basic` and the first bounded structure, `barricade_light`, through the existing scene-wired placement surface. Light Barricade fabrication produces a Ready Build, selected-work-order PLACE prefers its matching token, valid placement consumes exactly one token and creates an 80-HP collision obstacle, and invalid placement preserves the token. This remains a small tactical deployable slice, not freeform base building. Remaining work is richer filtering/sorting polish, deployment bridges beyond these two placeables, and future command/layout polish.
- Compound Infrastructure Powered Fabricator Milestone 1 is live. `InfrastructureRegistry` tracks structures and typed services and exposes versioned capture/restore; reusable generator, consumer, storage, and service components register independently with the compatible sector-oriented Power system. The authored `POWER` sector remains the first generation source, while a prebuilt Field Fabricator requests 10/25/40 power and scales `FabPipeline` progress through its effective `FABRICATION` service. Recipe `capacitor_bank_mk1` produces a Ready Build; the existing placement surface temporarily validates and commits it as a timed foundation, preserves the token on rejection, consumes exactly one token on success, and commissions damage-scaled +250 reserve storage. POWER/terminal snapshots include registered infrastructure demand and capacity. Registry persistence round trips without duplicate structures in focused validation, but it is not yet connected to a project-wide save manager because no global save authority currently exists.
- ARRN is runtime-complete for the documented V1 loop but still uses primitive relay visuals and text-heavy terminal panels; production relay art/audio, save/load persistence, and a dedicated ARRN terminal/minimap panel are future polish.
- Some terminal pages still use placeholder or lightly-derived summaries instead of full live runtime controls/data.
- Forest Shrumb cognitive modifiers are exposed as getters only; player movement, combat feel, enemy accuracy/tracking, instinct actions, and full inventory UI are intentionally not integrated in v1.
- Terminal page rendering still lives largely inside `custodian/game/ui/hud/ui.gd`; command routing, snapshot aggregation, and preview boundaries have been split, but page renderers/theme resources still need follow-up extraction.
- Observatory/telemetry is only a first slice. It does not yet render world-space heatmap overlays, persist history to disk, drive terminal-facing history views, or provide an abstract background simulation tick. Dormant physics suppression is live; background throttling awaits that ownership path.
- The project still exits headless validation with existing object/resource leak warnings that have not yet been cleaned up.
- Broader infrastructure depth, project-wide save/load wiring, a dedicated construction placement controller/zones, production structure art, and full long-horizon base systems remain incomplete relative to full doctrine scope.
- The remaining procgen handoff gap is live runtime verification: camera bounds, cursor aim, reachable anchors, and enemy navigation still need an end-to-end boot test in Godot.
- Terrain Builder V1 now has explicit elevation and mountain-cliff TileSet sources and smoke coverage for those source IDs. Remaining elevation gaps are dedicated layer separation, movement/pathing enforcement beyond current spawn/prop filtering and contract scoring, and final in-game visual readability tuning.
- The gothic compound connected map is a first authored destination slice using the reusable blueprint generator. Main tactical-map TileMapLayer adapter integration, full procedural gothic room assembly, save/load persistence of visited submaps, encounter composition, and minimap specialization remain future work.
- The Sundered Keep connected map is an authored destination slice whose Front Gate now uses `sundered_keep_main_overlay.png` as its production visual base. `sundered_keep_front_gate_large.json` retains gameplay/state authority while its static generated floor, edge, wall, prop, placeholder, and prefab ops are archive-only. The initial production overlay is intentionally sparse: the stateful Return Mooring module, animated Main Gate and Great Hall door, underpass/roof presentation, command cache, siege objects, and marine encounter remain; future decorative floor/wall/prop additions come only from explicit `mapper_placements`. Collision rails, elevation, markers, interactions, and siege behavior remain unchanged. The local siege still tracks the three enemies in its required opening wave; clearing that wave secures the encounter, stops its pressure timer, and prevents further objective damage even if timed reinforcements were spawned.
- Vehicle content is still art-incomplete: the hover buggy idle and horizontal movement loops are runtime-ready, while firing, damage, and destruction animations still need final source assets.
- Additional ruin prop definitions and production chip/dirt/vine/highlight overlays still need to be authored under `custodian/content/props/ruins/data/prop_definitions/`, `extracted/`, and `overlays/`; the first moss/crack-driven test definitions and procgen placement are available.
- Compound room template content is incomplete: `default_compound.json` references `hangar_large`, `hangar_small`, `corridor_h`, `corridor_v`, `storage`, and `landing_pad`, but only `command_post.tmj` exists today. Missing `.tmj` templates are tracked in `REQUIRED_ASSETS.md`.
- The sprite pipeline has automated post-process hooks for operator curated body outputs, modular Operator outputs, allied actor body/FX `SpriteFrames`, vehicle runtime resources, and enemy runtime import. Canonical manifests support square `__96` frame tokens and rectangular `__156x96` tokens, validating strip width against the declared frame count and generating `[width, height]` metadata without hand-authored JSON. Modular Operator inbox PNGs named `operator__modular_*` now route into `res://content/sprites/operator/new_operator/modular/`, run `build_operator_modular_runtime.py`, and refresh the live modular `SpriteFrames`; modular dodge source names route into the `dodge/` bucket. The generic `ingest.py` launcher also accepts `--build-operator-runtime` to rebuild already-authored modular source after a successful ingest, including dry-run and superseded-cleanup propagation. The builder emits supplied full dodge body/FX strips under `res://content/sprites/operator/runtime/actions/dodge/`, supplied E/N/W ranged stance layers under `res://content/sprites/operator/runtime/modules/new_operator/{lower_body,upper_body,ranged_weapon}/actions/ranged_2h/stance_01/`, and supplied unarmed fast-attack modular phase sheets under `res://content/sprites/operator/runtime/modules/new_operator/{lower_body,upper_body,upper_fx}/actions/unarmed/fast_attack/`. The `custodian/tools/operator/operator_ingest.sh` wrapper is the thin focused Operator ingest entrypoint and is exposed as `opingest` by `tools/custodian_aliases.sh`: default dry-run, `--apply` for inbox manifest generation, modular runtime build, Godot import, curated SpriteFrames update, modular layer smoke, and contract-report output. Full-body split dodge drops remain supported as optional compatibility assets. Simple non-Operator actors should use canonical `body`/`fx` strips and `build_actor_spriteframes.py` rather than the Operator modular pipeline.
- Modular Operator inbox routing now accepts all documented modular layers, including wardrobe cape and compatibility `modular_body_lower` / `modular_body_upper` names. The preferred naming contract is `operator__<modular_layer>__<loadout>__<action>__<direction>__<frames>f__<frame_size>.png`; block/defense and other generic actions are grouped by action family in the source tree and normalized into stable runtime modules under `operator/runtime/modules/new_operator/<layer>/actions/<loadout>/<action>/`. Explicit loadout/action names win over legacy short names when both exist. Source PNGs already in `new_operator/modular/` are rebuilt directly with `build_operator_modular_runtime.py`; they do not need to be moved through the inbox. Unarmed guard/block is live on the modular stack, and held guard movement now disables sprint, applies `block_move_multiplier`, reuses modular lower `unarmed_walk`, and keeps the modular upper block-hold loop. New live playback states still require deliberate Operator state-machine and curated-resource wiring.
- Operator modular production coverage is now inspectable with `custodian/tools/validation/operator_animation_contract_report.py`
  against `custodian/tools/validation/contracts/operator_modular_core.json`. General QA composites are produced by
  `custodian/tools/pipelines/operator_action_preview.py` under `custodian/animation_review/`, while future
  character art requests can be scaffolded under `content/sprites/_pipeline/requests/<owner>/` with
  `custodian/tools/pipelines/scaffold_character_contract.py`.
- Sprite ingest now supports opt-in `--remove-superseded` replacement cleanup. It removes only canonical sibling outputs in the exact destination directory whose semantic filename matches through direction and differs by frame-count/frame-size suffix, removes matching `.import` sidecars, and propagates into generated modular Operator runtime modules. Archive/history and distinct named variants remain untouched.
- The enemy variant system is a first runtime slice only: wolf profiles and sheet slicing are live, but beast-pack alpha extraction, Aseprite JSON rebaking, overlays, dedicated wolf scene structure, and the visual QA lab remain follow-up work.
- The grunt runtime now uses the newer 8-frame east death with west mirroring, directional E/W flinch with south body/FX fallback, and improved 11-frame E/W stagger. Directional idle beyond south, north-facing run/melee/FX, and broader death/flinch coverage remain future asset/runtime work.
- Melee combat still needs profile-data consolidation: light/fast/heavy timing, active frames, recovery, range, arc, damage, knockback, hit stop, camera impulse, and the new movement profile values are only partially centralized.
- Unarmed runtime body animation slices are still art-incomplete. Missing production sheets should be supplied under `custodian/content/sprites/_pipeline/inbox/` using canonical names such as `operator__body__unarmed__idle_01__s__?f__96.png`, `operator__body__unarmed__walk_01__s__?f__96.png`, `operator__body__unarmed__fast_01__s__?f__96.png`, and `operator__body__unarmed__heavy_01__s__?f__96.png`.

## Asset Source Cleanup

- A persistent generic runtime-ready asset intake now lives at `custodian/asset_drop/runtime_ready/`. Already organized assets can be dropped under its `inbox/` using a path that mirrors `res://content/`, or routed with an explicit `.runtime.json` sidecar. `custodian/tools/pipelines/runtime_ready_assets.py` provides non-mutating dry-run, conflict-safe apply, explicit replacement, immutable source archiving, JSON receipts, and an optional Godot import pass. Specialized sprite sheets that need parsing or rebuild hooks continue through `res://content/sprites/_pipeline/inbox/`.
- Content directory stabilization now has a first migration pass: `res://content/README.md` documents stable content domains, `docs/ASSET_LAYOUT_CONVENTION.md` defines duplicate/migration safety rules, and `custodian/tools/validation/content_asset_audit.py` reports loose content-root files, loose sprite/tile-domain files, unregistered quarantine files, and exact duplicate groups. The loose Road of Witnesses map now lives under `res://content/levels/hub/`; loose terminal/operator/enemy-scout/tile source files now live under owner-specific `source/` folders; and prior `res://content/unregistered/` vault art now lives under `res://content/props/gothic/vault_dressing/source/unregistered/` for later manifest promotion.
- A canonical `content/_aseprite/` directory now exists as the single home for all `.aseprite` and `.ase` source files, mirroring the content tree.
- `tools/aseprite/sweep_aseprite.sh` — one-time sweep to move all 213 existing `.aseprite` files into `_aseprite/` (run with `--apply --git`).
- `tools/aseprite/watch_aseprite.sh` — optional inotify daemon for instant move-on-save.
- `.githooks/pre-commit` — activated via `core.hooksPath = .githooks`, auto-sweeps `.aseprite` files before every commit.
- Updated `docs/ASSET_LAYOUT_CONVENTION.md` with the new convention.
- See `docs/ASSET_LAYOUT_CONVENTION.md` § "Aseprite Source File Convention" for full details.

## Documentation Status

- Elevated procgen presentation is live: deterministic `ASCENT_FIELD` floor authority configures a global, non-colliding three-layer endless-forest depth composition before streaming reveal; plateau/cliff/chasm runtime art remains individual 32x32 sources with stable semantic IDs. Authority: `design/02_features/procgen/ELEVATED_WORLD_PRESENTATION.md`.

- Active AI context directory: `custodian/docs/ai_context/`.
- Mandatory local routing primer: `custodian/AGENTS.md`.
- Agent task packet template: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`.
- Agent task packet directory: `custodian/docs/ai_context/task_packets/`.
- Validation recipes: `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Reusable prompt templates: `custodian/docs/ai_context/prompts/`.
- Agent automation backlog: `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`.
- Active runtime docs: `custodian/docs/*`.
- Godot implementation specs: `design/`.
- Sundered Keep production authority is split by role: procgen owns the playable generated frontage, floor/collision/navigation, distant reveal, actors/dressing, and terminal ingress; `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md` owns Shore Parish through the outer-wall east traverse and Front Gate handoff. Standard short fades connect them. The playable-blackout bridge and full-screen occluded handoff are not production route authority.
- Required asset tracker: `REQUIRED_ASSETS.md`.
- Event design docs: `design/02_features/events/LAST_ROUTEKEEPER_EVENT.md` (spec) and `design/02_features/events/LAST_ROUTEKEEPER_EVENT_CODE.md` (drop-in code) for The Last Routekeeper — a rare, one-time residual-system event inside Sundered Keep where the player recovers B. Chaffee's field-survey trace.
- Locked doctrine: `python-sim/design/MASTER_DESIGN_DOCTRINE.md`.
- Use `python-sim/design/DOC_STATUS.md` to resolve active-vs-legacy conflicts in older docs.
- Active migration/drift workflow: `custodian/docs/AGENT_MIGRATION_PLAYBOOK.md`.

## Idea Codex

`design/90_codex/` is a non-authoritative idea inventory. Cards preserve ideas and graduation history but never serve as active implementation specs. Graduated cards use `Graduated to:`, `Runtime status:`, and `Runtime path:` pointers; the linked active specs and this file remain build truth. `tools/validate_design_codex.py` checks index coverage, required metadata, graduation links, referenced paths, runtime-status agreement, and packaging-directory residue.
</file>

</files>
