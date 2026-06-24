extends Node
class_name EnemyBlackboard

var operator_ref: Node = null
var last_known_operator_position: Vector2 = Vector2.ZERO
var has_seen_operator: bool = false
var is_alerted: bool = false
var is_suspicious: bool = false

var current_objective: Node = null
var current_objective_type: StringName = &"none"

var target_storage: Node = null
var carried_resources: Dictionary = {}
var is_carrying_loot: bool = false

var target_exit: Node = null
var morale: float = 100.0
var home_position: Vector2 = Vector2.ZERO
var patrol_points: Array[Vector2] = []

var investigation_position: Vector2 = Vector2.ZERO
var investigation_timer: float = 0.0
var target_visible: bool = false
var target_last_seen_position: Vector2 = Vector2.ZERO
var target_last_heard_position: Vector2 = Vector2.ZERO
var pursuit_timer: float = 0.0
var search_timer: float = 0.0
var search_point_index: int = 0
var leash_radius_px: float = 700.0
var camp_id: StringName = &""
var objective_debug_scores: Dictionary = {}
var ambient_anchor: Node = null
var ambient_activity_id: StringName = &"none"
var ambient_activity_timer: float = 0.0
var ambient_noncombat_first: bool = true


func reset_alerts() -> void:
	is_alerted = false
	is_suspicious = false
	has_seen_operator = false
	operator_ref = null
	current_objective_type = &"none"
	current_objective = null
	ambient_activity_id = &"none"
	ambient_activity_timer = 0.0


func get_debug_snapshot() -> Dictionary:
	return {
		"alerted": is_alerted,
		"suspicious": is_suspicious,
		"objective_type": String(current_objective_type),
		"carrying_loot": is_carrying_loot,
		"carried_resources": carried_resources.duplicate(true),
		"morale": morale,
		"last_known_operator_position": last_known_operator_position,
		"investigation_position": investigation_position,
		"target_visible": target_visible,
		"pursuit_timer": pursuit_timer,
		"search_timer": search_timer,
		"camp_id": String(camp_id),
		"ambient_activity": String(ambient_activity_id),
		"ambient_anchor": ambient_anchor.name if ambient_anchor != null and is_instance_valid(ambient_anchor) else "",
		"scores": objective_debug_scores.duplicate(true),
	}
