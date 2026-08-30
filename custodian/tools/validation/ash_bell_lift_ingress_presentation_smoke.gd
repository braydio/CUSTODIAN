extends SceneTree

const PRESENTATION := preload(
	"res://game/world/approaches/ash_bell/"
	+ "ash_bell_lift_ingress_presentation.tscn"
)
const OPERATOR_PRESENTATION_RIG := preload(
	"res://game/actors/operator/presentation/operator_presentation_rig_2d.tscn"
)
const SPAWNER_SCRIPT := preload(
	"res://game/world/levels/world_ingress_spawner.gd"
)
const ASSET_ROOT := "res://assets/sprites/world/ingress/ash_bell/"
const THREADWAY_ASSET_ROOT := "res://content/sprites/world/ingress/ash_bell/"
const THREADWAY_TILE_ROOT := THREADWAY_ASSET_ROOT + "source/generated/"
const ROUTE_PATH := (
	"res://content/routes/ash_bell/forlorn_ritualant_underground_route.json"
)

class MockIngressDefinition extends RefCounted:
	var ingress_id: StringName = &"ash_bell_empty_lift"
	var route_profile: StringName = &"default"
	var prompt_text := "DESCEND"
	var target_spawn_id: StringName = &"Spawn_DescentLanding"
	var interaction_distance := 56.0
	var site_scene_path := ""

class MockRouteDefinition extends RefCounted:
	var route_id: StringName = &"forlorn_ritualant_underground"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	_validate_assets(errors)
	_validate_prompt(errors)
	_validate_puppet_scene(errors)
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
		"ash_bell__underground_ingress__lift_platform_back__idle__s__1f__128x128.png": Vector2i(128, 128),
		"ash_bell__underground_ingress__lift_platform_back__vibrate__s__4f__128x128.png": Vector2i(256, 256),
		"ash_bell__underground_ingress__lift_platform_front_lip__idle__s__1f__128x128.png": Vector2i(128, 128),
		"ash_bell__underground_ingress__lift_platform_front_lip__vibrate__s__4f__128x128.png": Vector2i(256, 256),
		"ash_bell__underground_ingress__shaft_scroll_tile__idle__s__1f__256x512.png": Vector2i(256, 512),
		"ash_bell__underground_ingress__foreground_occluder__idle__s__1f__256x256.png": Vector2i(512, 764),
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
	var resolve_name := "ash_bell_threadway_resolve_01__7f__32.png"
	var resolve_texture := load(THREADWAY_ASSET_ROOT + resolve_name) as Texture2D
	_check(resolve_texture != null, "missing threadway resolve strip", errors)
	if resolve_texture != null:
		_check(
			Vector2i(resolve_texture.get_width(), resolve_texture.get_height()) == Vector2i(224, 32),
			"threadway resolve strip must be 7 x 32x32 frames",
			errors
		)
	_validate_threadway_import(THREADWAY_ASSET_ROOT + resolve_name, errors)
	for tile_index in range(1, 7):
		var tile_name := "ash_bell_threadway_floor_tiles_6t_32px_%d.png" % tile_index
		var tile_texture := load(THREADWAY_TILE_ROOT + tile_name) as Texture2D
		_check(tile_texture != null, "missing threadway floor tile %d" % tile_index, errors)
		if tile_texture != null:
			_check(
				Vector2i(tile_texture.get_width(), tile_texture.get_height()) == Vector2i(32, 32),
				"threadway floor tile %d is not 32x32" % tile_index,
				errors
			)
		_validate_threadway_import(THREADWAY_TILE_ROOT + tile_name, errors)


func _validate_threadway_import(path: String, errors: Array[String]) -> void:
	var import_text := _read_text(path + ".import")
	_check("compress/mode=0" in import_text, "%s is not lossless" % path, errors)
	_check("mipmaps/generate=false" in import_text, "%s has mipmaps" % path, errors)


func _validate_scene(
	presentation: AshBellLiftIngressPresentation,
	errors: Array[String]
) -> void:
	var vibrate := presentation.get_node("LiftRoot/PlatformBackVibrate") as AnimatedSprite2D
	var platform := presentation.get_node("LiftRoot/PlatformBackIdle") as Sprite2D
	var front_idle := presentation.get_node("LiftRoot/PlatformFront/FrontLipIdle") as Sprite2D
	var front_vibrate := presentation.get_node("LiftRoot/PlatformFront/FrontLipVibrate") as AnimatedSprite2D
	var dust := presentation.get_node("DustBurst") as AnimatedSprite2D
	var lamp := presentation.get_node("LampFxRoot/Lamp") as AnimatedSprite2D
	var shaft_window := presentation.get_node("RearMassRoot/ShaftWindow") as Polygon2D
	var entrance_mask := presentation.get_node("ForegroundOccluderRoot") as Node2D
	var travel_geometry := presentation.get_node(
		"ForegroundOccluderRoot/TravelOcclusionGeometry"
	) as Node2D
	var threshold := presentation.get_node("EntranceThresholdMarker") as Marker2D
	var approach := presentation.get_node("InteractionApproachMarker") as Marker2D
	var rider_anchor := presentation.get_node("LiftRoot/RiderAnchor") as Marker2D
	var boarding_marker := presentation.get_node("BoardingMarker") as Marker2D
	_check(vibrate.sprite_frames.get_frame_count(&"vibrate") == 4, "vibrate frame count drifted", errors)
	_check(is_equal_approx(vibrate.sprite_frames.get_animation_speed(&"vibrate"), 10.0), "vibrate FPS drifted", errors)
	_check(vibrate.sprite_frames.get_animation_loop(&"vibrate"), "vibrate must loop", errors)
	_check(front_vibrate.sprite_frames.get_frame_count(&"vibrate") == 4, "front-lip vibrate frame count drifted", errors)
	_check(dust.sprite_frames.get_frame_count(&"burst") == 6, "dust frame count drifted", errors)
	_check(is_equal_approx(dust.sprite_frames.get_animation_speed(&"burst"), 12.0), "dust FPS drifted", errors)
	_check(not dust.sprite_frames.get_animation_loop(&"burst"), "dust must not loop", errors)
	_check(lamp.sprite_frames.get_frame_count(&"flicker") == 8, "lamp frame count drifted", errors)
	_check((presentation.get_node("EntranceStructureRoot/ChainLeft") as Node2D).position == Vector2(-42, -126), "left chain placement drifted", errors)
	_check((presentation.get_node("EntranceStructureRoot/ChainRight") as Node2D).position == Vector2(42, -126), "right chain placement drifted", errors)
	_check(not shaft_window.visible, "shaft interior must be hidden while parked", errors)
	_check(is_zero_approx(shaft_window.modulate.a), "parked shaft retained visible opacity", errors)
	_check(shaft_window.clip_children == CanvasItem.CLIP_CHILDREN_ONLY, "shaft window lost its irregular child mask", errors)
	_check(presentation.get_node_or_null("RearMassRoot/DarkMouth") != null, "idle cave mouth is missing", errors)
	_check(
		presentation.get_node_or_null("ThresholdSurface") == null,
		"flat ThresholdSurface polygon returned",
		errors
	)
	var mouth := presentation.get_node("RearMassRoot/DarkMouth") as Polygon2D
	var mouth_bounds := _polygon_bounds(mouth.polygon)
	_check(mouth_bounds.size.x <= 170.0, "idle shaft aperture exposes broad black side plates", errors)
	for plate_name in ["TopRockOverhang", "LeftMouthRock", "RightMouthRock", "LowerCaveLip"]:
		_check(
			presentation.get_node_or_null(
				"ForegroundOccluderRoot/TravelOcclusionGeometry/" + plate_name
			) is Polygon2D,
			"temporary occlusion plate is missing: %s" % plate_name,
			errors
		)
	_check(not travel_geometry.visible, "solid temporary occlusion geometry is visible while idle", errors)
	_check(entrance_mask.z_index == 1, "parked cave breakup must remain behind Operator z=2", errors)
	_check(not presentation.foreground_occluder.visible, "broad cave mask must be hidden while parked", errors)
	_check(presentation.foreground_occluder.region_enabled, "travel cave lip must use a localized texture region", errors)
	var lip_size := presentation.foreground_occluder.region_rect.size * presentation.foreground_occluder.scale
	_check(lip_size.x <= 180.0 and lip_size.y <= 84.0, "travel cave lip expanded into a whole-mountain foreground plate", errors)
	_check((presentation.get_node("EntranceStructureRoot/EntranceShell") as Sprite2D).visible, "entrance shell is hidden while idle", errors)
	_check(presentation.lift_root.visible, "lift is hidden while idle", errors)
	_check((presentation.get_node("RearMassRoot/MountainCliff") as Sprite2D).visible, "mountain is hidden while idle", errors)
	_check(presentation.lift_root.position == threshold.position, "parked platform is not aligned to its threshold", errors)
	_check(rider_anchor.position == Vector2(0, -26), "rider anchor height drifted", errors)
	_check(boarding_marker.position == Vector2(0, -26), "boarding marker drifted", errors)
	_check(approach.position.y > threshold.position.y, "interaction approach is not outside the platform threshold", errors)
	var platform_width := float(platform.texture.get_width()) * platform.scale.x
	_check(platform_width >= 150.0 and platform_width <= 190.0, "parked platform width is outside the Operator-scale target", errors)
	var dust_size := Vector2(
		float(dust.sprite_frames.get_frame_texture(&"burst", 0).get_width()) * dust.scale.x,
		float(dust.sprite_frames.get_frame_texture(&"burst", 0).get_height()) * dust.scale.y
	)
	_check(dust_size.x >= 80.0 and dust_size.x <= 112.0, "dust width is outside the restrained target", errors)
	_check(dust_size.y >= 48.0 and dust_size.y <= 64.0, "dust height is outside the restrained target", errors)
	_check(dust.modulate.a >= 0.25 and dust.modulate.a <= 0.40, "dust opacity is outside the restrained target", errors)
	_check(not dust.visible, "dust must not remain visible while idle", errors)
	_validate_world_depth_contract(presentation, errors)
	_check(platform.z_index == 1 and vibrate.z_index == 1, "parked platform back must use idle z=1", errors)
	_check((presentation.get_node("LiftRoot/PlatformFront") as Node2D).z_index == 3, "parked front lip must use idle z=3", errors)
	var lift_root := presentation.get_node("LiftRoot") as Node2D
	var rider := presentation.get_node("LiftRoot/RiderAnchor") as Marker2D
	var platform_front := presentation.get_node("LiftRoot/PlatformFront") as Node2D
	_check(platform.get_index() < rider.get_index(), "platform back must precede rider at equal Z", errors)
	_check(rider.get_index() < platform_front.get_index(), "rider must precede front lip at equal Z", errors)
	_check(lift_root.get_index() < entrance_mask.get_index(), "cave mask must follow lift at equal Z", errors)
	_validate_boarding_bounds(presentation, errors)
	var boarded_actor := Node2D.new()
	presentation.add_child(boarded_actor)
	boarded_actor.global_position = presentation.get_boarding_position()
	_check(presentation.is_actor_boarded(boarded_actor), "boarding marker is outside boarding gate", errors)
	boarded_actor.position = Vector2(73, -26)
	_check(not presentation.is_actor_boarded(boarded_actor), "side position passed boarding gate", errors)
	boarded_actor.position = Vector2(0, -61)
	_check(not presentation.is_actor_boarded(boarded_actor), "rear shaft position passed boarding gate", errors)
	boarded_actor.queue_free()


func _validate_prompt(errors: Array[String]) -> void:
	var parsed: Variant = JSON.parse_string(_read_text(ROUTE_PATH))
	var route := parsed as Dictionary if parsed is Dictionary else {}
	var ingress := route.get("ingress", {}) as Dictionary
	_check(
		str(ingress.get("prompt_text", "")) == "DESCEND BELOW",
		"Ash Bell interaction prompt drifted",
		errors
	)
	_check(is_equal_approx(float(ingress.get("interaction_distance", 0.0)), 56.0), "Ash Bell interaction distance drifted", errors)


func _validate_puppet_scene(errors: Array[String]) -> void:
	var rig := OPERATOR_PRESENTATION_RIG.instantiate() as OperatorPresentationRig2D
	_check(rig != null, "operator presentation puppet did not instantiate", errors)
	if rig == null:
		return
	root.add_child(rig)
	for descendant in rig.find_children("*", "", true, false):
		_check(
			not (descendant is CollisionObject2D)
			and not (descendant is CollisionShape2D),
			"presentation puppet contains gameplay collision",
			errors
		)
	var source := Node2D.new()
	source.name = "Operator"
	root.add_child(source)
	var body := AnimatedSprite2D.new()
	body.name = "AnimatedSprite2D"
	body.modulate = Color(0.8, 0.7, 0.6, 0.9)
	body.z_index = 3
	source.add_child(body)
	var weapon_socket := Node2D.new()
	weapon_socket.name = "PrimaryWeaponSocket"
	weapon_socket.position = Vector2(7.0, -9.0)
	source.add_child(weapon_socket)
	var weapon := AnimatedSprite2D.new()
	weapon.name = "PrimaryWeaponSprite"
	weapon.z_index = 6
	weapon_socket.add_child(weapon)
	_check(rig.capture_from_operator(source), "puppet could not capture visual parts", errors)
	_check(rig.get_part_count() == 2, "puppet did not capture body and equipment leaves", errors)
	var captured_body := rig.get_node_or_null("PoseRoot/PartsRoot/AnimatedSprite2D") as AnimatedSprite2D
	var captured_weapon := rig.get_node_or_null("PoseRoot/PartsRoot/PrimaryWeaponSprite") as AnimatedSprite2D
	_check(captured_body != null and captured_body.modulate == body.modulate, "puppet lost body modulation", errors)
	_check(captured_body != null and captured_body.z_index == body.z_index, "puppet lost body draw order", errors)
	_check(captured_weapon != null and captured_weapon.position == weapon_socket.position, "puppet lost nested equipment transform", errors)
	rig.hide_source_visuals()
	_check(not body.visible and not weapon.visible, "puppet did not hide captured source leaves", errors)
	rig.restore_source_visuals()
	_check(body.visible and weapon.visible, "puppet did not restore captured source leaves", errors)
	source.queue_free()
	rig.queue_free()


