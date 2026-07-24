extends Resource
class_name MaterialProfileLibrary

@export var profiles: Array[MaterialProfile] = []

var _by_id: Dictionary = {}


func rebuild() -> void:
	_by_id.clear()
	for profile in profiles:
		if profile == null:
			continue
		_by_id[profile.material_id] = profile


func get_profile(material_id: StringName) -> MaterialProfile:
	if _by_id.is_empty():
		rebuild()
	return _by_id.get(material_id, _by_id.get(&"unknown", null)) as MaterialProfile
