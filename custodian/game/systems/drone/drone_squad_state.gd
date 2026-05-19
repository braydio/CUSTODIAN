extends Resource
class_name DroneSquadState

const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")

@export var max_active_drones: int = 2
@export var max_reserve_drones: int = 0
@export var current_mode: int = DroneCommandProfileScript.Mode.FOLLOW

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


func get_summary() -> Dictionary:
	return {
		"mode": DroneCommandProfileScript.mode_name(current_mode),
		"active": active_drone_ids.duplicate(),
		"destroyed": destroyed_drone_ids.duplicate(),
		"reserve": max_reserve_drones,
	}
