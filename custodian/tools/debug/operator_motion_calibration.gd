extends Node2D
class_name OperatorMotionCalibration

const REQUEST_SCHEMA := "custodian.operator_motion_request.v2"
const GROUND_PRESETS_PATH := "res://tools/operator/motion_ground_presets.json"
const WORLD_FOLLOW_DISTANCE_PX := 96.0
const LOOP_CYCLE_PRESETS := [2, 3, 4, 6, 8]
const CATALOG_FRAMES := preload("res://game/actors/operator/operator_animation_catalog_frames.tres")
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
var ground_presets: Dictionary = {}
var ground_texture: Texture2D
var ground_tile_size := Vector2i(32, 32)


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
	var ground_error := _load_ground_presets()
	if not ground_error.is_empty():
		return ground_error
	var identity := request.get("identity", {}) as Dictionary
	identity_key = "%s/%s/%s/%s" % [identity.get("profile", ""), identity.get("group", ""), identity.get("action", ""), identity.get("direction", "")]
	if identity_key.count("/") != 3 or not resolve_runtime_animation():
		return "Runtime animation unavailable: %s" % identity_key
	return ""


func _load_ground_presets() -> String:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(GROUND_PRESETS_PATH))
	if not parsed is Dictionary or parsed.get("schema", "") != "custodian.operator_motion_ground_presets.v1":
		return "Unsupported motion ground preset registry"
	ground_presets.clear()
	for row_variant in parsed.get("presets", []):
		if row_variant is Dictionary and not String(row_variant.get("id", "")).is_empty():
			ground_presets[String(row_variant.id)] = row_variant
	_resolve_ground_texture()
	return ""


func _resolve_ground_texture() -> void:
	ground_texture = null
	ground_tile_size = Vector2i(32, 32)
	var preset_id := String(request.get("ground", "grid32"))
	var row := ground_presets.get(preset_id, {}) as Dictionary
	var raw_size := row.get("tile_size", [32, 32]) as Array
	if raw_size.size() >= 2:
		ground_tile_size = Vector2i(int(raw_size[0]), int(raw_size[1]))
	var raw_path = row.get("path")
	if raw_path == null or String(raw_path).is_empty():
		return
	var relative := String(raw_path).trim_prefix("custodian/")
	ground_texture = load("res://%s" % relative) as Texture2D


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


func cycle_duration() -> float:
	return float(frame_count) / maxf(0.001, float(request.get("fps", 12.0)))


func loop_cycles() -> int:
	return maxi(1, int(request.get("loop_cycles", 3)))


func sample_motion(elapsed: float) -> Dictionary:
	var duration := cycle_duration()
	var looping := bool(request.get("loop", true))
	var cycle_index := 0
	var phase_sec := 0.0
	if looping:
		var span := duration * float(loop_cycles())
		var span_elapsed := fposmod(elapsed, span)
		cycle_index = mini(loop_cycles() - 1, int(floor(span_elapsed / duration)))
		phase_sec = span_elapsed - float(cycle_index) * duration
	else:
		phase_sec = minf(elapsed, duration)
	var normalized := phase_sec / maxf(0.001, duration)
	var progress := curve_progress(normalized)
	var travel := float(request.get("travel_px", 0.0))
	var phase_distance := travel * progress
	var continuous_distance := float(cycle_index) * travel + phase_distance
	var direction := direction_vector()
	return {
		"normalized": normalized, "progress": progress, "phase_sec": phase_sec,
		"cycle_index": cycle_index, "phase_position": phase_distance,
		"continuous_position": continuous_distance, "phase_root": direction * phase_distance,
		"continuous_root": direction * continuous_distance,
	}


func presentation_offsets(sample: Dictionary) -> Dictionary:
	var looping := bool(request.get("loop", true))
	var root: Vector2 = sample.continuous_root if looping else sample.phase_root
	var distance: float = sample.continuous_position if looping else sample.phase_position
	if String(request.get("mode", "treadmill")) == "treadmill":
		return {"world_offset": -root, "actor_screen_offset": Vector2.ZERO}
	var follow := maxf(0.0, distance - WORLD_FOLLOW_DISTANCE_PX)
	var world_offset := -direction_vector() * follow
	return {"world_offset": world_offset, "actor_screen_offset": root + world_offset}


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
		sprite.centered = true; sprite.position = ANCHOR; sprite.stop(); sprite.frame = 0
		animation_layers.append(sprite); add_child(sprite)
	status_label = Label.new(); status_label.position = Vector2(12, 10); add_child(status_label)
	_update_presentation()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color("12161d"))
	var offsets := presentation_offsets(sample_motion(elapsed_sec))
	var world_offset: Vector2 = offsets.world_offset
	if ground_texture:
		var phase := Vector2(fposmod(world_offset.x, ground_tile_size.x), fposmod(world_offset.y, ground_tile_size.y))
		for y in range(int(phase.y) - ground_tile_size.y, int(CANVAS_SIZE.y), ground_tile_size.y):
			for x in range(int(phase.x) - ground_tile_size.x, int(CANVAS_SIZE.x), ground_tile_size.x):
				draw_texture(ground_texture, Vector2(x, y))
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
	var duration := cycle_duration()
	if bool(request.get("loop", true)):
		var span := duration * float(loop_cycles())
		if elapsed_sec >= span:
			elapsed_sec = fposmod(elapsed_sec, span)
	elif elapsed_sec >= duration:
		elapsed_sec = duration
		playing = false
	_update_presentation()


func _update_presentation() -> void:
	var sample := sample_motion(elapsed_sec)
	var offsets := presentation_offsets(sample)
	for sprite in animation_layers:
		sprite.position = ANCHOR + offsets.actor_screen_offset
		sprite.frame = mini(frame_count - 1, int(floor(sample.normalized * float(frame_count))))
	if status_label:
		status_label.text = ("%s\n%s · %.0f px/cycle\n%s · cycle %d/%d\n%.0f px total") % [
			identity_key, String(request.get("curve", "")).to_upper(),
			float(request.get("travel_px", 0)), String(request.get("mode", "treadmill")).to_upper(),
			int(sample.cycle_index) + 1, loop_cycles(), float(sample.continuous_position),
		]
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: playing = not playing
		KEY_M: request["mode"] = "world" if request.get("mode", "treadmill") == "treadmill" else "treadmill"
		KEY_C:
			var current := CURVES.find(StringName(request.get("curve", "attack_lunge")))
			request["curve"] = String(CURVES[(current + 1) % CURVES.size()])
		KEY_G:
			var ids := ground_presets.keys()
			var current := ids.find(String(request.get("ground", "grid32")))
			request["ground"] = ids[(current + 1) % ids.size()]
			_resolve_ground_texture()
		KEY_L when event.shift_pressed:
			var current_cycles := LOOP_CYCLE_PRESETS.find(loop_cycles())
			request["loop_cycles"] = LOOP_CYCLE_PRESETS[(current_cycles + 1) % LOOP_CYCLE_PRESETS.size()]


func _show_error(message: String) -> void:
	status_label = Label.new(); status_label.text = message; status_label.position = Vector2(12, 10); add_child(status_label)
	push_error("[OperatorMotionCalibration] %s" % message)
