extends Node2D
class_name Operator3DAnimationPreview

const OPERATOR_BODY_OWNER := 1 # OperatorBodyPresenter.Owner.LEGACY_FULL_BODY
const REQUEST_SCHEMA := "custodian.operator_3d_animation_preview_request.v1"
const DIRECTIONS := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const ACCEPTED_2D_SOURCE_PATH := "res://asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png"
const ACCEPTED_2D_SOURCE_SHA256 := "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3"
const ACCEPTED_2D_WIDTH := 1920
const ACCEPTED_2D_HEIGHT := 1024
const ACCEPTED_2D_CELL := 128
const ACCEPTED_2D_FRAME_COUNT := 15
const CANONICAL_128_COMPARISON_PROFILE := "accepted_128_root64_106_v1"
const CANONICAL_128_SPRITE_POSITION := Vector2(0.0, -42.0)
const OPERATOR_CAMERA_ZOOM := Vector2(0.84, 0.84)
const CANDIDATE_SCALE := Vector2(0.75, 0.75)
const CANDIDATE_POSITION := Vector2(0, -31.5)

@export var request_path := ""
@export var operator_path: NodePath = NodePath("World/Operator")
@export var camera_path: NodePath = NodePath("World/Camera2D")
@export var preserve_scene_camera_profile := false
@export var initial_direction := "N"

@onready var _operator: CharacterBody2D = get_node_or_null(operator_path) as CharacterBody2D
@onready var _camera: Camera2D = get_node_or_null(camera_path) as Camera2D

var _request: Dictionary = {}
var _approved_frames: SpriteFrames
var _accepted_source_frames: SpriteFrames
var _accepted_source_sheet: Image
var _accepted_source_preview_fps := 0.0
var _sprite: AnimatedSprite2D
var _candidate_frames: SpriteFrames
var _selected_direction := "N"
var _selected_mode := "candidate"
var _approved_sprite_position := Vector2.ZERO
var _approved_sprite_scale := Vector2.ONE
var _approved_sprite_offset := Vector2.ZERO
var _status_label: Label
var _badge_label: Label
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
	_select_preview("candidate", initial_direction)


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
	if _request.has("accepted_2d_reference") and not _load_accepted_source_frames():
		return false
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


func _load_accepted_source_frames() -> bool:
	var reference: Variant = _request.get("accepted_2d_reference")
	if not reference is Dictionary:
		_fail("accepted 2.5D reference metadata must be an object")
		return false
	if reference.get("source_path") != ACCEPTED_2D_SOURCE_PATH:
		_fail("accepted 2.5D source path differs from the canonical source-work file")
		return false
	if reference.get("source_sha256") != ACCEPTED_2D_SOURCE_SHA256:
		_fail("accepted 2.5D source identity differs from the accepted visual contract")
		return false
	var staged_path := String(reference.get("staged_path", ""))
	if not staged_path.begins_with("res://.ai/operator_3d_animation_preview/") or not staged_path.ends_with("/accepted_source.png"):
		_fail("accepted 2.5D source must be staged only under ignored preview data")
		return false
	if not FileAccess.file_exists(staged_path) or FileAccess.get_sha256(staged_path) != ACCEPTED_2D_SOURCE_SHA256:
		_fail("staged accepted 2.5D source bytes do not match the pinned source hash")
		return false
	if reference.get("width") != ACCEPTED_2D_WIDTH or reference.get("height") != ACCEPTED_2D_HEIGHT:
		_fail("accepted 2.5D sheet dimensions differ from 1920x1024")
		return false
	if reference.get("columns") != ACCEPTED_2D_WIDTH / ACCEPTED_2D_CELL or reference.get("rows") != DIRECTIONS.size():
		_fail("accepted 2.5D sheet grid must be 15 columns by eight direction rows")
		return false
	if reference.get("cell_width") != ACCEPTED_2D_CELL or reference.get("cell_height") != ACCEPTED_2D_CELL:
		_fail("accepted 2.5D source cells must be 128x128")
		return false
	if reference.get("directions") != DIRECTIONS or reference.get("frames_per_direction") != ACCEPTED_2D_FRAME_COUNT:
		_fail("accepted 2.5D direction order or frame count differs from the contract")
		return false
	if reference.get("looping") != true or reference.get("source_fps") != null:
		_fail("accepted 2.5D source must loop with source FPS unknown")
		return false
	if reference.get("timing_authority") != false or reference.get("runtime_promoted") != false:
		_fail("accepted art source must not grant timing or runtime promotion authority")
		return false
	if reference.get("presentation_profile") != CANONICAL_128_COMPARISON_PROFILE:
		_fail("accepted reference is missing the canonical 128px root/scale comparison profile")
		return false
	var cadence := float(reference.get("preview_cadence_fps", 0.0))
	if cadence <= 0.0 or cadence > 30.0 or reference.get("cadence_kind") != "display_only_not_source_timing":
		_fail("accepted source preview cadence must be explicit and carry no source timing authority")
		return false
	_accepted_source_preview_fps = cadence
	_accepted_source_sheet = Image.new()
	if _accepted_source_sheet.load(ProjectSettings.globalize_path(staged_path)) != OK:
		_fail("Godot could not decode the staged accepted 2.5D source")
		return false
	if _accepted_source_sheet.get_size() != Vector2i(ACCEPTED_2D_WIDTH, ACCEPTED_2D_HEIGHT) or _accepted_source_sheet.get_format() != Image.FORMAT_RGBA8:
		_fail("accepted 2.5D source must decode as 1920x1024 RGBA8")
		return false
	_accepted_source_frames = SpriteFrames.new()
	_accepted_source_frames.remove_animation("default")
	for row in DIRECTIONS.size():
		var animation_name := _accepted_source_animation(DIRECTIONS[row])
		_accepted_source_frames.add_animation(animation_name)
		_accepted_source_frames.set_animation_speed(animation_name, _accepted_source_preview_fps)
		_accepted_source_frames.set_animation_loop(animation_name, true)
		for column in ACCEPTED_2D_FRAME_COUNT:
			var cell := _accepted_source_sheet.get_region(Rect2i(column * ACCEPTED_2D_CELL, row * ACCEPTED_2D_CELL, ACCEPTED_2D_CELL, ACCEPTED_2D_CELL))
			if cell == null or cell.get_size() != Vector2i(ACCEPTED_2D_CELL, ACCEPTED_2D_CELL):
				_fail("accepted 2.5D atlas cell could not be extracted")
				return false
			_accepted_source_frames.add_frame(animation_name, ImageTexture.create_from_image(cell))
	return true


