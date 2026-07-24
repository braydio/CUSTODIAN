class_name LevelExit2D
extends Area2D

signal transition_requested(exit_id: StringName, actor: Node)

@export var exit_id: StringName = &""
@export var prompt_text: String = ""
@export var trigger_on_body_entered := true
@export var one_shot_until_reset := true
@export_range(0.0, 512.0, 1.0) var arrival_guard_radius := 0.0

var _transition_locked := false
var _arrival_guarded_actor: WeakRef
var _route_enabled := true


func _ready() -> void:
	add_to_group("route_exit")
	if exit_id.is_empty():
		push_error("[LevelExit2D] exit_id is required at %s" % get_path())
	if get_node_or_null("CollisionShape2D") == null:
		push_error("[LevelExit2D] authored CollisionShape2D is required at %s" % get_path())
	if trigger_on_body_entered and not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if _arrival_guarded_actor == null:
		set_physics_process(false)
		return
	var actor := _arrival_guarded_actor.get_ref() as Node2D
	if (
		actor == null
		or not is_instance_valid(actor)
		or actor.global_position.distance_to(global_position)
			>= arrival_guard_radius
	):
		_clear_arrival_guard()


func reset_transition_lock() -> void:
	_transition_locked = false


func is_transition_locked() -> bool:
	return _transition_locked


func set_route_enabled(enabled: bool) -> void:
	_route_enabled = enabled
	monitoring = enabled
	monitorable = enabled
	if not enabled:
		_transition_locked = true
		_arrival_guarded_actor = null
		set_physics_process(false)
	else:
		reset_transition_lock()
		if (
			trigger_on_body_entered
			and not body_entered.is_connected(_on_body_entered)
		):
			body_entered.connect(_on_body_entered)


func arm_arrival_guard(actor: Node) -> void:
	if (
		arrival_guard_radius <= 0.0
		or not (actor is Node2D)
		or (actor as Node2D).global_position.distance_to(
			global_position
		) >= arrival_guard_radius
	):
		_clear_arrival_guard()
		return
	_arrival_guarded_actor = weakref(actor)
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	set_physics_process(true)


func is_actor_arrival_guarded(actor: Node) -> bool:
	return (
		_arrival_guarded_actor != null
		and _arrival_guarded_actor.get_ref() == actor
	)


func _clear_arrival_guard() -> void:
	_arrival_guarded_actor = null
	set_physics_process(false)
	if (
		_route_enabled
		and trigger_on_body_entered
		and not body_entered.is_connected(_on_body_entered)
	):
		body_entered.connect(_on_body_entered)


func request_transition(actor: Node) -> bool:
	if (
		_transition_locked
		or exit_id.is_empty()
		or not _is_persistent_player(actor)
		or is_actor_arrival_guarded(actor)
	):
		return false
	if one_shot_until_reset:
		_transition_locked = true
	transition_requested.emit(exit_id, actor)
	return true


func _on_body_entered(body: Node) -> void:
	request_transition(body)


func _is_persistent_player(actor: Node) -> bool:
	return actor != null and (
		actor.is_in_group("player")
		or actor.is_in_group("operator")
		or String(actor.name) == "Operator"
	)
