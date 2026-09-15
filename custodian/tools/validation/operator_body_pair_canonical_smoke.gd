extends SceneTree
## C2a-R3 acceptance: the modular body pair is canonical.
##
## Both body renderers share the one generated runtime SpriteFrames, resolve
## semantic identities through OperatorAnimationSelector, and no longer depend on
## compatibility clip names, a per-instance SpriteFrames fork, or a second
## animation database.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CANONICAL := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _init() -> void:
	var canonical: SpriteFrames = load(CANONICAL)
	var scene_root := Node2D.new()
	scene_root.name = "OperatorBodyPairCanonicalRoot"
	root.add_child(scene_root)
	current_scene = scene_root
	var operator := OPERATOR_SCENE.instantiate()
	scene_root.add_child(operator)
	await process_frame

	var lower := operator.get_node_or_null("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node_or_null("ModularUpperBodySprite") as AnimatedSprite2D
	_check(lower != null and upper != null, "both body renderers should exist")
	if lower == null or upper == null:
		_report()
		return

	# A. both renderers share the ONE generated runtime resource
	_check(lower.sprite_frames == canonical, "lower body should bind the canonical runtime SpriteFrames")
	_check(upper.sprite_frames == canonical, "upper body should bind the canonical runtime SpriteFrames")

	# B. no per-instance fork. A duplicate would compare unequal to the shared
	#    resource, which is exactly how the retired catalog install hid itself.
	var second := OPERATOR_SCENE.instantiate()
	scene_root.add_child(second)
	await process_frame
	var second_lower := second.get_node_or_null("ModularLowerBodySprite") as AnimatedSprite2D
	_check(
		second_lower != null and second_lower.sprite_frames == lower.sprite_frames,
		"two Operators must share one SpriteFrames instance, not a per-instance fork"
	)
	second.queue_free()

	# C. the scene authors no semantic animation. These nodes are presentation
	#    owned and hidden at startup; runtime selection names the first clip.
	_check(String(lower.animation).is_empty() or lower.sprite_frames.has_animation(lower.animation),
		"lower body must not start on an unplayable scene-authored animation (%s)" % lower.animation)
	_check(String(upper.animation).is_empty() or upper.sprite_frames.has_animation(upper.animation),
		"upper body must not start on an unplayable scene-authored animation (%s)" % upper.animation)

	# D. compatibility clip names are gone from the body pair entirely
	for legacy in [
		&"unarmed_idle_down", &"unarmed_walk_right", &"unarmed_parry_right",
		&"unarmed_block_hold_right", &"unarmed_block_hitreact_right",
		&"ranged_2h_stance_modular_right", &"ranged_2h_aim_modular_right",
		&"operator_idle_hitreact_modular_up",
	]:
		_check(not lower.sprite_frames.has_animation(legacy),
			"canonical body must not carry the legacy clip %s" % legacy)

	# E. identities the cutover depends on, including the promoted upper guard art
	for identity in [
		"unarmed/defense/block_enter_01/e/lower_body", "unarmed/defense/block_enter_01/e/upper_body",
		"unarmed/defense/block_enter_01/w/lower_body", "unarmed/defense/block_enter_01/w/upper_body",
		"unarmed/defense/parry_01/n/lower_body", "unarmed/defense/parry_01/e/upper_body",
		"unarmed/attack/parry_recovery_01/e/lower_body", "unarmed/attack/parry_recovery_01/w/upper_body",
		"unarmed/locomotion/idle_hitreact_01/n/lower_body", "unarmed/locomotion/idle_hitreact_01/s/upper_body",
		"unarmed/locomotion/walk_01/ne/lower_body", "unarmed/locomotion/walk_01/nw/lower_body",
		"unarmed/locomotion/run_01/ne/lower_body", "unarmed/attack/fast_windup_01/n/lower_body",
		"melee_1h/posture/idle_ready_01/e/lower_body", "melee_1h/locomotion/run_01/s/upper_body",
	]:
		_check(canonical.has_animation(StringName(identity)), "missing canonical identity %s" % identity)

	# F. guard enter is a synchronized 4-frame pair at the authored clock
	for layer in ["lower_body", "upper_body"]:
		for sector in ["e", "w"]:
			var guard := StringName("unarmed/defense/block_enter_01/%s/%s" % [sector, layer])
			_check(canonical.get_frame_count(guard) == 4, "%s should be 4 frames" % guard)
			_check(is_equal_approx(canonical.get_animation_speed(guard), 10.0), "%s should play at 10 FPS" % guard)
			_check(not canonical.get_animation_loop(guard), "%s should not loop" % guard)

	# G. semantic selection, including the cross-action mis-publications R3 corrected
	var cases := [
		["unarmed_walk", &"lower_body", Vector2(1, -1), "unarmed/locomotion/walk_01/ne/lower_body"],
		["unarmed_walk", &"lower_body", Vector2(-1, -1), "unarmed/locomotion/walk_01/nw/lower_body"],
		["unarmed_run", &"lower_body", Vector2(1, -1), "unarmed/locomotion/run_01/ne/lower_body"],
		["unarmed_fast_windup_lower", &"lower_body", Vector2.UP, "unarmed/attack/fast_windup_01/n/lower_body"],
		# parry keeps its authored north; the reduced E/W policy would have lost it
		["unarmed_parry", &"lower_body", Vector2.UP, "unarmed/defense/parry_01/n/lower_body"],
		["unarmed_parry", &"upper_body", Vector2(1, 1), "unarmed/defense/parry_01/e/upper_body"],
		["unarmed_parry_success", &"lower_body", Vector2.LEFT, "unarmed/defense/parry_01/w/lower_body"],
		# post-success neutral is the recovery action on BOTH layers
		["unarmed_parry_success_01", &"lower_body", Vector2.RIGHT, "unarmed/attack/parry_recovery_01/e/lower_body"],
		["unarmed_parry_success_01", &"upper_body", Vector2(-1, -1), "unarmed/attack/parry_recovery_01/w/upper_body"],
		# deterministic hit-reaction projection; east/west no longer inherit a sector
		["unarmed_idle_hitreact", &"lower_body", Vector2.UP, "unarmed/locomotion/idle_hitreact_01/n/lower_body"],
		["unarmed_idle_hitreact", &"lower_body", Vector2.RIGHT, "unarmed/locomotion/idle_hitreact_01/s/lower_body"],
		["unarmed_idle_hitreact", &"lower_body", Vector2.LEFT, "unarmed/locomotion/idle_hitreact_01/s/lower_body"],
		# layer-specific coverage: the upper body has no authored NE idle/walk
		["unarmed_idle", &"upper_body", Vector2(1, -1), "unarmed/locomotion/idle_01/n/upper_body"],
		["unarmed_walk", &"upper_body", Vector2(-1, -1), "unarmed/locomotion/walk_01/n/upper_body"],
	]
	for case in cases:
		var got: StringName = operator.call(
			"_resolve_modular_body_animation", case[0], case[1], case[2]
		)
		_check(String(got) == String(case[3]),
			"%s %s %s resolved '%s', expected '%s'" % [case[0], case[1], case[2], got, case[3]])
		_check(canonical.has_animation(got), "resolved identity %s should be playable" % got)

	# H. interaction/success_01 is never the post-parry-neutral body
	for layer in [&"lower_body", &"upper_body"]:
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var neutral: StringName = operator.call(
				"_resolve_modular_body_animation", "unarmed_parry_success_01", layer, direction
			)
			_check(String(neutral).find("interaction") == -1,
				"post-parry neutral must never present interaction art (%s)" % neutral)

	# I. the ranged upper preserves the sectors that authored no fire action
	for sector_direction in [[Vector2(1, -1), "ne"], [Vector2.DOWN, "s"], [Vector2(-1, -1), "nw"]]:
		var absent: StringName = operator.call(
			"_resolve_modular_body_animation", "ranged_2h_fire_modular", &"upper_body", sector_direction[0]
		)
		_check(String(absent).is_empty(),
			"ranged upper fire should present nothing for %s, got '%s'" % [sector_direction[1], absent])

	# J. socket tracks are keyed by the live upper-body identity, with no translation
	var socket_raw := FileAccess.get_file_as_string(
		"res://content/data/operator/generated/operator_weapon_sockets.generated.json"
	)
	var socket_payload: Variant = JSON.parse_string(socket_raw)
	var tracks: Dictionary = (socket_payload as Dictionary).get("tracks", {})
	for key in tracks:
		_check(String(key).find("_modular_") == -1,
			"socket data must not carry the legacy track key %s" % key)
	for phase in [["posture", "stance_01"], ["cosmetic", "aim_01"], ["cosmetic", "fire_01"]]:
		for sector in ["e", "w", "se", "sw"]:
			var track_key := "ranged_2h/%s/%s/%s/upper_body" % [phase[0], phase[1], sector]
			_check(tracks.has(track_key), "missing canonical socket track %s" % track_key)
			if tracks.has(track_key):
				_check(
					(tracks[track_key] as Array).size() == canonical.get_frame_count(StringName(track_key)),
					"socket track %s frame count should match its animation" % track_key
				)

	operator.queue_free()
	scene_root.queue_free()
	_report()


func _report() -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		push_error("operator_body_pair_canonical_smoke failed")
		quit(1)
		return
	print("operator body pair canonical smoke passed")
	quit()
