extends Node2D
class_name CommandTerminal

signal terminal_visual_activated
signal terminal_visual_deactivated

const COMMAND_TERMINAL_ACTIVATION_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/command_terminal__body__interaction__activate__omni__4f__48.png"
const COMPAT_COMMAND_TERMINAL_ACTIVATION_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/computer_terminal__body__interaction__activate__omni__4f__48.png"
const COMMAND_TERMINAL_PICKUP_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/command_terminal__body__interaction__pickup__omni__4f__48.png"
const COMPAT_COMMAND_TERMINAL_PICKUP_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/computer_terminal__body__interaction__pickup__omni__4f__48.png"
const COMPAT_COMMAND_TERMINAL_PICKUP_ALT_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/computer_terminal__body__interaction__pick-up__omni__4f__48.png"

@export var launch_url: String = "http://127.0.0.1:7331"
@export var prompt_text: String = "ACCESS CUSTODIAN INTERFACE"
@export var interact_distance: float = 88.0
@export var activation_texture: Texture2D = null
@export var pickup_texture: Texture2D = null
@export var animation_frame_size: Vector2i = Vector2i(48, 48)
@export_range(2, 16, 1) var animation_frame_count: int = 4
@export_range(1.0, 24.0, 0.5) var activation_fps: float = 10.0
@export_range(0.0, 3.0, 0.05) var deactivate_delay_multiplier: float = 1.15
@export var pickup_modulate_alpha: float = 0.55

var _terminal_sprite: AnimatedSprite2D = null
var _terminal_body_collision: CollisionShape2D = null
var _is_active: bool = false
var _is_activating: bool = false
var _activation_sequence_token: int = 0
var _is_carried: bool = false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("command_terminal")
	_resolve_activation_texture()
	_resolve_pickup_texture()
	if _ensure_terminal_sprite():
		_hide_placeholder_geometry()
		_resolve_terminal_body_collision()
		_set_carried_state(false)
		_show_closed_frame()


func get_interaction_prompt() -> String:
	if _is_carried:
		return ""
	var interact_key := _get_interact_prompt_key()
	var resolved_prompt := prompt_text.strip_edges()
	if resolved_prompt.is_empty():
		resolved_prompt = "ACCESS CUSTODIAN INTERFACE"
	if _is_deployed():
		return "%s (%s) | BUILD TO PICK UP" % [resolved_prompt, interact_key]
	return "%s (%s)" % [resolved_prompt, interact_key]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interact_distance


func interact(_actor: Node) -> void:
	if _is_carried:
		return
	var ui := get_node_or_null("/root/GameRoot/UI")
	if ui == null or not ui.has_method("open_command_terminal"):
		return
	if ui.has_method("is_terminal_open") and bool(ui.call("is_terminal_open")):
		return
	await activate_visual()
	ui.call("open_command_terminal", launch_url)


func activate_visual() -> void:
	_activation_sequence_token += 1
	if _is_active and not _is_activating:
		return
	if not _ensure_terminal_sprite():
		_is_active = true
		return
	if _is_activating:
		await terminal_visual_activated
		return
	_is_activating = true
	_terminal_sprite.play("activate")
	await _terminal_sprite.animation_finished
	_terminal_sprite.stop()
	_terminal_sprite.animation = "idle_active"
	_terminal_sprite.frame = 0
	_is_activating = false
	_is_active = true
	terminal_visual_activated.emit()


func deactivate_visual_after_ui_close() -> void:
	var token := _activation_sequence_token + 1
	_activation_sequence_token = token
	await _deactivate_visual_after_delay(token)


func _deactivate_visual_after_delay(token: int) -> void:
	if not _is_active or _is_activating:
		return
	var delay := _get_activation_duration() * deactivate_delay_multiplier
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if token != _activation_sequence_token:
		return
	if not _is_active or _is_activating:
		return
	if not _ensure_terminal_sprite():
		_is_active = false
		return
	_terminal_sprite.play("deactivate")
	await _terminal_sprite.animation_finished
	if token != _activation_sequence_token:
		return
	_terminal_sprite.stop()
	_show_closed_frame()
	_is_active = false
	terminal_visual_deactivated.emit()


func is_carried() -> bool:
	return _is_carried


func set_carried_state(carried: bool, show_closed_frame: bool = true) -> void:
	if _is_carried == carried and _terminal_body_collision != null:
		_update_carried_state_visuals()
		return
	_set_carried_state(carried, show_closed_frame)


func _set_carried_state(carried: bool, show_closed_frame: bool = true) -> void:
	_is_carried = carried
	if not _is_carried:
		_is_active = false
		_is_activating = false
	_update_terminal_groups()
	_update_terminal_collision()
	_update_carried_state_visuals(show_closed_frame)


func _update_carried_state_visuals(show_closed_frame: bool = true) -> void:
	if _is_carried:
		modulate = Color(1.0, 1.0, 1.0, pickup_modulate_alpha)
		visible = true
	else:
		modulate = Color.WHITE
		visible = true
		if show_closed_frame:
			_show_closed_frame()


func _update_terminal_groups() -> void:
	if _is_carried:
		remove_from_group("interactable")
		remove_from_group("command_terminal")
	else:
		add_to_group("interactable")
		add_to_group("command_terminal")


func _update_terminal_collision() -> void:
	if _terminal_body_collision == null:
		_resolve_terminal_body_collision()
	if _terminal_body_collision != null:
		_terminal_body_collision.disabled = _is_carried


func _resolve_terminal_body_collision() -> void:
	if _terminal_body_collision != null and is_instance_valid(_terminal_body_collision):
		return
	_terminal_body_collision = get_node_or_null("Body/CollisionShape2D") as CollisionShape2D


