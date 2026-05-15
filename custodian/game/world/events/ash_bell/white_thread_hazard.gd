class_name WhiteThreadHazard
extends Area2D

@export var site_path: NodePath
@export var slow_multiplier: float = 0.88
@export var tension_tick_interval: float = 0.75

@onready var site: BellKneelerSite = get_node_or_null(site_path)

var _bodies_inside: Dictionary = {}
var _tick_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_tick_timer = maxf(0.0, _tick_timer - delta)
	for body_variant in _bodies_inside.keys():
		var body := body_variant as Node
		if body == null or not is_instance_valid(body):
			_bodies_inside.erase(body_variant)
			continue
		if not body.is_in_group("player"):
			continue
		if _tick_timer <= 0.0 and site != null:
			site.player_crossed_thread(_infer_move_kind(body))
		_apply_slow(body)
	if _tick_timer <= 0.0:
		_tick_timer = tension_tick_interval


func _on_body_entered(body: Node) -> void:
	_bodies_inside[body] = true


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
	if body.has_method("apply_external_speed_multiplier"):
		body.call("apply_external_speed_multiplier", slow_multiplier, 0.15)
