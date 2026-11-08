extends SceneTree
## Windowed evidence capture for the Pursuit Frame 3D playable preview.
##
## Requires a display (run without --headless). Output and telemetry go to the directory
## passed after `--`, never into the repository.
##
##   --pf3d-mode=chase    real gameplay chase; the Operator is led around an ellipse so the
##                        chase continues and the travel direction changes. The world stops
##                        if the Operator is caught, so captures end at that point.
##   --pf3d-mode=inspect  frozen AI; running clip in all eight directions plus a zoomed
##                        contact close-up of the candidate's feet on its shadow.
##
## Run: godot --path custodian --script res://tools/debug/pursuit_frame_3d_capture.gd -- \
##        --pf3d-mode=inspect --pf3d-out=/abs/dir --pf3d-telemetry=/abs/dir/telemetry.jsonl

const PREVIEW_SCENE := preload("res://scenes/debug/pursuit_frame_3d_playable_preview.tscn")
const ADAPTER := preload("res://tools/debug/pursuit_frame_3d_candidate_adapter.gd")
const CHASE_FRAMES := 720
const CAPTURE_EVERY := 6
const DIRECTION_HOLD := 12
const CLOSEUP_ZOOM := 4.0

var _out := ""
var _mode := "chase"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pf3d-out="):
			_out = arg.trim_prefix("--pf3d-out=")
		elif arg.begins_with("--pf3d-mode="):
			_mode = arg.trim_prefix("--pf3d-mode=")
	assert(_out != "", "pass --pf3d-out=<absolute directory>")
	DirAccess.make_dir_recursive_absolute(_out)
	_run()


func _run() -> void:
	var preview: Node2D = PREVIEW_SCENE.instantiate()
	root.add_child(preview)
	for i in 10:
		await process_frame
	if _mode == "inspect":
		await _inspect(preview)
	else:
		await _chase(preview)
	quit(0)


func _chase(preview: Node2D) -> void:
	var operator: Node2D = preview.playground.get_node("World/Operator")
	var index := 0
	for i in CHASE_FRAMES:
		# Automated stand-in for the player: lead the Pursuit Frame around an ellipse.
		var t := float(i) * 0.6 / 60.0
		operator.global_position = Vector2(280.0 * cos(t), 170.0 * sin(t))
		await process_frame
		if i % CAPTURE_EVERY == 0:
			await _save("%s/chase_%04d.png" % [_out, index])
			index += 1
	print("CAPTURE_DONE mode=chase frames=%d out=%s" % [index, _out])


func _inspect(preview: Node2D) -> void:
	var adapter = preview.adapter
	var candidate: CharacterBody2D = preview.candidate_enemy
	var camera: Camera2D = preview.playground.get_node("World/Camera2D")
	# Freeze the AI so the stills are stable: place the candidate beside the Operator.
	preview.legacy_enemy.set_physics_process(false)
	adapter.set_paused(true)
	var operator: Node2D = preview.playground.get_node("World/Operator")
	operator.global_position = Vector2(-330.0, 0.0)
	candidate.global_position = Vector2(-150.0, 40.0)
	preview.legacy_enemy.global_position = Vector2(-150.0, -120.0)
	adapter.set_mode(&"inspect")
	adapter.inspect_action_index = ADAPTER.INSPECT_ACTIONS.find("running")
	for d in 8:
		adapter.inspect_dir_index = d
		for i in DIRECTION_HOLD:
			adapter.advance(1.0 / 24.0)
			await process_frame
		await _save("%s/inspect_running_%s.png" % [_out, ADAPTER.COMPASS[d]])
	# Walk clip for the walking-to-running comparison.
	adapter.inspect_action_index = ADAPTER.INSPECT_ACTIONS.find("walking")
	adapter.inspect_dir_index = 2
	for i in DIRECTION_HOLD:
		adapter.advance(1.0 / 24.0)
		await process_frame
	await _save("%s/inspect_walking_S.png" % _out)
	# Contact close-up at native 1:1 texture scale.
	adapter.inspect_action_index = ADAPTER.INSPECT_ACTIONS.find("running")
	adapter.inspect_dir_index = 2
	adapter.toggle_native_scale()
	camera.zoom = Vector2(CLOSEUP_ZOOM, CLOSEUP_ZOOM)
	camera.global_position = candidate.global_position + Vector2(0.0, 0.0)
	adapter.step_frame(5)
	for i in DIRECTION_HOLD:
		adapter.advance(1.0 / 24.0)
		await process_frame
	await _save("%s/closeup_contact_running_E.png" % _out)
	print("CAPTURE_DONE mode=inspect out=%s" % _out)


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
