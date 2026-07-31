extends SceneTree

const LEVEL_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_front_gate_large.json"
)
const COLLISION_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_underlay_collision.json"
)
const ARCHIVE_PATH := (
	"res://content/levels/sundered_keep/archive/"
	+ "sundered_keep_front_gate_legacy_visual_ops.json"
)
const UNDERLAY_PATH := (
	"res://content/masters/sundered_keep/"
	+ "sundered_keep_main_overlay.png"
)
const MAPPER_SCENE := preload(
	"res://scenes/debug/sundered_keep_mapper.tscn"
)
const REMOVE_VISUAL_TYPES := [
	"fill_rect",
	"fill_weighted_rect",
	"paint_cells",
	"stamp_wall",
	"stamp_prop",
	"stamp_prefab",
]
const RETAIN_FUNCTIONAL_TYPES := [
	"blocker_rect",
	"interactable",
	"marker",
	"stamp_module",
]

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := _read_json(LEVEL_PATH)
	var collision := _read_json(COLLISION_PATH)
	var archive := _read_json(ARCHIVE_PATH)
	if level.is_empty() or collision.is_empty() or archive.is_empty():
		_finish()
		return

	var underlay := level.get("underlay", {}) as Dictionary
	_assert(
		str(underlay.get("texture_path", "")) == UNDERLAY_PATH,
		"production underlay path changed"
	)
	_assert(
		level.has("mapper_placements"),
		"mapper_placements is not explicitly present"
	)
	_assert(
		(level.get("mapper_placements", []) as Array).is_empty(),
		"production mapper_placements is not empty after migration"
	)

	for raw_op: Variant in level.get("ops", []):
		_assert(raw_op is Dictionary, "production op is not an object")
		if not (raw_op is Dictionary):
			continue
		var op_type := str((raw_op as Dictionary).get("type", ""))
		_assert(
			not REMOVE_VISUAL_TYPES.has(op_type),
			"retired visual op remains in production: %s" % op_type
		)
		_assert(
			RETAIN_FUNCTIONAL_TYPES.has(op_type),
			"unclassified production op remains: %s" % op_type
		)

	_assert(_has_marker(level, "spawn"), "spawn marker was removed")
	_assert(_has_marker(level, "main_gate"), "Main Gate marker was removed")
	_assert(
		_has_interactable(level, "main_gate"),
		"Main Gate interaction was removed"
	)
	_assert(
		_has_marker(level, "great_hall_door")
			and _has_interactable(level, "great_hall_door")
			and _has_blocker_role(level, "great_hall_door"),
		"Great Hall door authority was removed"
	)
	_assert(
		_has_marker(level, "return_gate")
			or _has_marker(level, "return_mooring"),
		"return causeway/mooring marker authority was removed"
	)
	_assert(
		_has_module(level, "return_mooring_3x3_01"),
		"stateful Return Mooring module was removed"
	)
	_assert(
		_has_blocker_role(level, "main_gate"),
		"Main Gate blocker contract was removed"
	)
	var siege := level.get("siege", {}) as Dictionary
	_assert(
		str(siege.get("schema", ""))
			== "custodian.sundered_keep.gatehouse_siege.v1"
			and not (siege.get("objectives", []) as Array).is_empty()
			and not (siege.get("waves", []) as Array).is_empty(),
		"gatehouse siege configuration was removed or disabled"
	)

	_assert(
		str(collision.get("schema", ""))
			== "custodian.sundered_keep.underlay_collision.v1",
		"underlay collision schema changed"
	)
	_assert(
		not (collision.get("segments", []) as Array).is_empty(),
		"authored collision segments were removed"
	)
	_assert(
		str(archive.get("schema", ""))
			== "custodian.sundered_keep.legacy_visual_ops.v1"
			and not bool(archive.get("runtime_authority", true)),
		"legacy visual-op archive contract is invalid"
	)

	var mapper := MAPPER_SCENE.instantiate()
	_assert(mapper != null, "production mapper could not instantiate")
	if mapper == null:
		_finish()
		return
	root.add_child(mapper)
	await process_frame
	await process_frame

	var state := mapper.call("get_sundered_keep_mapper_state") as Dictionary
	_assert(
		(state.get("placements", []) as Array).is_empty(),
		"mapper did not load with zero manual placements"
	)
	_assert(
		(state.get("palette", []) as Array).size() == 99,
		"mapper palette is unavailable"
	)
	_assert(
		mapper.has_method("_load_underlay_selection_as_stamp"),
		"mapper lost underlay-region sampling"
	)

	var preview := state.get("underlay_scene") as Node
	_assert(
		preview != null,
		"production map did not instantiate through the mapper"
	)
	if preview != null:
		_assert(
			preview.find_child("EntrySpawn", true, false) != null,
			"EntrySpawn/runtime entrance authority is missing"
		)
		_assert(
			preview.find_child("LevelShapeUnderlay", true, false) != null,
			"production scene does not contain its underlay sprite"
		)
		var runtime_state := (
			preview.call("get_sundered_keep_debug_state") as Dictionary
		)
		_assert(
			bool(runtime_state.get("underlay_present", false)),
			"production runtime did not build the underlay"
		)
		_assert(
			str(runtime_state.get("underlay_texture_path", ""))
				== UNDERLAY_PATH,
			"production runtime loaded the wrong underlay"
		)
		_assert(
			int(runtime_state.get("underlay_collision_segments", 0))
				== (collision.get("segments", []) as Array).size(),
			"production runtime did not retain all collision segments"
		)

	var palette := state.get("palette", []) as Array
	if not palette.is_empty():
		var tile_number := int((palette[0] as Dictionary).get(
			"tile_number",
			1
		))
		var temporary_cell := Vector2i(8, 8)
		mapper.set("_selected_tile_number", tile_number)
		_assert(
			bool(mapper.call(
				"_place_selected_tile",
				temporary_cell,
				false
			)),
			"mapper could not place a temporary palette tile"
		)
		var serialized := mapper.call("_placement_document") as Array
		_assert(
			serialized.size() == 1,
			"mapper did not serialize the temporary placement"
		)
		var temporary_document := (
			mapper.get("_level_document") as Dictionary
		).duplicate(true)
		temporary_document["mapper_placements"] = serialized
		mapper.set("_level_document", temporary_document)
		mapper.call("_load_mapping_document")
		state = mapper.call("get_sundered_keep_mapper_state") as Dictionary
		_assert(
			(state.get("placements", []) as Array).size() == 1,
			"mapper did not reload the serialized placement"
		)
		mapper.call("_remove_top_placement", temporary_cell)
		state = mapper.call("get_sundered_keep_mapper_state") as Dictionary
		_assert(
			(state.get("placements", []) as Array).is_empty(),
			"mapper could not remove the temporary top placement"
		)

	var disk_level := _read_json(LEVEL_PATH)
	_assert(
		(disk_level.get("mapper_placements", []) as Array).is_empty(),
		"temporary mapper test modified production data"
	)

	mapper.queue_free()
	await process_frame
	_finish()


