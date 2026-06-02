extends Node
class_name PropOperatorDepthSort

@export var target_path: NodePath = NodePath("..")
@export var operator_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var prop_y_offset: float = 0.0
@export var behind_operator_z_index: int = 1
@export var in_front_of_operator_z_index: int = 3
@export var update_interval_sec: float = 0.05

var _target: Node2D = null
var _operator: Node2D = null
var _elapsed := 0.0


func configure(target: Node2D, y_offset: float = 0.0, behind_z: int = 1, front_z: int = 3) -> void:
	_target = target
	prop_y_offset = y_offset
	behind_operator_z_index = behind_z
	in_front_of_operator_z_index = front_z
	_apply_depth_sort()


func _ready() -> void:
	_resolve_target()
	_apply_depth_sort()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < update_interval_sec:
		return
	_elapsed = 0.0
	_apply_depth_sort()


func _resolve_target() -> Node2D:
	if _target != null and is_instance_valid(_target):
		return _target
	_target = get_node_or_null(target_path) as Node2D
	return _target


func _resolve_operator() -> Node2D:
	if _operator != null and is_instance_valid(_operator):
		return _operator
	_operator = get_node_or_null(operator_path) as Node2D
	if _operator == null:
		_operator = get_tree().get_first_node_in_group("player") as Node2D
	return _operator


func _apply_depth_sort() -> void:
	var target := _resolve_target()
	var operator := _resolve_operator()
	if target == null or operator == null:
		return
	var prop_baseline_y := target.global_position.y + prop_y_offset
	target.z_as_relative = false
	target.z_index = behind_operator_z_index if operator.global_position.y > prop_baseline_y else in_front_of_operator_z_index
