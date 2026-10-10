extends Node2D
class_name Operator2DReviewSandbox

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const REQUEST_SCHEMA := "custodian.operator_2_5d_sandbox_request.v1"

var _request: Dictionary
var _operator: CharacterBody2D
var _frames: SpriteFrames
var _frame_index := 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--request")
	if index < 0 or index + 1 >= args.size():
		_fail("missing --request")
		return
	var request_path := args[index + 1]
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(request_path))
	if not parsed is Dictionary or parsed.get("schema") != REQUEST_SCHEMA:
		_fail("unsupported sandbox request")
		return
	_request = parsed
	var expected_request_hash := String(_request.get("request_sha256", ""))
	var payload_json := String(_request.get("payload_json", ""))
	var payload = JSON.parse_string(payload_json)
	var outer_payload := _request.duplicate(true)
	outer_payload.erase("request_sha256")
	outer_payload.erase("payload_json")
	if expected_request_hash.is_empty() or _sha256(payload_json.to_utf8_buffer()) != expected_request_hash or payload != outer_payload:
		_fail("request hash mismatch")
		return
	var frame_rows: Array = _request.get("frames", [])
	var durations: Array = _request.get("durations", [])
	var frame_pixel_hashes: Array[String] = []
	if frame_rows.is_empty() or frame_rows.size() != durations.size():
		_fail("frame/duration contract mismatch")
		return
	_frames = SpriteFrames.new()
	_frames.add_animation("review")
	for row in frame_rows:
		var frame_path := request_path.get_base_dir().path_join(String(row.get("path", "")))
		if not FileAccess.file_exists(frame_path) or FileAccess.get_sha256(frame_path) != String(row.get("sha256", "")):
			_fail("frame hash mismatch: %s" % frame_path)
			return
		var image := Image.load_from_file(frame_path)
		if image.is_empty() or image.get_size() != Vector2i(128, 128):
			_fail("frame is not exact 128x128 RGBA")
			return
		var pixel_hash := _sha256(image.get_data())
		if pixel_hash != String(row.get("pixel_sha256", "")):
			_fail("frame pixel hash mismatch: %s" % frame_path)
			return
		frame_pixel_hashes.append(pixel_hash)
		_frames.add_frame("review", ImageTexture.create_from_image(image), float(durations[_frames.get_frame_count("review")]))
	_operator = OPERATOR_SCENE.instantiate()
	_operator.position = Vector2.ZERO
	_operator.set_physics_process(false)
	_operator.set_process(false)
	add_child(_operator)
	var sprite := _operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		_fail("real Operator body renderer missing")
		return
	sprite.sprite_frames = _frames
	var displayed_image := _frames.get_frame_texture("review", 0).get_image()
	if displayed_image.is_empty() or _sha256(displayed_image.get_data()) != frame_pixel_hashes[0]:
		_fail("display texture pixels differ from exact Workbench frame")
		return
	sprite.play("review")
	# Keep body ownership with the existing presenter; no direct visibility writes.
	_operator.call("_set_body_presentation_owner", 1)
	_operator.call("_show_body_layer", sprite)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -10)
	camera.zoom = Vector2(3, 3)
	_operator.add_child(camera)
	camera.make_current()
	var result := {"schema":"custodian.operator_2_5d_sandbox_result.v1",
		"request_sha256":expected_request_hash, "presentation":"PASSED",
		"frame_size":[128,128], "frame_count":_frames.get_frame_count("review"),
		"durations":durations, "operator_scene":"res://game/actors/operator/operator.tscn",
		"body_owner":int(_operator.call("get_body_presentation_owner")),
		"visible_body_owners":_operator.call("get_visible_body_owners"),
		"operator_position":[_operator.position.x,_operator.position.y],
		"operator_scale":[_operator.scale.x,_operator.scale.y],
		"sprite_position":[sprite.position.x,sprite.position.y],
		"sprite_scale":[sprite.scale.x,sprite.scale.y],
		"sprite_visible":sprite.visible, "frames_reference_same":sprite.sprite_frames == _frames,
		"selected_frame_sha256":String(frame_rows[0].get("sha256", "")),
		"presented_pixel_sha256":_sha256(displayed_image.get_data()),
		"selected_texture_size":[_frames.get_frame_texture("review", 0).get_width(), _frames.get_frame_texture("review", 0).get_height()],
		"shadow_present":_operator.get_node_or_null("BlobShadow") != null,
		"shadow_position":[_operator.get_node("BlobShadow").position.x,_operator.get_node("BlobShadow").position.y],
		"camera_zoom":[camera.zoom.x,camera.zoom.y]}
	_write_result(request_path.get_base_dir().path_join("result.json"), result)
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)

func _write_result(path: String, result: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("cannot write sandbox result")
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()

func _fail(message: String) -> void:
	push_error("[Operator2DReviewSandbox] %s" % message)
	var args := OS.get_cmdline_user_args()
	var index := args.find("--request")
	if index >= 0 and index + 1 < args.size():
		_write_result(args[index + 1].get_base_dir().path_join("result.json"), {"schema":"custodian.operator_2_5d_sandbox_result.v1", "error":message})
	get_tree().quit(1)

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
