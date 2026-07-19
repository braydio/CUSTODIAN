extends Node
class_name SunderedKeepVistaController

@export var player_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var camera_path: NodePath = NodePath("/root/GameRoot/World/Camera2D")
@export var entry_marker_path: NodePath
@export var start_marker_path: NodePath
@export var reveal_full_marker_path: NodePath
@export var mid_gameplay_marker_path: NodePath
@export var end_marker_path: NodePath

@export var vista_root_path: NodePath
@export var grand_vista_root_path: NodePath
@export var vista_fog_band_path: NodePath
@export var fog_underlay_path: NodePath
@export var occlusion_root_path: NodePath
@export var cliff_occluder_path: NodePath
@export var wall_shadow_occluder_path: NodePath
@export var final_gate_shadow_veil_path: NodePath
@export var distant_keep_path: NodePath
@export var second_vista_start_marker_path: NodePath
@export var second_vista_full_marker_path: NodePath
@export var second_vista_end_marker_path: NodePath

@export_range(0.0, 1.0, 0.01) var vista_max_alpha := 1.0
@export_range(0.0, 1.0, 0.01) var vista_min_lateral_alpha := 0.35
@export_range(0.0, 1.0, 0.01) var vista_fog_max_alpha := 0.76
@export_range(0.0, 1.0, 0.01) var fog_underlay_min_alpha := 0.28
@export_range(0.0, 1.0, 0.01) var fog_underlay_max_alpha := 0.62
@export_range(0.0, 1.0, 0.01) var cliff_max_alpha := 0.92
@export_range(0.0, 1.0, 0.01) var shadow_max_alpha := 0.85
@export_range(0.0, 1.0, 0.01) var keep_min_alpha := 0.40

const CAMERA_ENTRY_OFFSET := Vector2(0.0, 0.0)
const CAMERA_ENTRY_ZOOM := Vector2(1.0, 1.0)
const CAMERA_FIRST_REVEAL_OFFSET := Vector2(0.0, -140.0)
const CAMERA_FIRST_REVEAL_ZOOM := Vector2(0.86, 0.86)
const CAMERA_TRAVERSE_OFFSET := Vector2(0.0, -48.0)
const CAMERA_TRAVERSE_ZOOM := Vector2(0.96, 0.96)
const CAMERA_GRAND_VISTA_OFFSET := Vector2(0.0, -48.0)
const CAMERA_GRAND_VISTA_ZOOM := Vector2(0.96, 0.96)
const CAMERA_FINAL_GATE_OFFSET := Vector2(0.0, 0.0)
const CAMERA_FINAL_GATE_ZOOM := Vector2(1.0, 1.0)

var _player: Node2D
var _camera: Camera2D
var _entry: Marker2D
var _start: Node2D
var _reveal_full: Node2D
var _mid_gameplay: Marker2D
var _end: Node2D
var _vista_root: CanvasItem
var _grand_vista_root: CanvasItem
var _vista_fog: CanvasItem
var _fog_underlay: CanvasItem
var _occlusion_root: CanvasItem
var _cliff: CanvasItem
var _shadow: CanvasItem
var _final_gate_shadow_veil: CanvasItem
var _keep: CanvasItem
var _second_vista_start: Marker2D
var _second_vista_full: Marker2D
var _second_vista_end: Marker2D
var _camera_target_offset := CAMERA_ENTRY_OFFSET
var _camera_target_zoom := CAMERA_ENTRY_ZOOM
var _last_progress := 0.0
var _reveal_choreography_active := false
var _reveal_choreography_weight := 0.0
var _reveal_progress_floor := 0.0


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


func has_camera_target() -> bool:
	return _camera != null and is_instance_valid(_camera)


func get_camera_target_state() -> Dictionary:
	return {
		"offset": _camera_target_offset,
		"zoom": _camera_target_zoom,
		"camera_bound": has_camera_target(),
	}


func begin_reveal_choreography() -> void:
	_reveal_choreography_active = true
	_reveal_choreography_weight = 0.0


func set_reveal_choreography_weight(weight: float) -> void:
	_reveal_choreography_weight = clampf(weight, 0.0, 1.0)
	_apply_progress(_last_progress)


func complete_reveal_choreography() -> void:
	_reveal_choreography_weight = 1.0
	_reveal_progress_floor = maxf(_reveal_progress_floor, _marker_progress(_reveal_full)) if _reveal_full != null else 0.25
	_reveal_choreography_active = false
	_apply_progress(_last_progress)


func get_reveal_choreography_state() -> Dictionary:
	return {
		"active": _reveal_choreography_active,
		"weight": _reveal_choreography_weight,
		"progress_floor": _reveal_progress_floor,
	}


