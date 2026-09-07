extends Node2D
class_name GothicCompoundTravelGate

enum TravelMode { ENTER_COMPOUND, RETURN_TO_MAIN }
enum PresentationState { INACTIVE, ROUTE_AVAILABLE, ACTIVATING, ACTIVE, FAILURE }

const ROOT := "res://content/sprites/environment/structure/district_transfer_frame/runtime/"
const TEXTURES := {
	"body": preload(ROOT + "body/structure/district_transfer_frame__body__structure__body__omni__1f__192x256.png"),
	"threshold": preload(ROOT + "body/structure/district_transfer_frame__body__structure__threshold__omni__1f__160x96.png"),
	"contact_shadow": preload(ROOT + "fx/structure/district_transfer_frame__fx__structure__contact_shadow__omni__1f__192x96.png"),
	"aperture_loop": preload(ROOT + "fx/interaction/district_transfer_frame__fx__interaction__aperture_loop__omni__8f__96x160.png"),
	"boot": preload(ROOT + "fx/interaction/district_transfer_frame__fx__interaction__boot__omni__6f__96x160.png"),
	"failure": preload(ROOT + "fx/interaction/district_transfer_frame__fx__interaction__failure__omni__6f__96x160.png"),
	"emissive_dead": preload(ROOT + "fx/state/district_transfer_frame__fx__state__emissive_dead__omni__1f__192x256.png"),
	"emissive_standby": preload(ROOT + "fx/state/district_transfer_frame__fx__state__emissive_standby__omni__1f__192x256.png"),
	"emissive_acquiring": preload(ROOT + "fx/state/district_transfer_frame__fx__state__emissive_acquiring__omni__1f__192x256.png"),
	"emissive_active": preload(ROOT + "fx/state/district_transfer_frame__fx__state__emissive_active__omni__1f__192x256.png"),
	"pedestal": preload(ROOT + "body/control/district_transfer_frame__body__control__pedestal__omni__1f__64x96.png"),
	"pedestal_screen_off": preload(ROOT + "fx/control/district_transfer_frame__fx__control__screen_off__omni__1f__32x32.png"),
	"pedestal_screen_ready": preload(ROOT + "fx/control/district_transfer_frame__fx__control__screen_ready__omni__1f__32x32.png"),
	"pedestal_screen_acquiring": preload(ROOT + "fx/control/district_transfer_frame__fx__control__screen_acquiring__omni__1f__32x32.png"),
	"pedestal_screen_active": preload(ROOT + "fx/control/district_transfer_frame__fx__control__screen_active__omni__1f__32x32.png"),
	"route_plate": preload(ROOT + "body/control/district_transfer_frame__body__control__route_plate__omni__1f__96x32.png"),
	"service_junction": preload(ROOT + "body/control/district_transfer_frame__body__control__service_junction__omni__1f__64x64.png"),
	"cable_feed_left": preload(ROOT + "body/dressing/district_transfer_frame__body__dressing__cable_feed_left__omni__1f__96x128.png"),
	"cable_feed_right": preload(ROOT + "body/dressing/district_transfer_frame__body__dressing__cable_feed_right__omni__1f__96x128.png"),
}

@export var travel_mode: TravelMode = TravelMode.ENTER_COMPOUND
@export var prompt_text: String = "ENTER CARROW YARD"
@export_range(32.0, 192.0, 1.0) var interaction_distance: float = 92.0
@export var connected_map_path: NodePath

var connected_map: Node = null
var presentation_state := PresentationState.INACTIVE
var _layers: Dictionary = {}
var _animation_elapsed := 0.0


func _ready() -> void:
	add_to_group("interactable")
	_resolve_connected_map()
	_build_presentation()
	set_presentation_state(PresentationState.ROUTE_AVAILABLE if connected_map != null else PresentationState.INACTIVE)


func _process(delta: float) -> void:
	var animation := _layers.get("interaction") as Sprite2D
	if animation == null or not animation.visible:
		return
	_animation_elapsed += delta
	var fps := 7.0
	if presentation_state == PresentationState.ACTIVATING:
		fps = 9.0
	elif presentation_state == PresentationState.FAILURE:
		fps = 8.0
	animation.frame = int(_animation_elapsed * fps) % animation.hframes


