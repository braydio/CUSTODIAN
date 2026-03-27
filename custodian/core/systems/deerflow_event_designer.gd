class_name DeerFlowEventDesigner
extends Node

## Generates event specifications (JSON) from game state analysis.
## This is the "thinking" phase - analyzes state and proposes events without generating code.

signal event_designed(spec: Dictionary)
signal design_rejected(reason: String)

const ALLOWED_EFFECT_TYPES: Array[String] = [
	"spawn_enemy",
	"modify_stat", 
	"disable_entity",
	"trigger_timer",
	"spawn_item",
	"modify_difficulty",
]

const MINIMAL_EVENT_TYPES: Array[String] = [
	"POWER_SURGE",
	"EMERGENCY_ALERT",
	"STRUCTURE_BREACH",
]

const TRIGGER_TYPES: Array[String] = [
	"low_power",
	"high_threat",
	"time_elapsed",
	"random",
	"manual",
	"low_resources",
]

const RISK_LEVELS: Array[String] = [
	"LOW",
	"MEDIUM",
	"HIGH",
	"CRITICAL",
]


func _ready() -> void:
	print("[DeerFlowEventDesigner] Initialized")


func analyze_and_design(game_state: Dictionary) -> Dictionary:
	"""Main entry point - analyze state and design appropriate event."""
	
	var analysis = _analyze_game_state(game_state)
	var event_spec = _generate_event_spec(analysis)
	
	if _validate_spec(event_spec):
		event_designed.emit(event_spec)
		return event_spec
	else:
		var reason = "Event spec validation failed"
		design_rejected.emit(reason)
		return {}


func _analyze_game_state(state: Dictionary) -> Dictionary:
	var analysis = {
		"tick": state.get("tick", 0),
		"phase": state.get("phase", "UNKNOWN"),
		"threat_level": state.get("threat_level", 1.0),
		"difficulty": state.get("difficulty_score", 1.0),
		"power": 0,
		"materials": 0,
		"turret_count": 0,
		"enemy_count": 0,
		"operator_hp": 100,
	}
	
	# Extract resources
	var resources = state.get("resources", {})
	analysis["power"] = resources.get("power", 0)
	analysis["materials"] = resources.get("materials", 0)
	
	# Extract entity info
	var entities = state.get("entities", [])
	for entity in entities:
		match entity.get("type"):
			"turret":
				analysis["turret_count"] = entity.get("total", 0)
			"enemy":
				analysis["enemy_count"] = entity.get("count", 0)
			"operator":
				analysis["operator_hp"] = entity.get("hp", 100)
	
	print("[DeerFlowEventDesigner] Analysis: ", analysis)
	return analysis


func _generate_event_spec(analysis: Dictionary) -> Dictionary:
	"""Generate event spec based on analysis."""
	
	var event_name = _pick_event_type(analysis)
	var trigger = _determine_trigger(analysis)
	var effects = _design_effects(analysis, event_name)
	var risk = _assess_risk(analysis, event_name)
	
	var spec = {
		"event_name": event_name,
		"trigger": {
			"type": trigger.type,
			"params": trigger.params,
		},
		"effects": effects,
		"risk_level": risk,
		"timestamp": Time.get_ticks_msec(),
	}
	
	print("[DeerFlowEventDesigner] Generated spec: ", spec)
	return spec


func _pick_event_type(analysis: Dictionary) -> String:
	var threat = analysis.get("threat_level", 1.0)
	var power = analysis.get("power", 0)
	var materials = analysis.get("materials", 0)
	
	# Decision logic for minimal version
	if power < 40:
		return "POWER_SURGE"
	elif threat > 7:
		return "EMERGENCY_ALERT"
	elif analysis.get("turret_count", 0) < 2:
		return "STRUCTURE_BREACH"
	else:
		return "EMERGENCY_ALERT"  # Default fallback


