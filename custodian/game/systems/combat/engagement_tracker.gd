class_name EngagementTracker
extends Node

signal engagement_started
signal engagement_ended
signal initiative_resolved(won: bool)
signal vanguard_seal_activated(duration_sec: float)
signal vanguard_seal_ended(reason: StringName)

const RELIC_SLOT := &"relic"
const VANGUARD_SEAL_ID := &"vanguard_seal"
const ENGAGEMENT_QUIET_SEC := 4.0
const VANGUARD_DURATION_SEC := 8.0
const INITIATIVE_STAGGER_MULTIPLIER := 1.20
const VANGUARD_DIRECT_DAMAGE_MULTIPLIER := 1.08
const VANGUARD_STAGGER_MULTIPLIER := 1.15

var operator: Node2D = null
var inventory_manager: Node = null
var engagement_active := false
var initiative_claimed := false
var initiative_lost := false
var vanguard_active := false
var _quiet_timer := 0.0
var _vanguard_timer := 0.0


func configure(operator_node: Node2D, inventory_node: Node = null) -> void:
	operator = operator_node
	inventory_manager = inventory_node


func advance_fixed(delta: float) -> void:
	var step := maxf(0.0, delta)
	if vanguard_active:
		_vanguard_timer = maxf(0.0, _vanguard_timer - step)
		if _vanguard_timer <= 0.0:
			_end_vanguard(&"expired")

	var hostile_intent := _has_live_hostile_intent()
	if hostile_intent and not engagement_active:
		_start_engagement()
	if not engagement_active:
		return
	if hostile_intent:
		_quiet_timer = 0.0
		return
	_quiet_timer += step
	if _quiet_timer >= ENGAGEMENT_QUIET_SEC:
		_end_engagement()


func prepare_direct_operator_hit(target: Node, _damage_kind: StringName) -> Dictionary:
	if not _is_living_hostile(target):
		return {
			"eligible": false,
			"direct_damage_multiplier": 1.0,
			"stagger_damage_multiplier": 1.0,
		}
	if not engagement_active:
		_start_engagement()
	_quiet_timer = 0.0

	var initiative_candidate := false
	var stagger_multiplier := 1.0
	if not initiative_claimed and not initiative_lost:
		initiative_candidate = true
		stagger_multiplier *= INITIATIVE_STAGGER_MULTIPLIER

	var direct_multiplier := 1.0
	if vanguard_active:
		direct_multiplier *= VANGUARD_DIRECT_DAMAGE_MULTIPLIER
		stagger_multiplier *= VANGUARD_STAGGER_MULTIPLIER

	return {
		"eligible": true,
		"initiative_candidate": initiative_candidate,
		"initiative_claimed": false,
		"vanguard_active": vanguard_active,
		"direct_damage_multiplier": direct_multiplier,
		"stagger_damage_multiplier": stagger_multiplier,
	}


func confirm_direct_operator_hit(
	applied_damage: float,
	prepared_hit: Dictionary
) -> bool:
	if (
		applied_damage <= 0.0
		or not bool(prepared_hit.get("eligible", false))
		or not bool(prepared_hit.get("initiative_candidate", false))
		or initiative_claimed
		or initiative_lost
	):
		return false
	initiative_claimed = true
	initiative_resolved.emit(true)
	if _is_vanguard_seal_equipped():
		_activate_vanguard()
	return true


func notify_direct_hostile_damage(applied_damage: float) -> void:
	if applied_damage <= 0.0:
		return
	if not engagement_active:
		_start_engagement()
	_quiet_timer = 0.0
	if not initiative_claimed and not initiative_lost:
		initiative_lost = true
		initiative_resolved.emit(false)
	if vanguard_active:
		_end_vanguard(&"direct_damage")


func get_status() -> Dictionary:
	return {
		"engagement_active": engagement_active,
		"initiative_claimed": initiative_claimed,
		"initiative_lost": initiative_lost,
		"quiet_remaining_sec": (
			maxf(0.0, ENGAGEMENT_QUIET_SEC - _quiet_timer)
			if engagement_active else 0.0
		),
		"vanguard_equipped": _is_vanguard_seal_equipped(),
		"vanguard_active": vanguard_active,
		"vanguard_remaining_sec": _vanguard_timer,
	}


func _start_engagement() -> void:
	engagement_active = true
	initiative_claimed = false
	initiative_lost = false
	_quiet_timer = 0.0
	engagement_started.emit()


func _end_engagement() -> void:
	engagement_active = false
	initiative_claimed = false
	initiative_lost = false
	_quiet_timer = 0.0
	if vanguard_active:
		_end_vanguard(&"engagement_ended")
	engagement_ended.emit()


func _activate_vanguard() -> void:
	vanguard_active = true
	_vanguard_timer = VANGUARD_DURATION_SEC
	vanguard_seal_activated.emit(VANGUARD_DURATION_SEC)


func _end_vanguard(reason: StringName) -> void:
	if not vanguard_active:
		return
	vanguard_active = false
	_vanguard_timer = 0.0
	vanguard_seal_ended.emit(reason)


func _is_vanguard_seal_equipped() -> bool:
	return (
		inventory_manager != null
		and is_instance_valid(inventory_manager)
		and inventory_manager.has_method("get_equipped")
		and StringName(inventory_manager.call("get_equipped", RELIC_SLOT)) == VANGUARD_SEAL_ID
	)


func _has_live_hostile_intent() -> bool:
	if (
		operator == null
		or not is_instance_valid(operator)
		or not is_inside_tree()
	):
		return false
	for hostile in get_tree().get_nodes_in_group("enemy"):
		if not _is_living_hostile(hostile):
			continue
		var target_variant: Variant = (
			hostile.get("target") if _has_property(hostile, &"target") else null
		)
		if target_variant == operator:
			return true
		var behavior: Node = (
			hostile.get("behavior_state_machine")
			if _has_property(hostile, &"behavior_state_machine") else null
		)
		if behavior == null or not is_instance_valid(behavior):
			continue
		var blackboard: Node = behavior.get("blackboard")
		if blackboard == null or not is_instance_valid(blackboard):
			continue
		if blackboard.get("operator_ref") != operator:
			continue
		var state := StringName(str(behavior.get("current_state")))
		if state in [&"notice", &"investigate", &"engage_operator", &"search"]:
			return true
	return false


func _is_living_hostile(target: Node) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_in_group("enemy"):
		return false
	var dead_variant: Variant = (
		target.get("dead") if _has_property(target, &"dead") else false
	)
	if dead_variant is bool and bool(dead_variant):
		return false
	var health_variant: Variant = (
		target.get("health") if _has_property(target, &"health") else 1.0
	)
	if (health_variant is float or health_variant is int) and float(health_variant) <= 0.0:
		return false
	return true


func _has_property(object: Object, property_name: StringName) -> bool:
	for property_variant in object.get_property_list():
		var property := property_variant as Dictionary
		if StringName(str(property.get("name", ""))) == property_name:
			return true
	return false
