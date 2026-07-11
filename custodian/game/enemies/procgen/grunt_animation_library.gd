extends RefCounted
class_name GruntAnimationLibrary

const GRUNT_FRAME_SIZE := Vector2i(96, 96)
const MARINE_FRAME_SIZE := Vector2i(96, 96)
const MARINE_DASH_FRAME_SIZE := Vector2i(128, 128)
const MARINE_DASH_FX_FRAME_SIZE := Vector2i(156, 156)
const MARINE_IDLE_DIRECTIONS := [&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw"]

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
	"melee_sw": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__sw__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__fast_01__w__11f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"stagger_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__stagger_01__s__8f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"stagger_e": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__stagger_01__e__8f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"stagger_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__stagger_01__w__8f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"crit_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__crit_01__s__8f__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"crit_recovery_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__crit_recovery_01__s__5f__96.png",
		"fps": 8.0,
		"loop": false,
	},
	"death_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__death_01__s__5__96.png",
		"fps": 10.0,
		"loop": false,
	},
	"flinch_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__flinch_01__s__6__96.png",
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
	"melee_fx_se": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__se__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_fx_sw": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__sw__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"melee_fx_w": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__fast_01__w__10f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"crit_fx_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__crit_01__s__8f__96.png",
		"fps": 12.0,
		"loop": false,
	},
	"flinch_fx_s": {
		"path": "res://content/sprites/enemies/enemy_grunt/runtime/fx/enemy_grunt__fx__melee__flinch_01__s__5f__96.png",
		"fps": 12.0,
		"loop": false,
	},
}

static var _cached_frames: SpriteFrames = null
static var _cached_fx_frames: SpriteFrames = null
static var _cached_marine_frames: SpriteFrames = null
static var _cached_marine_fx_frames: SpriteFrames = null


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


static func get_marine_sprite_frames() -> SpriteFrames:
	if _cached_marine_frames != null:
		return _cached_marine_frames
	var frames := SpriteFrames.new()
	for direction in MARINE_IDLE_DIRECTIONS:
		var suffix := String(direction)
		var spec := {
			"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__idle_01__%s__4f__96.png" % suffix,
			"fps": 6.0,
			"loop": true,
			"frame_size": MARINE_FRAME_SIZE,
		}
		_add_strip_animation(frames, "marine_idle_%s" % suffix, spec)
	_add_strip_animation(frames, "marine_dash_charge_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_charge_01__e__5f__128.png",
		"fps": 12.0,
		"loop": false,
		"frame_size": MARINE_DASH_FRAME_SIZE,
	})
	_add_strip_animation(frames, "marine_dash_inflight_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_inflight_01__e__5f__128.png",
		"fps": 20.0,
		"loop": false,
		"frame_size": MARINE_DASH_FRAME_SIZE,
	})
	_add_strip_animation(frames, "marine_dash_recovery_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_recovery_01__e__5f__128.png",
		"fps": 12.0,
		"loop": false,
		"frame_size": MARINE_DASH_FRAME_SIZE,
	})
	_cached_marine_frames = frames
	return _cached_marine_frames


static func get_marine_fx_sprite_frames() -> SpriteFrames:
	if _cached_marine_fx_frames != null:
		return _cached_marine_fx_frames
	var frames := SpriteFrames.new()
	_add_strip_animation(frames, "marine_dash_attack_fx_e", {
		"path": "res://content/sprites/enemies/enemy_marine/runtime/fx/enemy_marine__fx__unarmed__dash_attack_01__e__8f__156.png",
		"fps": 13.0,
		"loop": false,
		"frame_size": MARINE_DASH_FX_FRAME_SIZE,
	})
	_cached_marine_fx_frames = frames
	return _cached_marine_fx_frames


static func get_move_animation(direction: Vector2) -> StringName:
	return &"run_w" if direction.x < 0.0 else &"run_e"


static func get_attack_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		if direction.y > 0.35:
			return &"melee_sw"
		return &"melee_w"
	if direction.y > 0.35 and direction.x >= 0.0:
		return &"melee_se"
	return &"melee_e"


static func get_stagger_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		return &"stagger_w"
	if direction.x > 0.2:
		return &"stagger_e"
	return &"stagger_s"


static func get_attack_fx_animation(direction: Vector2) -> StringName:
	if direction.x < -0.2:
		if direction.y > 0.35:
			return &"melee_fx_sw"
		return &"melee_fx_w"
	if direction.y > 0.35:
		return &"melee_fx_se"
	return &"melee_fx_e"


static func get_marine_idle_animation(direction: Vector2) -> StringName:
	return StringName("marine_idle_%s" % _get_direction_suffix(direction))


static func get_marine_dash_attack_animation(_direction: Vector2) -> StringName:
	return &"marine_dash_inflight_e"


static func get_marine_dash_phase_animation(phase: StringName, _direction: Vector2 = Vector2.RIGHT) -> StringName:
	match phase:
		&"windup":
			return &"marine_dash_charge_e"
		&"dash":
			return &"marine_dash_inflight_e"
		&"impact_lock":
			return &"marine_dash_inflight_e"
		&"recovery":
			return &"marine_dash_recovery_e"
	return &"marine_dash_inflight_e"


static func get_marine_dash_attack_fx_animation(_direction: Vector2) -> StringName:
	return &"marine_dash_attack_fx_e"


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
	var frame_size: Vector2i = spec.get("frame_size", GRUNT_FRAME_SIZE)
	var frame_width := frame_size.x
	var frame_height := frame_size.y
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


static func _get_direction_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector := int(round(angle / (PI / 4.0))) % 8
	var angle_to_suffix := [&"e", &"se", &"s", &"sw", &"w", &"nw", &"n", &"ne"]
	return angle_to_suffix[sector]
