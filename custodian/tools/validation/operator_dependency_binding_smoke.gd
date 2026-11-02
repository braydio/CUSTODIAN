extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const DEPENDENCIES_SCRIPT := preload(
	"res://game/actors/operator/operator_runtime_dependencies.gd"
)

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var composition_root := Node2D.new()
	composition_root.name = "OperatorDependencyCompositionRoot"
	root.add_child(composition_root)
	var world := Node2D.new()
	world.name = "World"
	composition_root.add_child(world)
	var projectiles := _add_node(world, "Projectiles")
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var wall_placer := _add_node(world, "WallPlacer")
	var wall_build_system := _add_node(world, "WallBuildSystem")
	var terminal_deployment := _add_node(world, "TerminalDeployment")
	var weapon_factory := _add_node(composition_root, "WeaponDefinitionFactory")
	var ui := _add_node(composition_root, "UI")
	var operator := OPERATOR_SCENE.instantiate()
	world.add_child(operator)
	operator.set_physics_process(false)
	operator.set_process(false)
	await process_frame

	var dependencies: OperatorRuntimeDependencies = operator.get("_runtime_dependencies")
	check(dependencies != null, "Operator did not bind a dependency bundle at its facade boundary")
	if dependencies != null:
		check(dependencies.world_root == world, "owning World reference was not injected")
		check(dependencies.projectile_container == projectiles, "projectile container was not injected")
		check(dependencies.camera == camera, "world camera was not injected")
		check(dependencies.weapon_definition_factory == weapon_factory, "composition-root weapon factory was not injected")
		check(dependencies.wall_placer == wall_placer, "wall placer was not injected")
		check(dependencies.wall_build_system == wall_build_system, "wall build system was not injected")
		check(dependencies.terminal_deployment == terminal_deployment, "terminal deployment was not injected")
		check(dependencies.ui == ui, "composition-root UI was not injected")
		check(dependencies.inventory_manager == root.get_node_or_null("InventoryManager"), "inventory autoload reference was not injected")
		check(dependencies.cognitive_state == root.get_node_or_null("CognitiveState"), "cognitive autoload reference was not injected")
		check(dependencies.dev_observatory == root.get_node_or_null("DevObservatory"), "optional observability reference was not injected")
		check(dependencies.sector_heatmap == root.get_node_or_null("SectorHeatmap"), "optional heatmap reference was not injected")
		check(dependencies.material_intelligence == root.get_node_or_null("MaterialIntelligence"), "optional material intelligence reference was not injected")
		check(dependencies.noise_event_bus == root.get_node_or_null("NoiseEventBus"), "noise bus reference was not injected")
		check(dependencies.input_prompt_service == root.get_node_or_null("InputPromptService"), "input prompt reference was not injected")
		check(dependencies.world_history == root.get_node_or_null("WorldHistory"), "optional history reference was not injected")
		check(dependencies.dev_mode == root.get_node_or_null("DevMode"), "optional dev-mode reference was not injected")
		check(dependencies.game_state == root.get_node_or_null("GameState"), "game-state reference was not injected")
		check(operator.call("_get_world_camera") == camera, "camera accessor did not consume its injected dependency")
		check(operator.call("_get_dev_observatory") == root.get_node_or_null("DevObservatory"), "observability accessor did not consume its injected dependency")
		check(operator.call("_get_input_prompt_service") == root.get_node_or_null("InputPromptService"), "input-prompt accessor did not consume its injected dependency")

	var incomplete := DEPENDENCIES_SCRIPT.new() as OperatorRuntimeDependencies
	check(not incomplete.validate_required().is_empty(), "missing required world reference was accepted")
	incomplete.world_root = world
	check(incomplete.validate_required().is_empty(), "explicit owning-world reference was rejected")
	check(operator.call("bind_runtime_dependencies", incomplete), "valid explicit dependency injection failed")
	check(operator.call("_get_world_camera") == null, "missing optional camera did not stay absent")
	check(operator.call("_get_dev_observatory") == null, "missing optional observatory did not stay absent")
	check(operator.call("_get_input_prompt_service") == null, "missing optional prompt service did not stay absent")
	check(operator.call("_find_nearest_blueprint") == null, "missing optional wall placer did not fail closed")
	check(not bool(operator.call("_is_terminal_open")), "missing optional UI did not fail closed")

	operator.queue_free()
	composition_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("operator_dependency_binding_smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _add_node(parent: Node, node_name: String) -> Node:
	var node := Node.new()
	node.name = node_name
	parent.add_child(node)
	return node


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