func _determine_trigger(analysis: Dictionary) -> Dictionary:
	var power = analysis.get("power", 0)
	var threat = analysis.get("threat_level", 1.0)
	var enemy_count = analysis.get("enemy_count", 0)
	
	if power < 40:
		return {"type": "low_power", "params": {"threshold": 40}}
	elif threat > 6:
		return {"type": "high_threat", "params": {"threshold": 6}}
	elif enemy_count > 10:
		return {"type": "high_threat", "params": {"enemy_count": enemy_count}}
	else:
		return {"type": "manual", "params": {}}


func _design_effects(analysis: Dictionary, event_name: String) -> Array:
	var effects: Array = []
	var power = analysis.get("power", 0)
	var threat = analysis.get("threat_level", 1.0)
	var turrets = analysis.get("turret_count", 0)
	var enemies = analysis.get("enemy_count", 0)
	
	match event_name:
		"POWER_SURGE":
			if turrets > 0:
				effects.append({
					"type": "disable_entity",
					"target": "random_turret",
					"duration": 10,
				})
			effects.append({
				"type": "modify_stat",
				"target": "enemy",
				"stat": "speed",
				"multiplier": 1.3,
				"duration": 15,
			})
			effects.append({
				"type": "modify_difficulty",
				"delta": 0.5,
			})
		
		"EMERGENCY_ALERT":
			effects.append({
				"type": "modify_difficulty",
				"delta": 0.3,
			})
			if enemies < 5:
				effects.append({
					"type": "spawn_enemy",
					"count": 2,
					"enemy_type": "fast",
				})
			effects.append({
				"type": "trigger_timer",
				"delay": 20,
				"effect": "increase_difficulty",
			})
		
		"STRUCTURE_BREACH":
			effects.append({
				"type": "spawn_enemy",
				"count": 3,
				"enemy_type": "drone",
			})
			effects.append({
				"type": "modify_stat",
				"target": "operator",
				"stat": "defense",
				"multiplier": 0.8,
				"duration": 10,
			})
	
	return effects


func _assess_risk(analysis: Dictionary, event_name: String) -> String:
	var threat = analysis.get("threat_level", 1.0)
	var difficulty = analysis.get("difficulty", 1.0)
	var operator_hp = analysis.get("operator_hp", 100)
	
	match event_name:
		"POWER_SURGE":
			if threat > 5:
				return "HIGH"
			return "MEDIUM"
		"EMERGENCY_ALERT":
			return "MEDIUM"
		"STRUCTURE_BREACH":
			if operator_hp < 50:
				return "HIGH"
			return "MEDIUM"
	
	return "LOW"


func _validate_spec(spec: Dictionary) -> bool:
	# Validate event name
	if not spec.has("event_name"):
		push_error("[DeerFlowEventDesigner] Missing event_name")
		return false
	
	if not spec["event_name"] in MINIMAL_EVENT_TYPES:
		push_warning("[DeerFlowEventDesigner] Event not in allowed list: ", spec["event_name"])
		# Allow for now in minimal version
	
	# Validate trigger
	if not spec.has("trigger"):
		push_error("[DeerFlowEventDesigner] Missing trigger")
		return false
	
	var trigger = spec["trigger"]
	if not trigger.has("type"):
		push_error("[DeerFlowEventDesigner] Missing trigger type")
		return false
	
	# Validate effects
	if not spec.has("effects") or not spec["effects"] is Array:
		push_error("[DeerFlowEventDesigner] Invalid effects")
		return false
	
	for effect in spec["effects"]:
		if not effect.has("type"):
			push_error("[DeerFlowEventDesigner] Effect missing type")
			return false
		if not effect["type"] in ALLOWED_EFFECT_TYPES:
			push_warning("[DeerFlowEventDesigner] Effect type not allowed: ", effect["type"])
	
	# Validate risk level
	if not spec.get("risk_level") in RISK_LEVELS:
		push_error("[DeerFlowEventDesigner] Invalid risk level")
		return false
	
	return true


func get_allowed_effect_types() -> Array:
	return ALLOWED_EFFECT_TYPES.duplicate()


func get_allowed_event_types() -> Array:
	return MINIMAL_EVENT_TYPES.duplicate()
