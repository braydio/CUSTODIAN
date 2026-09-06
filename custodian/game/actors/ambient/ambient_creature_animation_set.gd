extends Resource
class_name AmbientCreatureAnimationSet

## Layer-aware semantic clip table for ambient actors.
##
## Clips are identified by (layer, action, direction). Presentation layers own
## independent SpriteFrames so a body strip and a prop strip that share a
## semantic action never collide on the same animation name.

const DEFAULT_LAYER := &"body"

@export var set_id: StringName = &""
@export var default_frame_size := Vector2i(96, 96)
@export var clips: Array[Dictionary] = []
@export var aliases: Dictionary = {}

var _index: Dictionary = {}
var _frames_cache: Dictionary = {}
var _duplicate_warned: Dictionary = {}

## Clears the lazily built lookup index and cached SpriteFrames. Call after
## mutating `clips` outside of `_init`.
func refresh() -> void:
	_index.clear()
	_frames_cache.clear()
	_duplicate_warned.clear()

static func clip_layer(clip: Dictionary) -> StringName:
	return StringName(clip.get("layer", DEFAULT_LAYER))

func get_layers() -> Array[StringName]:
	_ensure_index()
	var result: Array[StringName] = []
	for layer in _index: result.append(StringName(layer))
	return result

func has_layer(layer: StringName) -> bool:
	_ensure_index()
	return _index.has(layer)

func resolve_clip(action: StringName, direction: StringName, variation_ordinal := 0, layer: StringName = DEFAULT_LAYER) -> Dictionary:
	_ensure_index()
	var by_action: Dictionary = _index.get(layer, {})
	var candidates: Array = by_action.get(action, [])
	if candidates.is_empty(): return {}
	for fallback in _direction_fallbacks(direction):
		var directional := candidates.filter(func(c: Dictionary) -> bool: return StringName(c.get("direction", &"omni")) == fallback)
		if not directional.is_empty():
			var selected: Dictionary = (directional[posmod(variation_ordinal, directional.size())] as Dictionary).duplicate()
			selected["mirrored"] = direction == &"w" and fallback == &"e"
			return selected
	var first := (candidates[0] as Dictionary).duplicate()
	first["mirrored"] = false
	return first

func get_clip_duration(action: StringName, direction: StringName, layer: StringName = DEFAULT_LAYER) -> float:
	var clip := resolve_clip(action, direction, 0, layer)
	return float(clip.get("frame_count", 0)) / float(clip.get("fps", 0.0)) if not clip.is_empty() and float(clip.get("fps", 0.0)) > 0.0 else 0.0

## Builds (and caches) the SpriteFrames for one presentation layer. Duplicate
## animation names inside a layer keep the first clip and warn once so a bad
## drop cannot silently reassign an authored action.
func build_sprite_frames(layer: StringName = DEFAULT_LAYER) -> SpriteFrames:
	if _frames_cache.has(layer): return _frames_cache[layer]
	var frames := SpriteFrames.new()
	for clip in clips:
		if clip_layer(clip) != layer: continue
		var path := String(clip.get("path", ""))
		if path.is_empty() or not ResourceLoader.exists(path): continue
		var texture := load(path) as Texture2D
		if texture == null: continue
		var size: Vector2i = clip.get("frame_size", default_frame_size)
		var count := texture.get_width() / maxi(1, size.x)
		if count <= 0: continue
		var name := StringName(clip.get("animation_name", "%s__%s" % [clip.get("action", "idle"), clip.get("direction", "s")]))
		if frames.has_animation(name):
			_warn_duplicate(layer, name, path)
			continue
		frames.add_animation(name)
		frames.set_animation_loop(name, bool(clip.get("loop", false)))
		frames.set_animation_speed(name, float(clip.get("fps", 8.0)))
		for index in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(index * size.x, 0, size.x, size.y)
			frames.add_frame(name, atlas)
	_frames_cache[layer] = frames
	return frames

func get_capabilities(layer: StringName = DEFAULT_LAYER) -> Dictionary:
	var result := {}
	for clip in clips:
		if clip_layer(clip) != layer: continue
		result[String(clip.get("action", ""))] = true
	return result

func get_clip_count(layer: StringName = DEFAULT_LAYER) -> int:
	var total := 0
	for clip in clips:
		if clip_layer(clip) == layer: total += 1
	return total

func _ensure_index() -> void:
	if not _index.is_empty(): return
	for value in clips:
		var clip := value as Dictionary
		if clip == null: continue
		var layer := clip_layer(clip)
		var action := StringName(clip.get("action", &""))
		if not _index.has(layer): _index[layer] = {}
		var by_action: Dictionary = _index[layer]
		if not by_action.has(action): by_action[action] = []
		(by_action[action] as Array).append(clip)
	for layer in _index:
		var by_action: Dictionary = _index[layer]
		for action in by_action:
			(by_action[action] as Array).sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("path", "")) < String(b.get("path", "")))

func _warn_duplicate(layer: StringName, name: StringName, path: String) -> void:
	var key := "%s/%s" % [String(layer), String(name)]
	if _duplicate_warned.has(key): return
	_duplicate_warned[key] = true
	push_warning("[AmbientCreatureAnimationSet] %s: duplicate animation '%s' on layer '%s'; ignoring %s" % [String(set_id), String(name), String(layer), path])

func _direction_fallbacks(direction: StringName) -> Array[StringName]:
	match direction:
		&"w": return [&"w", &"e", &"s", &"n", &"omni"]
		&"e": return [&"e", &"w", &"s", &"n", &"omni"]
		&"n": return [&"n", &"s", &"e", &"w", &"omni"]
		_: return [&"s", &"n", &"e", &"w", &"omni"]
