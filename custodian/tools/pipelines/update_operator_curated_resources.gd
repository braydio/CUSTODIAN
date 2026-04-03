extends SceneTree

const BODY_FRAMES_PATH := "res://game/actors/operator/operator_runtime_frames.tres"
const WEAPON_FRAMES_PATH := "res://game/actors/operator/operator_weapon_frames.tres"
const MELEE_OVERLAY_FRAMES_PATH := "res://game/actors/operator/operator_melee_overlay_frames.tres"

const BASE_WALK_SHEET := "res://content/sprites/operator/runtime/animation_base/body/core_locomotion/walking_base.png"
const BASE_RUN_SHEET := "res://content/sprites/operator/runtime/animation_base/body/core_locomotion/running_base.png"
const BASE_LIGHT_ATTACK_SHEET := "res://content/sprites/operator/runtime/animation_base/body/melee/light_attack_base.png"
const BASE_FAST_ATTACK_RIGHT_SHEET := "res://content/sprites/operator/runtime/animation_base/body/melee/fast_attack_right_base.png"
const BASE_DEATH_SHEET := "res://content/sprites/operator/runtime/animation_base/body/core_locomotion/death_disintigrate_base.png"
const RANGED_RUN_SHEET := "res://content/sprites/operator/runtime/curated/body/ranged_2h/equipped_run_right_body.png"
const HEAVY_ANTICIPATION_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/heavy_anticipation_body.png"
const FAST_ATTACK_1_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/fast_attack_1_right_body.png"
const FAST_ATTACK_2_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/fast_attack_2_right_body.png"
const FAST_RECOVERY_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/fast_recovery_body.png"
const WALK_BASE_SLICES := [
	{"animation": "walk_up", "start": 56, "count": 8, "fps": 10.0},
	{"animation": "walk_up_right", "start": 48, "count": 8, "fps": 10.0},
	{"animation": "walk_right", "start": 40, "count": 8, "fps": 10.0},
	{"animation": "walk_down_right", "start": 32, "count": 8, "fps": 10.0},
	{"animation": "walk_down_default", "start": 24, "count": 8, "fps": 10.0},
]
const RUN_BASE_SLICES := [
	{"animation": "run_up", "start": 112, "count": 16, "fps": 14.0},
	{"animation": "run_up_right", "start": 96, "count": 16, "fps": 14.0},
	{"animation": "run_right", "start": 80, "count": 16, "fps": 14.0},
	{"animation": "run_down_right", "start": 64, "count": 16, "fps": 14.0},
	{"animation": "run_down", "start": 48, "count": 16, "fps": 14.0},
]
const LIGHT_ATTACK_BASE_SLICES := [
	{"animation": "melee_2h_fast_up", "start": 49, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_up_right", "start": 42, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_right", "start": 35, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_down_right", "start": 28, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_down", "start": 21, "count": 7, "fps": 12.0},
]

func _init() -> void:
	var body_frames := load(BODY_FRAMES_PATH) as SpriteFrames
	var weapon_frames := load(WEAPON_FRAMES_PATH) as SpriteFrames
	var melee_overlay_frames := load(MELEE_OVERLAY_FRAMES_PATH) as SpriteFrames

	if body_frames == null or weapon_frames == null or melee_overlay_frames == null:
		push_error("Failed to load one or more operator SpriteFrames resources.")
		quit(1)
		return

	# Base locomotion sheets are source masters. Only rebuild the runtime slices we actually consume.
	_replace_sheet_slices(body_frames, BASE_WALK_SHEET, WALK_BASE_SLICES, 96, 96)
	_replace_sheet_slices(body_frames, BASE_RUN_SHEET, RUN_BASE_SLICES, 96, 96)
	_replace_sheet_slices(body_frames, BASE_LIGHT_ATTACK_SHEET, LIGHT_ATTACK_BASE_SLICES, 96, 96)
	_replace_animation(body_frames, "melee_2h_fast_right", BASE_FAST_ATTACK_RIGHT_SHEET, 12, 0, 96, 128, 12.0, false)
	_replace_animation(body_frames, "melee_2h_heavy_anticipation", HEAVY_ANTICIPATION_SHEET, 5, 0, 96, 96, 11.0, false)
	_replace_animation(body_frames, "melee_2h_fast_1_right", FAST_ATTACK_1_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "melee_2h_fast_2_right", FAST_ATTACK_2_SHEET, 5, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "melee_2h_fast_recovery", FAST_RECOVERY_SHEET, 2, 0, 96, 96, 10.0, false)
	_replace_animation(body_frames, "death", BASE_DEATH_SHEET, 9, 0, 128, 128, 7.0, false)

	_replace_animation(weapon_frames, "equipped_run_right", RANGED_RUN_SHEET, 4, 1, 96, 96, 14.0, true)

	_replace_animation(melee_overlay_frames, "melee_2h_heavy_anticipation_weapon", HEAVY_ANTICIPATION_SHEET, 5, 1, 96, 96, 11.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_1_weapon", FAST_ATTACK_1_SHEET, 6, 1, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_1_fx", FAST_ATTACK_1_SHEET, 6, 2, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_2_weapon", FAST_ATTACK_2_SHEET, 5, 1, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_2_fx", FAST_ATTACK_2_SHEET, 5, 2, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_recovery_weapon", FAST_RECOVERY_SHEET, 2, 1, 96, 96, 10.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_recovery_fx", FAST_RECOVERY_SHEET, 2, 2, 96, 96, 10.0, false)

	ResourceSaver.save(body_frames, BODY_FRAMES_PATH)
	ResourceSaver.save(weapon_frames, WEAPON_FRAMES_PATH)
	ResourceSaver.save(melee_overlay_frames, MELEE_OVERLAY_FRAMES_PATH)
	quit()


func _replace_animation(
	sprite_frames: SpriteFrames,
	animation_name: String,
	texture_path: String,
	frame_count: int,
	row_index: int,
	frame_width: int,
	frame_height: int,
	speed: float,
	loop: bool
) -> void:
	if sprite_frames.has_animation(animation_name):
		sprite_frames.remove_animation(animation_name)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, speed)
	sprite_frames.set_animation_loop(animation_name, loop)

	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Missing texture for animation %s: %s" % [animation_name, texture_path])
		return

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * frame_width, row_index * frame_height, frame_width, frame_height)
		sprite_frames.add_frame(animation_name, atlas)


func _replace_animation_slice(
	sprite_frames: SpriteFrames,
	animation_name: String,
	texture_path: String,
	start_frame_index: int,
	frame_count: int,
	frame_width: int,
	frame_height: int,
	speed: float,
	loop: bool
) -> void:
	if sprite_frames.has_animation(animation_name):
		sprite_frames.remove_animation(animation_name)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, speed)
	sprite_frames.set_animation_loop(animation_name, loop)

	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Missing texture for animation %s: %s" % [animation_name, texture_path])
		return

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2((start_frame_index + frame_index) * frame_width, 0, frame_width, frame_height)
		sprite_frames.add_frame(animation_name, atlas)


func _replace_sheet_slices(
	sprite_frames: SpriteFrames,
	texture_path: String,
	slices: Array,
	frame_width: int,
	frame_height: int
) -> void:
	for slice_data in slices:
		if not (slice_data is Dictionary):
			continue
		_replace_animation_slice(
			sprite_frames,
			str(slice_data.get("animation", "")),
			texture_path,
			int(slice_data.get("start", 0)),
			int(slice_data.get("count", 0)),
			frame_width,
			frame_height,
			float(slice_data.get("fps", 10.0)),
			true
		)
