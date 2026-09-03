class_name AuthoredLevelMapperAdapter
extends Resource

func level_id() -> String:
	return ""

func supports_tile_authoring() -> bool:
	return false

func supports_underlay_sampling() -> bool:
	return false

func authoring_modes() -> Array[String]:
	return ["COLLISION", "MARKERS", "FEATURES", "REGIONS", "VALIDATION"]

func semantic_groups() -> Array[String]:
	return ["boundary", "encounter", "hazard", "interaction", "camera", "transition", "art", "traversal", "occlusion", "elevation", "spawn", "dynamic_blocker", "region"]

