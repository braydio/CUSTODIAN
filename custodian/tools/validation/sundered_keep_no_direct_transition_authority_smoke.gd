extends SceneTree
func _init() -> void:
	var errors: Array[String] = []
	var roots := ["res://game/world/approaches/sundered_keep", "res://game/world/sundered_keep"]
	var forbidden: Array[String] = ["BYPASS_RETURN_CAUSEWAY", "bypass_return_causeway", "resume_from_child", "adopt_active_level", "_upstream_map", "main_return_position", "configure_connection("]
	for root in roots: _scan(root, forbidden, errors)
	if errors.is_empty(): print("[SunderedKeepNoDirectTransitionAuthoritySmoke] PASS"); quit(0); return
	for error in errors: push_error("[SunderedKeepNoDirectTransitionAuthoritySmoke] %s" % error)
	quit(1)
func _scan(path: String, forbidden: Array[String], errors: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null: return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if dir.current_is_dir(): _scan(child, forbidden, errors)
		elif name.ends_with(".gd"):
			var file := FileAccess.open(child, FileAccess.READ); var text := file.get_as_text() if file != null else ""
			for token in forbidden:
				if text.contains(token): errors.append("%s retains %s" % [child, token])
		name = dir.get_next()
