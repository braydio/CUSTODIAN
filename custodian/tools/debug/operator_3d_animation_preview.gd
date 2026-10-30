extends Node2D
class_name Operator3DAnimationPreview

const OPERATOR_BODY_OWNER := 1 # OperatorBodyPresenter.Owner.LEGACY_FULL_BODY
const REQUEST_SCHEMA := "custodian.operator_3d_animation_preview_request.v1"
const DIRECTIONS := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const OPERATOR_CAMERA_ZOOM := Vector2(0.84, 0.84)
const CANDIDATE_SCALE := Vector2(0.75, 0.75)
const CANDIDATE_POSITION := Vector2(0, -31.5)

@export var request_path := ""

@onready var _operator: CharacterBody2D = $World/Operator
@onready var _camera: Camera2D = $World/Camera2D

var _request: Dictionary = {}
var _approved_frames: SpriteFrames
var _sprite: AnimatedSprite2D
var _candidate_frames: SpriteFrames
var _selected_direction := "N"
var _selected_mode := "candidate"
var _approved_sprite_position := Vector2.ZERO
var _approved_sprite_scale := Vector2.ONE
var _approved_sprite_offset := Vector2.ZERO
var _status_label: Label
var _setup_error := ""


func _ready() -> void:
	if request_path.is_empty():
		request_path = _request_argument()
	if request_path.is_empty():
		_fail("missing --request res://.ai/.../request.json")
		return
	if not _load_request():
		return
	if not _configure_operator():
		return
	_build_controls()
	_select_preview("candidate", "N")


func _request_argument() -> String:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--request")
	return args[index + 1] if index >= 0 and index + 1 < args.size() else ""


func _load_request() -> bool:
	if not request_path.begins_with("res://.ai/operator_3d_animation_preview/"):
		_fail("request must be inside the ignored dev-only custodian/.ai preview directory")
		return false
	var sidecar_path := request_path + ".sha256"
	if not FileAccess.file_exists(request_path) or not FileAccess.file_exists(sidecar_path):
		_fail("preview request or request hash sidecar is missing")
		return false
	var expected_sha := FileAccess.get_file_as_string(sidecar_path).strip_edges()
	if not _is_sha256(expected_sha) or FileAccess.get_sha256(request_path) != expected_sha:
		_fail("preview request hash mismatch")
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(request_path))
	if not parsed is Dictionary or parsed.get("schema") != REQUEST_SCHEMA:
		_fail("unsupported preview request schema")
		return false
	_request = parsed
	if _request.get("candidate_state") != "candidate_unapproved" or _request.get("production_approval") != false:
		_fail("preview request must remain candidate_unapproved")
		return false
	if _request.get("timing_authority_granted") != false:
		_fail("source FPS must not grant runtime timing authority")
		return false
	if _request.get("render_contract", {}).get("directions") != DIRECTIONS:
		_fail("preview directions must be the exact canonical eight-direction order")
		return false
	var root_pixel: Array = _request.get("render_contract", {}).get("root_pixel", [])
	if root_pixel.size() != 2 or not is_equal_approx(float(root_pixel[0]), 64.0) or not is_equal_approx(float(root_pixel[1]), 106.0):
		_fail("preview root registration must be (64,106)")
		return false
	var direction_rows: Array = _request.get("directions", [])
	if direction_rows.size() != DIRECTIONS.size():
		_fail("preview request must include all eight directions")
		return false
	for i in DIRECTIONS.size():
		if direction_rows[i].get("direction") != DIRECTIONS[i]:
			_fail("preview direction order is invalid")
			return false
	return true


