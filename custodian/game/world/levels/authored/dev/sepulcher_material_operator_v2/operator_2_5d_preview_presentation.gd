extends Node2D
class_name SepulcherCanonicalOperatorPreviewPresentation

signal visual_mode_changed(canonical_enabled: bool)

const DIRECTION_VECTORS := [
	Vector2(0.0, -1.0),
	Vector2(0.70710678, -0.70710678),
	Vector2(1.0, 0.0),
	Vector2(0.70710678, 0.70710678),
	Vector2(0.0, 1.0),
	Vector2(-0.70710678, 0.70710678),
	Vector2(-1.0, 0.0),
	Vector2(-0.70710678, -0.70710678),
]
const DIRECTION_NAMES := [&"N", &"NE", &"E", &"SE", &"S", &"SW", &"W", &"NW"]
const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const ILLUSTRATIVE_PREVIEW_FPS := 8.0
const LEGACY_BODY_PATHS := [
	NodePath("AnimatedSprite2D"),
	NodePath("ModularLowerBodySprite"),
	NodePath("ModularUpperBodySprite"),
]
const LEGACY_OVERLAY_PATHS := [
	NodePath("ModularSidearmSprite"),
	NodePath("ModularUpperFxSprite"),
	NodePath("DodgeFXBackSprite"),
	NodePath("MeleeWeaponOverlaySprite"),
	NodePath("MeleeFxOverlaySprite"),
	NodePath("PrimaryWeaponSocket/PrimaryWeaponSprite"),
	NodePath("PrimaryWeaponSocket/WeaponSprite"),
	NodePath("PrimaryWeaponSocket/OffhandPropSprite"),
]

@export var canonical_idle_sheet: Texture2D

var _operator: CharacterBody2D
var _canonical_sprite: Sprite2D
var _atlas_frames: Array[AtlasTexture] = []
var _canonical_enabled := true
var _frame_index := 0
var _direction_index := 4
var _frame_elapsed := 0.0
var _ready_for_input := false


func _ready() -> void:
	process_priority = 1000
	set_process(true)
	set_process_unhandled_input(true)
	_operator = get_parent() as CharacterBody2D
	_canonical_sprite = Sprite2D.new()
	_canonical_sprite.name = "Canonical128IdleBody"
	_canonical_sprite.centered = true
	# Existing legacy root [48,84] at Sprite2D position y=-18 resolves to actor-local y=18.
	# Match that projected ground registration with the accepted [64,106] 128px root.
	_canonical_sprite.position = Vector2(0.0, -24.0)
	_canonical_sprite.scale = Vector2.ONE
	_canonical_sprite.rotation = 0.0
	_canonical_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canonical_sprite.z_index = 1
	_canonical_sprite.visible = false
	add_child(_canonical_sprite)
	call_deferred("_initialize_preview")


func _initialize_preview() -> void:
	if _operator == null or canonical_idle_sheet == null:
		push_error("Sepulcher canonical preview requires the real Operator and accepted idle sheet")
		return
	if canonical_idle_sheet.get_width() != 1920 or canonical_idle_sheet.get_height() != 1024:
		push_error("Sepulcher canonical preview sheet must remain 1920x1024")
		return
	_build_atlas_frames()
	_canonical_enabled = true
	_canonical_sprite.visible = true
	_render_frame()
	_suppress_legacy_visuals()
	_ready_for_input = true
	visual_mode_changed.emit(true)


func _process(delta: float) -> void:
	if not _ready_for_input or not _canonical_enabled:
		return
	_suppress_legacy_visuals()
	_update_facing()
	_frame_elapsed += delta
	var frame_duration := 1.0 / ILLUSTRATIVE_PREVIEW_FPS
	while _frame_elapsed >= frame_duration:
		_frame_elapsed -= frame_duration
		_frame_index = (_frame_index + 1) % FRAMES_PER_DIRECTION
		_render_frame()


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_V:
		set_canonical_enabled(not _canonical_enabled)
		get_viewport().set_input_as_handled()


func set_canonical_enabled(enabled: bool) -> void:
	if _canonical_enabled == enabled:
		return
	_canonical_enabled = enabled
	_canonical_sprite.visible = enabled
	if enabled:
		_suppress_legacy_visuals()
	else:
		# The actual Operator remains the controller and animation authority. Let its
		# ordinary presentation code restore the live legacy appearance on the next tick.
		_operator.call_deferred("_update_animation")
		_operator.call_deferred("_update_primary_weapon_visual", false)
	visual_mode_changed.emit(enabled)


func is_canonical_enabled() -> bool:
	return _canonical_enabled


func get_canonical_sprite() -> Sprite2D:
	return _canonical_sprite


func get_direction_name() -> StringName:
	return DIRECTION_NAMES[_direction_index]


func get_frame_index() -> int:
	return _frame_index


func set_preview_frame(frame_index: int) -> void:
	_frame_index = posmod(frame_index, FRAMES_PER_DIRECTION)
	_frame_elapsed = 0.0
	_render_frame()


func _build_atlas_frames() -> void:
	_atlas_frames.clear()
	for direction in range(DIRECTION_COUNT):
		for frame in range(FRAMES_PER_DIRECTION):
			var atlas := AtlasTexture.new()
			atlas.atlas = canonical_idle_sheet
			atlas.region = Rect2(
				Vector2(frame * FRAME_SIZE.x, direction * FRAME_SIZE.y),
				Vector2(FRAME_SIZE)
			)
			_atlas_frames.append(atlas)


func _update_facing() -> void:
	var direction: Vector2
	if _operator.velocity.length_squared() > 0.0001:
		direction = _operator.get("movement_direction")
	else:
		direction = _operator.get("visual_idle_direction")
	if direction.length_squared() <= 0.0001:
		direction = Vector2.DOWN
	var resolved := _resolve_direction(direction)
	if resolved != _direction_index:
		_direction_index = resolved
		_frame_index = 0
		_frame_elapsed = 0.0
		_render_frame()


func _resolve_direction(direction: Vector2) -> int:
	var normalized := direction.normalized()
	var best_index := 0
	var best_dot := -INF
	for index in DIRECTION_VECTORS.size():
		var candidate := normalized.dot(DIRECTION_VECTORS[index])
		if candidate > best_dot:
			best_dot = candidate
			best_index = index
	return best_index


func _render_frame() -> void:
	if _atlas_frames.size() != DIRECTION_COUNT * FRAMES_PER_DIRECTION:
		return
	_canonical_sprite.texture = _atlas_frames[_direction_index * FRAMES_PER_DIRECTION + _frame_index]


func _suppress_legacy_visuals() -> void:
	if _operator == null or not is_instance_valid(_operator):
		return
	for path in LEGACY_BODY_PATHS + LEGACY_OVERLAY_PATHS:
		var layer := _operator.get_node_or_null(path) as CanvasItem
		if layer == null:
			continue
		if _operator.has_method("_hide_presentation_layer"):
			_operator.call("_hide_presentation_layer", layer, false)
		else:
			layer.visible = false
