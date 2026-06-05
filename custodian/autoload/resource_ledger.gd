extends Node

signal changed(snapshot: Dictionary)
signal resource_added(resource_id: String, amount: int, new_total: int)
signal resource_spent(cost: Dictionary)

@export var resource_defs_path: String = "res://content/resources/resource_defs.json"

const CANONICAL_RESOURCE_IDS := [
	"blackwood",
	"structural_alloy",
	"ruin_scrap",
	"spent_charge_cell",
	"frayed_signal_filament",
	"cracked_field_tag",
	"power_components",
	"resin_clot",
	"capacitor_dust",
	"signal_filament",
	"memory_glass_fragment",
	"white_thread_knot",
	"fiber_moss",
]
const LEGACY_RESOURCE_ALIASES := {
	"timber": "blackwood",
	"ore": "structural_alloy",
	"scrap": "ruin_scrap",
}

var _resources: Dictionary = {}
var _resource_defs: Dictionary = {}


func _ready() -> void:
	_reset_known_resources()
	load_resource_defs()


func load_resource_defs() -> void:
	_resource_defs = _load_json_dictionary(resource_defs_path)


func get_amount(resource_id: String) -> int:
	return int(_resources.get(_normalize_resource_id(resource_id), 0))


func get_snapshot() -> Dictionary:
	return _resources.duplicate(true)


func get_resource_defs() -> Dictionary:
	return _resource_defs.duplicate(true)


func add(resource_id: String, amount: int) -> void:
	if amount <= 0 or resource_id.is_empty():
		return

	var normalized_resource_id := _normalize_resource_id(resource_id)
	if normalized_resource_id.is_empty():
		return

	var new_total := get_amount(normalized_resource_id) + amount
	_resources[normalized_resource_id] = new_total

	resource_added.emit(normalized_resource_id, amount, new_total)
	changed.emit(get_snapshot())


func can_pay(cost: Dictionary) -> bool:
	var normalized_cost := _normalize_cost(cost)
	for resource_id_variant in normalized_cost.keys():
		var resource_id := str(resource_id_variant)
		var amount := int(normalized_cost[resource_id])
		if amount < 0:
			return false
		if get_amount(resource_id) < amount:
			return false
	return true


func pay(cost: Dictionary) -> bool:
	var normalized_cost := _normalize_cost(cost)
	if not can_pay(normalized_cost):
		return false

	for resource_id_variant in normalized_cost.keys():
		var resource_id := str(resource_id_variant)
		_resources[resource_id] = get_amount(resource_id) - int(normalized_cost[resource_id])

	resource_spent.emit(normalized_cost.duplicate(true))
	changed.emit(get_snapshot())
	return true


func clear() -> void:
	_reset_known_resources()
	changed.emit(get_snapshot())


func debug_grant(resources: Dictionary = {}) -> void:
	var grant := resources
	if grant.is_empty():
		grant = {
		"blackwood": 20,
		"ruin_scrap": 30,
		"spent_charge_cell": 2,
		"frayed_signal_filament": 2,
		"cracked_field_tag": 1,
		"structural_alloy": 12,
		"power_components": 2,
		"capacitor_dust": 6,
		"signal_filament": 1,
		"memory_glass_fragment": 2,
		"white_thread_knot": 1,
		"resin_clot": 4,
	}
	for resource_id_variant in grant.keys():
		add(str(resource_id_variant), int(grant[resource_id_variant]))


func _reset_known_resources() -> void:
	_resources.clear()
	for resource_id in CANONICAL_RESOURCE_IDS:
		_resources[resource_id] = 0


func _normalize_resource_id(resource_id: String) -> String:
	if resource_id.is_empty():
		return ""
	if CANONICAL_RESOURCE_IDS.has(resource_id):
		return resource_id
	return str(LEGACY_RESOURCE_ALIASES.get(resource_id, resource_id))


func _normalize_cost(cost: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	if cost.is_empty():
		return normalized

	for resource_id_variant in cost.keys():
		var resource_id := _normalize_resource_id(str(resource_id_variant))
		if resource_id.is_empty():
			continue
		var amount := int(cost[resource_id_variant])
		normalized[resource_id] = int(normalized.get(resource_id, 0)) + amount
	return normalized


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
