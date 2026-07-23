extends SceneTree

const CASES: Array[Dictionary] = [
	{
		"scene": "res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn",
		"exits": {
			"EventRuntimeRoot/Exits/Exit_Continue": {"id": &"continue", "size": Vector2(72.0, 104.0)},
			"EventRuntimeRoot/Exits/Exit_ReturnWorld": {"id": &"return_world", "size": Vector2(72.0, 88.0)},
		},
	},
	{
		"scene": "res://game/world/sundered_keep/return_causeway/ReturnCausewayApproach.tscn",
		"exits": {
			"Exits/Exit_Continue": {"id": &"continue", "size": Vector2(88.0, 88.0)},
			"Exits/Exit_Backtrack": {"id": &"backtrack", "size": Vector2(88.0, 88.0)},
		},
	},
	{
		"scene": "res://game/world/sundered_keep/sundered_keep_map.tscn",
		"exits": {
			"Exits/Exit_Backtrack": {"id": &"backtrack", "size": Vector2(88.0, 88.0)},
			"Exits/Exit_Exfil": {"id": &"exfil", "size": Vector2(88.0, 88.0)},
		},
	},
]


func _init() -> void:
	var errors: Array[String] = []
	for test_case: Dictionary in CASES:
		_validate_scene(test_case, errors)
	for root_path: String in [
		"res://game/world/approaches/sundered_keep",
		"res://game/world/sundered_keep",
	]:
		_scan_for_runtime_exit_construction(root_path, errors)
	_finish(errors)


func _validate_scene(test_case: Dictionary, errors: Array[String]) -> void:
	var packed := load(str(test_case.scene)) as PackedScene
	if packed == null:
		errors.append("scene failed to load: %s" % test_case.scene)
		return
	var instance := packed.instantiate()
	var seen: Dictionary = {}
	for node_path: String in test_case.exits.keys():
		var expected: Dictionary = test_case.exits[node_path]
		var route_exit := instance.get_node_or_null(node_path) as LevelExit2D
		if route_exit == null:
			errors.append("%s missing authored %s" % [test_case.scene, node_path])
			continue
		if route_exit.exit_id != expected.id:
			errors.append("%s has exit_id %s" % [node_path, route_exit.exit_id])
		if seen.has(route_exit.exit_id):
			errors.append("%s has duplicate exit_id %s" % [test_case.scene, route_exit.exit_id])
		seen[route_exit.exit_id] = true
		var collision := route_exit.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null:
			errors.append("%s lacks CollisionShape2D" % node_path)
			continue
		var rectangle := collision.shape as RectangleShape2D
		if rectangle == null or not rectangle.size.is_equal_approx(expected.size):
			errors.append("%s has wrong rectangle dimensions" % node_path)
	instance.free()


func _scan_for_runtime_exit_construction(root_path: String, errors: Array[String]) -> void:
	var directory := DirAccess.open(root_path)
	if directory == null:
		errors.append("unable to scan %s" % root_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := root_path.path_join(entry)
		if directory.current_is_dir():
			_scan_for_runtime_exit_construction(child, errors)
		elif entry.ends_with(".gd"):
			var source := FileAccess.get_file_as_string(child)
			for forbidden: String in ["LEVEL_EXIT_SCRIPT.new", "LevelExit2D.new"]:
				if source.contains(forbidden):
					errors.append("%s contains forbidden runtime exit construction: %s" % [child, forbidden])
		entry = directory.get_next()
	directory.list_dir_end()


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepAuthoredExitsSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error("[SunderedKeepAuthoredExitsSmoke] %s" % error)
	quit(1)
