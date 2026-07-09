extends Node
class_name DroneManager

const DEFAULT_DRONE_SCENE := preload("res://game/actors/allies/allied_infantry_droid.tscn")
const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const DroneSquadStateScript := preload("res://game/systems/drone/drone_squad_state.gd")
const GUARD_ORDER_MARKER_SCENE := preload("res://game/actors/effects/drone_guard_order_marker.tscn")

@export var operator_path: NodePath = NodePath("../Operator")
@export var spawn_on_ready: bool = true
@export var initial_active_drones: int = 2
@export var drone_scene: PackedScene = DEFAULT_DRONE_SCENE
@export var command_profile: Resource
@export var squad_state: Resource
@export var toggle_fire_action: StringName = &"drone_toggle_fire"
@export var cycle_follow_distance_action: StringName = &"drone_cycle_follow_distance"
@export var issue_guard_order_action: StringName = &"drone_issue_guard_order"
@export var recall_guard_order_action: StringName = &"drone_recall_order"
@export var announce_commands: bool = true

var _operator: Node2D = null
var _drone_parent: Node = null
var _drones: Array[Node2D] = []
var _guard_order_marker: Node2D = null


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
	_drones.append(drone)
	_apply_squad_state_to_drone(drone)
	return drone


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed(toggle_fire_action):
		toggle_fire_at_will()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(cycle_follow_distance_action):
		cycle_follow_distance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(recall_guard_order_action):
		recall_guard_order()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"attack_primary") and Input.is_action_pressed(issue_guard_order_action):
		issue_guard_order(_get_pointer_world_position())
		get_viewport().set_input_as_handled()


func set_squad_mode(mode: int) -> void:
	squad_state.set_mode(mode)
	_for_each_live_drone(func(drone: Node) -> void:
		if drone.has_method("set_mode"):
			drone.call("set_mode", mode)
	)


func set_squad_mode_name(mode_name: String) -> void:
	set_squad_mode(DroneCommandProfileScript.parse_mode(mode_name))


func toggle_fire_at_will() -> void:
	var enabled: bool = squad_state.toggle_fire_at_will()
	_propagate_fire_at_will(enabled)
	_announce_squad_state("Fire")


func set_fire_at_will(enabled: bool) -> void:
	squad_state.set_fire_at_will(enabled)
	_propagate_fire_at_will(enabled)


func cycle_follow_distance() -> void:
	var mode: int = squad_state.cycle_follow_distance()
	_propagate_follow_distance(mode)
	_announce_squad_state("Follow")


func set_follow_distance(mode: int) -> void:
	squad_state.set_follow_distance(mode)
	_propagate_follow_distance(mode)


func issue_guard_order(position: Vector2) -> void:
	squad_state.set_order_anchor(position)
	_propagate_order_anchor(position)
	_update_guard_order_marker()
	_announce_squad_state("Guard")


func recall_guard_order() -> void:
	squad_state.clear_order_anchor()
	_propagate_order_anchor_clear()
	_update_guard_order_marker()
	_announce_squad_state("Recall")


func has_guard_order() -> bool:
	return squad_state != null and squad_state.has_order_anchor()


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


func _apply_squad_state_to_drone(drone: Node) -> void:
	if drone == null or not is_instance_valid(drone):
		return
	if drone.has_method("set_mode"):
		drone.call("set_mode", squad_state.current_mode)
	if drone.has_method("set_fire_at_will"):
		drone.call("set_fire_at_will", squad_state.fire_at_will)
	if drone.has_method("set_follow_distance_mode"):
		drone.call("set_follow_distance_mode", squad_state.current_follow_distance)
	if squad_state.has_order_anchor() and drone.has_method("set_order_anchor"):
		drone.call("set_order_anchor", squad_state.order_anchor_position)
	elif drone.has_method("clear_order_anchor"):
		drone.call("clear_order_anchor")


func _propagate_fire_at_will(enabled: bool) -> void:
	_for_each_live_drone(func(drone: Node) -> void:
		if drone.has_method("set_fire_at_will"):
			drone.call("set_fire_at_will", enabled)
	)


func _propagate_follow_distance(mode: int) -> void:
	_for_each_live_drone(func(drone: Node) -> void:
		if drone.has_method("set_follow_distance_mode"):
			drone.call("set_follow_distance_mode", mode)
	)


func _propagate_order_anchor(position: Vector2) -> void:
	_for_each_live_drone(func(drone: Node) -> void:
		if drone.has_method("set_order_anchor"):
			drone.call("set_order_anchor", position)
	)


func _propagate_order_anchor_clear() -> void:
	_for_each_live_drone(func(drone: Node) -> void:
		if drone.has_method("clear_order_anchor"):
			drone.call("clear_order_anchor")
	)


func _for_each_live_drone(callback: Callable) -> void:
	_prune_drones()
	for drone in _drones:
		if drone != null and is_instance_valid(drone):
			callback.call(drone)


func _announce_squad_state(reason: String) -> void:
	if not announce_commands:
		return
	var summary := get_squad_summary()
	var fire_text := "FIRE AT WILL" if bool(summary.get("fire_at_will", true)) else "HOLD FIRE"
	var follow_text := String(summary.get("follow_distance", "UNKNOWN")).replace("_", " ")
	var tactical_text := String(summary.get("mode", "UNKNOWN"))
	var anchor_text := String(summary.get("anchor_kind", "FOLLOW"))
	if reason == "Fire":
		print("[Drones] Fire: %s | live=%d | follow=%s | mode=%s" % [fire_text, int(summary.get("live_count", 0)), follow_text, tactical_text])
	elif reason == "Follow":
		print("[Drones] %s: %s | live=%d | fire=%s | mode=%s" % [anchor_text, follow_text, int(summary.get("live_count", 0)), fire_text, tactical_text])
	elif reason == "Guard" or reason == "Recall":
		print("[Drones] %s %s | live=%d | fire=%s | mode=%s" % [anchor_text, follow_text, int(summary.get("live_count", 0)), fire_text, tactical_text])
	else:
		print("[Drones] %s | live=%d | fire=%s | follow=%s | mode=%s" % [reason, int(summary.get("live_count", 0)), fire_text, follow_text, tactical_text])


func _prune_drones() -> void:
	var live_drones: Array[Node2D] = []
	for drone in _drones:
		if drone == null or not is_instance_valid(drone):
			continue
		if drone.has_method("is_dead") and bool(drone.call("is_dead")):
			continue
		live_drones.append(drone)
	_drones = live_drones


func _get_pointer_world_position() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		return camera.get_global_mouse_position()
	if _operator != null and is_instance_valid(_operator):
		return _operator.get_global_mouse_position()
	return Vector2.ZERO


func _update_guard_order_marker() -> void:
	if not squad_state.has_order_anchor():
		if _guard_order_marker != null and is_instance_valid(_guard_order_marker):
			_guard_order_marker.queue_free()
		_guard_order_marker = null
		return
	if _guard_order_marker == null or not is_instance_valid(_guard_order_marker):
		_guard_order_marker = GUARD_ORDER_MARKER_SCENE.instantiate() as Node2D
		var marker_parent := _drone_parent if _drone_parent != null else get_parent()
		marker_parent.add_child(_guard_order_marker)
	_guard_order_marker.global_position = squad_state.order_anchor_position
