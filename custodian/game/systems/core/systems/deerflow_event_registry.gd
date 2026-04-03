class_name DeerFlowEventRegistry
extends Node

## Central registry for dynamically generated game events.

## Registry Structure
## Events are stored as callable functions that take game state and return effect dict

signal event_registered(event_name: String)
signal event_triggered(event_name: String, result: Dictionary)
signal event_rejected(event_name: String, reason: String)

# The main event registry - maps event_name -> callable function
var _events: Dictionary = {}

# Event metadata for display/debugging
var _event_metadata: Dictionary = {}

# Allowed API surface - whitelist of safe functions
const ALLOWED_API: Array[String] = [
	"disable_entity",
	"modify_stat",
	"spawn_enemy",
	"spawn_item",
	"trigger_timer",
	"modify_difficulty",
	"log_event",
	"get_entity_count",
	"get_resource_amount",
	"apply_damage",
	"heal_entity",
	"toggle_state",
]

# Registered event types for the minimal version
const MINIMAL_EVENT_TYPES: Array[String] = [
	"POWER_SURGE",
	"EMERGENCY_ALERT",
	"STRUCTURE_BREACH",
]


func _ready() -> void:
	add_to_group("deerflow_registry")
	print("[DeerFlowEventRegistry] Initialized with allowed API: ", ALLOWED_API)


func register_event(event_name: String, event_function: Callable, metadata: Dictionary = {}) -> bool:
	if _events.has(event_name):
		push_warning("[DeerFlow] Event already exists: " + event_name)
		return false
	
	_events[event_name] = event_function
	_event_metadata[event_name] = {
		"registered_at": Time.get_ticks_msec(),
		"metadata": metadata,
	}
	
	event_registered.emit(event_name)
	print("[DeerFlow] Registered event: ", event_name)
	return true


func register_event_from_spec(event_name: String, event_spec: Dictionary, metadata: Dictionary = {}) -> bool:
	if _event_metadata.has(event_name):
		push_warning("[DeerFlow] Event already exists: " + event_name)
		return false
	
	_event_metadata[event_name] = {
		"registered_at": Time.get_ticks_msec(),
		"metadata": metadata,
		"spec": event_spec,
		"source": "deerflow_pipeline",
	}
	
	event_registered.emit(event_name)
	print("[DeerFlow] Registered event from spec: ", event_name)
	return true


func unregister_event(event_name: String) -> bool:
	if not _events.has(event_name):
		push_warning("[DeerFlow] Event not found: " + event_name)
		return false
	
	_events.erase(event_name)
	_event_metadata.erase(event_name)
	print("[DeerFlow] Unregistered event: ", event_name)
	return true


func trigger_event(event_name: String, game_state: Dictionary) -> Dictionary:
	# Check for stored spec first (from DeerFlow pipeline)
	if _event_metadata.has(event_name) and _event_metadata[event_name].has("spec"):
		var spec = _event_metadata[event_name]["spec"]
		var result = execute_event_from_spec(spec, game_state)
		event_triggered.emit(event_name, result)
		return result
	
	# Fall back to callable (if any legacy events registered)
	if not _events.has(event_name):
		push_error("[DeerFlow] Event not found: " + event_name)
		return {"success": false, "error": "event_not_found"}
	
	var event_func: Callable = _events[event_name]
	if not event_func.is_valid():
		push_error("[DeerFlow] Event callable invalid: " + event_name)
		return {"success": false, "error": "invalid_callable"}
	
	var result: Variant = event_func.call(game_state)
	var result_dict: Dictionary = result if result is Dictionary else {"value": result}
	event_triggered.emit(event_name, result_dict)
	return {"success": true, "result": result_dict}


func has_event(event_name: String) -> bool:
	return _events.has(event_name)


func get_event_count() -> int:
	return _events.size()


func get_event_names() -> Array:
	return _events.keys()


func get_event_metadata(event_name: String) -> Dictionary:
	return _event_metadata.get(event_name, {})


func clear_registry() -> void:
	_events.clear()
	_event_metadata.clear()
	print("[DeerFlow] Registry cleared")


func get_allowed_api() -> Array:
	return ALLOWED_API.duplicate()


func is_api_allowed(function_name: String) -> bool:
	return function_name in ALLOWED_API


## DISPATCHER - executes event effects via GDScript instead of Python

func execute_event_from_spec(event_spec: Dictionary, game_state: Dictionary) -> Dictionary:
	var event_name = event_spec.get("event_name", "UNKNOWN")
	var effects = event_spec.get("effects", [])
	var trigger = event_spec.get("trigger", {})
	
	print("[DeerFlowDispatcher] Executing event: ", event_name)
	
	var results: Array = []
	var success = true
	
	# Check trigger conditions first
	if not _check_trigger(trigger, game_state):
		print("[DeerFlowDispatcher] Trigger condition not met for: ", event_name)
		return {"success": false, "triggered": false, "effects": []}
	
	# Execute each effect
	for effect in effects:
		var result = _dispatch_effect(effect, game_state)
		results.append(result)
		if result.get("success", false) == false:
			success = false
	
	return {
		"success": success,
		"triggered": true,
		"effects": results,
		"event_name": event_name
	}


func _check_trigger(trigger: Dictionary, game_state: Dictionary) -> bool:
	var trigger_type = trigger.get("type", "manual")
	var params = trigger.get("params", {})
	
	match trigger_type:
		"manual":
			return true
		"low_power":
			var threshold = params.get("threshold", 50)
			var power = game_state.get("resources", {}).get("power", 100)
			return power < threshold
		"high_threat":
			var threshold = params.get("threshold", 5)
			var threat = game_state.get("threat_level", 0)
			return threat >= threshold
		"timer":
			return true  # Timer handled externally
		_:
			return true


