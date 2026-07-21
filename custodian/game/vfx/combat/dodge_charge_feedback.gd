class_name DodgeChargeFeedback
extends Node2D

const BLUE_TECH := Color("#38d6e8")
const WHITE_CYAN := Color("#d9fbff")
const DANGER := Color("#c94d42")

@export_range(0.0, 1.0, 0.01) var visible_ratio_threshold := 0.27
@export_range(0.0, 2.0, 0.1) var maximum_body_compression_pixels := 2.0
@export_range(0.05, 0.5, 0.01) var ready_frame_duration := 1.0 / 24.0
@export_range(0.05, 0.5, 0.01) var release_frame_duration := 1.0 / 24.0
@export_range(0.05, 0.5, 0.01) var trail_lifetime := 0.14

@onready var meter_sprite: Sprite2D = $MeterSprite
@onready var ready_sprite: Sprite2D = $ReadySprite
@onready var release_sprite: Sprite2D = $ReleaseSprite
@onready var trail_sprite: Sprite2D = $TrailSprite

var _operator: Node2D = null
var _active := false
var _ratio := 0.0
var _charge_ready := false
var _ready_elapsed := 0.0
var _release_elapsed := 0.0
var _trail_elapsed := 0.0
var _particle_phase := 0.0
var _cancel_tween: Tween = null
var _afterimage_tween: Tween = null


func _ready() -> void:
	_operator = get_parent() as Node2D
	if _operator == null:
		push_warning("DodgeChargeFeedback requires an Operator Node2D parent")
		set_process(false)
		return
	_connect_operator_signal(&"dodge_charge_changed", Callable(self, "_on_dodge_charge_changed"))
	_connect_operator_signal(&"dodge_charge_released", Callable(self, "_on_dodge_charge_released"))
	_connect_operator_signal(&"dodge_charge_cancelled", Callable(self, "_on_dodge_charge_cancelled"))
	_reset_visuals()


func _process(delta: float) -> void:
	if _active and not _charge_ready and _ratio >= visible_ratio_threshold:
		_particle_phase = fmod(_particle_phase + delta * 1.8, 1.0)
		queue_redraw()
	_update_ready_animation(delta)
	_update_release_animation(delta)
	_update_trail(delta)


func _connect_operator_signal(signal_name: StringName, callback: Callable) -> void:
	if _operator.has_signal(signal_name) and not _operator.is_connected(signal_name, callback):
		_operator.connect(signal_name, callback)


func _on_dodge_charge_changed(active: bool, ratio: float, ready: bool) -> void:
	var was_ready := _charge_ready
	_active = active
	_ratio = clampf(ratio, 0.0, 1.0)
	_charge_ready = ready
	queue_redraw()
	if not active:
		_set_operator_compression(0.0)
		return
	if _cancel_tween != null and _cancel_tween.is_valid():
		_cancel_tween.kill()
	_reset_meter_appearance()
	meter_sprite.frame = clampi(int(round(_ratio * 7.0)), 0, 7)
	meter_sprite.visible = _ratio >= visible_ratio_threshold
	_set_operator_compression(lerpf(1.0, maximum_body_compression_pixels, _ratio))
	if ready and not was_ready:
		_play_ready_latch()


func _on_dodge_charge_released(ratio: float, direction: Vector2) -> void:
	_active = false
	_ratio = clampf(ratio, 0.0, 1.0)
	_charge_ready = false
	_set_operator_compression(0.0)
	meter_sprite.visible = false
	var launch_direction := direction.normalized()
	if launch_direction == Vector2.ZERO:
		launch_direction = Vector2.RIGHT
	_play_release_burst(_ratio, launch_direction)
	_play_trail(_ratio, launch_direction)
	if _ratio >= 0.999:
		_spawn_single_afterimage()
		_apply_maximum_charge_camera_impulse()


func _on_dodge_charge_cancelled(reason: StringName) -> void:
	_active = false
	_charge_ready = false
	_set_operator_compression(0.0)
	ready_sprite.visible = false
	queue_redraw()
	if reason == &"insufficient_stamina":
		_play_stamina_rejection()
		return
	_contract_meter()


func _reset_meter_appearance() -> void:
	meter_sprite.modulate = Color.WHITE
	meter_sprite.scale = Vector2.ONE
	ready_sprite.modulate = Color.WHITE


func _draw() -> void:
	if not _active or _charge_ready or _ratio < visible_ratio_threshold:
		return
	for index in range(3):
		var progress := fmod(_particle_phase + float(index) / 3.0, 1.0)
		var angle := progress * TAU + float(index) * 1.7
		var radius := lerpf(31.0, 18.0, progress)
		var particle_position := Vector2.from_angle(angle) * radius + Vector2(0.0, 22.0)
		particle_position = particle_position.round()
		var alpha := sin(progress * PI) * 0.55
		draw_rect(Rect2(particle_position, Vector2.ONE), Color(BLUE_TECH, alpha))


func _play_ready_latch() -> void:
	_ready_elapsed = 0.0
	ready_sprite.frame = 0
	ready_sprite.visible = true
	meter_sprite.visible = false
	for device_id in Input.get_connected_joypads():
		Input.start_joy_vibration(device_id, 0.12, 0.28, 0.08)


