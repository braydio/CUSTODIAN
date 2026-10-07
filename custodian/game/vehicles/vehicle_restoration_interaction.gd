extends Node2D
class_name VehicleRestorationInteraction

signal restoration_completed(target: Node)
signal restoration_cancelled(reason: StringName)

var target: PilotableVehicle
var resource_cost: Dictionary = {}
var hold_duration := 0.0
var restored_health_fraction := 0.0
var _active_actor: Node2D
var _hold_elapsed := 0.0
var _available := false
var _interact_held := false


func _ready() -> void:
	set_physics_process(true)
	set_available(_available)


func configure(vehicle: PilotableVehicle, profile: Dictionary) -> void:
	target = vehicle
	resource_cost = Dictionary(profile.get("cost", {})).duplicate(true)
	hold_duration = float(profile.get("hold_duration", 0.0))
	restored_health_fraction = float(profile.get("restored_health_fraction", 0.0))
	_available = true


func set_available(available: bool) -> void:
	_available = available
	if _available:
		add_to_group("interactable")
	else:
		remove_from_group("interactable")
		if _active_actor != null:
			cancel_restoration(&"TARGET_UNAVAILABLE")


func can_interact(_actor: Node) -> bool:
	return _available and is_instance_valid(target) and target.is_wreckage()


func is_restoration_active() -> bool:
	return _active_actor != null


func get_interaction_prompt() -> String:
	if not can_interact(_active_actor):
		return ""
	var label := "RESTORE %s" % target.get_display_name().to_upper()
	if _active_actor != null:
		return "HOLD INTERACT %s // %.1f/%.1fs" % [label, _hold_elapsed, hold_duration]
	return "HOLD INTERACT %s // %s // %.1fs" % [label, _format_cost(), hold_duration]


func get_interaction_position() -> Vector2:
	return target.global_position if is_instance_valid(target) else global_position


func get_interaction_distance() -> float:
	return target.interaction_range if is_instance_valid(target) else 0.0


func interact(actor: Node) -> void:
	if _active_actor != null or not can_interact(actor):
		return
	var actor_2d := actor as Node2D
	if actor_2d == null or get_interaction_position().distance_to(actor_2d.global_position) > get_interaction_distance():
		restoration_cancelled.emit(&"OUT_OF_RANGE")
		return
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger == null or not bool(ledger.call("can_pay", resource_cost)):
		restoration_cancelled.emit(&"INSUFFICIENT_RESOURCES")
		return
	_active_actor = actor_2d
	_hold_elapsed = 0.0
	_interact_held = true


func update_interaction_hold(actor: Node, is_held: bool, target_is_current: bool) -> void:
	if _active_actor == null or actor != _active_actor:
		return
	if not is_held:
		cancel_restoration(&"INPUT_RELEASED")
	elif not target_is_current:
		cancel_restoration(&"TARGET_LOST")


func cancel_restoration(reason: StringName = &"INTERRUPTED") -> void:
	_active_actor = null
	_hold_elapsed = 0.0
	_interact_held = false
	restoration_cancelled.emit(reason)


func _physics_process(delta: float) -> void:
	if _active_actor == null:
		return
	if not _interact_held:
		cancel_restoration(&"INPUT_RELEASED")
		return
	if not is_instance_valid(_active_actor) or get_interaction_position().distance_to(_active_actor.global_position) > get_interaction_distance():
		cancel_restoration(&"OUT_OF_RANGE")
		return
	_hold_elapsed += delta
	if _hold_elapsed >= hold_duration:
		_complete_restoration()


func _complete_restoration() -> void:
	var ledger := get_node_or_null("/root/ResourceLedger")
	if not can_interact(_active_actor) or ledger == null or not bool(ledger.call("can_pay", resource_cost)):
		cancel_restoration(&"CONTRACT_CHANGED")
		return
	if not bool(ledger.call("pay", resource_cost)):
		cancel_restoration(&"CONTRACT_CHANGED")
		return
	var restored := target.restore_from_wreck(restored_health_fraction)
	_active_actor = null
	_hold_elapsed = 0.0
	_interact_held = false
	if not restored:
		push_error("VehicleRestorationInteraction: target rejected a validated restoration")
		return
	restoration_completed.emit(target)


func _format_cost() -> String:
	var parts: PackedStringArray = []
	for resource_id in resource_cost.keys():
		parts.append("%s %s" % [resource_cost[resource_id], String(resource_id).replace("_", " ").to_upper()])
	return " + ".join(parts)
