extends Node2D
class_name OperatorMotionCalibration

const REQUEST_SCHEMA := "custodian.operator_motion_request.v1"
const CATALOG_FRAMES := preload("res://game/actors/operator/operator_animation_catalog_frames.tres")
const CAVERN_GROUND := preload("res://content/tiles/encounters/ritualant_set/underground/ritualant_underground__ground__cavern_repeat_01__512x512.png")
const CANVAS_SIZE := Vector2(768.0, 384.0)
const ANCHOR := Vector2(384.0, 224.0)
const CURVES := [&"constant", &"linear", &"ease_in", &"ease_out", &"ease_in_out", &"attack_lunge"]

var request: Dictionary = {}
var identity_key := ""
var frame_count := 0
var elapsed_sec := 0.0
var playing := true
var animation_layers: Array[AnimatedSprite2D] = []
var status_label: Label


func _ready() -> void:
	var request_path := _request_path_from_args(OS.get_cmdline_args())
	if request_path.is_empty():
		_show_error("No --motion-request supplied")
		return
	var error := load_request(request_path)
	if not error.is_empty():
		_show_error(error)
		return
	_build_runtime_view()
	set_process(true)


func _request_path_from_args(arguments: PackedStringArray) -> String:
	var index := arguments.find("--motion-request")
	return arguments[index + 1] if index >= 0 and index + 1 < arguments.size() else ""


