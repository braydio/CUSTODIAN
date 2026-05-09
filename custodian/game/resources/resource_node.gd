extends StaticBody2D
class_name ResourceNode

signal harvested(node: ResourceNode, resource_id: String, remaining_work: int)
signal depleted(node: ResourceNode, resource_id: String, amount: int)

@export_enum("blackwood_deadfall", "alloy_vein", "machine_wreckage", "power_node", "moss_patch") var node_kind: String = "blackwood_deadfall"
@export_enum("CUT", "MINE", "SALVAGE", "EXTRACT") var harvest_label: String = "CUT"
@export var resource_id: String = "blackwood"
@export_range(1, 20, 1) var work_required: int = 3
@export_range(1, 999, 1) var yield_amount: int = 6
@export var secondary_yields: Dictionary = {}
@export_range(24.0, 160.0, 1.0) var interaction_distance: float = 84.0
@export var standing_color: Color = Color(0.18, 0.14, 0.1, 1.0)
@export var depleted_color: Color = Color(0.08, 0.075, 0.07, 1.0)
@export var prompt_resource_label: String = ""
@export var depleted_prompt: String = ""

@onready var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var _work_remaining: int = 1
var _is_depleted: bool = false


func _ready() -> void:
	add_to_group("resource_nodes")
	add_to_group("interactable")
	_work_remaining = max(1, work_required)
	_apply_visual_state()


func is_depleted() -> bool:
	return _is_depleted


func get_interaction_prompt() -> String:
	if _is_depleted:
		return depleted_prompt
	var label := prompt_resource_label
	if label.is_empty():
		label = resource_id.replace("_", " ").to_upper()
	var harvested_count := work_required - _work_remaining
	return "%s %s (%d/%d)" % [harvest_label, label, harvested_count, work_required]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(_actor: Node) -> void:
	apply_harvest(1)


func apply_harvest(work_amount: int = 1) -> bool:
	if _is_depleted:
		return false

	_work_remaining -= max(1, work_amount)
	harvested.emit(self, resource_id, max(0, _work_remaining))
	_apply_visual_state()

	if _work_remaining <= 0:
		_deplete()

	return true


func _deplete() -> void:
	if _is_depleted:
		return

	_is_depleted = true
	_deposit_yields()
	_apply_visual_state()
	remove_from_group("interactable")
	depleted.emit(self, resource_id, yield_amount)


func _deposit_yields() -> void:
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger == null:
		push_warning("[ResourceNode] ResourceLedger unavailable; harvest yield was not stored")
		return

	ledger.call("add", resource_id, yield_amount)
	for secondary_id_variant in secondary_yields.keys():
		var secondary_id := str(secondary_id_variant)
		var amount := int(secondary_yields[secondary_id_variant])
		if amount > 0:
			ledger.call("add", secondary_id, amount)


func _apply_visual_state() -> void:
	if visual == null:
		return
	visual.color = depleted_color if _is_depleted else standing_color
	var scale_y := 0.45 if _is_depleted else 1.0
	visual.scale = Vector2(1.0, scale_y)
	if collision_shape != null:
		collision_shape.disabled = _is_depleted
