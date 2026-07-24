extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)

const PARALLAX_PATHS := [
	"VistaRoot/FirstVistaFarParallax",
	"VistaRoot/FirstVistaMistParallax",
	"GrandVistaRoot/LabyrinthFarParallax",
	"GrandVistaRoot/LabyrinthMistParallax",
	"GrandVistaRoot/LabyrinthNearRoot",
]

const ROOF_NAMES := [
	"WestKeepRoof",
	"CentralKeepRoof",
	"ExitKeepRoof",
]


class PresentationCamera:
	extends Camera2D

	var follow_target: Node2D
	var framing_offset := Vector2.ZERO
	var framing_zoom := Vector2.ONE
	var runtime_map: Node

	func set_follow_target(target: Node2D) -> void:
		follow_target = target

	func set_presentation_framing(
		_active: bool,
		target_offset := Vector2.ZERO,
		target_zoom := Vector2.ONE
	) -> void:
		framing_offset = target_offset
		framing_zoom = target_zoom

	func set_runtime_map(map: Node) -> void:
		runtime_map = map


func _init() -> void:
	var errors: Array[String] = []
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)

	var actor := CharacterBody2D.new()
	actor.name = "Operator"
	actor.add_to_group("operator")
	actor.add_to_group("player")
	actor.collision_layer = 1
	actor.collision_mask = 1
	var actor_shape := CollisionShape2D.new()
	var actor_circle := CircleShape2D.new()
	actor_circle.radius = 10.0
	actor_shape.shape = actor_circle
	actor.add_child(actor_shape)
	world.add_child(actor)

	var camera := PresentationCamera.new()
	camera.name = "Camera2D"
	camera.follow_target = actor
	world.add_child(camera)

	var scene := APPROACH_SCENE.instantiate() as Node2D
	if scene == null:
		_fail("Could not instantiate SunderedKeepApproach")
		return
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame

	var controller := scene.get_node_or_null(
		"VistaController"
	) as SunderedKeepVistaController
	var director := scene.get_node_or_null(
		"RevealDirector"
	) as SunderedKeepRevealDirector
	var vista_root := scene.get_node_or_null("VistaRoot") as CanvasItem
	if controller == null:
		errors.append("VistaController missing")
	if director == null:
		errors.append("RevealDirector missing")
	if vista_root == null:
		errors.append("VistaRoot missing")

	if controller != null:
		var initial := controller.get_camera_target_state()
		_expect_vec2(
			initial.get("offset", Vector2.INF),
			Vector2(0.0, -18.0),
			"initial camera offset",
			errors
		)
		_expect_vec2(
			initial.get("zoom", Vector2.ZERO),
			Vector2(1.12, 1.12),
			"initial camera zoom",
			errors
		)
	if camera.follow_target != actor:
		errors.append("initial camera follow target is not Operator")

	if controller != null:
		controller.apply_progress(0.50)
	if vista_root != null and vista_root.modulate.a > 0.01:
		errors.append("VistaRoot became visible from raw route progress")
	if director != null and director.has_played():
		errors.append("RevealDirector played before the physical reveal trigger")

	if director != null:
		director.anticipation_duration = 0.01
		director.reveal_in_duration = 0.04
		director.reveal_hold_duration = 0.15
		director.return_duration = 0.04
		director.atmosphere_settle_duration = 0.01

	var completion_count := [0]
	if director != null:
		director.reveal_completed.connect(
			func() -> void:
				completion_count[0] += 1
		)

	var reveal_trigger := scene.get_node_or_null(
		"SequenceTriggers/FirstVistaRevealTrigger"
	) as Area2D
	if reveal_trigger == null:
		errors.append("FirstVistaRevealTrigger missing")
	elif director != null:
		actor.global_position = reveal_trigger.global_position
		for unused in 8:
			await physics_frame
			if director.has_played():
				break
		if not director.has_played():
			errors.append("physical overlap did not start the first reveal")

	if director != null and director.has_played():
		var reached_hold := false
		for unused in 30:
			await process_frame
			var state := controller.get_reveal_choreography_state()
			if state.get("phase", "") == "FIRST_REVEAL_HOLD":
				reached_hold = true
				break
		if not reached_hold:
			errors.append("first reveal never reached its hold phase")
		else:
			if camera.follow_target == actor:
				errors.append("reveal camera never followed CameraPresentationAnchor")
			_expect_vec2(
				camera.framing_zoom,
				Vector2(0.84, 0.84),
				"first reveal zoom",
				errors
			)
		for unused in 40:
			if bool(
				director.get_reveal_state().get(
					"ready_for_return",
					false
				)
			):
				break
			await process_frame
		var progress_state := (
			controller.get_reveal_choreography_state()
		)
		if progress_state.get("phase", "") != "FIRST_PROGRESS_CONTROL":
			errors.append(
				"first reveal did not enter progress-driven framing"
			)
		var control_start := scene.get_node_or_null(
			"Markers/RevealControlStart"
		) as Marker2D
		var control_end := scene.get_node_or_null(
			"Markers/RevealControlEnd"
		) as Marker2D
		if control_start == null or control_end == null:
			errors.append("reveal-control markers missing")
		else:
			actor.global_position = control_start.global_position.lerp(
				control_end.global_position,
				0.5
			)
			await process_frame
			progress_state = (
				controller.get_reveal_choreography_state()
			)
			var progress_weight := float(
				progress_state.get(
					"first_progress_weight",
					-1.0
				)
			)
			if progress_weight < 0.45 or progress_weight > 0.55:
				errors.append(
					"player position did not drive reveal framing progress"
				)
			var first_anchor := scene.get_node_or_null(
				"Markers/FirstRevealCameraAnchor"
			) as Marker2D
			var presentation_anchor := controller.get_node_or_null(
				"CameraPresentationAnchor"
			) as Marker2D
			if first_anchor == null or presentation_anchor == null:
				errors.append(
					"progress-controlled camera anchor is unavailable"
				)
			else:
				var expected_anchor := (
					first_anchor.global_position.lerp(
						control_end.global_position,
						0.5
					)
				)
				if presentation_anchor.global_position.distance_to(
					expected_anchor
				) > 1.0:
					errors.append(
						"reveal progress did not interpolate "
						+ "between authored camera endpoints"
					)
		var return_trigger := scene.get_node_or_null(
			"SequenceTriggers/ReturnToGameplayTrigger"
		) as Area2D
		if return_trigger == null:
			errors.append("ReturnToGameplayTrigger missing")
		else:
			actor.global_position = return_trigger.global_position
			for unused in 8:
				await physics_frame
				if bool(
					director.get_reveal_state().get(
						"return_running",
						false
					)
				):
					break
		if not director.is_reveal_complete():
			await director.reveal_completed

	if director != null and not director.is_reveal_complete():
		errors.append("first reveal did not complete")
	if camera.follow_target != actor:
		errors.append("camera follow target did not return to Operator")
	_expect_vec2(
		camera.framing_offset,
		Vector2(0.0, -48.0),
		"returned gameplay offset",
		errors
	)
	_expect_vec2(
		camera.framing_zoom,
		Vector2(0.98, 0.98),
		"returned gameplay zoom",
		errors
	)
	if vista_root != null and vista_root.modulate.a < 0.99:
		errors.append("VistaRoot did not remain visible after the reveal")
	if reveal_trigger != null:
		actor.global_position = reveal_trigger.global_position + Vector2(0.0, 300.0)
		await physics_frame
		actor.global_position = reveal_trigger.global_position
		await physics_frame
		await process_frame
	if int(completion_count[0]) != 1:
		errors.append("first reveal did not remain one-shot")

	await _check_parallax(scene, camera, errors)
	await _check_roofs(scene, actor, errors)
	_check_labyrinth_depth(scene, errors)
	_check_final_fog(scene, errors)

	if errors.is_empty():
		print("[SunderedKeepVistaPolishSmoke] PASS")
		quit(0)
	else:
		for error in errors:
			push_error("[SunderedKeepVistaPolishSmoke] %s" % error)
		_fail("%d checks failed" % errors.size())


