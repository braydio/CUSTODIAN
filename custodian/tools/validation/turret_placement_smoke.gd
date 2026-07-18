extends SceneTree

const TurretPlacementScript := preload("res://game/systems/core/systems/turret_placement.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("/root/GameState")
	assert(game_state != null)
	var original_materials := int(game_state.get("materials"))
	game_state.set("materials", 10)

	var placement := TurretPlacementScript.new() as TurretPlacement
	root.add_child(placement)
	assert(placement.get_material_count() == 10)
	assert(placement.enter_placement_mode("gunner"))
	placement.exit_placement_mode()

	var turret_scene: PackedScene = placement.turret_scenes.get("gunner", null)
	assert(turret_scene != null)
	var turret := turret_scene.instantiate() as Node2D
	assert(turret != null)
	placement.get_placed_turrets().append(turret)
	assert(placement.attempt_dismantle(turret) == 5)
	assert(int(game_state.get("materials")) == 15)
	if is_instance_valid(turret):
		turret.free()

	game_state.set("materials", original_materials)
	placement.queue_free()
	await process_frame
	print("[TurretPlacementSmoke] ok")
	quit(0)
