extends SceneTree

const PLAYGROUND_SCENE := preload("res://tools/validation/lighting_playground.tscn")


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

	print("[LightingSystemSmoke] ok active_profile=%s flash_pool=%d" % [str(director.active_profile), transient_pool.get_child_count()])
	quit(0)
