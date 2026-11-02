class_name PowerGeneratorComponent
extends Node

@export var generator_id: StringName
@export var base_generation_rate: float = 0.0
@export var enabled: bool = true

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


func get_stable_power_id() -> String:
	if not generator_id.is_empty():
		return String(generator_id)
	var owner := get_parent()
	if owner != null and "infrastructure_instance_id" in owner:
		return String(owner.get("infrastructure_instance_id"))
	return String(get_path())


func get_power_output_rate() -> float:
	if not enabled or not _active:
		return 0.0
	var modifier := 1.0
	var owner := get_parent()
	if owner != null and owner.has_method("get_integrity_modifier"):
		modifier = clampf(float(owner.call("get_integrity_modifier")), 0.0, 1.0)
	return maxf(0.0, base_generation_rate * modifier)


func _register() -> void:
	if _registered:
		return
	var grid := get_node_or_null("/root/GameRoot/Power")
	if grid != null and grid.has_method("register_generator"):
		grid.call("register_generator", self)
		_registered = true


func _unregister() -> void:
	if not _registered:
		return
	var grid := get_node_or_null("/root/GameRoot/Power")
	if grid != null and grid.has_method("unregister_generator"):
		grid.call("unregister_generator", self)
	_registered = false

