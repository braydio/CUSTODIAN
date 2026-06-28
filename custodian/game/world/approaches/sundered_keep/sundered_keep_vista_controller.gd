extends Node
class_name SunderedKeepVistaController

@export var player_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var start_marker_path: NodePath
@export var end_marker_path: NodePath

@export var cliff_occluder_path: NodePath
@export var wall_shadow_occluder_path: NodePath
@export var underlay_fog_path: NodePath
@export var distant_keep_path: NodePath

@export_range(0.0, 1.0, 0.01) var cliff_max_alpha := 0.92
@export_range(0.0, 1.0, 0.01) var shadow_max_alpha := 0.85
@export_range(0.0, 1.0, 0.01) var fog_max_alpha := 0.72
@export_range(0.0, 1.0, 0.01) var keep_min_alpha := 0.22

var _player: Node2D
var _start: Node2D
var _end: Node2D
var _cliff: CanvasItem
var _shadow: CanvasItem
var _fog: CanvasItem
var _keep: CanvasItem


func _ready() -> void:
	_resolve_nodes()
	_apply_progress(0.0)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node2D
	if _player == null or _start == null or _end == null:
		return

	var progress_axis := _end.global_position - _start.global_position
	var total := progress_axis.length()
	if total <= 0.01:
		return

	var along := (_player.global_position - _start.global_position).dot(progress_axis.normalized())
	var t := clampf(along / total, 0.0, 1.0)
	_apply_progress(t)


func play_final_fade() -> void:
	var tween := create_tween()
	if _fog != null:
		tween.parallel().tween_property(_fog, "modulate:a", 1.0, 0.9)
	if _shadow != null:
		tween.parallel().tween_property(_shadow, "modulate:a", 1.0, 0.9)
	if _cliff != null:
		tween.parallel().tween_property(_cliff, "modulate:a", 1.0, 0.9)
	await tween.finished


func refresh_bindings() -> void:
	_resolve_nodes()


func apply_progress(t: float) -> void:
	_apply_progress(t)


func _resolve_nodes() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_start = get_node_or_null(start_marker_path) as Node2D
	_end = get_node_or_null(end_marker_path) as Node2D
	_cliff = get_node_or_null(cliff_occluder_path) as CanvasItem
	_shadow = get_node_or_null(wall_shadow_occluder_path) as CanvasItem
	_fog = get_node_or_null(underlay_fog_path) as CanvasItem
	_keep = get_node_or_null(distant_keep_path) as CanvasItem
	var approach_root := get_parent()
	if approach_root != null:
		if _start == null:
			_start = approach_root.get_node_or_null("ProgressStart") as Node2D
		if _end == null:
			_end = approach_root.get_node_or_null("ProgressEnd") as Node2D
		if _cliff == null:
			_cliff = approach_root.get_node_or_null("Occlusion/CliffOccluder") as CanvasItem
		if _shadow == null:
			_shadow = approach_root.get_node_or_null("Occlusion/WallShadowOccluder") as CanvasItem
		if _fog == null:
			_fog = approach_root.get_node_or_null("VistaUnderlay/UnderlayFogBand") as CanvasItem
		if _keep == null:
			_keep = approach_root.get_node_or_null("VistaUnderlay/DistantKeepProxy") as CanvasItem


func _apply_progress(t: float) -> void:
	if _cliff != null:
		_cliff.modulate.a = smoothstep(0.25, 0.85, t) * cliff_max_alpha
	if _shadow != null:
		_shadow.modulate.a = smoothstep(0.35, 0.95, t) * shadow_max_alpha
	if _fog != null:
		_fog.modulate.a = lerpf(0.25, fog_max_alpha, smoothstep(0.0, 1.0, t))
	if _keep != null:
		_keep.modulate.a = lerpf(1.0, keep_min_alpha, smoothstep(0.55, 1.0, t))
