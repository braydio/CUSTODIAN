extends SceneTree
## Headless real-gameplay check for the Pursuit Frame 3D playable preview.
##
## Runs scenes/debug/pursuit_frame_3d_playable_preview.tscn, which instances the real
## combat playground, the real Operator and two real pursuit_frame.tscn actors. Checks
## movement, presentation, grounding, reversibility and unchanged gameplay stats.
## Requires the staged candidate frames (custodian/tools/debug/pursuit_frame_3d_stage.py).
##
## Run: godot --headless --path custodian --script res://tools/validation/pursuit_frame_3d_playable_preview_smoke.gd

const PREVIEW_SCENE := preload("res://scenes/debug/pursuit_frame_3d_playable_preview.tscn")
const PURSUIT_FRAME_SCENE := "res://game/actors/enemies/pursuit_frame.tscn"
const SAMPLE_FRAMES := 480
const COMPASS := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]

var _preview: Node2D
var _frames := 0
var _failures: Array[String] = []
var _passes: Array[String] = []
var _start_positions := {}
var _samples: Array[Dictionary] = []
var _state := 0


func _initialize() -> void:
	_preview = PREVIEW_SCENE.instantiate()
	root.add_child(_preview)


func _process(_delta: float) -> bool:
	_frames += 1
	if _state == 0:
		if _frames < 3:
			return false
		_setup_checks()
		_state = 1
		return false
	if _state == 1:
		_sample()
		if _samples.size() >= SAMPLE_FRAMES:
			_state = 2
			_complete()
	return false


func _complete() -> void:
	await _run_checks()
	_finish()


func _setup_checks() -> void:
	var candidate: CharacterBody2D = _preview.candidate_enemy
	var legacy: CharacterBody2D = _preview.legacy_enemy
	_check(candidate.scene_file_path == PURSUIT_FRAME_SCENE, "candidate is the real pursuit_frame.tscn actor")
	_check(legacy.scene_file_path == PURSUIT_FRAME_SCENE, "legacy reference is the real pursuit_frame.tscn actor")
	_start_positions["candidate"] = candidate.global_position
	_start_positions["legacy"] = legacy.global_position
	_check(_preview.adapter.current_display_scale() == 50.0 / 80.0, "default display scale is 50/80 (Operator 50 px/m contract)")
	_check(_preview.adapter.presentation == &"candidate", "candidate presentation is the default")


func _sample() -> void:
	var candidate: CharacterBody2D = _preview.candidate_enemy
	var adapter = _preview.adapter
	_samples.append({
		"position": candidate.global_position,
		"velocity": candidate.velocity,
		"legacy_action": String(candidate.get_enemy_presentation_action()),
		"clip": adapter.clip_name,
		"dir": adapter.last_dir,
		"frame": adapter.frame_index,
		"visible_body_count": adapter.visible_body_count(),
		"root": candidate.to_global(adapter.candidate_sprite.position),
		"shadow": candidate.to_global(PursuitFrame3DCandidateAdapter.SHADOW_OFFSET),
		"label": adapter.label,
	})


