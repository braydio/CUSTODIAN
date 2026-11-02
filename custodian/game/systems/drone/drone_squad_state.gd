extends Resource
class_name DroneSquadState

const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")

enum AnchorKind {
	OPERATOR,
	ORDER_POINT,
}

@export var max_active_drones: int = 2
@export var max_reserve_drones: int = 0
@export var current_mode: int = DroneCommandProfileScript.Mode.FOLLOW
@export var fire_at_will: bool = true
@export var current_follow_distance: int = DroneCommandProfileScript.FollowDistance.CLOSE
@export var anchor_kind: AnchorKind = AnchorKind.OPERATOR
@export var order_anchor_position: Vector2 = Vector2.ZERO
@export var order_anchor_active: bool = false

var active_drone_ids: Array[String] = []
var destroyed_drone_ids: Array[String] = []


func register_drone(drone_id: String) -> bool:
	if active_drone_ids.has(drone_id):
		return true
	if active_drone_ids.size() >= max_active_drones:
		return false
	active_drone_ids.append(drone_id)
	return true


func mark_destroyed(drone_id: String) -> void:
	active_drone_ids.erase(drone_id)
	if not destroyed_drone_ids.has(drone_id):
		destroyed_drone_ids.append(drone_id)


func set_mode(mode: int) -> void:
	current_mode = mode


func set_fire_at_will(enabled: bool) -> void:
	fire_at_will = enabled


func toggle_fire_at_will() -> bool:
	fire_at_will = not fire_at_will
	return fire_at_will


func set_follow_distance(mode: int) -> void:
	current_follow_distance = mode


func cycle_follow_distance() -> int:
	match current_follow_distance:
		DroneCommandProfileScript.FollowDistance.CLOSE:
			current_follow_distance = DroneCommandProfileScript.FollowDistance.FAR
		DroneCommandProfileScript.FollowDistance.FAR:
			current_follow_distance = DroneCommandProfileScript.FollowDistance.FREE_ROAM
		_:
			current_follow_distance = DroneCommandProfileScript.FollowDistance.CLOSE
	return current_follow_distance


func set_order_anchor(position: Vector2) -> void:
	order_anchor_position = position
	order_anchor_active = true
	anchor_kind = AnchorKind.ORDER_POINT


func clear_order_anchor() -> void:
	order_anchor_active = false
	anchor_kind = AnchorKind.OPERATOR


func has_order_anchor() -> bool:
	return order_anchor_active and anchor_kind == AnchorKind.ORDER_POINT


func get_anchor_label() -> String:
	return "GUARD" if has_order_anchor() else "FOLLOW"


func get_summary() -> Dictionary:
	return {
		"mode": DroneCommandProfileScript.mode_name(current_mode),
		"follow_distance": DroneCommandProfileScript.follow_distance_name(current_follow_distance),
		"fire_at_will": fire_at_will,
		"active": active_drone_ids.duplicate(),
		"destroyed": destroyed_drone_ids.duplicate(),
		"reserve": max_reserve_drones,
		"max_active": max_active_drones,
		"anchor_kind": get_anchor_label(),
		"order_anchor_active": has_order_anchor(),
		"order_anchor_position": order_anchor_position,
	}
