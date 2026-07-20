class_name PowerConsumerComponent
extends Node

signal allocation_changed(allocated_power: float, power_tier: StringName, effective_output: float)

@export var consumer_id: StringName
@export var minimum_power: float = 0.0
@export var standard_power: float = 0.0
@export var overdrive_power: float = 0.0
@export var overdrive_efficiency: float = 1.0
@export_range(0, 100, 1) var priority: int = 50
@export var enabled: bool = true
@export var overdrive_enabled: bool = false

var allocated_power: float = 0.0
var power_tier: StringName = &"offline"
var effective_output: float = 0.0
var _active: bool = false
var _registered: bool = false


func _exit_tree() -> void:
	_unregister()


func set_infrastructure_active(active: bool) -> void:
	_active = active
	if _active:
		_register()
	else:
		_unregister()
		apply_power_allocation(0.0)


func get_stable_power_id() -> String:
	if not consumer_id.is_empty():
		return String(consumer_id)
	var owner := get_parent()
	if owner != null and "infrastructure_instance_id" in owner:
		return String(owner.get("infrastructure_instance_id"))
	return String(get_path())


func get_power_priority() -> int:
	return priority


func get_minimum_power() -> float:
	return minimum_power if enabled and _active else 0.0


func get_standard_power() -> float:
	return standard_power if enabled and _active else 0.0


func get_overdrive_power() -> float:
	return overdrive_power if enabled and overdrive_enabled and _active else 0.0


func is_power_consumer_enabled() -> bool:
	return enabled and _active


func apply_power_allocation(amount: float) -> void:
	var previous_tier := power_tier
	allocated_power = maxf(0.0, amount)
	if not enabled or not _active or allocated_power + 0.0001 < minimum_power:
		power_tier = &"offline"
		effective_output = 0.0
	elif standard_power > minimum_power and allocated_power + 0.0001 < standard_power:
		power_tier = &"degraded"
		effective_output = clampf(allocated_power / maxf(standard_power, 0.001), 0.0, 1.0)
	elif overdrive_enabled and overdrive_power > standard_power and allocated_power + 0.0001 >= overdrive_power:
		power_tier = &"overdrive"
		effective_output = maxf(1.0, overdrive_efficiency)
	else:
		power_tier = &"standard"
		effective_output = 1.0
	effective_output *= _get_integrity_modifier()
	allocation_changed.emit(allocated_power, power_tier, effective_output)
	if previous_tier != power_tier:
		_observe_tier_change(previous_tier)


func get_effective_output() -> float:
	return effective_output


func get_power_snapshot() -> Dictionary:
	return {
		"id": get_stable_power_id(),
		"priority": priority,
		"minimum": minimum_power,
		"standard": standard_power,
		"overdrive": overdrive_power,
		"allocated": allocated_power,
		"tier": String(power_tier),
		"effective_output": effective_output,
	}


func _get_integrity_modifier() -> float:
	var owner := get_parent()
	if owner != null and owner.has_method("get_integrity_modifier"):
		return clampf(float(owner.call("get_integrity_modifier")), 0.0, 1.0)
	return 1.0


func _register() -> void:
	if _registered:
		return
	var grid := get_node_or_null("/root/GameRoot/Power")
	if grid != null and grid.has_method("register_consumer"):
		grid.call("register_consumer", self)
		_registered = true


func _unregister() -> void:
	if not _registered:
		return
	var grid := get_node_or_null("/root/GameRoot/Power")
	if grid != null and grid.has_method("unregister_consumer"):
		grid.call("unregister_consumer", self)
	_registered = false


func _observe_tier_change(previous_tier: StringName) -> void:
	if not is_inside_tree():
		return
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", &"infrastructure_power_tier_changed", {
			"consumer_id": get_stable_power_id(),
			"previous_tier": String(previous_tier),
			"power_tier": String(power_tier),
			"allocated_power": allocated_power,
			"effective_output": effective_output,
		})
