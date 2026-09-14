extends SceneTree
## Migration gate: canonicalizing a renderer must not retime it.
##
## A compatibility SpriteFrames carries hand-authored FPS, loop and per-frame
## durations. The canonical builder falls back to 12 FPS and a loop heuristic
## when the source art has no `.animation.json` sidecar, so a cutover can
## silently change cadence while pixels and frame counts stay identical. That is
## exactly how C2a-R1 retimed the sidearm ranged stance (8 -> 12) and C2a-R2
## retimed the field-patch FX (11.2 -> 12) without any smoke noticing.
##
## This compares every compatibility clip against the canonical identity its
## consumer resolves to after cutover, and fails on any timing drift. It retires
## with the compatibility resources in C2b.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const CANONICAL := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"
const RESOURCES := {
	"modular_lower_body_sprite": "res://game/actors/operator/operator_modular_lower_body_frames.tres",
	"modular_upper_body_sprite": "res://game/actors/operator/operator_modular_upper_body_frames.tres",
	"modular_sidearm_sprite": "res://game/actors/operator/operator_modular_sidearm_frames.tres",
	"modular_upper_fx_sprite": "res://game/actors/operator/operator_modular_upper_fx_frames.tres",
}

## Clips whose pixels were published against the wrong action. C2a-R3 repoints
## the consumer at the correct canonical art, and the consumer's authored clock
## follows it. A pixel correction is not permission to change the clock.
const CROSS_ACTION_CORRECTIONS := {
	"modular_lower_body_sprite/unarmed_walk_up_right": "unarmed/locomotion/walk_01/ne",
	"modular_lower_body_sprite/unarmed_walk_up_left": "unarmed/locomotion/walk_01/nw",
	"modular_lower_body_sprite/unarmed_run_up_right": "unarmed/locomotion/run_01/ne",
	"modular_lower_body_sprite/unarmed_fast_windup_lower_up": "unarmed/attack/fast_windup_01/n",
}

## Playback paths that explicitly renormalize speed, so the resource FPS never
## reaches the screen: `_play_first_available_modular_fire_animation()` sets
## `speed_scale = target_fps / source_speed`, and the ranged aim path derives FPS
## from frame count over a tuned duration.
const RUNTIME_NORMALIZED := [
	"ranged_2h/cosmetic/fire_01/",
	"ranged_2h/cosmetic/aim_01/",
]

var _failures: int = 0
var _checked: int = 0
var _skipped_unpublished: int = 0


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _identity(sprite_frames: SpriteFrames, renderer: String, clip: StringName) -> String:
	var texture := sprite_frames.get_frame_texture(clip, 0)
	var atlas := texture as AtlasTexture
	if atlas == null or atlas.atlas == null:
		return ""
	var parts := atlas.atlas.resource_path.get_file().replace(".png", "").split("__")
	if parts.size() < 6:
		return ""
	var corrected: String = CROSS_ACTION_CORRECTIONS.get("%s/%s" % [renderer, clip], "")
	var identity := corrected if not corrected.is_empty() \
		else "%s/%s/%s/%s" % [parts[2], parts[3], parts[4], parts[5]]
	return "%s/%s" % [identity, parts[1]]


func _init() -> void:
	var canonical: SpriteFrames = load(CANONICAL)
	if canonical == null:
		_fail("canonical runtime SpriteFrames missing")
		quit(1)
		return

	for renderer in RESOURCES:
		var sprite_frames: SpriteFrames = load(RESOURCES[renderer])
		if sprite_frames == null:
			_fail("missing compatibility resource for %s" % renderer)
			continue
		for name in sprite_frames.get_animation_names():
			var clip := StringName(name)
			var frame_count := sprite_frames.get_frame_count(clip)
			if frame_count == 0:
				continue
			var identity := _identity(sprite_frames, renderer, clip)
			if identity.is_empty() or identity.find("legacy") != -1:
				continue
			var normalized := false
			for prefix in RUNTIME_NORMALIZED:
				if identity.begins_with(prefix):
					normalized = true
					break
			if normalized:
				continue
			var canonical_name := StringName(identity)
			if not canonical.has_animation(canonical_name):
				_skipped_unpublished += 1
				continue
			if canonical.get_frame_count(canonical_name) != frame_count:
				continue
			_checked += 1
			var want_fps := sprite_frames.get_animation_speed(clip)
			var got_fps := canonical.get_animation_speed(canonical_name)
			if not is_equal_approx(want_fps, got_fps):
				_fail("timing drift %s (via %s/%s): authored %.3f fps, canonical %.3f fps" % [
					identity, renderer, clip, want_fps, got_fps])
			var want_loop := sprite_frames.get_animation_loop(clip)
			var got_loop := canonical.get_animation_loop(canonical_name)
			if want_loop != got_loop:
				_fail("loop drift %s (via %s/%s): authored %s, canonical %s" % [
					identity, renderer, clip, want_loop, got_loop])
			for index in frame_count:
				var want_duration := sprite_frames.get_frame_duration(clip, index)
				var got_duration := canonical.get_frame_duration(canonical_name, index)
				if not is_equal_approx(want_duration, got_duration):
					_fail("duration drift %s frame %d (via %s/%s): authored %.4f, canonical %.4f" % [
						identity, index, renderer, clip, want_duration, got_duration])

	if _failures > 0:
		push_error("operator_timing_preservation_smoke failed")
		quit(1)
		return
	print("operator timing preservation smoke passed (%d identities checked, %d unpublished skipped)" % [
		_checked, _skipped_unpublished])
	quit()
