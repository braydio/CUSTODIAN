class_name WhiteThreadHazard
extends Area2D

@export var site_path: NodePath
@export var slow_multiplier: float = 0.88
@export_range(0, 100, 1) var slow_tension_threshold: int = 60
@export var tension_tick_interval: float = 0.75

## Optional child/node visual for the actual white thread line.
@export var thread_visual_path: NodePath
@export var telegraph_left_path: NodePath
@export var telegraph_right_path: NodePath

## Small immediate penalty when first entering the thread.
@export var entry_tension_amount: int = 1

@onready var site: ForlornRitualantSite = get_node_or_null(site_path)
@onready var thread_visual: CanvasItem = get_node_or_null(thread_visual_path)
@onready var telegraph_left: EncounterHazardTelegraph2D = get_node_or_null(telegraph_left_path)
@onready var telegraph_right: EncounterHazardTelegraph2D = get_node_or_null(telegraph_right_path)

var _bodies_inside: Dictionary = {}
var _tick_timer: float = 0.0
var _visual_pulse: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()


func _physics_process(delta: float) -> void:
	if site != null and (
		site.is_encounter_resolving()
		or site.is_terminal_resolution()
	):
		_bodies_inside.clear()
		_visual_pulse = 0.0
		_update_visual(false)
		return
	if site != null and site.suppresses_encounter_hazards():
		# Discard stored cadence so dialogue cannot close into an immediate tick.
		_tick_timer = tension_tick_interval
		_visual_pulse = maxf(0.0, _visual_pulse - delta)
		_update_visual(false)
		return

	_tick_timer = maxf(0.0, _tick_timer - delta)
	_visual_pulse = maxf(0.0, _visual_pulse - delta)

	var player_inside := false

	for body_variant in _bodies_inside.keys():
		var body := body_variant as Node
		if body == null or not is_instance_valid(body):
			_bodies_inside.erase(body_variant)
			continue

		if not body.is_in_group("player"):
			continue

		player_inside = true

		if _tick_timer <= 0.0 and site != null:
			site.player_crossed_thread(_infer_move_kind(body))
			_visual_pulse = 0.18

		_apply_slow(body)

	if _tick_timer <= 0.0:
		_tick_timer = tension_tick_interval

	_update_visual(player_inside)


func _on_body_entered(body: Node) -> void:
	if site != null and (
		site.is_encounter_resolving()
		or site.is_terminal_resolution()
	):
		return
	_bodies_inside[body] = true

	if body != null \
	and body.is_in_group("player") \
	and site != null \
	and not site.suppresses_encounter_hazards():
		site.event_state.add_thread_tension(entry_tension_amount, &"thread_entry")
		_visual_pulse = 0.22


func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)


func _infer_move_kind(body: Node) -> StringName:
	if body.has_method("is_dodging") and bool(body.call("is_dodging")):
		return &"dodge"

	if "is_sprinting" in body and bool(body.get("is_sprinting")):
		return &"run"

	if body.has_method("is_sprinting") and bool(body.call("is_sprinting")):
		return &"run"

	return &"walk"


func _apply_slow(body: Node) -> void:
	if site == null or site.event_state == null:
		return
	if site.is_encounter_resolving() or site.is_terminal_resolution():
		return
	if site.event_state.thread_tension < slow_tension_threshold:
		return
	if body.has_method("apply_external_speed_multiplier"):
		body.call("apply_external_speed_multiplier", slow_multiplier, 0.15)


func _update_visual(player_inside: bool = false) -> void:
	_update_telegraphs(player_inside)
	if thread_visual == null:
		return
	thread_visual.visible = true

	var base_alpha := 0.45
	if site != null and site.event_state != null:
		var tension := clampf(float(site.event_state.thread_tension) / 100.0, 0.0, 1.0)
		base_alpha = lerpf(0.35, 0.95, tension)

	if player_inside:
		base_alpha = maxf(base_alpha, 0.82)

	if _visual_pulse > 0.0:
		base_alpha = 1.0

	thread_visual.modulate = Color(0.78, 0.88, 1.0, base_alpha)


func _update_telegraphs(player_inside: bool) -> void:
	var state := EncounterHazardTelegraph2D.State.DORMANT
	if site == null or site.event_state == null or site.suppresses_encounter_hazards():
		state = EncounterHazardTelegraph2D.State.SUPPRESSED
	elif site.event_state.thread_tension >= 60:
		state = EncounterHazardTelegraph2D.State.ACTIVE
	elif site.event_state.thread_tension >= 30 or player_inside:
		state = EncounterHazardTelegraph2D.State.WARNING
	for telegraph in [telegraph_left, telegraph_right]:
		if telegraph != null:
			telegraph.set_presentation_state(state)
