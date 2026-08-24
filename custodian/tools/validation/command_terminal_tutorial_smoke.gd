extends SceneTree
const GAME := preload("res://scenes/game.tscn")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var memory := root.get_node("WorldEventMemory"); memory.call("reset_run_events", 77)
	var game := GAME.instantiate(); root.add_child(game); await process_frame; await process_frame
	var tutorial := game.get_node("CommandTerminalTutorial"); var ui := game.get_node("UI"); var power := game.get_node("Power"); var defense := game.get_node("World/Sectors/DEFENSE")
	assert(float(defense.get("current_health")) == 45.0); assert(float(power.get("total_power")) >= float(power.get("emergency_repair_power_cost")))
	ui.call("open_command_terminal"); await process_frame; assert(int(tutorial.call("get_tutorial_state").step) == 1)
	ui.call("_execute_terminal_command_buffered", ui.call("_parse_terminal_command", "STATUS")); assert(int(tutorial.call("get_tutorial_state").step) == 2)
	var hp_before := float(defense.get("current_health")); var power_before := float(power.get("total_power"))
	ui.call("_execute_terminal_command_buffered", ui.call("_parse_terminal_command", "REPAIR DEFENSE"))
	assert(float(defense.get("current_health")) > hp_before); assert(float(power.get("total_power")) < power_before)
	assert(memory.call("is_completed", &"command_terminal_repair_tutorial_complete"))
	print("command_terminal_tutorial_smoke: PASS"); quit(0)
