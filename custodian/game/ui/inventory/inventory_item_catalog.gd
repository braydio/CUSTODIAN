class_name InventoryItemCatalog
extends RefCounted

const ITEM_FILES := [
	"res://content/items/shrumb_drops/shrumb_drops.json",
	"res://content/items/lore/ash_bell_items.json",
]

static var _definitions: Dictionary = {}


static func get_definition(item_id: StringName) -> Dictionary:
	_ensure_loaded()
	var key := String(item_id)
	if _definitions.has(key):
		return (_definitions[key] as Dictionary).duplicate(true)
	return {
		"item_id": key,
		"display_name": key.replace("_", " ").capitalize(),
		"description": "No recovered archive description is available for this carried object.",
		"category": _infer_category(key, {}),
		"rarity": "unclassified",
		"provenance": "LOCAL LEDGER / UNVERIFIED",
	}


static func _ensure_loaded() -> void:
	if not _definitions.is_empty():
		return
	for path in ITEM_FILES:
		_load_file(path)
	_register_builtin(&"sundered_gate_key", "Sundered Gate Key", "A corroded winch key stamped with the keep's split-ring seal.", "key", "key_item")
	_register_builtin(&"p9_sidearm", "P-9 Field Sidearm", "Compact emergency weapon recognized by Custodian service imprint. Equip it in the Sidearm slot to replace offhand guard/parry with sidearm-ready.", "equipment", "equipment")
	_register_builtin(&"stilling_pin", "Stilling Pin", "A rusted iron pin that once anchored the Ash-Bell's silence. Setting it in the fountain basin counts the dead.", "key", "relic")


static func _load_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	for item_value in (parsed as Dictionary).get("items", []):
		if not (item_value is Dictionary):
			continue
		var item := (item_value as Dictionary).duplicate(true)
		var item_id := str(item.get("item_id", item.get("id", "")))
		if item_id.is_empty():
			continue
		item["item_id"] = item_id
		item["category"] = _infer_category(item_id, item)
		item["rarity"] = str(item.get("rarity", _infer_rarity(item)))
		item["provenance"] = str(item.get("provenance", _infer_provenance(item)))
		_definitions[item_id] = item


static func _register_builtin(item_id: StringName, display_name: String, description: String, category: String, rarity: String) -> void:
	_definitions[String(item_id)] = {
		"item_id": String(item_id),
		"display_name": display_name,
		"description": description,
		"category": category,
		"rarity": rarity,
		"provenance": "AUTHORED FIELD OBJECT",
	}


static func _infer_category(item_id: String, item: Dictionary) -> String:
	var item_type := str(item.get("type", ""))
	if item_type.contains("lore") or item.has("mechanical_effects"):
		return "relic"
	if item_type == "equipment":
		return "equipment"
	if item.has("cognitive_axis") or item_id in ["faint_recollection", "residual_instinct", "ancient_bearing"]:
		return "cognitive"
	if item_id.contains("key"):
		return "key"
	return "carried"


static func _infer_rarity(item: Dictionary) -> String:
	if str(item.get("type", "")).contains("lore"):
		return "relic"
	return "common"


static func _infer_provenance(item: Dictionary) -> String:
	var tags: Array = item.get("tags", [])
	if not tags.is_empty():
		return " / ".join(tags).to_upper()
	if item.has("cognitive_axis"):
		return "FOREST SHRUMB / COGNITIVE RESIDUE"
	return "LOCAL LEDGER"