func _resolve_activation_texture() -> void:
	if activation_texture != null:
		return
	activation_texture = _load_first_existing_texture([
		COMMAND_TERMINAL_ACTIVATION_TEXTURE_PATH,
		COMPAT_COMMAND_TERMINAL_ACTIVATION_TEXTURE_PATH,
	])


func _resolve_pickup_texture() -> void:
	if pickup_texture != null:
		return
	pickup_texture = _load_first_existing_texture([
		COMMAND_TERMINAL_PICKUP_TEXTURE_PATH,
		COMPAT_COMMAND_TERMINAL_PICKUP_TEXTURE_PATH,
		COMPAT_COMMAND_TERMINAL_PICKUP_ALT_TEXTURE_PATH,
	])


func _load_first_existing_texture(paths: Array[String]) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _ensure_terminal_sprite() -> bool:
	if activation_texture == null:
		return false
	if _terminal_sprite != null:
		return _terminal_sprite.sprite_frames != null and _terminal_sprite.sprite_frames.has_animation("idle_closed")
	_terminal_sprite = get_node_or_null("TerminalSprite") as AnimatedSprite2D
	if _terminal_sprite == null:
		_terminal_sprite = AnimatedSprite2D.new()
		_terminal_sprite.name = "TerminalSprite"
		_terminal_sprite.centered = true
		add_child(_terminal_sprite)
		move_child(_terminal_sprite, 0)
	return _build_terminal_frames()


func _build_terminal_frames() -> bool:
	if _terminal_sprite == null or activation_texture == null:
		return false
	var texture_width: int = activation_texture.get_width()
	var texture_height: int = activation_texture.get_height()
	var frame_width: int = maxi(animation_frame_size.x, 1)
	var frame_height: int = maxi(animation_frame_size.y, 1)
	var columns: int = maxi(1, texture_width / frame_width)
	var rows: int = maxi(1, texture_height / frame_height)
	var max_frames: int = maxi(1, columns * rows)
	var usable_frames: int = mini(animation_frame_count, max_frames)
	if usable_frames < 2:
		return false
	var frames := SpriteFrames.new()
	frames.add_animation("idle_closed")
	frames.set_animation_speed("idle_closed", 0.0)
	frames.set_animation_loop("idle_closed", false)
	frames.add_animation("activate")
	frames.set_animation_speed("activate", activation_fps)
	frames.set_animation_loop("activate", false)
	frames.add_animation("idle_active")
	frames.set_animation_speed("idle_active", 0.0)
	frames.set_animation_loop("idle_active", false)
	frames.add_animation("deactivate")
	frames.set_animation_speed("deactivate", activation_fps)
	frames.set_animation_loop("deactivate", false)
	for frame_index in range(usable_frames):
		var atlas := AtlasTexture.new()
		atlas.atlas = activation_texture
		var col := frame_index % columns
		var row := frame_index / columns
		atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
		if frame_index == 0:
			frames.add_frame("idle_closed", atlas)
		frames.add_frame("activate", atlas)
		if frame_index == usable_frames - 1:
			frames.add_frame("idle_active", atlas)
	for frame_index in range(usable_frames - 1, -1, -1):
		var atlas := AtlasTexture.new()
		atlas.atlas = activation_texture
		var col := frame_index % columns
		var row := frame_index / columns
		atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
		frames.add_frame("deactivate", atlas)
	_append_pickup_frames(frames, usable_frames, frame_width, frame_height, columns)
	_terminal_sprite.sprite_frames = frames
	_terminal_sprite.animation = "idle_closed"
	_terminal_sprite.frame = 0
	return true


func _append_pickup_frames(frames: SpriteFrames, usable_frames: int, frame_width: int, frame_height: int, columns: int) -> void:
	var source_texture := pickup_texture if pickup_texture != null else activation_texture
	if source_texture == null:
		return
	frames.add_animation("pickup")
	frames.set_animation_speed("pickup", activation_fps)
	frames.set_animation_loop("pickup", false)
	frames.add_animation("deploy")
	frames.set_animation_speed("deploy", activation_fps)
	frames.set_animation_loop("deploy", false)
	for frame_index in range(usable_frames):
		var atlas := AtlasTexture.new()
		atlas.atlas = source_texture
		var col := frame_index % columns
		var row := frame_index / columns
		atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
		frames.add_frame("pickup", atlas)
	for frame_index in range(usable_frames - 1, -1, -1):
		var atlas := AtlasTexture.new()
		atlas.atlas = source_texture
		var col := frame_index % columns
		var row := frame_index / columns
		atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
		frames.add_frame("deploy", atlas)


func play_pickup_transition(reverse: bool = false) -> void:
	if not _ensure_terminal_sprite():
		return
	var animation_name := "deploy" if reverse else "pickup"
	if not _terminal_sprite.sprite_frames.has_animation(animation_name):
		return
	_terminal_sprite.play(animation_name)


func _show_closed_frame() -> void:
	if _terminal_sprite == null:
		return
	_terminal_sprite.stop()
	_terminal_sprite.animation = "idle_closed"
	_terminal_sprite.frame = 0


func _hide_placeholder_geometry() -> void:
	for child_name in ["Cabinet", "Screen", "StatusStrip"]:
		var child := get_node_or_null(child_name)
		if child is CanvasItem:
			(child as CanvasItem).visible = false


func _is_deployed() -> bool:
	return not _is_carried


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var key_text := key_event.as_text_key_label().strip_edges().to_upper()
			if not key_text.is_empty():
				return key_text
	return "INTERACT"


func _get_activation_duration() -> float:
	var frame_total: int = maxi(animation_frame_count - 1, 1)
	return float(frame_total) / max(activation_fps, 0.001)
