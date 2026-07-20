class_name InfrastructureStructure
extends StaticBody2D

signal construction_state_changed(previous: StringName, current: StringName)
signal construction_progressed(progress: float)
signal commissioned()
signal integrity_changed(current: float, maximum: float)
signal structure_destroyed()

const STATE_FOUNDATION := &"foundation"
const STATE_UNDER_CONSTRUCTION := &"under_construction"
const STATE_COMMISSIONING := &"commissioning"
const STATE_OPERATIONAL := &"operational"
const STATE_DAMAGED := &"damaged"
const STATE_DISABLED := &"disabled"
const STATE_DESTROYED := &"destroyed"

@export var definition: StructureDefinition
@export var infrastructure_instance_id: StringName
@export var prebuilt_operational: bool = false
@export var registry_persistent: bool = true
@export var world_context_id: StringName = &"compound"
@export var auto_start_construction: bool = false

var construction_state: StringName = STATE_FOUNDATION
var construction_elapsed: float = 0.0
var current_integrity: float = 1.0
var _restore_payload: Dictionary = {}
var _destroyed: bool = false


func _ready() -> void:
	add_to_group("structure")
	add_to_group("infrastructure_structure")
	if definition != null:
		current_integrity = definition.max_integrity
	if not _restore_payload.is_empty():
		_apply_restore_payload(_restore_payload)
	elif prebuilt_operational:
		construction_state = STATE_OPERATIONAL
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	if registry != null and registry.has_method("register_structure"):
		registry.call("register_structure", self)
	_set_components_active(_is_commissioned_state())
	if auto_start_construction and construction_state == STATE_FOUNDATION:
		begin_construction()
	_update_presentation()


func _exit_tree() -> void:
	_set_components_active(false)
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	if registry != null and registry.has_method("unregister_structure"):
		registry.call("unregister_structure", self)


func _process(delta: float) -> void:
	if construction_state != STATE_UNDER_CONSTRUCTION:
		return
	construction_elapsed += maxf(0.0, delta)
	var duration := get_construction_duration()
	construction_progressed.emit(1.0 if duration <= 0.0 else clampf(construction_elapsed / duration, 0.0, 1.0))
	if construction_elapsed + 0.0001 >= duration:
		complete_construction()


func get_structure_id() -> StringName:
	return definition.structure_id if definition != null else &"unknown_structure"


func get_construction_duration() -> float:
	return maxf(0.0, definition.construction_time if definition != null else 0.0)


func begin_construction() -> bool:
	if _destroyed or construction_state != STATE_FOUNDATION:
		return false
	construction_elapsed = 0.0
	_set_construction_state(STATE_UNDER_CONSTRUCTION)
	_observe(&"infrastructure_construction_started", {
		"instance_id": String(infrastructure_instance_id),
		"structure_id": String(get_structure_id()),
		"duration": get_construction_duration(),
	})
	if get_construction_duration() <= 0.0:
		complete_construction()
	return true


func complete_construction() -> void:
	if _destroyed or construction_state not in [STATE_FOUNDATION, STATE_UNDER_CONSTRUCTION, STATE_COMMISSIONING]:
		return
	construction_elapsed = get_construction_duration()
	_set_construction_state(STATE_COMMISSIONING)
	_set_construction_state(STATE_OPERATIONAL)
	_set_components_active(true)
	commissioned.emit()
	_observe(&"infrastructure_commissioned", {
		"instance_id": String(infrastructure_instance_id),
		"structure_id": String(get_structure_id()),
	})
	_notify_registry_changed()


func get_construction_progress() -> float:
	var duration := get_construction_duration()
	if _is_commissioned_state():
		return 1.0
	if duration <= 0.0:
		return 0.0
	return clampf(construction_elapsed / duration, 0.0, 1.0)


