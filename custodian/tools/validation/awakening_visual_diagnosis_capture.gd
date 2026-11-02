extends SceneTree

## Layer isolation for the live Awakening scene. No scene or asset mutation.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const SCENE := preload("res://scenes/awakening_first_return.tscn")
const OUTPUT := "res://../reports/awakening_visual_diagnosis"
const MODES := ["baseline", "own_only", "own_underlay", "own_foreground", "no_foreground", "no_setpieces", "no_traversal"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 960)
	var scene := SCENE.instantiate() as Node2D
	root.add_child(scene)
	var camera := scene.get_node("World/Camera2D") as Camera2D
	camera.follow_enabled = false
	camera.auto_zoom_enabled = false
	camera.zoom = Vector2(0.9, 0.9)
	var output := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	for zone in Layout.ZONES:
		if int(zone["index"]) > 8:
			continue
		var zone_name := String(zone["node"])
		camera.global_position = (zone["envelope"] as Rect2).get_center()
		for mode in MODES:
			_apply_mode(scene, zone_name, mode)
			await _settle()
			var path := output.path_join("%02d_%s_%s.png" % [zone["index"], zone_name, mode])
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Visual diagnosis capture failed: " + path)
				quit(1)
				return
	print("Awakening layer diagnosis: " + output)
	quit(0)


func _apply_mode(scene: Node2D, selected: String, mode: String) -> void:
	var zones := scene.get_node("World/AwakeningZones")
	for zone in Layout.ZONES:
		var zone_name := String(zone["node"])
		var zone_node := zones.get_node_or_null(zone_name)
		if zone_node == null:
			continue
		var own := zone_name == selected
		for child_name in ["ArtUnderlay", "Occlusion", "SetPieces", "BlockoutPresentation"]:
			var child := zone_node.get_node_or_null(child_name) as CanvasItem
			if child == null:
				continue
			var visible := true
			if child_name == "BlockoutPresentation":
				visible = bool(scene.build_blockout_presentation) and zone_node.get_node_or_null("ArtUnderlay/Underlay") == null
			match mode:
				"own_only": visible = own and visible
				"own_underlay": visible = own and child_name == "ArtUnderlay"
				"own_foreground": visible = own and child_name == "Occlusion"
				"no_foreground": visible = child_name != "Occlusion" and visible
				"no_setpieces": visible = child_name != "SetPieces" and visible
			child.visible = visible
		if zone_name == "Zone10_RoadSouthReach":
			var road := zone_node.get_node_or_null("RoadOfWitnessesPrototype") as CanvasItem
			if road != null:
				road.visible = mode not in ["own_only", "own_underlay", "own_foreground"] or own
	var traversal := zones.get_node_or_null("Traversal/BlockoutPresentation") as CanvasItem
	if traversal != null:
		traversal.visible = mode not in ["no_traversal", "own_only", "own_underlay", "own_foreground"] and bool(scene.build_blockout_presentation) and not bool(scene.call("_has_production_traversal_art"))


func _settle() -> void:
	for frame in 3:
		RenderingServer.force_draw(false)
		await process_frame
