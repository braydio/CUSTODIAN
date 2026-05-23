extends Node2D
class_name GothicCompoundTravelGate

enum TravelMode { ENTER_COMPOUND, RETURN_TO_MAIN }

@export var travel_mode: TravelMode = TravelMode.ENTER_COMPOUND
@export var prompt_text: String = "ENTER GOTHIC COMPOUND"
@export_range(32.0, 192.0, 1.0) var interaction_distance: float = 92.0
@export var gate_texture: Texture2D = null
@export var connected_map_path: NodePath

var connected_map: Node = null
var _sprite: Sprite2D = null


func _ready() -> void:
	add_to_group("interactable")
	_resolve_connected_map()
	_ensure_visual()


func configure(map: Node, mode: int, prompt: String) -> void:
	connected_map = map
	travel_mode = mode
	prompt_text = prompt


func get_interaction_prompt() -> String:
	var key := _get_interact_prompt_key()
	return "%s (%s)" % [prompt_text, key]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	_resolve_connected_map()
	if connected_map == null:
		return
	match travel_mode:
		TravelMode.ENTER_COMPOUND:
			if connected_map.has_method("enter_from_main"):
				connected_map.call("enter_from_main", actor)
		TravelMode.RETURN_TO_MAIN:
			if connected_map.has_method("return_to_main"):
				connected_map.call("return_to_main", actor)


func _resolve_connected_map() -> void:
	if connected_map != null and is_instance_valid(connected_map):
		return
	if connected_map_path.is_empty():
		var parent_map := get_parent()
		if parent_map != null and parent_map.has_method("return_to_main"):
			connected_map = parent_map
		return
	var node := get_node_or_null(connected_map_path)
	if node != null and (node.has_method("enter_from_main") or node.has_method("return_to_main")):
		connected_map = node


func _ensure_visual() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "GateSprite"
	_sprite.centered = true
	_sprite.position = Vector2(0.0, -34.0)
	_sprite.texture = gate_texture
	if _sprite.texture == null:
		_sprite.texture = _load_first_existing_texture([
			"res://content/procgen/special_rooms/gothic_compound/39_gate_open_arch_frame.png",
			"res://content/procgen/special_rooms/gothic_compound/07_gate_arch_open_gothic.png",
		])
	if _sprite.texture != null:
		_sprite.scale = Vector2(1.25, 1.25)
	else:
		_sprite.modulate = Color(0.65, 0.54, 0.42, 1.0)
	add_child(_sprite)

	var marker := Polygon2D.new()
	marker.name = "TravelMarker"
	marker.color = Color(0.95, 0.68, 0.22, 0.38)
	marker.polygon = PackedVector2Array([
		Vector2(-26, 0),
		Vector2(0, -14),
		Vector2(26, 0),
		Vector2(0, 14),
	])
	add_child(marker)


func _load_first_existing_texture(paths: Array[String]) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return "INTERACT"
