class_name ConstructionCatalog
extends RefCounted

const ENTRIES := {
	&"capacitor_bank_mk1": {
		"definition": preload("res://content/infrastructure/definitions/power/capacitor_bank_mk1.tres"),
		"scene": preload("res://game/infrastructure/structures/capacitor_bank_mk1.tscn"),
	},
}


static func has_build(build_id: StringName) -> bool:
	return ENTRIES.has(build_id)


static func get_entry(build_id: StringName) -> Dictionary:
	if not ENTRIES.has(build_id):
		return {}
	return (ENTRIES[build_id] as Dictionary).duplicate()


static func get_definition(build_id: StringName) -> StructureDefinition:
	return get_entry(build_id).get("definition", null) as StructureDefinition


static func get_scene(build_id: StringName) -> PackedScene:
	return get_entry(build_id).get("scene", null) as PackedScene
