class_name VehicleSpawnResolver
extends Node

const VehicleRegistryScript = preload("res://game/vehicles/vehicle_registry.gd")

@export var registry_path: String = VehicleRegistry.DEFAULT_ARCHETYPES_PATH
@export var allow_placeholder_spawn: bool = false

var registry: VehicleRegistry = null


func _ready() -> void:
	_ensure_registry()


func spawn_vehicle(vehicle_id: String, parent: Node, global_position: Vector2) -> Node2D:
	_ensure_registry()
	if registry == null:
		push_warning("VehicleSpawnResolver: registry unavailable")
		return null
	var definition: VehicleDefinition = registry.get_vehicle(vehicle_id) as VehicleDefinition
	if definition == null:
		push_warning("VehicleSpawnResolver: unknown vehicle id '%s'" % vehicle_id)
		return null
	return spawn_definition(definition, parent, global_position)


func spawn_definition(definition: VehicleDefinition, parent: Node, global_position: Vector2) -> Node2D:
	if definition == null or parent == null:
		return null
	var errors: PackedStringArray = definition.validate()
	if not errors.is_empty():
		push_warning("VehicleSpawnResolver: invalid vehicle '%s': %s" % [definition.id_or_placeholder(), "; ".join(errors)])
		return null
	if not definition.is_runtime_supported() and not (definition.allow_placeholder_spawn or allow_placeholder_spawn):
		push_warning("VehicleSpawnResolver: refusing unsupported domain '%s' for '%s'" % [definition.domain, definition.id])
		return null
	var scene: Resource = load(definition.runtime_scene)
	if not (scene is PackedScene):
		push_warning("VehicleSpawnResolver: runtime scene missing or not PackedScene: %s" % definition.runtime_scene)
		return null
	var instance: Node = (scene as PackedScene).instantiate()
	if not (instance is Node2D):
		instance.queue_free()
		push_warning("VehicleSpawnResolver: runtime scene root is not Node2D for '%s'" % definition.id)
		return null
	var vehicle := instance as Node2D
	if vehicle.has_method("apply_vehicle_definition"):
		vehicle.call("apply_vehicle_definition", definition)
	vehicle.global_position = global_position
	parent.add_child(vehicle)
	vehicle.add_to_group("vehicle")
	vehicle.add_to_group("vehicles")
	if definition.is_pilotable():
		vehicle.add_to_group("pilotable_vehicles")
	return vehicle


func _ensure_registry() -> void:
	if registry != null:
		return
	registry = VehicleRegistry.new()
	add_child(registry)
	registry.load_registry(registry_path)