func _accepted_source_animation(direction: String) -> String:
	return "accepted_source_" + direction.to_lower()


func _uses_canonical_128_comparison_profile() -> bool:
	return _request.get("comparison_profile") == CANONICAL_128_COMPARISON_PROFILE


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
	if not preserve_scene_camera_profile:
		_camera.zoom = OPERATOR_CAMERA_ZOOM
		if _has_property(_camera, "base_zoom"):
			_camera.set("base_zoom", OPERATOR_CAMERA_ZOOM)
		if _has_property(_camera, "target_zoom"):
			_camera.set("target_zoom", OPERATOR_CAMERA_ZOOM)
	if _has_property(_camera, "auto_zoom_enabled"):
		_camera.set("auto_zoom_enabled", false)
	if _has_property(_camera, "follow_enabled"):
		_camera.set("follow_enabled", false)
	if not preserve_scene_camera_profile:
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
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-980.0, 18.0)
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	_badge_label = Label.new()
	_badge_label.text = "EXPERIMENTAL / UNAPPROVED"
	_badge_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.08))
	_badge_label.add_theme_font_size_override("font_size", 19)
	column.add_child(_badge_label)
	_status_label = Label.new()
	_status_label.custom_minimum_size.x = 720.0
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status_label)
	var modes := HBoxContainer.new()
	column.add_child(modes)
	var candidate_button := Button.new()
	candidate_button.text = "3D Candidate"
	candidate_button.pressed.connect(_on_mode_pressed.bind("candidate"))
	modes.add_child(candidate_button)
	if _accepted_source_frames != null:
		var accepted_source_button := Button.new()
		accepted_source_button.text = "Accepted 2.5D Source"
		accepted_source_button.pressed.connect(_on_mode_pressed.bind("accepted_source"))
		modes.add_child(accepted_source_button)
	var runtime_button := Button.new()
	runtime_button.text = "Live Runtime (legacy_96)"
	runtime_button.pressed.connect(_on_mode_pressed.bind("runtime_legacy_96"))
	modes.add_child(runtime_button)
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
	help.text = "1–8: direction   Tab: cycle candidate / accepted source / live legacy runtime"
	column.add_child(help)
	_update_status()


func _on_mode_pressed(mode: String) -> void:
	_select_preview(mode, _selected_direction)


func _on_direction_pressed(direction: String) -> void:
	_select_preview(_selected_mode, direction)


