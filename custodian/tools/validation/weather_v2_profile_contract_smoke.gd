extends SceneTree

const ENVIRONMENT := preload("res://game/world/environment/world_environment_director.gd")
const PRESENTATION_PROFILE := preload("res://game/world/environment/weather_presentation_profile.gd")
const LIGHTING := preload("res://game/world/lighting/world_lighting_director.gd")
const ATMOSPHERE_SCENE := preload("res://game/world/lighting/world_atmosphere_2d.tscn")

var _failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := PRESENTATION_PROFILE.new()
	profile.profile_id = &"contract_test"
	profile.quality_tier = PRESENTATION_PROFILE.QualityTier.HIGH
	profile.climate_overrides = {"humid": {"far_density": 0.8, "wind_scale": Vector2(0.5, 1.0)}}
	profile.zone_overrides = {"sheltered": {"near_density": 0.0}}
	profile.weather_overrides = {"heavy_rain": {"mid_density": 1.4, "opacity": 1.2}}
	var resolved := profile.resolve("humid", "sheltered", "heavy_rain", PRESENTATION_PROFILE.QualityTier.MEDIUM)
	_require(resolved.quality_tier == PRESENTATION_PROFILE.QualityTier.MEDIUM, "requested quality should clamp the profile quality")
	_require(is_equal_approx(float(resolved.far_density), 0.75), "climate override should respect the quality cap")
	_require(is_equal_approx(float(resolved.near_density), 0.0), "zone override should resolve after climate")
	_require(is_equal_approx(float(resolved.mid_density), 0.85), "weather override should resolve after zone and respect the quality cap")
	_require(is_equal_approx(float(resolved.opacity), 1.0), "resolved values should clamp to their supported range")
	_require((resolved.wind_scale as Vector2).is_equal_approx(Vector2(0.5, 1.0)), "wind scale should survive resolution")

	var contract := {"contract_seed": 741, "map": {"map_seed": 82}, "world_profile": {
		"profile_seed": 19, "climate_profile_id": "humid",
		"day_start_hour_min": 9.0, "day_start_hour_max": 9.0,
		"weather_weights": {"clear": 0.5, "overcast": 0.5},
	}}
	var legacy := ENVIRONMENT.new()
	var v2_a := ENVIRONMENT.new()
	var v2_b := ENVIRONMENT.new()
	legacy.configure_from_contract(contract, null)
	v2_a.presentation_profile = profile
	v2_b.presentation_profile = profile
	v2_a.presentation_quality_tier = PRESENTATION_PROFILE.QualityTier.MEDIUM
	v2_b.presentation_quality_tier = PRESENTATION_PROFILE.QualityTier.MEDIUM
	v2_a.configure_from_contract(contract, null)
	v2_b.configure_from_contract(contract, null)
	v2_a._presentation_zone_id = "sheltered"
	v2_b._presentation_zone_id = "sheltered"
	var legacy_state := legacy.get_presentation_state()
	_require(not bool(legacy_state.get("presentation_v2_enabled", true)), "profile absence must retain the legacy presentation path")
	_require(int(legacy_state.precipitation_mode) == 0 and is_zero_approx(float(legacy_state.precipitation_alpha)), "profile absence must preserve V1 clear-weather output")
	_require(legacy._sample_day(legacy.current_hour) == v2_a._sample_day(v2_a.current_hour), "profile must not change V1 day-lighting modifiers")
	_require(legacy._sample_weather() == v2_a._sample_weather(), "profile must not change V1 weather-lighting modifiers")
	legacy.debug_set_time_paused(true)
	v2_a.debug_set_time_paused(true)
	_require(int(v2_a.get_presentation_state().presentation_seed) == int(v2_b.get_presentation_state().presentation_seed), "equal contracts should produce equal presentation seeds")
	_require(is_equal_approx(float(v2_a.get_presentation_state().visual_time), float(v2_b.get_presentation_state().visual_time)), "equal fixed-step sequences should sample equal visual time")
	legacy.advance_environment(1.0)
	v2_a.advance_environment(1.0)
	v2_b.advance_environment(1.0)
	v2_a._presentation_zone_id = "sheltered"
	v2_b._presentation_zone_id = "sheltered"
	_require(is_equal_approx(float(v2_a.get_presentation_state().visual_time), float(v2_b.get_presentation_state().visual_time)), "visual sample time should be deterministic across equal step sequences")
	_require(v2_a.get_presentation_state().presentation_quality == PRESENTATION_PROFILE.QualityTier.MEDIUM, "quality fallback should be visible in the presentation projection")
	_require(is_zero_approx(float(v2_a.get_presentation_state().near_density)), "zone override should project into presentation state")
	_require((v2_a.get_presentation_state().presentation_wind as Vector2).is_equal_approx(Vector2(0.425, 0.85)), "climate wind override should scale visual wind only")
	for _step in 300:
		legacy.advance_environment(1.0)
		v2_a.advance_environment(1.0)
		_require(legacy.debug_get_state().weather_current == v2_a.debug_get_state().weather_current, "profile must not change the seeded V1 weather sequence")
		_require(legacy.debug_get_state().weather_target == v2_a.debug_get_state().weather_target, "profile must not change V1 transition targets")
		_require(legacy._sample_day(legacy.current_hour) == v2_a._sample_day(v2_a.current_hour), "profile must not change day-lighting modifiers during transitions")
		_require(legacy._sample_weather() == v2_a._sample_weather(), "profile must not change weather-lighting modifiers during transitions")
	_require(is_equal_approx(v2_a.current_hour, 9.0), "pausing the day clock should retain its V1 behavior")
	_require(is_equal_approx(float(v2_a.get_presentation_state().visual_time), 301.0), "fixed-step presentation time should continue while only the day clock is paused")
	await _check_atmosphere_binding(profile, contract)
	legacy.free()
	v2_a.free()
	v2_b.free()
	if _failed:
		quit(1)
		return
	print("weather_v2_profile_contract_smoke: PASS")
	quit(0)