func _has_marker(level: Dictionary, marker_id: String) -> bool:
	for raw_marker: Variant in level.get("markers", []):
		if (
			raw_marker is Dictionary
			and str((raw_marker as Dictionary).get("id", ""))
				== marker_id
		):
			return true
	return false


func _has_interactable(level: Dictionary, kind: String) -> bool:
	for raw_interactable: Variant in level.get("interactables", []):
		if (
			raw_interactable is Dictionary
			and str((raw_interactable as Dictionary).get("kind", ""))
				== kind
		):
			return true
	return false


func _has_blocker_role(level: Dictionary, role: String) -> bool:
	for raw_op: Variant in level.get("ops", []):
		if not (raw_op is Dictionary):
			continue
		var op := raw_op as Dictionary
		if (
			str(op.get("type", "")) == "blocker_rect"
			and str(op.get("role", "")) == role
		):
			return true
	return false


func _has_module(level: Dictionary, module_id: String) -> bool:
	for raw_op: Variant in level.get("ops", []):
		if not (raw_op is Dictionary):
			continue
		var op := raw_op as Dictionary
		if (
			str(op.get("type", "")) == "stamp_module"
			and str(op.get("module_id", "")) == module_id
		):
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_errors.append("missing JSON: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	_errors.append("invalid JSON: %s" % path)
	return {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _finish() -> void:
	if _errors.is_empty():
		print("[SunderedKeepUnderlayVisualAuthoritySmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error(
			"[SunderedKeepUnderlayVisualAuthoritySmoke] %s" % error
		)
	quit(1)
