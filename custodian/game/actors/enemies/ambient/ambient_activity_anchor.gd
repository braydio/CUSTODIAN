extends Area2D
class_name AmbientActivityAnchor

@export var faction_id: String = "none"
@export var activity_id: String = "ambient"
@export var radius_px: float = 28.0
@export var claim_duration_sec: float = 4.0
@export var escalation_radius_px: float = 160.0
@export var noncombat_first: bool = true

var claimed_by: Node = null


func _ready() -> void:
	add_to_group("ambient_activity_anchor")


func can_claim(actor: Node) -> bool:
	if claimed_by == null or not is_instance_valid(claimed_by):
		claimed_by = null
		return true
	return claimed_by == actor


func claim(actor: Node) -> bool:
	if not can_claim(actor):
		return false
	claimed_by = actor
	return true


func release(actor: Node) -> void:
	if claimed_by == actor:
		claimed_by = null


func get_anchor_position() -> Vector2:
	return global_position


func get_activity_snapshot() -> Dictionary:
	return {
		"faction_id": faction_id,
		"activity_id": activity_id,
		"claimed": claimed_by != null and is_instance_valid(claimed_by),
		"position": global_position,
		"noncombat_first": noncombat_first,
	}
