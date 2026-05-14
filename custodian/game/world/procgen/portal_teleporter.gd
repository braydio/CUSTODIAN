extends Area2D
class_name PortalTeleporter

const PORTAL_IDLE_SHEET := preload("res://content/sprites/environment/props/portal_ring/runtime/fx/portal_ring__fx__interaction__idle_01__omni__6f__161.png")
const PORTAL_ACTIVATE_SHEET := preload("res://content/sprites/environment/props/portal_ring/runtime/fx/portal_ring__fx__interaction__activate_01__omni__12f__161.png")
const PORTAL_ARRIVAL_SHEET := preload("res://content/sprites/environment/props/portal_ring/runtime/fx/portal_ring__fx__interaction__arrival_01__omni__12f__161.png")

const PORTAL_IDLE_FRAME_COUNT := 6
const PORTAL_ACTIVATE_FRAME_COUNT := 12
const PORTAL_ARRIVAL_FRAME_COUNT := 12

const META_TELEPORT_LOCK_UNTIL := "portal_teleport_lock_until_frame"
const META_RAMP_SOURCE_ID := "portal_ramp_source_instance_id"
const META_RAMP_PROGRESS := "portal_ramp_progress"
const META_RAMP_ELEVATION := "portal_ramp_elevation"

const ELEVATION_SOURCE := "portal_ramp"
const MOVEMENT_SOURCE := "portal_ramp"

@export var linked_portal_path: NodePath
@export var player_group: String = "player"
@export var only_players_can_teleport: bool = true

@export var trigger_radius: float = 14.0
@export var trigger_shape_size: Vector2 = Vector2.ZERO
@export var trigger_shape_offset: Vector2 = Vector2.ZERO
@export var arrival_offset: Vector2 = Vector2(0, 34)
@export_range(0, 240, 1) var cooldown_frames: int = 24

@export var fx_frame_size: Vector2i = Vector2i(161, 98)
@export var fx_offset: Vector2 = Vector2.ZERO
@export var fx_z_index: int = 0
@export var idle_fps: float = 8.0
@export var activate_fps: float = 16.0
@export var arrival_fps: float = 14.0

@export_range(1, 12, 1) var activation_teleport_frame: int = 10
@export_range(0.0, 2.0, 0.05) var arrival_animation_delay_seconds: float = 1.10
@export_range(0.1, 5.0, 0.1) var teleport_sequence_seconds: float = 2.0

@export var require_ramp_elevation_to_teleport: bool = true
@export var require_body_still_in_trigger_at_teleport_frame: bool = true
@export var stop_body_velocity_on_arrival: bool = true

@export var ramp_bottom_local_offset: Vector2 = Vector2(0, 34)
@export var ramp_top_local_offset: Vector2 = Vector2.ZERO
@export var ramp_lane_half_width: float = 16.0
@export var ramp_bottom_width: float = 64.0
@export var ramp_top_width: float = 30.0
@export var ramp_lane_margin: float = 3.0
@export var ramp_side_block_width: float = 28.0
@export var ramp_side_block_height: float = 44.0
@export var ramp_side_block_extra_height: float = 10.0
@export var ramp_required_elevation: float = 18.0
@export var ramp_max_elevation: float = 24.0
@export var ramp_speed_multiplier: float = 0.82
@export var ramp_visual_lift_factor: float = 0.5
@export var ramp_visual_z_scale: float = 0.08
@export var ramp_dual_approach: bool = false
@export var generate_side_block_collision: bool = true

@export var trigger_collision_layer_value: int = 0
@export var trigger_collision_mask_value: int = 1
@export var ramp_collision_layer_value: int = 0
@export var ramp_collision_mask_value: int = 1
@export var side_block_collision_layer_value: int = 1
@export var side_block_collision_mask_value: int = 0

var linked_portal: PortalTeleporter = null

var _state_sprite: AnimatedSprite2D = null
var _return_to_idle_on_finish: bool = true
var _teleport_sequence_active: bool = false
var _busy_until_frame: int = 0
var _active_body: Node2D = null

