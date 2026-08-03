extends Node2D
class_name AshBellLiftIngressPresentation

const OPERATOR_PRESENTATION_RIG_SCENE := preload(
	"res://game/actors/operator/presentation/operator_presentation_rig_2d.tscn"
)

@export var descent_distance := 176.0
@export var descent_duration := 1.05
@export var shaft_scroll_distance := 384.0

@onready var lift_root: Node2D = $LiftRoot
@onready var rider_anchor: Marker2D = $LiftRoot/RiderAnchor
@onready var shaft_scroll: Sprite2D = $ShaftWindow/ShaftScroll
@onready var platform_idle: Sprite2D = $LiftRoot/PlatformIdle
@onready var platform_vibrate: AnimatedSprite2D = $LiftRoot/PlatformVibrate
@onready var dust_burst: AnimatedSprite2D = $DustBurst
@onready var foreground_occluder: Sprite2D = $ForegroundOccluder
@onready var lamp: AnimatedSprite2D = $Lamp

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
	platform_vibrate.visible = false
	foreground_occluder.z_index = 0
	lamp.play(&"flicker")


func play_descent(actor: Node2D) -> void:
	if _playing or actor == null:
		return
	if not _create_presentation_rig(actor):
		_restore_operator_presentation()
		return
	_playing = true
	_presentation_rig.z_as_relative = false
	_presentation_rig.z_index = 40
	platform_idle.visible = false
	platform_vibrate.visible = true
	platform_vibrate.play(&"vibrate")
	foreground_occluder.z_index = 20
	dust_burst.play(&"burst")
	var lift_target_y := lift_root.position.y + descent_distance
	var shaft_start_y := shaft_scroll.region_rect.position.y
	var shaft_target_y := shaft_start_y - shaft_scroll_distance
	var reveal_duration := descent_duration * 0.42
	var hide_duration := descent_duration - reveal_duration
	var reveal_distance := descent_distance * 0.42
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
		lerpf(shaft_start_y, shaft_target_y, 0.42),
		reveal_duration
	)
	await _active_tween.finished
	if not _playing or _presentation_rig == null:
		return
	_presentation_rig.z_index = 0
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
	foreground_occluder.z_index = 0
	_playing = false
	_active_tween = null


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
	platform_idle.visible = false
	platform_vibrate.visible = true
	platform_vibrate.play(&"vibrate")
	foreground_occluder.z_index = 20
	_presentation_rig.z_as_relative = false
	_presentation_rig.z_index = 0
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
	_presentation_rig.z_index = 40
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
	platform_vibrate.stop()
	platform_vibrate.visible = false
	platform_idle.visible = true
	_restore_operator_presentation()
	foreground_occluder.z_index = 0
	_playing = false
	_active_tween = null


func reset_presentation() -> void:
	cancel_presentation()
	lift_root.position = _lift_start_position
	shaft_scroll.region_rect = _shaft_start_rect
	platform_vibrate.stop()
	platform_vibrate.visible = false
	platform_idle.visible = true
	foreground_occluder.z_index = 0
	dust_burst.stop()
	dust_burst.frame = 0


func cancel_presentation() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	_restore_operator_presentation()
	_playing = false
	foreground_occluder.z_index = 0


func is_playing() -> bool:
	return _playing


func has_presentation_puppet() -> bool:
	return _presentation_rig != null and is_instance_valid(_presentation_rig)


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


func _exit_tree() -> void:
	cancel_presentation()
