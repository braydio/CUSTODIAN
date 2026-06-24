extends Area2D

@export var ammo_type: String = "kinetic_light"
@export var amount_min: int = 6
@export var amount_max: int = 12
@export var guaranteed: bool = false
@export var debug_refill: bool = false
@export var standard_ammo: int = 0
@export var heavy_ammo: int = 0
@export var pickup_volume_db: float = -10.0

const FLOATING_TEXT_SCENE := preload("res://game/actors/effects/floating_text.tscn")

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body and body.has_method("add_ammo_type"):
		var gained := 0
		if standard_ammo > 0 or heavy_ammo > 0:
			var legacy: Dictionary = body.call("add_ammo", standard_ammo, heavy_ammo)
			gained = int(legacy.get("standard", 0)) + int(legacy.get("heavy", 0))
		else:
			var amount := 999999 if debug_refill else _resolve_pickup_amount()
			gained = int(body.call("add_ammo_type", ammo_type, amount))
		_spawn_typed_pickup_popup(gained)
		_play_pickup_tone()
		queue_free()
	elif body and body.has_method("add_ammo"):
		var gained = body.add_ammo(max(standard_ammo, _resolve_pickup_amount()), heavy_ammo)
		_spawn_pickup_popup(int(gained.get("standard", 0)), int(gained.get("heavy", 0)))
		_play_pickup_tone()
		queue_free()


func _resolve_pickup_amount() -> int:
	var low := mini(amount_min, amount_max)
	var high := maxi(amount_min, amount_max)
	if low == high:
		return max(0, low)
	return low + int((str(global_position).hash() & 0x7fffffff) % (high - low + 1))


func _spawn_typed_pickup_popup(gained: int) -> void:
	if FLOATING_TEXT_SCENE == null:
		return
	var popup = FLOATING_TEXT_SCENE.instantiate()
	if popup == null:
		return
	popup.global_position = global_position + Vector2(0, -20)
	popup.text = "+%d %s" % [gained, ammo_type.to_upper()]
	popup.text_color = Color(0.7, 1.0, 0.7, 1.0)
	var parent = get_parent()
	(parent if parent else get_tree().current_scene).add_child(popup)


func _spawn_pickup_popup(gained_standard: int, gained_heavy: int):
	if FLOATING_TEXT_SCENE == null:
		return
	var popup = FLOATING_TEXT_SCENE.instantiate()
	if popup == null:
		return
	popup.global_position = global_position + Vector2(0, -20)
	popup.text = "+%d STD  +%d HVY" % [gained_standard, gained_heavy]
	popup.text_color = Color(0.7, 1.0, 0.7, 1.0)
	var parent = get_parent()
	if parent:
		parent.add_child(popup)
	else:
		get_tree().current_scene.add_child(popup)


func _play_pickup_tone():
	var player = AudioStreamPlayer2D.new()
	var generator = AudioStreamGenerator.new()
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
		var sample_hz: float = 980.0
		var increment: float = sample_hz / float(generator.mix_rate)
		var phase: float = 0.0
		var total_frames: int = int(float(generator.mix_rate) * 0.12)
		for i in total_frames:
			var env: float = 1.0 - (float(i) / float(max(1, total_frames)))
			var s: float = sin(phase * TAU) * env * 0.38
			pb.push_frame(Vector2(s, s))
			phase = fmod(phase + increment, 1.0)

	var t = get_tree().create_timer(0.2)
	t.timeout.connect(player.queue_free)
