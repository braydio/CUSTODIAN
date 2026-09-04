extends Node2D
class_name WorldLightingDirector

signal lighting_profile_changed(profile: LightingProfile)
signal temporary_flash(color: Color, energy: float, duration: float)

@export var canvas_modulate_path: NodePath
@export var directional_light_path: NodePath
@export var default_profile: LightingProfile
@onready var canvas_modulate := get_node_or_null(canvas_modulate_path) as CanvasModulate
@onready var directional_light := get_node_or_null(directional_light_path) as DirectionalLight2D

var active_profile: LightingProfile
var cosmic_underlay_alpha := 0.0
var fog_alpha := 0.0
var resolved_ambient_color := Color.WHITE
var resolved_directional_color := Color.WHITE
var resolved_directional_energy := 1.0
var resolved_directional_rotation_degrees := 0.0
var _world_profile_overrides := {}
var _day_modifier := {}
var _weather_modifier := {}
var _base_ambient_color := Color.WHITE
var _base_directional_color := Color.WHITE
var _base_directional_energy := 1.0
var _base_directional_rotation_degrees := 0.0
var _base_cosmic_underlay_alpha := 0.0
var _base_fog_alpha := 0.0
var _profile_tween: Tween
var _flash_tween: Tween
var _flash_energy := 0.0
var _flash_color := Color.WHITE
var _zone_entries := {}

func _ready() -> void:
	add_to_group("world_lighting_director")
	if directional_light != null: directional_light.add_to_group("render_directional_light")
	if default_profile != null: apply_profile(default_profile, true)

func apply_profile(profile: LightingProfile, immediate := false) -> void:
	if profile == null: return
	active_profile = profile
	if _profile_tween != null and _profile_tween.is_valid(): _profile_tween.kill()
	var target := _profile_values(profile)
	var duration := 0.0 if immediate else maxf(0.0, profile.transition_seconds)
	if duration <= 0.0: _set_base_values(target)
	else:
		var source := _current_base_values()
		_profile_tween = create_tween()
		_profile_tween.tween_method(_apply_base_lerp.bind(source, target), 0.0, 1.0, duration)
	lighting_profile_changed.emit(profile)

func apply_world_profile_overrides(world_profile: Dictionary, _immediate := false) -> void:
	if world_profile.is_empty(): return
	_world_profile_overrides = world_profile.duplicate(true)
	_apply_composite_values()

func set_environment_modifiers(day_modifier: Dictionary, weather_modifier: Dictionary) -> void:
	_day_modifier = day_modifier.duplicate(true); _weather_modifier = weather_modifier.duplicate(true); _apply_composite_values()

func get_active_environment_influence() -> float: return active_profile.environment_influence if active_profile != null else 1.0
func get_active_weather_influence() -> float: return active_profile.weather_influence if active_profile != null else 1.0

func push_temporary_flash(color: Color, energy: float, duration: float) -> void:
	if duration <= 0.0 or energy <= 0.0: return
	if _flash_tween != null and _flash_tween.is_valid(): _flash_tween.kill()
	_flash_color = color; _flash_energy = energy; _apply_composite_values(); temporary_flash.emit(color, energy, duration)
	_flash_tween = create_tween(); _flash_tween.tween_method(_set_flash_energy, energy, 0.0, duration)

func push_zone_profile(zone: Node, profile: LightingProfile, priority := 0, immediate := false) -> void:
	if zone == null or profile == null: return
	_zone_entries[zone.get_instance_id()] = {"profile":profile,"priority":priority,"order":Time.get_ticks_msec()}; _apply_highest_priority_zone(immediate)

func pop_zone_profile(zone: Node, immediate := false) -> void:
	if zone == null: return
	_zone_entries.erase(zone.get_instance_id()); _apply_highest_priority_zone(immediate)

func _profile_values(profile: LightingProfile) -> Dictionary:
	return {"ambient":profile.ambient_color,"directional":profile.directional_color,"energy":profile.directional_energy,"rotation":profile.directional_rotation_degrees,"cosmic":profile.cosmic_underlay_alpha,"fog":profile.fog_alpha}

func _current_base_values() -> Dictionary:
	return {"ambient":_base_ambient_color,"directional":_base_directional_color,"energy":_base_directional_energy,"rotation":_base_directional_rotation_degrees,"cosmic":_base_cosmic_underlay_alpha,"fog":_base_fog_alpha}

func _apply_base_lerp(t: float, source: Dictionary, target: Dictionary) -> void:
	_set_base_values({"ambient":(source.ambient as Color).lerp(target.ambient, t),"directional":(source.directional as Color).lerp(target.directional, t),"energy":lerpf(source.energy,target.energy,t),"rotation":lerpf(source.rotation,target.rotation,t),"cosmic":lerpf(source.cosmic,target.cosmic,t),"fog":lerpf(source.fog,target.fog,t)})

func _set_base_values(values: Dictionary) -> void:
	_base_ambient_color = values.ambient; _base_directional_color = values.directional; _base_directional_energy = values.energy
	_base_directional_rotation_degrees = values.rotation; _base_cosmic_underlay_alpha = values.cosmic; _base_fog_alpha = values.fog; _apply_composite_values()

func _apply_composite_values() -> void:
	var day_amount := float(_day_modifier.get("local_exposure", 1.0)) * get_active_environment_influence()
	var weather_amount := float(_weather_modifier.get("local_exposure", 1.0)) * get_active_weather_influence()
	var day_ambient: Color = _day_modifier.get("ambient_multiplier", Color.WHITE); var day_directional: Color = _day_modifier.get("directional_multiplier", Color.WHITE)
	var weather_ambient: Color = _weather_modifier.get("ambient_multiplier", Color.WHITE); var weather_directional: Color = _weather_modifier.get("directional_multiplier", Color.WHITE)
	resolved_ambient_color = _multiply_color(_multiply_color(_base_ambient_color, Color.WHITE.lerp(day_ambient, day_amount)), Color.WHITE.lerp(weather_ambient, weather_amount))
	resolved_directional_color = _multiply_color(_multiply_color(_base_directional_color, Color.WHITE.lerp(day_directional, day_amount)), Color.WHITE.lerp(weather_directional, weather_amount))
	resolved_directional_energy = _base_directional_energy * lerpf(1.0, float(_day_modifier.get("directional_energy_multiplier",1.0)),day_amount) * lerpf(1.0,float(_weather_modifier.get("directional_energy_multiplier",1.0)),weather_amount)
	resolved_directional_rotation_degrees = _base_directional_rotation_degrees + float(_day_modifier.get("directional_rotation_offset",0.0)) * day_amount
	var climate_fog := float(_world_profile_overrides.get("fog_alpha",_base_fog_alpha)); var climate_cosmic := float(_world_profile_overrides.get("cosmic_underlay_alpha",_base_cosmic_underlay_alpha))
	fog_alpha = clampf(climate_fog + float(_day_modifier.get("fog_add",0.0))*day_amount + float(_weather_modifier.get("fog_add",0.0))*weather_amount,0.0,0.5)
	cosmic_underlay_alpha = clampf(climate_cosmic + float(_day_modifier.get("cosmic_add",0.0))*day_amount + float(_weather_modifier.get("cosmic_add",0.0))*weather_amount,0.0,1.0)
	if canvas_modulate != null: canvas_modulate.color = resolved_ambient_color.lerp(_flash_color,clampf(_flash_energy,0.0,1.0))
	if directional_light != null: directional_light.color = resolved_directional_color; directional_light.energy = resolved_directional_energy; directional_light.rotation_degrees = resolved_directional_rotation_degrees

func _multiply_color(a: Color, b: Color) -> Color: return Color(a.r*b.r,a.g*b.g,a.b*b.b,a.a*b.a)
func _set_flash_energy(value: float) -> void: _flash_energy = value; _apply_composite_values()

func _apply_highest_priority_zone(immediate := false) -> void:
	var best := default_profile; var best_priority := -2147483648; var best_order := -1
	for value in _zone_entries.values():
		var entry := value as Dictionary; var priority := int(entry.get("priority",0)); var order := int(entry.get("order",0))
		if priority > best_priority or (priority == best_priority and order >= best_order): best_priority = priority; best_order = order; best = entry.get("profile",default_profile)
	if best != null: apply_profile(best, immediate)
