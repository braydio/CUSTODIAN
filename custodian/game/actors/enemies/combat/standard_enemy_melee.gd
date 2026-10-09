extends RefCounted
class_name StandardEnemyMelee

## Ordinary baseline melee transaction. Enemy remains the actor and supplies
## shared targeting, hit, engagement, telemetry, and presentation services.
const EnemyHitSpatialContract = preload("res://game/systems/combat/enemy_hit_spatial_contract.gd")

var host: Enemy
var config: StandardEnemyMeleeConfig
var opening_strong_consumed := false
var windup_timer := 0.0
var queued_damage := 0.0
var queued_strong := false
var committed_forward := Vector2.DOWN
var committed_range_px := 0.0
var committed_range_source: StringName = &"unknown"
var committed_arc_degrees := 95.0
var attack_id := ""
var recovery_timer := 0.0
var redecision_timer := 0.0


func setup(new_host: Enemy, new_config: StandardEnemyMeleeConfig) -> void:
	host = new_host
	config = new_config
	committed_arc_degrees = config.contact_arc_degrees if config != null else 95.0


func is_active() -> bool:
	return not attack_id.is_empty()


func is_committed() -> bool:
	return is_active()


func is_eligible() -> bool:
	return not is_active() and recovery_timer <= 0.0 and redecision_timer <= 0.0


func get_debug_state() -> Dictionary:
	return {
		"active": is_active(),
		"committed": is_committed(),
		"attack_id": attack_id,
		"phase": "windup" if is_active() else "idle",
		"windup_remaining": windup_timer,
		"queued_damage": queued_damage,
		"queued_strong": queued_strong,
		"committed_forward": committed_forward,
		"committed_range_px": committed_range_px,
		"committed_range_source": String(committed_range_source),
		"committed_arc_degrees": committed_arc_degrees,
		"opening_strong_consumed": opening_strong_consumed,
		"recovery_remaining": recovery_timer,
		"redecision_remaining": redecision_timer,
	}


func get_committed_forward() -> Vector2:
	return committed_forward


func get_windup_duration() -> float:
	return config.windup_duration if config != null else 0.10


func get_contact_context(target_node: Node2D, direction: Vector2 = Vector2.ZERO) -> Dictionary:
	if host == null or config == null or target_node == null or not is_instance_valid(target_node):
		return {}
	var contact: Dictionary = host.resolve_standard_melee_contact_range(
		target_node, config.player_contact_range_px
	)
	var range_px := float(contact.get("range_px", config.player_contact_range_px))
	var facing := direction
	if facing.length_squared() <= 0.0001:
		facing = host.get_standard_melee_facing()
	var spatial := EnemyHitSpatialContract.radial_arc(
		host.global_position,
		target_node.global_position,
		facing,
		range_px,
		config.range_grace_multiplier,
		config.range_grace_px,
		config.contact_arc_degrees
	)
	spatial["base_contact_range_px"] = range_px
	spatial["melee_range_grace_multiplier"] = config.range_grace_multiplier
	spatial["melee_range_grace_px"] = config.range_grace_px
	spatial["contact_range_source"] = String(contact.get("source", "unknown"))
	return spatial


func try_start() -> bool:
	if host == null or config == null or not is_eligible():
		return false
	if host.dead or host.target == null or not is_instance_valid(host.target):
		return false
	if not host.target.has_method("take_damage"):
		return false
	queued_strong = not opening_strong_consumed
	if queued_strong:
		opening_strong_consumed = true
		queued_damage = host.damage * config.strong_opening_multiplier
	else:
		queued_damage = host.damage
	attack_id = host.next_standard_melee_attack_id()
	windup_timer = maxf(0.01, config.windup_duration)
	recovery_timer = 0.0
	redecision_timer = 0.0
	_capture_contact_context()
	host.on_standard_melee_started(queued_strong)
	var start_data := {
		"enemy_id": host.get_instance_id(),
		"attack_id": attack_id,
		"windup_duration": windup_timer,
	}
	host.record_standard_melee_event(&"enemy_attack_windup_started", start_data)
	host.record_standard_melee_event(&"enemy_attack_windup", {
		"enemy": host.enemy_name,
		"position": host.global_position,
		"damage": queued_damage,
		"attack_id": attack_id,
		"attacker_id": host.get_instance_id(),
		"target_id": host.target.get_instance_id() if is_instance_valid(host.target) else 0,
		"is_strong": queued_strong,
		"attack_objective": host.attack_objective,
		"target": host.target.name if is_instance_valid(host.target) else "",
		"range_px": committed_range_px,
		"contact_range_source": String(committed_range_source),
		"arc_degrees": committed_arc_degrees,
	})
	host.count_standard_melee_metric(&"enemy_attack_windups")
	return true


