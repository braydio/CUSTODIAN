extends Node2D

const VAULTWING_SCENE := preload("res://game/actors/ambient/vaultwing/vaultwing.tscn")
const BondState := preload("res://game/actors/ambient/vaultwing/vaultwing_bond_state.gd")
const Allegiance := preload("res://game/actors/core/actor_allegiance_component.gd")

class MomentTarget extends StaticBody2D:
	var hits := 0
	func receive_enemy_hit(amount: float, _kind: StringName = &"melee", _team: String = "enemy", _attacker: Node2D = null, _direction: Vector2 = Vector2.ZERO, _guard: float = -1.0, _context: Dictionary = {}) -> Dictionary:
		hits += 1
		return {"applied_damage": amount}

var vaultwing: Vaultwing
var operator: MomentTarget
var dive_committed := false
var operator_moved_after_commit := false
var air_stagger_seen := false
var grounded_seen := false
var climb_out_seen := false
var guarded_observation_seen := false
var controlled_approach_seen := false
var bond_trial_started := false
var bond_completed := false
var bond_completion_count := 0
var bond_same_actor := false
var hostile_attack_during_trial := false
var operator_targetable_after_bond := true
var _bond_actor_id := 0
var _bond_behavior_id := 0
var bait_morsel: Polygon2D

var dive_hit_count: int:
	get: return vaultwing.behavior.dive_hit_count if is_instance_valid(vaultwing) else 0
var dive_miss_count: int:
	get: return vaultwing.behavior.dive_miss_count if is_instance_valid(vaultwing) else 0
var dive_vector: Vector2:
	get: return vaultwing.behavior.strike_vector if is_instance_valid(vaultwing) else Vector2.ZERO
var dive_vector_x: float:
	get: return dive_vector.x
var dive_vector_y: float:
	get: return dive_vector.y

var vaultwing_state: StringName:
	get: return vaultwing.get_state_name() if is_instance_valid(vaultwing) else &"missing"
var vaultwing_band: StringName:
	get: return vaultwing.get_altitude_band_name() if is_instance_valid(vaultwing) else &"missing"
var vaultwing_stage: StringName:
	get: return vaultwing.get_bond_stage() if is_instance_valid(vaultwing) else &"missing"
var trial_phase: StringName:
	get: return vaultwing.get_bond_state().trial_phase if is_instance_valid(vaultwing) else &""
var vaultwing_allegiance: StringName:
	get: return vaultwing.get_allegiance() if is_instance_valid(vaultwing) else &"missing"

func _ready() -> void:
	operator = MomentTarget.new()
	operator.name = "Operator"
	operator.position = Vector2(760, 360)
	operator.add_to_group("player")
	var operator_shape := CollisionShape2D.new()
	var operator_circle := CircleShape2D.new()
	operator_circle.radius = 14.0
	operator_shape.shape = operator_circle
	operator.add_child(operator_shape)
	add_child(operator)
	_add_operator_visual()
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
	if is_instance_valid(vaultwing):
		guarded_observation_seen = guarded_observation_seen or vaultwing.get_bond_state().trial_phase == &"guarded_observation"
		if vaultwing.get_bond_state().bond_trial_active and state in [&"dive_windup", &"dive_strike", &"ground_attack"]:
			hostile_attack_during_trial = true
		if vaultwing.get_bond_stage() == BondState.BONDED:
			bond_same_actor = vaultwing.get_instance_id() == _bond_actor_id and vaultwing.behavior.get_instance_id() == _bond_behavior_id
			operator_targetable_after_bond = vaultwing.is_combat_targetable_by(operator, &"player")
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
		"begin_trial":
			vaultwing.get_bond_state().call("_set_stage", BondState.ACCEPTING)
			vaultwing.behavior.profile = vaultwing.behavior.profile.duplicate()
			vaultwing.behavior.profile.patrol_speed = 100.0
			_bond_actor_id = vaultwing.get_instance_id()
			_bond_behavior_id = vaultwing.behavior.get_instance_id()
			vaultwing.get_bond_state().bond_completed.connect(_on_bond_completed)
			bait_morsel.visible = true
			bond_trial_started = vaultwing.begin_bond_trial_with(operator)
			return bond_trial_started
		"controlled_approach":
			operator.global_position = vaultwing.global_position + Vector2(100, 0)
			controlled_approach_seen = true
			return true
		"final_feed":
			operator.global_position = vaultwing.global_position + Vector2(54, 0)
			bond_completed = vaultwing.complete_bond_trial(&"vaultwing_bait", operator)
			bait_morsel.visible = false
			return bond_completed
		"finish":
			return true
	return false

func _on_bond_completed() -> void:
	bond_completion_count += 1

func _add_operator_visual() -> void:
	var visual := Node2D.new()
	visual.name = "OperatorMomentSilhouette"
	visual.z_index = 5
	visual.z_as_relative = false
	operator.add_child(visual)
	_add_polygon(visual, PackedVector2Array([Vector2(-9,-31), Vector2(9,-31), Vector2(12,-5), Vector2(-12,-5)]), Color("72818a"))
	_add_polygon(visual, PackedVector2Array([Vector2(-7,-48), Vector2(7,-48), Vector2(9,-39), Vector2(5,-32), Vector2(-5,-32), Vector2(-9,-39)]), Color("c8b99a"))
	_add_polygon(visual, PackedVector2Array([Vector2(-11,-28), Vector2(-18,-9), Vector2(-14,-7), Vector2(-4,-23)]), Color("a98a5e"))
	_add_polygon(visual, PackedVector2Array([Vector2(11,-28), Vector2(19,-15), Vector2(16,-12), Vector2(7,-22)]), Color("a98a5e"))
	_add_polygon(visual, PackedVector2Array([Vector2(-10,-5), Vector2(-2,-5), Vector2(-5,14), Vector2(-12,14)]), Color("34424c"))
	_add_polygon(visual, PackedVector2Array([Vector2(2,-5), Vector2(10,-5), Vector2(13,14), Vector2(6,14)]), Color("34424c"))
	bait_morsel = Polygon2D.new()
	bait_morsel.name = "MomentBaitMorsel"
	bait_morsel.position = Vector2(19, -15)
	bait_morsel.polygon = PackedVector2Array([Vector2(-5,-3), Vector2(2,-5), Vector2(6,0), Vector2(2,4), Vector2(-5,3)])
	bait_morsel.color = Color("b98a48")
	bait_morsel.visible = false
	visual.add_child(bait_morsel)

func _add_polygon(parent: Node2D, points: PackedVector2Array, tint: Color) -> void:
	var shape := Polygon2D.new()
	shape.polygon = points
	shape.color = tint
	parent.add_child(shape)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("10151c"))
	draw_rect(Rect2(0, 420, 1280, 300), Color("292821"))
	draw_circle(Vector2(460, 360), 28.0, Color(0.15, 0.25, 0.32, 0.35))
