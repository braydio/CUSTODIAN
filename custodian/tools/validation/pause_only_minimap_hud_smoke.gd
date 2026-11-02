extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const SUNDERED_KEEP_HUD_SCENE := preload("res://game/ui/hud/custodian_hud.tscn")


func _init() -> void:
	var game := GAME_SCENE.instantiate()
	_assert(game.get_node_or_null("UI/Minimap") == null, "gameplay HUD still owns a minimap")
	var pause_minimap := game.get_node_or_null("PauseUI/PausePanel/Minimap") as Control
	_assert(pause_minimap != null, "pause menu minimap is missing")
	_assert(not bool(pause_minimap.get("enable_expand_toggle")), "pause minimap still accepts gameplay expand input")
	_assert(pause_minimap.custom_minimum_size == Vector2(500, 500), "pause minimap size drifted")

	var keep_hud := SUNDERED_KEEP_HUD_SCENE.instantiate()
	_assert(keep_hud.get_node_or_null("Root/TopRightPanel") == null, "Sundered Keep HUD still owns a minimap panel")
	for path in ["Root/TopLeftVitals", "Root/TopLeftLoadout", "Root/BottomLeftPrompt"]:
		var panel := keep_hud.get_node_or_null(path) as Control
		_assert(panel != null, "%s is missing" % path)
		_assert(panel.scale == Vector2(0.5, 0.5), "%s is not reduced to 25%% screen area" % path)

	game.free()
	keep_hud.free()
	print("[PauseOnlyMinimapHUDSmoke] PASS")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[PauseOnlyMinimapHUDSmoke] %s" % message)
	quit(1)
