extends SceneTree

## Headless smoke for the dev-only playable 3D Operator preview.
##
## Checks presentation ownership, staged frame metadata and sizes, direction mapping, a real movement
## input through the Operator's own controller, and that collision and shadow remain intact.
## Run: godot --headless --path custodian --script res://tools/validation/operator_3d_playable_preview_smoke.gd

const SCENE := "res://scenes/debug/operator_3d_playable_preview_awakening.tscn"
const Catalog := preload("res://tools/debug/operator_3d_preview_catalog.gd")

var _failures: Array[String] = []


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)
		push_error("[operator_3d_playable_preview_smoke] FAIL: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# 1. Direction mapping (pure function).
	var expected := {
		Vector2(1, 0): "E", Vector2(1, 1): "SE", Vector2(0, 1): "S", Vector2(-1, 1): "SW",
		Vector2(-1, 0): "W", Vector2(-1, -1): "NW", Vector2(0, -1): "N", Vector2(1, -1): "NE",
	}
	for v in expected:
		_check(Catalog.direction_for_velocity(v) == expected[v],
			"direction_for_velocity(%s) != %s" % [v, expected[v]])

	# 2. Staged metadata and frame sizes.
	var catalog := Catalog.new()
	for action in ["walking", "running", "alert", "casual_walk", "dead", "run_03", "runfast",
			"skill_01", "skill_03", "triple_combo_attack", "unsteady_walk"]:
		_check(catalog.has_action(80, action), "missing 80 px/m metadata for %s" % action)
		if not catalog.has_action(80, action):
			continue
		var size := catalog.frame_size(80, action)
		var expected_size := Vector2i(192, 192) if action in ["skill_01", "skill_03", "triple_combo_attack"] else Vector2i(160, 160)
		_check(size == expected_size, "%s frame size %s != %s" % [action, size, expected_size])
		var tex := catalog.texture(80, action, "S", 0)
		_check(tex != null and Vector2i(tex.get_size()) == size, "%s S0 texture size mismatch" % action)
	for action in ["running", "walking"]:
		_check(catalog.has_action(50, action) and catalog.frame_size(50, action) == Vector2i(128, 128),
			"50 px/m %s must be 128x128" % action)

	# 3. Scene: real Awakening instance, presenter ownership, one visible body.
	var packed := load(SCENE) as PackedScene
	_check(packed != null, "scene failed to load")
	if packed == null:
		_finish()
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var operator := root.get_node("Awakening/World/Operator") as CharacterBody2D
	var presenter = operator.get("_body_presenter")
	var owner3d := OperatorBodyPresenter.Owner.PREVIEW_3D_CANDIDATE
	_check(presenter != null and int(presenter.call("current_owner")) == owner3d,
		"3D candidate did not acquire the body")
	var visible_owners: Array = presenter.call("visible_owners")
	_check(visible_owners == [owner3d], "visible owners %s != [PREVIEW_3D]" % [visible_owners])
	var legacy := operator.get("animated_sprite") as CanvasItem
	_check(legacy == null or not legacy.visible, "legacy body still visible")
	var body := operator.get_node_or_null("Operator3DPreviewBody") as Sprite2D
	_check(body != null and body.visible and body.texture != null, "3D body missing or invisible")

	# 4. Gameplay authority intact: collision and shadow untouched by the preview.
	_check(operator.collision_layer != 0, "Operator collision layer was zeroed")
	_check(operator.find_children("*", "CollisionShape2D", true, false).size() > 0, "Operator has no collision shapes")
	_check(operator.get_node_or_null("BlobShadow") != null, "Operator shadow missing")

	# 5. Real movement through the Operator's own controller.
	# Test setup only (not gameplay): start from a known walkable point, as the executor preview did,
	# so rescue/unstuck logic does not steer the Operator while the movement input is checked.
	const SPAWN := Vector2(0.0, -1824.0)
	const LAYOUT := preload("res://game/world/awakening/awakening_layout.gd")
	_check(LAYOUT.is_point_walkable(SPAWN), "test spawn is not walkable")
	operator.global_position = SPAWN
	operator.velocity = Vector2.ZERO
	for i in range(30):
		await physics_frame
		await process_frame
	var start_x := operator.global_position.x
	Input.action_press("move_right")
	var east_frames := 0
	var moving_walk_frames := 0
	for i in range(90):
		await physics_frame
		await process_frame
		if operator.velocity.length() >= 8.0:
			east_frames += 1 if str(root.get("current_direction")) == "E" else 0
			moving_walk_frames += 1
	Input.action_release("move_right")
	var moved := operator.global_position.x - start_x
	_check(moved > 20.0, "Operator did not move under move_right (moved %.1f px)" % moved)
	_check(root.get("current_action") == "walking" or root.get("current_action") == "running",
		"moving Operator did not choose walking/running")
	# Movement is cut short by walls and rescue logic, so require east to dominate the moving frames.
	_check(moving_walk_frames > 0 and east_frames * 2 > moving_walk_frames,
		"move_right presented E on %d of %d moving frames" % [east_frames, moving_walk_frames])

	# 6. Sprint selects running from the same real input path.
	# Sample the presentation only on frames where the Operator is actually moving (it may be blocked by walls).
	# Walk back west for the sprint check: the eastward walk may have pressed the Operator into a wall.
	Input.action_press("move_left")
	Input.action_press("sprint")
	var moving_frames := 0
	var running_frames := 0
	for i in range(30):
		await physics_frame
		await process_frame
		if operator.velocity.length() >= 8.0:
			moving_frames += 1
			if root.get("current_action") == "running":
				running_frames += 1
	Input.action_release("sprint")
	Input.action_release("move_left")
	_check(moving_frames > 0, "Operator never moved while sprinting (cannot test running)")
	# Up to three transition frames are allowed while the sprint press reaches the controller.
	_check(running_frames > 0 and moving_frames - running_frames <= 3,
		"sprint did not select running after the transition (%d/%d)" % [running_frames, moving_frames])

	# 7. Ownership survives the frames and the preview reports no preemption.
	_check(int(presenter.call("current_owner")) == owner3d, "ownership changed during movement")

	# 8. Preview off restores the original owner and leaves the preview body hidden.
	root.call("_release")
	await process_frame
	_check(int(presenter.call("current_owner")) == OperatorBodyPresenter.Owner.LEGACY_FULL_BODY,
		"preview off did not restore the legacy owner")
	_check(not (body != null and body.visible), "preview body still visible with preview off")

	root.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("[operator_3d_playable_preview_smoke] PASS")
		quit(0)
	else:
		print("[operator_3d_playable_preview_smoke] FAIL (%d)" % _failures.size())
		quit(1)
