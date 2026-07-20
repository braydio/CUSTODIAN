extends Node
class_name TerminalDeployment

@export var terminal_path: NodePath = NodePath("../CommandTerminal")
@export var operator_path: NodePath = NodePath("../Operator")
@export var deploy_snap_to_grid: bool = false
@export var pickup_distance: float = 80.0

var _terminal: CommandTerminal = null
var _operator: Node2D = null
var _is_carrying: bool = false


func _ready() -> void:
	call_deferred("_resolve_nodes")


func _process(_delta: float) -> void:
	if not _is_carrying:
		return
	if _terminal == null or not is_instance_valid(_terminal):
		_is_carrying = false
		return
	_terminal.global_position = _get_deploy_position()


func handle_build_action() -> bool:
	if _terminal == null or not is_instance_valid(_terminal):
		return false
	if _is_carrying:
		return _deploy_carried_terminal()
	if not _can_pickup_terminal():
		return false
	return _pickup_terminal()


func is_carrying_terminal() -> bool:
	return _is_carrying


func get_terminal() -> CommandTerminal:
	if _terminal != null and is_instance_valid(_terminal):
		return _terminal
	return null


func _resolve_nodes() -> void:
	_terminal = get_node_or_null(terminal_path) as CommandTerminal
	_operator = get_node_or_null(operator_path) as Node2D
	if _terminal != null:
		_terminal.set_carried_state(false)


func _can_pickup_terminal() -> bool:
	if _terminal == null or not is_instance_valid(_terminal):
		return false
	if _operator == null or not is_instance_valid(_operator):
		return false
	if _is_carrying:
		return false
	return _operator.global_position.distance_to(_terminal.global_position) <= pickup_distance


func _pickup_terminal() -> bool:
	if not _can_pickup_terminal():
		return false
	_is_carrying = true
	_terminal.play_pickup_transition(false)
	_terminal.set_carried_state(true)
	_terminal.global_position = _get_deploy_position()
	return true


func _deploy_carried_terminal() -> bool:
	if not _is_carrying or _terminal == null or not is_instance_valid(_terminal):
		return false
	_terminal.global_position = _get_deploy_position()
	_terminal.revoke_command_authority()
	_terminal.set_carried_state(false, false)
	_terminal.play_pickup_transition(true)
	_is_carrying = false
	return true


func _get_deploy_position() -> Vector2:
	if deploy_snap_to_grid:
		return _snap_to_grid(_get_world_mouse_position())
	return _get_world_mouse_position()


func _get_world_mouse_position() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		return camera.get_global_mouse_position()
	if _operator != null and is_instance_valid(_operator):
		return _operator.global_position
	return Vector2.ZERO


func _snap_to_grid(position: Vector2) -> Vector2:
	return Vector2(
		round(position.x / 32.0) * 32.0,
		round(position.y / 32.0) * 32.0
	)