func _update_ready_animation(delta: float) -> void:
	if not ready_sprite.visible:
		return
	_ready_elapsed += delta
	ready_sprite.frame = mini(int(floor(_ready_elapsed / ready_frame_duration)), 4)
	if _ready_elapsed >= ready_frame_duration * 5.0:
		ready_sprite.visible = false
		if _active and _charge_ready:
			meter_sprite.frame = 7
			meter_sprite.visible = true


func _play_release_burst(ratio: float, direction: Vector2) -> void:
	_release_elapsed = 0.0
	release_sprite.global_position = _operator.global_position
	release_sprite.global_rotation = direction.angle()
	release_sprite.scale = Vector2.ONE * lerpf(0.72, 1.0, ratio)
	release_sprite.modulate = Color.WHITE.lerp(WHITE_CYAN, ratio * 0.35)
	release_sprite.frame = 0
	release_sprite.visible = true


func _update_release_animation(delta: float) -> void:
	if not release_sprite.visible:
		return
	_release_elapsed += delta
	release_sprite.frame = mini(int(floor(_release_elapsed / release_frame_duration)), 5)
	if release_sprite.frame >= 5 and _release_elapsed >= release_frame_duration * 6.0:
		release_sprite.visible = false


func _play_trail(ratio: float, direction: Vector2) -> void:
	_trail_elapsed = 0.0
	var length_scale := lerpf(0.25, 1.0, ratio)
	trail_sprite.global_position = _operator.global_position - direction * (8.0 + 12.0 * length_scale)
	trail_sprite.global_rotation = direction.angle()
	trail_sprite.scale = Vector2(length_scale, lerpf(0.65, 1.0, ratio))
	trail_sprite.modulate = Color(BLUE_TECH, lerpf(0.35, 0.9, ratio))
	trail_sprite.visible = true


func _update_trail(delta: float) -> void:
	if not trail_sprite.visible:
		return
	_trail_elapsed += delta
	var progress := clampf(_trail_elapsed / maxf(0.01, trail_lifetime), 0.0, 1.0)
	trail_sprite.modulate.a = 1.0 - progress
	trail_sprite.scale.x *= maxf(0.0, 1.0 - delta * 4.0)
	if progress >= 1.0:
		trail_sprite.visible = false


func _contract_meter() -> void:
	if not meter_sprite.visible:
		return
	if _cancel_tween != null and _cancel_tween.is_valid():
		_cancel_tween.kill()
	_cancel_tween = create_tween()
	_cancel_tween.set_parallel(true)
	_cancel_tween.tween_property(meter_sprite, "scale", Vector2(0.45, 0.45), 0.08)
	_cancel_tween.tween_property(meter_sprite, "modulate:a", 0.0, 0.08)
	_cancel_tween.chain().tween_callback(Callable(self, "_hide_meter_after_cancel"))


func _hide_meter_after_cancel() -> void:
	meter_sprite.visible = false
	_reset_meter_appearance()


func _play_stamina_rejection() -> void:
	meter_sprite.frame = 0
	meter_sprite.modulate = DANGER
	meter_sprite.scale = Vector2.ONE
	meter_sprite.visible = true
	_contract_meter()


func _spawn_single_afterimage() -> void:
	var body := _operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if body == null or body.sprite_frames == null:
		return
	var frame_texture := body.sprite_frames.get_frame_texture(body.animation, body.frame)
	if frame_texture == null:
		return
	var afterimage := Sprite2D.new()
	afterimage.name = "DodgeChargeAfterimage"
	afterimage.top_level = true
	afterimage.z_as_relative = false
	afterimage.texture = frame_texture
	afterimage.global_position = body.global_position
	afterimage.global_rotation = body.global_rotation
	afterimage.scale = body.global_scale
	afterimage.offset = body.offset
	afterimage.flip_h = body.flip_h
	afterimage.z_index = _operator.z_index - 1
	afterimage.modulate = Color(WHITE_CYAN, 0.42)
	add_child(afterimage)
	_afterimage_tween = create_tween()
	_afterimage_tween.set_parallel(true)
	_afterimage_tween.tween_property(afterimage, "modulate:a", 0.0, 0.12)
	_afterimage_tween.tween_property(afterimage, "scale", afterimage.scale * 1.03, 0.12)
	_afterimage_tween.chain().tween_callback(afterimage.queue_free)


func _apply_maximum_charge_camera_impulse() -> void:
	if not _operator.has_method("_get_world_camera"):
		return
	var camera_variant: Variant = _operator.call("_get_world_camera")
	if camera_variant is Node and (camera_variant as Node).has_method("shake"):
		(camera_variant as Node).call("shake", 0.12, 0.08)


func _set_operator_compression(pixels: float) -> void:
	if _operator.has_method("set_dodge_charge_visual_compression"):
		_operator.call("set_dodge_charge_visual_compression", pixels)


func _reset_visuals() -> void:
	_reset_meter_appearance()
	meter_sprite.visible = false
	ready_sprite.visible = false
	release_sprite.visible = false
	trail_sprite.visible = false
	_set_operator_compression(0.0)
