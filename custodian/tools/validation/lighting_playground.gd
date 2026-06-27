extends Node2D

@export var director_path: NodePath = NodePath("WorldLightingDirector")
@export var transient_pool_path: NodePath = NodePath("TransientLightPool")
@export var actor_path: NodePath = NodePath("PlayerPlaceholder")
@export var profiles: Array[LightingProfile] = []

@onready var director: WorldLightingDirector = get_node_or_null(director_path) as WorldLightingDirector
@onready var transient_pool: Node = get_node_or_null(transient_pool_path)
@onready var actor: Node2D = get_node_or_null(actor_path) as Node2D

var _profile_index := 0


func _ready() -> void:
	if actor != null:
		actor.add_to_group("player")
	if director != null and not profiles.is_empty():
		director.apply_profile(profiles[0], true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		match key_event.keycode:
			KEY_L:
				cycle_profile()
			KEY_F:
				trigger_flash()


func cycle_profile() -> void:
	if director == null or profiles.is_empty():
		return
	_profile_index = (_profile_index + 1) % profiles.size()
	director.apply_profile(profiles[_profile_index])


func trigger_flash() -> void:
	var position := actor.global_position if actor != null else global_position
	if transient_pool != null and transient_pool.has_method("flash_at"):
		transient_pool.flash_at(position + Vector2(42.0, -12.0), Color(1.0, 0.76, 0.32, 0.95), 1.15, 0.14)
	if director != null:
		director.push_temporary_flash(Color(1.0, 0.78, 0.45, 1.0), 0.28, 0.12)
