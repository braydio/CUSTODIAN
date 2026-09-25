extends SceneTree

## Real-Operator, real-camera gameplay captures for Awakening visual review.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const SCENE := preload("res://scenes/awakening_first_return.tscn")
const OUTPUT := "res://../reports/awakening_visual_walkthrough"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := SCENE.instantiate() as Node2D
	viewport.add_child(scene)
	var operator := scene.get_node("World/Operator") as Node2D
	var camera := scene.get_node("World/Camera2D") as Camera2D
	camera.operator_ref = operator
	camera.follow_target = operator
	var output := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	var only := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	for checkpoint in _checkpoints():
		if not only.is_empty() and not String(checkpoint["name"]).begins_with(only):
			continue
		var point: Vector2 = checkpoint["position"]
		operator.global_position = point
		if operator is CharacterBody2D:
			(operator as CharacterBody2D).velocity = Vector2.ZERO
		camera.call("snap_to_player_spawn", point)
		camera.clear_presentation_framing(true)
		for frame in (100 if String(checkpoint["name"]).begins_with("undergate") else 25):
			await physics_frame
		for frame in 3:
			RenderingServer.force_draw(false)
			await process_frame
		var path := output.path_join(String(checkpoint["name"]) + ".png")
		if viewport.get_texture().get_image().save_png(path) != OK:
			push_error("Awakening walkthrough capture failed: " + path)
			quit(1)
			return
	print("Awakening walkthrough captures: " + output)
	quit(0)


func _checkpoints() -> Array[Dictionary]:
	var creche := Layout.zone_by_id(&"zone01_creche")
	var ambulatory := Layout.zone_by_id(&"zone02_ambulatory")
	var attestation := Layout.zone_by_id(&"zone03_attestation")
	var reliquary := Layout.zone_by_id(&"zone04_locker_reliquary")
	var dust := Layout.zone_by_id(&"zone05_dust_lung")
	var undergate := Layout.zone_by_id(&"zone06_undergate")
	var approach := Layout.zone_by_id(&"zone08_custodian_approach")
	return [
		{"name": "creche_center", "position": Layout.OPERATOR_WAKE_POSITION},
		{"name": "creche_north_exit", "position": creche["exit"] + Vector2(0, 48)},
		{"name": "ambulatory_center", "position": (ambulatory["envelope"] as Rect2).get_center() + Vector2(256, 0)},
		{"name": "ambulatory_north_exit", "position": ambulatory["exit"] + Vector2(0, 48)},
		{"name": "attestation_center", "position": (attestation["envelope"] as Rect2).get_center()},
		{"name": "attestation_east_exit", "position": attestation["exit"] + Vector2(-48, 0)},
		{"name": "reliquary_center", "position": (reliquary["envelope"] as Rect2).get_center() + Vector2(-128, 0)},
		{"name": "reliquary_p9_locker", "position": _marker(&"zone04_locker_reliquary", "p9_locker") + Vector2(-96, 0)},
		{"name": "connector_04_05_A", "position": (Layout.CONNECTORS["04_05_A"] as Rect2).get_center()},
		{"name": "connector_04_05_B", "position": (Layout.CONNECTORS["04_05_B"] as Rect2).get_center()},
		{"name": "connector_04_05_C", "position": (Layout.CONNECTORS["04_05_C"] as Rect2).get_center()},
		{"name": "dust_lung_center", "position": (dust["envelope"] as Rect2).get_center() + Vector2(256, 0)},
		{"name": "dust_lung_lift", "position": _marker(&"zone05_dust_lung", "lift_lower")},
		{"name": "undergate_center", "position": (undergate["envelope"] as Rect2).get_center()},
		{"name": "undergate_north", "position": undergate["exit"] + Vector2(0, 64)},
		{"name": "gate_of_dust", "position": Vector2(0, -5000)},
		{"name": "custodian_approach", "position": (approach["envelope"] as Rect2).get_center()},
	]


func _marker(zone_id: StringName, marker_id: String) -> Vector2:
	for marker in Layout.markers_for(zone_id):
		if String(marker.get("id", "")) == marker_id:
			return marker["position"]
	return Vector2.ZERO
