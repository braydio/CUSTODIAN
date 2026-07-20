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
	var ui := game.get_node_or_null("UI")
	_require(ui != null, "game.tscn did not expose the terminal UI.")
	if ui == null:
		await _finish(game)
		return
	var lines: Array[String] = ui.call("_build_terminal_defense_coverage_lines", [
		{"name": "DEFENSE GRID", "status": "operational", "hp_pct": 0},
		{"name": "ARCHIVE", "status": "offline", "hp_pct": 80},
		{"name": "POWER", "status": "critical", "hp_pct": 50},
		{"name": "STORAGE", "status": "damaged", "hp_pct": 65},
	])
	_require(lines[0].contains("DESTROYED"), "Zero-health defense coverage was not classified DESTROYED.")
	_require(lines[1].contains("OFFLINE"), "Offline status was not preserved above nonzero health.")
	_require(lines[2].contains("CRITICAL"), "Critical status did not impose critical readiness.")
	_require(lines[3].contains("STRAINED"), "Damaged/low-health coverage was not classified STRAINED.")
	ui.call("open_command_terminal")
	ui.call("_set_terminal_page", "DEFENSE")
	ui.call("_refresh_snapshot")
	await process_frame
	var modes_body := ui.find_child("DefenseModesPanel", true, false).find_child("Body", true, false) as RichTextLabel
	var modes_text := modes_body.get_parsed_text() if modes_body != null else ""
	_require(modes_text.contains("CURRENT: FIRST CONTACT"), "Defense did not identify the current engagement policy.")
	_require(modes_text.contains("CONTROL: NOT EXPOSED"), "Unavailable engagement controls still appear selectable.")
	_require(not modes_text.contains("CLOSEST") and not modes_text.contains("HEAVIEST"), "Static fake engagement choices remain visible.")
	ui.call("close_command_terminal")
	await _finish(game)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerminalDefenseSemanticsSmoke] %s" % message)


func _finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	if _failed:
		quit(1)
		return
	print("[TerminalDefenseSemanticsSmoke] PASS")
	quit(0)
