extends Node2D

const VAULTWING_SCENE := preload("res://game/actors/ambient/vaultwing/vaultwing.tscn")

var vaultwing: Vaultwing
var operator: StaticBody2D
var dive_committed := false
var operator_moved_after_commit := false
var air_stagger_seen := false
var grounded_seen := false
var climb_out_seen := false

var vaultwing_state: StringName:
	get: return vaultwing.get_state_name() if is_instance_valid(vaultwing) else &"missing"
var vaultwing_band: StringName:
	get: return vaultwing.get_altitude_band_name() if is_instance_valid(vaultwing) else &"missing"

func _ready() -> void:
	operator = StaticBody2D.new()
	operator.name = "Operator"
	operator.position = Vector2(760, 360)
	operator.add_to_group("player")
	var operator_shape := CollisionShape2D.new()
	var operator_circle := CircleShape2D.new()
	operator_circle.radius = 14.0
	operator_shape.shape = operator_circle
	operator.add_child(operator_shape)
	add_child(operator)
	vaultwing = VAULTWING_SCENE.instantiate() as Vaultwing
	vaultwing.name = "Vaultwing"
	vaultwing.position = Vector2(460, 360)
	vaultwing.set_ambient_seed(4401)
	add_child(vaultwing)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(vaultwing): return
	var state := vaultwing.get_state_name()
	if state == &"dive_windup": dive_committed = true
	if state == &"air_stagger": air_stagger_seen = true
	if state == &"climb_out": climb_out_seen = true
	if vaultwing.get_altitude_band_name() in [&"ground", &"perched"]: grounded_seen = true
	queue_redraw()

func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if command.ends_with("/start_dive"): command = "start_dive"
	elif command.ends_with("/sidestep_operator"): command = "sidestep_operator"
	elif command.ends_with("/interrupt_dive"): command = "interrupt_dive"
	match command:
		"start_dive":
			vaultwing.request_dive(operator.global_position, operator)
			return true
		"sidestep_operator":
			operator.position += Vector2(0, 180)
			operator_moved_after_commit = true
			return true
		"interrupt_dive":
			vaultwing.take_damage(20.0)
			return true
	return false

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("10151c"))
	draw_rect(Rect2(0, 420, 1280, 300), Color("292821"))
	draw_circle(Vector2(460, 360), 28.0, Color(0.15, 0.25, 0.32, 0.35))