var _ramp_body_counts: Dictionary = {}
var _portal_player_root: Node2D = null


func _ready() -> void:
	_resolve_linked_portal()

	monitoring = true
	monitorable = false
	collision_layer = trigger_collision_layer_value
	collision_mask = trigger_collision_mask_value

	_ensure_collision_shape()
	_ensure_platform_impostor()
	_ensure_fx_sprites()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	_update_ramp_bodies()
	_try_start_teleport_for_overlapping_bodies()


func link_to(portal: PortalTeleporter) -> void:
	linked_portal = portal


func get_arrival_position(from_position: Vector2) -> Vector2:
	var offset := arrival_offset
	var approach := global_position - from_position

	if approach.length_squared() > 0.0001:
		offset = approach.normalized() * arrival_offset.length()

	return global_position + offset


func play_arrival(hold_seconds: float = -1.0, delay_seconds: float = -1.0) -> void:
	var resolved_delay := arrival_animation_delay_seconds

	if delay_seconds >= 0.0:
		resolved_delay = delay_seconds

	if resolved_delay > 0.0:
		await get_tree().create_timer(resolved_delay).timeout

	var visible_seconds := hold_seconds

	if visible_seconds < 0.0:
		visible_seconds = _get_animation_duration("arrival")
	else:
		visible_seconds = maxf(0.0, visible_seconds - resolved_delay)

	_play_action("arrival", false)

	var minimum_duration := _get_animation_duration("arrival")
	await get_tree().create_timer(maxf(visible_seconds, minimum_duration)).timeout

	if _state_sprite != null:
		if _state_sprite.animation == "arrival":
			_play_idle()


func _resolve_linked_portal() -> void:
	if linked_portal != null:
		if is_instance_valid(linked_portal):
			return

	if linked_portal_path.is_empty():
		return

	var node := get_node_or_null(linked_portal_path)

	if node is PortalTeleporter:
		linked_portal = node as PortalTeleporter
	else:
		push_warning("%s linked_portal_path does not point to a PortalTeleporter: %s" % [name, linked_portal_path])


func _on_body_entered(body: Node2D) -> void:
	_try_start_teleport_for_body(body)


func _try_start_teleport_for_overlapping_bodies() -> void:
	if _teleport_sequence_active:
		return

	var bodies := get_overlapping_bodies()

	for body in bodies:
		if body is Node2D:
			if _can_start_teleport(body as Node2D):
				_run_teleport_sequence(body as Node2D)
				return


func _try_start_teleport_for_body(body: Node2D) -> void:
	if _can_start_teleport(body):
		_run_teleport_sequence(body)


func _is_valid_teleport_body(body: Node2D) -> bool:
	if body == null:
		return false

	if not is_instance_valid(body):
		return false

	if only_players_can_teleport:
		if not body.is_in_group(player_group):
			return false

	return true


func _can_start_teleport(body: Node2D) -> bool:
	if not _is_valid_teleport_body(body):
		return false

	_resolve_linked_portal()

	if linked_portal == null:
		return false

	if not is_instance_valid(linked_portal):
		return false

	if _teleport_sequence_active:
		return false

	var frame := Engine.get_physics_frames()

	if frame < _busy_until_frame:
		return false

	var lock_until := 0

	if body.has_meta(META_TELEPORT_LOCK_UNTIL):
		lock_until = int(body.get_meta(META_TELEPORT_LOCK_UNTIL))

	if frame < lock_until:
		return false

	_apply_ramp_state(body)

	if require_ramp_elevation_to_teleport:
		if not _has_required_portal_elevation(body):
			return false

	return true


