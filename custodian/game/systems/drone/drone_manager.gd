extends Node
class_name DroneManager

const DEFAULT_DRONE_SCENE := preload("res://game/actors/allies/allied_infantry_droid.tscn")
const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const DroneSquadStateScript := preload("res://game/systems/drone/drone_squad_state.gd")

@export var operator_path: NodePath = NodePath("../Operator")
@export var spawn_on_ready: bool = true
@export var initial_active_drones: int = 2
@export var drone_scene: PackedScene = DEFAULT_DRONE_SCENE
@export var command_profile: Resource
@export var squad_state: Resource

var _operator: Node2D = null
var _drone_parent: Node = null
var _drones: Array[Node2D] = []


func _ready() -> void:
	add_to_group("drone_manager")
	if command_profile == null:
		command_profile = DroneCommandProfileScript.new()
	if squad_state == null:
		squad_state = DroneSquadStateScript.new()
	_operator = get_node_or_null(operator_path) as Node2D
	if _operator == null:
		_operator = get_node_or_null("/root/GameRoot/World/Operator") as Node2D
	_drone_parent = get_node_or_null("/root/GameRoot/World/Allies")
	if _drone_parent == null:
		_drone_parent = get_parent()
	if spawn_on_ready:
		call_deferred("spawn_initial_drones")


func spawn_initial_drones() -> void:
	if _operator == null or not is_instance_valid(_operator):
		return
	var desired_count = mini(initial_active_drones, squad_state.max_active_drones)
	for index in range(desired_count):
		spawn_drone(index)


func spawn_drone(index: int = -1) -> Node2D:
	if drone_scene == null or _operator == null:
		return null
	_prune_drones()
	if _drones.size() >= squad_state.max_active_drones:
		return null
	var slot := index
	if slot < 0:
		slot = _drones.size()
	var drone = drone_scene.instantiate() as Node2D
	if drone == null:
		return null
	var drone_id := "DRONE_%02d" % (slot + 1)
	if not squad_state.register_drone(drone_id):
		drone.queue_free()
		return null
	_drone_parent.add_child(drone)
	drone.global_position = _operator.global_position + Vector2((-1.0 if slot % 2 == 0 else 1.0) * 48.0, -28.0)
	if drone.has_method("configure"):
		drone.call("configure", slot, _operator, self, command_profile)
	if drone.has_method("set_mode"):
		drone.call("set_mode", squad_state.current_mode)
	_drones.append(drone)
	return drone


func set_squad_mode(mode: int) -> void:
	squad_state.set_mode(mode)
	for drone in _drones:
		if drone != null and is_instance_valid(drone) and drone.has_method("set_mode"):
			drone.call("set_mode", mode)


func set_squad_mode_name(mode_name: String) -> void:
	set_squad_mode(DroneCommandProfileScript.parse_mode(mode_name))


func notify_drone_destroyed(drone: Node) -> void:
	if drone == null:
		return
	var id := String(drone.get("drone_id"))
	if id != "":
		squad_state.mark_destroyed(id)
	_prune_drones()


func get_squad_summary() -> Dictionary:
	_prune_drones()
	var summary: Dictionary = squad_state.get_summary()
	summary["live_count"] = _drones.size()
	return summary


func _prune_drones() -> void:
	_drones = _drones.filter(func(drone: Node2D) -> bool:
		return drone != null and is_instance_valid(drone) and (not drone.has_method("is_dead") or not bool(drone.call("is_dead")))
	)
