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
	"unarmed/attack/heavy_01": [&"e", &"n", &"s", &"w"],
}

## Identities whose callers restrict the direction they ever request, so sparse
## coverage is safe without a projection entry. Each needs a reason, because
## "the caller happens to be careful" is only true until someone edits the caller.
const CALLER_CONSTRAINED_IDENTITIES := {
	"shared/transition/dodge_01":
		"played from DODGE_FULL_NORTH/SOUTH_ANIMATION directly; never direction-resolved",
	"ranged_2h/cosmetic/fire_walk_01":
		"a weapon-map fallback name and a speed-scale comparison; never direction-resolved",
	"ranged_2h/locomotion/run_01":
		"requested only inside a direction_suffix right/left guard, so only e/w",
	"unarmed/attack/dodge_fast_attack_01":
		"requested with Vector2.LEFT/RIGHT from the authored roll-exit inversion",
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
	_check_identity_coverage(operator, canonical)
	_check_rebind(operator, canonical)

	_report()


func _check_rebind(operator: Node, canonical: SpriteFrames) -> void:
	## The cutover itself: `animated_sprite` draws from the shared canonical spine,
	## nothing forks or mutates it, and the legacy full-body names are gone.
	var sprite := operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(sprite != null, "the Operator should still have its AnimatedSprite2D")
	if sprite == null:
		return

	# A. bound directly to the shared resource, not to a copy of it.
	_check(
		sprite.sprite_frames == canonical,
		"animated_sprite should bind the canonical runtime SpriteFrames"
	)

	# B. no per-instance fork. A duplicate compares unequal, which is exactly how
	#    the retired `duplicate(true)` injection used to hide.
	var second := OPERATOR_SCENE.instantiate()
	operator.get_parent().add_child(second)
	var second_sprite := second.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(
		second_sprite != null and second_sprite.sprite_frames == sprite.sprite_frames,
		"two Operators must share one SpriteFrames instance, not fork per instance"
	)
	second.queue_free()

	# C. the legacy full-body names the actor used to inject or select are absent
	#    from the canonical spine, so nothing can quietly resolve them again.
	for retired in [
		&"melee_2h_fast_1_right", &"melee_2h_fast_2_right", &"melee_2h_fast_3_right",
		&"melee_stance", &"idle_long", &"idle_right", &"run_right", &"walk_right",
		&"walk_down_default", &"ranged_2h_fire", &"ranged_2h_stance",
		&"ranged_2h_fire_walk", &"operator_dodge_full_north", &"operator_dodge_full_south",
		&"death",
	]:
		_check(
			not canonical.has_animation(retired),
			"retired legacy name %s must not exist in the canonical spine" % retired
		)

	# D. the canonical identities the cutover depends on are published.
	for identity in [
		"unarmed/reaction/death_01/omni/full_body",
		"ranged_2h/cosmetic/reload_01/omni/full_body",
		"ranged_2h/cosmetic/fire_walk_01/s/full_body",
		"shared/transition/dodge_01/n/full_body",
		"shared/transition/dodge_01/s/full_body",
		"unarmed/locomotion/idle_01/e/full_body",
		"unarmed/locomotion/walk_01/e/full_body",
		"unarmed/locomotion/walk_01/w/full_body",
		"unarmed/locomotion/run_01/e/full_body",
	]:
		_check(canonical.has_animation(identity), "%s should be published" % identity)

	# E. the ranged full-body composition is deliberately NOT published. Publishing
	#    it later would be schema-clean and architecturally wrong.
	for absent in [
		"ranged_2h/cosmetic/fire_01/e/full_body",
		"ranged_2h/posture/stance_01/e/full_body",
	]:
		_check(
			not canonical.has_animation(absent),
			"%s must stay unpublished; ranged presentation is the modular stack" % absent
		)

	# F. direction lives in the identity. `walk_01/e` and `walk_01/w` are separate
	#    authored strips, so playing west must use the west texture and must not
	#    mirror it back toward east.
	var east := "unarmed/locomotion/walk_01/e/full_body"
	var west := "unarmed/locomotion/walk_01/w/full_body"
	_check(east != west, "east and west walk should be different canonical identities")
	if canonical.has_animation(east) and canonical.has_animation(west):
		var east_texture := canonical.get_frame_texture(east, 0)
		var west_texture := canonical.get_frame_texture(west, 0)
		_check(
			east_texture != null and west_texture != null and east_texture != west_texture,
			"east and west walk should draw different textures, not one mirrored strip"
		)
	var played: StringName = operator._play_canonical_full_body(
		"unarmed_walk", _sector_vector(&"w")
	)
	_check(played == StringName(west), "west walk should resolve %s, got %s" % [west, played])
	_check(
		not sprite.flip_h,
		"canonical directional playback must not mirror; flip_h should be false"
	)


func _check_identity_coverage(operator: Node, canonical: SpriteFrames) -> void:
	## Every identity reachable through `_resolve_full_body_animation` must be
	## resolvable for every sector a caller can ask for.
	##
	## This audits the whole table rather than a list of families someone
	## remembered to enumerate, because that is the hole that let two regressions
	## through C2a-R4: `melee_1h_heavy/attack/heavy_windup_01` and
	## `fast_recovery_01` are authored `s`-only, were previously generic
	## direction-less compatibility clips, and silently stopped resolving for every
	## non-south attack. The heavy one skipped a gameplay phase, not just art.
	##
	## Four outcomes are acceptable, and nothing else is: the action is OMNI, it
	## publishes all eight sectors, it has an explicit projection policy, or its
	## caller provably constrains the request.
	var identities: Dictionary = operator.get("FULL_BODY_IDENTITIES")
	var projections: Dictionary = operator.get("FULL_BODY_AUTHORED_SECTORS")
	_check(identities != null and not identities.is_empty(), "the identity table should exist")
	if identities == null:
		return

	for base in identities:
		var identity: Array = identities[base]
		var action := "%s/%s/%s" % [identity[0], identity[1], identity[2]]
		if CALLER_CONSTRAINED_IDENTITIES.has(action):
			continue
		if canonical.has_animation("%s/omni/full_body" % action):
			continue
		if projections.has("%s/full_body" % action):
			# A policy exists; _check_full_body_projection validates its contents
			# for the families it enumerates. Here we only require every sector to
			# land somewhere real.
			for sector in SECTORS:
				var resolved: StringName = operator._full_body_authored_sector(
					identity[0], identity[1], identity[2], _sector_vector(sector)
				)
				_check(
					canonical.has_animation("%s/%s/full_body" % [action, resolved]),
					"%s projects %s -> %s, which is not published" % [action, sector, resolved]
				)
			continue
		for sector in SECTORS:
			_check(
				canonical.has_animation("%s/%s/full_body" % [action, sector]),
				("%s is requested by `%s` but publishes no %s full_body art, and has neither a "
				+ "FULL_BODY_AUTHORED_SECTORS policy nor a recorded caller constraint")
					% [action, base, sector]
			)


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
		print("operator animated_sprite canonical smoke: OK (%d promotion(s), projection policy, rebind)" % PROMOTIONS.size())
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator animated_sprite canonical smoke: %d failure(s)" % _failures.size())
	quit(1)
