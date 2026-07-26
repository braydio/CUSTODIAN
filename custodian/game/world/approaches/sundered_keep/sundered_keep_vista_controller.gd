extends Node
class_name SunderedKeepVistaController

@export var player_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var camera_path: NodePath = NodePath("/root/GameRoot/World/Camera2D")
@export var entry_marker_path: NodePath
@export var start_marker_path: NodePath
@export var reveal_full_marker_path: NodePath
@export var mid_gameplay_marker_path: NodePath
@export var first_camera_control_start_marker_path: NodePath
@export var reveal_control_start_marker_path: NodePath
@export var reveal_control_end_marker_path: NodePath
@export var first_camera_return_complete_marker_path: NodePath
@export var end_marker_path: NodePath

@export var vista_root_path: NodePath
@export var grand_vista_root_path: NodePath
@export var grand_vista_cinematic_root_path: NodePath
@export var fortress_vista_root_path: NodePath
@export var vista_fog_band_path: NodePath
@export var fog_underlay_path: NodePath
@export var occlusion_root_path: NodePath
@export var cliff_occluder_path: NodePath
@export var wall_shadow_occluder_path: NodePath
@export var final_gate_shadow_veil_path: NodePath
@export var distant_keep_path: NodePath
@export var first_reveal_light_path: NodePath
@export var second_vista_start_marker_path: NodePath
@export var second_vista_full_marker_path: NodePath
@export var second_vista_end_marker_path: NodePath
@export var first_reveal_camera_anchor_path: NodePath
@export var second_reveal_camera_anchor_path: NodePath
@export var parallax_reveal_root_path: NodePath
@export var parallax_foreground_root_path: NodePath

@export_range(0.0, 1.0, 0.01) var vista_max_alpha := 1.0
@export_range(0.0, 1.0, 0.01) var vista_min_lateral_alpha := 0.35
@export_range(0.0, 1.0, 0.01) var first_vista_fog_before_alpha := 0.68
@export_range(0.0, 1.0, 0.01) var first_vista_fog_apex_alpha := 0.24
@export_range(0.0, 1.0, 0.01) var first_vista_fog_settled_alpha := 0.32
@export_range(0.0, 1.0, 0.01) var fog_underlay_min_alpha := 0.28
@export_range(0.0, 1.0, 0.01) var fog_underlay_max_alpha := 0.62
@export_range(0.0, 1.0, 0.01) var cliff_max_alpha := 0.92
@export_range(0.0, 1.0, 0.01) var shadow_max_alpha := 0.38
@export_range(0.0, 1.0, 0.01) var keep_hidden_alpha := 0.08
@export_range(0.0, 1.0, 0.01) var keep_apex_alpha := 0.92
@export_range(0.0, 1.0, 0.01) var keep_settled_alpha := 0.82
@export_range(0.0, 0.5, 0.01) var first_reveal_light_peak := 0.20

const CAMERA_INTRO_TIGHT_OFFSET := Vector2(0.0, -18.0)
const CAMERA_INTRO_TIGHT_ZOOM := Vector2(1.12, 1.12)
const CAMERA_FIRST_REVEAL_OFFSET := Vector2.ZERO
const CAMERA_FIRST_REVEAL_ZOOM := Vector2(0.84, 0.84)
const CAMERA_TRAVERSE_OFFSET := Vector2(0.0, -48.0)
const CAMERA_TRAVERSE_ZOOM := Vector2(0.98, 0.98)
const CAMERA_SECOND_REVEAL_OFFSET := Vector2(150.0, -115.0)
const CAMERA_SECOND_REVEAL_ZOOM := Vector2(0.78, 0.78)
const CAMERA_FINAL_GATE_OFFSET := Vector2.ZERO
const CAMERA_FINAL_GATE_ZOOM := Vector2.ONE
const FIRST_VISTA_FOG_REVEAL_OFFSET := Vector2(-110.0, 50.0)
const FIRST_VISTA_FOG_SETTLED_OFFSET := Vector2(-90.0, 42.0)

enum FramingPhase {
	GAMEPLAY,
	SECOND_REVEAL,
	SECOND_REVEAL_HOLD,
	SECOND_PROGRESS_CONTROL,
	SECOND_RETURNING_TO_PLAY,
}

