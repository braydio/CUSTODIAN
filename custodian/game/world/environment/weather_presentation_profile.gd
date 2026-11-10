extends Resource
class_name WeatherPresentationProfile

enum QualityTier { LOW, MEDIUM, HIGH }

const QUALITY_LIMITS := {
	QualityTier.LOW: {"far_density": 0.5, "mid_density": 0.65, "near_density": 0.0},
	QualityTier.MEDIUM: {"far_density": 0.75, "mid_density": 0.85, "near_density": 0.4},
	QualityTier.HIGH: {"far_density": 2.0, "mid_density": 2.0, "near_density": 2.0},
}

@export var profile_id: StringName = &""
@export var enabled := true
@export var quality_tier: QualityTier = QualityTier.HIGH
@export var visual_seed_offset: int = 0
@export_range(0.0, 4.0, 0.01) var visual_time_scale := 1.0
@export var wind_scale := Vector2.ONE
@export_range(0.0, 2.0, 0.01) var opacity := 1.0
@export_range(0.0, 2.0, 0.01) var streak_scale := 1.0
@export_range(-1.0, 1.0, 0.01) var snow_drift := 0.0
@export_range(0.0, 2.0, 0.01) var dust_streak := 1.0
@export_range(0.0, 1.0, 0.01) var fog_altitude := 0.5
@export var climate_overrides: Dictionary = {}
@export var zone_overrides: Dictionary = {}
@export var weather_overrides: Dictionary = {}


func resolve(climate_id: String, zone_id: String, weather_id: String, requested_quality: int = QualityTier.HIGH) -> Dictionary:
	var resolved := {
		"quality_tier": clampi(mini(int(quality_tier), requested_quality), QualityTier.LOW, QualityTier.HIGH),
		"far_density": 1.0,
		"mid_density": 1.0,
		"near_density": 1.0,
		"opacity": opacity,
		"streak_scale": streak_scale,
		"snow_drift": snow_drift,
		"dust_streak": dust_streak,
		"fog_altitude": fog_altitude,
		"wind_scale": wind_scale,
		"visual_time_scale": visual_time_scale,
		"visual_seed_offset": visual_seed_offset,
	}
	var tier_limits: Dictionary = QUALITY_LIMITS[resolved.quality_tier]
	for key in tier_limits:
		resolved[key] = tier_limits[key]
	_merge_override(resolved, climate_overrides.get(climate_id, {}))
	_merge_override(resolved, zone_overrides.get(zone_id, {}))
	_merge_override(resolved, weather_overrides.get(weather_id, {}))
	resolved["far_density"] = clampf(float(resolved.get("far_density", 1.0)), 0.0, float(tier_limits.far_density))
	resolved["mid_density"] = clampf(float(resolved.get("mid_density", 1.0)), 0.0, float(tier_limits.mid_density))
	resolved["near_density"] = clampf(float(resolved.get("near_density", 1.0)), 0.0, float(tier_limits.near_density))
	resolved["opacity"] = clampf(float(resolved.get("opacity", 1.0)), 0.0, 1.0)
	resolved["streak_scale"] = clampf(float(resolved.get("streak_scale", 1.0)), 0.0, 3.0)
	resolved["snow_drift"] = clampf(float(resolved.get("snow_drift", 0.0)), -1.0, 1.0)
	resolved["dust_streak"] = clampf(float(resolved.get("dust_streak", 1.0)), 0.0, 2.0)
	resolved["fog_altitude"] = clampf(float(resolved.get("fog_altitude", 0.5)), 0.0, 1.0)
	resolved["wind_scale"] = _clamp_vector(resolved.get("wind_scale", Vector2.ONE))
	resolved["visual_time_scale"] = clampf(float(resolved.get("visual_time_scale", 1.0)), 0.0, 4.0)
	resolved["visual_seed_offset"] = int(resolved.get("visual_seed_offset", 0))
	return resolved


func _merge_override(target: Dictionary, value: Variant) -> void:
	if value is Dictionary:
		for key in value:
			if target.has(key):
				target[key] = value[key]


func _clamp_vector(value: Variant) -> Vector2:
	var vector := value as Vector2 if value is Vector2 else Vector2.ONE
	return Vector2(clampf(vector.x, -3.0, 3.0), clampf(vector.y, -3.0, 3.0))
