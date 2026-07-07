class_name InventoryAssetCatalog
extends RefCounted

const MANIFEST_PATH := "res://content/ui/inventory/runtime/inventory_ui_asset_manifest.json"
const RUNTIME_ICON_PATTERN := "res://content/ui/inventory/runtime/icons/icon_%s.png"
const LEGACY_ICON_PATTERN := "res://content/ui/inventory/icons/icon_%s.png"
const RESOURCE_ICON_PATTERN := "res://content/ui/inventory/icons/resources/icon_%s.png"
const PLACEHOLDER_SVG_ICON_PATTERN := "res://content/ui/inventory/icons/icon_%s.svg"
const FALLBACK_ICON := "res://content/ui/inventory/icons/icon_placeholder.png"
const SPECIAL_ITEM_PORTRAITS := {
	"p9_sidearm": "res://content/weapons/p9_custodian_sidearm/runtime/portrait/p9_custodian_sidearm__portrait__inventory__default__omni__1f__512.png",
}
const SPECIAL_ITEM_HUD_ICONS := {
	"p9_sidearm": "res://content/weapons/p9_custodian_sidearm/runtime/portrait/p9_custodian_sidearm__icon__hud__default__omni__1f__64.png",
}
const ITEM_MATERIALS := {
	"blackwood": "res://game/ui/inventory/materials/blackwood_ember_spark_material.tres",
}

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
	for path in [RUNTIME_ICON_PATTERN % item_id, LEGACY_ICON_PATTERN % item_id, RESOURCE_ICON_PATTERN % item_id, PLACEHOLDER_SVG_ICON_PATTERN % item_id, FALLBACK_ICON]:
		if ResourceLoader.exists(path):
			return path
	return ""


static func item_icon(item_id: String) -> Texture2D:
	return _load_texture(item_icon_path(item_id))


static func item_portrait_path(item_id: String) -> String:
	var special := str(SPECIAL_ITEM_PORTRAITS.get(item_id, ""))
	if not special.is_empty() and ResourceLoader.exists(special):
		return special
	return item_icon_path(item_id)


static func item_portrait(item_id: String) -> Texture2D:
	return _load_texture(item_portrait_path(item_id))


static func item_hud_icon_path(item_id: String) -> String:
	var special := str(SPECIAL_ITEM_HUD_ICONS.get(item_id, ""))
	if not special.is_empty() and ResourceLoader.exists(special):
		return special
	return item_icon_path(item_id)


static func item_hud_icon(item_id: String) -> Texture2D:
	return _load_texture(item_hud_icon_path(item_id))


static func item_material(item_id: String) -> Material:
	var path := str(ITEM_MATERIALS.get(item_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
	return resource.duplicate(true) as Material if resource is Material else null


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
