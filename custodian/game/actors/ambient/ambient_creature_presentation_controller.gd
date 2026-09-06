extends RefCounted
class_name AmbientCreaturePresentationController

## Cycle-safe semantic action resolver for ambient actors.
##
## The controller owns one body layer plus any number of synchronized prop
## layers. A prop layer never participates in the semantic fallback chain: it
## either has a clip authored for the body's *resolved* action or it hides, so
## a prop can never stand in for a body state it was not drawn for.

const BODY_LAYER := &"body"

const FALLBACKS := {
	"idle_alt":["idle"],"look":["idle"],"sniff":["look","idle"],"waddle":["idle"],"scurry":["waddle","idle"],"sit_enter":["sit_idle","idle"],"sit_idle":["idle"],"sit_exit":["idle"],
	"alert":["startle","look","idle"],"startle":["alert","idle"],"freeze":["idle"],"hiss":["alert","startle","idle"],"panic":["startle","scurry","waddle","idle"],"flee_start":["startle","scurry","waddle","idle"],
	"play_dead_enter":["freeze","idle"],"play_dead_hold":["freeze","idle"],"play_dead_peek":["look","idle"],"play_dead_exit":["idle"],"hide_enter":["scurry","idle"],"hide_hold":["idle"],"hide_peek":["look","idle"],"hide_exit":["idle"],
	"reject_hit":["startle","idle"],"disapprove":["look","idle"],"disapprove_hold":["disapprove","look","idle"],"notice_treat":["alert","look","idle"],"approach_wary":["waddle","idle"],"sniff_treat":["sniff","look","idle"],"take_treat":["eat","idle"],"eat":["idle"],"friend_happy":["greet","look","idle"],"greet":["friend_happy","look","idle"],"approach_player":["waddle","idle"],"follow":["waddle","idle"],"wait":["idle"],
	"search":["sniff","look","idle"],"dig":["search","sniff","idle"],"find_target":["alert","look","idle"],"look_back":["look","idle"],"excited_idle":["friend_happy","idle"],"danger_sense":["alert","freeze","idle"],"retrieve":["waddle","idle"],"gift_drop":["idle"]
}

var animation_set: AmbientCreatureAnimationSet
var body_sprite: AnimatedSprite2D
var layer_sprites: Dictionary = {}
var current_action: StringName = &""
var _resolve_cache: Dictionary = {}

## `extra_layers` maps a non-body layer name to the AnimatedSprite2D that renders
## it, e.g. {&"barrel_prop": $HideProp}.
func setup(set_resource: AmbientCreatureAnimationSet, body: AnimatedSprite2D, extra_layers: Dictionary = {}) -> void:
	animation_set = set_resource
	body_sprite = body
	current_action = &""
	_resolve_cache.clear()
	layer_sprites.clear()
	if body != null: layer_sprites[BODY_LAYER] = body
	for layer in extra_layers:
		var sprite := extra_layers[layer] as AnimatedSprite2D
		if sprite != null: layer_sprites[StringName(layer)] = sprite
	if animation_set == null: return
	for layer in layer_sprites:
		var sprite: AnimatedSprite2D = layer_sprites[layer]
		sprite.sprite_frames = animation_set.build_sprite_frames(StringName(layer))
		if layer != BODY_LAYER: sprite.visible = false

func play_action(action: StringName, direction := Vector2.DOWN, restart := false) -> bool:
	var suffix := _direction_suffix(direction)
	var resolved := _resolve(action, suffix)
	if resolved.is_empty() or body_sprite == null or body_sprite.sprite_frames == null:
		_sync_prop_layers(&"", suffix, restart)
		return false
	var name := StringName(resolved.get("animation_name", ""))
	if not body_sprite.sprite_frames.has_animation(name):
		_sync_prop_layers(&"", suffix, restart)
		return false
	body_sprite.flip_h = bool(resolved.get("mirrored", false))
	current_action = StringName(resolved.get("resolved_action", action))
	_play_on(body_sprite, name, restart)
	_sync_prop_layers(current_action, suffix, restart)
	return true

