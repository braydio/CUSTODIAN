extends Control

const DEFAULT_MENU_SCENE := "res://ui/main_menu.tscn"

@onready var reason_label: Label = get_node_or_null("Panel/Margin/Content/ReasonLabel")
@onready var waves_label: Label = get_node_or_null("Panel/Margin/Content/StatsContainer/WavesLabel")
@onready var enemies_label: Label = get_node_or_null("Panel/Margin/Content/StatsContainer/EnemiesLabel")
@onready var power_failures_label: Label = get_node_or_null("Panel/Margin/Content/StatsContainer/PowerFailuresLabel")
@onready var turrets_lost_label: Label = get_node_or_null("Panel/Margin/Content/StatsContainer/TurretsLostLabel")
@onready var restart_button: Button = get_node_or_null("Panel/Margin/Content/ButtonContainer/RestartButton")
@onready var menu_button: Button = get_node_or_null("Panel/Margin/Content/ButtonContainer/MenuButton")

var _reason: String = "Facility lost"
var _stats: Dictionary = {}
var _menu_scene_path: String = DEFAULT_MENU_SCENE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = true
	if restart_button != null and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button != null and not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.pressed.connect(_on_menu_pressed)
	_refresh()
	if restart_button != null:
		restart_button.grab_focus.call_deferred()


func configure(reason: String, stats: Dictionary, menu_scene_path: String = DEFAULT_MENU_SCENE) -> void:
	_reason = reason.strip_edges()
	if _reason.is_empty():
		_reason = "Facility lost"
	_stats = stats.duplicate(true)
	_menu_scene_path = menu_scene_path if not menu_scene_path.strip_edges().is_empty() else DEFAULT_MENU_SCENE
	if is_inside_tree():
		_refresh()


func _refresh() -> void:
	if reason_label != null:
		reason_label.text = _reason
	if waves_label != null:
		waves_label.text = "Waves Survived: %d" % int(_stats.get("waves_survived", 0))
	if enemies_label != null:
		enemies_label.text = "Enemies Destroyed: %d" % int(_stats.get("enemies_destroyed", 0))
	if power_failures_label != null:
		power_failures_label.text = "Power Failures: %d" % int(_stats.get("power_failures", 0))
	if turrets_lost_label != null:
		turrets_lost_label.text = "Turrets Lost: %d" % int(_stats.get("turrets_lost", 0))


func _on_restart_pressed() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("reset_run_state"):
		game_state.call("reset_run_state")
	else:
		get_tree().paused = false
	if get_tree().current_scene != null:
		get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("reset_run_state"):
		game_state.call("reset_run_state")
	else:
		get_tree().paused = false
	if ResourceLoader.exists(_menu_scene_path):
		get_tree().change_scene_to_file(_menu_scene_path)
	else:
		var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
		if ResourceLoader.exists(main_scene):
			get_tree().change_scene_to_file(main_scene)
		else:
			get_tree().reload_current_scene()