func _run_teleport_sequence(body: Node2D) -> void:
	if not _is_valid_teleport_body(body):
		return

	if linked_portal == null:
		return

	if not is_instance_valid(linked_portal):
		return

	_teleport_sequence_active = true
	_active_body = body
	_set_body_portal_transition_locked(body, true)

	var start_frame := Engine.get_physics_frames()
	var sequence_frames := int(ceil(teleport_sequence_seconds * float(Engine.physics_ticks_per_second)))
	var lock_frames: int = maxi(cooldown_frames, sequence_frames)

	_mark_busy_for_frames(lock_frames)
	linked_portal._mark_busy_for_frames(lock_frames)
	body.set_meta(META_TELEPORT_LOCK_UNTIL, start_frame + lock_frames)

	_play_action("activate")

	var start_msec := Time.get_ticks_msec()
	await _wait_for_action_frame(activation_teleport_frame)

	if not _is_valid_teleport_body(body):
		_finish_teleport_sequence()
		return

	if _active_body != body:
		_finish_teleport_sequence()
		return

	if linked_portal == null:
		_finish_teleport_sequence()
		return

	if not is_instance_valid(linked_portal):
		_finish_teleport_sequence()
		return

	if require_body_still_in_trigger_at_teleport_frame:
		if not get_overlapping_bodies().has(body):
			_finish_teleport_sequence()
			return

	_apply_ramp_state(body)

	if require_ramp_elevation_to_teleport:
		if not _has_required_portal_elevation(body):
			_finish_teleport_sequence()
			return

	var destination_position := linked_portal.get_arrival_position(global_position)
	body.global_position = destination_position

	if stop_body_velocity_on_arrival:
		if body is CharacterBody2D:
			(body as CharacterBody2D).velocity = Vector2.ZERO

	_clear_ramp_state(body)

	if body.has_method("play_portal_arrival_animation"):
		body.call("play_portal_arrival_animation")
	else:
		_set_body_portal_transition_locked(body, false)

	var elapsed_seconds := float(Time.get_ticks_msec() - start_msec) / 1000.0
	var arrival_hold_seconds := maxf(0.0, teleport_sequence_seconds - elapsed_seconds)

	linked_portal.call_deferred(
		"play_arrival",
		arrival_hold_seconds,
		arrival_animation_delay_seconds
	)

	_finish_teleport_sequence()


func _finish_teleport_sequence() -> void:
	if _active_body != null and is_instance_valid(_active_body):
		_set_body_portal_transition_locked(_active_body, false)
	_teleport_sequence_active = false
	_active_body = null


func _set_body_portal_transition_locked(body: Node2D, locked: bool) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.has_method("set_portal_transition_locked"):
		body.call("set_portal_transition_locked", locked)


func _mark_busy_for_frames(frame_count: int) -> void:
	var now := Engine.get_physics_frames()
	var resolved_count: int = maxi(frame_count, 1)
	_busy_until_frame = maxi(_busy_until_frame, now + resolved_count)


func _ensure_collision_shape() -> void:
	var collision_shape := get_node_or_null("PortalTriggerShape") as CollisionShape2D

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "PortalTriggerShape"
		add_child(collision_shape)

	collision_shape.position = trigger_shape_offset

	if trigger_shape_size.x > 0.0 and trigger_shape_size.y > 0.0:
		var rectangle := collision_shape.shape as RectangleShape2D

		if rectangle == null:
			rectangle = RectangleShape2D.new()
			collision_shape.shape = rectangle

		rectangle.size = trigger_shape_size
		return

	var circle := collision_shape.shape as CircleShape2D

	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle

	circle.radius = trigger_radius


