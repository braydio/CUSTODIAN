extends SceneTree

const BODY_FRAMES_PATH := "res://entities/operator/operator_runtime_frames.tres"
const WEAPON_FRAMES_PATH := "res://entities/operator/operator_weapon_frames.tres"
const MELEE_OVERLAY_FRAMES_PATH := "res://entities/operator/operator_melee_overlay_frames.tres"

const RANGED_RUN_SHEET := "res://assets/sprites/operator/runtime/curated/body/ranged_2h/equipped_run_right_body.png"
const HEAVY_ANTICIPATION_SHEET := "res://assets/sprites/operator/runtime/curated/body/melee_2h/heavy_anticipation_body.png"
const FAST_ATTACK_1_SHEET := "res://assets/sprites/operator/runtime/curated/body/melee_2h/fast_attack_1_right_body.png"
const FAST_ATTACK_2_SHEET := "res://assets/sprites/operator/runtime/curated/body/melee_2h/fast_attack_2_right_body.png"
const FAST_RECOVERY_SHEET := "res://assets/sprites/operator/runtime/curated/body/melee_2h/fast_recovery_body.png"

func _init() -> void:
	var body_frames := load(BODY_FRAMES_PATH) as SpriteFrames
	var weapon_frames := load(WEAPON_FRAMES_PATH) as SpriteFrames
	var melee_overlay_frames := load(MELEE_OVERLAY_FRAMES_PATH) as SpriteFrames

	if body_frames == null or weapon_frames == null or melee_overlay_frames == null:
		push_error("Failed to load one or more operator SpriteFrames resources.")
		quit(1)
		return

	_replace_animation(body_frames, "run_right", RANGED_RUN_SHEET, 4, 0, 96, 96, 14.0, true)
	_replace_animation(body_frames, "melee_2h_heavy_anticipation", HEAVY_ANTICIPATION_SHEET, 5, 0, 96, 96, 11.0, false)
	_replace_animation(body_frames, "melee_2h_fast_1_right", FAST_ATTACK_1_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "melee_2h_fast_2_right", FAST_ATTACK_2_SHEET, 5, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "melee_2h_fast_recovery", FAST_RECOVERY_SHEET, 2, 0, 96, 96, 10.0, false)

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
