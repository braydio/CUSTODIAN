extends Node

signal changed(snapshot: Dictionary)
signal resource_added(resource_id: String, amount: int, new_total: int)
signal resource_spent(cost: Dictionary)

@export var resource_defs_path: String = "res://content/resources/resource_defs.json"

var _resources: Dictionary = {}
var _resource_defs: Dictionary = {}


func _ready() -> void:
	load_resource_defs()


func load_resource_defs() -> void:
	_resource_defs = _load_json_dictionary(resource_defs_path)


func get_amount(resource_id: String) -> int:
	return int(_resources.get(resource_id, 0))


func get_snapshot() -> Dictionary:
	return _resources.duplicate(true)


func get_resource_defs() -> Dictionary:
	return _resource_defs.duplicate(true)


func add(resource_id: String, amount: int) -> void:
	if amount <= 0 or resource_id.is_empty():
		return

	var new_total := get_amount(resource_id) + amount
	_resources[resource_id] = new_total

	resource_added.emit(resource_id, amount, new_total)
	changed.emit(get_snapshot())


func can_pay(cost: Dictionary) -> bool:
	for resource_id_variant in cost.keys():
		var resource_id := str(resource_id_variant)
		var amount := int(cost[resource_id_variant])
		if amount < 0:
			return false
		if get_amount(resource_id) < amount:
			return false
	return true


func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false

	for resource_id_variant in cost.keys():
		var resource_id := str(resource_id_variant)
		_resources[resource_id] = get_amount(resource_id) - int(cost[resource_id_variant])

	resource_spent.emit(cost.duplicate(true))
	changed.emit(get_snapshot())
	return true


func clear() -> void:
	_resources.clear()
	changed.emit(get_snapshot())


func debug_grant(resources: Dictionary = {}) -> void:
	var grant := resources
	if grant.is_empty():
		grant = {
			"blackwood": 20,
			"ruin_scrap": 30,
			"structural_alloy": 12,
			"power_components": 2,
			"capacitor_dust": 6,
			"signal_filament": 1,
			"memory_glass_fragment": 2,
			"resin_clot": 4,
		}
	for resource_id_variant in grant.keys():
		add(str(resource_id_variant), int(grant[resource_id_variant]))


func _load_json_dictionary(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_warning("[ResourceLedger] Missing resource definition file: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[ResourceLedger] Could not open resource definition file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)

	push_warning("[ResourceLedger] Invalid resource definition JSON: %s" % path)
	return {}
