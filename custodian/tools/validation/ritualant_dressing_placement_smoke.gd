extends SceneTree

const SCENE_PATH := "res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn"
const PLACEMENT_PATH := "res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_dressing_placements.json"
const EXPECTED_COUNT := 37

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACEMENT_PATH))
	_assert(document is Dictionary, "placement JSON parses")
	if not document is Dictionary:
		_finish()
		return
	_assert(String(document.get("schema", "")) == "custodian.ritualant_dressing_placements.v1", "placement schema")
	_assert((document.get("placements", []) as Array).size() == EXPECTED_COUNT, "placement count")
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "Underground scene loads")
	if packed == null:
		_finish()
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var layer := level.get_node_or_null("PropsRoot/AuthoredDressing") as ForlornRitualantDressingLayer2D
	_assert(layer != null, "authored dressing layer exists")
	if layer != null:
		_assert(layer.get_errors().is_empty(), "dressing resolves without errors")
		var snapshot := layer.get_debug_snapshot()
		_assert(snapshot.size() == EXPECTED_COUNT, "all placements instantiate")
		var ids: Dictionary = {}
		for item: Dictionary in snapshot:
			var placement_id := String(item.get("placement_id", ""))
			_assert(not ids.has(placement_id), "unique placement %s" % placement_id)
			ids[placement_id] = true
			_assert(item.get("texture_size", Vector2i.ZERO) != Vector2i.ZERO, "%s texture size" % placement_id)
			_assert(item.get("collision_enabled") == false, "%s remains visual-only" % placement_id)
		_assert(ids.has("landing_service_pylon_w"), "landing dressing present")
		_assert(ids.has("anchor_n_visual"), "anchor dressing present")
		_assert(ids.has("teaser_gate"), "northern teaser dressing present")
		var east := layer.get_node_or_null("LandingServicePylonE") as Sprite2D
		_assert(east != null and east.flip_h, "east pylon mirror")
		_assert(east != null and east.position == Vector2(280, 1570), "east pylon position")
		var connector := layer.get_node_or_null("ConnectorCliffW") as Sprite2D
		_assert(connector != null and connector.z_index == -29, "connector depth")
	level.queue_free()
	_finish()


func _assert(condition: bool, label: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[ritualant_dressing_placement_smoke] Assertion failed: %s" % label)


func _finish() -> void:
	if not _failed:
		print("[ritualant_dressing_placement_smoke] PASS")
	quit(1 if _failed else 0)
