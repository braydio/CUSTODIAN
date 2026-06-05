extends Node2D
class_name FieldTerminalInteractable

signal witness_established(actor: Node)
signal terminal_access_requested(actor: Node)

const ACTIVATION_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/command_terminal__body__interaction__activate__omni__4f__48.png"
const COMPAT_ACTIVATION_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/builder_terminal__body__interaction__activate__omni__4f__48.png"
const LEGACY_ACTIVATION_TEXTURE_PATH := "res://content/sprites/environment/props/terminal/runtime/body/computer_terminal__body__interaction__activate__omni__4f__48.png"

@export var prompt_text: String = "ESTABLISH WITNESS"
@export_range(32.0, 180.0, 1.0) var interaction_distance: float = 96.0
@export var animation_frame_size: Vector2i = Vector2i(48, 48)
@export_range(2, 16, 1) var animation_frame_count: int = 4
@export_range(1.0, 24.0, 0.5) var activation_fps: float = 9.0

var witness_state_established := false
var _terminal_sprite: AnimatedSprite2D = null
var _activation_texture: Texture2D = null


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("field_terminal")
	_activation_texture = _load_first_existing_texture([
		ACTIVATION_TEXTURE_PATH,
		COMPAT_ACTIVATION_TEXTURE_PATH,
		LEGACY_ACTIVATION_TEXTURE_PATH,
	])
	if _ensure_terminal_sprite():
		_set_fallback_geometry_visible(false)
		_show_idle_frame()
	else:
		_set_fallback_geometry_visible(true)


func get_interaction_prompt() -> String:
	var key := _get_interact_prompt_key()
	if witness_state_established:
		return "CUSTODIAN TERMINAL: PARTIAL ARCHIVE (%s)" % key
	return "%s (%s)" % [prompt_text, key]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	if witness_state_established:
		terminal_access_requested.emit(actor)
		return
	establish_witness(actor)


func establish_witness(actor: Node = null) -> void:
	if witness_state_established:
		return
	witness_state_established = true
	if _ensure_terminal_sprite():
		_terminal_sprite.play("activate")
		await _terminal_sprite.animation_finished
		_terminal_sprite.stop()
		_terminal_sprite.animation = "idle_active"
		_terminal_sprite.frame = 0
	witness_established.emit(actor)


func _load_first_existing_texture(paths: Array[String]) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _ensure_terminal_sprite() -> bool:
	if _activation_texture == null:
		return false
	if _terminal_sprite != null:
		return _terminal_sprite.sprite_frames != null
	_terminal_sprite = get_node_or_null("TerminalSprite") as AnimatedSprite2D
	if _terminal_sprite == null:
		_terminal_sprite = AnimatedSprite2D.new()
		_terminal_sprite.name = "TerminalSprite"
		_terminal_sprite.centered = true
		add_child(_terminal_sprite)
		move_child(_terminal_sprite, 0)
	return _build_terminal_frames()


func _build_terminal_frames() -> bool:
	var frame_width: int = maxi(animation_frame_size.x, 1)
	var frame_height: int = maxi(animation_frame_size.y, 1)
	var columns: int = maxi(1, _activation_texture.get_width() / frame_width)
	var rows: int = maxi(1, _activation_texture.get_height() / frame_height)
	var usable_frames: int = mini(animation_frame_count, maxi(1, columns * rows))
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
	for frame_index in range(usable_frames):
		var atlas := AtlasTexture.new()
		atlas.atlas = _activation_texture
		atlas.region = Rect2((frame_index % columns) * frame_width, (frame_index / columns) * frame_height, frame_width, frame_height)
		if frame_index == 0:
			frames.add_frame("idle_closed", atlas)
		frames.add_frame("activate", atlas)
		if frame_index == usable_frames - 1:
			frames.add_frame("idle_active", atlas)
	_terminal_sprite.sprite_frames = frames
	return true


func _show_idle_frame() -> void:
	if _terminal_sprite == null:
		return
	_terminal_sprite.animation = "idle_active" if witness_state_established else "idle_closed"
	_terminal_sprite.frame = 0
	_terminal_sprite.stop()


func _set_fallback_geometry_visible(is_visible: bool) -> void:
	for node_name in ["Cabinet", "Screen", "StatusStrip"]:
		var item := get_node_or_null(node_name) as CanvasItem
		if item != null:
			item.visible = is_visible


func _get_interact_prompt_key() -> String:
	if not InputMap.has_action("interact"):
		return "G"
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			return OS.get_keycode_string(key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode)
	return "G"
