extends Area2D
class_name FabricatorTerminal

@export var interaction_label: String = "FABRICATOR"
@export var allowed_recipe_categories: Array[String] = []


func get_interaction_text() -> String:
	return interaction_label


func can_start_recipe(recipe_id: String) -> bool:
	var pipeline := _get_fab_pipeline()
	if pipeline == null:
		return false
	var recipe: Dictionary = pipeline.call("get_recipe", recipe_id)
	if recipe.is_empty():
		return false
	if not _recipe_category_allowed(recipe):
		return false
	return bool(pipeline.call("can_start_recipe", recipe_id))


func start_recipe(recipe_id: String) -> bool:
	var pipeline := _get_fab_pipeline()
	if pipeline == null:
		return false
	var recipe: Dictionary = pipeline.call("get_recipe", recipe_id)
	if recipe.is_empty():
		return false
	if not _recipe_category_allowed(recipe):
		return false
	return bool(pipeline.call("try_start_recipe", recipe_id))


func get_recipe_list() -> Dictionary:
	var pipeline := _get_fab_pipeline()
	if pipeline == null:
		return {}
	var recipes: Dictionary = pipeline.call("get_all_recipes")
	if allowed_recipe_categories.is_empty():
		return recipes

	var filtered: Dictionary = {}
	for recipe_id in recipes.keys():
		var recipe: Dictionary = recipes[recipe_id]
		if _recipe_category_allowed(recipe):
			filtered[recipe_id] = recipe.duplicate(true)
	return filtered


func _recipe_category_allowed(recipe: Dictionary) -> bool:
	if allowed_recipe_categories.is_empty():
		return true
	var category := str(recipe.get("category", ""))
	return allowed_recipe_categories.has(category)


func _get_fab_pipeline() -> Node:
	return get_node_or_null("/root/FabPipeline")