func _validate_lift_travel(
	presentation: AshBellLiftIngressPresentation,
	errors: Array[String]
) -> void:
	var actor := Node2D.new()
	actor.name = "Operator"
	var visual := AnimatedSprite2D.new()
	visual.name = "AnimatedSprite2D"
	visual.sprite_frames = SpriteFrames.new()
	actor.add_child(visual)
	root.add_child(actor)
	await process_frame
	actor.z_index = 7
	actor.z_as_relative = true
	actor.process_mode = Node.PROCESS_MODE_ALWAYS
	presentation.descent_duration = 0.05
	var lift_start := presentation.lift_root.position
	var descent_actor_position := Vector2(91.0, 137.0)
	actor.position = descent_actor_position
	await presentation.play_descent(actor)
	_check(
		is_equal_approx(presentation.lift_root.position.y, lift_start.y + 176.0),
		"lift did not descend 176 px",
		errors
	)
	_check(actor.position == descent_actor_position, "descent moved the live Operator body", errors)
	_check(visual.visible, "descent did not restore the live Operator visual", errors)
	_check(not presentation.has_presentation_puppet(), "descent puppet was not freed", errors)
	_check(actor.process_mode == Node.PROCESS_MODE_ALWAYS, "actor process mode was not restored", errors)
	_check(actor.z_index == 7 and actor.z_as_relative, "actor Z state was not restored", errors)
	_check(presentation.entrance_mask.z_index == 1, "descent did not restore idle cave depth", errors)
	_check(not presentation.foreground_occluder.visible, "descent left broad cave mask visible while parked", errors)
	var restored_position := Vector2(311.0, 277.0)
	actor.position = restored_position
	await presentation.play_ascent(actor)
	_check(presentation.lift_root.position == lift_start, "lift did not ascend to parked position", errors)
	_check(actor.position == restored_position, "ascent moved restored actor back into shaft", errors)
	_check(actor.z_index == 7 and actor.z_as_relative, "ascent changed actor render context", errors)
	_check(actor.process_mode == Node.PROCESS_MODE_ALWAYS, "ascent did not restore actor process mode", errors)
	_check(visual.visible, "ascent did not restore the live Operator visual", errors)
	_check(not presentation.has_presentation_puppet(), "ascent puppet was not freed", errors)
	_check(presentation.entrance_mask.z_index == 1, "ascent did not restore idle cave depth", errors)
	_check(not presentation.shaft_window.visible, "ascent left the shaft exposed in the parked state", errors)
	presentation.reset_presentation()
	presentation.descent_duration = 1.0
	presentation.play_descent(actor)
	await process_frame
	_check(not visual.visible, "live Operator visual was not hidden during descent", errors)
	_check(presentation.has_presentation_puppet(), "descent did not create a puppet", errors)
	_check(presentation.shaft_window.visible, "shaft did not become visible after accepted traversal", errors)
	_check(presentation.entrance_mask.z_index == 20, "foreground cave mask did not enter travel z=20", errors)
	_check(not presentation.foreground_occluder.visible, "cave lip activated before rider passed beneath it", errors)
	_check(not presentation.travel_occlusion_geometry.visible, "solid temporary geometry activated during travel", errors)
	_check(presentation.platform_back_vibrate.z_index == 5, "travel platform back did not enter z=5", errors)
	_check((presentation.get_node("LiftRoot/PlatformFront") as Node2D).z_index == 7, "travel front lip did not enter z=7", errors)
	await create_timer(0.3).timeout
	_check(presentation.foreground_occluder.visible, "cave lip did not activate during deep descent", errors)
	var puppet := presentation.get_presentation_puppet()
	_check(puppet != null and puppet.z_index == 6, "rider did not retain lift world z=6", errors)
	_check(puppet != null and not puppet.z_as_relative, "rider Z became relative to the lift hierarchy", errors)
	presentation.cancel_presentation()
	await process_frame
	_check(visual.visible, "cancellation did not restore the live Operator visual", errors)
	_check(not presentation.has_presentation_puppet(), "cancellation did not free the puppet", errors)
	_check(actor.position == restored_position, "cancellation moved the live Operator body", errors)
	_check(not presentation.travel_occlusion_geometry.visible, "cancellation exposed temporary occlusion geometry", errors)
	_check(not presentation.foreground_occluder.visible, "cancellation left textured travel occlusion visible", errors)
	presentation.reset_presentation()
	_check(presentation.lift_root.position == lift_start, "presentation did not reset lift", errors)
	_check(presentation.platform_back_idle.visible and presentation.front_lip_idle.visible, "idle platform layers not restored", errors)
	_check(not presentation.platform_back_vibrate.visible and not presentation.front_lip_vibrate.visible, "vibration remained visible", errors)
	_check(not presentation.shaft_window.visible, "reset did not hide the shaft interior", errors)
	_check(not presentation.dust_burst.visible, "reset did not hide the dust burst", errors)
	actor.queue_free()
	var invalid_source := Node2D.new()
	root.add_child(invalid_source)
	var invalid_position := Vector2(22.0, 33.0)
	invalid_source.position = invalid_position
	await presentation.play_descent(invalid_source)
	_check(invalid_source.position == invalid_position, "failed capture moved its source", errors)
	_check(not presentation.has_presentation_puppet(), "failed capture leaked a puppet", errors)
	invalid_source.queue_free()