func _resolve_nodes() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_camera = get_node_or_null(camera_path) as Camera2D
	_entry = get_node_or_null(entry_marker_path) as Marker2D
	_start = get_node_or_null(start_marker_path) as Node2D
	_reveal_full = get_node_or_null(reveal_full_marker_path) as Node2D
	_mid_gameplay = get_node_or_null(mid_gameplay_marker_path) as Marker2D
	_end = get_node_or_null(end_marker_path) as Node2D
	_vista_root = get_node_or_null(vista_root_path) as CanvasItem
	_grand_vista_root = get_node_or_null(grand_vista_root_path) as CanvasItem
	_vista_fog = get_node_or_null(vista_fog_band_path) as CanvasItem
	if String(fog_underlay_path).is_empty():
		_fog_underlay = null
	else:
		_fog_underlay = get_node_or_null(fog_underlay_path) as CanvasItem
	_occlusion_root = get_node_or_null(occlusion_root_path) as CanvasItem
	_cliff = get_node_or_null(cliff_occluder_path) as CanvasItem
	_shadow = get_node_or_null(wall_shadow_occluder_path) as CanvasItem
	_final_gate_shadow_veil = get_node_or_null(final_gate_shadow_veil_path) as CanvasItem
	_keep = get_node_or_null(distant_keep_path) as CanvasItem
	_second_vista_start = get_node_or_null(second_vista_start_marker_path) as Marker2D
	_second_vista_full = get_node_or_null(second_vista_full_marker_path) as Marker2D
	_second_vista_end = get_node_or_null(second_vista_end_marker_path) as Marker2D

	var approach_root := get_parent()
	if approach_root == null:
		return
	if _start == null:
		_start = approach_root.get_node_or_null("Markers/RevealStart") as Node2D
	if _entry == null:
		_entry = approach_root.get_node_or_null("Markers/EntrySpawn") as Marker2D
	if _reveal_full == null:
		_reveal_full = approach_root.get_node_or_null("Markers/RevealFull") as Node2D
	if _mid_gameplay == null:
		_mid_gameplay = approach_root.get_node_or_null("Markers/MidGameplayStart") as Marker2D
	if _end == null:
		_end = approach_root.get_node_or_null("Markers/ReturnTopdown") as Node2D
	if _vista_root == null:
		_vista_root = approach_root.get_node_or_null("VistaRoot") as CanvasItem
	if _grand_vista_root == null:
		_grand_vista_root = approach_root.get_node_or_null("GrandVistaRoot") as CanvasItem
	if _vista_fog == null:
		_vista_fog = approach_root.get_node_or_null("VistaRoot/ApproachFirstVistaFogVeil") as CanvasItem
	if _occlusion_root == null:
		_occlusion_root = approach_root.get_node_or_null("OcclusionRoot") as CanvasItem
	if _cliff == null:
		_cliff = approach_root.get_node_or_null("OcclusionRoot/ApproachEdgeMistWrap") as CanvasItem
	if _shadow == null:
		_shadow = approach_root.get_node_or_null("OcclusionRoot/ApproachFinalGateShadowVeil") as CanvasItem
	if _final_gate_shadow_veil == null:
		_final_gate_shadow_veil = approach_root.get_node_or_null("OcclusionRoot/ApproachFinalGateShadowVeil") as CanvasItem
	if _keep == null:
		_keep = approach_root.get_node_or_null("VistaRoot/ApproachFirstVistaHorizon") as CanvasItem
	if _second_vista_start == null:
		_second_vista_start = approach_root.get_node_or_null("Markers/SecondVistaStart") as Marker2D
	if _second_vista_full == null:
		_second_vista_full = approach_root.get_node_or_null("Markers/SecondVistaFull") as Marker2D
	if _second_vista_end == null:
		_second_vista_end = approach_root.get_node_or_null("Markers/SecondVistaEnd") as Marker2D


func _apply_progress(t: float) -> void:
	_last_progress = clampf(t, 0.0, 1.0)
	var reveal_start_progress := _marker_progress(_start) if _start != null else 0.0
	var reveal_full_progress := _marker_progress(_reveal_full) if _reveal_full != null else 0.38
	var authored_reveal_progress := lerpf(reveal_start_progress, reveal_full_progress, _reveal_choreography_weight)
	var reveal_t := maxf(t, _reveal_progress_floor)
	if _reveal_choreography_active:
		reveal_t = maxf(reveal_t, authored_reveal_progress)
	var first_vista_alpha := smoothstep(reveal_start_progress, reveal_full_progress, reveal_t)
	var second_vista_alpha := _get_second_vista_alpha(t)
	var exit_shadow_alpha := _get_exit_shadow_alpha(t)
	_apply_camera_progress(reveal_t)

	if _vista_root != null:
		_vista_root.modulate.a = first_vista_alpha * vista_max_alpha
	if _grand_vista_root != null:
		_grand_vista_root.modulate.a = second_vista_alpha
	if _vista_fog != null:
		_vista_fog.modulate.a = lerpf(0.0, vista_fog_max_alpha, first_vista_alpha)
	if _fog_underlay != null:
		_fog_underlay.modulate.a = lerpf(fog_underlay_min_alpha, fog_underlay_max_alpha, smoothstep(0.0, 1.0, t))
	if _occlusion_root != null:
		_occlusion_root.modulate.a = 1.0
	if _cliff != null:
		_cliff.modulate.a = minf(_cliff.modulate.a, cliff_max_alpha)
	if _shadow != null:
		_shadow.modulate.a = exit_shadow_alpha * shadow_max_alpha
	if _final_gate_shadow_veil != null:
		_final_gate_shadow_veil.modulate.a = exit_shadow_alpha * shadow_max_alpha
	if _keep != null:
		_keep.modulate.a = lerpf(keep_min_alpha, 1.0, first_vista_alpha)


