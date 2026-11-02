extends Resource
class_name TerrainStampCatalog

@export var stamps: Array[TerrainStampProfile] = []


func validation_report(require_textures: bool = true) -> Dictionary:
	var valid: Array[TerrainStampProfile] = []
	var rejected: Array[Dictionary] = []
	var seen: Dictionary = {}
	for profile: TerrainStampProfile in stamps:
		if profile == null:
			rejected.append({"stamp_id": "", "reasons": PackedStringArray(["null_profile"])})
			continue
		var failures := profile.validate_contract(require_textures)
		var key := String(profile.stamp_id)
		if seen.has(key):
			failures.append("duplicate_stamp_id")
		seen[key] = true
		if failures.is_empty():
			valid.append(profile)
		else:
			rejected.append({"stamp_id": key, "reasons": failures})
	valid.sort_custom(func(a: TerrainStampProfile, b: TerrainStampProfile) -> bool:
		return String(a.stamp_id) < String(b.stamp_id)
	)
	return {"valid": valid, "rejected": rejected}


func filter_profiles(
	families: PackedStringArray = PackedStringArray(),
	region_kind: StringName = &"",
	biome_id: StringName = &""
) -> Array[TerrainStampProfile]:
	var result: Array[TerrainStampProfile] = []
	for profile: TerrainStampProfile in validation_report(true).get("valid", []):
		if not families.is_empty() and not families.has(String(profile.family_id)):
			continue
		if (
			region_kind != &"" and not profile.allowed_region_kinds.is_empty()
			and not profile.allowed_region_kinds.has(String(region_kind))
		):
			continue
		if profile.required_biome != &"" and profile.required_biome != biome_id:
			continue
		result.append(profile)
	return result


func get_profile(stamp_id: StringName) -> TerrainStampProfile:
	for profile: TerrainStampProfile in validation_report(true).get("valid", []):
		if profile.stamp_id == stamp_id:
			return profile
	return null

