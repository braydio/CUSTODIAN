extends SceneTree


func _init() -> void:
	var scene := load("res://game/ui/hud/debug_screen.tscn") as PackedScene
	if scene == null:
		push_error("[DebugScreenSmoke] debug_screen.tscn did not load")
		quit(1)
		return
	var screen := scene.instantiate()
	if screen == null:
		push_error("[DebugScreenSmoke] debug_screen.tscn did not instantiate")
		quit(1)
		return
	root.add_child(screen)
	if not screen.has_method("set_debug_visible") or not screen.has_method("update_snapshot"):
		push_error("[DebugScreenSmoke] Debug screen API missing")
		quit(1)
		return
	screen.call("set_debug_visible", true)
	screen.call("update_snapshot", {
		"summary": "Smoke snapshot",
		"runtime": {"phase": "SMOKE", "time_scale": 1.0},
		"player": {"health": "100/100"},
		"combat": {"weapon": "Fists"},
		"world": {"scene": "smoke"},
		"systems": {"power": "ok"},
		"inventory": {"items": "empty"},
	})
	if not bool(screen.call("is_debug_visible")):
		push_error("[DebugScreenSmoke] Debug screen did not become visible")
		quit(1)
		return
	print("[DebugScreenSmoke] PASS")
	quit(0)
