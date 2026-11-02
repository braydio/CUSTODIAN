extends Resource
class_name DressingClusterCatalog

@export var profiles: Array[DressingClusterProfile] = []


func filter_profiles(biome: StringName, surface_material: StringName) -> Array[DressingClusterProfile]:
	var result: Array[DressingClusterProfile] = []
	for profile in profiles:
		if profile == null or not profile.validate_contract().is_empty():
			continue
		if profile.required_biome != biome:
			continue
		if not profile.allowed_surface_materials.has(String(surface_material)):
			continue
		result.append(profile)
	result.sort_custom(func(a: DressingClusterProfile, b: DressingClusterProfile) -> bool:
		return String(a.cluster_id) < String(b.cluster_id)
	)
	return result