func configure(map: Node, mode: int, prompt: String) -> void:
	connected_map = map
	travel_mode = mode
	prompt_text = prompt
	if is_inside_tree():
		set_presentation_state(PresentationState.ROUTE_AVAILABLE)


func get_interaction_prompt() -> String:
	return "%s (%s)" % [prompt_text, _get_interact_prompt_key()]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	_resolve_connected_map()
	if connected_map == null:
		set_presentation_state(PresentationState.FAILURE)
		return
	set_presentation_state(PresentationState.ACTIVATING)
	match travel_mode:
		TravelMode.ENTER_COMPOUND:
			if connected_map.has_method("enter_from_main"):
				connected_map.call("enter_from_main", actor)
		TravelMode.RETURN_TO_MAIN:
			if connected_map.has_method("return_to_main"):
				connected_map.call("return_to_main", actor)
	set_presentation_state(PresentationState.ACTIVE)


func set_presentation_state(next_state: PresentationState) -> void:
	presentation_state = next_state
	_animation_elapsed = 0.0
	if _layers.is_empty():
		return
	_set_visible("emissive_dead", next_state == PresentationState.INACTIVE)
	_set_visible("emissive_standby", next_state == PresentationState.ROUTE_AVAILABLE)
	_set_visible("emissive_acquiring", next_state == PresentationState.ACTIVATING)
	_set_visible("emissive_active", next_state == PresentationState.ACTIVE)
	_set_visible("pedestal_screen_off", next_state == PresentationState.INACTIVE or next_state == PresentationState.FAILURE)
	_set_visible("pedestal_screen_ready", next_state == PresentationState.ROUTE_AVAILABLE)
	_set_visible("pedestal_screen_acquiring", next_state == PresentationState.ACTIVATING)
	_set_visible("pedestal_screen_active", next_state == PresentationState.ACTIVE)
	var interaction := _layers.get("interaction") as Sprite2D
	interaction.visible = next_state in [PresentationState.ACTIVATING, PresentationState.ACTIVE, PresentationState.FAILURE]
	interaction.texture = TEXTURES["boot" if next_state == PresentationState.ACTIVATING else ("failure" if next_state == PresentationState.FAILURE else "aperture_loop")]
	interaction.hframes = 8 if next_state == PresentationState.ACTIVE else 6
	interaction.frame = 0


func get_presentation_debug_state() -> Dictionary:
	return {
		"state": presentation_state,
		"production_layers": _layers.keys(),
		"interaction_frames": (_layers.get("interaction") as Sprite2D).hframes,
		"scale": scale,
	}


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


func _build_presentation() -> void:
	var art := Node2D.new()
	art.name = "DistrictTransferFramePresentation"
	add_child(art)
	_add_layer(art, "contact_shadow", Vector2(0, -24), -3)
	_add_layer(art, "cable_feed_left", Vector2(-126, -64), -2)
	_add_layer(art, "cable_feed_right", Vector2(126, -64), -2)
	_add_layer(art, "body", Vector2(0, -128), -1)
	_add_layer(art, "threshold", Vector2(0, -48), 0)
	_add_layer(art, "route_plate", Vector2(0, -182), 1)
	_add_layer(art, "service_junction", Vector2(-122, -32), 1)
	_add_layer(art, "pedestal", Vector2(126, -48), 1)
	for layer_name in ["emissive_dead", "emissive_standby", "emissive_acquiring", "emissive_active"]:
		_add_layer(art, layer_name, Vector2(0, -128), 2)
	for layer_name in ["pedestal_screen_off", "pedestal_screen_ready", "pedestal_screen_acquiring", "pedestal_screen_active"]:
		_add_layer(art, layer_name, Vector2(126, -66), 3)
	var interaction := Sprite2D.new()
	interaction.name = "Interaction"
	interaction.centered = true
	interaction.position = Vector2(0, -104)
	interaction.z_index = 3
	art.add_child(interaction)
	_layers["interaction"] = interaction


func _add_layer(parent: Node2D, layer_name: String, layer_position: Vector2, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = layer_name.to_pascal_case()
	sprite.centered = true
	sprite.position = layer_position
	sprite.z_index = z
	sprite.texture = TEXTURES[layer_name]
	parent.add_child(sprite)
	_layers[layer_name] = sprite


func _set_visible(layer_name: String, value: bool) -> void:
	(_layers.get(layer_name) as Sprite2D).visible = value


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return "INTERACT"
