extends Node2D
class_name SidearmLockerInteractable

signal sidearm_taken(actor: Node)

## Sprite sheet: 1024×128, 8 frames of 128×128.
## Frame 1 = closed/locked. Playing frames 1→8 animates opening.
## After sidearm is taken, switches to _empty.png variant.
const LOCKER_SHEET_PATH := "res://content/sprites/props/storage/field_retention_locker/field_retention_locker_sheet.png"
const LOCKER_EMPTY_PATH := "res://content/sprites/props/storage/field_retention_locker/field_retention_locker_empty.png"
const SIDEARM_DEFINITION_PATH := "res://game/actors/operator/sidearm_pistol_definition.tres"

const FRAME_SIZE := Vector2i(128, 128)
const FRAME_COUNT := 8
const ANIMATION_FPS := 14.0

@export_range(24.0, 192.0, 1.0) var interaction_distance: float = 84.0

enum LockerState { CLOSED, OPEN, EMPTY }
var _state: LockerState = LockerState.CLOSED
var _locker_sprite: AnimatedSprite2D = null
var _empty_sprite: Sprite2D = null
var _empty_texture: Texture2D = null
var _sidearm_definition: Resource = null
var _opening_playback_started := false


func _ready() -> void:
	add_to_group("interactable")
	_empty_texture = load(LOCKER_EMPTY_PATH) if ResourceLoader.exists(LOCKER_EMPTY_PATH) else null
	if ResourceLoader.exists(SIDEARM_DEFINITION_PATH):
		_sidearm_definition = load(SIDEARM_DEFINITION_PATH)
	_build_locker_sprite()


func _build_locker_sprite() -> void:
	var sheet_texture := load(LOCKER_SHEET_PATH) as Texture2D
	if sheet_texture == null:
		return

	_locker_sprite = AnimatedSprite2D.new()
	_locker_sprite.name = "LockerSprite"
	_locker_sprite.centered = true
	add_child(_locker_sprite)
	move_child(_locker_sprite, 0)

	var frames := SpriteFrames.new()

	# closed — single frame (frame 1)
	frames.add_animation("closed")
	frames.set_animation_speed("closed", 0.0)
	frames.set_animation_loop("closed", false)

	# open — plays frames 1→8 then stops
	frames.add_animation("open")
	frames.set_animation_speed("open", ANIMATION_FPS)
	frames.set_animation_loop("open", false)

	# open_idle — holds on the last frame (frame 8)
	frames.add_animation("open_idle")
	frames.set_animation_speed("open_idle", 0.0)
	frames.set_animation_loop("open_idle", false)

	var columns := maxi(1, sheet_texture.get_width() / FRAME_SIZE.x)
	for frame_index in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_texture
		atlas.region = Rect2(
			(frame_index % columns) * FRAME_SIZE.x,
			(frame_index / columns) * FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y,
		)
		if frame_index == 0:
			frames.add_frame("closed", atlas)
		frames.add_frame("open", atlas)
		if frame_index == FRAME_COUNT - 1:
			frames.add_frame("open_idle", atlas)

	_locker_sprite.sprite_frames = frames
	_locker_sprite.animation = &"closed"
	_locker_sprite.frame = 0
	_locker_sprite.stop()


func get_interaction_prompt() -> String:
	var key := _get_interact_prompt_key()
	match _state:
		LockerState.CLOSED:
			return "OPEN FIELD RETENTION LOCKER (%s)" % key
		LockerState.OPEN:
			return "TAKE P-9 FIELD SIDEARM (%s)" % key
		LockerState.EMPTY:
			return ""
	return ""


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	if _state == LockerState.EMPTY:
		return
	if _state == LockerState.CLOSED and not _opening_playback_started:
		_open_locker()
	elif _state == LockerState.OPEN:
		_take_sidearm(actor)


func _open_locker() -> void:
	if _locker_sprite == null:
		return
	_opening_playback_started = true
	_locker_sprite.animation = &"open"
	_locker_sprite.frame = 0
	_locker_sprite.play()
	await _locker_sprite.animation_finished
	_locker_sprite.stop()
	_locker_sprite.animation = &"open_idle"
	_locker_sprite.frame = 0
	_state = LockerState.OPEN


func _take_sidearm(actor: Node) -> void:
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	if inventory_manager == null or not inventory_manager.has_method("add_item"):
		push_warning("[SidearmLocker] InventoryManager not available")
		return

	var result := inventory_manager.call("add_item", &"p9_sidearm", 1)
	if result <= 0:
		push_warning("[SidearmLocker] Failed to add P-9 to inventory")
		return

	_state = LockerState.EMPTY
	remove_from_group("interactable")

	# Hide animated sprite
	if _locker_sprite != null:
		_locker_sprite.visible = false

	# Show empty sprite variant
	if _empty_texture != null:
		_empty_sprite = Sprite2D.new()
		_empty_sprite.name = "EmptyLockerSprite"
		_empty_sprite.texture = _empty_texture
		_empty_sprite.centered = true
		add_child(_empty_sprite)
		move_child(_empty_sprite, 0)

	sidearm_taken.emit(actor)


func _get_interact_prompt_key() -> String:
	if not InputMap.has_action("interact"):
		return "E"
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			return OS.get_keycode_string(
				key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			)
	return "E"
