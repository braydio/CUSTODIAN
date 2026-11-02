extends SceneTree

const LEVEL_DEFINITION_SCRIPT := preload("res://game/world/levels/level_definition.gd")
const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var default_definition: RefCounted = LEVEL_DEFINITION_SCRIPT.new()
	default_definition.call("configure_from_dictionary", {})
	if default_definition.call("get_presentation_profile") != &"gameplay":
		errors.append("definition default is not gameplay")
	var registry: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
	if not registry.call("load_index"):
		errors.append("production level registry did not load")
	else:
		var vista: RefCounted = registry.call("get_level", &"sundered_keep_vista_approach")
		var keep: RefCounted = registry.call("get_level", &"sundered_keep_front_gate")
		if vista == null or vista.call("get_presentation_profile") != &"vista_approach":
			errors.append("Sundered Vista node does not own vista_approach presentation")
		if keep == null or keep.call("get_presentation_profile") != &"gameplay":
			errors.append("Sundered Front Gate should own gameplay presentation")
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "cinematic_profile", &"cinematic", &"Spawn_Main")
	fixture.ingress.set("_triggered", true)
	fixture.ingress.call("_enter_approach", fixture.actor)
	if fixture.ui.presentation_mode != &"cinematic":
		errors.append("registered cinematic profile was not applied")
	if not fixture.actor.vista_presentation_enabled:
		errors.append("cinematic profile did not suppress Operator gameplay presentation")
	var level: Node = fixture.loader.call("get_active_level_instance") as Node
	if level != null:
		level.call("return_to_main", fixture.actor)
		await process_frame
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelPresentationProfileSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[LevelPresentationProfileSmoke] %s" % error)
	quit(1)