func _configure_operator() -> bool:
	_sprite = _operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _sprite == null:
		_fail("real Operator AnimatedSprite2D renderer is missing")
		return false
	_approved_frames = _sprite.sprite_frames
	if _approved_frames == null:
		_fail("approved runtime SpriteFrames are missing from Operator scene")
		return false
	_approved_sprite_position = _sprite.position
	_approved_sprite_scale = _sprite.scale
	_approved_sprite_offset = _sprite.offset

	# This is a dev-only sample. Disable the instantiated actor's simulation and
	# collision while preserving its existing presenter and full-body renderer.
	_operator.set_process(false)
	_operator.set_physics_process(false)
	_operator.set_process_input(false)
	_operator.set_process_unhandled_input(false)
	_operator.set_process_unhandled_key_input(false)
	_operator.collision_layer = 0
	_operator.collision_mask = 0
	_operator.velocity = Vector2.ZERO
	for node in _operator.find_children("*", "CollisionShape2D", true, false):
		node.set_deferred("disabled", true)
	if not _operator.call("_set_body_presentation_owner", OPERATOR_BODY_OWNER):
		_fail("OperatorBodyPresenter refused the legacy full-body owner")
		return false
	if not _operator.call("_show_body_layer", _sprite):
		_fail("OperatorBodyPresenter refused the existing full-body renderer")
		return false
	if _camera.get_script() != load("res://game/world/camera.gd"):
		_fail("preview camera is not the existing game CameraController")
		return false
	_camera.zoom = OPERATOR_CAMERA_ZOOM
	if _has_property(_camera, "base_zoom"):
		_camera.set("base_zoom", OPERATOR_CAMERA_ZOOM)
	if _has_property(_camera, "target_zoom"):
		_camera.set("target_zoom", OPERATOR_CAMERA_ZOOM)
	if _has_property(_camera, "auto_zoom_enabled"):
		_camera.set("auto_zoom_enabled", false)
	if _has_property(_camera, "follow_enabled"):
		_camera.set("follow_enabled", false)
	_camera.call("set_authored_map_bounds", Rect2(Vector2.ZERO, Vector2(3712, 2688)))
	_camera.position = _operator.position
	_camera.position_smoothing_enabled = false
	_camera.make_current()
	_camera.set_process(false)
	return true


func _build_controls() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DiagnosticControls"
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var badge := Label.new()
	badge.text = "EXPERIMENTAL / UNAPPROVED"
	badge.add_theme_color_override("font_color", Color(1.0, 0.42, 0.08))
	badge.add_theme_font_size_override("font_size", 19)
	column.add_child(badge)
	_status_label = Label.new()
	column.add_child(_status_label)
	var modes := HBoxContainer.new()
	column.add_child(modes)
	var candidate_button := Button.new()
	candidate_button.text = "3D Candidate"
	candidate_button.pressed.connect(_on_mode_pressed.bind("candidate"))
	modes.add_child(candidate_button)
	var approved_button := Button.new()
	approved_button.text = "Approved Runtime"
	approved_button.pressed.connect(_on_mode_pressed.bind("approved"))
	modes.add_child(approved_button)
	var direction_grid := GridContainer.new()
	direction_grid.columns = 4
	column.add_child(direction_grid)
	for direction in DIRECTIONS:
		var button := Button.new()
		button.text = direction
		button.custom_minimum_size = Vector2(54, 34)
		button.pressed.connect(_on_direction_pressed.bind(direction))
		direction_grid.add_child(button)
	var help := Label.new()
	help.text = "1–8: direction   Tab: switch art   Loop plays in place"
	column.add_child(help)
	_update_status()


func _on_mode_pressed(mode: String) -> void:
	_select_preview(mode, _selected_direction)


func _on_direction_pressed(direction: String) -> void:
	_select_preview(_selected_mode, direction)


func _select_preview(mode: String, direction: String) -> bool:
	if not DIRECTIONS.has(direction) or not ["candidate", "approved"].has(mode):
		return false
	_selected_mode = mode
	_selected_direction = direction
	if mode == "candidate":
		var built := _build_candidate_frames(direction)
		if built == null:
			return false
		_candidate_frames = built
		_sprite.sprite_frames = _candidate_frames
		_sprite.position = CANDIDATE_POSITION
		_sprite.scale = CANDIDATE_SCALE
		_sprite.offset = Vector2.ZERO
		_sprite.speed_scale = 1.0
		_sprite.play("candidate")
	else:
		var approved_direction := direction
		if direction in ["NE", "NW"]:
			approved_direction = "N"
		elif direction in ["SE", "SW"]:
			approved_direction = "S"
		var runtime_animation := "unarmed/locomotion/idle_01/%s/full_body" % approved_direction.to_lower()
		if not _approved_frames.has_animation(runtime_animation):
			_fail("approved runtime full-body animation is missing: " + runtime_animation)
			return false
		if not _operator.call("_set_body_presentation_owner", OPERATOR_BODY_OWNER):
			_fail("OperatorBodyPresenter refused approved full-body owner")
			return false
		if not _operator.call("_show_body_layer", _sprite):
			_fail("OperatorBodyPresenter refused approved full-body renderer")
			return false
		_sprite.sprite_frames = _approved_frames
		_sprite.position = _approved_sprite_position
		_sprite.scale = _approved_sprite_scale
		_sprite.offset = _approved_sprite_offset
		_sprite.speed_scale = 1.0
		_sprite.play(runtime_animation)
	_update_status()
	return true


