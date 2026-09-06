class_name AwakeningFirstReturnMapperAdapter
extends AuthoredLevelMapperAdapter

## Mapper adapter for the Awakening opening dungeon. Zone, landmark, and route
## overlays are drawn by scenes/debug/awakening_first_return_overlay.gd, which
## reads awakening_layout.gd directly so the mapper cannot drift from runtime.

func level_id() -> String:
	return "awakening_first_return"

func supports_underlay_sampling() -> bool:
	return true
func authoring_modes() -> Array[String]:
	return ["COLLISION", "MARKER", "REGION"]

func semantic_groups() -> Array[String]:
	return ["zone_envelope", "critical_route", "optional_branch", "camera_reveal", "encounter", "interaction", "art_anchor"]