var _player: Node2D
var _camera: Camera2D
var _entry: Marker2D
var _start: Node2D
var _reveal_full: Node2D
var _mid_gameplay: Marker2D
var _first_camera_control_start: Marker2D
var _reveal_control_start: Marker2D
var _reveal_control_end: Marker2D
var _first_camera_return_complete: Marker2D
var _end: Node2D
var _vista_root: CanvasItem
var _grand_vista_root: CanvasItem
var _grand_vista_cinematic_root: CanvasItem
var _fortress_vista_root: CanvasItem
var _fortress_far: CanvasItem
var _fortress_mid: CanvasItem
var _fortress_near: CanvasItem
var _vista_fog: CanvasItem
var _fog_underlay: CanvasItem
var _occlusion_root: CanvasItem
var _cliff: CanvasItem
var _shadow: CanvasItem
var _final_gate_shadow_veil: CanvasItem
var _keep: CanvasItem
var _first_reveal_light: PointLight2D
var _second_vista_start: Marker2D
var _second_vista_full: Marker2D
var _second_vista_end: Marker2D
var _first_reveal_camera_anchor: Marker2D
var _second_reveal_camera_anchor: Marker2D
var _parallax_reveal_root: CanvasItem
var _parallax_foreground_root: CanvasItem
var _presentation_anchor: Marker2D
var _camera_target_offset := CAMERA_INTRO_TIGHT_OFFSET
var _camera_target_zoom := CAMERA_INTRO_TIGHT_ZOOM
var _last_progress := 0.0
var _framing_phase := FramingPhase.GAMEPLAY
var _first_enter_progress := 0.0
var _first_return_progress := 0.0
var _first_enter_weight := 0.0
var _first_return_weight := 0.0
var _first_camera_weight := 0.0
var _first_camera_phase := "GAMEPLAY_BEFORE"
var _first_reveal_weight := 0.0
var _first_progress_weight := 0.0
var _return_to_play_weight := 0.0
var _first_reveal_complete := false
var _second_enter_progress := 0.0
var _second_return_progress := 0.0
var _second_enter_weight := 0.0
var _second_return_weight := 0.0
var _second_camera_weight := 0.0
var _second_camera_phase := "SECOND_GAMEPLAY_BEFORE"
var _second_reveal_weight := 0.0
var _second_progress_weight := 0.0
var _second_return_to_play_weight := 0.0
var _second_reveal_complete := false
var _vista_fog_origin := Vector2.ZERO
var _vista_fog_origin_captured := false


func _ready() -> void:
	_resolve_nodes()
	_ensure_presentation_anchor()
	_apply_progress(_compute_route_progress())


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node2D
	if _player == null:
		return

	_apply_progress(_compute_route_progress())


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
	_ensure_presentation_anchor()
	_apply_progress(_compute_route_progress())


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


func enter_intro_tight_mode() -> void:
	_framing_phase = FramingPhase.GAMEPLAY
	_ensure_presentation_anchor()
	_apply_progress(_compute_route_progress())


func begin_first_reveal() -> void:
	# Compatibility only. Camera 1 is always derived from physical position.
	_apply_progress(_compute_route_progress())


func set_first_reveal_weight(weight: float) -> void:
	# Compatibility only. Timed reveal weights no longer own Camera 1.
	_apply_progress(_compute_route_progress())


func hold_first_reveal() -> void:
	# Compatibility only. Camera 1 has no timed hold state.
	_apply_progress(_compute_route_progress())


func begin_first_progress_control() -> void:
	# Compatibility only. The complete envelope is evaluated every frame.
	_apply_progress(_compute_route_progress())


func begin_return_to_gameplay() -> void:
	# Compatibility only. Return is the second position segment.
	_apply_progress(_compute_route_progress())


func set_return_to_gameplay_weight(weight: float) -> void:
	# Compatibility only. Timed return weights no longer own Camera 1.
	_apply_progress(_compute_route_progress())


func complete_first_reveal() -> void:
	# Compatibility only. Completion is derived from current position.
	_apply_progress(_compute_route_progress())


func begin_second_reveal() -> void:
	# Compatibility/event hook only. Camera 2 is physically evaluated.
	_apply_progress(_compute_route_progress())


