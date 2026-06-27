extends Area2D
class_name LightingZone2D

@export var profile: LightingProfile
@export var profile_priority: int = 0
@export var blend_on_enter: bool = true
@export var director_path: NodePath

var _director: WorldLightingDirector = null
var _active_bodies := {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_resolve_director()


func _on_body_entered(body: Node2D) -> void:
	if not _is_player_actor(body):
		return
	_active_bodies[body.get_instance_id()] = true
	var director := _resolve_director()
	if director != null:
		director.push_zone_profile(self, profile, profile_priority, not blend_on_enter)


func _on_body_exited(body: Node2D) -> void:
	if not _active_bodies.has(body.get_instance_id()):
		return
	_active_bodies.erase(body.get_instance_id())
	if not _active_bodies.is_empty():
		return
	var director := _resolve_director()
	if director != null:
		director.pop_zone_profile(self, not blend_on_enter)


func _resolve_director() -> WorldLightingDirector:
	if _director != null and is_instance_valid(_director):
		return _director
	if not director_path.is_empty():
		_director = get_node_or_null(director_path) as WorldLightingDirector
	if _director == null:
		_director = get_tree().get_first_node_in_group("world_lighting_director") as WorldLightingDirector
	return _director


func _is_player_actor(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("player"):
		return true
	return body.name == "Operator" or body.has_method("get_weapon_status")
