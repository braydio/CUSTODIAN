extends SceneTree

const MAPPER_SCENE := preload("res://scenes/debug/sundered_keep_approach_collision_mapper.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var scene := MAPPER_SCENE.instantiate() as Node
	if scene == null:
		_fail(["Could not instantiate collision mapper scene"])
		return
	root.add_child(scene)
	await process_frame
	await process_frame

	var world := scene.get_node_or_null("World") as Node2D
	if world == null:
		errors.append("World node missing")
	var camera := scene.get_node_or_null("World/Camera2D") as Camera2D
	if camera == null:
		errors.append("Camera2D missing")
	var overlay := scene.get_node_or_null("World/CollisionOverlay") as Node2D
	if overlay == null:
		errors.append("CollisionOverlay missing")
	var help := scene.get_node_or_null("CanvasLayer/Help") as Label
	if help == null:
		errors.append("Help label missing")
	elif not help.text.contains("connected polyline"):
		errors.append("Help label should describe connected polyline segment export")

	if not scene.has_method("get_collision_mapper_state"):
		errors.append("Mapper script does not expose get_collision_mapper_state()")
	if not scene.has_method("_apply_draft_segments_to_runtime_collision_map"):
		errors.append("Mapper script does not expose runtime collision-map apply helper")
	if not scene.has_method("_replace_boundary_segments_block") or not scene.has_method("_format_boundary_segments_const"):
		errors.append("Mapper script does not expose non-mutating replacement helpers")
	else:
		var state := scene.call("get_collision_mapper_state") as Dictionary
		var approach := state.get("approach") as Node
		if approach == null:
			errors.append("Mapper did not instantiate active Sundered Keep approach")
		elif approach.get_node_or_null("Collision/PathBoundaryCollision") == null:
			errors.append("Mapper approach missing PathBoundaryCollision")
		if not bool(state.get("show_existing", false)):
			errors.append("Existing collision overlay should start visible")
		if not bool(state.get("show_draft", false)):
			errors.append("Draft overlay should start visible")
		var replacement_lines: Array[String] = ["[Vector2(1.0, 2.0), Vector2(3.0, 4.0)],"]
		var replacement := str(scene.call("_format_boundary_segments_const", replacement_lines))
		var replaced := str(scene.call("_replace_boundary_segments_block", "before\nconst BOUNDARY_SEGMENTS := [\n\t[Vector2.ZERO, Vector2.ONE],\n]\nafter", replacement))
		if not replaced.contains("[Vector2(1.0, 2.0), Vector2(3.0, 4.0)],"):
			errors.append("Mapper replacement helper did not insert new segment text")
		if replaced.contains("Vector2.ZERO"):
			errors.append("Mapper replacement helper left stale segment text behind")

	if errors.is_empty():
		print("[SunderedKeepApproachCollisionMapperSmoke] PASS")
		quit(0)
		return
	_fail(errors)


func _fail(errors: Array[String]) -> void:
	for error in errors:
		push_error("[SunderedKeepApproachCollisionMapperSmoke] %s" % error)
	quit(1)
