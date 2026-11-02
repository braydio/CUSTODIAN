extends SceneTree
const GAME := preload("res://scenes/game.tscn")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var game := GAME.instantiate(); root.add_child(game); await process_frame; await process_frame
	var ui := game.get_node("UI"); ui.call("open_command_terminal"); await process_frame
	for page in ["POWER", "DEFENSE", "SENSORS", "POWER", "SENSORS", "DEFENSE"]:
		ui.call("_set_terminal_page", page); await process_frame
		var block := ui.find_child("MapPreviewBlock", true, false) as VBoxContainer
		var content := ui.find_child("Content", true, false) as VBoxContainer
		var widgets := ui.find_child("WidgetStack", true, false)
		assert(block != null and block.get_parent() == content)
		assert(block.get_node_or_null("MapPreview") != null and block.get_node_or_null("MapPreviewTitle") != null)
		assert(block.get_index() == widgets.get_index() + 1)
		var scroll := ui.find_child("MainContentScroll", true, false) as ScrollContainer
		var available_scroll := maxi(0, int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page))
		scroll.scroll_vertical = mini(37, available_scroll); var retained_scroll := scroll.scroll_vertical
		ui.call("_refresh_snapshot"); await process_frame; assert(scroll.scroll_vertical == retained_scroll)
	ui.call("_set_terminal_page", "POWER"); assert((ui.find_child("MainContentScroll", true, false) as ScrollContainer).scroll_vertical == 0)
	print("terminal_page_order_regression_smoke: PASS"); quit(0)
