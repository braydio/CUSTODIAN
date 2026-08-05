extends Area2D

@export var material_amount: int = 3
@export var pickup_volume_db: float = -6.0

const FLOATING_TEXT_SCENE := preload("res://game/actors/effects/floating_text.tscn")
const SCRAP_PICKUP_SOUND: AudioStream = preload("res://content/audio/sfx/items/pickup_collect_01.wav")


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
	_show_loot_toast(&"parts", "Recovered Parts", material_amount, Color(0.95, 0.82, 0.45, 1.0))
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
	player.name = "ScrapPickupAudio"
	player.stream = SCRAP_PICKUP_SOUND
	player.volume_db = pickup_volume_db
	player.max_distance = 320.0
	player.global_position = global_position
	var parent = get_parent()
	if parent:
		parent.add_child(player)
	else:
		get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _show_loot_toast(item_id: StringName, display_name: String, amount: int, accent: Color, icon: Texture2D = null, detail: String = "") -> void:
	var queue := get_tree().get_first_node_in_group("loot_toast_queue")
	if queue != null:
		queue.call("push_pickup", item_id, display_name, amount, accent, icon, detail)
