extends SceneTree

const SunderedKeepMapScript := preload("res://game/world/sundered_keep/sundered_keep_map.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_map := Node2D.new()
	main_map.name = "SmokeMainMap"
	root.add_child(main_map)

	var map := SunderedKeepMapScript.new()
	map.name = "SmokeSunderedKeep"
	root.add_child(map)
	await process_frame

	var hud := map.get_node_or_null("SunderedKeepCustodianHUD")
	_assert(hud != null, "Sundered Keep HUD was not created")
	_assert(not hud.visible, "Sundered Keep HUD showed while player was on the main map")

	var actor := Node2D.new()
	actor.name = "SmokeActor"
	root.add_child(actor)
	map.call("configure_connection", main_map, Vector2(96, 128))
	map.call("enter_from_main", actor)
	_assert(hud.visible, "Sundered Keep HUD did not show after entering the keep")

	hud.call("set_external_overlay_hidden", true)
	_assert(not hud.visible, "terminal-style suppression did not hide Sundered Keep HUD")
	hud.call("set_external_overlay_hidden", false)
	_assert(hud.visible, "Sundered Keep HUD did not restore while still in the keep")

	map.call("return_to_main", actor)
	_assert(not hud.visible, "Sundered Keep HUD remained visible after returning to main map")
	hud.call("set_external_overlay_hidden", true)
	hud.call("set_external_overlay_hidden", false)
	_assert(not hud.visible, "overlay restoration re-shown inactive Sundered Keep HUD")

	print("[SunderedKeepHUDScopeSmoke] PASS")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[SunderedKeepHUDScopeSmoke] %s" % message)
	quit(1)
