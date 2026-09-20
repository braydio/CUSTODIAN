extends SceneTree
## C2a-R4 acceptance: the animated_sprite cutover preserves authored behaviour.
##
## This gate is seeded before the rebind and grows with it. What it asserts today
## is the part of R4 that is already true and must stay true afterwards: every
## legacy clip promoted into a canonical identity is a PRESERVATION, not an art
## change. Same pixels, same frame count, same clock.
##
## A promotion is the one case where compatibility art becomes canonical art
## directly, so it is also the one case where "the canonical clip looks right"
## is checkable mechanically rather than by authoring judgement. Timing alone is
## not enough here: a promotion that sliced the wrong region of the legacy sheet
## would keep the clock and change every pixel.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md
## Evidence:  reports/operator/operator_animated_sprite_cutover_evidence.md

const CANONICAL := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"
const COMPATIBILITY := "res://game/actors/operator/operator_runtime_frames.tres"

## legacy compatibility clip -> canonical identity it was promoted into.
## Mirrors LEGACY_PROMOTIONS in
## tools/pipelines/migrations/operator_animated_sprite_cutover_evidence.py.
const PROMOTIONS := {
	"ranged_2h_reload": "ranged_2h/cosmetic/reload_01/omni/full_body",
}

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _frame_digest(frames: SpriteFrames, animation: String, index: int) -> PackedByteArray:
	var texture := frames.get_frame_texture(animation, index)
	if texture == null:
		return PackedByteArray()
	var image := texture.get_image()
	if image == null:
		return PackedByteArray()
	if image.is_compressed():
		image.decompress()
	return image.get_data()


func _init() -> void:
	var canonical: SpriteFrames = load(CANONICAL)
	var compatibility: SpriteFrames = load(COMPATIBILITY)
	_check(canonical != null, "canonical runtime SpriteFrames should load")
	_check(compatibility != null, "compatibility SpriteFrames should load")
	if canonical == null or compatibility == null:
		_report()
		return

	for legacy_clip in PROMOTIONS:
		var identity: String = PROMOTIONS[legacy_clip]
		_check(
			compatibility.has_animation(legacy_clip),
			"promotion source %s should still exist pre-cutover" % legacy_clip
		)
		if not compatibility.has_animation(legacy_clip):
			continue
		if not canonical.has_animation(identity):
			_failures.append("promoted identity %s should exist in the canonical runtime spine" % identity)
			continue

		# A. the clock is carried over exactly, not re-derived from the builder default.
		var legacy_frames := compatibility.get_frame_count(legacy_clip)
		var promoted_frames := canonical.get_frame_count(identity)
		_check(
			legacy_frames == promoted_frames,
			"%s should keep %d frames, has %d" % [identity, legacy_frames, promoted_frames]
		)
		_check(
			is_equal_approx(compatibility.get_animation_speed(legacy_clip), canonical.get_animation_speed(identity)),
			"%s should keep %s FPS, has %s" % [
				identity,
				compatibility.get_animation_speed(legacy_clip),
				canonical.get_animation_speed(identity),
			]
		)
		_check(
			compatibility.get_animation_loop(legacy_clip) == canonical.get_animation_loop(identity),
			"%s should keep loop=%s" % [identity, compatibility.get_animation_loop(legacy_clip)]
		)

		# B. the pixels are the same pixels. This is what distinguishes a promotion
		#    from a re-author, and it is what catches slicing the wrong row of a
		#    multi-row legacy sheet.
		if legacy_frames != promoted_frames:
			continue
		for index in legacy_frames:
			var legacy_digest := _frame_digest(compatibility, legacy_clip, index)
			var promoted_digest := _frame_digest(canonical, identity, index)
			_check(
				not legacy_digest.is_empty(),
				"%s frame %d should expose readable pixels" % [legacy_clip, index]
			)
			_check(
				legacy_digest == promoted_digest,
				"%s frame %d should be pixel-identical to %s" % [identity, index, legacy_clip]
			)
			_check(
				is_equal_approx(
					compatibility.get_frame_duration(legacy_clip, index),
					canonical.get_frame_duration(identity, index)
				),
				"%s frame %d should keep its authored duration" % [identity, index]
			)

	_report()


func _report() -> void:
	if _failures.is_empty():
		print("operator animated_sprite canonical smoke: OK (%d promotion(s) verified)" % PROMOTIONS.size())
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator animated_sprite canonical smoke: %d failure(s)" % _failures.size())
	quit(1)