func _ensure_platform_impostor() -> void:
	_ensure_portal_player_root()

	_ensure_ramp_zone(
		"PortalRampAreaSouth",
		ramp_bottom_local_offset,
		ramp_top_local_offset,
		"_on_south_ramp_body_entered",
		"_on_south_ramp_body_exited"
	)

	if generate_side_block_collision:
		_ensure_side_block_collision(
			"PortalSideBlocksSouth",
			ramp_bottom_local_offset,
			ramp_top_local_offset
		)
	else:
		_remove_child_if_present("PortalSideBlocksSouth")

	if ramp_dual_approach:
		var mirrored_bottom := _mirror_vertical_offset(ramp_bottom_local_offset)
		var mirrored_top := _mirror_vertical_offset(ramp_top_local_offset)

		_ensure_ramp_zone(
			"PortalRampAreaNorth",
			mirrored_bottom,
			mirrored_top,
			"_on_north_ramp_body_entered",
			"_on_north_ramp_body_exited"
		)

		if generate_side_block_collision:
			_ensure_side_block_collision(
				"PortalSideBlocksNorth",
				mirrored_bottom,
				mirrored_top
			)
		else:
			_remove_child_if_present("PortalSideBlocksNorth")
	else:
		_remove_child_if_present("PortalRampAreaNorth")
		_remove_child_if_present("PortalSideBlocksNorth")


func _ensure_portal_player_root() -> void:
	if _portal_player_root == null:
		_portal_player_root = get_node_or_null("PortalPlayerRoot") as Node2D
	elif not is_instance_valid(_portal_player_root):
		_portal_player_root = get_node_or_null("PortalPlayerRoot") as Node2D

	if _portal_player_root == null:
		_portal_player_root = Node2D.new()
		_portal_player_root.name = "PortalPlayerRoot"
		add_child(_portal_player_root)

	_portal_player_root.position = ramp_top_local_offset


func _ensure_ramp_zone(
	zone_name: String,
	bottom_offset: Vector2,
	top_offset: Vector2,
	enter_method: String,
	exit_method: String
) -> void:
	var ramp_area := get_node_or_null(NodePath(zone_name)) as Area2D

	if ramp_area == null:
		ramp_area = Area2D.new()
		ramp_area.name = zone_name
		add_child(ramp_area)

	ramp_area.position = Vector2.ZERO
	ramp_area.monitoring = true
	ramp_area.monitorable = false
	ramp_area.collision_layer = ramp_collision_layer_value
	ramp_area.collision_mask = ramp_collision_mask_value

	var enter_callable := Callable(self, enter_method)
	var exit_callable := Callable(self, exit_method)

	if not ramp_area.body_entered.is_connected(enter_callable):
		ramp_area.body_entered.connect(enter_callable)

	if not ramp_area.body_exited.is_connected(exit_callable):
		ramp_area.body_exited.connect(exit_callable)

	var ramp_collision := ramp_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D

	if ramp_collision == null:
		ramp_collision = CollisionPolygon2D.new()
		ramp_collision.name = "CollisionPolygon2D"
		ramp_area.add_child(ramp_collision)

	ramp_collision.polygon = _build_ramp_polygon(
		bottom_offset,
		top_offset,
		ramp_bottom_width,
		ramp_top_width
	)


func _build_ramp_polygon(
	bottom_offset: Vector2,
	top_offset: Vector2,
	bottom_width: float,
	top_width: float
) -> PackedVector2Array:
	var axis := top_offset - bottom_offset
	var normal := Vector2.RIGHT

	if axis.length_squared() > 0.001:
		var axis_normalized := axis.normalized()
		normal = Vector2(-axis_normalized.y, axis_normalized.x)

	var points := PackedVector2Array()
	points.append(bottom_offset - normal * bottom_width * 0.5)
	points.append(bottom_offset + normal * bottom_width * 0.5)
	points.append(top_offset + normal * top_width * 0.5)
	points.append(top_offset - normal * top_width * 0.5)

	return points


func _ensure_side_block_collision(
	root_name: String,
	bottom_offset: Vector2,
	top_offset: Vector2
) -> void:
	var side_block_root := get_node_or_null(NodePath(root_name)) as StaticBody2D

	if side_block_root == null:
		side_block_root = StaticBody2D.new()
		side_block_root.name = root_name
		add_child(side_block_root)

	side_block_root.collision_layer = side_block_collision_layer_value
	side_block_root.collision_mask = side_block_collision_mask_value

	_clear_children(side_block_root)

	var center_y := (bottom_offset.y + top_offset.y) * 0.5
	var height := maxf(
		absf(bottom_offset.y - top_offset.y) + ramp_side_block_extra_height,
		ramp_side_block_height
	)
	var left_x := -ramp_lane_half_width - ramp_side_block_width * 0.5
	var right_x := ramp_lane_half_width + ramp_side_block_width * 0.5

	side_block_root.add_child(_build_side_block_shape(Vector2(left_x, center_y), height))
	side_block_root.add_child(_build_side_block_shape(Vector2(right_x, center_y), height))


