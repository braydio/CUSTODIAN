extends Node
class_name AuthoredThresholdBlend2D

@export var reference_path: NodePath
@export var subject_path: NodePath
@export var target_path: NodePath

@export var south_y: float = 0.0
@export var north_y: float = -128.0

@export_range(0.0, 1.0, 0.01) var south_alpha := 0.0
@export_range(0.0, 1.0, 0.01) var north_alpha := 1.0
@export var smoothstep := true

var _reference: Node2D
var _subject: Node2D
var _target: CanvasItem


func _process(_delta: float) -> void:
	_resolve_nodes()
	if _reference == null or _subject == null or _target == null:
		return
	var local_y := _reference.to_local(_subject.global_position).y
	var weight := clampf(inverse_lerp(south_y, north_y, local_y), 0.0, 1.0)
	if smoothstep:
		weight = weight * weight * (3.0 - 2.0 * weight)
	_target.modulate.a = lerpf(south_alpha, north_alpha, weight)


func _resolve_nodes() -> void:
	if _reference == null or not is_instance_valid(_reference):
		_reference = get_node_or_null(reference_path) as Node2D
	if _subject == null or not is_instance_valid(_subject):
		_subject = get_node_or_null(subject_path) as Node2D
		if _subject == null and get_tree() != null:
			_subject = get_tree().get_first_node_in_group("player") as Node2D
	if _target == null or not is_instance_valid(_target):
		_target = get_node_or_null(target_path) as CanvasItem
