extends RefCounted
class_name GruntAnimationLibrary

const GRUNT_FRAME_SIZE := Vector2i(96, 96)

const ANIMATION_SPECS := {
	"idle_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__locomotion__idle_01__s__10f__96.png",
		"fps": 6.0,
		"loop": true,
	},
	"run_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__locomotion__run_01__e__10f__96.png",
		"fps": 10.0,
		"loop": true,
	},
	"run_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__locomotion__run_01__w__10f__96.png",
		"fps": 10.0,
		"loop": true,
	},
	"melee_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__e__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_se": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__se__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__w__11f__96.png",
		"fps": 12.0,
		"loop": false,
	},
}

const FX_ANIMATION_SPECS := {
	"melee_fx_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__e__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_fx_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__w__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
}

static var _cached_frames: SpriteFrames = null
static var _cached_fx_frames: SpriteFrames = null


static func get_grunt_sprite_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames
	var frames := SpriteFrames.new()
	for animation_name in ANIMATION_SPECS.keys():
		_add_strip_animation(frames, String(animation_name), ANIMATION_SPECS[animation_name])
	_cached_frames = frames
	return _cached_frames


static func get_grunt_fx_sprite_frames() -> SpriteFrames:
	if _cached_fx_frames != null:
		return _cached_fx_frames
	var frames := SpriteFrames.new()
	for animation_name in FX_ANIMATION_SPECS.keys():
		_add_strip_animation(frames, String(animation_name), FX_ANIMATION_SPECS[animation_name])
	_cached_fx_frames = frames
	return _cached_fx_frames


static func get_move_animation(direction: Vector2) -> StringName:
	return &"run_w" if direction.x < 0.0 else &"run_e"


static func get_attack_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		return &"melee_w"
	if direction.y > 0.35 and direction.x >= 0.0:
		return &"melee_se"
	return &"melee_e"


static func get_attack_fx_animation(direction: Vector2) -> StringName:
	return &"melee_fx_w" if direction.x < -0.2 else &"melee_fx_e"


static func _add_strip_animation(frames: SpriteFrames, animation_name: String, spec: Dictionary) -> void:
	var path := String(spec["path"])
	if not ResourceLoader.exists(path):
		push_warning("[GruntAnimationLibrary] Missing grunt sheet: %s" % path)
		return
	var texture := load(path)
	if not (texture is Texture2D):
		push_warning("[GruntAnimationLibrary] Grunt sheet is not a Texture2D: %s" % path)
		return
	var tex := texture as Texture2D
	var frame_width := GRUNT_FRAME_SIZE.x
	var frame_height := GRUNT_FRAME_SIZE.y
	var frame_count := int(tex.get_width() / frame_width)
	if frame_count <= 0 or tex.get_height() < frame_height:
		push_warning("[GruntAnimationLibrary] Grunt sheet has unexpected dimensions: %s" % path)
		return
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, bool(spec.get("loop", true)))
	frames.set_animation_speed(animation_name, float(spec.get("fps", 8.0)))
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float(frame_index * frame_width), 0.0, float(frame_width), float(frame_height))
		frames.add_frame(animation_name, atlas)
