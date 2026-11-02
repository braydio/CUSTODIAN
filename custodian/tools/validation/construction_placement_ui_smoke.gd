extends SceneTree

const UI_SCRIPT := preload("res://game/ui/hud/ui.gd")
const HUD_SCENE := preload("res://game/ui/construction/construction_placement_hud.tscn")


class TerminalBackgroundStub:
	extends Control

	func initialize() -> void:
		pass

	func generate_new() -> void:
		pass


var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(UI_SCRIPT)
	var terminal := Panel.new()
	terminal.name = "TerminalPanel"
	terminal.position = Vector2(120, 80)
	terminal.size = Vector2(800, 600)
	ui.add_child(terminal)
	var body := Control.new()
	body.name = "Body"
	terminal.add_child(body)
	var command_column := Control.new()
	command_column.name = "CommandColumn"
	body.add_child(command_column)
	var input_row := Control.new()
	input_row.name = "InputRow"
	command_column.add_child(input_row)
	var terminal_input := LineEdit.new()
	terminal_input.name = "TerminalInput"
	input_row.add_child(terminal_input)
	var background := TerminalBackgroundStub.new()
	background.name = "TerminalBackground"
	ui.add_child(background)
	var hud := HUD_SCENE.instantiate()
	ui.add_child(hud)
	game_root.add_child(ui)
	await process_frame
	ui.set("_terminal_open", true)
	ui.set("_terminal_current_page", "FABRICATION")
	var original_position := terminal.position
	var original_size := terminal.size
	var snapshot := {
		"build_id": &"capacitor_bank_mk1",
		"display_name": "Capacitor Bank Mk I",
		"category": &"power",
		"ready_count": 1,
		"footprint_tiles": Vector2i(3, 2),
		"rotation_degrees": 0,
		"valid": false,
		"message": "OUTSIDE CONSTRUCTION ZONE",
	}
	ui.call("enter_construction_placement_ui", snapshot)
	_require(not bool(ui.call("is_terminal_open")), "construction start did not close terminal")
	_require(not terminal.visible, "terminal shell remained visible")
	_require(terminal.position == original_position and terminal.size == original_size, "terminal was crushed into legacy placement strip")
	_require(hud.visible, "construction HUD did not become visible")
	_require(str(hud.get_node("Rows/Title").text) == "CAPACITOR BANK MK I", "HUD omitted structure name")
	_require(str(hud.get_node("Rows/FootprintRow/Footprint").text).contains("3×2"), "HUD omitted footprint")
	_require(str(hud.get_node("Rows/FootprintRow/Rotation").text).contains("0°"), "HUD omitted rotation")
	_require(str(hud.get_node("Rows/Status").text).contains("OUTSIDE CONSTRUCTION ZONE"), "HUD omitted validation reason")
	ui.call("exit_construction_placement_ui", true)
	_require(not hud.visible, "cancel did not hide construction HUD")
	_require(bool(ui.call("is_terminal_open")), "cancel did not reopen terminal")
	_require(str(ui.get("_terminal_current_page")) == "FABRICATION", "cancel did not return to FABRICATION")
	ui.call("enter_construction_placement_ui", snapshot)
	ui.call("exit_construction_placement_ui", false)
	_require(not bool(ui.call("is_terminal_open")), "successful exit reopened terminal")
	_require(not hud.visible, "successful exit left construction HUD visible")
	_require(not bool(ui.get("_main_hud_hidden")), "ordinary gameplay HUD was not restored")
	game_root.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("[ConstructionPlacementUISmoke] %s" % message)


func _finish() -> void:
	if failed:
		quit(1)
		return
	print("[ConstructionPlacementUISmoke] PASS")
	quit(0)
