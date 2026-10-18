extends AuthoredLevelMapperAdapter
class_name CarrowInteriorLayoutMapperAdapter

func level_id() -> String:
	return "carrow_interior_layout_draft"

func supports_tile_authoring() -> bool:
	return true

func supports_underlay_sampling() -> bool:
	return true

func authoring_modes() -> Array[String]:
	return ["FLOOR", "PROPS", "COLLISION", "PORTAL", "STORAGE", "WAYPOINTS"]
