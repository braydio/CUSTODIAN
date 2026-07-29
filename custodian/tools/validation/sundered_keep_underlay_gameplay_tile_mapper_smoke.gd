extends SceneTree

const MAPPER_SCENE := preload(
	"res://scenes/debug/"
	+ "sundered_keep_underlay_gameplay_tile_mapper.tscn"
)
const MAPPING_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_underlay_gameplay_tiles.json"
)
const UNDERLAY_TEXTURE_PATH := (
	"res://content/masters/sundered_keep/"
	+ "sundered_keep_main_overlay.png"
)
const SUNDERED_KEEP_MAP_SCRIPT := preload(
	"res://game/world/sundered_keep/sundered_keep_map.gd"
)


func _init() -> void:
	var mapper := MAPPER_SCENE.instantiate()
	if mapper == null:
		_fail("could not instantiate gameplay tile mapper")
		return
	root.add_child(mapper)
	await process_frame
	await process_frame

	var errors: Array[String] = []
	var state := mapper.call(
		"get_gameplay_tile_mapper_state"
	) as Dictionary
	var palette := state.get("palette", []) as Array
	if palette.size() != 99:
		errors.append("palette expected 99 entries, got %d" % palette.size())
	if int(state.get("palette_columns", 0)) != 11:
		errors.append("palette must use 11 columns")
	if int(state.get("palette_rows", 0)) != 9:
		errors.append("palette must use 9 rows")
	if int(state.get("tile_size", 0)) != 32:
		errors.append("placement grid must remain 32 px")
	if not mapper.has_method("_source_cell_size_px"):
		errors.append("mapper missing source cell size helper")
	if not mapper.has_method("_source_rect_px_from_cells"):
		errors.append("mapper missing source rect conversion")
	if not mapper.has_method("_load_underlay_selection_as_stamp"):
		errors.append("mapper missing underlay stamp loader")
	if not mapper.has_method("_place_underlay_stamp"):
		errors.append("mapper missing underlay stamp placement")
	if not mapper.has_method("_begin_paint_drag"):
		errors.append("mapper missing repeated drag painting")
	if not mapper.has_method("_undo") or not mapper.has_method("_redo"):
		errors.append("mapper missing undo/redo")
	if not mapper.has_method("_reload_mapping_document"):
		errors.append("mapper missing live mapping reload")
	if state.get("map_size", Vector2.ZERO) as Vector2 != Vector2(
		3584.0,
		2560.0
	):
		errors.append("mapper map size drifted from collision-underlay authority")

	var seen_paths := {}
	for index in palette.size():
		var item := palette[index] as Dictionary
		var expected_number := index + 1
		if int(item.get("number", 0)) != expected_number:
			errors.append("palette number %d is not stable" % expected_number)
		var expected_label := "%02d" % expected_number
		if str(item.get("label", "")) != expected_label:
			errors.append("palette label %d is not zero padded" % expected_number)
		var texture_path := str(item.get("texture_path", ""))
		if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
			errors.append("palette %s texture is missing" % expected_label)
		if seen_paths.has(texture_path):
			errors.append("palette texture is duplicated: %s" % texture_path)
		seen_paths[texture_path] = true

	var underlay_scene := state.get("underlay_scene") as Node
	if underlay_scene == null:
		errors.append("reviewed underlay/collision pair was not loaded")
	else:
		var boundary := underlay_scene.get_node_or_null(
			"World/MappedUnderlayBounds/UnderlayBoundaryCollision"
		)
		if boundary == null:
			errors.append("canonical mapped collision body is missing")
		elif boundary.get_child_count() != 127:
			errors.append(
				"expected 127 canonical collision rails, got %d"
				% boundary.get_child_count()
			)

	var mapping_file := FileAccess.open(MAPPING_DATA_PATH, FileAccess.READ)
	if mapping_file == null:
		errors.append("gameplay tile mapping JSON is missing")
	else:
		var parsed: Variant = JSON.parse_string(mapping_file.get_as_text())
		if not (parsed is Dictionary):
			errors.append("gameplay tile mapping JSON is invalid")
		else:
			var document := parsed as Dictionary
			if str(document.get("schema", "")) != (
				"custodian.sundered_keep.underlay_gameplay_tiles.v1"
			):
				errors.append("gameplay tile mapping schema drifted")
			if int(document.get("palette_count", 0)) != 99:
				errors.append("mapping document palette count must be 99")
			if str(document.get("underlay_texture_path", "")) != (
				UNDERLAY_TEXTURE_PATH
			):
				errors.append("mapping document underlay texture path drifted")
			var document_grid := document.get(
				"underlay_grid_size",
				[]
			) as Array
			if (
				document_grid.size() != 2
				or int(document_grid[0]) != 112
				or int(document_grid[1]) != 80
			):
				errors.append("mapping document underlay grid must be 112x80")

	var initial_placement_count := (
		state.get("placements", []) as Array
	).size()
	mapper.set("_selected_tile_number", 10)
	mapper.call("_place_selected_tile", Vector2i(12, 34))
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	var placements := state.get("placements", []) as Array
	if placements.size() != initial_placement_count + 1:
		errors.append("grid-snapped preview placement was not recorded")
	else:
		var placement := placements[placements.size() - 1] as Dictionary
		if placement.get("cell", Vector2i.ZERO) as Vector2i != Vector2i(12, 34):
			errors.append("preview placement did not retain its grid cell")
		if int(placement.get("tile_number", 0)) != 10:
			errors.append("preview placement did not retain tile number 10")
	mapper.call("_remove_top_placement", Vector2i(12, 34))
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count
	):
		errors.append("right-click removal contract did not remove the top tile")

	var source_cell_size := mapper.call("_source_cell_size_px") as Vector2
	if not source_cell_size.is_equal_approx(Vector2(5048.0 / 112.0, 3500.0 / 80.0)):
		errors.append(
			"underlay source-cell conversion does not use reviewed source bounds"
		)
	var source_rect_px := mapper.call(
		"_source_rect_px_from_cells",
		Rect2i(Vector2i(10, 12), Vector2i(4, 4))
	) as Rect2
	if not source_rect_px.size.is_equal_approx(source_cell_size * 4.0):
		errors.append("underlay source rectangle conversion is incorrect")

	mapper.set("_selection_start_cell", Vector2i(10, 12))
	mapper.set("_selection_end_cell", Vector2i(13, 15))
	mapper.set("_underlay_select_mode", true)
	mapper.call("_load_underlay_selection_as_stamp")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if str(state.get("paint_source", "")) != "UNDERLAY_STAMP":
		errors.append("paint source did not switch to underlay stamp")
	if bool(state.get("underlay_select_mode", true)):
		errors.append("source selection did not exit after stamp capture")
	var active_stamp := (
		state.get("active_underlay_stamp", {}) as Dictionary
	)
	if active_stamp.get("source_rect_cells", []) != [10, 12, 4, 4]:
		errors.append("active underlay stamp did not retain selected source cells")
	mapper.set("_mouse_world", Vector2(20, 22) * 32.0 + Vector2.ONE)
	mapper.call("_refresh_active_stamp_preview")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	var active_preview := state.get("active_stamp_preview") as Sprite2D
	if (
		active_preview == null
		or not active_preview.visible
		or not active_preview.region_enabled
		or not active_preview.region_rect.size.is_equal_approx(
			source_cell_size * 4.0
		)
	):
		errors.append("active stamp cursor preview is missing or malformed")

	mapper.call("_place_underlay_stamp", Vector2i(20, 22))
	var document := mapper.call("_mapping_document") as Dictionary
	placements = document.get("placements", []) as Array
	var stamp_placement: Dictionary = {}
	for placement_variant: Variant in placements:
		var placement := placement_variant as Dictionary
		if str(placement.get("type", "")) == "underlay_stamp":
			stamp_placement = placement
	if stamp_placement.is_empty():
		errors.append("mapping document did not serialize underlay stamp")
	elif (
		stamp_placement.get("source_rect_cells", [])
		!= [10, 12, 4, 4]
	):
		errors.append("serialized underlay stamp source rectangle drifted")
	var placed_root := mapper.get_node(
		"World/PlacedGameplayTiles"
	) as Node2D
	var found_region_preview := false
	for child: Node in placed_root.get_children():
		var sprite := child as Sprite2D
		if (
			sprite != null
			and str(sprite.get_meta("type", "")) == "underlay_stamp"
			and sprite.region_enabled
		):
			found_region_preview = true
	if not found_region_preview:
		errors.append("underlay stamp did not build a region-enabled preview")
	mapper.call("_undo")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count
	):
		errors.append("undo did not revert underlay stamp placement")
	mapper.call("_redo")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count + 1
	):
		errors.append("redo did not restore underlay stamp placement")
	mapper.call("_remove_top_placement", Vector2i(22, 24))
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count
	):
		errors.append("stamp footprint removal did not remove top placement")

	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	var undo_before_drag := int(state.get("undo_count", 0))
	mapper.call("_begin_paint_drag", Vector2(20, 22) * 32.0 + Vector2.ONE)
	mapper.call("_continue_paint_drag", Vector2(22, 22) * 32.0 + Vector2.ONE)
	mapper.call("_finish_paint_drag")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count + 3
	):
		errors.append("Shift-drag contract did not paint every crossed cell")
	if int(state.get("undo_count", 0)) != undo_before_drag + 1:
		errors.append("repeated drag painting created more than one undo state")
	mapper.call("_undo")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count
	):
		errors.append("one undo did not revert the complete paint drag")
	mapper.call("_redo")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count + 3
	):
		errors.append("redo did not restore the complete paint drag")
	mapper.call("_reload_mapping_document")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count
	):
		errors.append("live reload did not restore the saved mapping")
	mapper.call("_undo")
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if (
		(state.get("placements", []) as Array).size()
		!= initial_placement_count + 3
	):
		errors.append("reload was not captured as an undoable edit")
	mapper.call("_reload_mapping_document")

	var runtime_map := SUNDERED_KEEP_MAP_SCRIPT.new()
	runtime_map.set("map_size_tiles", Vector2i(112, 80))
	runtime_map.call("_create_layers")
	var underlay_texture := load(UNDERLAY_TEXTURE_PATH) as Texture2D
	var applied := bool(runtime_map.call(
		"_apply_underlay_stamp_placement",
		{
			"type": "underlay_stamp",
			"cell": [20, 22],
			"source_rect_cells": [10, 12, 4, 4],
			"tile_size": 32,
			"category": "underlay_sample",
		},
		underlay_texture
	))
	if not applied:
		errors.append("production consumer rejected a valid underlay stamp")
	else:
		var minimap_floor_cells := (
			runtime_map.get("_minimap_floor_cells") as Dictionary
		)
		if not minimap_floor_cells.is_empty():
			errors.append("production stamp created minimap floor authority")
		var palette_applied := bool(runtime_map.call(
			"_apply_palette_gameplay_tile_placement",
			{
				"type": "palette_tile",
				"cell": [30, 30],
				"tile_number": 1,
				"category": "floor",
			},
			{1: palette[0]}
		))
		if not palette_applied:
			errors.append(
				"production consumer rejected a legacy palette placement"
			)
		var layers := runtime_map.get("_layers") as Dictionary
		var floor_detail := layers.get("FloorDetail") as Node2D
		var collision := layers.get("Collision") as Node2D
		if floor_detail == null or floor_detail.get_child_count() != 2:
			errors.append(
				"production stamp/palette placements did not reach FloorDetail"
			)
		if collision == null or collision.get_child_count() != 0:
			errors.append("production stamp created collision authority")
	runtime_map.free()

	mapper.queue_free()
	await process_frame
	if errors.is_empty():
		print("[SunderedKeepUnderlayGameplayTileMapperSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error(
			"[SunderedKeepUnderlayGameplayTileMapperSmoke] %s" % error
		)
	_fail("%d check(s) failed" % errors.size())


func _fail(message: String) -> void:
	push_error(
		"[SunderedKeepUnderlayGameplayTileMapperSmoke] %s" % message
	)
	quit(1)
