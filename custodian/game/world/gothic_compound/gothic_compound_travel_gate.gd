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
@export var auto_trigger_offset := Vector2(0, -48)
@export var auto_trigger_size := Vector2(96, 64)
@export_range(1, 120, 1) var teleport_cooldown_frames := 24

var connected_map: Node = null
var presentation_state := PresentationState.INACTIVE
var _layers: Dictionary = {}
var _animation_elapsed := 0.0
var _travel_busy := false
var _auto_area: Area2D
var _last_travel_state := PresentationState.INACTIVE
var _travel_call_count := 0


func _ready() -> void:
	_resolve_connected_map()
	_build_presentation()
	_build_auto_travel_area()
	_register_with_map()
	var route_active := connected_map != null and connected_map.has_method("is_travel_route_active") and bool(connected_map.call("is_travel_route_active"))
	set_presentation_state(PresentationState.ACTIVE if route_active else (PresentationState.ROUTE_AVAILABLE if connected_map != null else PresentationState.INACTIVE))


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
	if presentation_state == PresentationState.ACTIVATING:
		animation.frame = mini(animation.hframes - 1, int(_animation_elapsed * fps))
	else:
		animation.frame = int(_animation_elapsed * fps) % animation.hframes


func configure(map: Node, mode: int, prompt: String) -> void:
	connected_map = map
	travel_mode = mode
	prompt_text = prompt
	if is_inside_tree():
		_register_with_map()
		var route_active := connected_map != null and connected_map.has_method("is_travel_route_active") and bool(connected_map.call("is_travel_route_active"))
		set_presentation_state(PresentationState.ACTIVE if route_active else PresentationState.ROUTE_AVAILABLE)


func get_interaction_prompt() -> String:
	return "%s (%s)" % [prompt_text, _get_interact_prompt_key()]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	if _travel_busy or presentation_state == PresentationState.ACTIVATING or presentation_state == PresentationState.INACTIVE:
		return
	_resolve_connected_map()
	if connected_map == null or not _map_can_travel():
		set_presentation_state(PresentationState.FAILURE)
		return
	if connected_map.has_method("is_travel_route_active") and bool(connected_map.call("is_travel_route_active")):
		return
	_travel_busy = true
	set_presentation_state(PresentationState.ACTIVATING)
	_complete_first_activation(actor)


func _complete_first_activation(actor: Node) -> void:
	await get_tree().create_timer(6.0 / 9.0).timeout
	if not is_instance_valid(connected_map) or not _map_can_travel():
		_travel_busy = false
		set_presentation_state(PresentationState.FAILURE)
		return
	if connected_map.has_method("activate_travel_route"):
		connected_map.call("activate_travel_route")
	else:
		set_presentation_state(PresentationState.ACTIVE)
	set_presentation_state(PresentationState.ACTIVE)
	await get_tree().process_frame
	_travel_actor(actor)
	_travel_busy = false


func _travel_actor(actor: Node) -> void:
	if not is_instance_valid(actor) or not _map_can_travel():
		return
	if _is_actor_locked(actor):
		return
	actor.set_meta("portal_teleport_lock_until_frame", Engine.get_physics_frames() + teleport_cooldown_frames)
	_last_travel_state = presentation_state
	_travel_call_count += 1
	match travel_mode:
		TravelMode.ENTER_COMPOUND:
			connected_map.call("enter_from_main", actor)
		TravelMode.RETURN_TO_MAIN:
			connected_map.call("return_to_main", actor)


func _on_auto_travel_body_entered(body: Node2D) -> void:
	if _travel_busy or presentation_state != PresentationState.ACTIVE or connected_map == null:
		return
	if not connected_map.has_method("is_travel_route_active") or not bool(connected_map.call("is_travel_route_active")):
		return
	if not body.is_in_group("player"):
		return
	if _is_actor_locked(body):
		return
	_travel_busy = true
	_travel_actor(body)
	_travel_busy = false


func _is_actor_locked(actor: Node) -> bool:
	return actor.has_meta("portal_teleport_lock_until_frame") and Engine.get_physics_frames() < int(actor.get_meta("portal_teleport_lock_until_frame"))


func _map_can_travel() -> bool:
	if connected_map == null:
		return false
	return connected_map.has_method("enter_from_main") if travel_mode == TravelMode.ENTER_COMPOUND else connected_map.has_method("return_to_main")


func set_presentation_state(next_state: PresentationState) -> void:
	presentation_state = next_state
	if next_state == PresentationState.ACTIVE:
		remove_from_group("interactable")
	elif next_state in [PresentationState.ROUTE_AVAILABLE, PresentationState.FAILURE]:
		add_to_group("interactable")
	else:
		remove_from_group("interactable")
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
		"travel_call_count": _travel_call_count,
		"last_travel_state": _last_travel_state,
		"has_interaction_prompt": is_in_group("interactable"),
		"auto_trigger_offset": auto_trigger_offset,
		"auto_trigger_size": auto_trigger_size,
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


func _register_with_map() -> void:
	if connected_map != null and connected_map.has_method("register_travel_gate"):
		connected_map.call("register_travel_gate", self)


func _build_auto_travel_area() -> void:
	_auto_area = Area2D.new()
	_auto_area.name = "AutoTravelArea"
	_auto_area.position = auto_trigger_offset
	_auto_area.collision_layer = 0
	_auto_area.collision_mask = 1
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = auto_trigger_size
	collision.shape = rectangle
	_auto_area.add_child(collision)
	add_child(_auto_area)
	_auto_area.body_entered.connect(_on_auto_travel_body_entered)


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