func _check_parallax(
	scene: Node2D,
	camera: PresentationCamera,
	errors: Array[String]
) -> void:
	var layers: Array[Node2D] = []
	for layer_path in PARALLAX_PATHS:
		var layer := scene.get_node_or_null(layer_path) as Node2D
		if layer == null:
			errors.append("%s missing" % layer_path)
		else:
			layers.append(layer)
	if layers.size() != PARALLAX_PATHS.size():
		return

	var first_far := layers[0]
	var first_mist := layers[1]
	var labyrinth_far := layers[2]
	var labyrinth_mist := layers[3]
	var labyrinth_near := layers[4]
	if first_far.get("follow_ratio").x <= first_mist.get("follow_ratio").x:
		errors.append("first vista far parallax ratio must exceed mist ratio")
	if labyrinth_far.get("follow_ratio").x <= labyrinth_mist.get("follow_ratio").x:
		errors.append("Labyrinth far parallax ratio must exceed mist ratio")
	if labyrinth_mist.get("follow_ratio").x <= labyrinth_near.get("follow_ratio").x:
		errors.append("Labyrinth mist parallax ratio must exceed near ratio")

	var origins: Array[Vector2] = []
	for layer in layers:
		origins.append(layer.position)
	var playable_position := (
		scene.get_node("PlayableRoot") as Node2D
	).position
	var collision_position := (
		scene.get_node("Collision") as Node2D
	).position
	camera.global_position += Vector2(120.0, 80.0)
	await process_frame
	await process_frame
	for index in layers.size():
		if layers[index].position.is_equal_approx(origins[index]):
			errors.append("%s did not respond to camera movement" % PARALLAX_PATHS[index])
	if (scene.get_node("PlayableRoot") as Node2D).position != playable_position:
		errors.append("PlayableRoot moved with the parallax layers")
	if (scene.get_node("Collision") as Node2D).position != collision_position:
		errors.append("route collisions moved with the parallax layers")


