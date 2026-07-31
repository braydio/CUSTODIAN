extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)

const PARALLAX_PATHS := [
	"VistaRoot/FirstVistaMistParallax",
	"GrandVistaRoot/GrandVistaCinematicRoot/LabyrinthFarParallax",
	"GrandVistaRoot/GrandVistaCinematicRoot/LabyrinthMistParallax",
	"GrandVistaRoot/GrandVistaCinematicRoot/LabyrinthNearRoot",
	"GrandVistaRoot/FortressVistaRoot/FortressFarParallax",
	"GrandVistaRoot/FortressVistaRoot/FortressMidParallax",
	"GrandVistaRoot/FortressVistaRoot/FortressNearParallax",
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
	var presentation_framing := false

	func set_follow_target(target: Node2D) -> void:
		follow_target = target

	func set_presentation_framing(
		active: bool,
		target_offset := Vector2.ZERO,
		target_zoom := Vector2.ONE
	) -> void:
		presentation_framing = active
		framing_offset = target_offset
		framing_zoom = target_zoom

	func set_runtime_map(map: Node) -> void:
		runtime_map = map

	func clear_presentation_framing(
		_restore_operator_follow := true
	) -> void:
		presentation_framing = false

	func has_presentation_framing() -> bool:
		return presentation_framing


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
	var second_trigger := scene.get_node_or_null(
		"SequenceTriggers/SecondVistaRevealTrigger"
	) as Area2D
	if second_trigger != null:
		# Camera 1 samples teleport across the authored route. Keep the
		# independently tested Camera 2 trigger from observing those teleports.
		second_trigger.set_deferred("monitoring", false)
		await physics_frame
	if controller == null:
		errors.append("VistaController missing")
	if director == null:
		errors.append("RevealDirector missing")
	if vista_root == null:
		errors.append("VistaRoot missing")

	if director != null:
		director.anticipation_duration = 0.01
		director.reveal_in_duration = 0.04
		director.atmosphere_settle_duration = 0.01

	var completion_count := [0]
	if director != null:
		director.reveal_completed.connect(
			func() -> void:
				completion_count[0] += 1
		)

	await _check_first_camera_envelope(
		scene,
		actor,
		camera,
		controller,
		vista_root,
		errors
	)
	if director != null and director.has_played() \
			and not director.is_reveal_complete():
		await director.reveal_completed
	if int(completion_count[0]) != 1:
		errors.append("first reveal accent did not remain one-shot")

	_check_fortress_composition(scene, errors)
	await _check_second_reveal(
		scene,
		actor,
		camera,
		controller,
		director,
		errors
	)
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


func _check_first_camera_envelope(
	scene: Node2D,
	actor: Node2D,
	camera: PresentationCamera,
	controller: SunderedKeepVistaController,
	vista_root: CanvasItem,
	errors: Array[String]
) -> void:
	if controller == null:
		return
	if scene.get_node_or_null(
		"SequenceTriggers/FirstVistaRevealTrigger"
	) != null:
		errors.append("Camera 1 still builds FirstVistaRevealTrigger")
	if scene.get_node_or_null(
		"SequenceTriggers/ReturnToGameplayTrigger"
	) != null:
		errors.append("Camera 1 still builds ReturnToGameplayTrigger")

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
	var cinematic_anchor := scene.get_node_or_null(
		"Markers/FirstRevealCameraAnchor"
	) as Marker2D
	var presentation_anchor := controller.get_node_or_null(
		"CameraPresentationAnchor"
	) as Marker2D
	var base_horizon := scene.get_node_or_null(
		"UnderlayRoot/FirstVistaBaseStormHorizon"
	) as Sprite2D
	var ocean_underlay := scene.get_node_or_null(
		"UnderlayRoot/ApproachOceanVoidUnderlay"
	) as Sprite2D
	var keep := scene.get_node_or_null(
		"ParallaxRoot/RevealDepth/DistantKeep_Parallax2D/"
		+ "DistantSunderedKeepLandmark"
	) as Sprite2D
	var reveal_fog := scene.get_node_or_null(
		"VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil"
	) as Sprite2D
	var reveal_light := scene.get_node_or_null(
		"OcclusionRoot/RevealMoonlightCue"
	) as PointLight2D
	var final_gate_veil := scene.get_node_or_null(
		"OcclusionRoot/ApproachFinalGateShadowVeil"
	) as CanvasItem
	if (
		control_start == null
		or control_apex == null
		or return_start == null
		or return_complete == null
		or cinematic_anchor == null
		or presentation_anchor == null
	):
		errors.append("Camera 1 envelope markers/anchor are incomplete")
		return
	if base_horizon == null or not base_horizon.texture.resource_path.ends_with(
		"first_vista_base_storm_horizon.png"
	):
		errors.append("persistent base storm horizon is missing")
	if ocean_underlay == null:
		errors.append("persistent ocean underlay is missing")
	if keep == null or not keep.texture.resource_path.ends_with(
		"distant_sundered_keep_landmark_v2.png"
	):
		errors.append("isolated distant Keep landmark is missing")
	if reveal_fog == null or not reveal_fog.texture.resource_path.ends_with(
		"first_vista_reveal_veil.png"
	):
		errors.append("controlled first-vista reveal veil is missing")
	if reveal_light == null:
		errors.append("first-vista moonlight cue is missing")

	var enter_axis := (
		control_apex.global_position
		- control_start.global_position
	)
	var return_axis := (
		return_complete.global_position
		- return_start.global_position
	)
	var before := control_start.global_position - enter_axis * 0.25
	var enter_mid := control_start.global_position.lerp(
		control_apex.global_position,
		0.5
	)
	var plateau := control_apex.global_position.lerp(
		return_start.global_position,
		0.5
	)
	var return_mid := return_start.global_position.lerp(
		return_complete.global_position,
		0.5
	)
	var after := return_complete.global_position + return_axis * 0.25
	var samples := [
		{
			"position": before,
			"phase": "GAMEPLAY_BEFORE",
			"enter": 0.0,
			"return": 0.0,
			"camera": 0.0,
			"keep_alpha": 0.08,
			"fog_alpha": 0.68,
			"fog_offset": Vector2.ZERO,
			"light_energy": 0.0,
		},
		{
			"position": enter_mid,
			"phase": "BLEND_TO_CINEMATIC",
			"enter": 0.5,
			"return": 0.0,
			"camera": 0.5,
			"keep_alpha": 0.57,
			"fog_alpha": 0.44,
			"fog_offset": Vector2(-61.05, 27.75),
			"light_energy": 0.10,
		},
		{
			"position": plateau,
			"phase": "CINEMATIC_APEX",
			"enter": 1.0,
			"return": 0.0,
			"camera": 1.0,
			"keep_alpha": 0.92,
			"fog_alpha": 0.24,
			"fog_offset": Vector2(-110.0, 50.0),
			"light_energy": 0.20,
		},
		{
			"position": return_mid,
			"phase": "BLEND_TO_GAMEPLAY",
			"enter": 1.0,
			"return": 0.5,
			"camera": 0.5,
			"keep_alpha": 0.87,
			"fog_alpha": 0.28,
			"fog_offset": Vector2(-100.0, 46.0),
			"light_energy": 0.15,
		},
		{
			"position": after,
			"phase": "GAMEPLAY_AFTER",
			"enter": 1.0,
			"return": 1.0,
			"camera": 0.0,
			"keep_alpha": 0.82,
			"fog_alpha": 0.32,
			"fog_offset": Vector2(-90.0, 42.0),
			"light_energy": 0.10,
		},
	]
	var fog_origin := (
		reveal_fog.get_meta(
			"first_vista_fog_origin",
			reveal_fog.position
		) as Vector2
		if reveal_fog != null
		else Vector2.ZERO
	)

	for sample: Dictionary in samples:
		await _assert_first_camera_sample(
			actor,
			camera,
			controller,
			vista_root,
			cinematic_anchor,
			presentation_anchor,
			base_horizon,
			ocean_underlay,
			keep,
			reveal_fog,
			fog_origin,
			reveal_light,
			final_gate_veil,
			sample,
			"forward",
			errors
		)
	var reverse_samples := samples.duplicate()
	reverse_samples.reverse()
	for sample: Dictionary in reverse_samples:
		await _assert_first_camera_sample(
			actor,
			camera,
			controller,
			vista_root,
			cinematic_anchor,
			presentation_anchor,
			base_horizon,
			ocean_underlay,
			keep,
			reveal_fog,
			fog_origin,
			reveal_light,
			final_gate_veil,
			sample,
			"backward",
			errors
		)

	for blend_data in [
		{
			"start": control_start.global_position,
			"end": control_apex.global_position,
			"key": "first_enter_weight",
		},
		{
			"start": return_start.global_position,
			"end": return_complete.global_position,
			"key": "first_return_weight",
		},
	]:
		var first_weight := -1.0
		for ratio in [0.25, 0.75, 0.25]:
			actor.global_position = (
				blend_data["start"] as Vector2
			).lerp(
				blend_data["end"] as Vector2,
				ratio
			)
			await physics_frame
			var state := controller.get_reveal_choreography_state()
			var weight := float(state.get(blend_data["key"], -1.0))
			if ratio == 0.25 and first_weight < 0.0:
				first_weight = weight
			elif ratio == 0.25 and absf(weight - first_weight) > 0.001:
				errors.append(
					"Camera 1 blend is history-dependent after reversal"
				)

	actor.global_position = plateau
	controller.refresh_bindings()
	var spawn_plateau := controller.get_reveal_choreography_state()
	if spawn_plateau.get("first_camera_phase", "") != "CINEMATIC_APEX":
		errors.append("Spawning in the Camera 1 plateau evaluated incorrectly")

	actor.global_position = after
	controller.refresh_bindings()
	var spawn_after := controller.get_reveal_choreography_state()
	if spawn_after.get("first_camera_phase", "") != "GAMEPLAY_AFTER":
		errors.append("Spawning after Camera 1 evaluated incorrectly")

	actor.global_position = before
	controller.apply_progress(0.0)
	var teleported := controller.get_reveal_choreography_state()
	if teleported.get("first_camera_phase", "") != "GAMEPLAY_BEFORE":
		errors.append("Teleporting backward did not immediately reset Camera 1")
	if presentation_anchor.global_position.distance_to(
		actor.global_position
	) > 0.01:
		errors.append("CameraPresentationAnchor did not track teleport immediately")


func _assert_first_camera_sample(
	actor: Node2D,
	camera: PresentationCamera,
	controller: SunderedKeepVistaController,
	vista_root: CanvasItem,
	cinematic_anchor: Marker2D,
	presentation_anchor: Marker2D,
	base_horizon: Sprite2D,
	ocean_underlay: Sprite2D,
	keep: Sprite2D,
	reveal_fog: Sprite2D,
	fog_origin: Vector2,
	reveal_light: PointLight2D,
	final_gate_veil: CanvasItem,
	sample: Dictionary,
	direction_label: String,
	errors: Array[String]
) -> void:
	actor.global_position = sample["position"] as Vector2
	await physics_frame
	var state := controller.get_reveal_choreography_state()
	var context := "%s %s" % [
		direction_label,
		String(sample["phase"]),
	]
	if state.get("first_camera_phase", "") != sample["phase"]:
		errors.append(
			"%s phase expected %s, got %s"
			% [
				context,
				sample["phase"],
				state.get("first_camera_phase", ""),
			]
		)
	var enter_weight := float(state.get("first_enter_weight", -1.0))
	var return_weight := float(state.get("first_return_weight", -1.0))
	var camera_weight := float(state.get("first_camera_weight", -1.0))
	if absf(enter_weight - float(sample["enter"])) > 0.03:
		errors.append("%s enter weight %.3f" % [context, enter_weight])
	if absf(return_weight - float(sample["return"])) > 0.03:
		errors.append("%s return weight %.3f" % [context, return_weight])
	if absf(camera_weight - float(sample["camera"])) > 0.03:
		errors.append("%s camera weight %.3f" % [context, camera_weight])
	var expected_anchor := actor.global_position.lerp(
		cinematic_anchor.global_position,
		camera_weight
	)
	if presentation_anchor.global_position.distance_to(expected_anchor) > 0.05:
		errors.append("%s presentation anchor mismatch" % context)
	var expected_follow: Node2D = (
		actor
		if camera_weight <= 0.001
		else presentation_anchor
	)
	if camera.follow_target != expected_follow:
		errors.append("%s camera follow authority mismatch" % context)
	if camera_weight <= 0.001 and camera.presentation_framing:
		errors.append("%s retained presentation framing" % context)
	if vista_root != null and vista_root.modulate.a < 0.99:
		errors.append("%s VistaRoot should remain continuously visible" % context)
	if base_horizon != null and base_horizon.modulate.a < 0.99:
		errors.append("%s base storm horizon crossfaded" % context)
	if ocean_underlay != null and ocean_underlay.modulate.a < 0.99:
		errors.append("%s ocean underlay crossfaded" % context)
	if keep != null and absf(
		keep.modulate.a - float(sample["keep_alpha"])
	) > 0.04:
		errors.append("%s Keep alpha %.3f" % [context, keep.modulate.a])
	if reveal_fog != null:
		if absf(
			reveal_fog.modulate.a - float(sample["fog_alpha"])
		) > 0.04:
			errors.append(
				"%s reveal fog alpha %.3f"
				% [context, reveal_fog.modulate.a]
			)
		var expected_fog_position := (
			fog_origin
			+ sample["fog_offset"] as Vector2
		)
		if reveal_fog.position.distance_to(expected_fog_position) > 1.0:
			errors.append("%s reveal fog peel position mismatch" % context)
	if reveal_light != null and absf(
		reveal_light.energy - float(sample["light_energy"])
	) > 0.03:
		errors.append(
			"%s reveal light energy %.3f"
			% [context, reveal_light.energy]
		)
	if final_gate_veil != null and final_gate_veil.modulate.a > 0.01:
		errors.append("%s activated the final-gate veil" % context)


func _check_fortress_composition(
	scene: Node2D,
	errors: Array[String]
) -> void:
	var cinematic_root := scene.get_node_or_null(
		"GrandVistaRoot/GrandVistaCinematicRoot"
	) as CanvasItem
	var fortress_root := scene.get_node_or_null(
		"GrandVistaRoot/FortressVistaRoot"
	) as CanvasItem
	if cinematic_root == null:
		errors.append("GrandVistaCinematicRoot missing")
	if fortress_root == null:
		errors.append("FortressVistaRoot missing")
		return
	if fortress_root.modulate.a < 0.99:
		errors.append("FortressVistaRoot container must remain visible")
	if not fortress_root.scale.is_equal_approx(Vector2(0.82, 0.82)):
		errors.append("FortressVistaRoot must use the 0.82 hierarchy scale")

	var expected_counts := {
		"FortressFarParallax": 4,
		"FortressMidParallax": 18,
		"FortressNearParallax": 8,
	}
	var grand_root := scene.get_node_or_null("GrandVistaRoot") as Node2D
	var playable_root := scene.get_node_or_null("PlayableRoot") as Node2D
	var component_count := 0
	var visible_component_count := 0
	var visible_precincts := {}
	var visible_route_hints := {}
	for layer_name: String in expected_counts:
		var layer := fortress_root.get_node_or_null(
			layer_name
		) as Node2D
		if layer == null:
			errors.append("%s missing" % layer_name)
			continue
		if layer.modulate.a > 0.01:
			errors.append("%s should start at zero alpha" % layer_name)
		var sprites := layer.find_children(
			"*",
			"Sprite2D",
			false,
			false
		)
		if sprites.size() != int(expected_counts[layer_name]):
			errors.append(
				"%s expected %d sprites, got %d"
				% [
					layer_name,
					int(expected_counts[layer_name]),
					sprites.size(),
				]
			)
		component_count += sprites.size()
		for node: Node in sprites:
			var sprite := node as Sprite2D
			if sprite.visible:
				visible_component_count += 1
				var precinct := str(
					sprite.get_meta("fortress_precinct", "")
				)
				visible_precincts[precinct] = (
					int(visible_precincts.get(precinct, 0)) + 1
				)
				var route_hint := str(
					sprite.get_meta("labyrinth_route_hint", "")
				)
				if not route_hint.is_empty():
					visible_route_hints[route_hint] = (
						int(visible_route_hints.get(route_hint, 0)) + 1
					)
				if str(sprite.get_meta("fortress_component", "")).begins_with(
					"battlement_crown"
				):
					errors.append(
						"%s leaves an unattached crown visible" % sprite.name
					)
			if sprite.texture == null:
				errors.append("%s has no texture" % sprite.name)
			if (
				sprite.texture_filter
				!= CanvasItem.TEXTURE_FILTER_LINEAR
			):
				errors.append("%s is not linearly filtered" % sprite.name)
			if not bool(sprite.get_meta("presentation_only", false)):
				errors.append("%s lacks presentation-only metadata" % sprite.name)
			if (
				grand_root != null
				and playable_root != null
				and (
					grand_root.z_index
					+ fortress_root.z_index
					+ layer.z_index
					+ sprite.z_index
				) >= playable_root.z_index
			):
				errors.append("%s does not remain below PlayableRoot" % sprite.name)

	if component_count != 30:
		errors.append("fortress component total expected 30, got %d" % component_count)
	if visible_component_count < 14 or visible_component_count > 18:
		errors.append(
			"primary composition should expose 14–18 parts, got %d"
			% visible_component_count
		)
	for precinct in [
		"western_collapsed_ward",
		"central_citadel",
		"eastern_gate_ward",
		"remote_inner_keep",
	]:
		if int(visible_precincts.get(precinct, 0)) <= 0:
			errors.append("fortress precinct is unreadable: %s" % precinct)
	for route_hint in ["upper", "middle", "lower"]:
		if int(visible_route_hints.get(route_hint, 0)) <= 0:
			errors.append("labyrinth route hint is missing: %s" % route_hint)
	var foreground_parapet := scene.get_node_or_null(
		"GrandVistaRoot/GrandVistaCinematicRoot/"
		+ "LabyrinthNearRoot/GrandVistaForegroundParapet"
	) as CanvasItem
	if (
		foreground_parapet == null
		or foreground_parapet.modulate.a > 0.01
		or not bool(
			foreground_parapet.get_meta(
				"disabled_for_cinematic_focal_axis",
				false
			)
		)
	):
		errors.append("central foreground chest/parapet focal mass remains active")
	if _contains_gameplay_authority(fortress_root):
		errors.append("FortressVistaRoot contains gameplay authority")


func _check_second_reveal(
	scene: Node2D,
	actor: CharacterBody2D,
	camera: PresentationCamera,
	controller: SunderedKeepVistaController,
	director: SunderedKeepRevealDirector,
	errors: Array[String]
) -> void:
	if controller == null or director == null:
		return
	director.second_reveal_anticipation_duration = 0.12
	director.second_reveal_in_duration = 0.04
	director.second_reveal_hold_duration = 0.08
	director.second_return_duration = 0.04

	var cinematic_root := scene.get_node_or_null(
		"GrandVistaRoot/GrandVistaCinematicRoot"
	) as CanvasItem
	var fortress_root := scene.get_node_or_null(
		"GrandVistaRoot/FortressVistaRoot"
	) as CanvasItem
	var fortress_far := scene.get_node_or_null(
		"GrandVistaRoot/FortressVistaRoot/FortressFarParallax"
	) as CanvasItem
	var fortress_mid := scene.get_node_or_null(
		"GrandVistaRoot/FortressVistaRoot/FortressMidParallax"
	) as CanvasItem
	var fortress_near := scene.get_node_or_null(
		"GrandVistaRoot/FortressVistaRoot/FortressNearParallax"
	) as CanvasItem
	var keep := scene.get_node_or_null(
		"ParallaxRoot/RevealDepth/DistantKeep_Parallax2D/"
		+ "DistantSunderedKeepLandmark"
	) as CanvasItem
	var second_trigger := scene.get_node_or_null(
		"SequenceTriggers/SecondVistaRevealTrigger"
	) as Area2D
	if second_trigger == null:
		errors.append("SecondVistaRevealTrigger missing")
		return
	second_trigger.set_deferred("monitoring", true)
	await physics_frame

	actor.global_position = second_trigger.global_position
	for unused in 8:
		await physics_frame
		if bool(
			director.get_reveal_state().get(
				"second_played",
				false
			)
		):
			break
	var presentation_anchor := controller.get_node_or_null(
		"CameraPresentationAnchor"
	) as Marker2D
	if presentation_anchor == null:
		errors.append("second reveal presentation anchor missing")
	elif presentation_anchor.global_position.distance_to(
		actor.global_position
	) > 1.0:
		errors.append("second reveal anchor teleported before its blend")
	if camera.follow_target != actor:
		errors.append("camera left Operator before second blend began")
	if (
		fortress_far == null
		or fortress_mid == null
		or fortress_near == null
	):
		errors.append("fortress reveal layers missing")
	elif (
		fortress_far.modulate.a > 0.01
		or fortress_mid.modulate.a > 0.01
		or fortress_near.modulate.a > 0.01
	):
		errors.append("fortress became visible during anticipation")

	var second_full := scene.get_node_or_null(
		"Markers/SecondVistaFull"
	) as Marker2D
	var second_end := scene.get_node_or_null(
		"Markers/SecondVistaEnd"
	) as Marker2D
	if second_full == null or second_end == null:
		errors.append("second progress markers missing")
		return
	actor.global_position = second_full.global_position
	for unused in 30:
		await physics_frame
		if bool(
			director.get_reveal_state().get(
				"second_ready_for_return",
				false
			)
		):
			break
	if not bool(
		director.get_reveal_state().get(
			"second_ready_for_return",
			false
		)
	):
		errors.append("second reveal did not enter progress control")
		return
	if cinematic_root == null or cinematic_root.modulate.a < 0.99:
		errors.append("second reveal did not expose cinematic layers")
	if fortress_root == null or fortress_root.modulate.a < 0.99:
		errors.append("fortress container was unexpectedly faded")
	if (
		fortress_far == null
		or absf(fortress_far.modulate.a - 0.66) > 0.03
	):
		errors.append("second reveal did not expose the far fortress")
	if (
		fortress_mid == null
		or absf(fortress_mid.modulate.a - 0.96) > 0.03
	):
		errors.append("second reveal did not expose the mid fortress")
	if (
		fortress_near == null
		or absf(fortress_near.modulate.a - 0.68) > 0.03
	):
		errors.append("second reveal did not stage the near fortress")
	if keep != null and keep.modulate.a > 0.05:
		errors.append("distant Keep proxy did not crossfade out")
	if camera.follow_target == actor:
		errors.append("second reveal camera did not use presentation anchor")
	_expect_vec2(
		camera.framing_zoom,
		Vector2(0.78, 0.78),
		"second reveal zoom",
		errors
	)

	actor.global_position = second_full.global_position.lerp(
		second_end.global_position,
		0.5
	)
	await process_frame
	await process_frame
	var state := controller.get_reveal_choreography_state()
	var progress := float(state.get("second_progress_weight", -1.0))
	if progress < 0.45 or progress > 0.55:
		errors.append(
			"second camera progress did not follow Operator position: %.3f"
			% progress
		)
	if cinematic_root != null and cinematic_root.modulate.a >= 0.99:
		errors.append("cinematic layers did not fade during second progress")
	if fortress_far != null and absf(fortress_far.modulate.a - 0.62) > 0.03:
		errors.append("far fortress did not recede with second progress")
	if fortress_mid != null and absf(fortress_mid.modulate.a - 0.73) > 0.04:
		errors.append("mid fortress did not recede with second progress")
	if fortress_near != null and absf(fortress_near.modulate.a - 0.17) > 0.05:
		errors.append("near fortress did not recede with second progress")

	var return_trigger := scene.get_node_or_null(
		"SequenceTriggers/SecondReturnToGameplayTrigger"
	) as Area2D
	if return_trigger == null:
		errors.append("SecondReturnToGameplayTrigger missing")
		return
	actor.global_position = return_trigger.global_position
	for unused in 20:
		await physics_frame
		if bool(
			director.get_reveal_state().get(
				"second_complete",
				false
			)
		):
			break
	if not bool(
		director.get_reveal_state().get(
			"second_complete",
			false
		)
	):
		await director.second_reveal_completed
	if camera.follow_target != actor:
		errors.append(
			"second handback did not restore Operator follow"
		)
	elif presentation_anchor.global_position.distance_to(
		actor.global_position
	) > 1.0:
		errors.append("presentation anchor did not return to Operator position")
	if cinematic_root == null or cinematic_root.modulate.a > 0.01:
		errors.append("cinematic layers remained visible after handback")
	if fortress_far == null or absf(fortress_far.modulate.a - 0.58) > 0.03:
		errors.append("far fortress did not settle at distant alpha")
	if fortress_mid == null or absf(fortress_mid.modulate.a - 0.42) > 0.03:
		errors.append("mid fortress did not settle at distant alpha")
	if fortress_near == null or absf(fortress_near.modulate.a - 0.10) > 0.03:
		errors.append("near fortress did not settle at distant alpha")
	actor.global_position = second_full.global_position
	await physics_frame
	var reverse_apex := controller.get_reveal_choreography_state()
	if reverse_apex.get("second_camera_phase", "") != "SECOND_CINEMATIC_APEX":
		errors.append("Camera 2 did not restore its apex during reverse travel")
	if float(reverse_apex.get("second_camera_weight", 0.0)) < 0.99:
		errors.append("Camera 2 reverse apex weight was not position-derived")
	actor.global_position = second_trigger.global_position
	await physics_frame
	var reverse_before := controller.get_reveal_choreography_state()
	if reverse_before.get("second_camera_phase", "") != "SECOND_GAMEPLAY_BEFORE":
		errors.append("Camera 2 did not reverse fully to gameplay")
	controller.apply_progress(1.0)
	if (
		fortress_far != null
		and fortress_far.modulate.a > 0.01
	):
		errors.append("final-gate progress did not fade fortress completely")
	actor.global_position = Vector2(-600.0, 900.0)
	await physics_frame
	await create_timer(0.30).timeout


func _contains_gameplay_authority(node: Node) -> bool:
	if (
		node is CollisionObject2D
		or node is CollisionShape2D
		or node is NavigationRegion2D
		or node is NavigationLink2D
		or node is Marker2D
		or node is Camera2D
	):
		return true
	for child: Node in node.get_children():
		if _contains_gameplay_authority(child):
			return true
	return false


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

	var labyrinth_far := layers[1]
	var labyrinth_mist := layers[2]
	var labyrinth_near := layers[3]
	var fortress_far := layers[4]
	var fortress_mid := layers[5]
	var fortress_near := layers[6]
	if labyrinth_far.get("follow_ratio").x <= labyrinth_mist.get("follow_ratio").x:
		errors.append("Labyrinth far parallax ratio must exceed mist ratio")
	if labyrinth_mist.get("follow_ratio").x <= labyrinth_near.get("follow_ratio").x:
		errors.append("Labyrinth mist parallax ratio must exceed near ratio")
	if fortress_far.get("follow_ratio").x <= fortress_mid.get("follow_ratio").x:
		errors.append("fortress far ratio must exceed mid ratio")
	if fortress_mid.get("follow_ratio").x <= fortress_near.get("follow_ratio").x:
		errors.append("fortress mid ratio must exceed near ratio")

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
