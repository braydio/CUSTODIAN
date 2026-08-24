extends Node
class_name CommandTerminalTutorial

const EVENT_ID := &"command_terminal_repair_tutorial_complete"

var _power: Node = null
var _defense: Node = null
var _ui: Node = null
var _step := -1
var _hp_before_repair := 0.0


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if _step < 0:
		_try_setup()
		return
	if _step == 0 and _ui != null and bool(_ui.call("is_terminal_open")):
		_ui.call("append_terminal_tutorial_line", "LOCAL POWER RESERVE DEGRADED.", "warning")
		_ui.call("append_terminal_tutorial_line", "RUN STATUS.", "info")
		_step = 1


func _try_setup() -> void:
	var memory := get_node_or_null("/root/WorldEventMemory")
	if memory != null and memory.has_method("is_completed") and bool(memory.call("is_completed", EVENT_ID)):
		set_process(false)
		return
	_power = get_node_or_null("/root/GameRoot/Power")
	_defense = get_node_or_null("/root/GameRoot/World/Sectors/DEFENSE")
	_ui = get_node_or_null("/root/GameRoot/UI")
	if _power == null or _defense == null or _ui == null:
		return
	_defense.call("take_damage", 55.0)
	_power.set("total_power", maxf(float(_power.get("emergency_repair_power_cost")) + 15.0, 40.0))
	var callback := Callable(self, "_on_terminal_command_executed")
	if not _ui.is_connected("terminal_command_executed", callback):
		_ui.connect("terminal_command_executed", callback)
	_step = 0


func _on_terminal_command_executed(normalized_command: String, handled: bool) -> void:
	if _step == 1 and normalized_command == "STATUS" and handled:
		_ui.call("append_terminal_tutorial_line", "DEFENSE GRID INTEGRITY DEGRADED.", "warning")
		_ui.call("append_terminal_tutorial_line", "EMERGENCY REPAIR AUTHORIZED.", "info")
		_ui.call("append_terminal_tutorial_line", "RUN: REPAIR DEFENSE", "info")
		_hp_before_repair = float(_defense.get("current_health"))
		_step = 2
		return
	if _step != 2 or normalized_command != "REPAIR DEFENSE":
		return
	# The router has completed synchronously before this signal is emitted.
	if not handled or float(_defense.get("current_health")) <= _hp_before_repair:
		return
	var memory := get_node_or_null("/root/WorldEventMemory")
	if memory != null:
		memory.call("mark_completed", EVENT_ID, {"sector": "DEFENSE", "command": "REPAIR DEFENSE"})
	_ui.call("append_terminal_tutorial_line", "REPAIR CONFIRMED.", "success")
	_ui.call("append_terminal_tutorial_line", "LOCAL COMMAND AUTHORITY ACCEPTED.", "success")
	_step = 3
	set_process(false)


func get_tutorial_state() -> Dictionary:
	return {"step": _step, "hp_before_repair": _hp_before_repair}