func set_second_reveal_weight(weight: float) -> void:
	# Compatibility/event hook only. Timed weights never own framing.
	_apply_progress(_compute_route_progress())


func hold_second_reveal() -> void:
	_apply_progress(_compute_route_progress())


func begin_second_progress_control() -> void:
	_apply_progress(_compute_route_progress())


func begin_second_return_to_gameplay() -> void:
	_apply_progress(_compute_route_progress())


func set_second_return_to_gameplay_weight(weight: float) -> void:
	_apply_progress(_compute_route_progress())


func complete_second_reveal() -> void:
	# Completion bookkeeping cannot override the reversible corridor.
	_apply_progress(_compute_route_progress())


# Compatibility with the former one-phase reveal API.
func begin_reveal_choreography() -> void:
	begin_first_reveal()


func set_reveal_choreography_weight(weight: float) -> void:
	set_first_reveal_weight(weight)


func complete_reveal_choreography() -> void:
	complete_first_reveal()


func get_reveal_choreography_state() -> Dictionary:
	var second_camera_active := _is_second_camera_active()
	return {
		"active": _first_camera_weight > 0.001 or second_camera_active,
		"weight": _first_enter_weight,
		"progress_floor": 0.0,
		"phase": (
			_second_camera_phase
			if second_camera_active
			else _first_camera_phase
		),
		"framing_phase": _second_camera_phase,
		"first_camera_phase": _first_camera_phase,
		"first_reveal_complete": _first_enter_progress >= 0.999,
		"first_progress_weight": _first_return_progress,
		"first_enter_progress": _first_enter_progress,
		"first_return_progress": _first_return_progress,
		"first_enter_weight": _first_enter_weight,
		"first_return_weight": _first_return_weight,
		"first_camera_weight": _first_camera_weight,
		"presentation_anchor_position": (
			_presentation_anchor.global_position
			if _presentation_anchor != null
			else Vector2.ZERO
		),
		"second_reveal_complete": _second_reveal_complete,
		"second_camera_phase": _second_camera_phase,
		"second_enter_progress": _second_enter_progress,
		"second_return_progress": _second_return_progress,
		"second_enter_weight": _second_enter_weight,
		"second_return_weight": _second_return_weight,
		"second_camera_weight": _second_camera_weight,
		"second_reveal_weight": _second_reveal_weight,
		"second_anchor_blend_weight": _second_camera_weight,
		"second_progress_weight": _second_progress_weight,
		"second_return_to_play_weight": _second_return_to_play_weight,
		"return_weight": _return_to_play_weight,
		"follow_target_is_operator": (
			_camera != null
			and _camera.get("follow_target") == _player
		),
		"follow_target_is_presentation_anchor": (
			_camera != null
			and _camera.get("follow_target") == _presentation_anchor
		),
	}


