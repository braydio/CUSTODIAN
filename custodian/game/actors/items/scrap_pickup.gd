extends Area2D

@export var material_amount: int = 3
@export var pickup_volume_db: float = -14.0

const FLOATING_TEXT_SCENE := preload("res://game/actors/effects/floating_text.tscn")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func set_material_amount(amount: int) -> void:
	material_amount = max(0, amount)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("add_materials"):
		game_state.call("add_materials", material_amount)
	_spawn_pickup_popup()
	_play_pickup_tone()
	queue_free()


func _spawn_pickup_popup() -> void:
	if FLOATING_TEXT_SCENE == null:
		return
	var popup = FLOATING_TEXT_SCENE.instantiate()
	if popup == null:
		return
	popup.global_position = global_position + Vector2(0, -20)
	popup.text = "+%d PARTS" % material_amount
	popup.text_color = Color(0.95, 0.85, 0.45, 1.0)
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
		var sample_hz: float = 620.0
		var increment: float = sample_hz / float(generator.mix_rate)
		var phase: float = 0.0
		var total_frames: int = int(float(generator.mix_rate) * 0.12)
		for i in total_frames:
			var env: float = 1.0 - (float(i) / float(max(1, total_frames)))
			var s: float = sin(phase * TAU) * env * 0.32
			pb.push_frame(Vector2(s, s))
			phase = fmod(phase + increment, 1.0)

	var t = get_tree().create_timer(0.2)
	t.timeout.connect(player.queue_free)
