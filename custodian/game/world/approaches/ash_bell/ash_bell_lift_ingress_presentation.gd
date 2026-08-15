extends Node2D
class_name AshBellLiftIngressPresentation

const OPERATOR_PRESENTATION_RIG_SCENE := preload(
	"res://game/actors/operator/presentation/operator_presentation_rig_2d.tscn"
)
const PROCGEN_DRESSING_CLEARANCE_LOCAL := Rect2(
	Vector2(-416.0, -432.0),
	Vector2(832.0, 608.0)
)
const LIFT_BACK_IDLE_Z := 1
const LIFT_FRONT_IDLE_Z := 3
const LIFT_BACK_TRAVEL_Z := 5
const RIDER_TRAVEL_Z := 6
const LIFT_FRONT_TRAVEL_Z := 7
const FOREGROUND_IDLE_Z := 1
const FOREGROUND_TRAVEL_Z := 20

@export var descent_distance := 176.0
@export var descent_duration := 1.05
@export var shaft_scroll_distance := 384.0

@onready var lift_root: Node2D = $LiftRoot
@onready var rider_anchor: Marker2D = $LiftRoot/RiderAnchor
@onready var boarding_marker: Marker2D = $BoardingMarker
@onready var entrance_threshold_marker: Marker2D = $EntranceThresholdMarker
@onready var interaction_approach_marker: Marker2D = $InteractionApproachMarker
@onready var shaft_window: Polygon2D = $RearMassRoot/ShaftWindow
@onready var shaft_scroll: Sprite2D = $RearMassRoot/ShaftWindow/ShaftScroll
@onready var platform_back_idle: Sprite2D = $LiftRoot/PlatformBackIdle
@onready var platform_back_vibrate: AnimatedSprite2D = $LiftRoot/PlatformBackVibrate
@onready var front_lip_idle: Sprite2D = $LiftRoot/PlatformFront/FrontLipIdle
@onready var front_lip_vibrate: AnimatedSprite2D = $LiftRoot/PlatformFront/FrontLipVibrate
@onready var dust_burst: AnimatedSprite2D = $DustBurst
@onready var entrance_mask: Node2D = $ForegroundOccluderRoot
@onready var foreground_occluder: Sprite2D = $ForegroundOccluderRoot/ForegroundOccluder
@onready var lamp: AnimatedSprite2D = $LampFxRoot/Lamp

var _playing := false
var _lift_start_position := Vector2.ZERO
var _shaft_start_rect := Rect2()
var _presentation_rig: OperatorPresentationRig2D
var _active_tween: Tween


func _ready() -> void:
	_lift_start_position = lift_root.position
	shaft_scroll.region_enabled = true
	if shaft_scroll.region_rect.size == Vector2.ZERO:
		shaft_scroll.region_rect = Rect2(0.0, 0.0, 256.0, 320.0)
	_shaft_start_rect = shaft_scroll.region_rect
	_set_platform_vibrating(false)
	shaft_window.visible = false
	shaft_window.modulate.a = 0.0
	dust_burst.visible = false
	_set_idle_depth_mode()
	if not dust_burst.animation_finished.is_connected(_on_dust_finished):
		dust_burst.animation_finished.connect(_on_dust_finished)
	lamp.play(&"flicker")


func play_descent(actor: Node2D) -> void:
	if _playing or actor == null:
		return
	if not _create_presentation_rig(actor):
		_restore_operator_presentation()
		return
	_playing = true
	_presentation_rig.z_as_relative = false
	_presentation_rig.z_index = RIDER_TRAVEL_Z
	_set_platform_vibrating(true)
	_set_travel_depth_mode()
	shaft_window.visible = true
	shaft_window.modulate.a = 0.0
	dust_burst.visible = true
	dust_burst.play(&"burst")
	var lift_target_y := lift_root.position.y + descent_distance
	var shaft_start_y := shaft_scroll.region_rect.position.y
	var shaft_target_y := shaft_start_y - shaft_scroll_distance
	var reveal_duration := descent_duration * 0.25
	var hide_duration := descent_duration - reveal_duration
	var reveal_distance := descent_distance * 0.25
	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.tween_property(
		lift_root,
		"position:y",
		lift_root.position.y + reveal_distance,
		reveal_duration
	)
	_active_tween.tween_method(
		_set_shaft_scroll_y,
		shaft_start_y,
		lerpf(shaft_start_y, shaft_target_y, 0.25),
		reveal_duration
	)
	_active_tween.tween_property(shaft_window, "modulate:a", 1.0, reveal_duration)
	await _active_tween.finished
	if not _playing or _presentation_rig == null:
		return
	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.tween_property(
		lift_root,
		"position:y",
		lift_target_y,
		hide_duration
	)
	_active_tween.tween_method(
		_set_shaft_scroll_y,
		shaft_scroll.region_rect.position.y,
		shaft_target_y,
		hide_duration
	)
	await _active_tween.finished
	if not _playing:
		return
	_restore_operator_presentation()
	_set_idle_depth_mode()
	_playing = false
	_active_tween = null


func get_interaction_approach_position() -> Vector2:
	return interaction_approach_marker.global_position


