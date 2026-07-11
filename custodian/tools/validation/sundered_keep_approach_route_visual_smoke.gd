extends SceneTree

const VISTA_ONE := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_vista_one.tscn")
const PRE_LEVEL := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_pre_level.tscn")
const GRAND_VISTA := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_grand_vista.tscn")
const CAUSEWAY := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_causeway_approach.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	await _check_stage(VISTA_ONE, "VistaOne", "BackdropVoidFill", Vector2(2450.0, 1650.0), errors)
	await _check_stage(PRE_LEVEL, "PreLevel", "UnderlayBackdrop/BackdropVoidFill", Vector2(2450.0, 1650.0), errors)
	await _check_stage(GRAND_VISTA, "GrandVista", "GrandVistaRoot/BackdropVoidFill", Vector2(2450.0, 1650.0), errors)
	await _check_causeway(errors)

	if errors.is_empty():
		print("[SunderedKeepApproachRouteVisualSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepApproachRouteVisualSmoke] %s" % error)
	quit(1)


func _check_stage(scene: PackedScene, label: String, fill_path: String, expected_bounds: Vector2, errors: Array[String]) -> void:
	var stage := scene.instantiate() as Node
	if stage == null:
		errors.append("%s could not instantiate" % label)
		return
	root.add_child(stage)
	await process_frame
	if stage.get_node_or_null(fill_path) == null:
		errors.append("%s missing %s" % [label, fill_path])
	_check_bounds(stage, label, expected_bounds, errors)
	stage.queue_free()
	await process_frame


func _check_causeway(errors: Array[String]) -> void:
	var stage := CAUSEWAY.instantiate() as Node
	if stage == null:
		errors.append("Causeway could not instantiate")
		return
	root.add_child(stage)
	await process_frame
	var underlay := stage.get_node_or_null("UnderlayRoot") as Node2D
	if underlay == null:
		errors.append("Causeway missing UnderlayRoot")
	else:
		if stage.get_node_or_null("UnderlayRoot/BackdropVoidFill") == null:
			errors.append("Causeway missing UnderlayRoot/BackdropVoidFill")
		if not is_equal_approx(underlay.modulate.a, 1.0):
			errors.append("Causeway UnderlayRoot alpha starts at %.3f, expected 1.0" % underlay.modulate.a)
	var controller := stage.get_node_or_null("VistaController") as SunderedKeepVistaController
	if controller == null:
		errors.append("Causeway missing VistaController")
	else:
		var vista_root_path := controller.get("vista_root_path") as NodePath
		if not String(vista_root_path).is_empty():
			errors.append("Causeway VistaController should not bind vista_root_path; got %s" % vista_root_path)
		controller.apply_progress(0.0)
		controller.apply_progress(1.0)
		if underlay != null and not is_equal_approx(underlay.modulate.a, 1.0):
			errors.append("Causeway UnderlayRoot alpha changed to %.3f after vista progress" % underlay.modulate.a)
	if stage.get_node_or_null("Collision/PathBoundaryCollision") == null:
		errors.append("Causeway missing collision rails")
	if stage.get_node_or_null("ExitToFrontGate") == null:
		errors.append("Causeway missing ExitToFrontGate")
	_check_bounds(stage, "Causeway", Vector2(2300.0, 1500.0), errors)
	stage.queue_free()
	await process_frame


func _check_bounds(stage: Node, label: String, expected_size: Vector2, errors: Array[String]) -> void:
	if not stage.has_method("get_camera_bounds"):
		errors.append("%s missing get_camera_bounds()" % label)
		return
	var bounds := stage.call("get_camera_bounds") as Rect2
	if not _vec2_nearly_equal(bounds.size, expected_size):
		errors.append("%s camera bounds size is %s, expected %s" % [label, bounds.size, expected_size])
	if _vec2_nearly_equal(bounds.size, Vector2(2400.0, 1600.0)):
		errors.append("%s is still using LevelStage fallback bounds" % label)


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon
