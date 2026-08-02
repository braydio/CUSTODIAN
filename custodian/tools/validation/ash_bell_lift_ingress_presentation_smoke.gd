extends SceneTree

const PRESENTATION := preload(
	"res://game/world/approaches/ash_bell/"
	+ "ash_bell_lift_ingress_presentation.tscn"
)
const SPAWNER_SCRIPT := preload(
	"res://game/world/levels/world_ingress_spawner.gd"
)
const ASSET_ROOT := "res://assets/sprites/world/ingress/ash_bell/"

class MockIngressDefinition extends RefCounted:
	var ingress_id: StringName = &"ash_bell_empty_lift"
	var route_profile: StringName = &"default"
	var prompt_text := "DESCEND"
	var target_spawn_id: StringName = &"Spawn_DescentLanding"
	var interaction_distance := 92.0

class MockRouteDefinition extends RefCounted:
	var route_id: StringName = &"forlorn_ritualant_underground"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	_validate_assets(errors)
	var presentation := PRESENTATION.instantiate() as AshBellLiftIngressPresentation
	_check(presentation != null, "presentation did not instantiate", errors)
	if presentation != null:
		root.add_child(presentation)
		await process_frame
		_validate_scene(presentation, errors)
		await _validate_lift_travel(presentation, errors)
		presentation.queue_free()
	_validate_specialized_spawner(errors)
	_validate_snapshot_hook_order(errors)
	await process_frame
	if errors.is_empty():
		print("[AshBellLiftIngressPresentationSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[AshBellLiftIngressPresentationSmoke] %s" % error)
	quit(1)


func _validate_assets(errors: Array[String]) -> void:
	var expected := {
		"ash_bell__underground_ingress__lift_platform__idle__s__1f__128x128.png": Vector2i(128, 128),
		"ash_bell__underground_ingress__lift_platform__vibrate__s__4f__128x128.png": Vector2i(256, 256),
		"ash_bell__underground_ingress__shaft_scroll_tile__idle__s__1f__256x512.png": Vector2i(256, 512),
		"ash_bell__underground_ingress__foreground_occluder__idle__s__1f__256x256.png": Vector2i(256, 256),
		"ash_bell__underground_ingress__lift_chain__idle__s__1f__64x256.png": Vector2i(64, 256),
		"ash_bell__underground_ingress_fx__descent_dust__burst__omni__6f__192x192.png": Vector2i(576, 384),
		"ash_bell__underground_ingress__entrance_shell__idle__s__1f__256x256.png": Vector2i(256, 256),
	}
	for file_name: String in expected:
		var texture := load(ASSET_ROOT + file_name) as Texture2D
		_check(texture != null, "missing runtime asset %s" % file_name, errors)
		if texture != null:
			_check(
				Vector2i(texture.get_width(), texture.get_height()) == expected[file_name],
				"wrong dimensions for %s" % file_name,
				errors
			)
		var import_text := _read_text(ASSET_ROOT + file_name + ".import")
		_check("compress/mode=0" in import_text, "%s is not lossless" % file_name, errors)
		_check("mipmaps/generate=false" in import_text, "%s has mipmaps" % file_name, errors)


