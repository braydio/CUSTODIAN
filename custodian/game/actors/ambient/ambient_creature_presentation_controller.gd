extends RefCounted
class_name AmbientCreaturePresentationController

const FALLBACKS := {
	"idle_alt":["idle"],"look":["idle"],"sniff":["look","idle"],"waddle":["idle"],"scurry":["waddle","idle"],"sit_enter":["sit_idle","idle"],"sit_idle":["idle"],"sit_exit":["idle"],
	"alert":["startle","look","idle"],"startle":["alert","idle"],"freeze":["idle"],"hiss":["alert","startle","idle"],"panic":["startle","scurry","waddle","idle"],"flee_start":["startle","scurry","waddle","idle"],
	"play_dead_enter":["freeze","idle"],"play_dead_hold":["freeze","idle"],"play_dead_peek":["look","idle"],"play_dead_exit":["idle"],"hide_enter":["scurry","idle"],"hide_hold":["idle"],"hide_peek":["look","idle"],"hide_exit":["idle"],
	"reject_hit":["startle","idle"],"disapprove":["look","idle"],"disapprove_hold":["disapprove","look","idle"],"notice_treat":["alert","look","idle"],"approach_wary":["waddle","idle"],"sniff_treat":["sniff","look","idle"],"take_treat":["eat","idle"],"eat":["idle"],"friend_happy":["greet","look","idle"],"greet":["friend_happy","look","idle"],"approach_player":["waddle","idle"],"follow":["waddle","idle"],"wait":["idle"],
	"search":["sniff","look","idle"],"dig":["search","sniff","idle"],"find_target":["alert","look","idle"],"look_back":["look","idle"],"excited_idle":["friend_happy","idle"],"danger_sense":["alert","freeze","idle"],"retrieve":["waddle","idle"],"gift_drop":["idle"]
}

var animation_set: AmbientCreatureAnimationSet
var body_sprite: AnimatedSprite2D
var current_action: StringName = &""
var _missing_reported := {}

func setup(set_resource: AmbientCreatureAnimationSet, body: AnimatedSprite2D) -> void:
	animation_set = set_resource
	body_sprite = body
	if body_sprite != null and animation_set != null: body_sprite.sprite_frames = animation_set.build_sprite_frames()

func play_action(action: StringName, direction := Vector2.DOWN, restart := false) -> bool:
	var resolved := _resolve(action, _direction_suffix(direction))
	if resolved.is_empty() or body_sprite == null: return false
	var name := StringName(resolved.get("animation_name", ""))
	if not body_sprite.sprite_frames.has_animation(name): return false
	body_sprite.flip_h = bool(resolved.get("mirrored", false))
	current_action = StringName(resolved.get("resolved_action", action))
	if restart or body_sprite.animation != name: body_sprite.play(name)
	return true

func has_action(action: StringName, direction := Vector2.DOWN) -> bool: return not _resolve(action, _direction_suffix(direction)).is_empty()
func get_action_duration(action: StringName, direction := Vector2.DOWN) -> float:
	var resolved := _resolve(action, _direction_suffix(direction))
	return float(resolved.get("frame_count", 0)) / float(resolved.get("fps", 0.0)) if not resolved.is_empty() and float(resolved.get("fps", 0.0)) > 0.0 else 0.0
func get_animation_capabilities() -> Dictionary:
	var capabilities := animation_set.get_capabilities() if animation_set != null else {}
	var aliases: Dictionary = animation_set.aliases if animation_set != null else {}
	for alias in aliases:
		capabilities[alias] = has_action(StringName(alias))
	return capabilities
func get_missing_animation_actions() -> Array[StringName]:
	var missing: Array[StringName] = []
	for action in FALLBACKS:
		if not has_action(StringName(action)): missing.append(StringName(action))
	return missing

func _resolve(action: StringName, direction: StringName) -> Dictionary:
	if animation_set == null: return {}
	var queue: Array[StringName] = [action]
	var visited := {}
	while not queue.is_empty():
		var candidate: StringName = queue.pop_front()
		if visited.has(candidate): continue
		visited[candidate] = true
		var clip := animation_set.resolve_clip(candidate, direction)
		if not clip.is_empty():
			clip["resolved_action"] = candidate
			return clip
		var aliases: Dictionary = animation_set.aliases
		if aliases.has(String(candidate)):
			queue.append(StringName(aliases[String(candidate)]))
		for fallback in FALLBACKS.get(String(candidate), []): queue.append(StringName(fallback))
	return {}

func _direction_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001: return &"s"
	if absf(direction.x) > absf(direction.y): return &"e" if direction.x > 0.0 else &"w"
	return &"s" if direction.y > 0.0 else &"n"