func has_action(action: StringName, direction := Vector2.DOWN) -> bool:
	return not _resolve(action, _direction_suffix(direction)).is_empty()

func get_action_duration(action: StringName, direction := Vector2.DOWN) -> float:
	var resolved := _resolve(action, _direction_suffix(direction))
	return float(resolved.get("frame_count", 0)) / float(resolved.get("fps", 0.0)) if not resolved.is_empty() and float(resolved.get("fps", 0.0)) > 0.0 else 0.0

## True when `layer` has a clip authored for the semantic action the body layer
## would resolve `action` to.
func has_layer_action(layer: StringName, action: StringName, direction := Vector2.DOWN) -> bool:
	if animation_set == null: return false
	var suffix := _direction_suffix(direction)
	var resolved := _resolve(action, suffix)
	var target := StringName(resolved.get("resolved_action", action)) if not resolved.is_empty() else action
	return not animation_set.resolve_clip(target, suffix, 0, layer).is_empty()

func get_animation_capabilities() -> Dictionary:
	var capabilities := animation_set.get_capabilities() if animation_set != null else {}
	var alias_map: Dictionary = animation_set.aliases if animation_set != null else {}
	for alias in alias_map:
		capabilities[alias] = has_action(StringName(alias))
	return capabilities

func get_missing_animation_actions() -> Array[StringName]:
	var missing: Array[StringName] = []
	for action in FALLBACKS:
		if not has_action(StringName(action)): missing.append(StringName(action))
	return missing

func _sync_prop_layers(resolved_action: StringName, suffix: StringName, restart: bool) -> void:
	for layer in layer_sprites:
		if layer == BODY_LAYER: continue
		var sprite: AnimatedSprite2D = layer_sprites[layer]
		if sprite == null: continue
		var clip := animation_set.resolve_clip(resolved_action, suffix, 0, StringName(layer)) if animation_set != null and resolved_action != &"" else {}
		var name := StringName(clip.get("animation_name", "")) if not clip.is_empty() else &""
		if name == &"" or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(name):
			sprite.visible = false
			sprite.stop()
			continue
		sprite.visible = true
		sprite.flip_h = bool(clip.get("mirrored", false))
		_play_on(sprite, name, restart)

func _play_on(sprite: AnimatedSprite2D, name: StringName, restart: bool) -> void:
	if restart or sprite.animation != name or not sprite.is_playing():
		sprite.play(name)
		if restart: sprite.set_frame_and_progress(0, 0.0)

func _resolve(action: StringName, direction: StringName) -> Dictionary:
	if animation_set == null: return {}
	var cache_key := "%s|%s" % [String(action), String(direction)]
	if _resolve_cache.has(cache_key): return _resolve_cache[cache_key]
	var resolved := {}
	var queue: Array[StringName] = [action]
	var visited := {}
	while not queue.is_empty():
		var candidate: StringName = queue.pop_front()
		if visited.has(candidate): continue
		visited[candidate] = true
		var clip := animation_set.resolve_clip(candidate, direction, 0, AmbientCreatureAnimationSet.DEFAULT_LAYER)
		if not clip.is_empty():
			clip["resolved_action"] = candidate
			resolved = clip
			break
		var alias_map: Dictionary = animation_set.aliases
		if alias_map.has(String(candidate)):
			queue.append(StringName(alias_map[String(candidate)]))
		for fallback in FALLBACKS.get(String(candidate), []): queue.append(StringName(fallback))
	_resolve_cache[cache_key] = resolved
	return resolved

func _direction_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001: return &"s"
	if absf(direction.x) > absf(direction.y): return &"e" if direction.x > 0.0 else &"w"
	return &"s" if direction.y > 0.0 else &"n"
