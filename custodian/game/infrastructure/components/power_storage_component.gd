class_name PowerStorageComponent
extends Node

@export var storage_id: StringName
@export var storage_capacity: float = 0.0
@export var charge_rate: float = 0.0
@export var discharge_rate: float = 0.0
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
	if not storage_id.is_empty():
		return String(storage_id)
	var owner := get_parent()
	if owner != null and "infrastructure_instance_id" in owner:
		return String(owner.get("infrastructure_instance_id"))
	return String(get_path())


func get_storage_profile() -> Dictionary:
	if not enabled or not _active:
		return {"capacity": 0.0, "charge_rate": 0.0, "discharge_rate": 0.0}
	var modifier := 1.0
	var owner := get_parent()
	if owner != null and owner.has_method("get_integrity_modifier"):
		modifier = clampf(float(owner.call("get_integrity_modifier")), 0.0, 1.0)
	return {
		"capacity": maxf(0.0, storage_capacity * modifier),
		"charge_rate": maxf(0.0, charge_rate * modifier),
		"discharge_rate": maxf(0.0, discharge_rate * modifier),
	}


func _register() -> void:
	if _registered:
		return
	var grid := get_node_or_null("/root/GameRoot/Power")
	if grid != null and grid.has_method("register_storage"):
		grid.call("register_storage", self)
		_registered = true


func _unregister() -> void:
	if not _registered:
		return
	var grid := get_node_or_null("/root/GameRoot/Power")
	if grid != null and grid.has_method("unregister_storage"):
		grid.call("unregister_storage", self)
	_registered = false

