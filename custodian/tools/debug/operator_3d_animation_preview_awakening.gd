extends Node2D

## Dev-only corrected Neutral Idle preview inside the real Awakening scene.
## The scene is instantiated intact; only its preview actor is made inert.

const AWAKENING := preload("res://scenes/awakening_first_return.tscn")
const LAYOUT := preload("res://game/world/awakening/awakening_layout.gd")
const PREVIEW_SCRIPT := preload("res://tools/debug/operator_3d_animation_preview.gd")
const SPAWN := Vector2(0.0, -1824.0)

var awakening: Node
var preview: Node


func _ready() -> void:
	awakening = AWAKENING.instantiate()
	awakening.name = "Awakening"
	add_child(awakening)
	move_child(awakening, 0)
	if not LAYOUT.is_point_walkable(SPAWN):
		push_error("Attestation preview spawn is outside the real walkable surface")
		return
	for blocker in LAYOUT.blocking_rects():
		if blocker.has_point(SPAWN):
			push_error("Attestation preview spawn overlaps blocking geometry")
			return

	var operator := awakening.get_node("World/Operator") as CharacterBody2D
	var camera := awakening.get_node("World/Camera2D") as Camera2D
	var shadow := operator.get_node_or_null("BlobShadow") as CanvasItem
	if shadow != null and shadow.material is CanvasItemMaterial:
		# The shared multiply material renders zero-alpha texels as a hard rectangle
		# over Awakening's bright floor. Use the same shadow texture and transform
		# with ordinary alpha blending on this disposable preview instance only.
		var preview_shadow_material := (shadow.material as CanvasItemMaterial).duplicate() as CanvasItemMaterial
		preview_shadow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
		shadow.material = preview_shadow_material
	operator.global_position = SPAWN
	operator.velocity = Vector2.ZERO
	operator.collision_layer = 0
	operator.collision_mask = 0
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set_process_input(false)
	operator.set_process_unhandled_input(false)
	operator.set_process_unhandled_key_input(false)
	for shape in operator.find_children("*", "CollisionShape2D", true, false):
		shape.set_deferred("disabled", true)

	var player_controller := awakening.get_node_or_null("World/PlayerController")
	if player_controller != null:
		player_controller.set_process(false)
		player_controller.set_physics_process(false)
		player_controller.set_process_input(false)
		player_controller.set_process_unhandled_input(false)
		player_controller.set_process_unhandled_key_input(false)
	for area in awakening.find_children("*", "Area2D", true, false):
		(area as Area2D).monitoring = false
		(area as Area2D).monitorable = false
		area.set_process(false)
		area.set_physics_process(false)
		for shape in area.find_children("*", "CollisionShape2D", true, false):
			shape.set_deferred("disabled", true)

	awakening.set("current_zone_index", 3)
	var visited: Dictionary = awakening.get("visited_zones")
	visited[&"zone03_attestation"] = true
	awakening.set("visited_zones", visited)
	awakening.call("_set_hud_zone", LAYOUT.ZONES[2])
	awakening.call("_update_zone_art_visibility")
	awakening.set_process(false)

	# Awakening's own _ready has already applied its authored scene zoom (2.25 ×
	# camera base 0.84 ≈ 1.89). The shared preview controller freezes that camera
	# without substituting the Sundered Keep profile.
	preview = Node2D.new()
	preview.name = "PreviewController"
	preview.set_script(PREVIEW_SCRIPT)
	preview.set("operator_path", NodePath("../Awakening/World/Operator"))
	preview.set("camera_path", NodePath("../Awakening/World/Camera2D"))
	preview.set("preserve_scene_camera_profile", true)
	preview.set("initial_direction", "S")
	add_child(preview)


func run_awakening_smoke_check() -> Dictionary:
	if awakening == null or preview == null:
		return {"ok": false, "error": "Awakening preview setup failed"}
	var camera := awakening.get_node("World/Camera2D") as Camera2D
	var operator := awakening.get_node("World/Operator") as CharacterBody2D
	var underlay := awakening.get_node("World/AwakeningZones/Zone03_Attestation/ArtUnderlay/Underlay") as CanvasItem
	var foreground := awakening.get_node("World/AwakeningZones/Zone03_Attestation/Occlusion/Foreground") as CanvasItem
	if awakening.scene_file_path != "res://scenes/awakening_first_return.tscn":
		return {"ok": false, "error": "preview did not instance the real Awakening scene"}
	if camera.get_script() != load("res://game/world/camera.gd"):
		return {"ok": false, "error": "real Awakening camera missing"}
	if absf(camera.zoom.x - 1.89) > 0.02 or absf(camera.zoom.y - 1.89) > 0.02:
		return {"ok": false, "error": "authored Awakening closer zoom profile was not preserved"}
	if operator.global_position != SPAWN or not LAYOUT.is_point_walkable(SPAWN):
		return {"ok": false, "error": "Attestation spawn is not on its walkable floor"}
	for blocker in LAYOUT.blocking_rects():
		if blocker.has_point(SPAWN):
			return {"ok": false, "error": "Attestation spawn intersects a blocker"}
	if not underlay.visible or not foreground.visible or underlay.modulate.a < 0.99 or foreground.modulate.a < 0.99:
		return {"ok": false, "error": "Attestation underlay or occlusion presentation is hidden"}
	var preview_result: Dictionary = preview.call("run_smoke_check")
	if not preview_result.get("ok", false):
		return preview_result
	var player_controller := awakening.get_node_or_null("World/PlayerController")
	if player_controller == null or player_controller.is_processing() or player_controller.is_physics_processing():
		return {"ok": false, "error": "Awakening player simulation remains active"}
	for area in awakening.find_children("*", "Area2D", true, false):
		if (area as Area2D).monitoring or (area as Area2D).monitorable or area.is_processing() or area.is_physics_processing():
			return {"ok": false, "error": "Awakening progression or trigger area remains active: " + area.name}
	var shadow := operator.get_node_or_null("BlobShadow") as CanvasItem
	if shadow == null or not shadow.visible or shadow.modulate.a <= 0.0:
		return {"ok": false, "error": "Operator ground shadow is not visible"}
	return {
		"ok": true,
		"real_awakening_scene": awakening.scene_file_path,
		"zone": "zone03_attestation",
		"spawn": [SPAWN.x, SPAWN.y],
		"walkable": true,
		"blocking_geometry_overlap": false,
		"real_camera_script": "res://game/world/camera.gd",
		"camera_zoom": [camera.zoom.x, camera.zoom.y],
		"attestation_underlay_visible": underlay.visible,
		"attestation_foreground_visible": foreground.visible,
		"gameplay_simulation_disabled": true,
		"awakening_progression_triggers_disabled": true,
		"operator_shadow_visible": shadow.visible,
		"preview": preview_result,
	}
