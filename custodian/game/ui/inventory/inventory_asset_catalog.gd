class_name InventoryAssetCatalog
extends RefCounted

const MANIFEST_PATH := "res://content/ui/inventory/runtime/inventory_ui_asset_manifest.json"
const RUNTIME_ICON_PATTERN := "res://content/ui/inventory/runtime/icons/icon_%s.png"
const LEGACY_ICON_PATTERN := "res://content/ui/inventory/icons/icon_%s.png"
const FALLBACK_ICON := "res://content/ui/inventory/icons/icon_placeholder.png"

static var _manifest: Dictionary = {}


static func asset_path(asset_id: String) -> String:
	var assets: Dictionary = _get_manifest().get("assets", {})
	var entry: Dictionary = assets.get(asset_id, {})
	for path_key in ["canonical_path", "fallback_path"]:
		var path := str(entry.get(path_key, ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	return ""


static func texture(asset_id: String) -> Texture2D:
	return _load_texture(asset_path(asset_id))


static func item_icon_path(item_id: String) -> String:
	for path in [RUNTIME_ICON_PATTERN % item_id, LEGACY_ICON_PATTERN % item_id, FALLBACK_ICON]:
		if ResourceLoader.exists(path):
			return path
	return ""


static func item_icon(item_id: String) -> Texture2D:
	return _load_texture(item_icon_path(item_id))


static func _get_manifest() -> Dictionary:
	if not _manifest.is_empty():
		return _manifest
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed as Dictionary
	return _manifest


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var resource: Resource = load(path)
	return resource as Texture2D if resource is Texture2D else null
