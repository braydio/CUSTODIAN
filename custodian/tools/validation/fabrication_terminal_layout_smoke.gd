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

	var terminal_panel := ui.get_node_or_null("TerminalPanel") as Control
	if terminal_panel != null:
		terminal_panel.visible = true
	ui.call("_set_terminal_page", "FABRICATION")
	ui.call("_set_terminal_widget_mode", "FABRICATION")
	ui.call("_render_terminal_fabrication_widgets")
	await process_frame
	await process_frame

	var fabrication_widgets := ui.find_child("FabricationWidgets", true, false) as Control
	_require(fabrication_widgets != null, "FabricationWidgets should exist.")
	_require(fabrication_widgets == null or fabrication_widgets.visible, "FabricationWidgets should be visible.")
	if fabrication_widgets != null:
		_check_no_visible_child_overflow(fabrication_widgets)

	for scroll in ui.find_children("*", "ScrollContainer", true, false):
		if not (scroll is ScrollContainer):
			continue
		var scroll_container := scroll as ScrollContainer
		if fabrication_widgets != null and (scroll_container == fabrication_widgets or fabrication_widgets.is_ancestor_of(scroll_container) or scroll_container.name == "MainContentScroll"):
			_require(
				scroll_container.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
				"%s should have horizontal scroll disabled." % scroll_container.name
			)

	var recipe_scroll := ui.find_child("RecipeScroll", true, false) as ScrollContainer
	_require(recipe_scroll != null, "RecipeScroll should exist.")
	if recipe_scroll != null:
		_require(recipe_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "RecipeScroll should allow vertical scrolling.")

	var action_row := ui.find_child("ActionRow", true, false) as Control
	_require(action_row != null, "ActionRow should exist.")
	if action_row != null:
		_require(action_row.size.y >= 40.0, "ActionRow should remain tall enough for buttons.")

	game.queue_free()
	await process_frame
	_finish()


func _check_no_visible_child_overflow(root_control: Control) -> void:
	var right_edge := root_control.global_position.x + root_control.size.x + 2.0
	for child in root_control.find_children("*", "Control", true, false):
		if not (child is Control):
			continue
		var control := child as Control
		if not control.is_visible_in_tree():
			continue
		var child_right := control.global_position.x + control.size.x
		_require(
			child_right <= right_edge,
			"%s exceeds FabricationWidgets width by %.1f px." % [control.name, child_right - right_edge]
		)


func _finish() -> void:
	if _failed:
		print("[FabricationTerminalLayoutSmoke] FAILED")
		quit(1)
		return
	print("[FabricationTerminalLayoutSmoke] PASS")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[FabricationTerminalLayoutSmoke] " + message)
