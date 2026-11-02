extends SceneTree

const PLAYGROUND_SCENE := preload("res://tools/validation/lighting_playground.tscn")
const GATEHOUSE_SCENE := preload("res://tools/validation/gatehouse_lighting_test.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var playground := PLAYGROUND_SCENE.instantiate()
	root.add_child(playground)
	await process_frame

	var director := playground.get_node_or_null("WorldLightingDirector") as WorldLightingDirector
	var canvas_modulate := playground.get_node_or_null("CanvasModulate") as CanvasModulate
	var directional_light := playground.get_node_or_null("DirectionalLight2D") as DirectionalLight2D
	var zone := playground.get_node_or_null("LightingZone2D") as LightingZone2D
	var transient_pool := playground.get_node_or_null("TransientLightPool")
	var occluder := playground.get_node_or_null("OccluderWallBody/LightOccluder2D") as LightOccluder2D

	assert(director != null, "Lighting playground is missing WorldLightingDirector.")
	assert(canvas_modulate != null, "Lighting playground is missing CanvasModulate.")
	assert(directional_light != null, "Lighting playground is missing DirectionalLight2D.")
	assert(zone != null, "Lighting playground is missing LightingZone2D.")
	assert(transient_pool != null and transient_pool.has_method("flash_at"), "Lighting playground is missing TransientLightPool.")
	assert(occluder != null and occluder.occluder != null, "Lighting playground is missing a LightOccluder2D polygon.")
	assert(playground.get_node_or_null("TerminalGlowRig/PointLight2D") is PointLight2D)
	assert(playground.get_node_or_null("BeaconGlowRig/GlowSprite") is Sprite2D)

	var starting_color := canvas_modulate.color
	playground.call("cycle_profile")
	await process_frame
	assert(director.active_profile != null, "LightingDirector did not keep an active profile.")
	assert(canvas_modulate.color != starting_color or director.active_profile.transition_seconds > 0.0)

	playground.call("trigger_flash")
	await process_frame
	assert(transient_pool.get_child_count() > 0, "TransientLightPool did not create pooled flash sprites.")

	var gatehouse := GATEHOUSE_SCENE.instantiate()
	root.add_child(gatehouse)
	await process_frame
	var window_rig := gatehouse.get_node_or_null("WindowLight") as LightRig2D
	var west_brazier := gatehouse.get_node_or_null("WestBrazier") as LightRig2D
	var gatehouse_zone := gatehouse.get_node_or_null("LightingZone2D") as LightingZone2D
	var dust := gatehouse.get_node_or_null("WindowDust") as AnimatedSprite2D
	assert(window_rig != null and window_rig.light_texture != null, "Gatehouse window rig should use an authored light cookie.")
	assert(window_rig.point_light != null and window_rig.point_light.shadow_enabled, "Gatehouse window light should cast shadows.")
	assert(window_rig.point_light.height == 76.0, "Gatehouse window light should apply authored light height.")
	assert(window_rig.point_light.scale.is_equal_approx(Vector2(1.7, 1.1)), "Gatehouse window light should apply asymmetric scale.")
	assert(west_brazier != null and west_brazier.light_texture != window_rig.light_texture, "Brazier and window rigs should not share the same generic cookie.")
	assert(gatehouse_zone != null and gatehouse_zone.profile != null, "Gatehouse should own a darker lighting zone profile.")
	assert(dust != null and dust.sprite_frames != null and dust.sprite_frames.get_frame_count("drift") == 8, "Window shaft dust should expose eight authored frames.")
	for occluder_path in [
		"PillarWest/LightOccluder2D",
		"PillarCenter/LightOccluder2D",
		"PillarEast/LightOccluder2D",
		"GateWall/LightOccluder2D",
	]:
		var gatehouse_occluder := gatehouse.get_node_or_null(occluder_path) as LightOccluder2D
		assert(gatehouse_occluder != null and gatehouse_occluder.occluder != null, "Gatehouse major geometry should own an occluder: %s" % occluder_path)

	print("[LightingSystemSmoke] ok active_profile=%s flash_pool=%d gatehouse_occluders=4" % [str(director.active_profile), transient_pool.get_child_count()])
	quit(0)
