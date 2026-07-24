extends Node
class_name SunderedKeepRevealDirector

signal reveal_started
signal reveal_completed
signal second_reveal_started
signal second_reveal_completed

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

@export_range(0.0, 0.4, 0.01) var anticipation_duration := 0.18
@export_range(0.1, 1.2, 0.01) var reveal_in_duration := 0.80
@export_range(0.2, 2.5, 0.05) var reveal_hold_duration := 1.80
@export_range(0.1, 1.0, 0.01) var return_duration := 0.70
@export_range(0.1, 1.0, 0.01) var atmosphere_settle_duration := 0.45
@export_range(0.1, 1.2, 0.01) var second_reveal_in_duration := 0.65
@export_range(0.2, 2.0, 0.05) var second_reveal_hold_duration := 1.30
@export_range(0.1, 1.0, 0.01) var second_return_duration := 0.55
@export_range(0.0, 1.0, 0.05) var reveal_movement_multiplier := 0.25

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
var _second_reveal_played := false
var _second_reveal_running := false
var _second_reveal_finished := false
var _near_fog_origin := Vector2.ZERO
var _mid_fog_origin := Vector2.ZERO
var _edge_mist_origin := Vector2.ZERO


func _ready() -> void:
	refresh_bindings()
	_prepare_initial_state()


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


func play_first_reveal() -> void:
	if _reveal_played:
		return
	_reveal_played = true
	_reveal_running = true
	reveal_started.emit()
	refresh_bindings()
	_set_player_movement_multiplier(reveal_movement_multiplier)
	if _vista_controller != null:
		_vista_controller.begin_first_reveal()

	var anticipation := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if _near_fog != null:
		anticipation.parallel().tween_property(_near_fog, "modulate:a", minf(_near_fog.modulate.a + 0.12, 1.0), anticipation_duration)
	if _mid_fog != null:
		anticipation.parallel().tween_property(_mid_fog, "modulate:a", minf(_mid_fog.modulate.a + 0.08, 1.0), anticipation_duration)
	await anticipation.finished

	var reveal_in := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal_in.tween_method(
		_set_first_reveal_weight,
		0.0,
		1.0,
		reveal_in_duration
	)
	if _near_fog is Node2D:
		reveal_in.parallel().tween_property(
			_near_fog,
			"position",
			_near_fog_origin + NEAR_FOG_TRAVEL,
			reveal_in_duration
		)
		reveal_in.parallel().tween_property(
			_near_fog,
			"modulate:a",
			0.04,
			reveal_in_duration
		)
	if _mid_fog is Node2D:
		reveal_in.parallel().tween_property(
			_mid_fog,
			"position",
			_mid_fog_origin + MID_FOG_TRAVEL,
			reveal_in_duration
		)
		reveal_in.parallel().tween_property(
			_mid_fog,
			"modulate:a",
			0.08,
			reveal_in_duration
		)
	if _edge_mist is Node2D:
		reveal_in.parallel().tween_property(
			_edge_mist,
			"position",
			_edge_mist_origin + EDGE_MIST_TRAVEL,
			reveal_in_duration
		)
	if _reveal_light != null:
		reveal_in.parallel().tween_property(
			_reveal_light,
			"energy",
			REVEAL_LIGHT_PEAK,
			reveal_in_duration * 0.72
		)
	await reveal_in.finished

	if _vista_controller != null:
		_vista_controller.hold_first_reveal()

	await get_tree().create_timer(reveal_hold_duration).timeout

	_set_player_movement_multiplier(1.0)
	if _vista_controller != null:
		_vista_controller.begin_return_to_gameplay()

	var return_tween := create_tween() \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_method(
		_set_return_to_gameplay_weight,
		0.0,
		1.0,
		return_duration
	)
	if _reveal_light != null:
		return_tween.parallel().tween_property(
			_reveal_light,
			"energy",
			0.0,
			return_duration
		)
	await return_tween.finished

	if _vista_controller != null:
		_vista_controller.complete_first_reveal()

	var settle := create_tween() \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	if _far_fog != null:
		settle.tween_property(
			_far_fog,
			"modulate:a",
			maxf(_far_fog.modulate.a, 0.16),
			atmosphere_settle_duration
		)
	await settle.finished

	_resolve_destination_prompt()
	if _destination_prompt != null:
		var prompt_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		prompt_tween.tween_property(_destination_prompt, "modulate:a", 1.0, 0.18)
		await prompt_tween.finished
	_reveal_running = false
	_reveal_finished = true
	reveal_completed.emit()


func play_second_reveal() -> void:
	if _second_reveal_played:
		return
	_second_reveal_played = true
	if _reveal_running:
		await reveal_completed
	if not _reveal_finished:
		_second_reveal_played = false
		return

	_second_reveal_running = true
	second_reveal_started.emit()
	refresh_bindings()
	_set_player_movement_multiplier(reveal_movement_multiplier)
	if _vista_controller != null:
		_vista_controller.begin_second_reveal()

	var reveal_in := create_tween() \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	reveal_in.tween_method(
		_set_second_reveal_weight,
		0.0,
		1.0,
		second_reveal_in_duration
	)
	await reveal_in.finished

	if _vista_controller != null:
		_vista_controller.hold_second_reveal()
	await get_tree().create_timer(
		second_reveal_hold_duration
	).timeout

	_set_player_movement_multiplier(1.0)
	if _vista_controller != null:
		_vista_controller.begin_second_return_to_gameplay()

	var return_tween := create_tween() \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_method(
		_set_second_return_to_gameplay_weight,
		0.0,
		1.0,
		second_return_duration
	)
	await return_tween.finished

	if _vista_controller != null:
		_vista_controller.complete_second_reveal()
	_second_reveal_running = false
	_second_reveal_finished = true
	second_reveal_completed.emit()


func play_reveal() -> void:
	play_first_reveal()


func has_played() -> bool:
	return _reveal_played


func is_reveal_complete() -> bool:
	return _reveal_finished


func get_reveal_state() -> Dictionary:
	return {
		"played": _reveal_played,
		"running": _reveal_running,
		"complete": _reveal_finished,
		"second_played": _second_reveal_played,
		"second_running": _second_reveal_running,
		"second_complete": _second_reveal_finished,
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


func _set_first_reveal_weight(weight: float) -> void:
	if _vista_controller != null:
		_vista_controller.set_first_reveal_weight(weight)


func _set_return_to_gameplay_weight(weight: float) -> void:
	if _vista_controller != null:
		_vista_controller.set_return_to_gameplay_weight(weight)


func _set_second_reveal_weight(weight: float) -> void:
	if _vista_controller != null:
		_vista_controller.set_second_reveal_weight(weight)


func _set_second_return_to_gameplay_weight(weight: float) -> void:
	if _vista_controller != null:
		_vista_controller.set_second_return_to_gameplay_weight(weight)


func release_presentation_constraints() -> void:
	_set_player_movement_multiplier(1.0)


func _set_player_movement_multiplier(multiplier: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node2D
	if _player != null \
			and _player.has_method("set_presentation_movement_multiplier"):
		_player.call(
			"set_presentation_movement_multiplier",
			clampf(multiplier, 0.0, 1.0)
		)


func _exit_tree() -> void:
	release_presentation_constraints()