func _check_atmosphere_binding(profile: Resource, contract: Dictionary) -> void:
	var host := Node2D.new()
	root.add_child(host)
	var world := Node2D.new()
	world.name = "World"
	host.add_child(world)
	var canvas := CanvasModulate.new()
	canvas.name = "CanvasModulate"
	world.add_child(canvas)
	var light := DirectionalLight2D.new()
	light.name = "DirectionalLight2D"
	world.add_child(light)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var lighting := LIGHTING.new()
	lighting.name = "WorldLightingDirector"
	lighting.canvas_modulate_path = NodePath("../CanvasModulate")
	lighting.directional_light_path = NodePath("../DirectionalLight2D")
	world.add_child(lighting)
	var environment := ENVIRONMENT.new()
	environment.name = "WorldEnvironmentDirector"
	world.add_child(environment)
	environment.configure_from_contract(contract, null)
	var atmosphere := ATMOSPHERE_SCENE.instantiate() as WorldAtmosphere2D
	host.add_child(atmosphere)
	await process_frame
	var material := atmosphere.get_atmosphere_material()
	_require(material != null, "production atmosphere scene should expose its shader material")
	var shader_code := material.shader.code
	_require(shader_code.contains("vec2 particle_coordinate = world_anchored ? world_position : pixel"), "V2 precipitation must use world-space coordinates while V1 retains its screen-space coordinates")
	_require(shader_code.contains("deterministic_visual_time_enabled ? floor(world_position) : pixel"), "V2 atmospheric grain must remain stable when the camera moves")
	_require(not bool(material.get_shader_parameter("deterministic_visual_time_enabled")), "profile absence must leave shader TIME enabled")
	environment.presentation_profile = profile
	environment.presentation_quality_tier = PRESENTATION_PROFILE.QualityTier.MEDIUM
	environment.debug_force_weather("heavy_rain")
	environment.advance_environment(2.0)
	atmosphere.call("_update_shader_parameters")
	var state := environment.get_presentation_state()
	_require(bool(material.get_shader_parameter("deterministic_visual_time_enabled")), "assigned profile should enable deterministic shader time")
	_require(is_equal_approx(float(material.get_shader_parameter("visual_time")), float(state.visual_time)), "shader time should use the director's fixed-step sample")
	_require(int(material.get_shader_parameter("visual_seed")) == int(state.presentation_seed), "shader seed should use the contract-derived presentation seed")
	_require((material.get_shader_parameter("weather_wind") as Vector2).is_equal_approx(state.presentation_wind), "shader wind should use the visual-only scaled wind projection")
	host.queue_free()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("weather_v2_profile_contract_smoke: " + message)
