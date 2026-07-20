class_name StructureDefinition
extends Resource

@export var structure_id: StringName
@export var display_name: String
@export_multiline var description: String

@export_category("Classification")
@export var category: StringName
@export var placement_mode: StringName = &"designated_zone"
@export var footprint_tiles: Vector2i = Vector2i(2, 2)
@export var unique_structure: bool = false

@export_category("Construction")
@export var recipe_id: StringName
@export var construction_time: float = 5.0
@export var required_site_tags: Array[StringName] = []
@export_range(0.0, 1.0, 0.05) var cancellation_refund_ratio: float = 0.5

@export_category("Power")
@export var base_generation_rate: float = 0.0
@export var minimum_power: float = 0.0
@export var standard_power: float = 0.0
@export var overdrive_power: float = 0.0
@export var overdrive_efficiency: float = 1.0
@export_range(0, 100, 1) var default_priority: int = 50

@export_category("Storage")
@export var storage_capacity: float = 0.0
@export var charge_rate: float = 0.0
@export var discharge_rate: float = 0.0

@export_category("Durability")
@export var max_integrity: float = 100.0
@export var armor_class: StringName = &"structure"
@export var repair_recipe_id: StringName

@export_category("Persistence")
@export var definition_version: int = 1