func _build_candidate_frames(direction: String) -> SpriteFrames:
	var direction_rows: Array = _request.get("directions", [])
	var selected: Dictionary = {}
	for row in direction_rows:
		if row.get("direction") == direction:
			selected = row
			break
	var rows: Array = selected.get("frames", [])
	var source_frames: Array = _request.get("source", {}).get("rendered_source_frames", [])
	if rows.is_empty() or rows.size() != source_frames.size():
		_fail("candidate direction frame count differs from declared source-frame sequence: " + direction)
		return null
	var fps := float(_request.get("source", {}).get("authored_fps", 0.0))
	if fps <= 0.0:
		_fail("candidate authored FPS is invalid")
		return null
	var frames := SpriteFrames.new()
	frames.add_animation("candidate")
	frames.set_animation_speed("candidate", fps)
	frames.set_animation_loop("candidate", true)
	for i in rows.size():
		var row: Dictionary = rows[i]
		if row.get("source_frame") != source_frames[i]:
			_fail("candidate frame order differs from source: " + direction)
			return null
		var path := String(row.get("path", ""))
		if not path.begins_with("res://.ai/operator_3d_animation_preview/"):
			_fail("candidate frame path is outside ignored dev staging")
			return null
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != String(row.get("sha256", "")):
			_fail("candidate frame file hash mismatch: " + path)
			return null
		var image := Image.new()
		var image_error := image.load(ProjectSettings.globalize_path(path))
		if image_error != OK or image.get_width() != 128 or image.get_height() != 128:
			_fail("Godot could not decode an exact 128x128 candidate frame: " + path)
			return null
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		if _sha256(image.get_data()) != String(row.get("pixel_sha256", "")):
			_fail("candidate decoded RGBA pixel hash mismatch: " + path)
		frames.add_frame("candidate", ImageTexture.create_from_image(image), 1.0)
	return frames


func _update_status() -> void:
	if _status_label == null:
		return
	if _selected_mode == "candidate":
		var source: Dictionary = _request.get("source", {})
		_status_label.text = "%s — %s — %d frames @ %.3f FPS (preview only; no runtime timing authority)" % [
			String(_request.get("animation_id", "candidate")), _selected_direction,
			_request.get("directions", [])[DIRECTIONS.find(_selected_direction)].get("frames", []).size(),
			float(source.get("authored_fps", 0.0)),
		]
	else:
		var approved_direction := _approved_runtime_direction(_selected_direction)
		var suffix := "" if approved_direction == _selected_direction else " (nearest full-body: %s)" % approved_direction
		_status_label.text = "Approved runtime — %s%s — existing game animation cadence" % [_selected_direction, suffix]


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_TAB:
		_select_preview("approved" if _selected_mode == "candidate" else "candidate", _selected_direction)
		get_viewport().set_input_as_handled()
		return
	var direction_index := -1
	match event.keycode:
		KEY_1: direction_index = 0
		KEY_2: direction_index = 1
		KEY_3: direction_index = 2
		KEY_4: direction_index = 3
		KEY_5: direction_index = 4
		KEY_6: direction_index = 5
		KEY_7: direction_index = 6
		KEY_8: direction_index = 7
	if direction_index >= 0:
		_select_preview(_selected_mode, DIRECTIONS[direction_index])
		get_viewport().set_input_as_handled()


