extends Node
## Opt-in, evidence-only missing-art flags. Does not alter simulation or publish assets.
## Enabled in a DevMode debug session; release builds additionally require
## --custodian-art-inspection alongside --custodian-dev.

const FLAG_DIR := "user://art_inspector/flags"
const ACTOR_GROUPS := ["player", "enemy", "enemies", "npc", "projectile", "projectiles", "interactable"]
const MAX_VISIBLE_ACTORS := 80
const NOTICE_SECONDS := 2.0

var _busy := false
var _notice: Label
var _notice_left := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.ctrl_pressed or key.alt_pressed or key.meta_pressed or key.shift_pressed:
		return
	if key.keycode != KEY_I and key.physical_keycode != KEY_I:
		return
	if _busy or not _allowed():
		return
	# Do not steal letters from the Developer Shell or other focused controls.
	if get_viewport().gui_get_focus_owner() != null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return
	get_viewport().set_input_as_handled()
	_capture(player)


func _allowed() -> bool:
	var dev := get_node_or_null("/root/DevMode")
	if dev == null or not dev.has_method("allows") or not bool(dev.call("allows", &"debug_ui")):
		return false
	if OS.is_debug_build():
		return true
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	return args.has("--custodian-art-inspection")


func _capture(player: Node2D) -> void:
	_busy = true
	var scene := get_tree().current_scene
	var scene_path := scene.scene_file_path if scene != null else ""
	var scene_tag := scene_path.get_file().get_basename().to_lower().replace(" ", "_")
	if scene_tag.is_empty():
		scene_tag = "unknown"
	var player_pos := player.global_position
	var stamp := Time.get_datetime_string_from_system(true, false).replace(":", "-").replace("T", "_")
	var stem := "%sZ_%s_x%d_y%d_t%d" % [
		stamp, scene_tag, roundi(player_pos.x), roundi(player_pos.y), Time.get_ticks_usec()
	]
	var folder := ProjectSettings.globalize_path(FLAG_DIR)
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		_show_notice("ART FLAG FAILED: cannot create " + folder)
		_busy = false
		return
	var png_path := folder.path_join(stem + ".png")
	var json_path := folder.path_join(stem + ".json")
	var payload := _make_payload(stem, scene_path, player)
	payload["screenshot_filename"] = stem + ".png"
	payload["screenshot_status"] = "pending"
	await RenderingServer.frame_post_draw
	if scene == get_tree().current_scene and get_viewport().get_texture() != null:
		var image := get_viewport().get_texture().get_image()
		var png_result := image.save_png(png_path)
		payload["screenshot_status"] = "saved" if png_result == OK else "write_error_%d" % png_result
	else:
		payload["screenshot_status"] = "scene_changed"
	var temp_path := json_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		_show_notice("ART FLAG FAILED: cannot write JSON")
		_busy = false
		return
	file.store_string(JSON.stringify(payload, "\t") + "\n")
	file.flush()
	file.close()
	if DirAccess.rename_absolute(temp_path, json_path) != OK:
		_show_notice("ART FLAG FAILED: cannot finalize JSON")
		_busy = false
		return
	print("[ArtInspector] Flag: ", json_path, " | snapshot: ", png_path)
	_show_notice("ART FLAG SAVED  x%d y%d" % [roundi(player_pos.x), roundi(player_pos.y)])
	_busy = false


func _make_payload(stem: String, scene_path: String, player: Node2D) -> Dictionary:
	var camera := get_viewport().get_camera_2d()
	var obs := get_node_or_null("/root/DevObservatory")
	var viewport_size := get_viewport().get_visible_rect().size
	var payload := {
		"schema": "custodian.art_inspection_flag.v1",
		"id": stem,
		"status": "untriaged",
		"intent": "missing_art",
		"reported_utc": Time.get_datetime_string_from_system(true, false) + "Z",
		"scene_path": scene_path,
		"world_position": _point(player.global_position),
		"mouse_world_position": _point(get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()),
		"viewport_size": _point(viewport_size),
		"visible_actors": _visible_actors(),
		"artifact_authority": "observation_only_no_asset_approval",
		"notes": "",
		"f10_last_export": "",
	}
	if camera != null:
		payload["camera_world_position"] = _point(camera.global_position)
		payload["camera_zoom"] = _point(camera.zoom)
	if obs != null:
		payload["f10_last_export"] = str(obs.get("last_export_absolute_path"))
	return payload


func _visible_actors() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var seen := {}
	var viewport_rect := get_viewport().get_visible_rect()
	for group in ACTOR_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			if found.size() >= MAX_VISIBLE_ACTORS:
				return found
			var actor := node as Node2D
			if actor == null or not is_instance_valid(actor) or seen.has(actor.get_instance_id()):
				continue
			seen[actor.get_instance_id()] = true
			if not actor.is_visible_in_tree():
				continue
			var screen_pos := actor.get_global_transform_with_canvas().origin
			if not viewport_rect.has_point(screen_pos):
				continue
			found.append({
				"node": str(actor.get_path()),
				"name": actor.name,
				"class": actor.get_class(),
				"group": group,
				"world_position": _point(actor.global_position),
				"screen_position": _point(screen_pos),
			})
	return found


func _point(p: Vector2) -> Array[float]:
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01)]


func _show_notice(message: String) -> void:
	if _notice == null:
		var layer := CanvasLayer.new()
		layer.name = "ArtInspectorNotice"
		layer.layer = 110
		add_child(layer)
		_notice = Label.new()
		_notice.position = Vector2(18.0, 78.0)
		_notice.add_theme_color_override("font_color", Color(0.86, 0.96, 0.78))
		_notice.add_theme_color_override("font_shadow_color", Color.BLACK)
		_notice.add_theme_font_size_override("font_size", 15)
		layer.add_child(_notice)
	_notice.text = message
	_notice.visible = true
	_notice_left = NOTICE_SECONDS
	set_process(true)


func _process(delta: float) -> void:
	_notice_left -= maxf(0.0, delta)
	if _notice_left <= 0.0:
		if _notice != null:
			_notice.visible = false
		set_process(false)