func _dispatch_effect(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var effect_type = effect.get("type", "")
	var target = effect.get("target", "")
	
	if not effect_type in ALLOWED_API:
		push_warning("[DeerFlowDispatcher] Effect type not in API whitelist: ", effect_type)
		return {"success": false, "error": "effect_type_not_allowed"}
	
	match effect_type:
		"disable_entity":
			return _effect_disable_entity(effect, game_state)
		"modify_stat":
			return _effect_modify_stat(effect, game_state)
		"spawn_enemy":
			return _effect_spawn_enemy(effect, game_state)
		"spawn_item":
			return _effect_spawn_item(effect, game_state)
		"trigger_timer":
			return _effect_trigger_timer(effect, game_state)
		"modify_difficulty":
			return _effect_modify_difficulty(effect, game_state)
		"log_event":
			return _effect_log_event(effect, game_state)
		"get_entity_count":
			return _effect_get_entity_count(effect, game_state)
		"get_resource_amount":
			return _effect_get_resource_amount(effect, game_state)
		"apply_damage":
			return _effect_apply_damage(effect, game_state)
		"heal_entity":
			return _effect_heal_entity(effect, game_state)
		"toggle_state":
			return _effect_toggle_state(effect, game_state)
		_:
			push_warning("[DeerFlowDispatcher] Unhandled effect type: ", effect_type)
			return {"success": false, "error": "unknown_effect_type"}


func _effect_disable_entity(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var target = effect.get("target", "")
	var duration = effect.get("duration", 5)
	print("[DeerFlowDispatcher] disable_entity: ", target, " for ", duration, " ticks")
	return {
		"success": true,
		"effect_type": "disable_entity",
		"target": target,
		"duration": duration
	}


func _effect_modify_stat(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var target = effect.get("target", "")
	var stat = effect.get("stat", "speed")
	var multiplier = effect.get("multiplier", 1.0)
	var duration = effect.get("duration", 0)
	print("[DeerFlowDispatcher] modify_stat: ", target, " ", stat, " *= ", multiplier, " for ", duration, " ticks")
	return {
		"success": true,
		"effect_type": "modify_stat",
		"target": target,
		"stat": stat,
		"multiplier": multiplier,
		"duration": duration
	}


func _effect_spawn_enemy(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var count = effect.get("count", 1)
	var enemy_type = effect.get("enemy_type", "drone")
	print("[DeerFlowDispatcher] spawn_enemy: ", count, " x ", enemy_type)
	return {
		"success": true,
		"effect_type": "spawn_enemy",
		"count": count,
		"enemy_type": enemy_type
	}


func _effect_spawn_item(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var item_type = effect.get("item_type", "scrap")
	print("[DeerFlowDispatcher] spawn_item: ", item_type)
	return {
		"success": true,
		"effect_type": "spawn_item",
		"item_type": item_type
	}


func _effect_trigger_timer(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var delay = effect.get("delay", 10)
	var timer_effect = effect.get("effect", "increase_difficulty")
	print("[DeerFlowDispatcher] trigger_timer: ", timer_effect, " after ", delay, " ticks")
	return {
		"success": true,
		"effect_type": "trigger_timer",
		"delay": delay,
		"effect": timer_effect
	}


func _effect_modify_difficulty(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var delta = effect.get("delta", 0)
	print("[DeerFlowDispatcher] modify_difficulty: +", delta)
	return {
		"success": true,
		"effect_type": "modify_difficulty",
		"delta": delta
	}


func _effect_log_event(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var message = effect.get("message", "")
	var level = effect.get("level", "info")
	print("[DeerFlowDispatcher] log_event [", level, "]: ", message)
	return {
		"success": true,
		"effect_type": "log_event",
		"message": message,
		"level": level
	}


func _effect_get_entity_count(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var entity_type = effect.get("entity_type", "enemy")
	var count = game_state.get("entities", {}).get(entity_type, 0)
	print("[DeerFlowDispatcher] get_entity_count: ", entity_type, " = ", count)
	return {
		"success": true,
		"effect_type": "get_entity_count",
		"entity_type": entity_type,
		"count": count
	}


func _effect_get_resource_amount(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var resource = effect.get("resource", "power")
	var amount = game_state.get("resources", {}).get(resource, 0)
	print("[DeerFlowDispatcher] get_resource_amount: ", resource, " = ", amount)
	return {
		"success": true,
		"effect_type": "get_resource_amount",
		"resource": resource,
		"amount": amount
	}


func _effect_apply_damage(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var target = effect.get("target", "")
	var damage = effect.get("damage", 10)
	print("[DeerFlowDispatcher] apply_damage: ", target, " -", damage)
	return {
		"success": true,
		"effect_type": "apply_damage",
		"target": target,
		"damage": damage
	}


func _effect_heal_entity(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var target = effect.get("target", "")
	var heal_amount = effect.get("amount", 10)
	print("[DeerFlowDispatcher] heal_entity: ", target, " +", heal_amount)
	return {
		"success": true,
		"effect_type": "heal_entity",
		"target": target,
		"amount": heal_amount
	}


func _effect_toggle_state(effect: Dictionary, game_state: Dictionary) -> Dictionary:
	var target = effect.get("target", "")
	var state = effect.get("state", "")
	print("[DeerFlowDispatcher] toggle_state: ", target, " = ", state)
	return {
		"success": true,
		"effect_type": "toggle_state",
		"target": target,
		"state": state
	}