func _resolve_nodes() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_camera = get_node_or_null(camera_path) as Camera2D
	_entry = get_node_or_null(entry_marker_path) as Marker2D
	_start = get_node_or_null(start_marker_path) as Node2D
	_reveal_full = get_node_or_null(reveal_full_marker_path) as Node2D
	_mid_gameplay = get_node_or_null(mid_gameplay_marker_path) as Marker2D
	_first_camera_control_start = get_node_or_null(
		first_camera_control_start_marker_path
	) as Marker2D
	_reveal_control_start = get_node_or_null(
		reveal_control_start_marker_path
	) as Marker2D
	_reveal_control_end = get_node_or_null(
		reveal_control_end_marker_path
	) as Marker2D
	_first_camera_return_complete = get_node_or_null(
		first_camera_return_complete_marker_path
	) as Marker2D
	_end = get_node_or_null(end_marker_path) as Node2D
	_vista_root = get_node_or_null(vista_root_path) as CanvasItem
	_grand_vista_root = get_node_or_null(grand_vista_root_path) as CanvasItem
	_grand_vista_cinematic_root = get_node_or_null(
		grand_vista_cinematic_root_path
	) as CanvasItem
	_fortress_vista_root = get_node_or_null(
		fortress_vista_root_path
	) as CanvasItem
	if _fortress_vista_root != null:
		_fortress_far = _fortress_vista_root.get_node_or_null(
			"FortressFarParallax"
		) as CanvasItem
		_fortress_mid = _fortress_vista_root.get_node_or_null(
			"FortressMidParallax"
		) as CanvasItem
		_fortress_near = _fortress_vista_root.get_node_or_null(
			"FortressNearParallax"
		) as CanvasItem
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
	_first_reveal_light = get_node_or_null(
		first_reveal_light_path
	) as PointLight2D
	if _vista_fog is Node2D and not _vista_fog_origin_captured:
		_vista_fog_origin = (_vista_fog as Node2D).position
		_vista_fog_origin_captured = true
		_vista_fog.set_meta(
			"first_vista_fog_origin",
			_vista_fog_origin
		)
	_second_vista_start = get_node_or_null(second_vista_start_marker_path) as Marker2D
	_second_vista_full = get_node_or_null(second_vista_full_marker_path) as Marker2D
	_second_vista_end = get_node_or_null(second_vista_end_marker_path) as Marker2D
	_first_reveal_camera_anchor = get_node_or_null(
		first_reveal_camera_anchor_path
	) as Marker2D
	_second_reveal_camera_anchor = get_node_or_null(
		second_reveal_camera_anchor_path
	) as Marker2D
	_parallax_reveal_root = get_node_or_null(
		parallax_reveal_root_path
	) as CanvasItem
	_parallax_foreground_root = get_node_or_null(
		parallax_foreground_root_path
	) as CanvasItem

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
	if _first_camera_control_start == null:
		_first_camera_control_start = approach_root.get_node_or_null(
			"Markers/FirstCameraControlStart"
		) as Marker2D
	if _reveal_control_start == null:
		_reveal_control_start = approach_root.get_node_or_null(
			"Markers/RevealControlStart"
		) as Marker2D
	if _reveal_control_end == null:
		_reveal_control_end = approach_root.get_node_or_null(
			"Markers/RevealControlEnd"
		) as Marker2D
	if _first_camera_return_complete == null:
		_first_camera_return_complete = approach_root.get_node_or_null(
			"Markers/FirstCameraReturnComplete"
		) as Marker2D
	if _end == null:
		_end = approach_root.get_node_or_null("Markers/ReturnTopdown") as Node2D
	if _vista_root == null:
		_vista_root = approach_root.get_node_or_null("VistaRoot") as CanvasItem
	if _grand_vista_root == null:
		_grand_vista_root = approach_root.get_node_or_null("GrandVistaRoot") as CanvasItem
	if _grand_vista_cinematic_root == null:
		_grand_vista_cinematic_root = approach_root.get_node_or_null(
			"GrandVistaRoot/GrandVistaCinematicRoot"
		) as CanvasItem
	if _fortress_vista_root == null:
		_fortress_vista_root = approach_root.get_node_or_null(
			"GrandVistaRoot/FortressVistaRoot"
		) as CanvasItem
	if _fortress_vista_root != null:
		if _fortress_far == null:
			_fortress_far = _fortress_vista_root.get_node_or_null(
				"FortressFarParallax"
			) as CanvasItem
		if _fortress_mid == null:
			_fortress_mid = _fortress_vista_root.get_node_or_null(
				"FortressMidParallax"
			) as CanvasItem
		if _fortress_near == null:
			_fortress_near = _fortress_vista_root.get_node_or_null(
				"FortressNearParallax"
			) as CanvasItem
	if _vista_fog == null:
		_vista_fog = approach_root.get_node_or_null(
			"VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil"
		) as CanvasItem
		if _vista_fog is Node2D:
			_vista_fog_origin = (_vista_fog as Node2D).position
			_vista_fog_origin_captured = true
			_vista_fog.set_meta(
				"first_vista_fog_origin",
				_vista_fog_origin
			)
	if _occlusion_root == null:
		_occlusion_root = approach_root.get_node_or_null("OcclusionRoot") as CanvasItem
	if _cliff == null:
		_cliff = approach_root.get_node_or_null("OcclusionRoot/ApproachEdgeMistWrap") as CanvasItem
	if _shadow == null:
		_shadow = approach_root.get_node_or_null("OcclusionRoot/ApproachFinalGateShadowVeil") as CanvasItem
	if _final_gate_shadow_veil == null:
		_final_gate_shadow_veil = approach_root.get_node_or_null("OcclusionRoot/ApproachFinalGateShadowVeil") as CanvasItem
	if _keep == null:
		_keep = approach_root.get_node_or_null(
			"ParallaxRoot/RevealDepth/"
			+ "DistantKeep_Parallax2D/"
			+ "DistantSunderedKeepLandmark"
		) as CanvasItem
	if _first_reveal_light == null:
		_first_reveal_light = approach_root.get_node_or_null(
			"OcclusionRoot/RevealMoonlightCue"
		) as PointLight2D
	if _second_vista_start == null:
		_second_vista_start = approach_root.get_node_or_null("Markers/SecondVistaStart") as Marker2D
	if _second_vista_full == null:
		_second_vista_full = approach_root.get_node_or_null("Markers/SecondVistaFull") as Marker2D
	if _second_vista_end == null:
		_second_vista_end = approach_root.get_node_or_null("Markers/SecondVistaEnd") as Marker2D
	if _first_reveal_camera_anchor == null:
		_first_reveal_camera_anchor = approach_root.get_node_or_null(
			"Markers/FirstRevealCameraAnchor"
		) as Marker2D
	if _second_reveal_camera_anchor == null:
		_second_reveal_camera_anchor = approach_root.get_node_or_null(
			"Markers/SecondVistaCameraAnchor"
		) as Marker2D
	if _parallax_reveal_root == null:
		_parallax_reveal_root = approach_root.get_node_or_null(
			"ParallaxRoot/RevealDepth"
		) as CanvasItem
	if _parallax_foreground_root == null:
		_parallax_foreground_root = approach_root.get_node_or_null(
			"ParallaxRoot/ForegroundDepth"
		) as CanvasItem


