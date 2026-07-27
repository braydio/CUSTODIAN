@tool
extends Node2D
class_name HumanoidCutoutRig2D

signal state_started(state: StringName)
signal state_finished(state: StringName)
signal direction_changed(direction: StringName)

const ATLAS_SIZE := Vector2i(480, 384)
const CELL_SIZE := Vector2i(96, 96)
const PART_CELLS := {
	&"head": Vector2i(0, 0),
	&"torso": Vector2i(1, 0),
	&"pelvis": Vector2i(2, 0),
	&"back_attachment": Vector2i(3, 0),
	&"front_attachment": Vector2i(4, 0),
	&"upper_arm_back": Vector2i(0, 1),
	&"forearm_back": Vector2i(1, 1),
	&"hand_back": Vector2i(2, 1),
	&"upper_arm_front": Vector2i(3, 1),
	&"forearm_front": Vector2i(4, 1),
	&"hand_front": Vector2i(0, 2),
	&"thigh_back": Vector2i(1, 2),
	&"shin_back": Vector2i(2, 2),
	&"foot_back": Vector2i(3, 2),
	&"thigh_front": Vector2i(4, 2),
	&"shin_front": Vector2i(0, 3),
	&"foot_front": Vector2i(1, 3),
	&"weapon": Vector2i(2, 3),
	&"cape": Vector2i(3, 3),
	&"reserved": Vector2i(4, 3),
}
const REQUIRED_PARTS := [
	&"head", &"torso", &"pelvis",
	&"upper_arm_back", &"forearm_back", &"hand_back",
	&"upper_arm_front", &"forearm_front", &"hand_front",
	&"thigh_back", &"shin_back", &"foot_back",
	&"thigh_front", &"shin_front", &"foot_front",
]
const PART_NODE_PATHS := {
	&"pelvis": ^"MotionRoot/PelvisPivot/PelvisSprite",
	&"cape": ^"MotionRoot/PelvisPivot/CapePivot/CapeSprite",
	&"back_attachment": ^"MotionRoot/PelvisPivot/BackAttachmentPivot/BackAttachmentSprite",
	&"torso": ^"MotionRoot/PelvisPivot/TorsoPivot/TorsoSprite",
	&"head": ^"MotionRoot/PelvisPivot/TorsoPivot/HeadPivot/HeadSprite",
	&"upper_arm_back": ^"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackUpperArmSprite",
	&"forearm_back": ^"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot/BackForearmSprite",
	&"hand_back": ^"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot/BackHandPivot/BackHandSprite",
	&"upper_arm_front": ^"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontUpperArmSprite",
	&"forearm_front": ^"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot/FrontForearmSprite",
	&"hand_front": ^"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot/FrontHandPivot/FrontHandSprite",
	&"thigh_back": ^"MotionRoot/PelvisPivot/BackThighPivot/BackThighSprite",
	&"shin_back": ^"MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot/BackShinSprite",
	&"foot_back": ^"MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot/BackFootPivot/BackFootSprite",
	&"thigh_front": ^"MotionRoot/PelvisPivot/FrontThighPivot/FrontThighSprite",
	&"shin_front": ^"MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot/FrontShinSprite",
	&"foot_front": ^"MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot/FrontFootPivot/FrontFootSprite",
	&"front_attachment": ^"MotionRoot/PelvisPivot/FrontAttachmentPivot/FrontAttachmentSprite",
	&"weapon": ^"MotionRoot/PelvisPivot/WeaponPivot/WeaponSprite",
	&"reserved": ^"MotionRoot/PelvisPivot/ReservedPivot/ReservedSprite",
}

@export_group("Rig")
@export var skin: HumanoidCutoutRigSkin:
	set(value):
		skin = value
		if value != null and value.profile != null:
			profile = value.profile
		if is_node_ready():
			_apply_skin()
@export var profile: HumanoidCutoutRigProfile:
	set(value):
		profile = value
		if is_node_ready():
			reset_to_rest_pose()

@export_group("Editor Preview")
@export_enum("s", "n", "e", "w") var preview_direction: String = "s":
	set(value):
		preview_direction = value
		if Engine.is_editor_hint() and is_node_ready():
			set_direction_code(StringName(value))
@export_enum("idle", "run", "attack_light", "hit_react", "death") var preview_animation: String = "idle":
	set(value):
		preview_animation = value
		if Engine.is_editor_hint() and is_node_ready():
			play_state(StringName(value), true)
@export_range(0.05, 4.0, 0.05) var playback_speed: float = 1.0:
	set(value):
		playback_speed = maxf(0.05, value)
		if is_node_ready():
			animation_player.speed_scale = playback_speed
