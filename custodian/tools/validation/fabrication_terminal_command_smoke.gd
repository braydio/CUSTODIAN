extends SceneTree

const UIScript := preload("res://game/ui/hud/ui.gd")
const RouterScript := preload("res://game/ui/terminal/terminal_command_router.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var resource_ledger := root.get_node_or_null("/root/ResourceLedger")
	var build_inventory := root.get_node_or_null("/root/BuildInventory")
	var fab_pipeline := root.get_node_or_null("/root/FabPipeline")
	if resource_ledger == null or build_inventory == null or fab_pipeline == null:
		push_error("[FabricationTerminalCommandSmoke] fabrication autoloads unavailable")
		quit(1)
		return

	resource_ledger.call("clear")
	build_inventory.call("clear")
	fab_pipeline.call("clear_jobs")

	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(UIScript)
	root.add_child(ui)
	await process_frame

	var router := RouterScript.new()
	var failures: Array[String] = []

	var grant_parsed := router.parse("FAB GRANT BLACKWOOD 10")
	if not bool(ui.call("_execute_local_terminal_command_legacy", grant_parsed)):
		failures.append("FAB GRANT command was not handled")
	if int(resource_ledger.call("get_amount", "blackwood")) != 10:
		failures.append("FAB GRANT did not normalize BLACKWOOD to blackwood")

	resource_ledger.call("add", "ruin_scrap", 25)
	resource_ledger.call("add", "structural_alloy", 8)
	resource_ledger.call("add", "power_components", 1)

	var start_parsed := router.parse("FAB START TURRET_BASIC")
	if not bool(ui.call("_execute_local_terminal_command_legacy", start_parsed)):
		failures.append("FAB START command was not handled")

	var jobs: Array = fab_pipeline.call("get_jobs_snapshot")
	if jobs.is_empty():
		failures.append("FAB START TURRET_BASIC did not start turret_basic recipe")
	else:
		var first_job := jobs[0] as Dictionary
		if String(first_job.get("recipe_id", "")) != "turret_basic":
			failures.append("started recipe id was %s instead of turret_basic" % String(first_job.get("recipe_id", "")))

	var terminal_lines: Array = ui.get("_terminal_lines")
	terminal_lines.clear()
	var reboot_parsed := router.parse("REBOOT")
	if not bool(ui.call("_execute_local_terminal_command_legacy", reboot_parsed)):
		failures.append("REBOOT command was not handled")
	if not terminal_lines.any(func(line): return str(line).contains("REBOOT PROTECTED")):
		failures.append("REBOOT without confirmation did not preserve the protected-command contract")
	if not router.is_known_verb("RESET") or not router.is_known_verb("REBOOT"):
		failures.append("RESET/REBOOT should be known protected system verbs")
	var reboot_confirmed := router.parse("REBOOT CONFIRM")
	if not bool(ui.call("_execute_local_terminal_command_legacy", reboot_confirmed)):
		failures.append("REBOOT CONFIRM command was not handled")
	var reboot_lines: Array = ui.get("_terminal_lines")
	if reboot_lines.size() <= 1:
		failures.append("REBOOT did not restore the terminal boot transcript")
	for line in reboot_lines:
		if not (line is String):
			failures.append("REBOOT restored a non-String terminal line")
			break

	if not failures.is_empty():
		for failure in failures:
			push_error("[FabricationTerminalCommandSmoke] %s" % failure)
		quit(1)
		return

	print("[FabricationTerminalCommandSmoke] ok")
	quit(0)
