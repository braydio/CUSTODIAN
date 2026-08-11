extends SceneTree

const GAME_SCENE_PATH := "res://scenes/game.tscn"
const RETICLE_SCENE := preload("res://game/ui/hud/components/ranged_reticle.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var hud := Control.new()
	root.add_child(hud)
	var intent := RETICLE_SCENE.instantiate() as Control
	hud.add_child(intent)
	await process_frame
	intent.position = Vector2(300.0, 200.0)
	intent.call("set_weapon_status", {
		"ranged_posture": "ready",
		"ranged_transition_ratio": 1.0,
		"ranged_aim_accuracy_ratio": 1.0,
	})
	if not intent.visible:
		failures.append("single ranged intent reticle did not become visible in ready posture")
	if intent.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("intent reticle can intercept input")

	var game_source := FileAccess.get_file_as_string(GAME_SCENE_PATH)
	if game_source.contains("RangedBallisticPip") \
	or game_source.contains("ranged_ballistic_pip"):
		failures.append("production game scene still wires the retired ballistic pip")

	intent.visible = false
	if intent.visible:
		failures.append("HUD hiding did not hide the ranged intent reticle")
	hud.queue_free()
	await process_frame
	if failures.is_empty():
		print("ranged_ballistic_reticle_smoke: PASS (single intent reticle)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