func _select_preview(mode: String, direction: String) -> bool:
	if mode == "approved":
		mode = "runtime_legacy_96"
	if not DIRECTIONS.has(direction) or not ["candidate", "accepted_source", "runtime_legacy_96"].has(mode):
		return false
	if mode == "accepted_source" and _accepted_source_frames == null:
		return false
	_selected_mode = mode
	_selected_direction = direction
	if mode == "candidate":
		var built := _build_candidate_frames(direction)
		if built == null:
			return false
		_candidate_frames = built
		_sprite.sprite_frames = _candidate_frames
		if _uses_canonical_128_comparison_profile():
			_sprite.position = CANONICAL_128_SPRITE_POSITION
			_sprite.scale = Vector2.ONE
		else:
			_sprite.position = CANDIDATE_POSITION
			_sprite.scale = CANDIDATE_SCALE
		_sprite.offset = Vector2.ZERO
		_sprite.speed_scale = 1.0
		_sprite.play("candidate")
	elif mode == "accepted_source":
		_sprite.sprite_frames = _accepted_source_frames
		_sprite.position = CANONICAL_128_SPRITE_POSITION
		_sprite.scale = Vector2.ONE
		_sprite.offset = Vector2.ZERO
		_sprite.speed_scale = 1.0
		_sprite.play(_accepted_source_animation(direction))
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
	_update_badge()
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
		_status_label.text = "%s — %s — %s — %d frames @ %.3f FPS (preview only; no runtime timing authority)" % [
			String(_request.get("animation_id", "candidate")), String(_request.get("candidate_version", _request.get("candidate_job_id", "unversioned"))), _selected_direction,
			_request.get("directions", [])[DIRECTIONS.find(_selected_direction)].get("frames", []).size(),
			float(source.get("authored_fps", 0.0)),
		]
	elif _selected_mode == "accepted_source":
		_status_label.text = "Accepted 2.5D visual source — %s — 15 frames @ %.3f FPS display cadence (source FPS unknown; no timing authority; not runtime-promoted)" % [
			_selected_direction, _accepted_source_preview_fps,
		]
	else:
		var approved_direction := _approved_runtime_direction(_selected_direction)
		var suffix := "" if approved_direction == _selected_direction else " (direction art falls back to %s)" % approved_direction
		_status_label.text = "Live runtime legacy_96 — %s%s — current SpriteFrames" % [_selected_direction, suffix]


