extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)
const MAPPER_SCENE := preload(
	"res://scenes/debug/sundered_keep_approach_mapper.tscn"
)
const AUTHORITY_PATHS := [
	"res://content/levels/sundered_keep/sundered_keep_approach_outskirts.json",
	"res://content/levels/sundered_keep/sundered_keep_approach_collision.json",
	"res://content/levels/sundered_keep/sundered_keep_approach_occlusion.json",
]
const PREVIEW_CONFIG_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_approach_mapper_preview.json"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var approach := APPROACH_SCENE.instantiate()
	root.add_child(approach)
	await process_frame
	var mapper := MAPPER_SCENE.instantiate()
	root.add_child(mapper)
	await process_frame
	for path in AUTHORITY_PATHS:
		_check(FileAccess.file_exists(path), "missing mapper authority %s" % path, errors)
	var preview_config_file := FileAccess.open(PREVIEW_CONFIG_PATH, FileAccess.READ)
	_check(preview_config_file != null, "missing mapper preview config", errors)
	if preview_config_file != null:
		var parsed_preview: Variant = JSON.parse_string(preview_config_file.get_as_text())
		_check(parsed_preview is Dictionary, "invalid mapper preview config", errors)
		if parsed_preview is Dictionary:
			var preview := parsed_preview as Dictionary
			for expensive_toggle in [
				"route_contact_shadow", "edge_mist_wrap", "grand_vista_presentation",
				"animated_overlays", "authored_enemies", "debug_probe",
			]:
				_check(
					not bool(preview.get(expensive_toggle, true)),
					"expensive mapper default enabled: %s" % expensive_toggle,
					errors
				)
	_check(
		mapper.call("get_production_preview_scene_path") == (
			"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
		),
		"mapper does not preview the production scene",
		errors
	)
	_check(
		(mapper.call("get_supported_authoring_features") as PackedStringArray).size() >= 10,
		"mapper feature contract is incomplete",
		errors
	)
	_check(
		(approach.call("get_boundary_segments") as Array).size() >= 40,
		"production approach did not consume mapper collision rails",
		errors
	)
	var marker_state := approach.call("get_authoring_marker_state") as Dictionary
	var spawn_state := marker_state.get("spawn", {}) as Dictionary
	var source_spawn := spawn_state.get("source_position", Vector2.ZERO) as Vector2
	var runtime_spawn := spawn_state.get("runtime_position", Vector2.ZERO) as Vector2
	var entry_spawn := approach.get_node_or_null("Markers/EntrySpawn") as Marker2D
	_check(entry_spawn != null, "production approach EntrySpawn is missing", errors)
	if entry_spawn != null:
		_check(
			entry_spawn.position.is_equal_approx(runtime_spawn),
			"runtime EntrySpawn does not honor mapper spawn %s -> %s"
			% [source_spawn, runtime_spawn],
			errors
		)
	var mapper_state := mapper.call("get_collision_mapper_state") as Dictionary
	var marker_report := mapper.call("get_marker_authority_report") as Dictionary
	_check(
		int(marker_report.get("marker_count", 0)) == 19,
		"canonical marker set does not contain all 19 approach markers",
		errors
	)
	_check(
		(marker_report.get("errors", []) as Array).is_empty(),
		"duplicate or invalid markers remain: %s"
		% str(marker_report.get("errors", [])),
		errors
	)
	_check(
		marker_state.size() == int(marker_report.get("marker_count", -1)),
		"runtime and mapper marker authorities do not match",
		errors
	)
	_check(
		(mapper_state.get("zone_records", []) as Array).size() >= 7,
		"approach mapper did not load authored feature zones",
		errors
	)
	var directory := DirAccess.open("res://scenes/debug")
	var mapper_scenes: Array[String] = []
	if directory != null:
		for filename in directory.get_files():
			if filename.begins_with("sundered_keep") and filename.ends_with("_mapper.tscn"):
				mapper_scenes.append(filename)
	_check(
		mapper_scenes.count("sundered_keep_approach_mapper.tscn") == 1,
		"approach mapper scene is missing or duplicated: %s" % str(mapper_scenes),
		errors
	)
	_finish(errors)


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepApproachOutskirtsMapperSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepApproachOutskirtsMapperSmoke] %s" % error)
	quit(1)
