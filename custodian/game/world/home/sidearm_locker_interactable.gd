extends Node2D
class_name SidearmLockerInteractable

signal sidearm_taken(actor: Node)

## The First Return P-9 release fixture: the Custodian Designation Locker.
##
## Visual authority is the `awakening_designation_locker` Asset V2 family. Each
## state is its own canonical runtime output, so the node never slices a state
## out of the animation strip:
##
##   closed          128×160, 1 frame — faceplate flush with the wall
##   authorize_open  1024×160, 8 frames of 128×160 @ 10 FPS, one-shot
##   open_loaded     128×160, 1 frame — P-9 in its retention cradle
##   empty           128×160, 1 frame — clamps and hardware, unloaded
##
## Gameplay contract: interact → authorize → opening animation → open_loaded →
## grant p9_sidearm → empty. The P-9 can only ever be granted once.
const ART_ROOT := "res://content/sprites/environment/props/awakening/awakening_designation_locker/runtime/body"
const CLOSED_PATH := ART_ROOT + "/awakening_designation_locker__body__state__closed__omni__1f__128x160.png"
const AUTHORIZE_OPEN_PATH := ART_ROOT + "/awakening_designation_locker__body__interaction__authorize_open__omni__8f__128x160.png"
const OPEN_LOADED_PATH := ART_ROOT + "/awakening_designation_locker__body__state__open_loaded__omni__1f__128x160.png"
const EMPTY_PATH := ART_ROOT + "/awakening_designation_locker__body__state__empty__omni__1f__128x160.png"

const FRAME_SIZE := Vector2i(128, 160)
const FRAME_COUNT := 8
const ANIMATION_FPS := 10.0

## Visual-only nudge east so the faceplate reads as relief set into the Locker
## Reliquary's east wall instead of a free-standing cabinet on open floor.
## Calibrated in the live scene against the zone underlay: the wall's inner face
## sits near world x 928, and the opaque faceplate is 64 px of the 128 px canvas,
## so +72 seats its right edge on the wall grille without covering the sconces.
## This moves pixels only — the node anchor, interaction position, collider, and
## layout footprint all stay on (832, -1952).
const SPRITE_VISUAL_OFFSET := Vector2(72, 0)

const SIDEARM_DEFINITION_PATH := "res://game/actors/operator/sidearm_pistol_definition.tres"

@export_range(24.0, 192.0, 1.0) var interaction_distance: float = 84.0

enum LockerState { CLOSED, OPEN, EMPTY }
var _state: LockerState = LockerState.CLOSED
var _locker_sprite: AnimatedSprite2D = null
var _sidearm_definition: Resource = null
var _opening_playback_started := false
var _sidearm_granted := false


func _ready() -> void:
	add_to_group("interactable")
	if ResourceLoader.exists(SIDEARM_DEFINITION_PATH):
		_sidearm_definition = load(SIDEARM_DEFINITION_PATH)
	_build_locker_sprite()


func _build_locker_sprite() -> void:
	var closed_texture := _load_texture(CLOSED_PATH)
	var strip_texture := _load_texture(AUTHORIZE_OPEN_PATH)
	var open_loaded_texture := _load_texture(OPEN_LOADED_PATH)
	var empty_texture := _load_texture(EMPTY_PATH)
	if closed_texture == null or strip_texture == null:
		push_warning("[SidearmLocker] awakening_designation_locker runtime art missing")
		return

	_locker_sprite = AnimatedSprite2D.new()
	_locker_sprite.name = "LockerSprite"
	_locker_sprite.centered = true
	_locker_sprite.offset = SPRITE_VISUAL_OFFSET
	add_child(_locker_sprite)
	move_child(_locker_sprite, 0)

	var frames := SpriteFrames.new()
	_add_still(frames, "closed", closed_texture)
	_add_still(frames, "open_loaded", open_loaded_texture if open_loaded_texture != null else closed_texture)
	_add_still(frames, "empty", empty_texture if empty_texture != null else closed_texture)

	# authorize_open — plays the transformation once, then stops on its last frame
	frames.add_animation("authorize_open")
	frames.set_animation_speed("authorize_open", ANIMATION_FPS)
	frames.set_animation_loop("authorize_open", false)

	var columns := maxi(1, strip_texture.get_width() / FRAME_SIZE.x)
	for frame_index in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = strip_texture
		atlas.region = Rect2(
			(frame_index % columns) * FRAME_SIZE.x,
			(frame_index / columns) * FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y,
		)
		frames.add_frame("authorize_open", atlas)

	_locker_sprite.sprite_frames = frames
	_locker_sprite.animation = &"closed"
	_locker_sprite.frame = 0
	_locker_sprite.stop()


func _add_still(frames: SpriteFrames, name: String, texture: Texture2D) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, 0.0)
	frames.set_animation_loop(name, false)
	frames.add_frame(name, texture)


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func get_interaction_prompt() -> String:
	var key := _get_interact_prompt_key()
	match _state:
		LockerState.CLOSED:
			return "AUTHORIZE DESIGNATION LOCKER (%s)" % key
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


## Authorization: the faceplate transformation plays once, then the locker rests
## on `open_loaded` with the P-9 visible in its cradle.
func _open_locker() -> void:
	if _locker_sprite == null:
		return
	_opening_playback_started = true
	_locker_sprite.animation = &"authorize_open"
	_locker_sprite.frame = 0
	_locker_sprite.play()
	await _locker_sprite.animation_finished
	_locker_sprite.stop()
	_locker_sprite.animation = &"open_loaded"
	_locker_sprite.frame = 0
	_state = LockerState.OPEN


func _take_sidearm(actor: Node) -> void:
	if _sidearm_granted:
		return

	var inventory_manager := get_node_or_null("/root/InventoryManager")
	if inventory_manager == null or not inventory_manager.has_method("add_item"):
		push_warning("[SidearmLocker] InventoryManager not available")
		return

	var result: Variant = inventory_manager.call("add_item", &"p9_sidearm", 1)
	if int(result) <= 0:
		push_warning("[SidearmLocker] Failed to add P-9 to inventory")
		return

	_sidearm_granted = true
	_state = LockerState.EMPTY
	remove_from_group("interactable")

	# Retention hardware remains; the cradle is now unloaded.
	if _locker_sprite != null:
		_locker_sprite.animation = &"empty"
		_locker_sprite.frame = 0
		_locker_sprite.stop()

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
