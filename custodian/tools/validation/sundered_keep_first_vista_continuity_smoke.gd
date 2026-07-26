extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)


class PresentationCamera:
	extends Camera2D

	func set_follow_target(_target: Node2D) -> void:
		pass

	func set_presentation_framing(
		_active: bool,
		_offset := Vector2.ZERO,
		_zoom := Vector2.ONE
	) -> void:
		pass


func _init() -> void:
	_run.call_deferred()


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
	var camera := PresentationCamera.new()
	camera.name = "Camera2D"
	world.add_child(camera)

	var scene := APPROACH_SCENE.instantiate() as Node2D
	root.add_child(scene)
	await process_frame

	var controller := scene.get_node_or_null(
		"VistaController"
	) as SunderedKeepVistaController
	var control_start := scene.get_node_or_null(
		"Markers/FirstCameraControlStart"
	) as Marker2D
	var control_apex := scene.get_node_or_null(
		"Markers/RevealControlStart"
	) as Marker2D
	var return_start := scene.get_node_or_null(
		"Markers/RevealControlEnd"
	) as Marker2D
	var return_complete := scene.get_node_or_null(
		"Markers/FirstCameraReturnComplete"
	) as Marker2D
	var base_horizon := scene.get_node_or_null(
		"UnderlayRoot/FirstVistaBaseStormHorizon"
	) as Sprite2D
	var ocean_underlay := scene.get_node_or_null(
		"UnderlayRoot/ApproachOceanVoidUnderlay"
	) as Sprite2D
	var vista_root := scene.get_node_or_null("VistaRoot") as CanvasItem
	var keep := scene.get_node_or_null(
		"ParallaxRoot/RevealDepth/DistantKeep_Parallax2D/"
		+ "DistantSunderedKeepLandmark"
	) as Sprite2D
	var fog := scene.get_node_or_null(
		"VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil"
	) as Sprite2D
	var light := scene.get_node_or_null(
		"OcclusionRoot/RevealMoonlightCue"
	) as PointLight2D
	var cinematic := scene.get_node_or_null(
		"GrandVistaRoot/GrandVistaCinematicRoot"
	) as CanvasItem
	var final_veil := scene.get_node_or_null(
		"OcclusionRoot/ApproachFinalGateShadowVeil"
	) as CanvasItem

	for required: Node in [
		controller,
		control_start,
		control_apex,
		return_start,
		return_complete,
		base_horizon,
		ocean_underlay,
		vista_root,
		keep,
		fog,
		light,
		cinematic,
		final_veil,
	]:
		if required == null:
			errors.append("first-vista continuity fixture is incomplete")
			_finish(game_root, errors)
			return

	if scene.get_node_or_null(
		"VistaRoot/FirstVistaFarParallax/ApproachFirstVistaHorizon"
	) != null:
		errors.append("baked alternate first-vista wallpaper is still active")
	_expect_texture(
		base_horizon,
		"first_vista_base_storm_horizon.png",
		Vector2i(2600, 1460),
		errors
	)
	_expect_texture(
		keep,
		"distant_sundered_keep_landmark_v2.png",
		Vector2i(1840, 854),
		errors
	)
	_expect_texture(
		fog,
		"first_vista_reveal_veil.png",
		Vector2i(2600, 720),
		errors
	)

	var enter_axis := (
		control_apex.global_position
		- control_start.global_position
	)
	var return_axis := (
		return_complete.global_position
		- return_start.global_position
	)
	var before := control_start.global_position - enter_axis * 0.25
	var early := control_start.global_position.lerp(
		control_apex.global_position,
		0.23
	)
	var apex := control_apex.global_position.lerp(
		return_start.global_position,
		0.5
	)
	var after := return_complete.global_position + return_axis * 0.25
	var fog_origin := fog.get_meta(
		"first_vista_fog_origin",
		fog.position
	) as Vector2

	actor.global_position = before
	controller.apply_progress(0.0)
	_expect_continuous_world(
		base_horizon,
		ocean_underlay,
		vista_root,
		cinematic,
		final_veil,
		errors
	)
	_expect_close(keep.modulate.a, 0.08, 0.02, "concealed Keep alpha", errors)
	_expect_close(fog.modulate.a, 0.68, 0.02, "concealing fog alpha", errors)
	_expect_close(light.energy, 0.0, 0.01, "pre-reveal light", errors)

	actor.global_position = early
	controller.apply_progress(0.0)
	_expect_continuous_world(
		base_horizon,
		ocean_underlay,
		vista_root,
		cinematic,
		final_veil,
		errors
	)
	if keep.modulate.a > 0.14:
		errors.append("23% reveal makes the Keep readable too early")
	if fog.modulate.a < 0.63:
		errors.append("23% reveal removes too much concealing fog")
	if light.energy > 0.04:
		errors.append("23% reveal overstates the moonlight cue")

	actor.global_position = apex
	controller.apply_progress(0.0)
	_expect_continuous_world(
		base_horizon,
		ocean_underlay,
		vista_root,
		cinematic,
		final_veil,
		errors
	)
	_expect_close(keep.modulate.a, 0.92, 0.02, "apex Keep alpha", errors)
	_expect_close(fog.modulate.a, 0.24, 0.02, "apex fog alpha", errors)
	_expect_close(light.energy, 0.20, 0.02, "apex moonlight cue", errors)
	var apex_fog_travel := fog.position.distance_to(fog_origin)
	if apex_fog_travel < 80.0 or apex_fog_travel > 140.0:
		errors.append(
			"fog peel travel %.2f is outside the 80–140 px budget (%s -> %s)"
			% [apex_fog_travel, fog_origin, fog.position]
		)

	actor.global_position = after
	controller.apply_progress(0.0)
	_expect_continuous_world(
		base_horizon,
		ocean_underlay,
		vista_root,
		cinematic,
		final_veil,
		errors
	)
	_expect_close(keep.modulate.a, 0.82, 0.02, "settled Keep alpha", errors)
	_expect_close(fog.modulate.a, 0.32, 0.02, "settled fog alpha", errors)

	actor.global_position = before
	controller.apply_progress(0.0)
	_expect_close(keep.modulate.a, 0.08, 0.02, "reverse concealed Keep alpha", errors)
	_expect_close(fog.modulate.a, 0.68, 0.02, "reverse concealing fog alpha", errors)
	if fog.position.distance_to(fog_origin) > 1.0:
		errors.append(
			"reverse traversal did not restore the reveal veil (%s -> %s)"
			% [fog_origin, fog.position]
		)

	_finish(game_root, errors)


