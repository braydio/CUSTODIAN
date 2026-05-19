class_name DeerFlowCodeGenerator
extends Node

## Converts event specifications (JSON) into executable Python/GDScript code.

signal code_generated(code: String)
signal generation_failed(reason: String)

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


func _ready() -> void:
	print("[DeerFlowCodeGenerator] Initialized")


func generate_code(event_spec: Dictionary) -> String:
	var event_name = event_spec.get("event_name", "UNKNOWN_EVENT")
	var trigger = event_spec.get("trigger", {})
	var effects = event_spec.get("effects", [])
	var risk = event_spec.get("risk_level", "MEDIUM")
	
	var code = _generate_function(event_name, trigger, effects, risk)
	
	if _validate_code(code):
		code_generated.emit(code)
		return code
	else:
		generation_failed.emit("Code validation failed")
		return ""


func _generate_function(event_name: String, trigger: Dictionary, effects: Array, risk: String) -> String:
	var func_name = event_name.to_lower().replace(" ", "_")
	
	var code = """def %s(state):
	\"\"\"Trigger %s event.
	
	Args:
		state: Current game state dict
	
	Returns:
		dict with triggered_effects and state_changes
	\"\"\"
	# Event: %s
	# Risk Level: %s
	# Trigger: %s
	
	triggered = False
	applied_effects = []
	
	# Check trigger conditions
	trigger_type = "%s"
""" % [func_name, event_name, event_name, risk, trigger.get("type", "manual"), trigger.get("type", "manual")]
	
	# Add trigger condition based on type
	match trigger.get("type"):
		"low_power":
			code += _generate_low_power_check(trigger.get("params", {}))
		"high_threat":
			code += _generate_high_threat_check(trigger.get("params", {}))
		"manual":
			code += "\ttriggered = True\n"
		_:
			code += "\ttriggered = True\n"
	
	# Add effect implementations
	code += "\tif triggered:\n"
	
	for effect in effects:
		code += _generate_effect_implementation(effect)
	
	code += "\n\treturn {\"triggered\": triggered, \"effects\": applied_effects}\n"
	
	return code


func _generate_low_power_check(params: Dictionary) -> String:
	var threshold = params.get("threshold", 50)
	return """\tpower = state.get("resources", {}).get("power", 100)
	if power < %d:
		triggered = True
""" % threshold


func _generate_high_threat_check(params: Dictionary) -> String:
	var threshold = params.get("threshold", 5)
	return """\tthreat = state.get("threat_level", 1)
	if threat >= %d:
		triggered = True
""" % threshold


func _generate_effect_implementation(effect: Dictionary) -> String:
	var effect_type = effect.get("type", "")
	var target = effect.get("target", "")
	var result = ""
	
	match effect_type:
		"disable_entity":
			var duration = effect.get("duration", 5)
			result = "\t\t# Disable %s for %d ticks\n" % [target, duration]
			result += "\t\tapplied_effects.append({\"type\": \"disable_entity\", \"target\": \"%s\", \"duration\": %d})\n" % [target, duration]
		
		"modify_stat":
			var stat = effect.get("stat", "speed")
			var multiplier = effect.get("multiplier", 1.0)
			var duration = effect.get("duration", 0)
			result = "\t\t# Modify %s %s by %fx" % [target, stat, multiplier]
			if duration > 0:
				result += " for %d ticks" % duration
			result += "\n"
			result += "\t\tapplied_effects.append({\"type\": \"modify_stat\", \"target\": \"%s\", \"stat\": \"%s\", \"multiplier\": %s})\n" % [target, stat, str(multiplier)]
		
		"modify_difficulty":
			var delta = effect.get("delta", 0)
			result = "\t\t# Adjust difficulty by %+.1f\n" % delta
			result += "\t\tapplied_effects.append({\"type\": \"modify_difficulty\", \"delta\": %s})\n" % str(delta)
		
		"spawn_enemy":
			var count = effect.get("count", 1)
			var enemy_type = effect.get("type", "drone")
			result = "\t\t# Spawn %d %s enemies\n" % [count, enemy_type]
			result += "\t\tapplied_effects.append({\"type\": \"spawn_enemy\", \"count\": %d, \"enemy_type\": \"%s\"})\n" % [count, enemy_type]
		
		"trigger_timer":
			var delay = effect.get("delay", 10)
			var timer_effect = effect.get("effect", "increase_difficulty")
			result = "\t\t# Trigger %s after %d ticks\n" % [timer_effect, delay]
			result += "\t\tapplied_effects.append({\"type\": \"trigger_timer\", \"delay\": %d, \"effect\": \"%s\"})\n" % [delay, timer_effect]
		
		"spawn_item":
			var item_type = effect.get("type", "ruin_scrap")
			result = "\t\t# Spawn %s item\n" % item_type
			result += "\t\tapplied_effects.append({\"type\": \"spawn_item\", \"item_type\": \"%s\"})\n" % item_type
		
		_:
			result = "\t\t# Unknown effect type: %s\n" % effect_type
	
	return result


func _validate_code(code: String) -> bool:
	if code.is_empty():
		push_error("[DeerFlowCodeGenerator] Empty code generated")
		return false
	
	# Check for dangerous patterns
	var dangerous = [
		"import os",
		"import sys",
		"import subprocess",
		"import socket",
		"open(",
		"file.",
		"exec(",
		"eval(",
	]
	
	for pattern in dangerous:
		if pattern in code:
			push_error("[DeerFlowCodeGenerator] Dangerous pattern detected: ", pattern)
			return false
	
	# Check function definition exists
	if not code.contains("def "):
		push_error("[DeerFlowCodeGenerator] No function definition found")
		return false
	
	# Check return statement exists
	if not code.contains("return "):
		push_error("[DeerFlowCodeGenerator] No return statement found")
		return false
	
	# Check for valid function calls (only allowed API)
	var all_words = code.split(" ")
	for word in all_words:
		word = word.strip_edges()
		if word.ends_with("(") and not word.begins_with("#"):
			var func_name = word.replace("(", "").replace("(", "")
			if func_name not in ALLOWED_API and func_name not in ["def", "if", "for", "while", "return", "in", "is", "and", "or", "not", "True", "False", "None"]:
				# Allow some built-ins
				if func_name not in ["state", "triggered", "applied_effects", "trigger", "type", "target", "power", "threat", "duration", "delta", "count", "item_type", "enemy_type", "multiplier", "stat"]:
					push_warning("[DeerFlowCodeGenerator] Potentially unknown function: ", func_name)
	
	return true


func get_allowed_api() -> Array:
	return ALLOWED_API.duplicate()