func _apply_camera_progress(t: float) -> void:
	var reveal_full_progress := _marker_progress(_reveal_full) if _reveal_full != null else 0.25
	var mid_progress := _marker_progress(_mid_gameplay) if _mid_gameplay != null else 0.45
	var second_start_progress := _marker_progress(_second_vista_start) if _second_vista_start != null else 0.60
	var second_end_progress := _marker_progress(_second_vista_end) if _second_vista_end != null else 0.86
	var end_progress := _marker_progress(_end) if _end != null else 1.0

	if t <= reveal_full_progress:
		var weight := smoothstep(0.0, maxf(reveal_full_progress, 0.001), t)
		_set_camera_target(
			CAMERA_ENTRY_OFFSET.lerp(CAMERA_FIRST_REVEAL_OFFSET, weight),
			CAMERA_ENTRY_ZOOM.lerp(CAMERA_FIRST_REVEAL_ZOOM, weight)
		)
	elif t <= mid_progress:
		var weight := smoothstep(reveal_full_progress, maxf(mid_progress, reveal_full_progress + 0.001), t)
		_set_camera_target(
			CAMERA_FIRST_REVEAL_OFFSET.lerp(CAMERA_TRAVERSE_OFFSET, weight),
			CAMERA_FIRST_REVEAL_ZOOM.lerp(CAMERA_TRAVERSE_ZOOM, weight)
		)
	elif t <= second_start_progress:
		_set_camera_target(CAMERA_TRAVERSE_OFFSET, CAMERA_TRAVERSE_ZOOM)
	elif t <= second_end_progress:
		_set_camera_target(CAMERA_GRAND_VISTA_OFFSET, CAMERA_GRAND_VISTA_ZOOM)
	else:
		var weight := smoothstep(second_end_progress, maxf(end_progress, second_end_progress + 0.001), t)
		_set_camera_target(
			CAMERA_GRAND_VISTA_OFFSET.lerp(CAMERA_FINAL_GATE_OFFSET, weight),
			CAMERA_GRAND_VISTA_ZOOM.lerp(CAMERA_FINAL_GATE_ZOOM, weight)
		)


func _set_camera_target(target_offset: Vector2, target_zoom: Vector2) -> void:
	_camera_target_offset = target_offset
	_camera_target_zoom = target_zoom
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_node_or_null(camera_path) as Camera2D
	if _camera != null and _camera.has_method("set_presentation_framing"):
		_camera.call("set_presentation_framing", true, target_offset, target_zoom)


func _get_second_vista_alpha(t: float) -> float:
	if _start == null or _end == null or _second_vista_start == null or _second_vista_full == null or _second_vista_end == null:
		return 0.0

	var start_progress := _marker_progress(_second_vista_start)
	var full_progress := _marker_progress(_second_vista_full)
	var end_progress := _marker_progress(_second_vista_end)

	if not (start_progress < full_progress and full_progress < end_progress):
		push_warning("[SunderedKeepVistaController] Second vista marker progress is invalid: start=%s full=%s end=%s" % [start_progress, full_progress, end_progress])
		return 0.0

	if t < start_progress:
		return 0.0
	if t <= full_progress:
		return smoothstep(start_progress, full_progress, t)
	if t <= end_progress:
		return 1.0 - smoothstep(full_progress, end_progress, t)
	return 0.0


func _marker_progress(marker: Node2D) -> float:
	var progress_axis := _end.global_position - _start.global_position
	var total := progress_axis.length()
	if total <= 0.01:
		return 0.0
	var along := (marker.global_position - _start.global_position).dot(progress_axis.normalized())
	return clampf(along / total, 0.0, 1.0)


func _get_exit_shadow_alpha(t: float) -> float:
	if _second_vista_end == null or _end == null:
		return smoothstep(0.82, 1.0, t)
	return smoothstep(_marker_progress(_second_vista_end), _marker_progress(_end), t)
