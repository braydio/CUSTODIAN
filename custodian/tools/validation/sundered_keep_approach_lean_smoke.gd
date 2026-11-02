extends SceneTree

const APPROACH := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var actor := CharacterBody2D.new()
	actor.name = "Operator"
	actor.add_to_group("player")
	world.add_child(actor)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var approach := APPROACH.instantiate() as Node2D
	root.add_child(approach)
	await process_frame
	await process_frame

	for removed_path: String in [
		"GrandVistaRoot/GrandVistaCinematicRoot/LabyrinthNearRoot/GrandVistaForegroundParapet",
		"OcclusionRoot/ApproachEdgeMistWrap",
		"OcclusionRoot/ApproachFogStrip01",
		"OcclusionRoot/ApproachFogStrip02",
		"OcclusionRoot/ApproachFogStrip03",
	]:
		_check(approach.get_node_or_null(removed_path) == null, "%s is still built" % removed_path, errors)

	var fortress_root := approach.get_node_or_null("GrandVistaRoot/FortressVistaRoot")
	var component_count := 0
	if fortress_root == null:
		errors.append("FortressVistaRoot is missing")
	else:
		component_count = fortress_root.find_children("*", "Sprite2D", true, false).size()
	_check(component_count == 17, "expected 17 fortress sprites, got %d" % component_count, errors)
	_check(get_nodes_in_group("authored_vista_enemy").is_empty(), "authored vista enemies defaulted on", errors)

	for light_name: String in ["LabyrinthMoonRimLight", "LabyrinthGateLight"]:
		var light := approach.get_node_or_null("OcclusionRoot/" + light_name) as PointLight2D
		_check(light != null and light.texture is GradientTexture2D, "%s is missing radial texture" % light_name, errors)
		if light != null and light.texture is GradientTexture2D:
			var texture := light.texture as GradientTexture2D
			_check(texture.width == 256 and texture.height == 256, "%s is not 256x256" % light_name, errors)

	var hidden_layer := approach.get_node_or_null(
		"GrandVistaRoot/GrandVistaCinematicRoot/LabyrinthFarParallax"
	) as Node2D
	if hidden_layer == null:
		errors.append("hidden Grand Vista parallax layer is missing")
	else:
		var before := hidden_layer.position
		camera.global_position += Vector2(400.0, 200.0)
		hidden_layer.call("_process", 1.0)
		_check(hidden_layer.position == before, "hidden Grand Vista parallax still processed", errors)

	var import_file := FileAccess.open(
		"res://content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png.import",
		FileAccess.READ
	)
	var import_text := import_file.get_as_text() if import_file != null else ""
	_check("mipmaps/generate=false" in import_text, "route-master mipmaps remain enabled", errors)

	game_root.queue_free()
	approach.queue_free()
	await process_frame
	if errors.is_empty():
		print("[SunderedKeepApproachLeanSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error("[SunderedKeepApproachLeanSmoke] %s" % error)
	quit(1)


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)
