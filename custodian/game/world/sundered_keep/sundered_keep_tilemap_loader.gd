extends RefCounted
class_name SunderedKeepTilemapLoader


func load_level(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		push_warning("[SunderedKeepDataTilemap] Missing level data: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[SunderedKeepDataTilemap] Could not open level data: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("[SunderedKeepDataTilemap] Invalid JSON level data: %s" % path)
		return {}

	var data := parsed as Dictionary
	if str(data.get("schema", "")) != "custodian.sundered_keep.level_tilemap.v1":
		push_warning("[SunderedKeepDataTilemap] Unsupported level schema in %s" % path)
		return {}
	return data
