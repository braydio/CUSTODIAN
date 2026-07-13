extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var ui := game.get_node_or_null("UI")
	_require(ui != null, "Main game scene should expose UI node.")
	if ui == null:
		game.queue_free()
		_finish()
		return

	ui.call("_apply_terminal_theme")
	_check_border_frame_style(ui.get_node_or_null("TerminalPanel"), "panel", "terminal panel")
	_check_stretched_center_style(ui.get_node_or_null("TerminalPanel/Header"), "panel", "terminal header")
	_check_border_frame_style(ui.find_child("MapOutput", true, false), "normal", "map output")
	_check_border_frame_style(ui.get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll"), "panel", "activity scroll")
	_check_stretched_center_style(ui.get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/TerminalInput"), "normal", "terminal input")
	_check_stretched_center_style(ui.find_child("OverviewButton", true, false), "normal", "nav button")
	_check_stretched_center_style(ui.find_child("WaitButton", true, false), "normal", "action button")

	ui.call("_set_terminal_page", "FABRICATION")
	await process_frame
	_check_border_frame_style(ui.get_node_or_null("TerminalPanel"), "panel", "fabrication terminal panel")
	_check_stretched_center_style(ui.get_node_or_null("TerminalPanel/Header"), "panel", "fabrication terminal header")
	_check_border_frame_style(ui.find_child("FabStatusPanel", true, false), "panel", "fabrication widget panel")
	_check_stretched_center_style(ui.find_child("CraftOneButton", true, false), "normal", "fabrication action button")

	game.queue_free()
	await process_frame
	_finish()


func _check_border_frame_style(control: Node, style_name: String, label: String) -> void:
	var style := _get_style(control, style_name, label)
	if style == null:
		return
	_require(
		style.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT,
		"%s should tile-fit horizontally." % label
	)
	_require(
		style.axis_stretch_vertical == StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT,
		"%s should tile-fit vertically." % label
	)
	_require(not style.draw_center, "%s should not draw a tiled center." % label)
	_require(
		_max_margin(style) <= 4.0,
		"%s should use small frame margins, got %s." % [label, _max_margin(style)]
	)


func _check_stretched_center_style(control: Node, style_name: String, label: String) -> void:
	var style := _get_style(control, style_name, label)
	if style == null:
		return
	_require(
		style.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH,
		"%s should stretch horizontally once, not tile." % label
	)
	_require(
		style.axis_stretch_vertical == StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH,
		"%s should stretch vertically once, not tile." % label
	)
	_require(style.draw_center, "%s should draw a single clean center." % label)
	_require(
		_max_margin(style) <= 4.0,
		"%s should use small frame margins, got %s." % [label, _max_margin(style)]
	)


func _get_style(control: Node, style_name: String, label: String) -> StyleBoxTexture:
	_require(control != null, "%s control should exist." % label)
	if control == null:
		return null
	_require(control is Control, "%s should be a Control." % label)
	if not (control is Control):
		return null
	var style := (control as Control).get_theme_stylebox(style_name) as StyleBoxTexture
	_require(style != null, "%s %s style should be a StyleBoxTexture." % [label, style_name])
	return style


func _max_margin(style: StyleBoxTexture) -> float:
	return maxf(
		maxf(style.texture_margin_left, style.texture_margin_right),
		maxf(style.texture_margin_top, style.texture_margin_bottom)
	)


func _finish() -> void:
	if _failed:
		print("[TerminalStyleboxRenderingSmoke] FAILED")
		quit(1)
		return
	print("[TerminalStyleboxRenderingSmoke] PASS")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerminalStyleboxRenderingSmoke] " + message)
