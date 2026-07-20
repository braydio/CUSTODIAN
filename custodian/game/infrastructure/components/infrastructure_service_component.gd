class_name InfrastructureServiceComponent
extends Node

@export var service_id: StringName
@export var base_output: float = 1.0
@export var requires_power: bool = true

var _active: bool = false


func set_infrastructure_active(active: bool) -> void:
	_active = active
	_notify_changed()


func get_service_output() -> float:
	if not _active:
		return 0.0
	var owner := get_parent()
	var output := base_output
	if owner != null and owner.has_method("get_integrity_modifier"):
		output *= clampf(float(owner.call("get_integrity_modifier")), 0.0, 1.0)
	if requires_power and owner != null and owner.has_method("get_power_efficiency"):
		output *= maxf(0.0, float(owner.call("get_power_efficiency")))
	return output


func _notify_changed() -> void:
	if not is_inside_tree():
		return
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	if registry != null and registry.has_method("notify_structure_changed"):
		registry.call("notify_structure_changed", [service_id])
