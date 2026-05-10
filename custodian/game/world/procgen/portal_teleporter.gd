extends Area2D
class_name PortalTeleporter

const PORTAL_IDLE_SHEET := preload("res://content/sprites/environment/props/portal_ring/runtime/fx/portal_ring__fx__interaction__idle_01__omni__6f__161.png")
const PORTAL_ACTIVATE_SHEET := preload("res://content/sprites/environment/props/portal_ring/runtime/fx/portal_ring__fx__interaction__activate_01__omni__12f__161.png")
const PORTAL_ARRIVAL_SHEET := preload("res://content/sprites/environment/props/portal_ring/runtime/fx/portal_ring__fx__interaction__arrival_01__omni__12f__161.png")

const PORTAL_IDLE_FRAME_COUNT := 6
const PORTAL_ACTIVATE_FRAME_COUNT := 12
const PORTAL_ARRIVAL_FRAME_COUNT := 12

@export var trigger_radius: float = 14.0
@export var arrival_offset: Vector2 = Vector2(0, 34)
@export_range(0, 240, 1) var cooldown_frames: int = 24
@export var fx_frame_size: Vector2i = Vector2i(161, 98)
@export var fx_offset: Vector2 = Vector2.ZERO
@export var fx_z_index: int = 6
@export var idle_fps: float = 8.0
@export var activate_fps: float = 16.0
@export var arrival_fps: float = 14.0
@export_range(1, 12, 1) var activation_teleport_frame: int = 10
@export_range(0.1, 5.0, 0.1) var teleport_sequence_seconds: float = 2.0

var linked_portal: PortalTeleporter = null
var _idle_sprite: AnimatedSprite2D = null
var _action_sprite: AnimatedSprite2D = null
var _hide_action_on_finish: bool = true
var _teleport_sequence_active: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	_ensure_collision_shape()
	_ensure_fx_sprites()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func link_to(portal: PortalTeleporter) -> void:
	linked_portal = portal


func get_arrival_position(from_position: Vector2) -> Vector2:
	var offset := arrival_offset
	var approach := global_position - from_position
	if approach.length_squared() > 0.0001:
		offset = approach.normalized() * arrival_offset.length()
	return global_position + offset


func _on_body_entered(body: Node2D) -> void:
	if linked_portal == null or not is_instance_valid(linked_portal):
		return
	if body == null or not body.is_in_group("player"):
		return

	var frame := Engine.get_physics_frames()
	var lock_until := int(body.get_meta("portal_teleport_lock_until_frame", 0))
	if frame < lock_until:
		return
	if _teleport_sequence_active:
		return

	_run_teleport_sequence(body, frame)


func _run_teleport_sequence(body: Node2D, start_frame: int) -> void:
	_teleport_sequence_active = true
	var sequence_frames := int(ceil(teleport_sequence_seconds * float(Engine.physics_ticks_per_second)))
	body.set_meta("portal_teleport_lock_until_frame", start_frame + max(cooldown_frames, sequence_frames))
	_play_action(&"activate")

	var start_msec := Time.get_ticks_msec()
	await _wait_for_action_frame(activation_teleport_frame)
	if body == null or not is_instance_valid(body) or linked_portal == null or not is_instance_valid(linked_portal):
		_teleport_sequence_active = false
		return

	body.global_position = linked_portal.get_arrival_position(global_position)
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO
	var elapsed_seconds := float(Time.get_ticks_msec() - start_msec) / 1000.0
	var arrival_hold_seconds := maxf(0.0, teleport_sequence_seconds - elapsed_seconds)
	linked_portal.call_deferred("play_arrival", arrival_hold_seconds)
	_teleport_sequence_active = false


func play_arrival(hold_seconds: float = -1.0) -> void:
	var visible_seconds := hold_seconds
	if visible_seconds < 0.0:
		visible_seconds = _get_animation_duration(&"arrival")
	_play_action(&"arrival", false)
	await get_tree().create_timer(maxf(visible_seconds, _get_animation_duration(&"arrival"))).timeout
	if _action_sprite != null and _action_sprite.animation == &"arrival":
		_action_sprite.visible = false


func _ensure_collision_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			var existing_shape := (child as CollisionShape2D).shape
			if existing_shape is CircleShape2D:
				(existing_shape as CircleShape2D).radius = trigger_radius
			return

	var shape := CircleShape2D.new()
	shape.radius = trigger_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "PortalTriggerShape"
	collision_shape.shape = shape
	add_child(collision_shape)


func _ensure_fx_sprites() -> void:
	var frames := SpriteFrames.new()
	_add_strip_animation(frames, &"idle", PORTAL_IDLE_SHEET, PORTAL_IDLE_FRAME_COUNT, idle_fps, true)
	_add_strip_animation(frames, &"activate", PORTAL_ACTIVATE_SHEET, PORTAL_ACTIVATE_FRAME_COUNT, activate_fps, false)
	_add_strip_animation(frames, &"arrival", PORTAL_ARRIVAL_SHEET, PORTAL_ARRIVAL_FRAME_COUNT, arrival_fps, false)

	_idle_sprite = get_node_or_null("PortalIdleFx") as AnimatedSprite2D
	if _idle_sprite == null:
		_idle_sprite = AnimatedSprite2D.new()
		_idle_sprite.name = "PortalIdleFx"
		add_child(_idle_sprite)
	_configure_fx_sprite(_idle_sprite, frames)
	_idle_sprite.play(&"idle")

	_action_sprite = get_node_or_null("PortalActionFx") as AnimatedSprite2D
	if _action_sprite == null:
		_action_sprite = AnimatedSprite2D.new()
		_action_sprite.name = "PortalActionFx"
		add_child(_action_sprite)
	_configure_fx_sprite(_action_sprite, frames)
	_action_sprite.visible = false
	if not _action_sprite.animation_finished.is_connected(_on_action_animation_finished):
		_action_sprite.animation_finished.connect(_on_action_animation_finished)


func _configure_fx_sprite(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames
	sprite.position = fx_offset
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = fx_z_index


func _add_strip_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	texture: Texture2D,
	frame_count: int,
	fps: float,
	loop: bool
) -> void:
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * fx_frame_size.x, 0, fx_frame_size.x, fx_frame_size.y)
		frames.add_frame(animation_name, atlas)


func _play_action(animation_name: StringName, hide_on_finish: bool = true) -> void:
	if _action_sprite == null:
		return
	_hide_action_on_finish = hide_on_finish
	_action_sprite.visible = true
	_action_sprite.play(animation_name)


func _on_action_animation_finished() -> void:
	if _action_sprite != null and _hide_action_on_finish:
		_action_sprite.visible = false


func _wait_for_action_frame(frame_number: int) -> void:
	if _action_sprite == null:
		return
	var target_frame := maxi(0, frame_number - 1)
	while _action_sprite != null and _action_sprite.visible and _action_sprite.animation == &"activate":
		if _action_sprite.frame >= target_frame:
			return
		await _action_sprite.frame_changed


func _get_animation_duration(animation_name: StringName) -> float:
	if _action_sprite == null or _action_sprite.sprite_frames == null:
		return 0.0
	if not _action_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var fps := _action_sprite.sprite_frames.get_animation_speed(animation_name)
	if fps <= 0.0:
		return 0.0
	return float(_action_sprite.sprite_frames.get_frame_count(animation_name)) / fps
