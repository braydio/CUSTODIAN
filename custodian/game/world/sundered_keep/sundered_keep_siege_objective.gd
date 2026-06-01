extends Damageable
class_name SunderedKeepSiegeObjective

@export var objective_id: String = ""
@export var display_name: String = "Objective"
@export var objective_group: String = "command_post"
@export var objective_radius: float = 18.0

var last_damage_source: String = ""

var _status_label: Label = null
var _health_bar: ProgressBar = null
var _visual: ColorRect = null


func _ready() -> void:
	add_to_group("structure")
	if not objective_group.is_empty():
		add_to_group(objective_group)
	_build_visuals()
	super._ready()
	_refresh_visuals()


func configure(id: String, label: String, group_name: String, hp: float) -> void:
	objective_id = id
	display_name = label
	objective_group = group_name
	max_health = maxf(1.0, hp)
	current_health = max_health


func take_damage(amount: float) -> void:
	last_damage_source = "siege_pressure"
	super.take_damage(amount)
	_refresh_visuals()


func repair(amount: float) -> void:
	super.repair(amount)
	_refresh_visuals()


func get_objective_status() -> Dictionary:
	return {
		"id": objective_id,
		"name": display_name,
		"group": objective_group,
		"hp": current_health,
		"max_hp": max_health,
		"state": state,
		"efficiency": get_efficiency(),
		"last_damage_source": last_damage_source,
	}


func _build_visuals() -> void:
	_visual = ColorRect.new()
	_visual.name = "ObjectiveMarker"
	_visual.offset_left = -objective_radius
	_visual.offset_top = -objective_radius
	_visual.offset_right = objective_radius
	_visual.offset_bottom = objective_radius
	_visual.color = Color(0.15, 0.55, 0.95, 0.42)
	add_child(_visual)

	_health_bar = ProgressBar.new()
	_health_bar.name = "HealthBar"
	_health_bar.show_percentage = false
	_health_bar.min_value = 0.0
	_health_bar.max_value = 100.0
	_health_bar.offset_left = -42.0
	_health_bar.offset_top = -34.0
	_health_bar.offset_right = 42.0
	_health_bar.offset_bottom = -24.0
	add_child(_health_bar)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.offset_left = -82.0
	_status_label.offset_top = -56.0
	_status_label.offset_right = 82.0
	_status_label.offset_bottom = -36.0
	add_child(_status_label)


func _on_state_changed(_new_state: String) -> void:
	_refresh_visuals()


func _refresh_visuals() -> void:
	if _health_bar != null:
		_health_bar.value = get_efficiency() * 100.0
	if _status_label != null:
		_status_label.text = "%s %s%%" % [display_name, int(round(get_efficiency() * 100.0))]
	if _visual == null:
		return
	match state:
		"operational":
			_visual.color = Color(0.15, 0.55, 0.95, 0.42)
		"damaged":
			_visual.color = Color(0.95, 0.74, 0.18, 0.48)
		"critical":
			_visual.color = Color(1.0, 0.28, 0.16, 0.58)
		"destroyed":
			_visual.color = Color(0.18, 0.05, 0.04, 0.72)
		_:
			_visual.color = Color(0.15, 0.55, 0.95, 0.42)
