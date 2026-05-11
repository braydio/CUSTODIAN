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
@export var idle_fx_enabled: bool = false
@export_range(1, 12, 1) var activation_teleport_frame: int = 10
@export_range(0.1, 5.0, 0.1) var teleport_sequence_seconds: float = 2.0
@export var ramp_bottom_local_offset: Vector2 = Vector2(0, 34)
@export var ramp_top_local_offset: Vector2 = Vector2.ZERO
@export var ramp_lane_half_width: float = 16.0
@export var ramp_bottom_width: float = 64.0
@export var ramp_top_width: float = 30.0
@export var ramp_side_block_width: float = 28.0
@export var ramp_side_block_height: float = 44.0
@export var ramp_required_elevation: float = 18.0
@export var ramp_max_elevation: float = 24.0
@export var ramp_speed_multiplier: float = 0.82
@export var ramp_visual_lift_factor: float = 0.5
@export var ramp_visual_z_scale: float = 0.08
@export var ramp_dual_approach: bool = false

var linked_portal: PortalTeleporter = null
var _idle_sprite: AnimatedSprite2D = null
var _action_sprite: AnimatedSprite2D = null
var _hide_action_on_finish: bool = true
var _teleport_sequence_active: bool = false
var _ramp_body_counts: Dictionary = {}
var _portal_player_root: Node2D = null


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	_ensure_collision_shape()
	_ensure_platform_impostor()
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
	if not _has_required_elevation(body):
		return

	var frame := Engine.get_physics_frames()
	var lock_until := int(body.get_meta("portal_teleport_lock_until_frame", 0))
	if frame < lock_until:
		return
	if _teleport_sequence_active:
		return

	_run_teleport_sequence(body, frame)


func _physics_process(_delta: float) -> void:
	if _ramp_body_counts.is_empty():
		return
	for body in _ramp_body_counts.keys():
		if body == null or not is_instance_valid(body):
			_ramp_body_counts.erase(body)
			continue
		_apply_ramp_state(body)


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


func _ensure_platform_impostor() -> void:
	_ensure_portal_player_root()
	_ensure_ramp_zone(
		&"PortalRampAreaSouth",
		ramp_bottom_local_offset,
		ramp_top_local_offset,
		&"_on_south_ramp_body_entered",
		&"_on_south_ramp_body_exited"
	)
	_ensure_side_block_collision(&"PortalSideBlocksSouth", 14.0)
	if ramp_dual_approach:
		var mirrored_bottom := _mirror_vertical_offset(ramp_bottom_local_offset)
		var mirrored_top := _mirror_vertical_offset(ramp_top_local_offset)
		_ensure_ramp_zone(
			&"PortalRampAreaNorth",
			mirrored_bottom,
			mirrored_top,
			&"_on_north_ramp_body_entered",
			&"_on_north_ramp_body_exited"
		)
		_ensure_side_block_collision(&"PortalSideBlocksNorth", -14.0)


func _ensure_portal_player_root() -> void:
	if _portal_player_root == null or not is_instance_valid(_portal_player_root):
		_portal_player_root = get_node_or_null("PortalPlayerRoot") as Node2D
	if _portal_player_root == null:
		_portal_player_root = Node2D.new()
		_portal_player_root.name = "PortalPlayerRoot"
		add_child(_portal_player_root)
	_portal_player_root.position = ramp_top_local_offset


func _ensure_ramp_zone(
	zone_name: StringName,
	bottom_offset: Vector2,
	top_offset: Vector2,
	enter_method: StringName,
	exit_method: StringName
) -> void:
	var ramp_area := get_node_or_null(NodePath(zone_name)) as Area2D
	if ramp_area == null:
		ramp_area = Area2D.new()
		ramp_area.name = zone_name
		add_child(ramp_area)
	ramp_area.position = Vector2.ZERO
	ramp_area.monitoring = true
	ramp_area.monitorable = false
	ramp_area.collision_layer = 0
	ramp_area.collision_mask = 1
	if not ramp_area.body_entered.is_connected(Callable(self, enter_method)):
		ramp_area.body_entered.connect(Callable(self, enter_method))
	if not ramp_area.body_exited.is_connected(Callable(self, exit_method)):
		ramp_area.body_exited.connect(Callable(self, exit_method))
	var ramp_collision := ramp_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if ramp_collision == null:
		ramp_collision = CollisionPolygon2D.new()
		ramp_collision.name = "CollisionPolygon2D"
		ramp_area.add_child(ramp_collision)
	ramp_collision.polygon = PackedVector2Array([
		Vector2(-ramp_bottom_width * 0.5, bottom_offset.y),
		Vector2(ramp_bottom_width * 0.5, bottom_offset.y),
		Vector2(ramp_top_width * 0.5, top_offset.y),
		Vector2(-ramp_top_width * 0.5, top_offset.y),
	])


