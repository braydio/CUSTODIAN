extends Resource
class_name AmbientCreatureAnimationSet

@export var set_id: StringName = &""
@export var default_frame_size := Vector2i(96, 96)
@export var clips: Array[Dictionary] = []
@export var aliases: Dictionary = {}

func resolve_clip(action: StringName, direction: StringName, variation_ordinal := 0) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for value in clips:
		var clip := value as Dictionary
		if StringName(clip.get("action", &"")) == action:
			candidates.append(clip)
	if candidates.is_empty(): return {}
	for fallback in _direction_fallbacks(direction):
		var directional := candidates.filter(func(c: Dictionary) -> bool: return StringName(c.get("direction", &"omni")) == fallback)
		if not directional.is_empty():
			directional.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("path", "")) < String(b.get("path", "")))
			var selected: Dictionary = directional[posmod(variation_ordinal, directional.size())].duplicate()
			selected["mirrored"] = direction == &"w" and fallback == &"e"
			return selected
	return candidates[0]

func get_clip_duration(action: StringName, direction: StringName) -> float:
	var clip := resolve_clip(action, direction)
	return float(clip.get("frame_count", 0)) / float(clip.get("fps", 0.0)) if not clip.is_empty() and float(clip.get("fps", 0.0)) > 0.0 else 0.0

func build_sprite_frames(_layer: StringName = &"body") -> SpriteFrames:
	var frames := SpriteFrames.new()
	for clip in clips:
		var path := String(clip.get("path", ""))
		if path.is_empty() or not ResourceLoader.exists(path): continue
		var texture := load(path) as Texture2D
		if texture == null: continue
		var size: Vector2i = clip.get("frame_size", default_frame_size)
		var count := texture.get_width() / maxi(1, size.x)
		if count <= 0: continue
		var name := StringName(clip.get("animation_name", "%s__%s" % [clip.get("action", "idle"), clip.get("direction", "s")]))
		frames.add_animation(name)
		frames.set_animation_loop(name, bool(clip.get("loop", false)))
		frames.set_animation_speed(name, float(clip.get("fps", 8.0)))
		for index in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(index * size.x, 0, size.x, size.y)
			frames.add_frame(name, atlas)
	return frames

func get_capabilities() -> Dictionary:
	var result := {}
	for clip in clips: result[String(clip.get("action", ""))] = true
	return result

func _direction_fallbacks(direction: StringName) -> Array[StringName]:
	match direction:
		&"w": return [&"w", &"e", &"s", &"n", &"omni"]
		&"e": return [&"e", &"w", &"s", &"n", &"omni"]
		&"n": return [&"n", &"s", &"e", &"w", &"omni"]
		_: return [&"s", &"n", &"e", &"w", &"omni"]
