extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")

const EXPECTED_SPRITES := {
	"PathSprites/MainlandApproachPath": Vector2(-300, 120),
	"PathSprites/HillClimbPath": Vector2(-190, -120),
	"PathSprites/OverlookLedge": Vector2(-320, -320),
	"PathSprites/LateralTraversePath": Vector2(260, -260),
	"PathSprites/FortressWallMass": Vector2(650, -420),
	"Occlusion/CliffOccluder": Vector2(520, -420),
	"Occlusion/WallShadowOccluder": Vector2(-900, -360),
	"VistaUnderlay/UnderlayFogBand": Vector2(-900, -620),
}


func _init() -> void:
	var scene := APPROACH_SCENE.instantiate() as Node2D
	if scene == null:
		_fail("Could not instantiate SunderedKeepApproach")
		return
	root.add_child(scene)
	await process_frame

	var errors: Array[String] = []

	if scene.get_node_or_null("EntrySpawn") == null:
		errors.append("EntrySpawn missing")
	if scene.get_node_or_null("ProgressStart") == null:
		errors.append("ProgressStart missing")
	if scene.get_node_or_null("ProgressEnd") == null:
		errors.append("ProgressEnd missing")

	for node_path: String in EXPECTED_SPRITES:
		var sprite := scene.get_node_or_null(node_path) as Sprite2D
		if sprite == null:
			errors.append("%s missing or not Sprite2D" % node_path)
			continue
		if sprite.texture == null:
			errors.append("%s has null texture" % node_path)
		if sprite.centered:
			errors.append("%s should use centered=false" % node_path)
		if sprite.position != EXPECTED_SPRITES[node_path]:
			errors.append("%s position expected %s, got %s" % [node_path, EXPECTED_SPRITES[node_path], sprite.position])

	var keep_proxy := scene.get_node_or_null("VistaUnderlay/DistantKeepProxy") as Sprite2D
	if keep_proxy == null or keep_proxy.texture == null:
		errors.append("VistaUnderlay/DistantKeepProxy missing texture")

	var controller := scene.get_node_or_null("VistaController")
	if controller == null:
		errors.append("VistaController missing")
	else:
		var dummy_player := Node2D.new()
		dummy_player.name = "Operator"
		scene.add_child(dummy_player)
		controller.set("player_path", NodePath("../Operator"))
		dummy_player.global_position = (scene.get_node("ProgressEnd") as Node2D).global_position
		controller.call("_process", 0.016)
		var cliff := scene.get_node_or_null("Occlusion/CliffOccluder") as CanvasItem
		var fog := scene.get_node_or_null("VistaUnderlay/UnderlayFogBand") as CanvasItem
		if cliff == null or cliff.modulate.a < 0.8:
			errors.append("VistaController did not raise cliff occluder alpha at ProgressEnd")
		if fog == null or fog.modulate.a < 0.65:
			errors.append("VistaController did not raise fog alpha at ProgressEnd")

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