func _validate_scene(
	presentation: AshBellLiftIngressPresentation,
	errors: Array[String]
) -> void:
	var vibrate := presentation.get_node("LiftRoot/PlatformVibrate") as AnimatedSprite2D
	var dust := presentation.get_node("DustBurst") as AnimatedSprite2D
	var lamp := presentation.get_node("Lamp") as AnimatedSprite2D
	_check(vibrate.sprite_frames.get_frame_count(&"vibrate") == 4, "vibrate frame count drifted", errors)
	_check(is_equal_approx(vibrate.sprite_frames.get_animation_speed(&"vibrate"), 10.0), "vibrate FPS drifted", errors)
	_check(vibrate.sprite_frames.get_animation_loop(&"vibrate"), "vibrate must loop", errors)
	_check(dust.sprite_frames.get_frame_count(&"burst") == 6, "dust frame count drifted", errors)
	_check(is_equal_approx(dust.sprite_frames.get_animation_speed(&"burst"), 12.0), "dust FPS drifted", errors)
	_check(not dust.sprite_frames.get_animation_loop(&"burst"), "dust must not loop", errors)
	_check(lamp.sprite_frames.get_frame_count(&"flicker") == 8, "lamp frame count drifted", errors)
	_check((presentation.get_node("ChainLeft") as Node2D).position == Vector2(-42, -126), "left chain placement drifted", errors)
	_check((presentation.get_node("ChainRight") as Node2D).position == Vector2(42, -126), "right chain placement drifted", errors)
	_check((presentation.get_node("ForegroundOccluder") as CanvasItem).z_index == 20, "foreground occluder must sit between lift and rider", errors)
	_check((presentation.get_node("Lamp") as CanvasItem).z_index == 110, "lamp Z drifted", errors)


func _validate_lift_travel(
	presentation: AshBellLiftIngressPresentation,
	errors: Array[String]
) -> void:
	var actor := Node2D.new()
	actor.name = "Operator"
	root.add_child(actor)
	actor.z_index = 7
	actor.z_as_relative = true
	actor.process_mode = Node.PROCESS_MODE_ALWAYS
	presentation.descent_duration = 0.05
	var lift_start := presentation.lift_root.position
	await presentation.play_descent(actor)
	_check(
		is_equal_approx(presentation.lift_root.position.y, lift_start.y + 176.0),
		"lift did not descend 176 px",
		errors
	)
	_check(actor.process_mode == Node.PROCESS_MODE_ALWAYS, "actor process mode was not restored", errors)
	_check(actor.z_index == 7 and actor.z_as_relative, "actor Z state was not restored", errors)
	var restored_position := Vector2(311.0, 277.0)
	actor.position = restored_position
	await presentation.play_ascent(actor)
	_check(presentation.lift_root.position == lift_start, "lift did not ascend to parked position", errors)
	_check(actor.position == restored_position, "ascent moved restored actor back into shaft", errors)
	_check(actor.z_index == 7 and actor.z_as_relative, "ascent changed actor render context", errors)
	_check(actor.process_mode == Node.PROCESS_MODE_ALWAYS, "ascent did not restore actor process mode", errors)
	presentation.reset_presentation()
	_check(presentation.lift_root.position == lift_start, "presentation did not reset lift", errors)
	_check(presentation.platform_idle.visible, "idle platform not restored", errors)
	_check(not presentation.platform_vibrate.visible, "vibration remained visible", errors)
	actor.queue_free()


func _validate_specialized_spawner(errors: Array[String]) -> void:
	var spawner := SPAWNER_SCRIPT.new()
	root.add_child(spawner)
	var record := {
		"mode": "route",
		"identity": "forlorn_ritualant_underground",
		"definition": MockRouteDefinition.new(),
		"ingress": MockIngressDefinition.new(),
	}
	var ingress := spawner.call("_create_ingress", record, Node.new()) as Area2D
	_check(ingress is AshBellLiftIngressSite, "spawner did not select Ash Bell lift ingress", errors)
	if ingress != null:
		root.add_child(ingress)
		_check(
			ingress.get_node_or_null("AshBellLiftIngressPresentation") != null,
			"specialized ingress did not attach presentation",
			errors
		)
		ingress.queue_free()
	spawner.queue_free()


func _validate_snapshot_hook_order(errors: Array[String]) -> void:
	var source := _read_text("res://game/world/procgen/ingress/world_ingress_site.gd")
	var capture_index := source.find("_entry_snapshot = capture_world_origin(actor)")
	var presentation_index := source.find("await call(\"_play_entry_presentation\", actor)")
	var route_index := source.find("start_route")
	_check(
		capture_index >= 0 and presentation_index > capture_index and route_index > presentation_index,
		"snapshot/presentation/route ordering drifted",
		errors
	)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)