func _build_side_block_shape(shape_position: Vector2, shape_height: float) -> CollisionShape2D:
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"

	var rect := RectangleShape2D.new()
	rect.size = Vector2(ramp_side_block_width, maxf(shape_height, 1.0))

	collision_shape.shape = rect
	collision_shape.position = shape_position

	return collision_shape


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _remove_child_if_present(node_name: String) -> void:
	var node := get_node_or_null(NodePath(node_name))

	if node == null:
		return

	remove_child(node)
	node.queue_free()


func _on_south_ramp_body_entered(body: Node2D) -> void:
	_on_ramp_body_entered(body)


func _on_south_ramp_body_exited(body: Node2D) -> void:
	_on_ramp_body_exited(body)


func _on_north_ramp_body_entered(body: Node2D) -> void:
	_on_ramp_body_entered(body)


func _on_north_ramp_body_exited(body: Node2D) -> void:
	_on_ramp_body_exited(body)


func _on_ramp_body_entered(body: Node2D) -> void:
	if not _is_valid_teleport_body(body):
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


func _update_ramp_bodies() -> void:
	if _ramp_body_counts.is_empty():
		return

	for body in _ramp_body_counts.keys():
		if body == null:
			_ramp_body_counts.erase(body)
			continue

		if not is_instance_valid(body):
			_ramp_body_counts.erase(body)
			continue

		_apply_ramp_state(body)


func _apply_ramp_state(body: Node2D) -> void:
	if not _is_valid_teleport_body(body):
		return

	var sample := _sample_best_ramp_for_body(body.global_position)

	if sample.is_empty():
		_clear_ramp_state(body)
		return

	if not bool(sample.get("inside_lane")):
		_clear_ramp_state(body)
		return

	var progress := float(sample.get("progress"))
	var elevation := lerpf(0.0, ramp_max_elevation, progress)

	body.set_meta(META_RAMP_SOURCE_ID, get_instance_id())
	body.set_meta(META_RAMP_PROGRESS, progress)
	body.set_meta(META_RAMP_ELEVATION, elevation)

	_set_body_fake_elevation(body, elevation)
	_set_body_movement_multiplier(body, ramp_speed_multiplier)


func _clear_ramp_state(body: Node2D) -> void:
	if body == null:
		return

	if not is_instance_valid(body):
		return

	var source_id := 0

	if body.has_meta(META_RAMP_SOURCE_ID):
		source_id = int(body.get_meta(META_RAMP_SOURCE_ID))

	if source_id != 0:
		if source_id != get_instance_id():
			return

	if body.has_meta(META_RAMP_SOURCE_ID):
		body.remove_meta(META_RAMP_SOURCE_ID)

	if body.has_meta(META_RAMP_PROGRESS):
		body.remove_meta(META_RAMP_PROGRESS)

	if body.has_meta(META_RAMP_ELEVATION):
		body.remove_meta(META_RAMP_ELEVATION)

	_clear_body_fake_elevation(body)
	_clear_body_movement_multiplier(body)


func _has_required_portal_elevation(body: Node2D) -> bool:
	if body == null:
		return false

	if not is_instance_valid(body):
		return false

	if not body.has_meta(META_RAMP_SOURCE_ID):
		return false

	var source_id := int(body.get_meta(META_RAMP_SOURCE_ID))

	if source_id != get_instance_id():
		return false

	if not body.has_meta(META_RAMP_ELEVATION):
		return false

	var elevation := float(body.get_meta(META_RAMP_ELEVATION))
	return elevation >= ramp_required_elevation