func _expect_continuous_world(
	base_horizon: Sprite2D,
	ocean_underlay: Sprite2D,
	vista_root: CanvasItem,
	cinematic: CanvasItem,
	final_veil: CanvasItem,
	errors: Array[String]
) -> void:
	if base_horizon.modulate.a < 0.99:
		errors.append("base storm horizon crossfaded")
	if ocean_underlay.modulate.a < 0.99:
		errors.append("ocean underlay crossfaded")
	if vista_root.modulate.a < 0.99:
		errors.append("first-vista presentation root crossfaded")
	if cinematic.modulate.a > 0.01:
		errors.append("second-vista cinematic appeared during Camera 1")
	if final_veil.modulate.a > 0.01:
		errors.append("final-gate veil appeared during Camera 1")


func _expect_texture(
	sprite: Sprite2D,
	suffix: String,
	expected_size: Vector2i,
	errors: Array[String]
) -> void:
	if sprite.texture == null:
		errors.append("%s is missing its texture" % sprite.name)
		return
	if not sprite.texture.resource_path.ends_with(suffix):
		errors.append("%s uses the wrong texture" % sprite.name)
	if Vector2i(sprite.texture.get_size()) != expected_size:
		errors.append(
			"%s expected %s source art, got %s"
			% [sprite.name, expected_size, sprite.texture.get_size()]
		)


func _expect_close(
	actual: float,
	expected: float,
	tolerance: float,
	label: String,
	errors: Array[String]
) -> void:
	if absf(actual - expected) > tolerance:
		errors.append(
			"%s expected %.2f, got %.3f"
			% [label, expected, actual]
		)


func _finish(game_root: Node, errors: Array[String]) -> void:
	game_root.queue_free()
	if errors.is_empty():
		print("[SunderedKeepFirstVistaContinuitySmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepFirstVistaContinuitySmoke] %s" % error)
	quit(1)
