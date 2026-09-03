extends SceneTree

# Real generated-world integration proof for the ambient enemy spawn chain.
#
# procgen_enemy_family_spawn_smoke and ambient_actor_spawn_walkability_smoke
# both use a fixture WalkabilityProvider that unconditionally returns
# "walkable" once armed. That is enough to prove the marker/camp/spawner
# wiring, but it cannot catch a mismatch between EncounterCadencePlanner's
# notion of "walkable" and ProcGenTilemap's own runtime walkability authority
# (find_safe_runtime_walkable_global). This smoke drives a real
# CustodianContractMap generation, feeds the resulting contract through the
# real ContractWorldLoader marker-placement path, and requires the real
# ProcGenTilemap walkability authority to accept at least one spawn per
# family so an EnemyGrunt and a PursuitFrame actually enter the tree.

const CONTRACT_SCENE := preload(
	"res://game/world/procgen/custodian_contract_map.tscn"
)
const LOADER_SCRIPT := preload(
	"res://game/systems/core/systems/contract_world_loader.gd"
)
const SPAWNER_SCRIPT := preload(
	"res://game/systems/spawning/ambient_enemy_spawner.gd"
)
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const PURSUIT_SCENE := preload("res://game/actors/enemies/pursuit_frame.tscn")
const DEFAULT_SEED := 12345


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var seed_arg := DEFAULT_SEED
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			seed_arg = int(argument.trim_prefix("--seed="))

	var contract_map := CONTRACT_SCENE.instantiate() as CustodianContractMap
	contract_map.auto_generate_on_ready = false
	root.add_child(contract_map)
	await process_frame

	await contract_map.generate_contract(seed_arg)
	var contract := contract_map.get_latest_contract()
	if contract.is_empty():
		push_error(
			"[ProcgenAmbientEnemyRealWorldSpawnSmoke] generation failed: %s"
			% str(contract_map.get_latest_generation_failure())
		)
		quit(1)
		return

	var map_record := contract.get("map", {}) as Dictionary
	var map_instance := map_record.get("instance") as Node
	var level_data := map_record.get("level_data", {}) as Dictionary
	var errors: Array[String] = []

	var encounter_plan := level_data.get("encounter_plan", {}) as Dictionary
	var encounters := encounter_plan.get("encounters", []) as Array
	if String(encounter_plan.get("schema", "")) != "custodian.procgen_encounter_plan.v1":
		errors.append("level_data.encounter_plan missing custodian.procgen_encounter_plan.v1 schema")
	if encounters.is_empty():
		errors.append(
			"encounter plan produced zero encounters; skipped=%s"
			% str(encounter_plan.get("skipped", []))
		)

	# --- Real GameRoot/World rig, mirroring ContractWorldLoader's defaults ---
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var enemies_root := Node2D.new()
	enemies_root.name = "Enemies"
	world.add_child(enemies_root)
	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	operator.add_to_group("player")
	var operator_collision := CollisionShape2D.new()
	var operator_shape := CircleShape2D.new()
	operator_shape.radius = 8.0
	operator_collision.shape = operator_shape
	operator.add_child(operator_collision)
	world.add_child(operator)
	for child_name in [
		"SpawnNodes", "Camera2D", "CommandTerminal",
		"FieldFabricatorMk1", "FabricationConstructionZone", "Items", "Sectors",
	]:
		var placeholder := Node2D.new()
		placeholder.name = child_name
		world.add_child(placeholder)
	var nav_system := Node.new()
	nav_system.name = "NavigationSystem"
	game_root.add_child(nav_system)

	var spawner := SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	spawner.name = "AmbientEnemySpawner"
	spawner.enemy_scene = GRUNT_SCENE
	spawner.enemy_scenes = [GRUNT_SCENE, PURSUIT_SCENE]
	spawner.enemy_container_path = NodePath("../World/Enemies")
	game_root.add_child(spawner)

	if not map_instance.is_in_group("procgen_walkability_provider"):
		errors.append("generated map_instance did not join procgen_walkability_provider group")

	var loader := LOADER_SCRIPT.new() as ContractWorldLoader
	loader.name = "ContractWorldLoader"
	root.add_child(loader)
	loader.call("_on_contract_generated", contract)
	for i in 3:
		await process_frame

	var markers := get_nodes_in_group("ambient_enemy_camp_marker")
	if markers.is_empty():
		errors.append("no ambient_enemy_camp_marker nodes were placed from the generated contract")

	var camps := get_nodes_in_group("ambient_enemy_camp")
	if camps.is_empty():
		errors.append("no AmbientEnemyCamp nodes were created from the placed markers")

	# Bring the player to the nearest camp so activation range engages, then
	# pump both idle (camp activation) and physics (spawn queue drain) frames
	# the way real gameplay does.
	if not camps.is_empty():
		var nearest := camps[0] as AmbientEnemyCamp
		var nearest_dist := INF
		for c in camps:
			var camp := c as AmbientEnemyCamp
			var d := camp.global_position.distance_to(operator.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = camp
		operator.global_position = nearest.global_position
	for i in 40:
		await process_frame
		await physics_frame

	var grunts := 0
	var pursuit_frames := 0
	for child in enemies_root.get_children():
		if child.name.begins_with("EnemyGrunt"):
			grunts += 1
		elif child.name.begins_with("PursuitFrame"):
			pursuit_frames += 1

	print(
		(
			"[ProcgenAmbientEnemyRealWorldSpawnSmoke] seed=%d encounters=%d markers=%d "
			+ "camps=%d active_enemy_count=%d grunts=%d pursuit_frames=%d"
		) % [
			seed_arg, encounters.size(), markers.size(), camps.size(),
			spawner.get_active_enemy_count(), grunts, pursuit_frames,
		]
	)

	if grunts == 0:
		errors.append("real generated world produced zero EnemyGrunt spawns")
	if pursuit_frames == 0:
		errors.append("real generated world produced zero PursuitFrame spawns")

	if errors.is_empty():
		print("procgen_ambient_enemy_real_world_spawn_smoke: PASS")
		quit(0)
		return
	for error in errors:
		push_error("[ProcgenAmbientEnemyRealWorldSpawnSmoke] %s" % error)
	quit(1)