func tick(delta: float) -> bool:
	if not is_active():
		return false
	windup_timer = maxf(0.0, windup_timer - delta)
	host.velocity = Vector2.ZERO
	if windup_timer > maxf(0.0, config.tracking_lock_sec):
		_capture_contact_context()
	if windup_timer > 0.0:
		return true
	if not host.request_standard_melee_engagement(host.target as Node2D, config.recovery_duration):
		return true
	_execute()
	return true


func update_recovery(delta: float) -> void:
	if recovery_timer > 0.0:
		recovery_timer = maxf(0.0, recovery_timer - delta)
		if recovery_timer <= 0.0:
			redecision_timer = maxf(0.0, config.redecision_delay_sec)
			host.record_standard_melee_event(&"enemy_attack_recovery_completed", {
				"enemy_id": host.get_instance_id(),
			})
		return
	if redecision_timer > 0.0:
		redecision_timer = maxf(0.0, redecision_timer - delta)


func cancel(result: StringName = &"interrupted", reason: StringName = &"interrupted") -> void:
	if attack_id.is_empty():
		_clear_context()
		return
	host.record_standard_melee_event(&"enemy_attack_resolved", {
		"attack_id": attack_id,
		"attacker_id": host.get_instance_id(),
		"target_id": host.target.get_instance_id() if host.target != null and is_instance_valid(host.target) else 0,
		"attack_type": "melee",
		"phase": "cancelled",
		"result": String(result),
		"reason": String(reason),
		"enemy": host.enemy_name,
		"position": host.global_position,
	})
	host.count_standard_melee_metric(StringName("enemy_attack_result_%s" % String(result)))
	if result == &"cancelled_by_death":
		host.count_standard_melee_metric(&"enemy_attack_interrupted_by_death")
	elif reason == &"parry":
		host.count_standard_melee_metric(&"enemy_attack_interrupted_by_parry")
	host.release_standard_melee_engagement()
	_clear_context()


func _capture_contact_context() -> void:
	committed_range_px = config.player_contact_range_px
	committed_range_source = &"standard_melee"
	committed_arc_degrees = config.contact_arc_degrees
	if host.target is Node2D and is_instance_valid(host.target):
		var target_node := host.target as Node2D
		var contact := host.resolve_standard_melee_contact_range(target_node, config.player_contact_range_px)
		committed_range_px = float(contact.get("range_px", config.player_contact_range_px))
		committed_range_source = StringName(str(contact.get("source", "unknown")))
		var to_target := target_node.global_position - host.global_position
		if to_target.length_squared() > 0.0001:
			committed_forward = to_target.normalized()
			return
	var facing := host.get_standard_melee_facing()
	committed_forward = facing.normalized() if facing.length_squared() > 0.0001 else Vector2.DOWN