func get_integrity_modifier() -> float:
	if _destroyed or definition == null or definition.max_integrity <= 0.0:
		return 0.0
	return clampf(current_integrity / definition.max_integrity, 0.0, 1.0)


func get_power_efficiency() -> float:
	for child in get_children():
		if child is PowerConsumerComponent:
			return (child as PowerConsumerComponent).get_effective_output()
	return 1.0 if _is_commissioned_state() else 0.0


func has_infrastructure_service(service_id: StringName) -> bool:
	for child in get_children():
		if child is InfrastructureServiceComponent \
		and (child as InfrastructureServiceComponent).service_id == service_id:
			return true
	return false


func get_infrastructure_service_output(service_id: StringName) -> float:
	var total := 0.0
	for child in get_children():
		if child is InfrastructureServiceComponent \
		and (child as InfrastructureServiceComponent).service_id == service_id:
			total += (child as InfrastructureServiceComponent).get_service_output()
	return total


func take_damage(
	amount: float,
	_direction: Vector2 = Vector2.ZERO,
	_knockback: float = 0.0,
	_attack_context: Dictionary = {}
) -> float:
	if _destroyed or amount <= 0.0:
		return 0.0
	var applied := minf(current_integrity, amount)
	current_integrity = maxf(0.0, current_integrity - amount)
	if current_integrity <= 0.0:
		_destroy()
	elif _is_commissioned_state():
		_set_construction_state(STATE_DAMAGED)
		_refresh_component_outputs()
	integrity_changed.emit(current_integrity, get_max_integrity())
	_observe(&"infrastructure_damaged", {
		"instance_id": String(infrastructure_instance_id),
		"amount": applied,
		"integrity": current_integrity,
	})
	_notify_registry_changed()
	return applied


func heal(amount: float) -> float:
	if _destroyed or amount <= 0.0:
		return 0.0
	var before := current_integrity
	current_integrity = minf(get_max_integrity(), current_integrity + amount)
	if current_integrity >= get_max_integrity() and construction_state == STATE_DAMAGED:
		_set_construction_state(STATE_OPERATIONAL)
	_refresh_component_outputs()
	integrity_changed.emit(current_integrity, get_max_integrity())
	_observe(&"infrastructure_repaired", {
		"instance_id": String(infrastructure_instance_id),
		"amount": current_integrity - before,
		"integrity": current_integrity,
	})
	_notify_registry_changed()
	return current_integrity - before


func get_max_integrity() -> float:
	return definition.max_integrity if definition != null else 1.0


func is_dead() -> bool:
	return _destroyed


func capture_infrastructure_state() -> Dictionary:
	return {
		"instance_id": String(infrastructure_instance_id),
		"structure_id": String(get_structure_id()),
		"definition_version": definition.definition_version if definition != null else 1,
		"scene_path": scene_file_path,
		"world_context_id": String(world_context_id),
		"position": {"x": global_position.x, "y": global_position.y},
		"rotation": rotation,
		"construction_state": String(construction_state),
		"construction_elapsed": construction_elapsed,
		"integrity": current_integrity,
		"destroyed": _destroyed,
		"registry_persistent": registry_persistent,
		"components": _capture_component_state(),
	}


func prepare_infrastructure_restore(payload: Dictionary) -> void:
	_restore_payload = payload.duplicate(true)
	infrastructure_instance_id = StringName(str(payload.get("instance_id", "")))


func complete_infrastructure_restore() -> void:
	if _restore_payload.is_empty():
		return
	_apply_restore_payload(_restore_payload)
	_restore_payload.clear()
	_set_components_active(_is_commissioned_state() and not _destroyed)
	_update_presentation()
	_notify_registry_changed()


