extends SceneTree

const LAB_SCENE := preload("res://tools/visual_labs/sundered_keep_shoreline_lab.tscn")
const OUTPUT_DIR := "res://../reports/visual_labs/sundered_keep_shoreline/vocabulary_context"
const FIXTURES := {
	1: "res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_001.json",
	17: "res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_017.json",
	71: "res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_071.json",
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var output := ProjectSettings.globalize_path(OUTPUT_DIR)
	var error := DirAccess.make_dir_recursive_absolute(output)
	if error != OK:
		push_error("Could not create shoreline capture directory: %s" % error_string(error))
		quit(1)
		return
	var lab := LAB_SCENE.instantiate() as Node2D
	root.add_child(lab)
	await _settle()
	await _capture(lab, output, "cliff_vocabulary_context_off", {
		"shape_preset": 9, "production_context_mode": 0,
	})
	await _capture(lab, output, "cliff_vocabulary_false_color", {
		"false_color_debug": true,
	})
	await _capture(lab, output, "cliff_vocabulary_boundary_samples", {
		"false_color_debug": false,
		"show_boundary_polyline": true,
		"show_cliff_sample_points": true,
		"show_corner_markers": true,
	})
	await _capture(lab, output, "concave_cove_cliffs", {
		"shape_preset": 3, "show_floor": false, "show_ocean": false,
		"show_foam": false, "show_boundary_polyline": false,
		"show_cliff_sample_points": false, "show_corner_markers": false,
	})
	await _capture(lab, output, "concave_cove_cliffs_foam", {
		"show_ocean": true, "show_foam": true,
	})
	await _capture(lab, output, "concave_cove_ocean_underlay", {
		"production_context_mode": 1,
	})
	await _capture(lab, output, "jagged_coast_all_layers", {
		"shape_preset": 6, "show_floor": true, "production_context_mode": 0,
	})
	for seed_value in [1, 17, 71]:
		lab.set("production_fixture_path", FIXTURES[seed_value])
		lab.set("shape_preset", 8)
		lab.set("context_moment", 1)
		for mode in [0, 1, 2]:
			await _capture(lab, output, "production_seed_%03d_context_%d" % [seed_value, mode], {
				"production_context_mode": mode,
			})
	lab.queue_free()
	print("[SunderedKeepShorelineLabCapture] PASS path=%s" % output)
	quit(0)


func _capture(lab: Node2D, output: String, name: String, values: Dictionary) -> void:
	for key in values:
		lab.set(key, values[key])
	await _settle()
	_frame_lab(lab)
	await _settle()
	var image := root.get_texture().get_image()
	var error := image.save_png(output.path_join(name + ".png"))
	if error != OK:
		push_error("Could not save %s: %s" % [name, error_string(error)])


func _frame_lab(lab: Node2D) -> void:
	var camera := lab.get_node("Camera2D") as Camera2D
	camera.enabled = true
	camera.position = Vector2(640.0, 360.0)
	camera.zoom = Vector2.ONE
	if int(lab.get("shape_preset")) != 8:
		return
	var file := FileAccess.open(String(lab.get("production_fixture_path")), FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not parsed is Dictionary:
		return
	var context := (parsed as Dictionary).get("vista_context", {}) as Dictionary
	var gate := context.get("gate_threshold", []) as Array
	if gate.size() < 2:
		return
	var floor_layer := lab.get_node("PreviewRoot/Floor") as TileMapLayer
	camera.position = floor_layer.to_global(
		floor_layer.map_to_local(Vector2i(int(gate[0]), int(gate[1]) + 8))
	)
	camera.zoom = Vector2(0.65, 0.65)


func _settle() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