func _update_badge() -> void:
	if _badge_label == null:
		return
	if _selected_mode == "accepted_source":
		_badge_label.text = "ACCEPTED ART SOURCE / NOT RUNTIME-PROMOTED"
		_badge_label.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))
	elif _selected_mode == "runtime_legacy_96":
		_badge_label.text = "LIVE RUNTIME REFERENCE / legacy_96"
		_badge_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.86))
	else:
		_badge_label.text = "EXPERIMENTAL / UNAPPROVED"
		_badge_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.08))


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_TAB:
		var modes := PackedStringArray(["candidate"])
		if _accepted_source_frames != null:
			modes.append("accepted_source")
		modes.append("runtime_legacy_96")
		var next_index := (modes.find(_selected_mode) + 1) % modes.size()
		_select_preview(modes[next_index], _selected_direction)
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

	var accepted_source_checked_frames := 0
	if _accepted_source_frames != null:
		for row in DIRECTIONS.size():
			var direction: String = DIRECTIONS[row]
			if not _select_preview("accepted_source", direction):
				return {"ok": false, "error": "accepted 2.5D source selection failed: " + direction}
			var animation_name := _accepted_source_animation(direction)
			if _sprite.sprite_frames != _accepted_source_frames or _sprite.sprite_frames.get_frame_count(animation_name) != ACCEPTED_2D_FRAME_COUNT:
				return {"ok": false, "error": "accepted 2.5D source frame count mismatch: " + direction}
			if not _sprite.sprite_frames.get_animation_loop(animation_name) or not is_equal_approx(_sprite.sprite_frames.get_animation_speed(animation_name), _accepted_source_preview_fps):
				return {"ok": false, "error": "accepted 2.5D display cadence/loop policy mismatch: " + direction}
			for column in ACCEPTED_2D_FRAME_COUNT:
				var texture := _sprite.sprite_frames.get_frame_texture(animation_name, column)
				if texture == null or texture.get_size() != Vector2(ACCEPTED_2D_CELL, ACCEPTED_2D_CELL):
					return {"ok": false, "error": "accepted 2.5D frame dimensions mismatch: %s frame %d" % [direction, column + 1]}
				var actual := texture.get_image()
				var expected := _accepted_source_sheet.get_region(Rect2i(column * ACCEPTED_2D_CELL, row * ACCEPTED_2D_CELL, ACCEPTED_2D_CELL, ACCEPTED_2D_CELL))
				if actual == null or actual.get_format() != Image.FORMAT_RGBA8 or actual.get_data() != expected.get_data():
					return {"ok": false, "error": "accepted 2.5D source pixels/order changed: %s frame %d" % [direction, column + 1]}
				accepted_source_checked_frames += 1
			if _sprite.position != CANONICAL_128_SPRITE_POSITION or _sprite.scale != Vector2.ONE:
				return {"ok": false, "error": "accepted 2.5D source is not using the canonical root/scale transform"}
			var accepted_visible: Array = _operator.call("get_visible_body_owners")
			if accepted_visible.size() != 1 or accepted_visible[0] != OPERATOR_BODY_OWNER:
				return {"ok": false, "error": "accepted source created competing body presentation"}
			if _badge_label.text != "ACCEPTED ART SOURCE / NOT RUNTIME-PROMOTED":
				return {"ok": false, "error": "accepted source is not labeled as non-runtime-promoted art"}

	if not _select_preview("candidate", "N"):
		return {"ok": false, "error": _setup_error}
	var visible_owners: Array = _operator.call("get_visible_body_owners")
	var shadow := _operator.get_node_or_null("BlobShadow") as Node2D
	var candidate_position := CANONICAL_128_SPRITE_POSITION if _uses_canonical_128_comparison_profile() else CANDIDATE_POSITION
	var candidate_scale := Vector2.ONE if _uses_canonical_128_comparison_profile() else CANDIDATE_SCALE
	var expected_ground_y := candidate_position.y + (106.0 - 64.0) * candidate_scale.y
	if _sprite.position != candidate_position or _sprite.scale != candidate_scale:
		return {"ok": false, "error": "candidate is not using the declared comparison profile transform"}
	if absf(expected_ground_y) > 0.001:
		return {"ok": false, "error": "candidate ground registration does not align to Operator root"}
	if int(_operator.call("get_body_presentation_owner")) != OPERATOR_BODY_OWNER or visible_owners.size() != 1 or visible_owners[0] != OPERATOR_BODY_OWNER:
		return {"ok": false, "error": "body presenter does not report exactly one legacy full-body owner"}
	if shadow == null or shadow.position != Vector2(0, 13):
		return {"ok": false, "error": "Operator's existing ground shadow placement changed"}
	if _operator.collision_layer != 0 or _operator.collision_mask != 0 or _operator.is_physics_processing():
		return {"ok": false, "error": "preview Operator simulation/collision is enabled"}
	if _camera.get_script() != load("res://game/world/camera.gd"):
		return {"ok": false, "error": "preview does not use the fixed real game camera profile"}
	if not preserve_scene_camera_profile and _camera.zoom != OPERATOR_CAMERA_ZOOM:
		return {"ok": false, "error": "preview does not use the fixed real game camera profile"}
	if _badge_label == null or _badge_label.text != "EXPERIMENTAL / UNAPPROVED" or not _badge_label.visible:
		return {"ok": false, "error": "experimental unapproved indicator is not visible"}
	if not _status_label.text.contains(String(_request.get("candidate_version", _request.get("candidate_job_id", "unversioned")))):
		return {"ok": false, "error": "exact candidate version is not displayed"}
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
		"camera_profile_preserved": preserve_scene_camera_profile,
		"candidate_version": _request.get("candidate_version", _request.get("candidate_job_id", "unversioned")),
		"candidate_sprite_position": [_sprite.position.x, _sprite.position.y],
		"candidate_sprite_scale": [_sprite.scale.x, _sprite.scale.y],
		"ground_registration_residual_y": expected_ground_y,
		"shadow_position": [shadow.position.x, shadow.position.y],
		"live_runtime_identity": "legacy_96",
		"live_runtime_diagonal_fallbacks": {"NE": "N", "NW": "N", "SE": "S", "SW": "S"},
		"accepted_2d_source_sha256": ACCEPTED_2D_SOURCE_SHA256 if _accepted_source_frames != null else "",
		"accepted_2d_source_checked_frames": accepted_source_checked_frames,
		"accepted_2d_source_fps": null,
		"accepted_2d_preview_cadence_fps": _accepted_source_preview_fps,
		"comparison_profile": _request.get("comparison_profile", "legacy_96_runtime_preview"),
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
