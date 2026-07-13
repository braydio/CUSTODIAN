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
	ui.call("_set_terminal_widget_mode", "FABRICATION")
	ui.call("_render_terminal_fabrication_widgets")
	_require(bool(fabrication_widgets.visible), "FabricationWidgets should be visible in FABRICATION mode.")
	_require(not bool(settings_widgets.visible), "SettingsWidgets should not be visible in FABRICATION mode.")
	_require(recipe_rows.get_child_count() > 0, "Fabrication work orders should render as button rows.")
	_require(recipe_rows.get_child(0) is Button, "First work-order row should be a Button.")
	_require(not bool((craft_one as Button).disabled), "CraftOneButton should be enabled for affordable selected recipe.")

	(craft_one as Button).pressed.emit()
	await process_frame
	var jobs: Array = fab_pipeline.call("get_jobs_snapshot")
	_require(not jobs.is_empty(), "CraftOneButton should start a fabrication job.")
	if not jobs.is_empty():
		_require(str((jobs[0] as Dictionary).get("recipe_id", "")) == "turret_basic", "CraftOneButton should start selected recipe.")

	game.queue_free()
	await process_frame
	_finish()


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
