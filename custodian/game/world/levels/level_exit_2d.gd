class_name LevelExit2D
extends Area2D

signal transition_requested(exit_id: StringName, actor: Node)

@export var exit_id: StringName = &""
@export var prompt_text: String = ""
@export var trigger_on_body_entered := true
@export var one_shot_until_reset := true

var _transition_locked := false


func _ready() -> void:
	add_to_group("route_exit")
	if exit_id.is_empty():
		push_error("[LevelExit2D] exit_id is required at %s" % get_path())
	if get_node_or_null("CollisionShape2D") == null:
		push_error("[LevelExit2D] authored CollisionShape2D is required at %s" % get_path())
	if trigger_on_body_entered and not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func reset_transition_lock() -> void:
	_transition_locked = false


func is_transition_locked() -> bool:
	return _transition_locked


func set_route_enabled(enabled: bool) -> void:
	monitoring = enabled
	monitorable = enabled
	if not enabled:
		_transition_locked = true
	else:
		reset_transition_lock()


func request_transition(actor: Node) -> bool:
	if _transition_locked or exit_id.is_empty() or not _is_persistent_player(actor):
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
