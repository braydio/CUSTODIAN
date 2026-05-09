extends Node
class_name FabRecipeDatabase

signal recipes_loaded()

@export var recipes_path: String = "res://content/fabrication/fab_recipes.json"

var _recipes: Dictionary = {}


func _ready() -> void:
	load_recipes()


func load_recipes() -> void:
	_recipes = _load_json_dictionary(recipes_path)
	recipes_loaded.emit()


func has_recipe(recipe_id: String) -> bool:
	return _recipes.has(recipe_id)


func get_recipe(recipe_id: String) -> Dictionary:
	return (_recipes.get(recipe_id, {}) as Dictionary).duplicate(true)


func get_all_recipes() -> Dictionary:
	return _recipes.duplicate(true)


func get_cost(recipe_id: String) -> Dictionary:
	var recipe := get_recipe(recipe_id)
	return (recipe.get("cost", {}) as Dictionary).duplicate(true)


func get_build_seconds(recipe_id: String) -> float:
	var recipe := get_recipe(recipe_id)
	return float(recipe.get("build_seconds", 0.0))


func _load_json_dictionary(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_warning("[FabRecipeDatabase] Missing recipe file: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[FabRecipeDatabase] Could not open recipe file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)

	push_warning("[FabRecipeDatabase] Invalid recipe JSON: %s" % path)
	return {}