func _execute() -> void:
	if host.dead:
		cancel(&"cancelled_by_death", &"death")
		return
	host.record_standard_melee_event(&"enemy_attack_active", {
		"attack_id": attack_id,
		"attacker_id": host.get_instance_id(),
		"target_id": host.target.get_instance_id() if host.target != null and is_instance_valid(host.target) else 0,
		"attack_type": "melee",
		"phase": "active",
		"enemy": host.enemy_name,
	})
	if host.target == null or not is_instance_valid(host.target) or host.is_combat_target_destroyed(host.target):
		host.count_standard_melee_metric(&"enemy_attack_cancelled_no_target")
		host.record_standard_melee_event(&"enemy_attack_cancelled", {
			"attack_id": attack_id,
			"attacker_id": host.get_instance_id(),
			"target_id": 0,
			"attack_type": "melee",
			"phase": "active",
			"result": "interrupted",
			"enemy": host.enemy_name,
			"reason": "no_target",
			"position": host.global_position,
		})
		_clear_context()
		return
	var target_node := host.target as Node2D if host.target is Node2D else null
	if target_node == null:
		host.count_standard_melee_metric(&"enemy_attack_cancelled_no_target")
		host.record_standard_melee_event(&"enemy_attack_cancelled", {
			"attack_id": attack_id,
			"attacker_id": host.get_instance_id(),
			"target_id": 0,
			"attack_type": "melee",
			"phase": "active",
			"result": "interrupted",
			"enemy": host.enemy_name,
			"reason": "target_not_node2d",
			"position": host.global_position,
		})
		_clear_context()
		return
	var spatial := get_contact_context(target_node, committed_forward)
	var miss_reason := StringName(str(spatial.get("spatial_reason", "")))
	if not miss_reason.is_empty():
		host.count_standard_melee_metric(&"enemy_attack_whiffs")
		host.count_standard_melee_metric(&"enemy_attack_result_whiffed")
		var suffix := "out_of_range" if miss_reason == &"target_out_of_range" else "out_of_arc"
		host.count_standard_melee_metric(StringName("enemy_attack_whiffed_%s" % suffix))
		var whiff_data := {
			"attack_id": attack_id,
			"attacker_id": host.get_instance_id(),
			"target_id": target_node.get_instance_id(),
			"enemy": host.enemy_name,
			"attack_type": "melee",
			"phase": "active",
			"result": "whiffed",
			"reason": String(miss_reason),
			"position": host.global_position,
			"target": target_node.name,
			"target_position": target_node.global_position,
			"queued_damage": queued_damage,
			"range_px": committed_range_px,
			"arc_degrees": committed_arc_degrees,
		}
		whiff_data.merge(spatial, true)
		host.record_standard_melee_event(&"enemy_attack_whiff", whiff_data)
		_begin_recovery()
		_clear_context()
		return
	var hit_result := host.resolve_standard_melee_hit(target_node, queued_damage, attack_id, spatial)
	host.count_standard_melee_metric(&"enemy_attacks_resolved")
	var resolved_data := {
		"attack_id": attack_id,
		"attacker_id": host.get_instance_id(),
		"target_id": target_node.get_instance_id(),
		"enemy": host.enemy_name,
		"attack_type": "melee",
		"phase": "resolved",
		"position": host.global_position,
		"target": target_node.name,
		"target_position": target_node.global_position,
		"result": String(hit_result.get("result", "")),
		"hit_kind": String(hit_result.get("hit_kind", "")),
		"applied_damage": float(hit_result.get("applied_damage", 0.0)),
		"damage_attempted": queued_damage,
		"target_health_before": hit_result.get("target_health_before", null),
		"target_health_after": hit_result.get("target_health_after", null),
		"dodged": bool(hit_result.get("dodged", false)),
		"blocked": bool(hit_result.get("blocked", false)),
		"parried": bool(hit_result.get("parried", false)),
	}
	resolved_data.merge(spatial, true)
	host.record_standard_melee_event(&"enemy_attack_resolved", resolved_data)
	host.count_standard_melee_metric(StringName("enemy_attack_result_%s" % String(hit_result.get("result", "unknown"))))
	if not bool(hit_result.get("dodged", false)) and not bool(hit_result.get("parried", false)) and not bool(hit_result.get("blocked", false)) and float(hit_result.get("applied_damage", 0.0)) > 0.0:
		print("Enemy hit ", target_node.name, " for ", hit_result.get("applied_damage", 0.0), " damage!")
	_begin_recovery()
	_clear_context()


func _begin_recovery() -> void:
	recovery_timer = maxf(0.0, config.recovery_duration)
	redecision_timer = 0.0


func _clear_context() -> void:
	queued_damage = 0.0
	queued_strong = false
	committed_forward = Vector2.DOWN
	committed_range_px = 0.0
	committed_range_source = &"unknown"
	committed_arc_degrees = config.contact_arc_degrees if config != null else 95.0
	windup_timer = 0.0
	attack_id = ""
