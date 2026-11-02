extends SceneTree

const TEST_SCENE := preload("res://scenes/twin_solaria_backdrop_test.tscn")
const EXPECTED_MAP_SIZE := Vector2(3500.0, 3000.0)


func _initialize() -> void:
	var scene := TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var background := scene.get_node_or_null("World/TwinSolariaBackdrop/Background") as Sprite2D
	if background == null or background.texture == null:
		failures.append("development backdrop texture is missing")
	elif Vector2(background.texture.get_size()) != EXPECTED_MAP_SIZE:
		failures.append("development backdrop is not the expected largest 3500x3000 raster")

	if scene.get_node_or_null("World/Operator") == null:
		failures.append("operator is missing")
	if scene.get_node_or_null("World/Camera2D") == null:
		failures.append("camera is missing")
	if scene.get_node_or_null("World/TwinSolariaBackdrop/PerimeterCollision") == null:
		failures.append("perimeter collision is missing")
	if not scene.has_method("get_test_snapshot"):
		failures.append("test snapshot API is missing")
	else:
		var snapshot: Dictionary = scene.call("get_test_snapshot")
		if Vector2(snapshot.get("map_size", Vector2.ZERO)) != EXPECTED_MAP_SIZE:
			failures.append("camera/test bounds do not match the backdrop")

	if failures.is_empty():
		print("Twin Solaria backdrop test smoke: PASS")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error("Twin Solaria backdrop test smoke: %s" % failure)
	scene.queue_free()
	await process_frame
	quit(1)
