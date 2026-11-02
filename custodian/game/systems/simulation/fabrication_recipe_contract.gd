class_name FabricationRecipeContract
extends RefCounted

const RECIPES := {
	"COMPONENTS_BATCH": {"category":"REPAIRS", "inputs":{"SCRAP":2}, "outputs":{"COMPONENTS":1}, "ticks":6.0},
	"DRONE_FRAME": {"category":"DRONES", "inputs":{"COMPONENTS":3}, "outputs":{"ASSEMBLIES":1}, "ticks":8.0},
	"ELECTRONICS_CORE": {"category":"DEFENSE", "inputs":{"COMPONENTS":2,"ASSEMBLIES":1}, "outputs":{"MODULES":1}, "ticks":10.0},
	"REPAIR_DRONE": {"category":"DRONES", "inputs":{"COMPONENTS":5,"ASSEMBLIES":2,"MODULES":1}, "outputs":{"repair_drones":1}, "ticks":12.0},
	"TURRET_AMMO": {"category":"DEFENSE", "inputs":{"COMPONENTS":1}, "outputs":{"turret_ammo":3}, "ticks":7.0},
	"ARCHIVE_PLATING": {"category":"ARCHIVE", "inputs":{"COMPONENTS":3,"ASSEMBLIES":1}, "outputs":{"ARCHIVE_ARMOR":1}, "ticks":14.0, "unlock_level":4},
}

static func get_recipe(recipe_id: String, knowledge_level: int) -> Dictionary:
	var recipe: Dictionary = RECIPES.get(recipe_id.to_upper(), {})
	if recipe.is_empty() or knowledge_level < int(recipe.get("unlock_level", 0)): return {}
	return recipe.duplicate(true)

static func has_inputs(state: WorldSimulationState, inputs: Dictionary) -> bool:
	for key in inputs:
		if int(state.inventory.get(String(key), 0)) < int(inputs[key]): return false
	return true

static func consume_inputs(state: WorldSimulationState, inputs: Dictionary) -> void:
	for key in inputs: state.inventory[String(key)] = int(state.inventory.get(String(key), 0)) - int(inputs[key])

static func apply_outputs(state: WorldSimulationState, outputs: Dictionary) -> void:
	for key in outputs:
		var amount := int(outputs[key]); var name := String(key)
		if name in ["repair_drones", "turret_ammo"]: state.stocks[name] = int(state.stocks.get(name, 0)) + amount
		elif name == "ARCHIVE_ARMOR":
			var archive: SectorSimulationState = state.sectors.get("ARCHIVE"); if archive != null: archive.damage = maxf(0.0, archive.damage - 0.2 * amount)
		else: state.inventory[name] = int(state.inventory.get(name, 0)) + amount
