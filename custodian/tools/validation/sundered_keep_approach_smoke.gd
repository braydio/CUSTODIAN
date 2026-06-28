extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")

const EXPECTED_SPRITE_RECTS := {
	"PathSprites/MainlandApproachPath": Rect2(Vector2(-300, 120), Vector2(470, 400)),
	"PathSprites/HillClimbPath": Rect2(Vector2(-190, -120), Vector2(400, 240)),
	"PathSprites/OverlookLedge": Rect2(Vector2(-320, -320), Vector2(640, 200)),
	"PathSprites/LateralTraversePath": Rect2(Vector2(260, -260), Vector2(520, 180)),
	"PathSprites/FortressWallMass": Rect2(Vector2(650, -420), Vector2(350, 380)),
	"Occlusion/CliffOccluder": Rect2(Vector2(520, -420), Vector2(520, 540)),
	"Occlusion/WallShadowOccluder": Rect2(Vector2(-900, -360), Vector2(2100, 130)),
	"VistaUnderlay/UnderlayFogBand": Rect2(Vector2(-900, -620), Vector2(2100, 360)),
	"VistaUnderlay/DistantKeepProxy": Rect2(Vector2(-900, -680), Vector2(2100, 420)),
}


func _init() -> void:
	var scene := APPROACH_SCENE.instantiate() as Node2D
	if scene == null:
		_fail("Could not instantiate SunderedKeepApproach")
		return
	root.add_child(scene)
	await process_frame

	var errors: Array[String] = []

	var entry := scene.get_node_or_null("EntrySpawn") as Marker2D
	if entry == null:
		errors.append("EntrySpawn missing")
	elif entry.position != Vector2(-240, 420):
		errors.append("EntrySpawn expected (-240, 420), got %s" % entry.position)
	if scene.get_node_or_null("ProgressStart") == null:
		errors.append("ProgressStart missing")
	if scene.get_node_or_null("ProgressEnd") == null:
		errors.append("ProgressEnd missing")

	var backdrop := scene.get_node_or_null("ApproachVoidBackdrop") as ColorRect
	if backdrop == null:
		errors.append("ApproachVoidBackdrop missing")
	elif backdrop.color.a < 1.0:
		errors.append("ApproachVoidBackdrop should be opaque")

	for node_path: String in EXPECTED_SPRITE_RECTS:
		var sprite := scene.get_node_or_null(node_path) as Sprite2D
		if sprite == null:
			errors.append("%s missing or not Sprite2D" % node_path)
			continue
		if sprite.texture == null:
			errors.append("%s has null texture" % node_path)
			continue
		if sprite.centered:
			errors.append("%s should use centered=false" % node_path)
		_check_sprite_rect(node_path, sprite, EXPECTED_SPRITE_RECTS[node_path] as Rect2, errors)

	var cliff_start := scene.get_node_or_null("Occlusion/CliffOccluder") as CanvasItem
	if cliff_start == null or cliff_start.modulate.a > 0.01:
		errors.append("CliffOccluder should start hidden; alpha=%s" % (cliff_start.modulate.a if cliff_start else "missing"))
	var shadow_start := scene.get_node_or_null("Occlusion/WallShadowOccluder") as CanvasItem
	if shadow_start == null or shadow_start.modulate.a > 0.01:
		errors.append("WallShadowOccluder should start hidden; alpha=%s" % (shadow_start.modulate.a if shadow_start else "missing"))
	var fog_start := scene.get_node_or_null("VistaUnderlay/UnderlayFogBand") as CanvasItem
	if fog_start == null or fog_start.modulate.a < 0.24 or fog_start.modulate.a > 0.31:
		errors.append("UnderlayFogBand should start at low alpha around 0.25; alpha=%s" % (fog_start.modulate.a if fog_start else "missing"))

	var controller := scene.get_node_or_null("VistaController")
	if controller == null:
		errors.append("VistaController missing")
	else:
		if not controller.has_method("refresh_bindings"):
			errors.append("VistaController missing refresh_bindings()")
		if not controller.has_method("apply_progress"):
			errors.append("VistaController missing apply_progress()")
		var dummy_player := Node2D.new()
		dummy_player.name = "Operator"
		scene.add_child(dummy_player)
		controller.set("player_path", NodePath("../Operator"))
		controller.call("refresh_bindings")
		dummy_player.global_position = (scene.get_node("ProgressEnd") as Node2D).global_position
		controller.call("_process", 0.016)
		controller.call("apply_progress", 1.0)
		var cliff := scene.get_node_or_null("Occlusion/CliffOccluder") as CanvasItem
		var fog := scene.get_node_or_null("VistaUnderlay/UnderlayFogBand") as CanvasItem
		if cliff == null or cliff.modulate.a < 0.8:
			errors.append("VistaController did not raise cliff occluder alpha at ProgressEnd; alpha=%s" % (cliff.modulate.a if cliff else "missing"))
		if fog == null or fog.modulate.a < 0.65:
			errors.append("VistaController did not raise fog alpha at ProgressEnd; alpha=%s" % (fog.modulate.a if fog else "missing"))

	var trigger := scene.get_node_or_null("ExitTransitionTrigger") as Area2D
	if trigger == null:
		errors.append("ExitTransitionTrigger missing")
	elif String(trigger.get("target_scene_path")) != "res://game/world/sundered_keep/sundered_keep_map.gd":
		errors.append("ExitTransitionTrigger target path is wrong: %s" % String(trigger.get("target_scene_path")))
	elif trigger.get_node_or_null("CollisionShape2D") == null:
		errors.append("ExitTransitionTrigger missing CollisionShape2D")

	for body_name in ["PlayableCollision_Mainland", "PlayableCollision_Hill", "PlayableCollision_Overlook", "PlayableCollision_Lateral"]:
		var body := scene.get_node_or_null("Collision/%s" % body_name) as StaticBody2D
		if body == null:
			errors.append("%s missing" % body_name)
			continue
		var poly := body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if poly == null or poly.polygon.size() < 3:
			errors.append("%s collision polygon invalid" % body_name)

	if errors.is_empty():
		print("[SunderedKeepApproachSmoke] PASS")
		quit(0)
	else:
		for err in errors:
			push_error("[SunderedKeepApproachSmoke] %s" % err)
		_fail("%d checks failed" % errors.size())


func _fail(message: String) -> void:
	push_error("[SunderedKeepApproachSmoke] %s" % message)
	quit(1)


func _check_sprite_rect(node_path: String, sprite: Sprite2D, expected: Rect2, errors: Array[String]) -> void:
	if not _vec2_nearly_equal(sprite.position, expected.position):
		errors.append("%s position expected %s, got %s" % [node_path, expected.position, sprite.position])
	var rendered_size := Vector2(
		float(sprite.texture.get_width()) * sprite.scale.x,
		float(sprite.texture.get_height()) * sprite.scale.y
	)
	if not _vec2_nearly_equal(rendered_size, expected.size):
		errors.append("%s rendered size expected %s, got %s" % [node_path, expected.size, rendered_size])


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon
