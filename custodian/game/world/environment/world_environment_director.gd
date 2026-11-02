extends Node
class_name WorldEnvironmentDirector

signal time_changed(hour: float)
signal weather_changed(weather_id: StringName)
signal environment_state_changed(state: Dictionary)

enum PrecipitationMode { NONE, RAIN, SNOW, ASH, DUST }
const WEATHER_DEFS := {
	"clear":{"ambient":Color.WHITE,"directional":Color.WHITE,"energy":1.0,"fog":0.0,"cosmic":0.0,"wind":0.85,"gust":0.85,"mode":0,"precip":0.0,"tint":Color.WHITE,"grade":0.0,"next":["overcast","mist","dust_wind"]},
	"overcast":{"ambient":Color(0.94,0.96,1,1),"directional":Color(0.9,0.94,1,1),"energy":0.62,"fog":0.025,"cosmic":0.0,"wind":1.0,"gust":1.0,"mode":0,"precip":0.0,"tint":Color(0.92,0.96,1,1),"grade":0.05,"next":["clear","light_rain","mist","snow","ashfall"]},
	"light_rain":{"ambient":Color(0.88,0.93,1,1),"directional":Color(0.84,0.91,1,1),"energy":0.55,"fog":0.045,"cosmic":0.0,"wind":1.1,"gust":1.1,"mode":1,"precip":0.48,"tint":Color(0.84,0.93,1,1),"grade":0.07,"next":["overcast","heavy_rain","clear"]},
	"heavy_rain":{"ambient":Color(0.8,0.88,0.98,1),"directional":Color(0.78,0.87,1,1),"energy":0.34,"fog":0.085,"cosmic":0.0,"wind":1.45,"gust":1.45,"mode":1,"precip":1.0,"tint":Color(0.78,0.89,1,1),"grade":0.1,"next":["light_rain","overcast"]},
	"mist":{"ambient":Color(0.91,0.95,0.98,1),"directional":Color(0.9,0.95,1,1),"energy":0.52,"fog":0.14,"cosmic":0.0,"wind":0.4,"gust":0.3,"mode":0,"precip":0.0,"tint":Color(0.9,0.96,0.98,1),"grade":0.07,"next":["clear","overcast"]},
	"dust_wind":{"ambient":Color(1,0.91,0.78,1),"directional":Color(1,0.86,0.7,1),"energy":0.72,"fog":0.07,"cosmic":0.0,"wind":1.6,"gust":1.7,"mode":4,"precip":0.62,"tint":Color(1,0.82,0.64,1),"grade":0.1,"next":["clear","overcast"]},
	"snow":{"ambient":Color(0.91,0.96,1,1),"directional":Color(0.84,0.93,1,1),"energy":0.58,"fog":0.065,"cosmic":0.01,"wind":0.9,"gust":0.9,"mode":2,"precip":0.72,"tint":Color(0.88,0.95,1,1),"grade":0.06,"next":["overcast","clear","mist"]},
	"ashfall":{"ambient":Color(0.82,0.78,0.74,1),"directional":Color(0.84,0.72,0.64,1),"energy":0.44,"fog":0.1,"cosmic":0.015,"wind":0.65,"gust":0.7,"mode":3,"precip":0.72,"tint":Color(0.74,0.68,0.64,1),"grade":0.1,"next":["clear","overcast"]},
}
const DAY_KEYS := [
	{"hour":0.0,"ambient":Color(0.62,0.68,0.88,1),"directional":Color(0.52,0.64,1,1),"energy":0.2,"rotation":-12.0,"cosmic":0.025},
	{"hour":5.0,"ambient":Color(0.7,0.74,0.88,1),"directional":Color(0.66,0.72,0.94,1),"energy":0.28,"rotation":-28.0,"cosmic":0.015},
	{"hour":6.5,"ambient":Color(0.95,0.82,0.7,1),"directional":Color(1,0.72,0.54,1),"energy":0.58,"rotation":-34.0,"cosmic":0.005},
	{"hour":8.0,"ambient":Color(1,0.98,0.94,1),"directional":Color(1,0.96,0.9,1),"energy":0.92,"rotation":-20.0,"cosmic":0.0},
	{"hour":12.0,"ambient":Color(1.04,1.03,1,1),"directional":Color(1,1,0.98,1),"energy":1.0,"rotation":0.0,"cosmic":0.0},
	{"hour":17.0,"ambient":Color(1,0.91,0.8,1),"directional":Color(1,0.78,0.6,1),"energy":0.84,"rotation":24.0,"cosmic":0.0},
	{"hour":18.5,"ambient":Color(0.9,0.72,0.66,1),"directional":Color(1,0.58,0.43,1),"energy":0.52,"rotation":34.0,"cosmic":0.005},
	{"hour":20.0,"ambient":Color(0.72,0.68,0.8,1),"directional":Color(0.64,0.66,0.92,1),"energy":0.3,"rotation":24.0,"cosmic":0.015},
	{"hour":22.0,"ambient":Color(0.64,0.68,0.86,1),"directional":Color(0.54,0.64,1,1),"energy":0.22,"rotation":0.0,"cosmic":0.022},
	{"hour":24.0,"ambient":Color(0.62,0.68,0.88,1),"directional":Color(0.52,0.64,1,1),"energy":0.2,"rotation":-12.0,"cosmic":0.025},
]

@export_range(60.0,7200.0,1.0) var day_length_seconds := 1440.0
@export var clock_enabled := true
@export_range(0.1,10.0,0.1) var indoor_transition_seconds := 1.25
@onready var lighting_director := get_node_or_null("../WorldLightingDirector") as WorldLightingDirector
@onready var operator := get_node_or_null("../Operator") as Node2D
var current_hour := 9.0
var _active_map: ProcGenTilemap
var _world_profile := {}
var _environment_seed := 0
var _weather_rng := RandomNumberGenerator.new()
var _weather_current := "clear"
var _weather_target := "clear"
var _weather_hold_remaining := 0.0
var _weather_transition_elapsed := 0.0
var _weather_transition_duration := 0.0
var _weather_transitioning := false
var _environment_exposure := 1.0
var _weather_exposure := 1.0
var _observatory_accum := 0.0
var _last_wind_speed_multiplier := -1.0
var _last_gust_multiplier := -1.0

func _ready() -> void: add_to_group("world_environment_director")

func _physics_process(delta: float) -> void:
	advance_environment(delta)
	_observatory_accum += delta
	if _observatory_accum >= 0.5: _observatory_accum = 0.0; _publish_gauges()

func advance_environment(delta: float) -> void:
	if clock_enabled: current_hour = fposmod(current_hour + delta * 24.0 / maxf(day_length_seconds,1.0),24.0); time_changed.emit(current_hour)
	_update_weather(delta)
	var region := _resolve_environment_region()
	var blend_step := delta / maxf(indoor_transition_seconds, 0.01)
	_environment_exposure = move_toward(_environment_exposure, float(region.get("environment_exposure", 1.0)), blend_step)
	_weather_exposure = move_toward(_weather_exposure, float(region.get("weather_exposure", 1.0)), blend_step)
	_apply_environment()

func configure_from_contract(contract: Dictionary, map_instance: Node) -> void:
	_world_profile = (contract.get("world_profile",{}) as Dictionary).duplicate(true)
	_active_map = map_instance as ProcGenTilemap if map_instance is ProcGenTilemap else null
	var map_block: Dictionary = contract.get("map",{})
	_environment_seed = int(contract.get("contract_seed",0)) ^ (int(map_block.get("map_seed",0))*1103515245) ^ (int(_world_profile.get("profile_seed",0))*214013)
	var start_rng := RandomNumberGenerator.new(); start_rng.seed = _environment_seed ^ 0x571D4E91
	current_hour = start_rng.randf_range(float(_world_profile.get("day_start_hour_min",7.5)),float(_world_profile.get("day_start_hour_max",10.0)))
	_weather_rng.seed = _environment_seed ^ 0x24681357; _weather_current = _pick_weighted_weather(); _weather_target = _weather_current
	_weather_transitioning = false; _weather_hold_remaining = _weather_rng.randf_range(90.0,240.0)
	var region := _resolve_environment_region()
	_environment_exposure = float(region.get("environment_exposure", 1.0)); _weather_exposure = float(region.get("weather_exposure", 1.0)); _apply_environment(); weather_changed.emit(_weather_current)

func _update_weather(delta: float) -> void:
	if _world_profile.is_empty(): return
	if _weather_transitioning:
		_weather_transition_elapsed += delta
		if _weather_transition_elapsed >= _weather_transition_duration:
			_weather_current = _weather_target; _weather_transitioning = false; _weather_hold_remaining = _weather_rng.randf_range(90.0,240.0); weather_changed.emit(_weather_current)
		return
	_weather_hold_remaining -= delta
	if _weather_hold_remaining > 0.0: return
	_weather_target = _pick_next_weather(_weather_current)
	if _weather_target == _weather_current: _weather_hold_remaining = _weather_rng.randf_range(90.0,240.0); return
	_weather_transitioning = true; _weather_transition_elapsed = 0.0; _weather_transition_duration = _weather_rng.randf_range(8.0,15.0)

func _pick_weighted_weather() -> String:
	var weights: Dictionary = _world_profile.get("weather_weights",{"clear":1.0}); var candidates: Array[String] = []
	for value in weights:
		var key := String(value)
		if WEATHER_DEFS.has(key): candidates.append(key)
	candidates.sort(); return _pick(candidates,weights,"clear")

func _pick_next_weather(current: String) -> String:
	var weights: Dictionary = _world_profile.get("weather_weights",{"clear":1.0}); var allowed: Array[String] = []
	for value in (WEATHER_DEFS.get(current,WEATHER_DEFS.clear) as Dictionary).next:
		var key := String(value)
		if float(weights.get(key,0.0)) > 0.0: allowed.append(key)
	return _pick(allowed,weights,current) if not allowed.is_empty() else _pick_weighted_weather()

func _pick(candidates: Array[String], weights: Dictionary, fallback: String) -> String:
	var total := 0.0
	for key in candidates: total += maxf(0.0,float(weights.get(key,0.0)))
	if total <= 0.0: return fallback
	var roll := _weather_rng.randf()*total; var running := 0.0
	for key in candidates:
		running += maxf(0.0,float(weights.get(key,0.0)))
		if roll <= running: return key
	return candidates.back()

func _resolve_environment_region() -> Dictionary:
	if not is_inside_tree() or operator == null or not is_instance_valid(operator):
		return _exterior_region()
	for provider in get_tree().get_nodes_in_group("environment_region_provider"):
		if provider == null or not provider.has_method("get_environment_region_at_global"):
			continue
		var region := provider.call("get_environment_region_at_global", operator.global_position) as Dictionary
		if bool(region.get("contains", false)):
			return region
	return _exterior_region()


func _exterior_region() -> Dictionary:
	return {
		"contains": true,
		"indoor": false,
		"environment_exposure": 1.0,
		"weather_exposure": 1.0,
	}

func _exposure_for_indoor(is_indoor: bool) -> float:
	return 0.12 if is_indoor else 1.0

func _sample_day(hour: float) -> Dictionary:
	for index in DAY_KEYS.size()-1:
		var left: Dictionary = DAY_KEYS[index]; var right: Dictionary = DAY_KEYS[index+1]
		if hour < float(left.hour) or hour > float(right.hour): continue
		var t := inverse_lerp(float(left.hour),float(right.hour),hour)
		return {"ambient_multiplier":(left.ambient as Color).lerp(right.ambient,t),"directional_multiplier":(left.directional as Color).lerp(right.directional,t),"directional_energy_multiplier":lerpf(left.energy,right.energy,t),"directional_rotation_offset":lerpf(left.rotation,right.rotation,t),"cosmic_add":lerpf(left.cosmic,right.cosmic,t),"fog_add":0.0}
	return {}

func _sample_weather() -> Dictionary:
	var source: Dictionary = WEATHER_DEFS.get(_weather_current,WEATHER_DEFS.clear)
	if not _weather_transitioning: return _weather_modifier(source)
	var target: Dictionary = WEATHER_DEFS.get(_weather_target,source); var t := clampf(_weather_transition_elapsed/maxf(_weather_transition_duration,0.001),0.0,1.0)
	var result := {}
	for key in ["energy","fog","cosmic","wind","gust","precip","grade"]: result[key] = lerpf(float(source[key]),float(target[key]),t)
	result.ambient = (source.ambient as Color).lerp(target.ambient,t); result.directional = (source.directional as Color).lerp(target.directional,t); result.tint = (source.tint as Color).lerp(target.tint,t); result.mode = target.mode if t >= 0.25 else source.mode
	return _weather_modifier(result)

func _weather_modifier(definition: Dictionary) -> Dictionary:
	return {"ambient_multiplier":definition.ambient,"directional_multiplier":definition.directional,"directional_energy_multiplier":definition.energy,"fog_add":definition.fog,"cosmic_add":definition.cosmic,"wind_speed_multiplier":definition.wind,"gust_multiplier":definition.gust,"precipitation_mode":definition.mode,"precipitation_intensity":definition.precip,"weather_tint":definition.tint,"weather_grade_mix":definition.grade}

func _apply_environment() -> void:
	if lighting_director == null: return
	var day := _sample_day(current_hour); day.local_exposure = _environment_exposure
	var weather := _sample_weather(); weather.local_exposure = _weather_exposure
	lighting_director.set_environment_modifiers(day,weather)
	var wind_speed := float(weather.wind_speed_multiplier); var gust := float(weather.gust_multiplier)
	if _active_map != null and (not is_equal_approx(wind_speed,_last_wind_speed_multiplier) or not is_equal_approx(gust,_last_gust_multiplier)):
		_active_map.set_environment_wind_multipliers(wind_speed,gust)
		_last_wind_speed_multiplier = wind_speed; _last_gust_multiplier = gust
	environment_state_changed.emit(debug_get_state())

func get_presentation_state() -> Dictionary:
	var weather := _sample_weather(); var influence := lighting_director.get_active_weather_influence() if lighting_director != null else 1.0
	return {"hour":current_hour,"weather_id":StringName(_weather_target if _weather_transitioning else _weather_current),"precipitation_mode":int(weather.get("precipitation_mode",0)),"precipitation_alpha":clampf(float(weather.get("precipitation_intensity",0.0))*_weather_exposure*influence,0.0,1.0),"weather_tint":weather.get("weather_tint",Color.WHITE),"weather_grade_mix":float(weather.get("weather_grade_mix",0.0))*_weather_exposure*influence,"wind_speed_multiplier":weather.get("wind_speed_multiplier",1.0),"gust_multiplier":weather.get("gust_multiplier",1.0),"local_exposure":_environment_exposure,"environment_exposure":_environment_exposure,"weather_exposure":_weather_exposure}

func debug_set_hour(hour: float) -> void: current_hour = fposmod(hour,24.0); _apply_environment()
func debug_set_time_paused(paused: bool) -> void: clock_enabled = not paused
func debug_force_weather(weather_id: String) -> void:
	if not WEATHER_DEFS.has(weather_id): push_error("Unknown weather id: %s" % weather_id); return
	_weather_current = weather_id; _weather_target = weather_id; _weather_transitioning = false; _weather_hold_remaining = _weather_rng.randf_range(90.0,240.0); _apply_environment(); weather_changed.emit(weather_id)
func debug_get_state() -> Dictionary:
	var result := get_presentation_state(); result.merge({"environment_seed":_environment_seed,"weather_current":_weather_current,"weather_target":_weather_target,"weather_transitioning":_weather_transitioning,"weather_hold_remaining":_weather_hold_remaining},true); return result

func _publish_gauges() -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null or not observatory.has_method("set_gauge"): return
	var state := get_presentation_state(); observatory.call("set_gauge",&"world_environment_hour",current_hour); observatory.call("set_gauge",&"world_environment_weather_id",String(state.weather_id)); observatory.call("set_gauge",&"world_environment_precipitation_alpha",state.precipitation_alpha); observatory.call("set_gauge",&"world_environment_local_exposure",_environment_exposure)