func _run_checks() -> void:
	var candidate: CharacterBody2D = _preview.candidate_enemy
	var legacy: CharacterBody2D = _preview.legacy_enemy
	var adapter = _preview.adapter
	var operator: Node2D = _preview.playground.get_node("World/Operator")

	# Movement: the real enemy must detect and chase.
	var moved := candidate.global_position.distance_to(_start_positions["candidate"])
	_check(moved >= 40.0, "candidate world position genuinely changed (moved %.1f px)" % moved)
	var start_gap: float = (_start_positions["candidate"] as Vector2).distance_to(operator.global_position)
	var end_gap: float = candidate.global_position.distance_to(operator.global_position)
	_check(end_gap < start_gap, "candidate closed distance to Operator (%.1f -> %.1f px)" % [start_gap, end_gap])
	var moving := _samples.filter(func(s): return (s["velocity"] as Vector2).length() > 20.0)
	_check(moving.size() >= 30, "candidate was moving in %d sampled frames" % moving.size())

	# Frames advance during real movement, and the clip matches the legacy locomotion.
	var distinct := {}
	for s in moving:
		if s["clip"] in ["running", "walking"]:
			distinct[s["frame"]] = true
	_check(distinct.size() >= 3, "candidate frames advanced during movement (%d distinct)" % distinct.size())
	var locomotion_ok := true
	for s in moving:
		if s["legacy_action"] in ["locomotion.run", "locomotion.relaxed_run"] and s["clip"] != "running":
			locomotion_ok = false
		if s["legacy_action"] in ["locomotion.walk", "locomotion.relaxed_walk"] and s["clip"] != "walking":
			locomotion_ok = false
	_check(locomotion_ok, "running/walking mapping follows the enemy's own locomotion action")

	# Direction follows travel (8-way, screen space).
	var agree := 0
	for s in moving:
		var v: Vector2 = s["velocity"]
		var idx := int(round(wrapf(v.angle(), 0.0, TAU) / (PI / 4.0))) % 8
		if COMPASS[idx] == s["dir"]:
			agree += 1
	var agree_ratio := float(agree) / maxf(1.0, float(moving.size()))
	_check(agree_ratio >= 0.9, "animation direction follows travel (%.0f%% of moving samples)" % (agree_ratio * 100.0))

	# Grounding: the visual root stays on the shadow contact point for every sample.
	var max_root_error := 0.0
	for s in _samples:
		max_root_error = maxf(max_root_error, (s["root"] as Vector2).distance_to(s["shadow"] as Vector2))
	_check(max_root_error < 0.01, "visual root registered to the contact shadow (max error %.4f px)" % max_root_error)

	# Exactly one visible body, and the legacy body is hidden.
	var single_body := _samples.all(func(s): return s["visible_body_count"] == 1)
	_check(single_body, "exactly one visible body on every sampled frame")
	_check(not candidate.get_node("AnimatedSprite2D").visible, "legacy body hidden while candidate is shown")

	# Reversible A/B.
	adapter.set_presentation(&"legacy")
	_check(candidate.get_node("AnimatedSprite2D").visible and adapter.visible_body_count() == 1, "legacy presentation restores exactly one legacy body")
	adapter.set_presentation(&"candidate")
	_check(not candidate.get_node("AnimatedSprite2D").visible and adapter.visible_body_count() == 1, "candidate presentation restores exactly one candidate body")

	# Inspection: the extended-height class is used only where it is needed.
	adapter.set_mode(&"inspect")
	adapter.inspect_action_index = adapter.INSPECT_ACTIONS.find("behit_flyup")
	adapter.inspect_dir_index = 2
	adapter.advance(0.0)
	_check(adapter.clip_name == "behit_flyup" and adapter.candidate_sprite.texture.get_height() == 320, "behit_flyup uses the 256x320 extended viewport")
	adapter.inspect_action_index = adapter.INSPECT_ACTIONS.find("running")
	adapter.advance(0.0)
	_check(adapter.candidate_sprite.texture.get_height() == 256, "running uses the 256x256 standard viewport")
	adapter.set_mode(&"gameplay")

	# Gameplay stats and collision are untouched by the preview.
	var shape := candidate.get_node("CollisionShape2D").shape as RectangleShape2D
	_check(shape != null and shape.size == Vector2(28, 28), "collision shape unchanged (28x28)")
	_check(candidate.speed == 96.0, "movement speed unchanged (96)")
	_check(candidate.damage == 15.0, "damage unchanged (15)")

	# Regression: production scene and enemy script do not reference the debug adapter.
	var scene_text := FileAccess.get_file_as_string(PURSUIT_FRAME_SCENE)
	_check(not scene_text.contains("pursuit_frame_3d"), "production pursuit_frame.tscn does not reference the candidate")
	var enemy_text := FileAccess.get_file_as_string("res://game/actors/enemies/enemy.gd")
	_check(not enemy_text.contains("pursuit_frame_3d"), "enemy.gd does not reference the candidate")
	var manifest_ok := FileAccess.file_exists(PursuitFrame3DCandidateAdapter.MANIFEST_PATH)
	_check(manifest_ok, "staged candidate manifest present")

	# Telemetry-style summary.
	var summary := {
		"samples": _samples.size(),
		"moved_px": moved,
		"gap_start_px": start_gap,
		"gap_end_px": end_gap,
		"distinct_frames_while_moving": distinct.size(),
		"direction_agreement": agree_ratio,
		"max_root_error_px": max_root_error,
		"candidate_state": String(_preview.candidate_enemy.get("behavior_state_machine").get("current_state")),
	}
	print("SUMMARY_JSON ", JSON.stringify(summary))


func _check(ok: bool, message: String) -> void:
	if ok:
		_passes.append(message)
		print("PASS ", message)
	else:
		_failures.append(message)
		print("FAIL ", message)


func _finish() -> void:
	print("RESULT passes=%d failures=%d" % [_passes.size(), _failures.size()])
	quit(0 if _failures.is_empty() else 1)
