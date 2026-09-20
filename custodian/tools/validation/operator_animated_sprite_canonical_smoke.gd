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
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

const SECTORS: Array[StringName] = [&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw"]

## Sectors each full-body locomotion action actually authors. The projection
## table may map a missing sector onto one of these, and may not send an
## authored sector anywhere else.
const AUTHORED_FULL_BODY_SECTORS := {
	"unarmed/locomotion/idle_01": [&"e", &"n", &"s", &"w"],
	"unarmed/locomotion/walk_01": [&"e", &"n", &"s", &"w"],
	"unarmed/locomotion/run_01": [&"e", &"n", &"s", &"se", &"sw", &"w"],
}

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

	var scene_root := Node2D.new()
	scene_root.name = "OperatorAnimatedSpriteCanonicalRoot"
	root.add_child(scene_root)
	current_scene = scene_root
	var operator := OPERATOR_SCENE.instantiate()
	scene_root.add_child(operator)
	await process_frame
	_check_full_body_projection(operator, canonical)

	_report()


func _sector_vector(sector: StringName) -> Vector2:
	match sector:
		&"n": return Vector2(0.0, -1.0)
		&"ne": return Vector2(1.0, -1.0).normalized()
		&"e": return Vector2(1.0, 0.0)
		&"se": return Vector2(1.0, 1.0).normalized()
		&"s": return Vector2(0.0, 1.0)
		&"sw": return Vector2(-1.0, 1.0).normalized()
		&"w": return Vector2(-1.0, 0.0)
		&"nw": return Vector2(-1.0, -1.0).normalized()
	return Vector2.ZERO


func _check_full_body_projection(operator: Node, canonical: SpriteFrames) -> void:
	## Sparse full-body locomotion coverage is resolved by an explicit authoring
	## table, not by the selector. The selector stays exact-only, so a missing
	## identity is an error; deciding what a missing diagonal shows is
	## presentation policy and belongs to the caller.
	var table: Dictionary = operator.get("FULL_BODY_AUTHORED_SECTORS")
	_check(table != null and not table.is_empty(), "the full-body projection table should exist")
	if table == null or table.is_empty():
		return

	for identity in AUTHORED_FULL_BODY_SECTORS:
		var parts: PackedStringArray = String(identity).split("/")
		var authored: Array = AUTHORED_FULL_BODY_SECTORS[identity]
		_check(
			table.has("%s/full_body" % identity),
			"%s should declare a projection" % identity
		)
		for sector in SECTORS:
			var resolved: StringName = operator._full_body_authored_sector(
				parts[0], parts[1], parts[2], _sector_vector(sector)
			)

			# A. every projected destination is real canonical full-body art.
			var destination := "%s/%s/full_body" % [identity, resolved]
			_check(
				canonical.has_animation(destination),
				"%s projects %s -> %s, which is not published" % [identity, sector, destination]
			)

			if authored.has(sector):
				# B. an authored sector always presents itself. Projection covers
				#    missing art; it never overrides art that exists.
				_check(
					resolved == sector,
					"%s authors %s and must present it, not %s" % [identity, sector, resolved]
				)
				continue

			# C. a missing sector projects horizontally, and never onto another
			#    action. The historical fallback drew idle art for walk diagonals;
			#    that substitution is exactly what this table exists to stop.
			_check(
				resolved == &"e" or resolved == &"w",
				"%s should project missing %s horizontally, got %s" % [identity, sector, resolved]
			)
			_check(
				authored.has(resolved),
				"%s projects %s onto unauthored %s" % [identity, sector, resolved]
			)

	# D. run authors its lower diagonals and keeps them. Sparse coverage may be
	#    projected; authored art may not be discarded to make a table uniform.
	for sector in [&"se", &"sw"]:
		var run_sector: StringName = operator._full_body_authored_sector(
			"unarmed", "locomotion", "run_01", _sector_vector(sector)
		)
		_check(
			run_sector == sector,
			"run_01 authors %s and must not discard it (got %s)" % [sector, run_sector]
		)

	# E. the selector itself stays exact-only: it reports the unauthored
	#    diagonals as absent rather than quietly finding something near them.
	var selector = operator._get_operator_animation_selector()
	for sector in [&"ne", &"nw", &"se", &"sw"]:
		_check(
			not selector.has_sector_identity("unarmed", "locomotion", "walk_01", sector, &"full_body"),
			"selector should report walk_01 %s full_body absent, not substitute for it" % sector
		)
	_check(
		selector.has_sector_identity("unarmed", "locomotion", "walk_01", &"e", &"full_body"),
		"selector should resolve the authored walk_01 e full_body"
	)


func _report() -> void:
	if _failures.is_empty():
		print("operator animated_sprite canonical smoke: OK (%d promotion(s), full-body projection policy)" % PROMOTIONS.size())
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator animated_sprite canonical smoke: %d failure(s)" % _failures.size())
	quit(1)