func _apply_progress(t: float) -> void:
	_last_progress = clampf(t, 0.0, 1.0)
	_update_first_camera_envelope_state()
	_update_second_camera_envelope_state()
	var reveal_t := _first_enter_weight
	var keep_t := _smootherstep_range(0.12, 0.82, reveal_t)
	var fog_t := _smootherstep_range(0.05, 0.90, reveal_t)
	var exit_shadow_alpha := _get_exit_shadow_alpha(t)
	var cinematic_alpha := _get_second_cinematic_alpha()
	var fortress_alphas := _get_fortress_layer_alphas(
		exit_shadow_alpha
	)
	var fortress_replacement_alpha := maxf(
		fortress_alphas.x,
		maxf(fortress_alphas.y, fortress_alphas.z)
	)
	_apply_camera_progress(t)

	if _parallax_reveal_root != null:
		# The reveal root is continuously present; its focal children own alpha.
		_parallax_reveal_root.modulate.a = 1.0
	if _parallax_foreground_root != null:
		var foreground_t := smoothstep(0.58, 1.0, t)
		_parallax_foreground_root.modulate.a = lerpf(
			0.08,
			0.24,
			foreground_t
		)
	if _vista_root != null:
		# VistaRoot now contains only the controlled reveal veil.
		_vista_root.modulate.a = 1.0
	if _grand_vista_root != null:
		_grand_vista_root.modulate.a = 1.0
	if _grand_vista_cinematic_root != null:
		_grand_vista_cinematic_root.modulate.a = cinematic_alpha
	if _fortress_vista_root != null:
		_fortress_vista_root.modulate.a = 1.0
	if _fortress_far != null:
		_fortress_far.modulate.a = fortress_alphas.x
	if _fortress_mid != null:
		_fortress_mid.modulate.a = fortress_alphas.y
	if _fortress_near != null:
		_fortress_near.modulate.a = fortress_alphas.z
	if _vista_fog != null:
		var reveal_fog_alpha := lerpf(
			first_vista_fog_before_alpha,
			first_vista_fog_apex_alpha,
			fog_t
		)
		_vista_fog.modulate.a = lerpf(
			reveal_fog_alpha,
			first_vista_fog_settled_alpha,
			_first_return_weight
		)
		if _vista_fog is Node2D and _vista_fog_origin_captured:
			var reveal_offset := FIRST_VISTA_FOG_REVEAL_OFFSET * fog_t
			var settled_offset := FIRST_VISTA_FOG_SETTLED_OFFSET
			(_vista_fog as Node2D).position = _vista_fog_origin + reveal_offset.lerp(
				settled_offset,
				_first_return_weight
			)
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
		var reveal_keep_alpha := lerpf(
			keep_hidden_alpha,
			keep_apex_alpha,
			keep_t
		)
		var persistent_keep_alpha := lerpf(
			reveal_keep_alpha,
			keep_settled_alpha,
			_first_return_weight
		)
		var replacement_weight := smoothstep(
			0.0,
			0.75,
			fortress_replacement_alpha
		)
		_keep.modulate.a = persistent_keep_alpha * (
			1.0 - replacement_weight
		)
	if _first_reveal_light != null:
		var reveal_light_energy := first_reveal_light_peak * reveal_t
		_first_reveal_light.energy = lerpf(
			reveal_light_energy,
			first_reveal_light_peak * 0.5,
			_first_return_weight
		)


