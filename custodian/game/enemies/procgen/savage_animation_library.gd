extends RefCounted
class_name SavageAnimationLibrary

const ANIMATION_SPECS := {
	"idle_e": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__e__9f__128.png",
		"frame_size": Vector2i(128, 128),
		"fps": 6.0,
	},
	"idle_n": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__n__5f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 6.0,
	},
	"idle_s": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__s__9f__95.png",
		"frame_size": Vector2i(95, 95),
		"fps": 6.0,
	},
	"idle_se": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__se__5f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 6.0,
	},
	"idle_sw": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__sw__4f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 6.0,
	},
	"idle_w": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__w__9f__128.png",
		"frame_size": Vector2i(128, 128),
		"fps": 6.0,
	},
}

static var _cached_frames: SpriteFrames = null


static func get_savage_sprite_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames
	var frames := SpriteFrames.new()
	for animation_name in ANIMATION_SPECS:
		_add_strip_animation(frames, String(animation_name), ANIMATION_SPECS[animation_name])
	_cached_frames = frames
	return _cached_frames


static func get_idle_animation(direction: Vector2) -> StringName:
	var suffix := _get_direction_suffix(direction)
	if suffix == &"ne":
		return &"idle_n"
	if suffix == &"nw":
		return &"idle_n"
	return StringName("idle_%s" % String(suffix))


static func _add_strip_animation(frames: SpriteFrames, animation_name: String, spec: Dictionary) -> void:
	var path := String(spec["path"])
	if not ResourceLoader.exists(path):
		push_warning("[SavageAnimationLibrary] Missing savage sheet: %s" % path)
		return
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("[SavageAnimationLibrary] Savage sheet is not a Texture2D: %s" % path)
		return
	var frame_size: Vector2i = spec["frame_size"]
	if texture.get_height() != frame_size.y or texture.get_width() % frame_size.x != 0:
		push_warning("[SavageAnimationLibrary] Savage sheet has unexpected dimensions: %s" % path)
		return
	var frame_count := int(texture.get_width() / frame_size.x)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, float(spec.get("fps", 6.0)))
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(float(frame_index * frame_size.x), 0.0, float(frame_size.x), float(frame_size.y))
		frames.add_frame(animation_name, atlas)


static func _get_direction_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector := int(round(angle / (PI / 4.0))) % 8
	var angle_to_suffix := [&"e", &"se", &"s", &"sw", &"w", &"nw", &"n", &"ne"]
	return angle_to_suffix[sector]
