class_name DeerFlowOrchestrator
extends Node

## Main orchestrator for the DeerFlow autonomous content pipeline.

## Pipeline:
## 1. Generate State Snapshot
## 2. Design Event (JSON spec)
## 3. Generate Code
## 4. Validate Code
## 5. Register Event

signal pipeline_started()
signal pipeline_step_completed(step: String, data: Variant)
signal pipeline_completed(event_name: String, success: bool)
signal pipeline_failed(step: String, reason: String)

@onready var snapshot_generator: DeerFlowStateSnapshot = DeerFlowStateSnapshot.new()
@onready var event_designer: DeerFlowEventDesigner = DeerFlowEventDesigner.new()
@onready var code_generator: DeerFlowCodeGenerator = DeerFlowCodeGenerator.new()
@onready var validator: DeerFlowValidator = DeerFlowValidator.new()

var _event_registry: Node = null
var _enabled: bool = false


func _ready() -> void:
	add_to_group("deerflow_orchestrator")
	# Note: Don't add children in _ready, add them in setup
	print("[DeerFlowOrchestrator] Initialized")


func setup(registry: Node) -> void:
	_event_registry = registry
	_add_system_nodes()
	_enabled = true
	print("[DeerFlowOrchestrator] Setup complete")


func _add_system_nodes() -> void:
	add_child(snapshot_generator)
	add_child(event_designer)
	add_child(code_generator)
	add_child(validator)


func run_pipeline() -> bool:
	if not _enabled:
		push_error("[DeerFlow] Pipeline not enabled - call setup() first")
		return false
	
	if _event_registry == null:
		push_error("[DeerFlow] No event registry connected")
		return false
	
	pipeline_started.emit()
	print("[DeerFlow] Pipeline started")
	
	# Step 1: Generate state snapshot
	pipeline_step_completed.emit("snapshot", {})
	var snapshot = snapshot_generator.generate_snapshot()
	print("[DeerFlow] Step 1: Snapshot generated - tick: ", snapshot.get("tick", 0))
	
	# Step 2: Design event
	pipeline_step_completed.emit("design", snapshot)
	var event_spec = event_designer.analyze_and_design(snapshot)
	if event_spec.is_empty():
		pipeline_failed.emit("design", "Event design failed")
		return false
	print("[DeerFlow] Step 2: Event designed - ", event_spec.get("event_name", "UNKNOWN"))
	
	# Step 3: Generate code
	pipeline_step_completed.emit("generate", event_spec)
	var code = code_generator.generate_code(event_spec)
	if code.is_empty():
		pipeline_failed.emit("generate", "Code generation failed")
		return false
	print("[DeerFlow] Step 3: Code generated - ", code.length(), " chars")
	
	# Step 4: Validate code
	pipeline_step_completed.emit("validate", code)
	if not validator.validate(code, event_spec):
		pipeline_failed.emit("validate", "Validation failed")
		return false
	print("[DeerFlow] Step 4: Validation passed")
	
	# Step 5: Register event (manual approval step for now)
	pipeline_step_completed.emit("register", code)
	# For now, we log instead of auto-registering
	# The human should review and manually register after testing
	print("[DeerFlow] Step 5: Code ready for review (manual registration)")
	
	# Store code in registry for manual review
	_event_registry.set("pending_code", code)
	_event_registry.set("pending_spec", event_spec)
	
	pipeline_completed.emit(event_spec.get("event_name", "UNKNOWN"), true)
	print("[DeerFlow] Pipeline completed successfully!")
	
	return true


func run_simple_event(event_name: String) -> bool:
	"""Run pipeline for a specific event type."""
	if not _enabled or _event_registry == null:
		return false
	
	# Create a simple manual trigger event spec
	var event_spec = {
		"event_name": event_name,
		"trigger": {"type": "manual", "params": {}},
		"effects": _get_default_effects(event_name),
		"risk_level": "MEDIUM",
	}
	
	# Generate code
	var code = code_generator.generate_code(event_spec)
	if code.is_empty():
		return false
	
	# Validate
	if not validator.validate(code, event_spec):
		return false
	
	# Register
	_event_registry.set("pending_code", code)
	_event_registry.set("pending_spec", event_spec)
	
	return true