func _smootherstep_range(start: float, end: float, value: float) -> float:
	if is_equal_approx(start, end):
		return 1.0 if value >= end else 0.0
	return _smootherstep(clampf((value - start) / (end - start), 0.0, 1.0))


func _apply_camera_progress(t: float) -> void:
	if _first_return_progress < 0.999:
		_apply_first_camera_envelope()
		return
	_apply_second_camera_envelope(t)


func _segment_progress(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> float:
	var axis := segment_end - segment_start
	var length_squared := axis.length_squared()
	if length_squared <= 0.001:
		return 0.0
	return clampf(
		(point - segment_start).dot(axis) / length_squared,
		0.0,
		1.0
	)


func _smootherstep(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * t * (
		t * (t * 6.0 - 15.0) + 10.0
	)


func _evaluate_first_camera_envelope() -> Dictionary:
	if (
		_player == null
		or _first_camera_control_start == null
		or _reveal_control_start == null
		or _reveal_control_end == null
		or _first_camera_return_complete == null
	):
		return {
			"enter_progress": 0.0,
			"return_progress": 0.0,
			"enter_weight": 0.0,
			"return_weight": 0.0,
			"camera_weight": 0.0,
		}

	var enter_progress := _segment_progress(
		_player.global_position,
		_first_camera_control_start.global_position,
		_reveal_control_start.global_position
	)
	var return_progress := _segment_progress(
		_player.global_position,
		_reveal_control_end.global_position,
		_first_camera_return_complete.global_position
	)
	var enter_weight := _smootherstep(enter_progress)
	var return_weight := _smootherstep(return_progress)
	return {
		"enter_progress": enter_progress,
		"return_progress": return_progress,
		"enter_weight": enter_weight,
		"return_weight": return_weight,
		"camera_weight": enter_weight * (1.0 - return_weight),
	}


func _update_first_camera_envelope_state() -> void:
	var envelope := _evaluate_first_camera_envelope()
	_first_enter_progress = float(
		envelope.get("enter_progress", 0.0)
	)
	_first_return_progress = float(
		envelope.get("return_progress", 0.0)
	)
	_first_enter_weight = float(
		envelope.get("enter_weight", 0.0)
	)
	_first_return_weight = float(
		envelope.get("return_weight", 0.0)
	)
	_first_camera_weight = float(
		envelope.get("camera_weight", 0.0)
	)
	_first_camera_phase = _get_first_camera_phase(
		_first_enter_progress,
		_first_return_progress
	)

	# Compatibility state remains derived; it never owns framing.
	_first_reveal_weight = _first_enter_weight
	_first_progress_weight = _first_return_progress
	_return_to_play_weight = _first_return_weight
	_first_reveal_complete = _first_enter_progress >= 0.999


func _evaluate_second_camera_envelope() -> Dictionary:
	if (
		_player == null
		or _second_vista_start == null
		or _second_vista_full == null
		or _second_vista_end == null
	):
		return {
			"enter_progress": 0.0,
			"return_progress": 0.0,
			"enter_weight": 0.0,
			"return_weight": 0.0,
			"camera_weight": 0.0,
		}
	var enter_progress := _segment_progress(
		_player.global_position,
		_second_vista_start.global_position,
		_second_vista_full.global_position
	)
	var return_progress := _segment_progress(
		_player.global_position,
		_second_vista_full.global_position,
		_second_vista_end.global_position
	)
	var enter_weight := _smootherstep(enter_progress)
	var return_weight := _smootherstep(return_progress)
	return {
		"enter_progress": enter_progress,
		"return_progress": return_progress,
		"enter_weight": enter_weight,
		"return_weight": return_weight,
		"camera_weight": enter_weight * (1.0 - return_weight),
	}


func _update_second_camera_envelope_state() -> void:
	var envelope := _evaluate_second_camera_envelope()
	_second_enter_progress = float(
		envelope.get("enter_progress", 0.0)
	)
	_second_return_progress = float(
		envelope.get("return_progress", 0.0)
	)
	_second_enter_weight = float(
		envelope.get("enter_weight", 0.0)
	)
	_second_return_weight = float(
		envelope.get("return_weight", 0.0)
	)
	_second_camera_weight = float(
		envelope.get("camera_weight", 0.0)
	)
	_second_camera_phase = _get_second_camera_phase(
		_second_enter_progress,
		_second_return_progress
	)

	# Legacy fields remain position-derived for debug and event compatibility.
	_second_reveal_weight = _second_enter_weight
	_second_progress_weight = _second_return_progress
	_second_return_to_play_weight = _second_return_weight
	_second_reveal_complete = _second_return_progress >= 0.999


func _get_second_camera_phase(
	enter_progress: float,
	return_progress: float
) -> String:
	if enter_progress <= 0.001:
		return "SECOND_GAMEPLAY_BEFORE"
	if enter_progress < 0.999:
		return "SECOND_BLEND_TO_CINEMATIC"
	if return_progress <= 0.001:
		return "SECOND_CINEMATIC_APEX"
	if return_progress < 0.999:
		return "SECOND_BLEND_TO_GAMEPLAY"
	return "SECOND_GAMEPLAY_AFTER"


func _get_first_camera_phase(
	enter_progress: float,
	return_progress: float
) -> String:
	if enter_progress <= 0.001:
		return "GAMEPLAY_BEFORE"
	if enter_progress < 0.999:
		return "BLEND_TO_CINEMATIC"
	if return_progress <= 0.001:
		return "CINEMATIC_APEX"
	if return_progress < 0.999:
		return "BLEND_TO_GAMEPLAY"
	return "GAMEPLAY_AFTER"


func _apply_first_camera_envelope() -> void:
	if (
		_player == null
		or _first_reveal_camera_anchor == null
		or _presentation_anchor == null
	):
		return

	_presentation_anchor.global_position = (
		_player.global_position.lerp(
			_first_reveal_camera_anchor.global_position,
			_first_camera_weight
		)
	)
	_set_camera_follow_target(_presentation_anchor)

	var gameplay_offset := CAMERA_INTRO_TIGHT_OFFSET.lerp(
		CAMERA_TRAVERSE_OFFSET,
		_first_return_weight
	)
	var gameplay_zoom := CAMERA_INTRO_TIGHT_ZOOM.lerp(
		CAMERA_TRAVERSE_ZOOM,
		_first_return_weight
	)
	_set_camera_target(
		gameplay_offset.lerp(
			CAMERA_FIRST_REVEAL_OFFSET,
			_first_camera_weight
		),
		gameplay_zoom.lerp(
			CAMERA_FIRST_REVEAL_ZOOM,
			_first_camera_weight
		)
	)


func _apply_second_camera_envelope(t: float) -> void:
	if (
		_player == null
		or _second_reveal_camera_anchor == null
		or _presentation_anchor == null
	):
		return
	_presentation_anchor.global_position = (
		_player.global_position.lerp(
			_second_reveal_camera_anchor.global_position,
			_second_camera_weight
		)
	)
	_set_camera_follow_target(_presentation_anchor)

	var gameplay_offset := _get_gameplay_camera_offset(t)
	var gameplay_zoom := _get_gameplay_camera_zoom(t)
	_set_camera_target(
		gameplay_offset.lerp(
			CAMERA_SECOND_REVEAL_OFFSET,
			_second_camera_weight
		),
		gameplay_zoom.lerp(
			CAMERA_SECOND_REVEAL_ZOOM,
			_second_camera_weight
		)
	)


func _apply_gameplay_camera_progress(t: float) -> void:
	_set_camera_target(
		_get_gameplay_camera_offset(t),
		_get_gameplay_camera_zoom(t)
	)


func _get_gameplay_camera_offset(t: float) -> Vector2:
	var second_end_progress := _marker_progress(_second_vista_end) if _second_vista_end != null else 0.86
	var end_progress := _marker_progress(_end) if _end != null else 1.0
	var final_weight := smoothstep(
		second_end_progress,
		maxf(end_progress, second_end_progress + 0.001),
		t
	)
	return CAMERA_TRAVERSE_OFFSET.lerp(
		CAMERA_FINAL_GATE_OFFSET,
		final_weight
	)


func _get_gameplay_camera_zoom(t: float) -> Vector2:
	var second_end_progress := _marker_progress(_second_vista_end) if _second_vista_end != null else 0.86
	var end_progress := _marker_progress(_end) if _end != null else 1.0
	var final_weight := smoothstep(
		second_end_progress,
		maxf(end_progress, second_end_progress + 0.001),
		t
	)
	return CAMERA_TRAVERSE_ZOOM.lerp(
		CAMERA_FINAL_GATE_ZOOM,
		final_weight
	)


func _ensure_presentation_anchor() -> void:
	if _presentation_anchor != null and is_instance_valid(_presentation_anchor):
		return
	_presentation_anchor = Marker2D.new()
	_presentation_anchor.name = "CameraPresentationAnchor"
	add_child(_presentation_anchor)


func _track_operator_with_presentation_anchor() -> void:
	if _player == null or _presentation_anchor == null:
		return
	_presentation_anchor.global_position = _player.global_position
	_set_camera_follow_target(_presentation_anchor)


func _set_camera_follow_target(target: Node2D) -> void:
	if _camera == null:
		return
	if _camera.has_method("set_follow_target"):
		_camera.call("set_follow_target", target)


func _set_camera_target(target_offset: Vector2, target_zoom: Vector2) -> void:
	_camera_target_offset = target_offset
	_camera_target_zoom = target_zoom
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_node_or_null(camera_path) as Camera2D
	if _camera != null and _camera.has_method("set_presentation_framing"):
		_camera.call("set_presentation_framing", true, target_offset, target_zoom)


func _get_second_cinematic_alpha() -> float:
	return _smootherstep_range(
		0.08,
		0.92,
		_second_camera_weight
	)


func _get_fortress_layer_alphas(
	exit_shadow_alpha: float
) -> Vector3:
	var far_reveal := _smootherstep_range(
		0.0,
		0.55,
		_second_enter_weight
	)
	var mid_reveal := _smootherstep_range(
		0.18,
		0.88,
		_second_enter_weight
	)
	var near_reveal := _smootherstep_range(
		0.48,
		1.0,
		_second_enter_weight
	)
	var far_alpha := lerpf(
		far_reveal * 0.66,
		0.58,
		_second_return_weight
	)
	var mid_alpha := lerpf(
		mid_reveal * 0.96,
		0.42,
		_smootherstep_range(0.08, 1.0, _second_return_weight)
	)
	var near_alpha := lerpf(
		near_reveal * 0.68,
		0.10,
		_smootherstep_range(0.0, 0.68, _second_return_weight)
	)
	var final_fade := 1.0 - smoothstep(
		0.05,
		0.85,
		exit_shadow_alpha
	)
	return Vector3(
		far_alpha,
		mid_alpha,
		near_alpha
	) * final_fade


func _is_second_camera_active() -> bool:
	return _second_camera_weight > 0.001


func _compute_route_progress() -> float:
	if (
		_player == null
		or _start == null
		or _end == null
	):
		return _last_progress
	var progress_axis := _end.global_position - _start.global_position
	var total := progress_axis.length()
	if total <= 0.01:
		return _last_progress
	var along := (
		_player.global_position - _start.global_position
	).dot(progress_axis.normalized())
	return clampf(along / total, 0.0, 1.0)


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
