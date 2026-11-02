extends SceneTree

const HOVER_BUGGY_FRAMES_PATH := "res://game/actors/vehicles/hover_buggy_idle_frames.tres"
const HOVER_BUGGY_RUNTIME_DIR := "res://content/sprites/vehicles/hover_buggy/runtime"

const HOVER_BUGGY_IDLE_FALLBACKS := [
	"res://content/sprites/vehicles/hover_buggy/runtime/hover_buggy_idle.png",
	"res://content/sprites/vehicles/hover_buggy/hover_buggy_base.png",
]
const HOVER_BUGGY_IDLE_LOOP_FALLBACKS := [
	"res://content/sprites/vehicles/hover_buggy/runtime/hover_buggy_idle_hover_runtime.png",
	"res://content/sprites/vehicles/hover_buggy/runtime/hover_buggy_idle_hover_clean.png",
	"res://content/sprites/vehicles/hover_buggy/hover_buggy_base_float.png",
]
const HOVER_BUGGY_IDLE_START_FALLBACKS := [
	"res://content/sprites/vehicles/hover_buggy/hover_buggy_base.png",
]
const HOVER_BUGGY_MOVE_FALLBACKS := [
	"res://content/sprites/vehicles/hover_buggy/runtime/hover_buggy_move_horiz_clean.png",
	"res://content/sprites/vehicles/hover_buggy/hover_buggy_travel_south.png",
]

var _had_rebuild_error := false


func _init() -> void:
	var frames := load(HOVER_BUGGY_FRAMES_PATH) as SpriteFrames
	if frames == null:
		push_error("Failed to load hover buggy SpriteFrames: %s" % HOVER_BUGGY_FRAMES_PATH)
		quit(1)
		return

	_replace_hover_buggy_animation(frames, "idle", ["idle", "parked"], ["omni", "s"], HOVER_BUGGY_IDLE_FALLBACKS, 1.0, false)
	_replace_hover_buggy_animation(frames, "idle_start", ["idle_start", "takeoff"], ["omni", "s"], HOVER_BUGGY_IDLE_START_FALLBACKS, 8.0, false)
	_replace_hover_buggy_animation(frames, "idle_loop", ["idle_loop", "hover"], ["omni", "s"], HOVER_BUGGY_IDLE_LOOP_FALLBACKS, 5.5, true, true)
	_replace_hover_buggy_animation(frames, "move", ["move", "drive"], ["omni", "e", "w", "s", "n"], HOVER_BUGGY_MOVE_FALLBACKS, 8.0, true)

	if _had_rebuild_error:
		quit(1)
		return

	var save_error := ResourceSaver.save(frames, HOVER_BUGGY_FRAMES_PATH)
	if save_error != OK:
		push_error("Failed to save hover buggy SpriteFrames: %s" % error_string(save_error))
		quit(1)
		return

	print("Updated vehicle runtime resources.")
	quit()


func _replace_hover_buggy_animation(
	sprite_frames: SpriteFrames,
	animation_name: String,
	actions: Array[String],
	directions: Array[String],
	fallback_paths: Array,
	speed: float,
	loop: bool,
	ping_pong_fallback: bool = false
) -> void:
	var sheet_path := _find_hover_buggy_runtime_sheet(actions, directions)
	var use_ping_pong := false
	if sheet_path.is_empty():
		sheet_path = _first_existing_path(fallback_paths)
		use_ping_pong = ping_pong_fallback
	if sheet_path.is_empty():
		push_error("Missing hover buggy sheet for %s" % animation_name)
		_had_rebuild_error = true
		return

	_replace_strip_animation(sprite_frames, animation_name, sheet_path, speed, loop, use_ping_pong)


func _find_hover_buggy_runtime_sheet(actions: Array[String], directions: Array[String]) -> String:
	var runtime_path := ProjectSettings.globalize_path(HOVER_BUGGY_RUNTIME_DIR)
	var dir := DirAccess.open(runtime_path)
	if dir == null:
		return ""

	var files: Array[String] = []
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".png"):
			files.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	files.sort()

	var candidates: Array[Dictionary] = []
	for file_name in files:
		var stem := file_name.get_basename()
		var parts := stem.split("__")
		if parts.size() < 6:
			continue
		if parts[0] != "hover_buggy" or parts[1] != "body":
			continue
		var action := String(parts[2])
		var direction := String(parts[parts.size() - 3])
		var variant := "__".join(parts.slice(3, parts.size() - 3))
		if not actions.has(action) and not actions.has(variant):
			continue
		if not directions.is_empty() and not directions.has(direction):
			continue
		candidates.append({
			"path": HOVER_BUGGY_RUNTIME_DIR + "/" + file_name,
			"action": action,
			"variant": variant,
			"direction": direction,
		})

	for action_name in actions:
		for direction_name in directions:
			for candidate in candidates:
				var action_matches: bool = str(candidate["action"]) == action_name or str(candidate["variant"]) == action_name
				if action_matches and candidate["direction"] == direction_name:
					return str(candidate["path"])

	for action_name in actions:
		for candidate in candidates:
			var action_matches: bool = str(candidate["action"]) == action_name or str(candidate["variant"]) == action_name
			if action_matches:
				return str(candidate["path"])

	return ""


func _first_existing_path(paths: Array) -> String:
	for path_variant in paths:
		var path := str(path_variant)
		if _texture_file_exists(path):
			return path
	return ""


func _replace_strip_animation(
	sprite_frames: SpriteFrames,
	animation_name: String,
	texture_path: String,
	speed: float,
	loop: bool,
	use_ping_pong: bool = false
) -> void:
	var texture := _load_texture(texture_path)
	if texture == null:
		push_error("Missing texture for vehicle animation %s: %s" % [animation_name, texture_path])
		_had_rebuild_error = true
		return

	var frame_height := texture.get_height()
	var frame_width := frame_height
	if frame_width <= 0 or texture.get_width() < frame_width:
		push_error("Invalid vehicle strip dimensions for %s: %s" % [animation_name, texture_path])
		_had_rebuild_error = true
		return

	var frame_count := int(texture.get_width() / frame_width)
	if frame_count <= 0:
		push_error("Vehicle strip produced no frames for %s: %s" % [animation_name, texture_path])
		_had_rebuild_error = true
		return

	if sprite_frames.has_animation(animation_name):
		sprite_frames.remove_animation(animation_name)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, speed)
	sprite_frames.set_animation_loop(animation_name, loop)

	for frame_index in range(frame_count):
		_add_atlas_frame(sprite_frames, animation_name, texture, frame_index, frame_width, frame_height)

	if use_ping_pong and frame_count > 2:
		for frame_index in range(frame_count - 2, 0, -1):
			_add_atlas_frame(sprite_frames, animation_name, texture, frame_index, frame_width, frame_height)


func _add_atlas_frame(sprite_frames: SpriteFrames, animation_name: String, texture: Texture2D, frame_index: int, frame_width: int, frame_height: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(frame_index * frame_width, 0, frame_width, frame_height)
	sprite_frames.add_frame(animation_name, atlas)


func _load_texture(texture_path: String) -> Texture2D:
	if ResourceLoader.exists(texture_path):
		var resource_texture := load(texture_path) as Texture2D
		if resource_texture != null:
			return resource_texture
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(texture_path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _texture_file_exists(texture_path: String) -> bool:
	if ResourceLoader.exists(texture_path):
		return true
	return FileAccess.file_exists(ProjectSettings.globalize_path(texture_path))
