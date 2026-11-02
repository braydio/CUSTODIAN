extends SceneTree

const UIScript := preload("res://game/ui/hud/ui.gd")
const HUDScene := preload("res://game/ui/hud/custodian_hud.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := HUDScene.instantiate()
	if hud == null:
		push_error("[TerminalOverlayVisibilitySmoke] CustodianHUD did not instantiate")
		quit(1)
		return
	root.add_child(hud)
	await process_frame
	if not hud.is_in_group("gameplay_overlay"):
		push_error("[TerminalOverlayVisibilitySmoke] CustodianHUD is not registered as gameplay_overlay")
		quit(1)
		return

	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(UIScript)
	root.add_child(ui)
	if not ui.has_method("open_command_terminal") or not ui.has_method("close_command_terminal"):
		push_error("[TerminalOverlayVisibilitySmoke] UI terminal API missing")
		quit(1)
		return
	if not ui.has_method("_set_debug_screen_visible"):
		push_error("[TerminalOverlayVisibilitySmoke] UI debug visibility API missing")
		quit(1)
		return

	ui.call("_set_debug_screen_visible", true)
	var debug_screen := ui.get_node_or_null("DebugScreen")
	if debug_screen == null or not bool(debug_screen.call("is_debug_visible")):
		push_error("[TerminalOverlayVisibilitySmoke] Debug screen did not become visible before terminal open")
		quit(1)
		return

	ui.call("open_command_terminal")
	if hud.visible:
		push_error("[TerminalOverlayVisibilitySmoke] CustodianHUD remained visible while terminal was open")
		quit(1)
		return
	if bool(debug_screen.call("is_debug_visible")):
		push_error("[TerminalOverlayVisibilitySmoke] Debug screen remained visible while terminal was open")
		quit(1)
		return

	ui.call("close_command_terminal")
	if not hud.visible:
		push_error("[TerminalOverlayVisibilitySmoke] CustodianHUD did not restore after terminal close")
		quit(1)
		return
	if not bool(debug_screen.call("is_debug_visible")):
		push_error("[TerminalOverlayVisibilitySmoke] Debug screen desired visibility did not restore after terminal close")
		quit(1)
		return

	print("[TerminalOverlayVisibilitySmoke] PASS")
	quit(0)
