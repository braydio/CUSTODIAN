extends Node2D
class_name AshBellLiftIngressPresentation

@export var descent_distance := 176.0
@export var descent_duration := 1.05
@export var shaft_scroll_distance := 384.0

@onready var lift_root: Node2D = $LiftRoot
@onready var rider_anchor: Marker2D = $LiftRoot/RiderAnchor
@onready var shaft_scroll: Sprite2D = $ShaftWindow/ShaftScroll
@onready var platform_idle: Sprite2D = $LiftRoot/PlatformIdle
@onready var platform_vibrate: AnimatedSprite2D = $LiftRoot/PlatformVibrate
@onready var dust_burst: AnimatedSprite2D = $DustBurst
@onready var lamp: AnimatedSprite2D = $Lamp

var _playing := false
var _lift_start_position := Vector2.ZERO
var _shaft_start_rect := Rect2()


func _ready() -> void:
	_lift_start_position = lift_root.position
	shaft_scroll.region_enabled = true
	if shaft_scroll.region_rect.size == Vector2.ZERO:
		shaft_scroll.region_rect = Rect2(0.0, 0.0, 256.0, 320.0)
	_shaft_start_rect = shaft_scroll.region_rect
	platform_vibrate.visible = false
	lamp.play(&"flicker")


func play_descent(actor: Node2D) -> void:
	if _playing or actor == null:
		return
	_playing = true
	var original_process_mode := actor.process_mode
	var original_z_index := actor.z_index
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	# Keep the modular Operator layers in their normal relative render context.
	# The foreground lip sits at Z 20: the rider begins above it, then passes
	# behind it only after entering the shaft.
	actor.z_index = 40
	actor.global_position = rider_anchor.global_position
	platform_idle.visible = false
	platform_vibrate.visible = true
	platform_vibrate.play(&"vibrate")
	dust_burst.play(&"burst")
	var lift_target_y := lift_root.position.y + descent_distance
	var actor_target_y := actor.global_position.y + descent_distance
	var shaft_start_y := shaft_scroll.region_rect.position.y
	var shaft_target_y := shaft_start_y - shaft_scroll_distance
	var reveal_duration := descent_duration * 0.42
	var hide_duration := descent_duration - reveal_duration
	var reveal_distance := descent_distance * 0.42
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(lift_root, "position:y", lift_root.position.y + reveal_distance, reveal_duration)
	tween.tween_property(actor, "global_position:y", actor.global_position.y + reveal_distance, reveal_duration)
	tween.tween_method(
		_set_shaft_scroll_y,
		shaft_start_y,
		lerpf(shaft_start_y, shaft_target_y, 0.42),
		reveal_duration
	)
	await tween.finished
	if is_instance_valid(actor):
		actor.z_index = 0
	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(lift_root, "position:y", lift_target_y, hide_duration)
	tween.tween_property(actor, "global_position:y", actor_target_y, hide_duration)
	tween.tween_method(_set_shaft_scroll_y, shaft_scroll.region_rect.position.y, shaft_target_y, hide_duration)
	await tween.finished
	if is_instance_valid(actor):
		actor.process_mode = original_process_mode
		actor.z_index = original_z_index
	_playing = false


func play_ascent(actor: Node2D) -> void:
	if _playing or actor == null:
		return
	_playing = true
	# World restoration already placed the Operator at the captured map point.
	# Never move it back into the shaft; this return pass is lift presentation
	# only, while the ingress overlap guard prevents immediate re-entry.
	lift_root.position = _lift_start_position + Vector2(0.0, descent_distance)
	shaft_scroll.region_rect = Rect2(
		_shaft_start_rect.position - Vector2(0.0, shaft_scroll_distance),
		_shaft_start_rect.size
	)
	platform_idle.visible = false
	platform_vibrate.visible = true
	platform_vibrate.play(&"vibrate")
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lift_root, "position:y", _lift_start_position.y, descent_duration)
	tween.tween_method(
		_set_shaft_scroll_y,
		shaft_scroll.region_rect.position.y,
		_shaft_start_rect.position.y,
		descent_duration
	)
	await tween.finished
	platform_vibrate.stop()
	platform_vibrate.visible = false
	platform_idle.visible = true
	_playing = false


func reset_presentation() -> void:
	_playing = false
	lift_root.position = _lift_start_position
	shaft_scroll.region_rect = _shaft_start_rect
	platform_vibrate.stop()
	platform_vibrate.visible = false
	platform_idle.visible = true
	dust_burst.stop()
	dust_burst.frame = 0


func is_playing() -> bool:
	return _playing


func _set_shaft_scroll_y(value: float) -> void:
	var rect := shaft_scroll.region_rect
	rect.position.y = value
	shaft_scroll.region_rect = rect
