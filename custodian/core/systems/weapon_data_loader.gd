class_name WeaponDataLoader
extends Node

const WEAPON_DATA_PATH := "res://assets/weapons/data/"
const REGISTRY_PATH := "res://assets/weapons/registry.json"

var _weapon_cache: Dictionary = {}
var _registry: Dictionary = {}

func _ready() -> void:
	load_registry()
	load_all_weapons()

func load_registry() -> void:
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.parse_string(json_text)
		if json is Dictionary:
			_registry = json
		file.close()

func load_all_weapons() -> void:
	if _registry.is_empty() or not _registry.has("weapons"):
		push_warning("[WeaponDataLoader] Registry empty or missing weapons list")
		return
	
	for weapon_id in _registry["weapons"]:
		load_weapon(weapon_id)

func load_weapon(weapon_id: String) -> Dictionary:
	var path = WEAPON_DATA_PATH + weapon_id + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[WeaponDataLoader] Failed to load: " + path)
		return {}
	
	var json_text = file.get_as_text()
	var json = JSON.parse_string(json_text)
	file.close()
	
	if json is Dictionary:
		_weapon_cache[weapon_id] = json
		return json
	return {}

func get_weapon_data(weapon_id: String) -> Dictionary:
	return _weapon_cache.get(weapon_id, {})

func get_weapon_stats(weapon_id: String) -> Dictionary:
	var data = get_weapon_data(weapon_id)
	return data.get("stats", {})

func get_weapon_ammo(weapon_id: String) -> Dictionary:
	var data = get_weapon_data(weapon_id)
	return data.get("ammo", {})
