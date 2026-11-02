extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)
const RETIRED_FOG_SHEET := (
	"res://content/backgrounds/sundered_keep/approach/fog/"
	+ "outer_wall_checkpoint_fog_ribbon_01.png"
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
	var actor := Node2D.new()
	actor.name = "Operator"
	world.add_child(actor)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var approach := APPROACH_SCENE.instantiate()
	root.add_child(approach)
	await process_frame
	await process_frame
	var fog := approach.get_node_or_null(
		"UnderlayRoot/OuterWallCheckpointFog"
	) as Sprite2D
	_check(fog is ProceduralFogRibbon2D, "procedural fog node is missing", errors)
	if fog is ProceduralFogRibbon2D:
		var ribbon := fog as ProceduralFogRibbon2D
		_check(ribbon.ribbon_size == Vector2(1536.0, 384.0), "fog coverage size drifted", errors)
		_check(ribbon.texture != null and ribbon.texture.get_size() == Vector2.ONE, "fog does not use a 1x1 carrier texture", errors)
		_check(ribbon.material is ShaderMaterial, "fog shader material is missing", errors)
		_check(ribbon.fog_tint.a <= 0.3001, "fog alpha exceeds readability limit", errors)
		_check(ribbon.z_index == -1, "fog depth drifted", errors)
		_check(not bool(ribbon.get_meta("collision_authority", true)), "fog owns collision authority", errors)
	_check(not ResourceLoader.exists(RETIRED_FOG_SHEET), "retired 9216x384 fog sheet still exists", errors)
	game_root.queue_free()
	approach.queue_free()
	await process_frame
	if errors.is_empty():
		print("[SunderedKeepProceduralFogRibbonSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepProceduralFogRibbonSmoke] %s" % error)
	quit(1)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)