func _validate_specialized_spawner(errors: Array[String]) -> void:
	var spawner := SPAWNER_SCRIPT.new()
	root.add_child(spawner)
	var record := {
		"mode": "route",
		"identity": "forlorn_ritualant_underground",
		"definition": MockRouteDefinition.new(),
		"ingress": MockIngressDefinition.new(),
	}
	var world_owner := Node.new()
	root.add_child(world_owner)
	var ingress := spawner.call("_create_ingress", record, world_owner) as Area2D
	_check(ingress is AshBellLiftIngressSite, "spawner did not select Ash Bell lift ingress", errors)
	if ingress != null:
		root.add_child(ingress)
		_check(bool(ingress.get("requires_explicit_interaction")), "Ash Bell ingress is not explicit-interaction only", errors)
		_check(ingress.is_in_group("interactable"), "Ash Bell ingress is not discoverable by Interact", errors)
		_check(is_equal_approx(ingress.interaction_distance, 56.0), "specialized ingress interaction distance drifted", errors)
		var player := Node2D.new()
		player.name = "Operator"
		player.add_to_group("player")
		root.add_child(player)
		player.global_position = ingress.global_position + Vector2(80, -26)
		ingress.interact(player)
		_check(not bool(ingress.get("_approach_enter_deferred")), "off-platform interaction triggered lift traversal", errors)
		ingress.call("_on_body_entered", player)
		_check(not bool(ingress.get("_approach_enter_deferred")), "body entry auto-triggered explicit lift traversal", errors)
		player.queue_free()
		_check(
			ingress.get_node_or_null("AshBellLiftIngressPresentation") != null,
			"specialized ingress did not attach presentation",
			errors
		)
		ingress.queue_free()
	world_owner.queue_free()
	spawner.queue_free()
	var generic := WorldIngressSite.new()
	root.add_child(generic)
	_check(not generic.requires_explicit_interaction, "generic ingress interaction behavior changed", errors)
	_check(not generic.is_in_group("interactable"), "generic ingress unexpectedly became interactable", errors)
	generic.queue_free()


