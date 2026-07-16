extends Node2D
class_name WorldLightingDirector

const LightingProfileScript := preload("res://game/world/lighting/lighting_profile.gd")

signal lighting_profile_changed(profile: LightingProfile)
signal temporary_flash(color: Color, energy: float, duration: float)

@export var canvas_modulate_path: NodePath
@export var directional_light_path: NodePath
@export var default_profile: LightingProfile

@onready var canvas_modulate: CanvasModulate = get_node_or_null(canvas_modulate_path) as CanvasModulate
@onready var directional_light: DirectionalLight2D = get_node_or_null(directional_light_path) as DirectionalLight2D

var active_profile: LightingProfile = null
var cosmic_underlay_alpha: float = 0.0
var fog_alpha: float = 0.0

var _profile_tween: Tween = null
var _flash_tween: Tween = null
var _flash_energy: float = 0.0
var _zone_entries: Dictionary = {}


func _ready() -> void:
	add_to_group("world_lighting_director")
	if default_profile != null:
		apply_profile(default_profile, true)


func apply_profile(profile: LightingProfile, immediate: bool = false) -> void:
	if profile == null:
		return

	active_profile = profile
	if _profile_tween != null and _profile_tween.is_valid():
		_profile_tween.kill()

	var duration := 0.0 if immediate else maxf(0.0, profile.transition_seconds)
	if duration <= 0.0:
		_apply_profile_values(profile)
	else:
		_profile_tween = create_tween()
		_profile_tween.set_parallel(true)
		if canvas_modulate != null:
			_profile_tween.tween_property(canvas_modulate, "color", profile.ambient_color, duration)
		if directional_light != null:
			_profile_tween.tween_property(directional_light, "color", profile.directional_color, duration)
			_profile_tween.tween_property(directional_light, "energy", profile.directional_energy, duration)
			_profile_tween.tween_property(directional_light, "rotation_degrees", profile.directional_rotation_degrees, duration)
		_profile_tween.tween_property(self, "cosmic_underlay_alpha", profile.cosmic_underlay_alpha, duration)
		_profile_tween.tween_property(self, "fog_alpha", profile.fog_alpha, duration)

	lighting_profile_changed.emit(profile)


func apply_world_profile_overrides(world_profile: Dictionary, immediate: bool = false) -> void:
	var source_profile := active_profile if active_profile != null else default_profile
	if source_profile == null or world_profile.is_empty():
		return
	var resolved := source_profile.duplicate(true) as LightingProfile
	resolved.fog_alpha = clampf(
		float(world_profile.get("fog_alpha", resolved.fog_alpha)),
		0.0,
		0.5
	)
	resolved.cosmic_underlay_alpha = clampf(
		float(world_profile.get("cosmic_underlay_alpha", resolved.cosmic_underlay_alpha)),
		0.0,
		0.5
	)
	apply_profile(resolved, immediate)


func push_temporary_flash(color: Color, energy: float, duration: float) -> void:
	if duration <= 0.0 or energy <= 0.0:
		return

	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	_flash_energy = energy
	_apply_flash_to_ambient(color, energy)
	temporary_flash.emit(color, energy, duration)

	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "_flash_energy", 0.0, duration)
	_flash_tween.tween_callback(_restore_active_profile_values)


func push_zone_profile(zone: Node, profile: LightingProfile, priority: int = 0, immediate: bool = false) -> void:
	if zone == null or profile == null:
		return
	_zone_entries[zone.get_instance_id()] = {
		"profile": profile,
		"priority": priority,
		"order": Time.get_ticks_msec(),
	}
	_apply_highest_priority_zone(immediate)


func pop_zone_profile(zone: Node, immediate: bool = false) -> void:
	if zone == null:
		return
	_zone_entries.erase(zone.get_instance_id())
	_apply_highest_priority_zone(immediate)


func _apply_profile_values(profile: LightingProfile) -> void:
	if canvas_modulate != null:
		canvas_modulate.color = profile.ambient_color
	if directional_light != null:
		directional_light.color = profile.directional_color
		directional_light.energy = profile.directional_energy
		directional_light.rotation_degrees = profile.directional_rotation_degrees
	cosmic_underlay_alpha = profile.cosmic_underlay_alpha
	fog_alpha = profile.fog_alpha


func _apply_flash_to_ambient(color: Color, energy: float) -> void:
	if canvas_modulate == null:
		return
	var base_color := active_profile.ambient_color if active_profile != null else canvas_modulate.color
	canvas_modulate.color = base_color.lerp(color, clampf(energy, 0.0, 1.0))


func _restore_active_profile_values() -> void:
	if active_profile != null:
		_apply_profile_values(active_profile)


func _apply_highest_priority_zone(immediate: bool = false) -> void:
	var best_profile := default_profile
	var best_priority := -2147483648
	var best_order := -1

	for entry_variant in _zone_entries.values():
		if not (entry_variant is Dictionary):
			continue
		var entry := entry_variant as Dictionary
		var priority := int(entry.get("priority", 0))
		var order := int(entry.get("order", 0))
		if priority > best_priority or (priority == best_priority and order >= best_order):
			best_priority = priority
			best_order = order
			best_profile = entry.get("profile", default_profile) as LightingProfile

	if best_profile != null:
		apply_profile(best_profile, immediate)