func _check_roofs(
	scene: Node2D,
	actor: CharacterBody2D,
	errors: Array[String]
) -> void:
	var route_master := scene.get_node_or_null(
		"PlayableRoot/ApproachRouteMaster"
	) as Sprite2D
	if route_master == null:
		errors.append("ApproachRouteMaster missing")
	elif not (
		route_master.material is ShaderMaterial
		and (route_master.material as ShaderMaterial).shader != null
		and (route_master.material as ShaderMaterial).shader.resource_path.ends_with(
			"route_master_occlusion_mask.gdshader"
		)
	):
		errors.append("ApproachRouteMaster is missing the roof cutout shader")

	var roof_root := scene.get_node_or_null("RoofOcclusionRoot") as Node2D
	if roof_root == null:
		errors.append("RoofOcclusionRoot missing")
		return
	for roof_name in ROOF_NAMES:
		var roof := roof_root.get_node_or_null(roof_name) as Sprite2D
		var zone := roof_root.get_node_or_null(
			"%sOccluder" % roof_name
		) as Area2D
		if roof == null:
			errors.append("RoofOcclusionRoot/%s missing" % roof_name)
			continue
		if zone == null:
			errors.append("roof zone for %s missing" % roof_name)
			continue

		var bystander := Node2D.new()
		bystander.name = "Bystander"
		zone.body_entered.emit(bystander)
		await create_timer(0.22).timeout
		if roof.modulate.a < 0.95:
			errors.append("%s faded for a non-player body" % roof_name)
		bystander.free()

		actor.global_position = zone.global_position
		for unused in 8:
			await physics_frame
			if roof.modulate.a < 0.30:
				break
		await create_timer(0.20).timeout
		if roof.modulate.a >= 0.30:
			errors.append("%s did not fade below alpha 0.30" % roof_name)
		actor.global_position = Vector2(-600.0, 900.0)
		await physics_frame
		await create_timer(0.30).timeout
		if roof.modulate.a <= 0.95:
			errors.append("%s did not restore above alpha 0.95" % roof_name)


func _check_labyrinth_depth(
	scene: Node2D,
	errors: Array[String]
) -> void:
	for node_path in [
		"OcclusionRoot/LabyrinthContactFog",
		"OcclusionRoot/LabyrinthMoonRimLight",
		"OcclusionRoot/LabyrinthGateLight",
	]:
		if scene.get_node_or_null(node_path) == null:
			errors.append("%s missing" % node_path)


func _check_final_fog(
	scene: Node2D,
	errors: Array[String]
) -> void:
	var fog_rect := scene.call(
		"get_final_fog_coverage_rect"
	) as Rect2
	var level_exit := scene.get_node_or_null(
		"EventRuntimeRoot/Exits/Exit_Continue"
	) as Area2D
	if level_exit == null:
		errors.append("authored Exit_Continue missing for final fog validation")
		return
	var exit_position := level_exit.global_position
	var final_view := Rect2(
		exit_position - Vector2(960.0, 540.0),
		Vector2(1920.0, 1080.0)
	).grow_individual(
		256.0,
		192.0,
		256.0,
		192.0
	)
	if not fog_rect.encloses(final_view):
		errors.append(
			"final fog %s does not enclose overscanned final view %s"
			% [fog_rect, final_view]
		)


func _expect_vec2(
	actual: Vector2,
	expected: Vector2,
	label: String,
	errors: Array[String],
	epsilon := 0.02
) -> void:
	if (
		absf(actual.x - expected.x) > epsilon
		or absf(actual.y - expected.y) > epsilon
	):
		errors.append("%s expected %s, got %s" % [label, expected, actual])


func _fail(message: String) -> void:
	push_error("[SunderedKeepVistaPolishSmoke] %s" % message)
	quit(1)