func _sample_best_ramp_for_body(world_pos: Vector2) -> Dictionary:
	var best_sample: Dictionary = {}
	var best_progress := -1.0

	var south_sample := _sample_ramp(
		world_pos,
		ramp_bottom_local_offset,
		ramp_top_local_offset
	)

	if bool(south_sample.get("inside_lane")):
		best_sample = south_sample
		best_progress = float(south_sample.get("progress"))

	if ramp_dual_approach:
		var north_sample := _sample_ramp(
			world_pos,
			_mirror_vertical_offset(ramp_bottom_local_offset),
			_mirror_vertical_offset(ramp_top_local_offset)
		)

		if bool(north_sample.get("inside_lane")):
			var north_progress := float(north_sample.get("progress"))

			if north_progress > best_progress:
				best_sample = north_sample
				best_progress = north_progress

	return best_sample


func _sample_ramp(
	world_pos: Vector2,
	bottom_local_offset: Vector2,
	top_local_offset: Vector2
) -> Dictionary:
	var bottom_world := global_position + bottom_local_offset
	var top_world := global_position + top_local_offset
	var axis := top_world - bottom_world
	var axis_len_sq := axis.length_squared()

	if axis_len_sq < 0.001:
		return {
			"progress": 0.0,
			"inside_lane": false,
			"lateral_distance": 999999.0,
			"half_width": 0.0
		}

	var progress := clampf((world_pos - bottom_world).dot(axis) / axis_len_sq, 0.0, 1.0)
	var closest_point := bottom_world + axis * progress
	var half_width := lerpf(ramp_bottom_width * 0.5, ramp_top_width * 0.5, progress)
	var lateral_distance := world_pos.distance_to(closest_point)
	var inside_lane := lateral_distance <= half_width + ramp_lane_margin

	return {
		"progress": progress,
		"inside_lane": inside_lane,
		"lateral_distance": lateral_distance,
		"half_width": half_width
	}


func _mirror_vertical_offset(offset: Vector2) -> Vector2:
	return Vector2(offset.x, -offset.y)


func _set_body_fake_elevation(body: Node2D, elevation: float) -> void:
	if body.has_method("set_fake_elevation_source"):
		body.call("set_fake_elevation_source", ELEVATION_SOURCE, elevation)
		return

	if body.has_method("set_fake_elevation"):
		body.call("set_fake_elevation", elevation)


func _clear_body_fake_elevation(body: Node2D) -> void:
	if body.has_method("clear_fake_elevation_source"):
		body.call("clear_fake_elevation_source", ELEVATION_SOURCE)
		return

	if body.has_method("set_fake_elevation"):
		body.call("set_fake_elevation", 0.0)


func _set_body_movement_multiplier(body: Node2D, multiplier: float) -> void:
	if body.has_method("set_movement_surface_multiplier_source"):
		body.call("set_movement_surface_multiplier_source", MOVEMENT_SOURCE, multiplier)
		return

	if body.has_method("set_movement_surface_multiplier"):
		body.call("set_movement_surface_multiplier", multiplier)


func _clear_body_movement_multiplier(body: Node2D) -> void:
	if body.has_method("clear_movement_surface_multiplier_source"):
		body.call("clear_movement_surface_multiplier_source", MOVEMENT_SOURCE)
		return

	if body.has_method("set_movement_surface_multiplier"):
		body.call("set_movement_surface_multiplier", 1.0)


