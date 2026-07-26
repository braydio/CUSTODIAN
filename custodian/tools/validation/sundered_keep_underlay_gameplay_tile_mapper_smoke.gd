extends SceneTree

const MAPPER_SCENE := preload(
	"res://scenes/debug/"
	+ "sundered_keep_underlay_gameplay_tile_mapper.tscn"
)
const MAPPING_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_underlay_gameplay_tiles.json"
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

	mapper.set("_selected_tile_number", 10)
	mapper.call("_place_selected_tile", Vector2i(12, 34))
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	var placements := state.get("placements", []) as Array
	if placements.size() != 1:
		errors.append("grid-snapped preview placement was not recorded")
	else:
		var placement := placements[0] as Dictionary
		if placement.get("cell", Vector2i.ZERO) as Vector2i != Vector2i(12, 34):
			errors.append("preview placement did not retain its grid cell")
		if int(placement.get("tile_number", 0)) != 10:
			errors.append("preview placement did not retain tile number 10")
	mapper.call("_remove_top_placement", Vector2i(12, 34))
	state = mapper.call("get_gameplay_tile_mapper_state") as Dictionary
	if not (state.get("placements", []) as Array).is_empty():
		errors.append("right-click removal contract did not remove the top tile")

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