@export var show_pivots: bool = false:
	set(value):
		show_pivots = value
		queue_redraw()
@export var show_part_bounds: bool = false:
	set(value):
		show_part_bounds = value
		queue_redraw()
@export var show_baseline: bool = false:
	set(value):
		show_baseline = value
		queue_redraw()
@export var show_atlas_cell_names: bool = false:
	set(value):
		show_atlas_cell_names = value
		queue_redraw()
@export var pixel_snap_preview: bool = true
@export_range(0.0, 45.0, 1.0) var review_rotation_quantization_degrees: float = 0.0
@export_tool_button("Reset Rest Pose") var reset_rest_pose_action := reset_to_rest_pose
@export_tool_button("Reload Skin") var reload_skin_action := reload_skin

@onready var motion_root: Node2D = $MotionRoot
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon_grip_anchor: Marker2D = $MotionRoot/PelvisPivot/WeaponPivot/WeaponGripAnchor
@onready var weapon_tip_anchor: Marker2D = $MotionRoot/PelvisPivot/WeaponPivot/WeaponTipAnchor
@onready var hit_anchor: Marker2D = $HitAnchor

var _direction: StringName = &"s"
var _state: StringName = &""
var _warned_missing_required_atlases := false
var _warned_invalid_atlases: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var finished := Callable(self, "_on_animation_finished")
	if not animation_player.animation_finished.is_connected(finished):
		animation_player.animation_finished.connect(finished)
	if profile == null and skin != null:
		profile = skin.profile
	if profile == null:
		profile = HumanoidCutoutRigProfile.new()
	reset_to_rest_pose()
	_apply_skin()
	set_direction_code(StringName(preview_direction))
	set_playback_speed(playback_speed)
	if Engine.is_editor_hint():
		play_state(StringName(preview_animation), true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and pixel_snap_preview:
		motion_root.position = motion_root.position.round()
	if Engine.is_editor_hint() and review_rotation_quantization_degrees > 0.0:
		var step := deg_to_rad(review_rotation_quantization_degrees)
		for node in _pivot_nodes():
			node.rotation = snappedf(node.rotation, step)


func set_skin(value: HumanoidCutoutRigSkin) -> void:
	skin = value


func set_facing_vector(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	var abs_x := absf(direction.x)
	var abs_y := absf(direction.y)
	var next := _direction
	if is_equal_approx(abs_x, abs_y):
		if _direction == &"n" or _direction == &"s":
			next = &"n" if direction.y < 0.0 else &"s"
		elif _direction == &"e" or _direction == &"w":
			next = &"w" if direction.x < 0.0 else &"e"
	elif abs_x > abs_y:
		next = &"w" if direction.x < 0.0 else &"e"
	else:
		next = &"n" if direction.y < 0.0 else &"s"
	set_direction_code(next)


func set_direction_code(direction: StringName) -> void:
	var normalized := direction
	if not [&"n", &"e", &"s", &"w"].has(normalized):
		normalized = &"s"
	if normalized == _direction and _parts_have_textures():
		return
	_direction = normalized
	_apply_skin()
	_apply_draw_order()
	direction_changed.emit(_direction)


func play_state(state: StringName, restart: bool = false) -> void:
	if not has_state(state):
		return
	if not restart and _state == state and animation_player.is_playing():
		return
	reset_to_rest_pose()
	_state = state
	animation_player.play(String(state), -1.0, playback_speed)
	state_started.emit(state)


func stop_state() -> void:
	animation_player.stop()
	_state = &""


func has_state(state: StringName) -> bool:
	return animation_player != null and animation_player.has_animation(String(state))


func set_playback_speed(multiplier: float) -> void:
	playback_speed = maxf(0.05, multiplier)


func set_visual_modulate(value: Color) -> void:
	motion_root.modulate = value


func get_weapon_grip_anchor() -> Marker2D:
	return weapon_grip_anchor


func get_weapon_tip_anchor() -> Marker2D:
	return weapon_tip_anchor


func get_hit_anchor() -> Marker2D:
	return hit_anchor


func get_direction_code() -> StringName:
	return _direction


func is_west_mirrored() -> bool:
	return motion_root.scale.x < 0.0


func reload_skin() -> void:
	_warned_missing_required_atlases = false
	_warned_invalid_atlases.clear()
	_apply_skin()


func reset_to_rest_pose() -> void:
	if not is_node_ready():
		return
	animation_player.stop()
	motion_root.position = Vector2.ZERO
	motion_root.rotation = 0.0
	for pivot in _pivot_nodes():
		pivot.rotation = 0.0
		pivot.scale = Vector2.ONE
	_apply_profile_layout()
	_apply_draw_order()
	queue_redraw()


func _apply_skin() -> void:
	if not is_node_ready():
		return
	if skin == null:
		for sprite in _part_sprites().values():
			(sprite as Sprite2D).texture = null
		return
	if profile == null:
		profile = skin.profile if skin.profile != null else HumanoidCutoutRigProfile.new()
	if not skin.has_required_atlases() and not _warned_missing_required_atlases:
		_warned_missing_required_atlases = true
		push_warning("[HumanoidCutoutRig2D] Skin '%s' requires south, north, and east 480x384 atlases." % String(skin.skin_id))
	var atlas := skin.get_atlas(_direction)
	var atlas_valid := _is_valid_atlas(atlas, _direction)
	for part_name in PART_CELLS:
		var sprite := get_node_or_null(PART_NODE_PATHS[part_name]) as Sprite2D
		if sprite == null:
			continue
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.texture = _slice_atlas(atlas, PART_CELLS[part_name]) if atlas_valid else null
	motion_root.scale = Vector2(-1.0, 1.0) if _direction == &"w" and skin.uses_mirrored_west() else Vector2.ONE
	motion_root.modulate = skin.default_modulate
	_apply_profile_layout()
	_apply_draw_order()


func _is_valid_atlas(atlas: Texture2D, direction: StringName) -> bool:
	if atlas == null:
		return false
	var actual := Vector2i(atlas.get_width(), atlas.get_height())
	if actual == ATLAS_SIZE:
		return true
	if not _warned_invalid_atlases.has(direction):
		_warned_invalid_atlases[direction] = true
		push_warning("[HumanoidCutoutRig2D] Direction '%s' atlas is %s; expected %s." % [String(direction), actual, ATLAS_SIZE])
	return false


func _slice_atlas(atlas: Texture2D, cell: Vector2i) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = atlas
	result.region = Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE))
	result.filter_clip = true
	return result