func load_request(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "Motion request not found: %s" % path
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("schema", "") != REQUEST_SCHEMA:
		return "Unsupported motion request"
	request = parsed
	var identity := request.get("identity", {}) as Dictionary
	identity_key = "%s/%s/%s/%s" % [identity.get("profile", ""), identity.get("group", ""), identity.get("action", ""), identity.get("direction", "")]
	if identity_key.count("/") != 3 or not resolve_runtime_animation():
		return "Runtime animation unavailable: %s" % identity_key
	return ""


func resolve_runtime_animation() -> bool:
	frame_count = 0
	for layer_name in [&"lower_body", &"upper_body", &"full_body", &"head", &"cape", &"weapon", &"fx"]:
		var animation := StringName("%s/%s" % [identity_key, layer_name])
		if CATALOG_FRAMES.has_animation(animation):
			frame_count = maxi(frame_count, CATALOG_FRAMES.get_frame_count(animation))
	return frame_count > 0


func direction_vector() -> Vector2:
	var direction := String((request.get("identity", {}) as Dictionary).get("direction", "e"))
	var vectors := {"e": Vector2.RIGHT, "w": Vector2.LEFT, "n": Vector2.UP, "s": Vector2.DOWN,
		"ne": Vector2(1, -1), "nw": Vector2(-1, -1), "se": Vector2(1, 1), "sw": Vector2(-1, 1), "omni": Vector2.RIGHT}
	return (vectors.get(direction, Vector2.RIGHT) as Vector2).normalized()


func curve_progress(normalized: float) -> float:
	var t := clampf(normalized, 0.0, 1.0)
	match String(request.get("curve", "attack_lunge")):
		"constant", "linear": return t
		"ease_in": return t * t
		"ease_out": return 1.0 - pow(1.0 - t, 2.0)
		"ease_in_out": return smoothstep(0.0, 1.0, t)
		"attack_lunge":
			var points := [Vector2(0.0, 0.0), Vector2(0.15, 0.03), Vector2(0.35, 0.25), Vector2(0.60, 0.72), Vector2(0.80, 0.94), Vector2(1.0, 1.0)]
			for index in range(points.size() - 1):
				var left: Vector2 = points[index]
				var right: Vector2 = points[index + 1]
				if t <= right.x:
					var local := (t - left.x) / (right.x - left.x)
					return lerpf(left.y, right.y, smoothstep(0.0, 1.0, local))
	return 1.0


func sample_offsets(normalized: float) -> Dictionary:
	var root := direction_vector() * float(request.get("travel_px", 0.0)) * curve_progress(normalized)
	return {"progress": curve_progress(normalized), "world_actor": root, "treadmill_ground": -root}


func _build_runtime_view() -> void:
	var available: Dictionary = {}
	for name in [&"lower_body", &"upper_body", &"full_body", &"head", &"cape", &"weapon", &"fx"]:
		available[name] = CATALOG_FRAMES.has_animation(StringName("%s/%s" % [identity_key, name]))
	var layers := [&"lower_body", &"upper_body"] if available[&"lower_body"] and available[&"upper_body"] else [&"full_body"]
	for overlay in [&"head", &"cape", &"weapon", &"fx"]:
		if available[overlay]: layers.append(overlay)
	for name in layers:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = CATALOG_FRAMES; sprite.animation = StringName("%s/%s" % [identity_key, name])
		sprite.centered = true; sprite.position = ANCHOR; sprite.play()
		animation_layers.append(sprite); add_child(sprite)
	status_label = Label.new(); status_label.position = Vector2(12, 10); add_child(status_label)
	_update_presentation(0.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color("12161d"))
	var normalized := elapsed_sec / maxf(0.001, float(frame_count) / maxf(0.001, float(request.get("fps", 12.0))))
	var offsets := sample_offsets(normalized)
	var world_offset: Vector2 = offsets.treadmill_ground if request.get("mode", "treadmill") == "treadmill" else Vector2.ZERO
	if request.get("ground", "grid32") == "ritualant_cavern":
		var phase := Vector2(fposmod(world_offset.x, 512.0), fposmod(world_offset.y, 512.0))
		for y in range(int(phase.y) - 512, int(CANVAS_SIZE.y), 512):
			for x in range(int(phase.x) - 512, int(CANVAS_SIZE.x), 512):
				draw_texture(CAVERN_GROUND, Vector2(x, y))
	var grid_phase := Vector2(fposmod(world_offset.x, 32.0), fposmod(world_offset.y, 32.0))
	for x in range(int(grid_phase.x), int(CANVAS_SIZE.x), 32):
		var alpha := 0.48 if int(x - grid_phase.x) % 96 == 0 else 0.26
		draw_line(Vector2(x, 0), Vector2(x, CANVAS_SIZE.y), Color(0.72, 0.78, 0.84, alpha))
	for y in range(int(grid_phase.y), int(CANVAS_SIZE.y), 32):
		var alpha_y := 0.48 if int(y - grid_phase.y) % 96 == 0 else 0.26
		draw_line(Vector2(0, y), Vector2(CANVAS_SIZE.x, y), Color(0.72, 0.78, 0.84, alpha_y))


func _process(delta: float) -> void:
	if playing:
		elapsed_sec += delta
	var duration := float(frame_count) / maxf(0.001, float(request.get("fps", 12.0)))
	if elapsed_sec >= duration: elapsed_sec = fmod(elapsed_sec, duration)
	_update_presentation(elapsed_sec / duration)


func _update_presentation(normalized: float) -> void:
	var offsets := sample_offsets(normalized)
	var mode := String(request.get("mode", "treadmill"))
	for sprite in animation_layers:
		sprite.position = ANCHOR + (offsets.world_actor if mode == "world" else Vector2.ZERO)
	if status_label:
		status_label.text = "%s\n%s · %.0f px · %.3f s\n%s · %.1f%%" % [identity_key, String(request.get("curve", "")).to_upper(), float(request.get("travel_px", 0)), float(frame_count) / float(request.get("fps", 12.0)), mode.to_upper(), normalized * 100.0]
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: playing = not playing
		KEY_M: request["mode"] = "world" if request.get("mode", "treadmill") == "treadmill" else "treadmill"
		KEY_C:
			var current := CURVES.find(StringName(request.get("curve", "attack_lunge")))
			request["curve"] = String(CURVES[(current + 1) % CURVES.size()])
		KEY_G: request["ground"] = "grid32" if request.get("ground", "ritualant_cavern") == "ritualant_cavern" else "ritualant_cavern"


func _show_error(message: String) -> void:
	status_label = Label.new(); status_label.text = message; status_label.position = Vector2(12, 10); add_child(status_label)
	push_error("[OperatorMotionCalibration] %s" % message)