func _validate_boarding_bounds(
	presentation: AshBellLiftIngressPresentation,
	errors: Array[String]
) -> void:
	var bounds := presentation.get_node_or_null("BoardingBounds")
	_check(bounds is StaticBody2D, "boarding bounds StaticBody2D is missing", errors)
	if bounds == null:
		return
	var expected := {
		"BackStop": [Vector2(0.5, -36), Vector2(223, 16)],
		"LeftFrontWing": [Vector2(-56, 38), Vector2(48, 18)],
		"RightFrontWing": [Vector2(56, 38), Vector2(48, 18)],
	}
	for node_name: String in expected:
		var collision := bounds.get_node_or_null(node_name) as CollisionShape2D
		_check(collision != null, "%s collision is missing" % node_name, errors)
		if collision == null:
			continue
		var shape := collision.shape as RectangleShape2D
		_check(collision.position == expected[node_name][0], "%s position drifted" % node_name, errors)
		_check(shape != null and shape.size == expected[node_name][1], "%s dimensions drifted" % node_name, errors)


func _validate_world_depth_contract(
	presentation: AshBellLiftIngressPresentation,
	errors: Array[String]
) -> void:
	var expected := {
		"RearMassRoot": -8,
		"EntranceStructureRoot": 1,
		"LiftRoot": 0,
		"ForegroundOccluderRoot": 1,
		"DustBurst": 10,
		"LampFxRoot": 10,
	}
	for node_path: String in expected:
		var item := presentation.get_node_or_null(node_path) as CanvasItem
		_check(item != null, "%s is missing from lift depth contract" % node_path, errors)
		if item != null:
			_check(item.z_index == expected[node_path], "%s world Z drifted" % node_path, errors)
	for root_name: String in ["RearMassRoot", "EntranceStructureRoot", "ForegroundOccluderRoot"]:
		var band := presentation.get_node(root_name) as Node2D
		_check(not band.z_as_relative, "%s must use absolute z" % root_name, errors)
		_check(not band.y_sort_enabled, "%s must disable y-sort" % root_name, errors)


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


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)
