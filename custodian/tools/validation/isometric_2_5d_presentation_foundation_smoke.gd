extends SceneTree

const FIXTURE := "res://tools/validation/fixtures/isometric_2_5d_presentation_foundation.tscn"
const MAIN_SCENE := "res://game/app/boot/runtime_entrypoint.tscn"
const RUNTIME_DIR := "res://game/world/presentation/isometric_2_5d/"
const FORBIDDEN := ["Node3D", "Vector3", "Camera3D", "CharacterBody3D", "MeshInstance3D"]

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		push_error("FAIL: " + msg)
		_failed = true


func _run() -> void:
	var packed := load(FIXTURE) as PackedScene
	_check(packed != null, "fixture loads")
	if packed == null:
		quit(1)
		return
	var fixture := packed.instantiate()
	root.add_child(fixture)
	await process_frame

	var rear := fixture.get_node("RearAnchor") as IsometricVisualAnchor2D
	var front := fixture.get_node("FrontAnchor") as IsometricVisualAnchor2D
	var rear_visual := rear.get_node("VisualRoot") as Node2D

	# 2/3: elevation moves only VisualRoot; ground position unchanged.
	var ground_before := rear.get_ground_world_position()
	var visual_before := rear_visual.position
	var profile := IsometricPresentationProfile.new()
	profile.visual_elevation_px = 80.0
	profile.depth_band = IsometricPresentationProfile.DepthBand.STRUCTURE
	profile.sort_anchor_offset = Vector2(0, 4)
	rear.profile = profile
	_check(rear.get_ground_world_position() == ground_before, "ground position unchanged by elevation")
	_check(rear.position == Vector2(100, 100), "anchor local position unchanged")
	_check(rear_visual.position == visual_before + Vector2(0, -80), "elevation offsets only VisualRoot")
	_check(rear.z_index == 40, "profile applies band z_index")
	rear.set_visual_elevation_px(10.0)
	_check(rear_visual.position == visual_before + Vector2(0, -10), "elevation is absolute, not cumulative")
	rear.set_visual_elevation_px(80.0)
	_check(rear.get_sort_world_position() == ground_before + Vector2(0, 4), "sort position uses ground + offset")

	# 4: no body/collision/navigation authority, no physics process.
	for n in [rear, front]:
		_check(not (n is CollisionObject2D) and not (n is NavigationRegion2D), "anchor is not a body/nav node")
		_check(not n.is_physics_processing(), "anchor does not physics-process")
		_check(_count_types(n, ["CollisionShape2D", "CollisionPolygon2D", "NavigationAgent2D"]) == 0, "no collision/nav children")

	# 5: band ordering.
	var order := [
		IsometricPresentationProfile.DepthBand.UNDERLAY,
		IsometricPresentationProfile.DepthBand.VISTA,
		IsometricPresentationProfile.DepthBand.SURFACE,
		IsometricPresentationProfile.DepthBand.GROUND,
		IsometricPresentationProfile.DepthBand.STRUCTURE,
		IsometricPresentationProfile.DepthBand.ROOF_OCCLUSION,
		IsometricPresentationProfile.DepthBand.OVERHEAD,
	]
	var expected := [-300, -200, -100, 0, 40, 90, 100]
	for i in order.size():
		_check(IsometricPresentationProfile.z_index_for_band(order[i]) == expected[i], "band %d z" % i)

	# 6: sorting follows ground roots despite rear's elevated visual overlapping front.
	var ground_profile := IsometricPresentationProfile.new()
	ground_profile.visual_elevation_px = 80.0
	rear.profile = ground_profile
	front.profile = IsometricPresentationProfile.new()
	var rear_sprite_bottom := rear.global_position.y + rear_visual.position.y
	_check(rear_sprite_bottom < rear.global_position.y, "rear visual is raised above its ground root")
	_check(rear_visual.position.y + 40.0 > -80.0 and rear.global_position.y + rear_visual.position.y + 40.0 > rear.global_position.y - 80.0, "rear visual extent overlaps upward")
	_check(fixture.y_sort_enabled, "fixture y_sort_enabled")
	_check(rear.get_sort_world_position().y < front.get_sort_world_position().y, "rear sorts behind front by ground root")
	_check(rear.z_index == 0 and front.z_index == 0, "equal band so y-sort alone decides")

	# 7: RoofOccluder2D reusable.
	var roof := fixture.get_node("Roof")
	_check(roof is RoofOccluder2D, "RoofOccluder2D reusable")
	var targets: Array[CanvasItem] = [rear_visual]
	(roof as RoofOccluder2D).configure(targets)

	# 8: production main scene unchanged.
	_check(str(ProjectSettings.get_setting("application/run/main_scene")) == MAIN_SCENE, "main scene unchanged")

	# 9: no prohibited 3D types in runtime surface.
	for f in DirAccess.get_files_at(RUNTIME_DIR):
		if f.ends_with(".gd"):
			var src := FileAccess.get_file_as_string(RUNTIME_DIR + f)
			for word in FORBIDDEN:
				_check(not src.contains(word), "%s contains %s" % [f, word])

	fixture.queue_free()
	if _failed:
		quit(1)
		return
	print("isometric_2_5d_presentation_foundation_smoke: OK")
	quit(0)


func _count_types(node: Node, types: Array) -> int:
	var c := 0
	for child in node.get_children():
		if child.get_class() in types:
			c += 1
		c += _count_types(child, types)
	return c
