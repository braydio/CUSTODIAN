extends SceneTree

const CATALOG := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exhibit_catalog.gd")
const PRESENTER := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exhibit_presenter.gd")
const LEVEL_SCENE := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var report: Dictionary = CATALOG.load_report()
	_check(failures, report.failures.is_empty(), "catalog resolves every listed authority: %s" % str(report.failures))
	var counts: Dictionary = {}
	for entry: Dictionary in report.valid:
		counts[entry.wing] = int(counts.get(entry.wing, 0)) + 1
	_check(failures, counts.get("terrain", 0) >= 2, "terrain has two canonical profiles")
	_check(failures, counts.get("topology", 0) >= 2, "topology has two canonical semantics")
	_check(failures, counts.get("sites", 0) >= 2, "sites cite two canonical placer APIs")
	_check(failures, counts.get("presentation", 0) >= 2, "presentation has two registered stamp profiles")
	var population: Dictionary = _find_entry(report.valid, "population.unavailable")
	_check(failures, population.get("status") == "na" and not String(population.get("reason", "")).is_empty(), "population absence is explicitly explained")
	var duplicate_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG.MANIFEST_PATH)) as Dictionary
	var duplicate: Dictionary = duplicate_manifest.exhibits[0].duplicate(true)
	duplicate_manifest.exhibits.append(duplicate)
	_check(failures, not CATALOG.validate_manifest(duplicate_manifest).failures.is_empty(), "duplicate exhibit identifiers are rejected")
	var invalid_na: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG.MANIFEST_PATH)) as Dictionary
	invalid_na.exhibits[6].reason = ""
	_check(failures, not CATALOG.validate_manifest(invalid_na).failures.is_empty(), "N/A entry without a reason is rejected")
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await process_frame
	var presenter := level.get_node_or_null("ExhibitPresenter")
	_check(failures, presenter != null and presenter.get_script() == PRESENTER, "gallery owns one local exhibit presenter")
	if presenter != null:
		var before := str(level.get_gallery_wing_ids()) + "|" + str(level.get_gallery_floor_regions())
		presenter.call("_on_wing_selected", 1)
		presenter.call("_on_wing_selected", 4)
		var after := str(level.get_gallery_wing_ids()) + "|" + str(level.get_gallery_floor_regions())
		_check(failures, before == after, "selection leaves authored world geometry unchanged")
		_check(failures, presenter.get_child_count() == 1, "presenter stays bounded to one local panel")
	level.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS procgen_showcase_exhibit_catalog_smoke")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _find_entry(entries: Array, exhibit_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("exhibit_id", "")) == exhibit_id:
			return entry
	return {}


func _check(failures: Array[String], condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures.append(message)
