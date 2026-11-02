extends SceneTree

# Usage:
# godot --headless --path . \
#   --script res://tools/validation/authored_underlay_plate_pipeline_smoke.gd \
#   -- --manifest=res://content/.../map.plates.json \
#      --scene=res://game/.../map_underlay_runtime.tscn

const EXPECTED_SCHEMA := "custodian.authored_underlay_plate_manifest.v1"


func _init() -> void:
	var arguments := _parse_arguments(OS.get_cmdline_user_args())
	var manifest_path := String(arguments.get("manifest", ""))
	var scene_path := String(arguments.get("scene", ""))

	if manifest_path.is_empty() or scene_path.is_empty():
		_fail("Required: --manifest=res://... --scene=res://...")
		return
	if not FileAccess.file_exists(manifest_path):
		_fail("Manifest missing: %s" % manifest_path)
		return

	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(manifest_path)
	)
	if not (parsed is Dictionary):
		_fail("Manifest root is not an object.")
		return

	var manifest := parsed as Dictionary
	_assert_equal(
		String(manifest.get("schema", "")),
		EXPECTED_SCHEMA,
		"manifest schema"
	)

	var plates: Array = manifest.get("plates", []) as Array
	_assert_true(not plates.is_empty(), "manifest has plates")
	var ids := {}

	for value: Variant in plates:
		_assert_true(value is Dictionary, "plate definition is an object")
		var plate := value as Dictionary
		var plate_id := String(plate.get("id", ""))
		_assert_true(not plate_id.is_empty(), "plate ID is non-empty")
		_assert_true(not ids.has(plate_id), "plate ID is unique")
		ids[plate_id] = true

		var texture_path := String(plate.get("res_path", ""))
		_assert_true(
			ResourceLoader.exists(texture_path),
			"plate exists: %s" % texture_path
		)
		var texture := load(texture_path) as Texture2D
		_assert_true(texture != null, "plate loads: %s" % texture_path)

		var recorded_size := plate.get("texture_size_px", []) as Array
		_assert_true(recorded_size.size() == 2, "texture size is recorded")
		if texture != null and recorded_size.size() == 2:
			_assert_equal(
				texture.get_width(),
				int(recorded_size[0]),
				"texture width"
			)
			_assert_equal(
				texture.get_height(),
				int(recorded_size[1]),
				"texture height"
			)

		var core := plate.get("texture_core_rect", []) as Array
		_assert_true(core.size() == 4, "texture core rect is recorded")
		if texture != null and core.size() == 4:
			_assert_true(float(core[0]) >= 0.0, "core x is valid")
			_assert_true(float(core[1]) >= 0.0, "core y is valid")
			_assert_true(
				float(core[0]) + float(core[2])
					<= float(texture.get_width()) + 0.001,
				"core fits texture width"
			)
			_assert_true(
				float(core[1]) + float(core[3])
					<= float(texture.get_height()) + 0.001,
				"core fits texture height"
			)

	_assert_true(ResourceLoader.exists(scene_path), "runtime scene exists")
	var packed := load(scene_path) as PackedScene
	_assert_true(packed != null, "runtime scene loads")
	if packed == null:
		return

	var instance := packed.instantiate()
	root.add_child(instance)
	_assert_true(
		instance is AuthoredUnderlayPlateLoader,
		"runtime root uses AuthoredUnderlayPlateLoader"
	)
	_assert_true(
		instance.get_node_or_null("PlateRoot") != null,
		"runtime scene contains PlateRoot"
	)
	_assert_true(
		not _has_forbidden_descendant(instance),
		"plate scene owns no collision/navigation"
	)

	if instance is AuthoredUnderlayPlateLoader:
		var loader := instance as AuthoredUnderlayPlateLoader
		loader.streaming_enabled = false
		loader.reload_manifest()
		loader.force_load_all()
		_assert_equal(
			loader.get_loaded_plate_count(),
			plates.size(),
			"all manifest plates load"
		)
		loader.clear_loaded()
		_assert_equal(
			loader.get_loaded_plate_count(),
			0,
			"clear removes all plates"
		)

	instance.queue_free()
	print("[authored_underlay_plate_pipeline_smoke] PASS")
	quit(0)


func _has_forbidden_descendant(node: Node) -> bool:
	for child: Node in node.get_children():
		if (
			child is CollisionObject2D
			or child is NavigationRegion2D
			or child is NavigationObstacle2D
		):
			return true
		if _has_forbidden_descendant(child):
			return true
	return false


func _parse_arguments(values: PackedStringArray) -> Dictionary:
	var result := {}
	for value: String in values:
		if not value.begins_with("--"):
			continue
		var split := value.trim_prefix("--").split("=", true, 1)
		if split.size() == 2:
			result[split[0]] = split[1]
	return result


func _assert_true(value: bool, label: String) -> void:
	if not value:
		_fail("Assertion failed: %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_fail(
			"Assertion failed: %s expected=%s actual=%s"
			% [label, str(expected), str(actual)]
		)


func _fail(message: String) -> void:
	push_error("[authored_underlay_plate_pipeline_smoke] %s" % message)
	quit(1)
