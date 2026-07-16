extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ledger := root.get_node_or_null("/root/ResourceLedger")
	var build_inventory := root.get_node_or_null("/root/BuildInventory")
	var fab_pipeline := root.get_node_or_null("/root/FabPipeline")
	_require(ledger != null, "ResourceLedger autoload should exist.")
	_require(build_inventory != null, "BuildInventory autoload should exist.")
	_require(fab_pipeline != null, "FabPipeline autoload should exist.")
	if _failed:
		_finish()
		return

	ledger.call("clear")
	build_inventory.call("clear")
	fab_pipeline.call("clear_jobs")
	ledger.call("add", "ruin_scrap", 25)
	ledger.call("add", "structural_alloy", 8)
	ledger.call("add", "power_components", 1)

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

	var fabrication_widgets := ui.find_child("FabricationWidgets", true, false)
	var settings_widgets := ui.find_child("SettingsWidgets", true, false)
	var recipe_rows := ui.find_child("Rows", true, false)
	var craft_one := ui.find_child("CraftOneButton", true, false)
	_require(fabrication_widgets != null, "FabricationWidgets should exist under WidgetStack.")
	_require(settings_widgets != null, "SettingsWidgets should remain separate from FabricationWidgets.")
	_require(recipe_rows != null, "Fabrication recipe row container should exist.")
	_require(craft_one is Button, "CraftOneButton should be a Button.")

	ui.set("_terminal_fabrication_selected_work_order_id", "turret_basic")
	ui.call("_set_terminal_page", "FABRICATION")
	ui.call("_set_terminal_widget_mode", "FABRICATION")
	ui.call("_render_terminal_fabrication_widgets")
	_require(bool(fabrication_widgets.visible), "FabricationWidgets should be visible in FABRICATION mode.")
	_require(not bool(settings_widgets.visible), "SettingsWidgets should not be visible in FABRICATION mode.")
	_require(recipe_rows.get_child_count() > 0, "Fabrication work orders should render as button rows.")
	_require(recipe_rows.get_child(0) is Button, "First work-order row should be a Button.")
	var action_title := ui.get_node_or_null("TerminalPanel/Body/NavRail/ActionTitle") as Label
	_require(action_title != null and action_title.text == "TERMINAL ACTIONS", "Fabrication action rail should not be labeled READY BUILDS.")
	var first_row := recipe_rows.get_child(0) as Button
	_require(first_row.has_meta("fabrication_flat_row"), "Work-order rows should use the flat-row contract.")
	_require(first_row.get_theme_stylebox("normal") is StyleBoxFlat, "Work-order rows should use StyleBoxFlat instead of button art.")
	for label_name in ["StateLabel", "NameLabel", "CategoryLabel", "CostLabel"]:
		_require(first_row.find_child(label_name, true, false) is Label, "Work-order row should expose %s." % label_name)
	var selected_body := ui.find_child("FabSelectedRecipePanel", true, false).find_child("Body", true, false) as RichTextLabel
	_require(selected_body.get_parsed_text().strip_edges().begins_with("BASIC TURRET"), "Selected detail should begin with the selected work-order name.")
	_require(selected_body.get_parsed_text().contains("STATE") and selected_body.get_parsed_text().contains("CATEGORY") and selected_body.get_parsed_text().contains("RESULT"), "Selected detail should expose state, category, and result before cost.")
	_require(selected_body.get_parsed_text().contains("NEED"), "Selected detail should render a NEED/HAVE/MISSING resource grid.")
	_require(selected_body.get_parsed_text().contains("MISSING"), "Selected detail should render missing-resource values.")
	var terminal_output := ui.get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll/TerminalOutput") as RichTextLabel
	_require(terminal_output != null and terminal_output.get_parsed_text().contains("SELECT WORK ORDER"), "Fabrication Control should show idle work-order guidance.")
	_require(terminal_output != null and terminal_output.get_parsed_text().contains("TO MAX crafts until capped or resources fail"), "Fabrication Control should explain TO MAX while idle.")
	var ready_panel := ui.find_child("FabReadyBuildPanel", true, false) as Control
	var progress_body := ui.find_child("FabProgressPanel", true, false).find_child("Body", true, false) as RichTextLabel
	_require(ready_panel != null and not ready_panel.visible, "Empty ready-build panel should collapse into the shared status strip.")
	_require(progress_body.get_parsed_text().contains("IN PROGRESS: NONE"), "Compact bottom strip should report no active jobs.")
	_require(progress_body.get_parsed_text().contains("READY BUILDS: NONE"), "Compact bottom strip should report no ready builds.")
	_require(not bool((craft_one as Button).disabled), "CraftOneButton should be enabled for affordable selected recipe.")

	ui.set("_terminal_fabrication_selected_work_order_id", "archive_sensor_pylon")
	ui.call("_render_terminal_fabrication_widgets")
	await process_frame
	var archive_button := _find_recipe_button(recipe_rows, "archive_sensor_pylon")
	_require(archive_button != null and archive_button.button_pressed, "Selected detail should correspond to a highlighted work-order row.")
	_require(str(ui.get("_terminal_fabrication_selected_work_order_id")) == "archive_sensor_pylon", "Resolved selected work order should remain synchronized with the highlighted row.")

	ui.set("_terminal_fabrication_selected_work_order_id", "lattice_field_patch")
	ui.call("_render_terminal_fabrication_widgets")
	await process_frame
	selected_body = ui.find_child("FabSelectedRecipePanel", true, false).find_child("Body", true, false) as RichTextLabel
	_require(selected_body.get_parsed_text().strip_edges().begins_with("LATTICE FIELD PATCH"), "Field Patch detail should begin with its selected work-order name.")
	_require(selected_body.get_parsed_text().contains("CARRY") and selected_body.get_parsed_text().contains("PATCH 1/2"), "Field Patch detail should expose PATCH current/max carry state.")

	ui.set("_terminal_fabrication_selected_work_order_id", "turret_basic")
	ledger.call("clear")
	ui.call("_render_terminal_fabrication_widgets")
	await process_frame
	craft_one = ui.find_child("CraftOneButton", true, false)
	_require(bool((craft_one as Button).disabled), "CraftOneButton should remain visibly disabled when materials are missing.")
	ledger.call("add", "ruin_scrap", 25)
	ledger.call("add", "structural_alloy", 8)
	ledger.call("add", "power_components", 1)
	ui.call("_render_terminal_fabrication_widgets")
	await process_frame
	craft_one = ui.find_child("CraftOneButton", true, false)
	_require(not bool((craft_one as Button).disabled), "CraftOneButton should re-enable after required materials are restored.")

	(craft_one as Button).pressed.emit()
	await process_frame
	var jobs: Array = fab_pipeline.call("get_jobs_snapshot")
	_require(not jobs.is_empty(), "CraftOneButton should start a fabrication job.")
	if not jobs.is_empty():
		_require(str((jobs[0] as Dictionary).get("recipe_id", "")) == "turret_basic", "CraftOneButton should start selected recipe.")
	ui.call("_render_terminal_fabrication_widgets")
	await process_frame
	var terminal_body := ui.get_node_or_null("TerminalPanel/Body") as Control
	var action_row := ui.find_child("ActionRow", true, false) as Control
	_require(ready_panel.visible, "Active fabrication should expand the progress/ready list region.")
	if terminal_body != null and action_row != null:
		_require(action_row.get_global_rect().end.y <= terminal_body.get_global_rect().end.y + 1.0, "Expanded fabrication status should keep the action row inside the terminal body.")

	game.queue_free()
	await process_frame
	_finish()


func _find_recipe_button(rows: Node, recipe_id: String) -> Button:
	for child in rows.get_children():
		if child is Button and str(child.get_meta("recipe_id", "")) == recipe_id:
			return child as Button
	return null


func _finish() -> void:
	if _failed:
		print("[FabricationTerminalClickableSmoke] FAILED")
		quit(1)
		return
	print("[FabricationTerminalClickableSmoke] ok")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[FabricationTerminalClickableSmoke] " + message)