func run_smoke_check() -> Dictionary:
	if not _setup_error.is_empty():
		return {"ok": false, "error": _setup_error}
	var checked_frames := 0
	for direction in DIRECTIONS:
		if not _select_preview("candidate", direction):
			return {"ok": false, "error": _setup_error}
		var expected_rows: Array = _request["directions"][DIRECTIONS.find(direction)]["frames"]
		if _sprite.sprite_frames.get_frame_count("candidate") != expected_rows.size():
			return {"ok": false, "error": "SpriteFrames count mismatch: " + direction}
		if not _sprite.sprite_frames.get_animation_loop("candidate"):
			return {"ok": false, "error": "candidate animation is not looping: " + direction}
		if not is_equal_approx(_sprite.sprite_frames.get_animation_speed("candidate"), float(_request["source"]["authored_fps"])):
			return {"ok": false, "error": "candidate playback speed differs from authored FPS: " + direction}
		for index in expected_rows.size():
			var texture := _sprite.sprite_frames.get_frame_texture("candidate", index)
			if texture == null or texture.get_size() != Vector2(128, 128):
				return {"ok": false, "error": "Godot imported texture invalid: %s frame %d" % [direction, index + 1]}
			var image := texture.get_image()
			if image == null or image.get_size() != Vector2i(128, 128):
				return {"ok": false, "error": "Godot image dimensions invalid: %s frame %d" % [direction, index + 1]}
			if image.get_format() != Image.FORMAT_RGBA8:
				image.convert(Image.FORMAT_RGBA8)
			if _sha256(image.get_data()) != String(expected_rows[index]["pixel_sha256"]):
				return {"ok": false, "error": "Godot decoded pixels differ: %s frame %d" % [direction, index + 1]}
			if FileAccess.get_sha256(String(expected_rows[index]["path"])) != String(expected_rows[index]["sha256"]):
				return {"ok": false, "error": "Godot source file hash differs: %s frame %d" % [direction, index + 1]}
			checked_frames += 1
		if not _select_preview("approved", direction):
			return {"ok": false, "error": "approved runtime animation missing: " + direction}
		var approved_owner := int(_operator.call("get_body_presentation_owner"))
		if approved_owner != OPERATOR_BODY_OWNER or _sprite.sprite_frames != _approved_frames or not _sprite.is_playing():
			return {"ok": false, "error": "approved runtime comparison did not use the existing full-body renderer: " + direction}
		var approved_visible: Array = _operator.call("get_visible_body_owners")
		if approved_visible.size() != 1 or approved_visible[0] != approved_owner:
			return {"ok": false, "error": "approved runtime presented competing body owners: " + direction}

	if not _select_preview("candidate", "N"):
		return {"ok": false, "error": _setup_error}
	var visible_owners: Array = _operator.call("get_visible_body_owners")
	var shadow := _operator.get_node_or_null("BlobShadow") as Node2D
	var expected_ground_y := CANDIDATE_POSITION.y + (106.0 - 64.0) * CANDIDATE_SCALE.y
	if absf(expected_ground_y) > 0.001:
		return {"ok": false, "error": "candidate ground registration does not align to Operator root"}
	if int(_operator.call("get_body_presentation_owner")) != OPERATOR_BODY_OWNER or visible_owners.size() != 1 or visible_owners[0] != OPERATOR_BODY_OWNER:
		return {"ok": false, "error": "body presenter does not report exactly one legacy full-body owner"}
	if shadow == null or shadow.position != Vector2(0, 13):
		return {"ok": false, "error": "Operator's existing ground shadow placement changed"}
	if _operator.collision_layer != 0 or _operator.collision_mask != 0 or _operator.is_physics_processing():
		return {"ok": false, "error": "preview Operator simulation/collision is enabled"}
	if _camera.get_script() != load("res://game/world/camera.gd") or _camera.zoom != OPERATOR_CAMERA_ZOOM:
		return {"ok": false, "error": "preview does not use the fixed real game camera profile"}
	return {
		"ok": true,
		"candidate_state": _request["candidate_state"],
		"production_approval": _request["production_approval"],
		"timing_authority_granted": _request["timing_authority_granted"],
		"directions": DIRECTIONS,
		"checked_frames": checked_frames,
		"fps": _request["source"]["authored_fps"],
		"frame_count_per_direction": _request["source"]["rendered_source_frames"].size(),
		"one_visible_body_owner": visible_owners,
		"real_operator_scene": "res://game/actors/operator/operator.tscn",
		"real_camera_script": "res://game/world/camera.gd",
		"camera_zoom": [_camera.zoom.x, _camera.zoom.y],
		"candidate_sprite_position": [_sprite.position.x, _sprite.position.y],
		"candidate_sprite_scale": [_sprite.scale.x, _sprite.scale.y],
		"ground_registration_residual_y": expected_ground_y,
		"shadow_position": [shadow.position.x, shadow.position.y],
		"approved_runtime_art_available_all_directions": true,
		"approved_runtime_diagonal_fallbacks": {"NE": "N", "NW": "N", "SE": "S", "SW": "S"},
	}


func _approved_runtime_direction(direction: String) -> String:
	if direction in ["NE", "NW"]:
		return "N"
	if direction in ["SE", "SW"]:
		return "S"
	return direction


func _has_property(object: Object, property_name: String) -> bool:
	for property_info in object.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false


func _is_sha256(value: String) -> bool:
	if value.length() != 64:
		return false
	for character in value:
		if not "0123456789abcdef".contains(character):
			return false
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> void:
	_setup_error = message
	push_error("[Operator3DAnimationPreview] " + message)
