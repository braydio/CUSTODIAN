extends Area2D

@export var item_id: StringName = &"faint_recollection"
@export var quantity: int = 1
@export var pickup_volume_db: float = -12.0
@export var visual_bob_amplitude: float = 2.0
@export var visual_bob_speed: float = 3.5
@export var animation_fps: float = 8.0
@export var animation_frame_count: int = 4

const FLOATING_TEXT_SCENE := preload("res://game/actors/effects/floating_text.tscn")

const ITEM_DISPLAY := {
	&"faint_recollection": "Faint Recollection",
	&"residual_instinct": "Residual Instinct",
	&"ancient_bearing": "Ancient Bearing",
}

const ITEM_COLORS := {
	&"faint_recollection": Color(0.62, 0.82, 1.0, 1.0),
	&"residual_instinct": Color(0.95, 0.55, 0.38, 1.0),
	&"ancient_bearing": Color(0.86, 0.72, 1.0, 1.0),
}

const ITEM_ANIMATION_TEXTURES := {
	&"faint_recollection": preload("res://content/sprites/items/faint_recollection.png"),
	&"residual_instinct": preload("res://content/sprites/items/faded_instinct.png"),
	&"ancient_bearing": preload("res://content/sprites/items/ancient_bearing.png"),
}

@onready var visual: Sprite2D = get_node_or_null("Visual")
@onready var label: Label = get_node_or_null("Label")

var _visual_base_y: float = 0.0
var _visual_time: float = 0.0
var _animation_time: float = 0.0


func _ready() -> void:
	if visual != null:
		_visual_base_y = visual.position.y
	body_entered.connect(_on_body_entered)
	_refresh_visual()


func _process(delta: float) -> void:
	if visual == null:
		return
	_visual_time += delta * visual_bob_speed
	var bob := sin(_visual_time) * visual_bob_amplitude
	visual.position.y = _visual_base_y + bob
	visual.scale = Vector2.ONE * lerp(0.95, 1.05, (sin(_visual_time * 0.8) + 1.0) * 0.5)
	_animation_time += delta
	visual.frame = int(floor(_animation_time * animation_fps)) % max(1, animation_frame_count)


func set_item(new_item_id: StringName, new_quantity: int = 1) -> void:
	item_id = new_item_id
	quantity = max(1, new_quantity)
	_refresh_visual()


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var inventory := get_node_or_null("/root/InventoryManager")
	if inventory != null:
		inventory.add_item(item_id, quantity)

	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null:
		cognitive.add_from_item(item_id, quantity)

	_spawn_pickup_popup()
	_play_pickup_tone()
	print("[CognitivePickup] %s +%d" % [_get_display_name(), quantity])
	queue_free()


func _refresh_visual() -> void:
	if visual != null:
		visual.texture = ITEM_ANIMATION_TEXTURES.get(item_id, null)
		visual.hframes = animation_frame_count if visual.texture != null else 1
		visual.vframes = 1
		visual.frame = 0
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.modulate = Color.WHITE if visual.texture != null else ITEM_COLORS.get(item_id, Color(0.8, 0.85, 0.95, 1.0))
		_animation_time = 0.0
	if label != null:
		label.text = _get_label_text()


func _get_display_name() -> String:
	return str(ITEM_DISPLAY.get(item_id, String(item_id).capitalize()))


func _get_label_text() -> String:
	match item_id:
		&"faint_recollection":
			return "MEM"
		&"residual_instinct":
			return "INST"
		&"ancient_bearing":
			return "BEAR"
		_:
			return "COG"


func _spawn_pickup_popup() -> void:
	if FLOATING_TEXT_SCENE == null:
		return
	var popup = FLOATING_TEXT_SCENE.instantiate()
	if popup == null:
		return
	popup.global_position = global_position + Vector2(0, -22)
	popup.text = "%s +%d" % [_get_display_name(), quantity]
	popup.text_color = ITEM_COLORS.get(item_id, Color(0.8, 0.85, 0.95, 1.0))
	var parent = get_parent()
	if parent:
		parent.add_child(popup)
	else:
		get_tree().current_scene.add_child(popup)


func _play_pickup_tone() -> void:
	var player := AudioStreamPlayer2D.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.2
	player.stream = generator
	player.volume_db = pickup_volume_db
	player.global_position = global_position

	var parent = get_parent()
	if parent:
		parent.add_child(player)
	else:
		get_tree().current_scene.add_child(player)
	player.play()

	var playback = player.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var pb: AudioStreamGeneratorPlayback = playback
		var sample_hz: float = 740.0
		var increment: float = sample_hz / float(generator.mix_rate)
		var phase: float = 0.0
		var total_frames: int = int(float(generator.mix_rate) * 0.12)
		for i in total_frames:
			var env: float = 1.0 - (float(i) / float(max(1, total_frames)))
			var s: float = sin(phase * TAU) * env * 0.30
			pb.push_frame(Vector2(s, s))
			phase = fmod(phase + increment, 1.0)

	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(player.queue_free)
