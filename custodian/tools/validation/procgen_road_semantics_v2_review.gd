extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const REVIEW_SEED := 824790
const MAP_SIZE := Vector2i(128, 104)
const VIEWPORT_SIZE := Vector2i(1600, 900)
const OUTPUT_DIR := "res://../reports/procgen_road_semantics_v2"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var world := Node2D.new()
	viewport.add_child(world)
	var map := MAP_SCENE.instantiate() as ProcGenTilemap
	world.add_child(map)
	if not map.is_node_ready():
		await map.ready
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var procgen := map.get_node("ProcGen2") as ProcGen
	map.procgen_node = procgen
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = REVIEW_SEED
	procgen.map_size = MAP_SIZE
	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.generate()
	for _frame in range(480):
		if not map.debug_get_generated_floor_cells().is_empty():
			break
		await process_frame
	for _frame in range(4):
		await process_frame
	var camera := Camera2D.new()
	camera.enabled = true
	world.add_child(camera)
	camera.position = Vector2(MAP_SIZE) * 16.0
	var fit := minf(float(VIEWPORT_SIZE.x) / (MAP_SIZE.x * 32.0), float(VIEWPORT_SIZE.y) / (MAP_SIZE.y * 32.0)) * 0.94
	camera.zoom = Vector2.ONE * fit
	for _frame in range(6):
		RenderingServer.force_draw(false)
		await process_frame
	var viewport_texture := viewport.get_texture()
	if viewport_texture == null:
		push_error("Road Semantics capture requires a rendering backend; headless dummy rendering exposes no viewport texture")
		viewport.queue_free()
		await process_frame
		quit(2)
		return
	var image := viewport_texture.get_image()
	var capture_path := OUTPUT_DIR.path_join("seed_%d_overview.png" % REVIEW_SEED)
	var save_error := image.save_png(ProjectSettings.globalize_path(capture_path))
	var summary := map.debug_get_road_semantics_summary()
	var road_closeup_path := ""
	var largest_fragment := _largest_road_fragment(map.get_ruined_road_tiles())
	if not largest_fragment.is_empty():
		var bounds := _cell_bounds(largest_fragment).grow(4)
		camera.position = Vector2(bounds.position) * 32.0 + Vector2(bounds.size) * 16.0
		var closeup_fit := minf(float(VIEWPORT_SIZE.x) / (bounds.size.x * 32.0), float(VIEWPORT_SIZE.y) / (bounds.size.y * 32.0)) * 0.92
		camera.zoom = Vector2.ONE * clampf(closeup_fit, 0.5, 2.0)
		for _frame in range(6):
			RenderingServer.force_draw(false)
			await process_frame
		var closeup_texture := viewport.get_texture()
		if closeup_texture != null:
			road_closeup_path = OUTPUT_DIR.path_join("seed_%d_road_fragment_detail.png" % REVIEW_SEED)
			save_error = closeup_texture.get_image().save_png(ProjectSettings.globalize_path(road_closeup_path))
	var report := {
		"seed": REVIEW_SEED,
		"production_wide_roads_enabled": map.intent_main_roads_enabled,
		"road_semantics": summary,
		"ruined_road_cells": map.get_ruined_road_tiles().size(),
		"service_hardstand_cells": map.get_service_hardstand_tiles().size(),
		"parking_staging_cells": map.get_parking_zone_tiles().size(),
		"route_audit": map.debug_run_route_playability_audit(),
		"capture": capture_path,
		"road_fragment_detail_capture": road_closeup_path,
	}
	var file := FileAccess.open(OUTPUT_DIR.path_join("review_manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ") + "\n")
	viewport.queue_free()
	await process_frame
	if save_error != OK:
		push_error("Road semantics visual capture failed: " + error_string(save_error))
		quit(1)
		return
	print("procgen_road_semantics_v2_review: capture=%s road_detail=%s fragments=%d roads=%d apron=%d parking=%d" % [capture_path, road_closeup_path, int(summary.get("ruined_road_fragment_count", 0)), int(summary.get("ruined_road_cell_count", 0)), int(summary.get("service_hardstand_cell_count", 0)), int(summary.get("parking_cell_count", 0))])
	quit(0)


func _largest_road_fragment(cells: Array[Vector2i]) -> Array[Vector2i]:
	var remaining: Dictionary = {}
	for cell: Vector2i in cells:
		remaining[cell] = true
	var largest: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if not remaining.has(cell):
			continue
		var component: Array[Vector2i] = []
		var queue: Array[Vector2i] = [cell]
		remaining.erase(cell)
		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			component.append(current)
			for delta: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := current + delta
				if remaining.has(next):
					remaining.erase(next)
					queue.append(next)
		if component.size() > largest.size():
			largest = component
	return largest


func _cell_bounds(cells: Array[Vector2i]) -> Rect2i:
	var min_cell := cells[0]
	var max_cell := cells[0]
	for cell: Vector2i in cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)
