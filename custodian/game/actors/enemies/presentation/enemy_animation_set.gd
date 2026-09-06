extends Resource
class_name EnemyAnimationSet

@export var set_id: StringName = &""
@export var default_frame_size := Vector2i(96, 96)
@export var clips: Array[Dictionary] = []

var _sprite_frames_cache: Dictionary = {}
var _build_collisions: Dictionary = {}
var collision_errors_enabled := true


func resolve_clip(action: StringName, direction: StringName, variation_ordinal: int = 0) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for clip_variant in clips:
		var clip := clip_variant as Dictionary
		if StringName(clip.get("action", &"")) == action:
			candidates.append(clip)
	if candidates.is_empty():
		return {}
	var directions := _direction_fallbacks(direction)
	for fallback_direction in directions:
		var directional: Array[Dictionary] = []
		for clip in candidates:
			if StringName(clip.get("direction", &"omni")) == fallback_direction:
				directional.append(clip)
		if not directional.is_empty():
			directional.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return String(a.get("variant", "")) < String(b.get("variant", ""))
			)
			return directional[posmod(variation_ordinal, directional.size())]
	return candidates[0]


func get_clip_duration(action: StringName, direction: StringName, variation_ordinal: int = 0) -> float:
	var clip := resolve_clip(action, direction, variation_ordinal)
	if clip.is_empty():
		return 0.0
	var frame_count := int(clip.get("frame_count", 0))
	var fps := float(clip.get("fps", 0.0))
	if frame_count <= 0 or fps <= 0.0:
		return 0.0
	return float(frame_count) / fps


func build_sprite_frames(layer: StringName) -> SpriteFrames:
	if _sprite_frames_cache.has(layer):
		return _sprite_frames_cache[layer] as SpriteFrames
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	var signatures: Dictionary = {}
	var collisions: Array[Dictionary] = []
	for clip_variant in clips:
		var clip := clip_variant as Dictionary
		var path := String(clip.get("%s_path" % String(layer), ""))
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		var frame_size: Vector2i = clip.get("frame_size", default_frame_size)
		var frame_count := texture.get_width() / maxi(1, frame_size.x)
		if frame_count <= 0 or texture.get_height() < frame_size.y:
			continue
		var animation_name := get_animation_name(clip, layer)
		var signature := {
			"source_path": path,
			"frame_size": frame_size,
			"frame_count": frame_count,
			"fps": float(clip.get("fps", 8.0)),
			"loop": bool(clip.get("loop", false)),
		}
		if signatures.has(animation_name):
			var existing := signatures[animation_name] as Dictionary
			if existing == signature:
				continue
			var collision := {
				"set_id": set_id,
				"layer": layer,
				"animation_name": animation_name,
				"old_signature": existing.duplicate(true),
				"new_signature": signature.duplicate(true),
			}
			collisions.append(collision)
			if collision_errors_enabled:
				push_error(
					"[EnemyAnimationSet] animation collision set_id=%s layer=%s name=%s old=%s new=%s"
					% [String(set_id), String(layer), String(animation_name), str(existing), str(signature)]
				)
			continue
		signatures[animation_name] = signature
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, bool(clip.get("loop", false)))
		frames.set_animation_speed(animation_name, float(clip.get("fps", 8.0)))
		for frame_index in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
			frames.add_frame(animation_name, atlas)
	_sprite_frames_cache[layer] = frames
	_build_collisions[layer] = collisions
	return frames


func invalidate_sprite_frames_cache() -> void:
	_sprite_frames_cache.clear()
	_build_collisions.clear()


func get_build_collisions(layer: StringName) -> Array[Dictionary]:
	return (_build_collisions.get(layer, []) as Array).duplicate(true)


func get_animation_name(clip: Dictionary, layer: StringName = &"body") -> StringName:
	var explicit_name := StringName(clip.get("%s_name" % String(layer), &""))
	if not explicit_name.is_empty():
		return explicit_name
	return StringName("%s__%s__%s" % [
		String(clip.get("action", &"missing")).replace(".", "_"),
		String(clip.get("variant", &"default")),
		String(clip.get("direction", &"omni")),
	])


func _direction_fallbacks(direction: StringName) -> Array[StringName]:
	match direction:
		&"n", &"ne", &"nw":
			return [direction, &"e", &"w", &"s", &"omni"]
		&"s", &"se", &"sw":
			return [direction, &"e", &"w", &"s", &"omni"]
		&"w":
			return [&"w", &"e", &"s", &"omni"]
		_:
			return [&"e", &"w", &"s", &"omni"]