func _ensure_fx_sprites() -> void:
	var frames := SpriteFrames.new()

	_add_strip_animation(
		frames,
		"idle",
		PORTAL_IDLE_SHEET,
		PORTAL_IDLE_FRAME_COUNT,
		idle_fps,
		true
	)

	_add_strip_animation(
		frames,
		"activate",
		PORTAL_ACTIVATE_SHEET,
		PORTAL_ACTIVATE_FRAME_COUNT,
		activate_fps,
		false
	)

	_add_strip_animation(
		frames,
		"arrival",
		PORTAL_ARRIVAL_SHEET,
		PORTAL_ARRIVAL_FRAME_COUNT,
		arrival_fps,
		false
	)

	_clear_legacy_fx_sprite("PortalIdleFx")
	_clear_legacy_fx_sprite("PortalActionFx")

	_state_sprite = get_node_or_null("PortalStateSprite") as AnimatedSprite2D

	if _state_sprite == null:
		_state_sprite = AnimatedSprite2D.new()
		_state_sprite.name = "PortalStateSprite"
		add_child(_state_sprite)

	_configure_fx_sprite(_state_sprite, frames)

	if not _state_sprite.animation_finished.is_connected(_on_state_animation_finished):
		_state_sprite.animation_finished.connect(_on_state_animation_finished)

	_play_idle()


func _clear_legacy_fx_sprite(node_name: String) -> void:
	var legacy := get_node_or_null(NodePath(node_name)) as Node

	if legacy == null:
		return

	remove_child(legacy)
	legacy.queue_free()


func _configure_fx_sprite(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames
	sprite.position = fx_offset
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = fx_z_index
	sprite.visible = true


func _add_strip_animation(
	frames: SpriteFrames,
	animation_name: String,
	texture: Texture2D,
	frame_count: int,
	fps: float,
	loop: bool
) -> void:
	if frame_count <= 0:
		push_warning("Portal animation %s has invalid frame_count=%s" % [animation_name, frame_count])
		return

	if fps <= 0.0:
		push_warning("Portal animation %s has invalid fps=%s; using 1 fps." % [animation_name, fps])
		fps = 1.0

	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)

	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			frame_index * fx_frame_size.x,
			0,
			fx_frame_size.x,
			fx_frame_size.y
		)
		frames.add_frame(animation_name, atlas)


func _play_action(animation_name: String, return_to_idle_on_finish: bool = true) -> void:
	if _state_sprite == null:
		return

	if _state_sprite.sprite_frames == null:
		return

	if not _state_sprite.sprite_frames.has_animation(animation_name):
		push_warning("%s missing portal animation: %s" % [name, animation_name])
		return

	_return_to_idle_on_finish = return_to_idle_on_finish
	_state_sprite.visible = true
	_state_sprite.play(animation_name)
	_state_sprite.set_frame_and_progress(0, 0.0)


func _play_idle() -> void:
	if _state_sprite == null:
		return

	if _state_sprite.sprite_frames == null:
		return

	if not _state_sprite.sprite_frames.has_animation("idle"):
		return

	_return_to_idle_on_finish = true
	_state_sprite.visible = true
	_state_sprite.play("idle")


func _on_state_animation_finished() -> void:
	if _state_sprite == null:
		return

	if _return_to_idle_on_finish:
		_play_idle()


func _wait_for_action_frame(frame_number: int) -> void:
	if _state_sprite == null:
		return

	var target_frame := maxi(0, frame_number - 1)
	var safety_seconds := maxf(_get_animation_duration("activate") + 0.5, 0.75)
	var start_msec := Time.get_ticks_msec()

	while _state_sprite != null:
		if not is_instance_valid(_state_sprite):
			return

		if _state_sprite.animation != "activate":
			return

		if _state_sprite.frame >= target_frame:
			return

		var elapsed := float(Time.get_ticks_msec() - start_msec) / 1000.0

		if elapsed > safety_seconds:
			push_warning("%s timed out waiting for portal activate frame %s." % [name, frame_number])
			return

		await get_tree().process_frame


func _get_animation_duration(animation_name: String) -> float:
	if _state_sprite == null:
		return 0.0

	if _state_sprite.sprite_frames == null:
		return 0.0

	if not _state_sprite.sprite_frames.has_animation(animation_name):
		return 0.0

	var fps := _state_sprite.sprite_frames.get_animation_speed(animation_name)

	if fps <= 0.0:
		return 0.0

	var frame_count := _state_sprite.sprite_frames.get_frame_count(animation_name)
	return float(frame_count) / fps