func _ensure_side_block_collision(root_name: StringName, y_offset: float) -> void:
	var side_block_root := get_node_or_null(NodePath(root_name)) as StaticBody2D
	if side_block_root == null:
		side_block_root = StaticBody2D.new()
		side_block_root.name = root_name
		add_child(side_block_root)
	side_block_root.collision_layer = 1
	side_block_root.collision_mask = 0
	_clear_named_children(side_block_root, "CollisionShape2D")
	var left_shape := _build_side_block_shape(Vector2(-ramp_lane_half_width - ramp_side_block_width * 0.5, y_offset))
	var right_shape := _build_side_block_shape(Vector2(ramp_lane_half_width + ramp_side_block_width * 0.5, y_offset))
	side_block_root.add_child(left_shape)
	side_block_root.add_child(right_shape)


func _build_side_block_shape(position: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ramp_side_block_width, ramp_side_block_height)
	shape.shape = rect
	shape.position = position
	return shape


func _clear_named_children(parent: Node, child_name: String) -> void:
	for child in parent.get_children():
		if child != null and child.name == child_name:
			child.queue_free()


func _on_south_ramp_body_entered(body: Node2D) -> void:
	_on_ramp_body_entered(body)


func _on_south_ramp_body_exited(body: Node2D) -> void:
	_on_ramp_body_exited(body)


func _on_north_ramp_body_entered(body: Node2D) -> void:
	_on_ramp_body_entered(body)


func _on_north_ramp_body_exited(body: Node2D) -> void:
	_on_ramp_body_exited(body)


func _on_ramp_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if not _ramp_body_counts.has(body):
		_ramp_body_counts[body] = 0
	_ramp_body_counts[body] = int(_ramp_body_counts[body]) + 1
	_apply_ramp_state(body)


func _on_ramp_body_exited(body: Node2D) -> void:
	if body == null:
		return
	if not _ramp_body_counts.has(body):
		return
	var count := int(_ramp_body_counts[body]) - 1
	if count > 0:
		_ramp_body_counts[body] = count
		return
	_ramp_body_counts.erase(body)
	_clear_ramp_state(body)


func _apply_ramp_state(body: Node2D) -> void:
	if body == null or not is_instance_valid(body):
		return
	var use_mirrored_ramp := ramp_dual_approach and body.global_position.y < global_position.y
	var bottom_offset := _mirror_vertical_offset(ramp_bottom_local_offset) if use_mirrored_ramp else ramp_bottom_local_offset
	var top_offset := _mirror_vertical_offset(ramp_top_local_offset) if use_mirrored_ramp else ramp_top_local_offset
	var progress := _get_ramp_progress(body.global_position, bottom_offset, top_offset)
	var elevation := lerpf(0.0, ramp_max_elevation, progress)
	if body.has_method("set_fake_elevation"):
		body.call("set_fake_elevation", elevation)
	if body.has_method("set_movement_surface_multiplier"):
		body.call("set_movement_surface_multiplier", ramp_speed_multiplier)


func _clear_ramp_state(body: Node2D) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.has_method("set_fake_elevation"):
		body.call("set_fake_elevation", 0.0)
	if body.has_method("set_movement_surface_multiplier"):
		body.call("set_movement_surface_multiplier", 1.0)


func _get_ramp_progress(world_pos: Vector2, bottom_local_offset: Vector2, top_local_offset: Vector2) -> float:
	var bottom_world := global_position + bottom_local_offset
	var top_world := global_position + top_local_offset
	var distance := bottom_world.y - top_world.y
	if absf(distance) < 0.001:
		return 0.0
	return clampf((bottom_world.y - world_pos.y) / distance, 0.0, 1.0)


func _mirror_vertical_offset(offset: Vector2) -> Vector2:
	return Vector2(offset.x, -offset.y)


func _has_required_elevation(body: Node2D) -> bool:
	var value: Variant = body.get("fake_elevation")
	if value is float or value is int:
		return float(value) >= ramp_required_elevation
	return false


func _ensure_fx_sprites() -> void:
	var frames := SpriteFrames.new()
	_add_strip_animation(frames, &"activate", PORTAL_ACTIVATE_SHEET, PORTAL_ACTIVATE_FRAME_COUNT, activate_fps, false)
	_add_strip_animation(frames, &"arrival", PORTAL_ARRIVAL_SHEET, PORTAL_ARRIVAL_FRAME_COUNT, arrival_fps, false)

	if idle_fx_enabled:
		_add_strip_animation(frames, &"idle", PORTAL_IDLE_SHEET, PORTAL_IDLE_FRAME_COUNT, idle_fps, true)
		_idle_sprite = get_node_or_null("PortalIdleFx") as AnimatedSprite2D
		if _idle_sprite == null:
			_idle_sprite = AnimatedSprite2D.new()
			_idle_sprite.name = "PortalIdleFx"
			add_child(_idle_sprite)
		_configure_fx_sprite(_idle_sprite, frames)
		_idle_sprite.play(&"idle")
	elif _idle_sprite != null and is_instance_valid(_idle_sprite):
		_idle_sprite.queue_free()
		_idle_sprite = null

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
