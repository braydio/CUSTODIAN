class_name OperatorRuntimeDependencies
extends RefCounted
## Explicit external references shared across the Operator facade and future domains.
## This is a data bundle, not a service locator: it has no lookup API or tree access.

var world_root: Node
var projectile_container: Node
var weapon_definition_factory: Node
var camera: Node
var wall_placer: Node
var wall_build_system: Node
var terminal_deployment: Node
var ui: Node

var inventory_manager: Node
var cognitive_state: Node
var dev_observatory: Node
var sector_heatmap: Node
var material_intelligence: Node
var noise_event_bus: Node
var input_prompt_service: Node
var world_history: Node
var dev_mode: Node
var game_state: Node


func validate_required() -> PackedStringArray:
	var errors := PackedStringArray()
	if world_root == null:
		errors.append("world_root is required")
	return errors
