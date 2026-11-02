extends RefCounted
class_name TerminalWorldActionService


func toggle_sector_power(scene: SceneTree, sector_name: String) -> bool:
	var power := scene.root.get_node_or_null("GameRoot/Power")
	return power != null and bool(power.call("toggle_sector_power", sector_name))


func set_sector_priority(scene: SceneTree, sector_name: String, priority: int) -> bool:
	var power := scene.root.get_node_or_null("GameRoot/Power")
	return power != null and bool(power.call("set_sector_priority", sector_name, priority))


func apply_emergency_repair(scene: SceneTree, sector_name: String) -> Dictionary:
	var power := scene.root.get_node_or_null("GameRoot/Power")
	return power.call("apply_emergency_repair", sector_name) if power != null else {"available": false, "reason": "POWER_UNAVAILABLE"}


func start_recipe(scene: SceneTree, recipe_id: String) -> bool:
	var pipeline := scene.root.get_node_or_null("FabPipeline")
	return pipeline != null and bool(pipeline.call("try_start_recipe", recipe_id))


func enter_turret_placement(scene: SceneTree, build_token_id: String = "turret_basic") -> bool:
	var placement := scene.root.get_node_or_null("GameRoot/World/TurretPlacement")
	return placement != null and bool(placement.call("enter_build_token_placement", build_token_id))


func enter_construction_placement(scene: SceneTree, build_token_id: StringName) -> bool:
	var placement := scene.root.get_node_or_null("GameRoot/World/ConstructionPlacement")
	return placement != null and bool(placement.call("enter_build_token_placement", build_token_id))