func _apply_restore_payload(payload: Dictionary) -> void:
	var position_data: Dictionary = payload.get("position", {}) if payload.get("position", {}) is Dictionary else {}
	global_position = Vector2(float(position_data.get("x", 0.0)), float(position_data.get("y", 0.0)))
	rotation = float(payload.get("rotation", 0.0))
	world_context_id = StringName(str(payload.get("world_context_id", "compound")))
	construction_state = StringName(str(payload.get("construction_state", "foundation")))
	construction_elapsed = maxf(0.0, float(payload.get("construction_elapsed", 0.0)))
	current_integrity = clampf(float(payload.get("integrity", get_max_integrity())), 0.0, get_max_integrity())
	_destroyed = bool(payload.get("destroyed", current_integrity <= 0.0))
	var components: Dictionary = payload.get("components", {}) if payload.get("components", {}) is Dictionary else {}
	_restore_component_state(components)


func _capture_component_state() -> Dictionary:
	var result := {}
	for child in get_children():
		if child is PowerConsumerComponent:
			result["consumer"] = {
				"priority": (child as PowerConsumerComponent).priority,
				"overdrive_enabled": (child as PowerConsumerComponent).overdrive_enabled,
				"enabled": (child as PowerConsumerComponent).enabled,
			}
	return result


func _restore_component_state(components: Dictionary) -> void:
	var consumer_state: Dictionary = components.get("consumer", {}) if components.get("consumer", {}) is Dictionary else {}
	for child in get_children():
		if child is PowerConsumerComponent and not consumer_state.is_empty():
			(child as PowerConsumerComponent).priority = int(consumer_state.get("priority", (child as PowerConsumerComponent).priority))
			(child as PowerConsumerComponent).overdrive_enabled = bool(consumer_state.get("overdrive_enabled", false))
			(child as PowerConsumerComponent).enabled = bool(consumer_state.get("enabled", true))


func _set_construction_state(next_state: StringName) -> void:
	if construction_state == next_state:
		return
	var previous := construction_state
	construction_state = next_state
	construction_state_changed.emit(previous, construction_state)
	_update_presentation()


func _is_commissioned_state() -> bool:
	return construction_state in [STATE_OPERATIONAL, STATE_DAMAGED]


func _set_components_active(active: bool) -> void:
	for child in get_children():
		if child.has_method("set_infrastructure_active"):
			child.call("set_infrastructure_active", active)


func _refresh_component_outputs() -> void:
	for child in get_children():
		if child is PowerConsumerComponent:
			(child as PowerConsumerComponent).apply_power_allocation((child as PowerConsumerComponent).allocated_power)
	var grid := get_node_or_null("/root/GameRoot/Power")
	if grid != null and grid.has_method("request_grid_refresh"):
		grid.call("request_grid_refresh")


func _destroy() -> void:
	_destroyed = true
	current_integrity = 0.0
	_set_construction_state(STATE_DESTROYED)
	_set_components_active(false)
	structure_destroyed.emit()
	_observe(&"infrastructure_destroyed", {
		"instance_id": String(infrastructure_instance_id),
		"structure_id": String(get_structure_id()),
	})
	_update_presentation()


func _update_presentation() -> void:
	var body := get_node_or_null("Body") as CanvasItem
	if body == null:
		return
	match construction_state:
		STATE_FOUNDATION, STATE_UNDER_CONSTRUCTION:
			body.modulate = Color(0.58, 0.62, 0.58, 1.0)
		STATE_DAMAGED:
			body.modulate = Color(0.82, 0.55, 0.42, 1.0)
		STATE_DESTROYED:
			body.modulate = Color(0.22, 0.22, 0.24, 0.8)
		_:
			body.modulate = Color.WHITE


func _notify_registry_changed() -> void:
	var service_ids: Array[StringName] = []
	for child in get_children():
		if child is InfrastructureServiceComponent:
			service_ids.append((child as InfrastructureServiceComponent).service_id)
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	if registry != null and registry.has_method("notify_structure_changed"):
		registry.call("notify_structure_changed", service_ids)


func _observe(event_name: StringName, payload: Dictionary) -> void:
	if not is_inside_tree():
		return
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
