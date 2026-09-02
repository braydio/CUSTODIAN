extends SceneTree

const PLACEMENTS := "res://game/world/levels/authored/ash_bell/common/lower_quarter_native_prop_placements.json"
const SEMANTIC := "res://content/metadata/assets/meridian_civic_props_native.semantic.json"
const SCENES := {
	"lower_quarter": "res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn",
	"west_gate_works": "res://game/world/levels/authored/ash_bell/west_gate_works/west_gate_works.tscn",
	"station_ix": "res://game/world/levels/authored/ash_bell/station_ix/station_ix.tscn",
}
const EXPECTED_COUNTS := {"lower_quarter": 104, "west_gate_works": 64, "station_ix": 82}
const BLOCKED_SOURCE_IDS := {177: true, 201: true, 212: true}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var placement_doc := _json(PLACEMENTS)
	var semantic_doc := _json(SEMANTIC)
	_assert(not placement_doc.is_empty(), "placement JSON loads")
	_assert(not semantic_doc.is_empty(), "semantic manifest loads")
	var semantic_by_id: Dictionary = {}
	for value: Variant in semantic_doc.get("entries", []):
		var entry := value as Dictionary
		semantic_by_id[int(entry.get("id", -1))] = entry
	var placement_ids: Dictionary = {}
	var source_ids: Dictionary = {}
	var families: Dictionary = {}
	var total := 0
	for level_id: String in EXPECTED_COUNTS:
		var level := (placement_doc.get("levels", {}) as Dictionary).get(level_id, {}) as Dictionary
		var records := level.get("placements", []) as Array
		var origin := _vec(level.get("map_origin", []))
		var enabled_count := 0
		for value: Variant in records:
			var record := value as Dictionary
			var placement_id := String(record.get("placement_id", ""))
			_assert(not placement_ids.has(placement_id), "unique placement_id %s" % placement_id)
			placement_ids[placement_id] = true
			var source_id := int(record.get("source_id", -1))
			_assert(semantic_by_id.has(source_id), "source_id %s resolves" % source_id)
			_assert(not BLOCKED_SOURCE_IDS.has(source_id), "review-required source %s absent" % source_id)
			var semantic := semantic_by_id[source_id] as Dictionary
			_assert(not bool(semantic.get("review_required", false)), "source %s is production-approved" % source_id)
			_assert(String(semantic.get("runtime_family")) == String(record.get("runtime_family")), "runtime family matches source %s" % source_id)
			_assert(String(semantic.get("variant_key")) == String(record.get("variant_key")), "variant matches source %s" % source_id)
			var texture := "res://content/sprites/environment/props/meridian_civic/native/%s/%s" % [semantic.get("runtime_family"), semantic.get("source_file")]
			_assert(ResourceLoader.exists(texture), "texture exists for source %s" % source_id)
			var calculated := origin + _vec(record.get("cell", [])) * 32.0 + Vector2(16, 16) + _vec(record.get("offset_px", []))
			_assert(calculated == _vec(record.get("world_anchor", [])), "world anchor %s" % placement_id)
			source_ids[source_id] = true
			families[String(record.get("semantic_family"))] = true
			if bool(record.get("enabled", true)):
				if level_id == "lower_quarter":
					var cell := Vector2i(int((record.get("cell", []) as Array)[0]), int((record.get("cell", []) as Array)[1]))
					_assert(not Rect2i(62, 82, 5, 12).has_point(cell), "%s stays outside reserved arrival axis" % placement_id)
				enabled_count += 1
				total += 1
		_assert(enabled_count == EXPECTED_COUNTS[level_id], "%s active count" % level_id)
	_assert(total == 250, "total active placement count")
	_assert(source_ids.size() == 180, "unique source count")
	_assert(families.size() == 77, "semantic family coverage")
	for level_id: String in SCENES:
		var scene := load(SCENES[level_id]) as PackedScene
		var instance := scene.instantiate()
		root.add_child(instance)
		await process_frame
		var layer_path := "PropsRoot/NativeCivicPropRoot" if level_id == "lower_quarter" else "PropsRoot/NativePropRoot"
		var layer := instance.get_node(layer_path) as LowerQuarterNativePropLayer2D
		var snapshot := layer.get_debug_snapshot()
		_assert(layer.get_errors().is_empty(), "%s layer errors" % level_id)
		_assert(snapshot.size() == EXPECTED_COUNTS[level_id], "%s instantiated count" % level_id)
		for item: Dictionary in snapshot:
			_assert(item.get("scale") == Vector2.ONE, "%s native scale" % item.get("placement_id"))
			_assert(not bool(item.get("collision_enabled", true)), "%s collision disabled" % item.get("placement_id"))
			_assert(not String(item.get("resolved_texture", "")).is_empty(), "%s resolved texture" % item.get("placement_id"))
		instance.queue_free()
		await process_frame
	_assert(not FileAccess.get_file_as_string("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd").contains("_draw_prop"), "legacy prop drawing absent")
	print("lower_quarter_native_prop_placement_smoke: PASS active_placements=250 sources=180 families=77")
	quit(0)


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _vec(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array and (value as Array).size() == 2 else Vector2.INF


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("lower_quarter_native_prop_placement_smoke failed: %s" % label)
		quit(1)
