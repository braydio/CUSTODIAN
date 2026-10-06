extends Resource
class_name IsometricPresentationProfile

## Presentation-only 2.5D data. Ground XY stays authoritative; nothing here
## owns collision, navigation, or movement.

enum DepthBand {
	UNDERLAY,
	VISTA,
	SURFACE,
	GROUND,
	STRUCTURE,
	ROOF_OCCLUSION,
	OVERHEAD,
}

const BAND_Z_INDEX := {
	DepthBand.UNDERLAY: -300,
	DepthBand.VISTA: -200,
	DepthBand.SURFACE: -100,
	DepthBand.GROUND: 0,
	DepthBand.STRUCTURE: 40,
	DepthBand.ROOF_OCCLUSION: 90,
	DepthBand.OVERHEAD: 100,
}

@export var visual_elevation_px := 0.0
@export var depth_band: DepthBand = DepthBand.GROUND
@export var sort_anchor_offset := Vector2.ZERO


static func z_index_for_band(band: int) -> int:
	return int(BAND_Z_INDEX.get(band, 0))


func get_band_z_index() -> int:
	return z_index_for_band(depth_band)
