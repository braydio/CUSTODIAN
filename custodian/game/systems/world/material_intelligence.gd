extends Node

const DEFAULT_MATERIAL := &"unknown"

const PROFILE_DEFINITIONS := {
	&"unknown": {
		"display_name": "Unknown",
		"tags": [],
	},
	&"stone_dry": {
		"display_name": "Dry Stone",
		"tags": [&"hard", &"stone"],
		"footstep_sound_family": &"stone",
	},
	&"stone_wet": {
		"display_name": "Wet Stone",
		"tags": [&"hard", &"stone", &"wet"],
		"footstep_noise_mult": 1.08,
		"footstep_sound_family": &"stone_wet",
	},
	&"metal_rusted": {
		"display_name": "Rusted Metal",
		"tags": [&"hard", &"metal", &"loud"],
		"footstep_noise_mult": 1.25,
		"bullet_impact_fx": &"metal_spark",
		"melee_impact_fx": &"metal",
		"footstep_sound_family": &"metal",
	},
	&"metal_powered": {
		"display_name": "Powered Metal",
		"tags": [&"hard", &"metal", &"loud", &"powered"],
		"footstep_noise_mult": 1.25,
		"bullet_impact_fx": &"powered_metal_spark",
		"melee_impact_fx": &"metal",
		"footstep_sound_family": &"metal",
	},
	&"ash": {
		"display_name": "Ash",
		"tags": [&"soft", &"organic"],
		"footstep_noise_mult": 0.72,
		"footstep_sound_family": &"ash",
	},
	&"soil": {
		"display_name": "Soil",
		"tags": [&"soft", &"organic"],
		"footstep_noise_mult": 0.82,
		"footstep_sound_family": &"soil",
	},
	&"grass": {
		"display_name": "Grass",
		"tags": [&"soft", &"organic"],
		"footstep_noise_mult": 0.75,
		"footstep_sound_family": &"grass",
	},
	&"memory_glass": {
		"display_name": "Memory Glass",
		"tags": [&"hard", &"glass", &"strange"],
		"footstep_noise_mult": 1.15,
		"bullet_impact_fx": &"memory_glass",
		"melee_impact_fx": &"memory_glass",
		"footstep_sound_family": &"glass",
	},
	&"ruin_concrete": {
		"display_name": "Ruin Concrete",
		"tags": [&"hard", &"stone"],
		"bullet_impact_fx": &"stone_dust",
		"melee_impact_fx": &"stone",
		"footstep_sound_family": &"stone",
	},
	&"void_growth": {
		"display_name": "Void Growth",
		"tags": [&"organic", &"anomalous"],
		"footstep_noise_mult": 0.65,
		"stealth_visibility_mult": 0.9,
		"footstep_sound_family": &"void_growth",
	},
	&"wood_old": {
		"display_name": "Old Wood",
		"tags": [&"organic", &"wood"],
		"footstep_noise_mult": 1.1,
		"bullet_impact_fx": &"wood_chip",
		"melee_impact_fx": &"wood",
		"footstep_sound_family": &"wood",
	},
	&"shallow_water": {
		"display_name": "Shallow Water",
		"tags": [&"liquid", &"wet"],
		"footstep_noise_mult": 1.18,
		"stealth_visibility_mult": 1.1,
		"bullet_impact_fx": &"water_splash",
		"melee_impact_fx": &"water_splash",
		"footstep_sound_family": &"water",
	},
}

@export var default_cell_size_px := 64.0
@export var debug_logging_enabled := true
@export var profile_library: MaterialProfileLibrary

var material_overrides: Dictionary = {}
var material_counts: Dictionary = {}
var contact_counts_by_kind: Dictionary = {}
var contact_counts_by_material: Dictionary = {}
var total_contacts := 0
var _profile_library_ready := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_profile_library()
	if debug_logging_enabled:
		_log_event(&"material_intelligence_ready", {
			"default_cell_size_px": default_cell_size_px,
			"profile_count": profile_library.profiles.size(),
		})


func _exit_tree() -> void:
	if profile_library != null:
		profile_library.profiles.clear()
	profile_library = null
	_profile_library_ready = false


func get_material_id_at(world_position: Vector2) -> StringName:
	var key := _cell_key(_world_to_cell(world_position))
	return StringName(material_overrides.get(key, DEFAULT_MATERIAL))


func get_material_at(world_position: Vector2) -> MaterialProfile:
	_ensure_profile_library()
	return profile_library.get_profile(get_material_id_at(world_position))


func set_material_cell(cell: Vector2i, material_id: StringName) -> void:
	_ensure_profile_library()
	var profile := profile_library.get_profile(material_id)
	var resolved_id := profile.material_id if profile != null else DEFAULT_MATERIAL
	var key := _cell_key(cell)
	var previous_id := StringName(material_overrides.get(key, DEFAULT_MATERIAL))

	if previous_id == resolved_id and material_overrides.has(key):
		return

	if material_overrides.has(key):
		_decrement_material_count(previous_id)

	material_overrides[key] = resolved_id
	var count_key := String(resolved_id)
	material_counts[count_key] = int(material_counts.get(count_key, 0)) + 1


func set_material_at(
	world_position: Vector2,
	material_id: StringName
) -> void:
	set_material_cell(_world_to_cell(world_position), material_id)


func report_contact(
	world_position: Vector2,
	contact_kind: StringName,
	data: Dictionary = {}
) -> void:
	var profile := get_material_at(world_position)
	var material_id := (
		profile.material_id
		if profile != null
		else DEFAULT_MATERIAL
	)
	var kind_key := String(contact_kind)
	var material_key := String(material_id)

	total_contacts += 1
	contact_counts_by_kind[kind_key] = (
		int(contact_counts_by_kind.get(kind_key, 0)) + 1
	)
	contact_counts_by_material[material_key] = (
		int(contact_counts_by_material.get(material_key, 0)) + 1
	)

	var payload := data.duplicate(true)
	payload.merge({
		"contact_kind": kind_key,
		"material_id": material_key,
		"position": world_position,
		"footstep_noise_mult": (
			profile.footstep_noise_mult if profile != null else 1.0
		),
		"bullet_impact_fx": String(
			profile.bullet_impact_fx if profile != null else &"default"
		),
		"melee_impact_fx": String(
			profile.melee_impact_fx if profile != null else &"default"
		),
	}, true)

	_log_event(&"material_contact", payload)
	_heatmap_add(
		StringName("material_%s" % kind_key),
		0.25,
		world_position
	)


func get_summary() -> Dictionary:
	return {
		"schema": "custodian.material_intelligence.summary.v1",
		"default_cell_size_px": default_cell_size_px,
		"override_cell_count": material_overrides.size(),
		"material_counts": material_counts.duplicate(true),
		"total_contacts": total_contacts,
		"contact_counts_by_kind": contact_counts_by_kind.duplicate(true),
		"contact_counts_by_material": (
			contact_counts_by_material.duplicate(true)
		),
	}


func clear() -> void:
	material_overrides.clear()
	material_counts.clear()
	contact_counts_by_kind.clear()
	contact_counts_by_material.clear()
	total_contacts = 0


func _world_to_cell(position: Vector2) -> Vector2i:
	var cell_size := maxf(default_cell_size_px, 1.0)
	return Vector2i(
		floori(position.x / cell_size),
		floori(position.y / cell_size)
	)


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _ensure_profile_library() -> void:
	if profile_library != null:
		if _profile_library_ready:
			return
		profile_library.rebuild()
		if profile_library.get_profile(DEFAULT_MATERIAL) == null:
			var fallback := (
				MaterialProfile.new()
			)
			fallback.material_id = DEFAULT_MATERIAL
			fallback.display_name = "Unknown"
			profile_library.profiles.append(fallback)
			profile_library.rebuild()
		_profile_library_ready = true
		return

	profile_library = (
		MaterialProfileLibrary.new()
	)
	for material_id: StringName in PROFILE_DEFINITIONS:
		var definition := PROFILE_DEFINITIONS[material_id] as Dictionary
		var profile := MaterialProfile.new()
		profile.material_id = material_id
		profile.display_name = str(
			definition.get("display_name", "Unknown")
		)
		profile.footstep_noise_mult = float(
			definition.get("footstep_noise_mult", 1.0)
		)
		profile.stealth_visibility_mult = float(
			definition.get("stealth_visibility_mult", 1.0)
		)
		profile.bullet_impact_fx = StringName(
			definition.get("bullet_impact_fx", &"default")
		)
		profile.melee_impact_fx = StringName(
			definition.get("melee_impact_fx", &"default")
		)
		profile.footstep_sound_family = StringName(
			definition.get("footstep_sound_family", &"default")
		)
		var tags: Array[StringName] = []
		for tag: StringName in definition.get("tags", []):
			tags.append(tag)
		profile.tags = tags
		profile_library.profiles.append(profile)
	profile_library.rebuild()
	_profile_library_ready = true


func _decrement_material_count(material_id: StringName) -> void:
	var key := String(material_id)
	var remaining := int(material_counts.get(key, 0)) - 1
	if remaining > 0:
		material_counts[key] = remaining
	else:
		material_counts.erase(key)


func _log_event(
	kind: StringName,
	data: Dictionary = {}
) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", kind, data)


func _heatmap_add(
	event_type: StringName,
	weight: float,
	position: Vector2
) -> void:
	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap != null and heatmap.has_method("add"):
		heatmap.call("add", position, event_type, weight)
