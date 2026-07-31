extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var actor := Node2D.new()
	actor.name = "Operator"
	world.add_child(actor)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)

	var approach := APPROACH_SCENE.instantiate() as Node2D
	root.add_child(approach)
	await process_frame
	await process_frame

	_check(bool(approach.call("is_visual_ready")), "approach visuals are not ready", errors)
	_check(
		(approach.call("get_boundary_segments") as Array).size() == 45,
		"extended Parish boundary does not contain 45 mapper rails",
		errors
	)
	for path in [
		"PlayableRoot/ShoreParishNorthboundGround",
		"PlayableRoot/OuterWallEastTraverseGround",
		"UnderlayRoot/OuterWallCheckpointDetail",
	]:
		var sprite := approach.get_node_or_null(path) as Sprite2D
		_check(sprite != null and sprite.texture != null, "missing authored overlay %s" % path, errors)
		if sprite != null:
			_check(not bool(sprite.get_meta("collision_authority", true)), "%s owns collision" % path, errors)
	var fog := approach.get_node_or_null(
		"UnderlayRoot/OuterWallCheckpointFog"
	) as AnimatedSprite2D
	_check(fog != null, "local checkpoint fog animation is missing", errors)
	if fog != null:
		_check(fog.sprite_frames.get_frame_count(&"loop") == 6, "checkpoint fog is not six frames", errors)
		_check(is_equal_approx(fog.sprite_frames.get_animation_speed(&"loop"), 7.0), "checkpoint fog speed drifted", errors)
		_check(fog.modulate.a <= 0.3001, "checkpoint fog exceeds route readability alpha", errors)
	_check(
		approach.get_node_or_null("OcclusionRoot/ApproachFinalGateShadowVeil") == null,
		"full-screen final navigation veil is still built",
		errors
	)
	var grand_root := approach.get_node_or_null("GrandVistaRoot") as CanvasItem
	_check(grand_root != null and not grand_root.visible, "duplicate whole-Keep Vista remains visible", errors)

	var controller := approach.get_node_or_null("VistaController")
	_check(controller != null, "VistaController missing", errors)
	if controller != null:
		actor.global_position = Vector2(700.0, -125.0)
		controller.call("_process", 0.0)
		var state := controller.call("get_reveal_choreography_state") as Dictionary
		_check(str(state.get("second_camera_phase", "")) == "SECOND_DISABLED", "Camera 2 is not explicitly disabled", errors)
		for key in ["second_enter_progress", "second_return_progress", "second_enter_weight", "second_return_weight", "second_camera_weight"]:
			_check(is_zero_approx(float(state.get(key, -1.0))), "%s is not zero" % key, errors)

	var marker_state := approach.call("get_authoring_marker_state") as Dictionary
	var exit_source := (marker_state.get("level_exit", {}) as Dictionary).get("source_position", Vector2.ZERO) as Vector2
	var return_source := (marker_state.get("return_causeway", {}) as Dictionary).get("source_position", Vector2.ZERO) as Vector2
	_check(exit_source.x >= 1220.0 and exit_source.x <= 1280.0, "Parish exit was not extended east", errors)
	_check(return_source.x >= 1100.0, "reverse spawn was not extended with the traverse", errors)

	game_root.queue_free()
	approach.queue_free()
	await process_frame
	if errors.is_empty():
		print("[SunderedKeepApproachSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepApproachSmoke] %s" % error)
	quit(1)


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)
