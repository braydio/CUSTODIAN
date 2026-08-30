extends Area2D
class_name FieldRepairInteraction

signal repair_completed(target: Node, amount: float)
signal repair_cancelled(reason: StringName)

@export var target_path: NodePath
@export var interaction_range := 84.0
@export var hold_duration := 3.0
@export var resource_cost: Dictionary = {"ruin_scrap": 4}
@export var repair_amount := 30.0
@export var prompt_label := "FIELD REPAIR"

var _active_actor: Node2D = null
var _hold_elapsed := 0.0


func _ready() -> void:
	add_to_group("interactable")
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = interaction_range
	collision.shape = shape
	add_child(collision)
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		Vector2(-13, -8), Vector2(13, -8), Vector2(13, 8), Vector2(-13, 8),
	])
	marker.color = Color(0.28, 0.72, 0.62, 0.85)
	add_child(marker)


func _physics_process(delta: float) -> void:
	if _active_actor == null:
		return
	if not is_instance_valid(_active_actor) or global_position.distance_to(_active_actor.global_position) > interaction_range:
		cancel_repair(&"OUT_OF_RANGE")
		return
	_hold_elapsed += delta
	if _hold_elapsed >= hold_duration:
		_complete_repair()


func get_interaction_prompt() -> String:
	var target := get_node_or_null(target_path)
	if target == null:
		return ""
	if _active_actor != null:
		return "%s %.1f/%.1fs" % [prompt_label, _hold_elapsed, hold_duration]
	return "%s // HOLD" % prompt_label


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_range


func interact(actor: Node) -> void:
	if _active_actor != null:
		return
	var actor_2d := actor as Node2D
	if actor_2d == null or global_position.distance_to(actor_2d.global_position) > interaction_range:
		repair_cancelled.emit(&"OUT_OF_RANGE")
		return
	var target := get_node_or_null(target_path)
	if not _target_is_repairable(target):
		repair_cancelled.emit(&"TARGET_UNAVAILABLE")
		return
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger == null or not bool(ledger.call("can_pay", resource_cost)):
		repair_cancelled.emit(&"INSUFFICIENT_RESOURCES")
		return
	_active_actor = actor_2d
	_hold_elapsed = 0.0


func cancel_repair(reason: StringName = &"INTERRUPTED") -> void:
	_active_actor = null
	_hold_elapsed = 0.0
	repair_cancelled.emit(reason)


func _complete_repair() -> void:
	var target := get_node_or_null(target_path)
	var ledger := get_node_or_null("/root/ResourceLedger")
	if not _target_is_repairable(target) or ledger == null or not bool(ledger.call("pay", resource_cost)):
		cancel_repair(&"CONTRACT_CHANGED")
		return
	target.call("repair", repair_amount)
	_active_actor = null
	_hold_elapsed = 0.0
	repair_completed.emit(target, repair_amount)


func _target_is_repairable(target: Node) -> bool:
	if target == null or not target.has_method("repair"):
		return false
	if not ("current_health" in target and "max_health" in target):
		return false
	return float(target.get("current_health")) < float(target.get("max_health")) and float(target.get("current_health")) > 0.0