func _apply_profile_layout() -> void:
	if profile == null:
		return
	var atlas_offset := profile.get_atlas_offset(_direction)
	var pivots := {
		^"MotionRoot/PelvisPivot": [&"pelvis", profile.pelvis_anchor],
		^"MotionRoot/PelvisPivot/CapePivot": [&"cape", profile.cape_anchor],
		^"MotionRoot/PelvisPivot/BackAttachmentPivot": [&"back_attachment", profile.back_attachment_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot": [&"torso", profile.torso_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot/HeadPivot": [&"head", profile.head_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot": [&"far_shoulder", profile.far_shoulder_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot": [&"far_elbow", profile.far_elbow_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot/BackHandPivot": [&"far_wrist", profile.far_wrist_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot": [&"near_shoulder", profile.near_shoulder_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot": [&"near_elbow", profile.near_elbow_anchor],
		^"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot/FrontHandPivot": [&"near_wrist", profile.near_wrist_anchor],
		^"MotionRoot/PelvisPivot/BackThighPivot": [&"far_hip", profile.far_hip_anchor],
		^"MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot": [&"far_knee", profile.far_knee_anchor],
		^"MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot/BackFootPivot": [&"far_ankle", profile.far_ankle_anchor],
		^"MotionRoot/PelvisPivot/FrontThighPivot": [&"near_hip", profile.near_hip_anchor],
		^"MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot": [&"near_knee", profile.near_knee_anchor],
		^"MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot/FrontFootPivot": [&"near_ankle", profile.near_ankle_anchor],
		^"MotionRoot/PelvisPivot/FrontAttachmentPivot": [&"front_attachment", profile.front_attachment_anchor],
		^"MotionRoot/PelvisPivot/WeaponPivot": [&"weapon", profile.weapon_anchor],
	}
	for path in pivots:
		var node := get_node_or_null(path) as Node2D
		if node == null:
			continue
		var spec: Array = pivots[path]
		var absolute_anchor := profile.get_pivot(_direction, spec[0], spec[1])
		var parent_pivot := node.get_parent() as Node2D
		if parent_pivot == motion_root:
			node.position = absolute_anchor - profile.frame_center + profile.visual_offset
		else:
			node.position = absolute_anchor - _absolute_profile_anchor_for_node(parent_pivot)
	for part_name in PART_NODE_PATHS:
		var sprite := get_node_or_null(PART_NODE_PATHS[part_name]) as Sprite2D
		if sprite == null:
			continue
		var pivot := sprite.get_parent() as Node2D
		var pivot_absolute := _absolute_profile_anchor_for_node(pivot)
		sprite.position = atlas_offset - pivot_absolute
	weapon_grip_anchor.position = profile.weapon_grip_anchor - profile.weapon_anchor
	weapon_tip_anchor.position = profile.weapon_tip_anchor - profile.weapon_anchor
	$BodyCenterAnchor.position = profile.pelvis_anchor - profile.frame_center + profile.visual_offset
	$HeadAnchor.position = profile.head_anchor - profile.frame_center + profile.visual_offset
	hit_anchor.position = profile.torso_anchor - profile.frame_center + profile.visual_offset
	$GroundAnchor.position = Vector2(0.0, profile.ground_y - profile.frame_center.y) + profile.visual_offset


func _absolute_profile_anchor_for_node(node: Node2D) -> Vector2:
	if node == $MotionRoot/PelvisPivot:
		return profile.get_pivot(_direction, &"pelvis", profile.pelvis_anchor)
	var mapping := {
		$MotionRoot/PelvisPivot/CapePivot: [&"cape", profile.cape_anchor],
		$MotionRoot/PelvisPivot/BackAttachmentPivot: [&"back_attachment", profile.back_attachment_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot: [&"torso", profile.torso_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot/HeadPivot: [&"head", profile.head_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot: [&"far_shoulder", profile.far_shoulder_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot: [&"far_elbow", profile.far_elbow_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot/BackHandPivot: [&"far_wrist", profile.far_wrist_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot: [&"near_shoulder", profile.near_shoulder_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot: [&"near_elbow", profile.near_elbow_anchor],
		$MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot/FrontHandPivot: [&"near_wrist", profile.near_wrist_anchor],
		$MotionRoot/PelvisPivot/BackThighPivot: [&"far_hip", profile.far_hip_anchor],
		$MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot: [&"far_knee", profile.far_knee_anchor],
		$MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot/BackFootPivot: [&"far_ankle", profile.far_ankle_anchor],
		$MotionRoot/PelvisPivot/FrontThighPivot: [&"near_hip", profile.near_hip_anchor],
		$MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot: [&"near_knee", profile.near_knee_anchor],
		$MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot/FrontFootPivot: [&"near_ankle", profile.near_ankle_anchor],
		$MotionRoot/PelvisPivot/FrontAttachmentPivot: [&"front_attachment", profile.front_attachment_anchor],
		$MotionRoot/PelvisPivot/WeaponPivot: [&"weapon", profile.weapon_anchor],
	}
	var spec: Variant = mapping.get(node)
	if spec is Array:
		return profile.get_pivot(_direction, spec[0], spec[1])
	return Vector2.ZERO


func _apply_draw_order() -> void:
	if profile == null:
		return
	var order := profile.get_draw_order(_direction)
	for part_name in PART_NODE_PATHS:
		var sprite := get_node_or_null(PART_NODE_PATHS[part_name]) as Sprite2D
		if sprite != null:
			sprite.z_as_relative = true
			sprite.z_index = int(order.get(String(part_name), 0))


func _part_sprites() -> Dictionary:
	var result := {}
	for part_name in PART_NODE_PATHS:
		var sprite := get_node_or_null(PART_NODE_PATHS[part_name]) as Sprite2D
		if sprite != null:
			result[part_name] = sprite
	return result


func _pivot_nodes() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for child in motion_root.find_children("*Pivot", "Node2D", true, false):
		if child is Node2D:
			result.append(child as Node2D)
	return result


func _parts_have_textures() -> bool:
	var sprites := _part_sprites()
	return not sprites.is_empty() and (sprites.values()[0] as Sprite2D).texture != null


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == _state:
		state_finished.emit(_state)


func _draw() -> void:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		return
	if profile == null:
		return
	var color := Color(0.2, 0.9, 1.0, 0.8)
	if show_baseline:
		var y := profile.ground_y - profile.frame_center.y + profile.visual_offset.y
		draw_line(Vector2(-48, y), Vector2(48, y), Color(1.0, 0.75, 0.2, 0.8), 1.0)
	if show_pivots:
		for pivot in _pivot_nodes():
			var p := to_local(pivot.global_position)
			draw_line(p - Vector2(3, 0), p + Vector2(3, 0), color, 1.0)
			draw_line(p - Vector2(0, 3), p + Vector2(0, 3), color, 1.0)
	if show_part_bounds:
		for sprite in _part_sprites().values():
			var part := sprite as Sprite2D
			var top_left := to_local(part.global_position)
			draw_rect(Rect2(top_left, Vector2(CELL_SIZE)), Color(0.2, 1.0, 0.4, 0.3), false, 1.0)
	if show_atlas_cell_names:
		var font := ThemeDB.fallback_font
		var row := 0
		for part_name in PART_CELLS:
			draw_string(font, Vector2(52, -44 + row * 7), String(part_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)
			row += 1
