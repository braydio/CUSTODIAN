extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")

var _failed := false


func _init() -> void:
	root.size = Vector2i(1366, 768)
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var power := game.get_node_or_null("Power")
	var ui := game.get_node_or_null("UI")
	_require(power != null, "game.tscn did not expose the authoritative Power system.")
	_require(ui != null, "game.tscn did not expose the terminal UI.")
	if power == null or ui == null:
		await _finish(game)
		return
	power.set_process(false)
	power.set("power_generation_rate", 20.0)
	power.set("power_consumption_rate", 60.0)
	ui.call("open_command_terminal")
	ui.call("_set_terminal_page", "OVERVIEW")
	ui.call("_refresh_snapshot")
	await process_frame
	var snapshot: Dictionary = ui.get("_terminal_snapshot")
	var power_status: Dictionary = snapshot.get("power_status", {})
	_require(is_equal_approx(float(power_status.get("net_per_second", 0.0)), -40.0), "Live terminal snapshot did not preserve the authoritative negative net rate.")
	_require((snapshot.get("sectors", []) as Array).size() == 6, "Live snapshot did not resolve exactly the six authored sectors.")
	var body := ui.find_child("OverviewContractPanel", true, false).find_child("Body", true, false) as RichTextLabel
	_require(body != null and body.get_parsed_text().contains("OPEN POWER // CORRECT DEFICIT"), "Live Overview recommendation copy did not identify the grid deficit.")
	if body != null:
		body.meta_clicked.emit("terminal_action:open_power")
		await process_frame
		_require(String(ui.get("_terminal_current_page")) == "POWER", "Live Overview power recommendation did not route through terminal_action:open_power.")
	ui.call("close_command_terminal")
	await _finish(game)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerminalOverviewLiveSnapshotSmoke] %s" % message)


func _finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	if _failed:
		quit(1)
		return
	print("[TerminalOverviewLiveSnapshotSmoke] PASS")
	quit(0)
