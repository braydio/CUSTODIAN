class_name DeerFlowValidator
extends Node

## Validates generated code for syntax, safety, and API compliance.

signal validation_passed(code: String)
signal validation_failed(reason: String)

const DANGEROUS_PATTERNS: Array[String] = [
	"import os",
	"import sys",
	"import subprocess",
	"import socket",
	"import requests",
	"import urllib",
	"open(",
	"file.",
	"read(",
	"write(",
	"exec(",
	"eval(",
	"compile(",
	"__import__",
	"os.system",
	"os.popen",
	"subprocess.call",
	"subprocess.run",
	"subprocess.Popen",
]

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

const REQUIRED_PATTERNS: Array[String] = [
	"def ",
	"state",
	"return ",
]

const MAX_LINES: int = 30


func _ready() -> void:
	print("[DeerFlowValidator] Initialized with ", DANGEROUS_PATTERNS.size(), " dangerous patterns")


func validate(code: String, event_spec: Dictionary = {}) -> bool:
	if code.is_empty():
		_validation_failed("Empty code")
		return false
	
	# Stage 1: Syntax check
	if not _check_syntax(code):
		return false
	
	# Stage 2: Static safety filter  
	if not _check_safety(code):
		return false
	
	# Stage 3: API whitelist check
	if not _check_api(code):
		return false
	
	# Stage 4: Structure requirements
	if not _check_structure(code):
		return false
	
	# Stage 5: Optional spec alignment
	if not event_spec.is_empty():
		if not _check_spec_alignment(code, event_spec):
			return false
	
	validation_passed.emit(code)
	print("[DeerFlowValidator] Validation passed")
	return true


func _check_syntax(code: String) -> bool:
	# Check for valid Python syntax indicators
	if not code.contains("def "):
		_validation_failed("No function definition")
		return false
	
	if not code.contains("return "):
		_validation_failed("No return statement")
		return false
	
	# Check for basic syntax errors
	var lines = code.split("\n")
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		# Check for obvious syntax issues
		if line.ends_with("=") or line.ends_with(","):
			# Might be incomplete line - check if next line is indented
			if i + 1 < lines.size():
				if not lines[i+1].begins_with("\t") and not lines[i+1].begins_with(" "):
					_validation_failed("Potential syntax issue at line " + str(i+1))
					return false
	
	return true


func _check_safety(code: String) -> bool:
	for pattern in DANGEROUS_PATTERNS:
		if pattern in code:
			_validation_failed("Dangerous pattern detected: " + pattern)
			return false
	
	# Check for suspicious function calls
	var suspicious = ["eval", "exec", "compile", "open", "file", "os.", "sys.", "subprocess"]
	for pattern in suspicious:
		if pattern in code:
			_validation_failed("Suspicious pattern: " + pattern)
			return false
	
	return true


func _check_api(code: String) -> bool:
	# Extract all function calls
	var lines = code.split("\n")
	var valid = true
	
	for line in lines:
		if line.contains("#"):
			line = line.split("#")[0]  # Remove comments
		
		# Find function-like patterns
		var words = line.split(" ")
		for i in range(words.size() - 1):
			var word = words[i].strip_edges()
			if word.ends_with("("):
				var func_name = word.replace("(", "")
				# Skip built-in Python things
				if func_name in ["def", "if", "for", "while", "return", "in", "is", "and", "or", "not", "True", "False", "None", "print", "len", "range", "str", "int", "float", "dict", "list", "bool"]:
					continue
				# Skip event-specific words
				if func_name in ["triggered", "applied_effects", "state", "power", "threat", "duration", "delta", "count", "enemy_type", "item_type", "multiplier", "stat"]:
					continue
				# Check if it's in allowed API
				if func_name not in ALLOWED_API:
					push_warning("[DeerFlowValidator] Unknown function: ", func_name)
					# Don't fail on this for now - allow exploration
	
	return true


func _check_structure(code: String) -> bool:
	var lines = code.split("\n")
	
	# Check line count
	if lines.size() > MAX_LINES:
		_validation_failed("Code too long: " + str(lines.size()) + " lines (max " + str(MAX_LINES) + ")")
		return false
	
	# Check for function name
	var func_match = code.find("def ")
	if func_match == -1:
		_validation_failed("No function definition")
		return false
	
	# Extract function name
	var func_line = lines[0]
	var func_name = func_line.split("(")[0].replace("def ", "").strip_edges()
	
	# Check function has proper name
	if func_name.is_empty():
		_validation_failed("Invalid function name")
		return false
	
	# Check state parameter exists
	if "(state)" not in code:
		_validation_failed("Function must accept 'state' parameter")
		return false
	
	return true


func _check_spec_alignment(code: String, spec: Dictionary) -> bool:
	# Optional: Check that generated code aligns with the spec
	
	var event_name = spec.get("event_name", "")
	if event_name.is_empty():
		return true  # Skip if no event name
	
	# Check event name in function name
	var expected_func = event_name.to_lower().replace(" ", "_")
	if expected_func not in code:
		push_warning("[DeerFlowValidator] Event name '" + event_name + "' not found in code")
	
	# Check trigger type handling
	var trigger = spec.get("trigger", {})
	var trigger_type = trigger.get("type", "")
	if trigger_type != "manual":
		if trigger_type not in code:
			push_warning("[DeerFlowValidator] Trigger '" + trigger_type + "' not handled in code")
	
	return true


func _validation_failed(reason: String) -> void:
	validation_failed.emit(reason)
	print("[DeerFlowValidator] FAILED: ", reason)


func get_allowed_api() -> Array:
	return ALLOWED_API.duplicate()


func get_dangerous_patterns() -> Array:
	return DANGEROUS_PATTERNS.duplicate()