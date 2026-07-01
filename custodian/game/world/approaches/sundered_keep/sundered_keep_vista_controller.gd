extends Node
class_name SunderedKeepVistaController

@export var player_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var start_marker_path: NodePath
@export var end_marker_path: NodePath

@export var vista_root_path: NodePath
@export var vista_fog_band_path: NodePath
@export var fog_underlay_path: NodePath
@export var occlusion_root_path: NodePath
@export var cliff_occluder_path: NodePath
@export var wall_shadow_occluder_path: NodePath
@export var distant_keep_path: NodePath

@export_range(0.0, 1.0, 0.01) var vista_max_alpha := 1.0
@export_range(0.0, 1.0, 0.01) var vista_min_lateral_alpha := 0.35
@export_range(0.0, 1.0, 0.01) var vista_fog_max_alpha := 0.76
@export_range(0.0, 1.0, 0.01) var fog_underlay_min_alpha := 0.28
@export_range(0.0, 1.0, 0.01) var fog_underlay_max_alpha := 0.62
@export_range(0.0, 1.0, 0.01) var cliff_max_alpha := 0.92
@export_range(0.0, 1.0, 0.01) var shadow_max_alpha := 0.85
@export_range(0.0, 1.0, 0.01) var keep_min_alpha := 0.40

var _player: Node2D
var _start: Node2D
var _end: Node2D
var _vista_root: CanvasItem
var _vista_fog: CanvasItem
var _fog_underlay: CanvasItem
var _occlusion_root: CanvasItem
var _cliff: CanvasItem
var _shadow: CanvasItem
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
	if _vista_root != null:
		tween.parallel().tween_property(_vista_root, "modulate:a", vista_min_lateral_alpha, 0.9)
	if _vista_fog != null:
		tween.parallel().tween_property(_vista_fog, "modulate:a", 1.0, 0.9)
	if _fog_underlay != null:
		tween.parallel().tween_property(_fog_underlay, "modulate:a", 1.0, 0.9)
	if _occlusion_root != null:
		tween.parallel().tween_property(_occlusion_root, "modulate:a", 1.0, 0.9)
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
	_vista_root = get_node_or_null(vista_root_path) as CanvasItem
	_vista_fog = get_node_or_null(vista_fog_band_path) as CanvasItem
	_fog_underlay = get_node_or_null(fog_underlay_path) as CanvasItem
	_occlusion_root = get_node_or_null(occlusion_root_path) as CanvasItem
	_cliff = get_node_or_null(cliff_occluder_path) as CanvasItem
	_shadow = get_node_or_null(wall_shadow_occluder_path) as CanvasItem
	_keep = get_node_or_null(distant_keep_path) as CanvasItem

	var approach_root := get_parent()
	if approach_root == null:
		return
	if _start == null:
		_start = approach_root.get_node_or_null("Markers/RevealStart") as Node2D
	if _end == null:
		_end = approach_root.get_node_or_null("Markers/ReturnTopdown") as Node2D
	if _vista_root == null:
		_vista_root = approach_root.get_node_or_null("VistaRoot") as CanvasItem
	if _vista_fog == null:
		_vista_fog = approach_root.get_node_or_null("VistaRoot/VistaFogBand") as CanvasItem
	if _fog_underlay == null:
		_fog_underlay = approach_root.get_node_or_null("UnderlayRoot/FogUnderlay") as CanvasItem
	if _occlusion_root == null:
		_occlusion_root = approach_root.get_node_or_null("OcclusionRoot") as CanvasItem
	if _cliff == null:
		_cliff = approach_root.get_node_or_null("OcclusionRoot/CliffOccluder") as CanvasItem
	if _shadow == null:
		_shadow = approach_root.get_node_or_null("OcclusionRoot/WallShadowOccluder") as CanvasItem
	if _keep == null:
		_keep = approach_root.get_node_or_null("VistaRoot/DistantSunderedKeep") as CanvasItem


func _apply_progress(t: float) -> void:
	var reveal := smoothstep(0.0, 0.38, t)
	var lateral := smoothstep(0.58, 0.92, t)
	var occlusion := smoothstep(0.58, 0.95, t)
	var vista_alpha := lerpf(0.0, vista_max_alpha, reveal)
	vista_alpha = lerpf(vista_alpha, vista_min_lateral_alpha, lateral)

	if _vista_root != null:
		_vista_root.modulate.a = vista_alpha
	if _vista_fog != null:
		_vista_fog.modulate.a = lerpf(0.0, vista_fog_max_alpha, reveal)
	if _fog_underlay != null:
		_fog_underlay.modulate.a = lerpf(fog_underlay_min_alpha, fog_underlay_max_alpha, smoothstep(0.0, 1.0, t))
	if _occlusion_root != null:
		_occlusion_root.modulate.a = occlusion
	if _cliff != null:
		_cliff.modulate.a = occlusion * cliff_max_alpha
	if _shadow != null:
		_shadow.modulate.a = smoothstep(0.48, 0.96, t) * shadow_max_alpha
	if _keep != null:
		_keep.modulate.a = lerpf(1.0, keep_min_alpha, lateral)
