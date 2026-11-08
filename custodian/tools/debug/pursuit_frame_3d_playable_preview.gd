extends Node2D
## Development-only playable preview for the Pursuit Frame 3D candidate.
##
## Instances the real combat playground (real controllable Operator, arena walls)
## and spawns two real pursuit_frame.tscn actors under identical conditions:
## a legacy reference and a candidate. Only the candidate carries the debug adapter.
## Nothing here is loaded by production scenes.
##
## Controls (chosen to avoid the project's existing bindings):
##   F1          candidate / legacy presentation (candidate actor)
##   Enter       gameplay mapping / action inspection
##   [ ]         previous / next inspected action (inspection mode)
##   , .         previous / next inspected direction (inspection mode)
##   ; '         step frame back / forward
##   - =         playback FPS down / up
##   N           game scale (50 px/m) / native 1:1 (80 px/m)
##   /           pause / resume enemy AI on both actors
##   F12         screenshot to the screenshot directory

const PLAYGROUND := preload("res://scenes/debug/combat_playground.tscn")
const PURSUIT_FRAME := preload("res://game/actors/enemies/pursuit_frame.tscn")
const ADAPTER := preload("res://tools/debug/pursuit_frame_3d_candidate_adapter.gd")

var playground: Node
var legacy_enemy: CharacterBody2D
var candidate_enemy: CharacterBody2D
var adapter: PursuitFrame3DCandidateAdapter
var hud: Label
var _screenshot_dir := "user://pf3d_screenshots"
var _shot_request := ""


func _ready() -> void:
	playground = PLAYGROUND.instantiate()
	add_child(playground)
	var enemies: Node2D = playground.get_node("World/Enemies")
	for child in enemies.get_children():
		enemies.remove_child(child)
		child.queue_free()
	legacy_enemy = PURSUIT_FRAME.instantiate()
	legacy_enemy.name = "PursuitFrameLegacy"
	legacy_enemy.position = Vector2(-70.0, -60.0)  # inside the Pursuit Frame awareness bubble of the Operator (225 px)
	enemies.add_child(legacy_enemy)
	candidate_enemy = PURSUIT_FRAME.instantiate()
	candidate_enemy.name = "PursuitFrameCandidate"
	candidate_enemy.position = Vector2(-70.0, 60.0)
	enemies.add_child(candidate_enemy)
	adapter = ADAPTER.new()
	adapter.name = "CandidateBody"
	candidate_enemy.add_child(adapter)
	_build_hud()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pf3d-screenshot-dir="):
			_screenshot_dir = arg.trim_prefix("--pf3d-screenshot-dir=")


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(12.0, 12.0)
	hud.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	hud.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	hud.add_theme_constant_override("outline_size", 4)
	layer.add_child(hud)


func _process(_delta: float) -> void:
	var bsm = candidate_enemy.get("behavior_state_machine")
	var state := String(bsm.get("current_state")) if bsm != null else "?"
	hud.text = "PURSUIT FRAME 3D PREVIEW  [dev only]\n" \
		+ "presentation (F1): %s   mode (Enter): %s   scale (N): %.3f%s\n" % [
			adapter.presentation, adapter.mode, adapter.current_display_scale(),
			"  paused (/)" if adapter.paused else "",
		] \
		+ "candidate state: %s   legacy action: %s\n" % [state, legacy_enemy.get_enemy_presentation_action()] \
		+ "3D clip: %s   dir: %s   frame: %d   fps: %.1f\n" % [
			adapter.clip_name, adapter.last_dir, adapter.frame_index, adapter._current_fps(),
		] \
		+ adapter.label \
		+ "\n[ ] action  , . direction  ; ' step  - = fps  F12 screenshot"


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			adapter.toggle_presentation()
		KEY_ENTER, KEY_KP_ENTER:
			adapter.toggle_mode()
		KEY_BRACKETLEFT:
			adapter.cycle_inspect_action(-1)
		KEY_BRACKETRIGHT:
			adapter.cycle_inspect_action(1)
		KEY_COMMA:
			adapter.cycle_inspect_direction(-1)
		KEY_PERIOD:
			adapter.cycle_inspect_direction(1)
		KEY_SEMICOLON:
			adapter.step_frame(-1)
		KEY_APOSTROPHE:
			adapter.step_frame(1)
		KEY_MINUS:
			adapter.adjust_fps(-2.0)
		KEY_EQUAL:
			adapter.adjust_fps(2.0)
		KEY_N:
			adapter.toggle_native_scale()
		KEY_SLASH:
			adapter.toggle_paused()
			legacy_enemy.set_physics_process(not adapter.paused)
		KEY_F12:
			_shot_request = "%s/pf3d_%s.png" % [_screenshot_dir, Time.get_datetime_string_from_system(false, true).replace(":", "-")]
			_capture_screenshot.call_deferred()


func _capture_screenshot() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_screenshot_dir))
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(_shot_request) if _shot_request.begins_with("user://") else _shot_request)
