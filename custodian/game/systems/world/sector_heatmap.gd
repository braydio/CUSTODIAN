extends Node

@export var tile_size: int = 32
@export var sample_interval_sec: float = 0.25

var heat: Dictionary = {}
var active_channel: String = "player_presence"
var _sample_timer: float = 0.0


func _process(delta: float) -> void:
	_sample_timer += delta
	if _sample_timer < sample_interval_sec:
		return
	_sample_timer = 0.0

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	add(player.global_position, "player_presence", sample_interval_sec)
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		observatory.call("set_gauge", "heat_player_presence_cells", get_hot_cells("player_presence", 0.01).size())


func add(position: Vector2, channel: String, amount := 1.0) -> void:
	var cell := _cell(position)
	if not heat.has(cell):
		heat[cell] = {}
	var channels: Dictionary = heat[cell]
	channels[channel] = float(channels.get(channel, 0.0)) + float(amount)
	heat[cell] = channels


func get_value(position: Vector2, channel: String) -> float:
	var cell := _cell(position)
	if not heat.has(cell):
		return 0.0
	return float((heat[cell] as Dictionary).get(channel, 0.0))


func get_hot_cells(channel: String, minimum := 1.0) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for cell in heat.keys():
		var value := float((heat[cell] as Dictionary).get(channel, 0.0))
		if value >= float(minimum):
			output.append({
				"cell": cell,
				"value": value,
			})
	return output


func get_top_hot_cells(channel: String, limit := 10) -> Array[Dictionary]:
	var hot_cells := get_hot_cells(channel, 0.01)
	hot_cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("value", 0.0)) > float(b.get("value", 0.0))
	)
	if hot_cells.size() <= limit:
		return hot_cells
	return hot_cells.slice(0, limit)


func get_active_channel() -> String:
	return active_channel


func set_active_channel(channel: String) -> void:
	active_channel = channel


func _cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / float(tile_size)), floor(pos.y / float(tile_size)))
