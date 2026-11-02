extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)
const OCCLUSION_PATH := (
	"res://content/levels/sundered_keep/sundered_keep_approach_occlusion.json"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var approach := APPROACH_SCENE.instantiate()
	root.add_child(approach)
	await process_frame
	var parsed: Variant = JSON.parse_string(_read_text(OCCLUSION_PATH))
	var document := parsed as Dictionary if parsed is Dictionary else {}
	var records := document.get("roof_occluders", []) as Array
	_check(records.size() >= 3, "checkpoint roof authoring is incomplete", errors)
	for raw: Variant in records:
		var record := raw as Dictionary
		_check(
			float(record.get("faded_alpha", 1.0)) <= 0.08,
			"roof does not fade to the authored cutaway alpha",
			errors
		)
		_check(
			bool(record.get("foreground_arch_persists", false)),
			"checkpoint foreground architecture is not preserved",
			errors
		)
		var roof_name := str(record.get("id", ""))
		_check(
			approach.get_node_or_null("RoofOcclusionRoot/%s" % roof_name) != null,
			"runtime missing mapper-authored roof %s" % roof_name,
			errors
		)
	_check(
		not _read_text(
			"res://game/world/approaches/sundered_keep/sundered_keep_approach.gd"
		).contains("Foliage"),
		"checkpoint cutaway depends on foliage occlusion",
		errors
	)
	_finish(errors)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepCheckpointOcclusionSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepCheckpointOcclusionSmoke] %s" % error)
	quit(1)