func play_ascent(actor: Node2D) -> void:
	if _playing or actor == null:
		return
	if not _create_presentation_rig(actor):
		_restore_operator_presentation()
		return
	_playing = true
	lift_root.position = _lift_start_position + Vector2(0.0, descent_distance)
	shaft_scroll.region_rect = Rect2(
		_shaft_start_rect.position - Vector2(0.0, shaft_scroll_distance),
		_shaft_start_rect.size
	)
	_set_platform_vibrating(true)
	shaft_window.visible = true
	shaft_window.modulate.a = 1.0
	_set_travel_depth_mode()
	_presentation_rig.z_as_relative = false
	_presentation_rig.z_index = RIDER_TRAVEL_Z
	var hidden_duration := descent_duration * 0.58
	var reveal_duration := descent_duration - hidden_duration
	var reveal_lift_y := lerpf(lift_root.position.y, _lift_start_position.y, 0.58)
	var reveal_shaft_y := lerpf(
		shaft_scroll.region_rect.position.y,
		_shaft_start_rect.position.y,
		0.58
	)
	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(
		lift_root,
		"position:y",
		reveal_lift_y,
		hidden_duration
	)
	_active_tween.tween_method(
		_set_shaft_scroll_y,
		shaft_scroll.region_rect.position.y,
		reveal_shaft_y,
		hidden_duration
	)
	await _active_tween.finished
	if not _playing or _presentation_rig == null:
		return
	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(
		lift_root,
		"position:y",
		_lift_start_position.y,
		reveal_duration
	)
	_active_tween.tween_method(
		_set_shaft_scroll_y,
		reveal_shaft_y,
		_shaft_start_rect.position.y,
		reveal_duration
	)
	await _active_tween.finished
	if not _playing:
		return
	_set_platform_vibrating(false)
	_restore_operator_presentation()
	shaft_window.visible = false
	shaft_window.modulate.a = 0.0
	_set_idle_depth_mode()
	_playing = false
	_active_tween = null


func reset_presentation() -> void:
	cancel_presentation()
	lift_root.position = _lift_start_position
	shaft_scroll.region_rect = _shaft_start_rect
	shaft_window.visible = false
	shaft_window.modulate.a = 0.0
	_set_platform_vibrating(false)
	_set_idle_depth_mode()
	dust_burst.visible = false
	dust_burst.stop()
	dust_burst.frame = 0


func cancel_presentation() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	_restore_operator_presentation()
	_playing = false
	shaft_window.visible = false
	shaft_window.modulate.a = 0.0
	_set_idle_depth_mode()


func is_playing() -> bool:
	return _playing


func has_presentation_puppet() -> bool:
	return _presentation_rig != null and is_instance_valid(_presentation_rig)


func get_presentation_puppet() -> OperatorPresentationRig2D:
	return _presentation_rig if has_presentation_puppet() else null


func get_boarding_position() -> Vector2:
	return boarding_marker.global_position


func get_procgen_dressing_clearance_world_rect() -> Rect2:
	return Rect2(
		global_position + PROCGEN_DRESSING_CLEARANCE_LOCAL.position,
		PROCGEN_DRESSING_CLEARANCE_LOCAL.size
	)


func is_actor_boarded(actor: Node2D) -> bool:
	var local_position := to_local(actor.global_position)
	return (
		absf(local_position.x) <= 42.0
		and local_position.y >= -54.0
		and local_position.y <= 18.0
	)


func _create_presentation_rig(actor: Node2D) -> bool:
	_restore_operator_presentation()
	_presentation_rig = (
		OPERATOR_PRESENTATION_RIG_SCENE.instantiate()
		as OperatorPresentationRig2D
	)
	if _presentation_rig == null:
		return false
	rider_anchor.add_child(_presentation_rig)
	_presentation_rig.position = Vector2.ZERO
	_presentation_rig.z_as_relative = false
	_presentation_rig.z_index = RIDER_TRAVEL_Z
	if not _presentation_rig.capture_from_operator(actor):
		_presentation_rig.free()
		_presentation_rig = null
		return false
	_presentation_rig.play_pose(&"lift_braced")
	_presentation_rig.hide_source_visuals()
	return true


func _restore_operator_presentation() -> void:
	if _presentation_rig == null:
		return
	if is_instance_valid(_presentation_rig):
		_presentation_rig.restore_source_visuals()
		_presentation_rig.free()
	_presentation_rig = null


func _set_shaft_scroll_y(value: float) -> void:
	var rect := shaft_scroll.region_rect
	rect.position.y = value
	shaft_scroll.region_rect = rect


func _set_platform_vibrating(is_vibrating: bool) -> void:
	platform_back_idle.visible = not is_vibrating
	front_lip_idle.visible = not is_vibrating
	platform_back_vibrate.visible = is_vibrating
	front_lip_vibrate.visible = is_vibrating
	if is_vibrating:
		platform_back_vibrate.play(&"vibrate")
		front_lip_vibrate.play(&"vibrate")
	else:
		platform_back_vibrate.stop()
		front_lip_vibrate.stop()


func _set_idle_depth_mode() -> void:
	lift_root.z_index = 0
	platform_back_idle.z_as_relative = false
	platform_back_vibrate.z_as_relative = false
	platform_back_idle.z_index = LIFT_BACK_IDLE_Z
	platform_back_vibrate.z_index = LIFT_BACK_IDLE_Z
	$LiftRoot/PlatformFront.z_as_relative = false
	$LiftRoot/PlatformFront.z_index = LIFT_FRONT_IDLE_Z
	entrance_mask.z_index = FOREGROUND_IDLE_Z
	foreground_occluder.visible = false


func _set_travel_depth_mode() -> void:
	lift_root.z_index = 0
	platform_back_idle.z_as_relative = false
	platform_back_vibrate.z_as_relative = false
	platform_back_idle.z_index = LIFT_BACK_TRAVEL_Z
	platform_back_vibrate.z_index = LIFT_BACK_TRAVEL_Z
	$LiftRoot/PlatformFront.z_as_relative = false
	$LiftRoot/PlatformFront.z_index = LIFT_FRONT_TRAVEL_Z
	entrance_mask.z_index = FOREGROUND_TRAVEL_Z
	foreground_occluder.visible = true


func _on_dust_finished() -> void:
	dust_burst.visible = false


func _exit_tree() -> void:
	cancel_presentation()
