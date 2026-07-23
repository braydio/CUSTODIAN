extends Node
class_name SunderedKeepRevealDirector

signal reveal_started
signal reveal_completed

@export var player_path := NodePath("/root/GameRoot/World/Operator")
@export var entry_marker_path := NodePath("../Markers/EntrySpawn")
@export var threshold_marker_path := NodePath("../Markers/RevealStart")
@export var vista_controller_path := NodePath("../VistaController")
@export var near_fog_path := NodePath("../OcclusionRoot/ApproachFogStrip01")
@export var mid_fog_path := NodePath("../OcclusionRoot/ApproachFogStrip02")
@export var far_fog_path := NodePath("../OcclusionRoot/ApproachFogStrip03")
@export var edge_mist_path := NodePath("../OcclusionRoot/ApproachEdgeMistWrap")
@export var reveal_light_path := NodePath("../OcclusionRoot/RevealMoonlightCue")
@export var destination_prompt_path := NodePath("../EventRuntimeRoot/LevelExitAffordance")

@export_range(0.0, 0.25, 0.01) var anticipation_duration := 0.08
@export_range(0.1, 0.6, 0.01) var peel_duration := 0.28
@export_range(0.1, 0.8, 0.01) var settle_duration := 0.45

const NEAR_FOG_TRAVEL := Vector2(-180.0, 58.0)
const MID_FOG_TRAVEL := Vector2(170.0, 42.0)
const EDGE_MIST_TRAVEL := Vector2(0.0, 24.0)
const REVEAL_LIGHT_PEAK := 0.42

var _player: Node2D
var _entry_marker: Node2D
var _threshold_marker: Node2D
var _vista_controller: SunderedKeepVistaController
var _near_fog: CanvasItem
var _mid_fog: CanvasItem
var _far_fog: CanvasItem
var _edge_mist: CanvasItem
var _reveal_light: PointLight2D
var _destination_prompt: CanvasItem
var _reveal_played := false
var _reveal_running := false
var _reveal_finished := false
var _near_fog_origin := Vector2.ZERO
var _mid_fog_origin := Vector2.ZERO
var _edge_mist_origin := Vector2.ZERO


func _ready() -> void:
	refresh_bindings()
	_prepare_initial_state()


func _process(_delta: float) -> void:
	if _reveal_played:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node2D
	if _player == null or _entry_marker == null or _threshold_marker == null:
		return
	if _has_crossed_threshold(_player.global_position):
		play_reveal()


func refresh_bindings() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_entry_marker = get_node_or_null(entry_marker_path) as Node2D
	_threshold_marker = get_node_or_null(threshold_marker_path) as Node2D
	_vista_controller = get_node_or_null(vista_controller_path) as SunderedKeepVistaController
	_near_fog = get_node_or_null(near_fog_path) as CanvasItem
	_mid_fog = get_node_or_null(mid_fog_path) as CanvasItem
	_far_fog = get_node_or_null(far_fog_path) as CanvasItem
	_edge_mist = get_node_or_null(edge_mist_path) as CanvasItem
	_reveal_light = get_node_or_null(reveal_light_path) as PointLight2D
	_destination_prompt = get_node_or_null(destination_prompt_path) as CanvasItem
	if _destination_prompt != null and not _reveal_played:
		_destination_prompt.modulate.a = 0.0
	if _near_fog is Node2D:
		_near_fog_origin = (_near_fog as Node2D).position
	if _mid_fog is Node2D:
		_mid_fog_origin = (_mid_fog as Node2D).position
	if _edge_mist is Node2D:
		_edge_mist_origin = (_edge_mist as Node2D).position


func play_reveal() -> void:
	if _reveal_played:
		return
	_reveal_played = true
	_reveal_running = true
	reveal_started.emit()
	refresh_bindings()
	if _vista_controller != null:
		_vista_controller.begin_reveal_choreography()

	var anticipation := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if _near_fog != null:
		anticipation.parallel().tween_property(_near_fog, "modulate:a", minf(_near_fog.modulate.a + 0.12, 1.0), anticipation_duration)
	if _mid_fog != null:
		anticipation.parallel().tween_property(_mid_fog, "modulate:a", minf(_mid_fog.modulate.a + 0.08, 1.0), anticipation_duration)
	await anticipation.finished

	var peel := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	peel.tween_method(_set_camera_reveal_weight, 0.0, 1.0, peel_duration)
	if _near_fog is Node2D:
		peel.parallel().tween_property(_near_fog, "position", _near_fog_origin + NEAR_FOG_TRAVEL, peel_duration)
		peel.parallel().tween_property(_near_fog, "modulate:a", 0.04, peel_duration)
	if _mid_fog is Node2D:
		peel.parallel().tween_property(_mid_fog, "position", _mid_fog_origin + MID_FOG_TRAVEL, peel_duration)
		peel.parallel().tween_property(_mid_fog, "modulate:a", 0.08, peel_duration)
	if _edge_mist is Node2D:
		peel.parallel().tween_property(_edge_mist, "position", _edge_mist_origin + EDGE_MIST_TRAVEL, peel_duration)
		peel.parallel().tween_property(_edge_mist, "modulate:a", 0.34, peel_duration)
	if _reveal_light != null:
		peel.parallel().tween_property(_reveal_light, "energy", REVEAL_LIGHT_PEAK, peel_duration * 0.72)
	await peel.finished

	if _vista_controller != null:
		_vista_controller.complete_reveal_choreography()
	var settle := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _reveal_light != null:
		settle.parallel().tween_property(_reveal_light, "energy", 0.0, settle_duration)
	if _far_fog != null:
		# Far haze deliberately remains: only a small clarity lift separates the keep.
		settle.parallel().tween_property(_far_fog, "modulate:a", maxf(_far_fog.modulate.a, 0.16), settle_duration)
	await settle.finished

	_resolve_destination_prompt()
	if _destination_prompt != null:
		var prompt_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		prompt_tween.tween_property(_destination_prompt, "modulate:a", 1.0, 0.18)
		await prompt_tween.finished
	_reveal_running = false
	_reveal_finished = true
	reveal_completed.emit()


func has_played() -> bool:
	return _reveal_played


func is_reveal_complete() -> bool:
	return _reveal_finished


func get_reveal_state() -> Dictionary:
	return {
		"played": _reveal_played,
		"running": _reveal_running,
		"complete": _reveal_finished,
		"camera_bound": _vista_controller != null,
		"threshold_bound": _threshold_marker != null,
		"prompt_visible": _destination_prompt != null and _destination_prompt.modulate.a > 0.99,
	}


func _prepare_initial_state() -> void:
	if _reveal_light != null:
		_reveal_light.energy = 0.0
	_resolve_destination_prompt()
	if _destination_prompt != null:
		_destination_prompt.modulate.a = 0.0


func _resolve_destination_prompt() -> void:
	if _destination_prompt == null or not is_instance_valid(_destination_prompt):
		_destination_prompt = get_node_or_null(destination_prompt_path) as CanvasItem


func _set_camera_reveal_weight(weight: float) -> void:
	if _vista_controller != null:
		_vista_controller.set_reveal_choreography_weight(weight)


func _has_crossed_threshold(world_position: Vector2) -> bool:
	var axis := _threshold_marker.global_position - _entry_marker.global_position
	if axis.length_squared() <= 0.01:
		return false
	return (world_position - _threshold_marker.global_position).dot(axis.normalized()) >= 0.0
