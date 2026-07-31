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
	var directory := DirAccess.open("res://scenes/debug")
	var mapper_scenes: Array[String] = []
	if directory != null:
		for filename in directory.get_files():
			if filename.begins_with("sundered_keep") and filename.ends_with("_mapper.tscn"):
				mapper_scenes.append(filename)
	_check(
		mapper_scenes.size() == 2,
		"expected exactly production Keep and approach mapper scenes: %s"
		% str(mapper_scenes),
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
