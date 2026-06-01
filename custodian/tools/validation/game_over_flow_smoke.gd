extends SceneTree

const MODAL_SCENE := preload("res://game/ui/game_over/game_over_modal.tscn")


func _init() -> void:
	var failures: Array[String] = []
	await process_frame

	var game_state := root.get_node_or_null("GameState")
	var game_stats := root.get_node_or_null("GameStats")
	if game_state == null:
		failures.append("GameState autoload missing")
	if game_stats == null:
		failures.append("GameStats autoload missing")

	if failures.is_empty():
		game_state.call("reset_run_state")
		game_stats.call("reset")
		game_stats.call("record_wave_survived", 3)
		game_stats.call("record_enemy_destroyed", "grunt")
		game_stats.call("record_enemy_destroyed", "drone")
		game_stats.call("record_power_failure")
		var snapshot: Dictionary = game_stats.call("get_snapshot")
		_assert_equal(snapshot.get("waves_survived", -1), 3, "waves_survived stat", failures)
		_assert_equal(snapshot.get("enemies_destroyed", -1), 2, "enemies_destroyed stat", failures)
		_assert_equal(snapshot.get("power_failures", -1), 1, "power_failures stat", failures)

		game_state.call("trigger_game_over", "Smoke test failure")
		await process_frame
		_assert_equal(game_state.get("game_over"), true, "game_over flag", failures)
		_assert_equal(paused, true, "tree paused", failures)
		var modal := _find_modal(root)
		if modal == null:
			failures.append("GameOverModal was not added to the scene tree")
		else:
			var reason_label := modal.get_node_or_null("Panel/Margin/Content/ReasonLabel")
			if reason_label == null or str(reason_label.text) != "Smoke test failure":
				failures.append("GameOverModal reason label did not update")

		game_state.call("reset_run_state")
		_assert_equal(paused, false, "tree unpaused after reset", failures)
		_assert_equal(game_state.get("game_over"), false, "game_over reset", failures)

	var standalone := MODAL_SCENE.instantiate()
	if standalone == null:
		failures.append("GameOverModal scene failed to instantiate")
	else:
		standalone.queue_free()

	if failures.is_empty():
		print("[game_over_flow_smoke] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[game_over_flow_smoke] " + failure)
		quit(1)


func _find_modal(node: Node) -> Node:
	if node.name == "GameOverModal":
		return node
	for child in node.get_children():
		var found := _find_modal(child)
		if found != null:
			return found
	return null


func _assert_equal(actual: Variant, expected: Variant, label: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, str(expected), str(actual)])
