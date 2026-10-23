class_name RoadProcessionSequence
extends Node2D

const EVENT_ID: StringName = &"hub_road_procession_v1"
const RECORD_SCHEMA := "custodian.hub_authored_event.road_procession.v1"
const BEAT_NAMES: Array[StringName] = [&"south", &"middle", &"north"]
const BEAT_POSITIONS: Array[Vector2] = [
	Vector2(0.0, -1376.0),
	Vector2(0.0, -1792.0),
	Vector2(0.0, -2208.0),
]
const TRIGGER_RADIUS := 44.0
const BELL_SAMPLE_RATE := 22050
const BELL_DURATION_SECONDS := 0.85

class ProcessionLamp extends Node2D:
	const FADE_SECONDS := 1.4
	var tint := Color("e6c982")
	var intensity := 0.0
	var light: PointLight2D

	func activate() -> void:
		intensity = 1.0
		if light != null:
			light.energy = 0.7
		set_process(true)
		queue_redraw()

	func _ready() -> void:
		light = PointLight2D.new()
		light.name = "LocalLampLight"
		light.color = tint
		light.energy = 0.0
		light.texture_scale = 2.2
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 0.62),
			Color(1.0, 1.0, 1.0, 0.0),
		])
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		var texture := GradientTexture2D.new()
		texture.width = 128
		texture.height = 128
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.gradient = gradient
		light.texture = texture
		light.shadow_enabled = false
		add_child(light)
		set_process(false)

	func _process(delta: float) -> void:
		intensity = maxf(0.0, intensity - delta / FADE_SECONDS)
		light.energy = intensity * 0.7
		queue_redraw()
		if intensity <= 0.0:
			set_process(false)

	func _draw() -> void:
		if intensity <= 0.0:
			return
		draw_circle(Vector2.ZERO, 52.0, Color(tint, 0.035 * intensity))
		draw_circle(Vector2.ZERO, 30.0, Color(tint, 0.09 * intensity))
		draw_circle(Vector2.ZERO, 14.0, Color(tint, 0.24 * intensity))
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color(tint.lightened(0.22), 0.8 * intensity), 2.0)


var _hub_state: HubState
var _event_state: Dictionary = {}
var _lamps: Array[ProcessionLamp] = []
var _bells: Array[AudioStreamPlayer2D] = []
var _activation_order: Array[StringName] = []
var _beat_activation_count := 0
var _bell_activation_count := 0


func configure(hub_state: HubState) -> void:
	_hub_state = hub_state


func get_sequence_snapshot() -> Dictionary:
	return {
		"event_id": EVENT_ID,
		"completed_beats": int(_event_state.get("completed_beats", 0)),
		"sequence_complete": bool(_event_state.get("sequence_complete", false)),
		"beat_activation_count": _beat_activation_count,
		"bell_activation_count": _bell_activation_count,
		"activation_order": _activation_order.duplicate(),
		"lamp_intensities": _lamp_intensities(),
		"lamp_energies": _lamp_energies(),
	}


func _ready() -> void:
	if _hub_state == null:
		push_error("[RoadProcessionSequence] HubState binding is required")
		return
	_event_state = _normalize_record(_hub_state.get_authored_event_record(EVENT_ID))
	for index in BEAT_POSITIONS.size():
		_add_beat(index)


func _add_beat(index: int) -> void:
	var area := Area2D.new()
	area.name = "%sTrigger" % String(BEAT_NAMES[index]).capitalize()
	area.position = BEAT_POSITIONS[index]
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = TRIGGER_RADIUS
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered.bind(index))
	add_child(area)

	var lamp := ProcessionLamp.new()
	lamp.name = "%sLamp" % String(BEAT_NAMES[index]).capitalize()
	lamp.position = BEAT_POSITIONS[index]
	add_child(lamp)
	_lamps.append(lamp)

	var bell := AudioStreamPlayer2D.new()
	bell.name = "%sBell" % String(BEAT_NAMES[index]).capitalize()
	bell.position = BEAT_POSITIONS[index]
	bell.max_distance = 2400.0
	bell.volume_db = -8.0
	bell.stream = _make_bell_stream(index)
	add_child(bell)
	_bells.append(bell)


func _on_body_entered(body: Node2D, beat_index: int) -> void:
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
	if bool(_event_state.get("sequence_complete", false)):
		return
	var completed := int(_event_state.get("completed_beats", 0))
	if beat_index != completed or beat_index < 0 or beat_index >= BEAT_POSITIONS.size():
		return

	_lamps[beat_index].activate()
	_bells[beat_index].play()
	_activation_order.append(BEAT_NAMES[beat_index])
	_beat_activation_count += 1
	_bell_activation_count += 1
	completed += 1
	_event_state["completed_beats"] = completed
	_event_state["sequence_complete"] = completed == BEAT_POSITIONS.size()
	_event_state["last_beat"] = String(BEAT_NAMES[beat_index])
	_hub_state.set_authored_event_record(EVENT_ID, _event_state)


func _normalize_record(record: Dictionary) -> Dictionary:
	if record.has("schema") and str(record.get("schema", "")) != RECORD_SCHEMA:
		return _default_record()
	var completed := clampi(int(record.get("completed_beats", 0)), 0, BEAT_POSITIONS.size())
	return {
		"schema": RECORD_SCHEMA,
		"completed_beats": completed,
		"sequence_complete": completed == BEAT_POSITIONS.size(),
		"last_beat": String(BEAT_NAMES[completed - 1]) if completed > 0 else "",
	}


func _default_record() -> Dictionary:
	return {
		"schema": RECORD_SCHEMA,
		"completed_beats": 0,
		"sequence_complete": false,
		"last_beat": "",
	}


func _lamp_intensities() -> Array[float]:
	var values: Array[float] = []
	for lamp in _lamps:
		values.append(lamp.intensity)
	return values


func _lamp_energies() -> Array[float]:
	var values: Array[float] = []
	for lamp in _lamps:
		values.append(lamp.light.energy if lamp.light != null else 0.0)
	return values


func _make_bell_stream(beat_index: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = BELL_SAMPLE_RATE
	stream.stereo = false
	var sample_count := int(BELL_SAMPLE_RATE * BELL_DURATION_SECONDS)
	var raw := PackedByteArray()
	raw.resize(sample_count * 2)
	var fundamentals := [659.25, 554.37, 440.0]
	var fundamental: float = fundamentals[beat_index]
	for sample_index in sample_count:
		var time := float(sample_index) / float(BELL_SAMPLE_RATE)
		var envelope := exp(-time * 4.8) * (1.0 - exp(-time * 48.0))
		var tone := sin(TAU * fundamental * time)
		tone += 0.48 * sin(TAU * fundamental * 2.01 * time)
		tone += 0.24 * sin(TAU * fundamental * 2.98 * time)
		tone += 0.12 * sin(TAU * fundamental * 4.13 * time)
		var pcm := clampf(tone * envelope * 0.28, -1.0, 1.0)
		raw.encode_s16(sample_index * 2, int(round(pcm * 32767.0)))
	stream.data = raw
	return stream
