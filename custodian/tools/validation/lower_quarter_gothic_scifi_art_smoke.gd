extends SceneTree

const WALL_REVIEW := "res://content/metadata/assets/lower_quarter_gothic_scifi_walls.source_review.json"
const PROP_REVIEW := "res://content/metadata/assets/lower_quarter_gothic_scifi_props.source_review.json"
const WALL_MANIFEST := "res://content/metadata/assets/lower_quarter_gothic_scifi_walls_native.semantic.json"
const PROP_MANIFEST := "res://content/metadata/assets/lower_quarter_gothic_scifi_props_native.semantic.json"
const LOWER_QUARTER_SCENE := "res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn"


func _initialize() -> void:
	var failures: Array[String] = []
	_check_review(WALL_REVIEW, 97, 75, 22, 0, failures)
	_check_review(PROP_REVIEW, 73, 56, 15, 2, failures)
	_check_manifest(WALL_MANIFEST, failures)
	_check_manifest(PROP_MANIFEST, failures)
	var scene := load(LOWER_QUARTER_SCENE) as PackedScene
	if scene == null:
		failures.append("Lower Quarter scene unavailable")
	else:
		var instance := scene.instantiate()
		var wall_root := instance.get_node_or_null("BackgroundRoot/GothicSciFiWallModuleRoot")
		if wall_root == null:
			failures.append("GothicSciFiWallModuleRoot is not mounted")
		elif not wall_root.get_script():
			failures.append("GothicSciFiWallModuleRoot has no script")
		instance.free()
	if failures.is_empty():
		print("lower_quarter_gothic_scifi_art_smoke: PASS")
	else:
		for failure in failures:
			push_error(failure)
		print("lower_quarter_gothic_scifi_art_smoke: FAIL")
	quit(0 if failures.is_empty() else 1)


func _check_review(path: String, expected: int, generic: int, explicit_only: int, detail_only: int, failures: Array[String]) -> void:
	var document := _json(path, failures)
	if document.is_empty():
		return
	var entries := document.get("entries", []) as Array
	var counts := {"generic": 0, "explicit_only": 0, "detail_only": 0}
	for entry_variant: Variant in entries:
		var status := String((entry_variant as Dictionary).get("production_status", ""))
		if counts.has(status):
			counts[status] += 1
	if entries.size() != expected or counts["generic"] != generic or counts["explicit_only"] != explicit_only or counts["detail_only"] != detail_only:
		failures.append("Review contract mismatch: %s" % path)
	if float(document.get("runtime_scale", -1.0)) != 0.5:
		failures.append("Review scale is not 0.5: %s" % path)


func _check_manifest(path: String, failures: Array[String]) -> void:
	var document := _json(path, failures)
	if document.is_empty():
		return
	var contract := document.get("runtime_contract", {}) as Dictionary
	if float(contract.get("global_source_scale", -1.0)) != 0.5 or bool(contract.get("individual_autofit", true)):
		failures.append("Runtime scale/autofit contract mismatch: %s" % path)
	for entry_variant: Variant in document.get("entries", []):
		var entry := entry_variant as Dictionary
		if float(entry.get("native_scale", -1.0)) != 1.0 or String(entry.get("collision_profile", "")) != "none":
			failures.append("Runtime entry violates scale/collision contract: %s" % entry.get("variant_key", ""))


func _json(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("Missing JSON: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		failures.append("Invalid JSON: %s" % path)
		return {}
	return parsed as Dictionary
