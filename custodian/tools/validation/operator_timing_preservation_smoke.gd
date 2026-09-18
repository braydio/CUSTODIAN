extends SceneTree
## Migration gate: canonicalizing a renderer must not retime it.
##
## A renderer cutover swaps a compatibility SpriteFrames, which carries
## hand-authored FPS, loop and per-frame durations, for the generated canonical
## resource. The builder falls back to 12 FPS and a loop heuristic when the
## source art has no `.animation.json` sidecar, so a cutover can silently change
## cadence while pixels and frame counts stay identical. That is how C2a-R1
## retimed the sidearm ranged stance (8 -> 12) and C2a-R2 the field-patch FX
## (11.2 -> 12) with every smoke still green.
##
## The authored side is read from the FROZEN baseline, not from the live
## compatibility resources. Those `.tres` files are generated machinery that
## `update_operator_compatibility_resources.py` refreshes from canonical assets,
## so reading them here would be circular: an ingest can rewrite the "historical"
## values to match whatever canonical currently says, and the gate would approve
## its own drift. That is not hypothetical -- an inbox ingest did exactly this to
## three cross-action clips.
##
## Retires with the compatibility resources in C2b.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const CANONICAL := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"
const BASELINE := "res://../reports/operator/operator_compatibility_timing.json"
const BASELINE_SCHEMA := "custodian.operator_compatibility_timing.v1"
## C2a-T1 deliberately left `full_body` to the animated_sprite slice, so C2a-R4
## captured it separately. Two baselines with independent provenance, rather than
## one file pretending the original capture was always comprehensive.
const FULL_BODY_BASELINE := "res://../reports/operator/operator_full_body_compatibility_timing.json"
const FULL_BODY_SCHEMA := "custodian.operator_full_body_timing.v1"

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
var _unpreservable: int = 0


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _identity(renderer: String, clip: String, art: Dictionary) -> String:
	if art.is_empty():
		return ""
	var corrected: String = CROSS_ACTION_CORRECTIONS.get("%s/%s" % [renderer, clip], "")
	var identity := corrected if not corrected.is_empty() else "%s/%s/%s/%s" % [
		art.get("profile", ""), art.get("group", ""), art.get("action", ""), art.get("direction", "")]
	return "%s/%s" % [identity, art.get("layer", "")]


func _init() -> void:
	var canonical: SpriteFrames = load(CANONICAL)
	if canonical == null:
		_fail("canonical runtime SpriteFrames missing")
		quit(1)
		return

	var raw := FileAccess.get_file_as_string(BASELINE)
	if raw.is_empty():
		_fail("frozen authored-timing baseline missing: %s" % BASELINE)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		_fail("frozen baseline is not a JSON object: %s" % BASELINE)
		quit(1)
		return
	var baseline: Dictionary = parsed
	if String(baseline.get("schema", "")) != BASELINE_SCHEMA:
		_fail("unexpected baseline schema %s" % baseline.get("schema"))
		quit(1)
		return
	if not bool(baseline.get("frozen", false)):
		_fail("baseline is not marked frozen; it must be captured evidence, not a live dump")
		quit(1)
		return

	var resources: Dictionary = baseline.get("resources", {})
	for renderer in resources:
		var clips: Dictionary = (resources[renderer] as Dictionary).get("clips", {})
		for clip in clips:
			var authored: Dictionary = clips[clip]
			var frame_count := int(authored.get("frames", 0))
			if frame_count == 0:
				continue
			var identity := _identity(String(renderer), String(clip), authored.get("art", {}))
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
			var want_fps := float(authored.get("fps", 0.0))
			var got_fps := canonical.get_animation_speed(canonical_name)
			if not is_equal_approx(want_fps, got_fps):
				_fail("timing drift %s (via %s/%s): authored %.3f fps, canonical %.3f fps" % [
					identity, renderer, clip, want_fps, got_fps])
			var want_loop := bool(authored.get("loop", false))
			var got_loop := canonical.get_animation_loop(canonical_name)
			if want_loop != got_loop:
				_fail("loop drift %s (via %s/%s): authored %s, canonical %s" % [
					identity, renderer, clip, want_loop, got_loop])
			var durations: Array = authored.get("durations", [])
			for index in frame_count:
				if index >= durations.size():
					break
				var want_duration := float(durations[index])
				var got_duration := canonical.get_frame_duration(canonical_name, index)
				if not is_equal_approx(want_duration, got_duration):
					_fail("duration drift %s frame %d (via %s/%s): authored %.4f, canonical %.4f" % [
						identity, index, renderer, clip, want_duration, got_duration])

	_check_full_body(canonical)

	if _failures > 0:
		push_error("operator_timing_preservation_smoke failed")
		quit(1)
		return
	print("operator timing preservation smoke passed (%d identities checked, %d unpublished skipped, %d recorded unpreservable)" % [
		_checked, _skipped_unpublished, _unpreservable])
	quit()


## The authored full-body clock, compared against the live canonical resource.
func _check_full_body(canonical: SpriteFrames) -> void:
	var raw := FileAccess.get_file_as_string(FULL_BODY_BASELINE)
	if raw.is_empty():
		_fail("frozen full-body timing baseline missing: %s" % FULL_BODY_BASELINE)
		return
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		_fail("full-body baseline is not a JSON object")
		return
	var baseline: Dictionary = parsed
	if String(baseline.get("schema", "")) != FULL_BODY_SCHEMA:
		_fail("unexpected full-body baseline schema %s" % baseline.get("schema"))
		return
	if not bool(baseline.get("frozen", false)):
		_fail("full-body baseline is not marked frozen")
		return
	var identities: Dictionary = baseline.get("identities", {})
	for identity in identities:
		var record: Dictionary = identities[identity]
		var name := StringName(identity)
		if not canonical.has_animation(name):
			_skipped_unpublished += 1
			continue
		if canonical.get_frame_count(name) != int(record["frames"]):
			continue
		# An identity the baseline marks unpreservable carries its reason with it.
		# It is reported every run so it cannot quietly become normal, but it does
		# not fail the gate: the clock genuinely cannot be expressed today.
		if record.has("unpreservable"):
			_unpreservable += 1
			print("  UNPRESERVABLE %s: %s" % [identity, record["unpreservable"]])
			continue
		_checked += 1
		var want_fps := float(record["fps"])
		var got_fps := canonical.get_animation_speed(name)
		if not is_equal_approx(want_fps, got_fps):
			_fail("full-body timing drift %s (via %s): authored %.3f fps, canonical %.3f fps" % [
				identity, record["via_clip"], want_fps, got_fps])
		var want_loop := bool(record["loop"])
		if want_loop != canonical.get_animation_loop(name):
			_fail("full-body loop drift %s (via %s): authored %s, canonical %s" % [
				identity, record["via_clip"], want_loop, canonical.get_animation_loop(name)])
		var durations: Array = record.get("durations", [])
		for index in int(record["frames"]):
			if index >= durations.size():
				break
			if not is_equal_approx(float(durations[index]), canonical.get_frame_duration(name, index)):
				_fail("full-body duration drift %s frame %d (via %s): authored %.4f, canonical %.4f" % [
					identity, index, record["via_clip"], float(durations[index]),
					canonical.get_frame_duration(name, index)])
