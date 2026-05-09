extends RefCounted
class_name WolfAnimationLibrary

const WOLF_FRAME_SIZE := 64
const WOLF_DIRECTION_ROWS := {
	"south": 0,
	"west": 1,
	"east": 2,
	"north": 3,
}

const ANIMATION_SPECS := {
	"idle": {"path": "res://content/sprites/enemies/wolf/wolf-idle.png", "fps": 6.0, "loop": true},
	"run": {"path": "res://content/sprites/enemies/wolf/wolf-run.png", "fps": 10.0, "loop": true},
	"bite": {"path": "res://content/sprites/enemies/wolf/wolf-bite.png", "fps": 12.0, "loop": false},
	"death": {"path": "res://content/sprites/enemies/wolf/wolf-death.png", "fps": 10.0, "loop": false},
	"howl": {"path": "res://content/sprites/enemies/wolf/wolf-howl.png", "fps": 8.0, "loop": false},
}

static var _cached_frames: SpriteFrames = null


static func get_wolf_sprite_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames
	var frames := SpriteFrames.new()
	for animation_key in ANIMATION_SPECS.keys():
		for direction_name in WOLF_DIRECTION_ROWS.keys():
			_add_sheet_row_animation(
				frames,
				"%s_%s" % [String(animation_key), String(direction_name)],
				ANIMATION_SPECS[animation_key],
				int(WOLF_DIRECTION_ROWS[direction_name])
			)
	_add_legacy_aliases(frames)
	_cached_frames = frames
	return _cached_frames


static func _add_sheet_row_animation(frames: SpriteFrames, animation_name: String, spec: Dictionary, row_index: int) -> void:
	var path := String(spec["path"])
	if not ResourceLoader.exists(path):
		push_warning("[WolfAnimationLibrary] Missing wolf sheet: %s" % path)
		return
	var texture := load(path)
	if not (texture is Texture2D):
		push_warning("[WolfAnimationLibrary] Wolf sheet is not a Texture2D: %s" % path)
		return
	var tex := texture as Texture2D
	var frame_size := WOLF_FRAME_SIZE
	var cols := int(tex.get_width() / frame_size)
	var rows := int(tex.get_height() / frame_size)
	if cols <= 0 or rows <= row_index:
		push_warning("[WolfAnimationLibrary] Wolf sheet has unexpected dimensions: %s" % path)
		return
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, bool(spec.get("loop", true)))
	frames.set_animation_speed(animation_name, float(spec.get("fps", 8.0)))
	for col in range(cols):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float(col * frame_size), float(row_index * frame_size), float(frame_size), float(frame_size))
		frames.add_frame(animation_name, atlas)


static func _add_legacy_aliases(frames: SpriteFrames) -> void:
	_copy_animation(frames, "idle_east", "idle_east")
	_copy_animation(frames, "run_east", "run_east")
	_copy_animation(frames, "bite_east", "bite_east")
	_copy_animation(frames, "death_east", "death_east")
	_copy_animation(frames, "howl_east", "howl_east")


static func _copy_animation(frames: SpriteFrames, source_name: String, target_name: String) -> void:
	if not frames.has_animation(source_name):
		return
	if frames.has_animation(target_name):
		return
	frames.add_animation(target_name)
	frames.set_animation_loop(target_name, frames.get_animation_loop(source_name))
	frames.set_animation_speed(target_name, frames.get_animation_speed(source_name))
	for frame_index in range(frames.get_frame_count(source_name)):
		frames.add_frame(target_name, frames.get_frame_texture(source_name, frame_index), frames.get_frame_duration(source_name, frame_index))
