extends Area2D
class_name LatticeFieldPatchPickup

@export var patch_amount: int = 1
@export var fallback_materials: Dictionary = {
	"resin_clot": 1,
	"capacitor_dust": 1,
}
@export var pickup_volume_db: float = -12.0

const FLOATING_TEXT_SCENE := preload("res://game/actors/effects/floating_text.tscn")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if not body.has_method("add_field_patches"):
		return

	var gained := int(body.call("add_field_patches", patch_amount))
	if gained > 0:
		_spawn_pickup_popup("+%d FIELD PATCH" % gained, Color(0.55, 0.95, 0.78, 1.0))
	else:
		_grant_fallback_materials()
		_spawn_pickup_popup("FIELD PATCH FULL // MATERIALS", Color(0.95, 0.82, 0.45, 1.0))
	_play_pickup_tone()
	queue_free()


func _grant_fallback_materials() -> void:
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger == null:
		return
	for resource_id_variant in fallback_materials.keys():
		var amount := int(fallback_materials[resource_id_variant])
		if amount > 0:
			ledger.call("add", str(resource_id_variant), amount)


func _spawn_pickup_popup(text: String, color: Color) -> void:
	if FLOATING_TEXT_SCENE == null:
		return
	var popup := FLOATING_TEXT_SCENE.instantiate()
	if popup == null:
		return
	popup.global_position = global_position + Vector2(0, -22)
	popup.text = text
	popup.text_color = color
	var parent := get_parent()
	if parent != null:
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

	var parent := get_parent()
	if parent != null:
		parent.add_child(player)
	else:
		get_tree().current_scene.add_child(player)
	player.play()

	var playback := player.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var pb := playback as AudioStreamGeneratorPlayback
		var sample_hz := 820.0
		var increment := sample_hz / float(generator.mix_rate)
		var phase := 0.0
		var total_frames := int(float(generator.mix_rate) * 0.12)
		for i in total_frames:
			var env := 1.0 - (float(i) / float(max(1, total_frames)))
			var sample := sin(phase * TAU) * env * 0.32
			pb.push_frame(Vector2(sample, sample))
			phase = fmod(phase + increment, 1.0)

	var timer := get_tree().create_timer(0.2)
	timer.timeout.connect(player.queue_free)