func _get_default_effects(event_name: String) -> Array:
	match event_name:
		"POWER_SURGE":
			return [
				{"type": "disable_entity", "target": "random_turret", "duration": 10},
				{"type": "modify_stat", "target": "enemy", "stat": "speed", "multiplier": 1.3, "duration": 15},
			]
		"EMERGENCY_ALERT":
			return [
				{"type": "modify_difficulty", "delta": 0.3},
				{"type": "spawn_enemy", "count": 2, "enemy_type": "fast"},
			]
		"STRUCTURE_BREACH":
			return [
				{"type": "spawn_enemy", "count": 3, "enemy_type": "drone"},
				{"type": "modify_stat", "target": "operator", "stat": "defense", "multiplier": 0.8},
			]
	
	return []


func manual_register() -> bool:
	"""Manually register the pending code after review."""
	if _event_registry == null:
		return false
	
	var code: String = _event_registry.get("pending_code") if _event_registry.has_method("get") and _event_registry.get("pending_code") != null else ""
	var spec: Dictionary = _event_registry.get("pending_spec") if _event_registry.has_method("get") and _event_registry.get("pending_spec") is Dictionary else {}
	
	if code.is_empty():
		push_warning("[DeerFlow] No pending code to register")
		return false
	
	var event_name = spec.get("event_name", "UNKNOWN")
	
	# Register using spec (dispatcher will execute effects via GDScript)
	if _event_registry.has_method("register_event_from_spec"):
		_event_registry.register_event_from_spec(event_name, spec, {"code": code})
	else:
		push_error("[DeerFlow] Registry missing register_event_from_spec method")
		return false
	
	# Store code for reference/debugging
	_event_registry.set("last_registered_event", event_name)
	_event_registry.set("last_registered_code", code)
	
	# Clear pending
	_event_registry.set("pending_code", "")
	_event_registry.set("pending_spec", {})
	
	print("[DeerFlow] Manual registration complete for: ", event_name)
	return true


func get_pending_code() -> String:
	if _event_registry:
		var value: Variant = _event_registry.get("pending_code")
		return str(value) if value != null else ""
	return ""


func get_pending_spec() -> Dictionary:
	if _event_registry:
		var value: Variant = _event_registry.get("pending_spec")
		return value if value is Dictionary else {}
	return {}


func is_enabled() -> bool:
	return _enabled


func auto_register() -> bool:
	"""Auto-register the pending event without manual review (for testing)."""
	if _event_registry == null:
		return false
	
	var spec: Dictionary = get_pending_spec()
	if spec.is_empty():
		push_warning("[DeerFlow] No pending spec to auto-register")
		return false
	
	var event_name = spec.get("event_name", "UNKNOWN")
	
	# Register using spec directly
	if _event_registry.has_method("register_event_from_spec"):
		_event_registry.register_event_from_spec(event_name, spec, {"auto_registered": true})
	else:
		push_error("[DeerFlow] Registry missing register_event_from_spec method")
		return false
	
	# Clear pending
	_event_registry.set("pending_code", "")
	_event_registry.set("pending_spec", {})
	
	print("[DeerFlow] Auto-registration complete for: ", event_name)
	return true


func trigger_pending_event(game_state: Dictionary) -> Dictionary:
	"""Trigger the pending event directly (bypass registration, for quick testing)."""
	var spec = get_pending_spec()
	if spec.is_empty():
		return {"success": false, "error": "no_pending_event"}
	
	var event_name = spec.get("event_name", "UNKNOWN")
	
	if _event_registry.has_method("execute_event_from_spec"):
		var result = _event_registry.execute_event_from_spec(spec, game_state)
		print("[DeerFlow] Triggered pending event: ", event_name, " result: ", result)
		return result
	
	return {"success": false, "error": "dispatcher_not_available"}
