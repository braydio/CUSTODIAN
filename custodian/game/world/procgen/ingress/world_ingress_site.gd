extends Area2D
class_name WorldIngressSite

@export var ingress_id: StringName
@export var approach_scene: PackedScene
@export var target_scene_path: String = ""
@export var target_spawn_id: StringName = &""
@export var prompt_text: String = "APPROACH"
@export_range(32.0, 192.0, 1.0) var interaction_distance: float = 92.0

var _triggered := false
var _sprite: Sprite2D = null


func _ready() -> void:
	add_to_group("world_ingress_site")
	body_entered.connect(_on_body_entered)
	_ensure_collision()
	_ensure_visual()


func configure(
	p_ingress_id: StringName,
	p_approach_scene: PackedScene,
	p_target_scene_path: String,
	p_target_spawn_id: StringName = &""
) -> void:
	ingress_id = p_ingress_id
	approach_scene = p_approach_scene
	target_scene_path = p_target_scene_path
	target_spawn_id = p_target_spawn_id


func get_interaction_prompt() -> String:
	return prompt_text


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not _is_player_body(body):
		return
	_triggered = true
	_enter_approach(body)


func _enter_approach(actor: Node) -> void:
	if approach_scene == null:
		push_error("[WorldIngressSite] Missing approach_scene for %s" % ingress_id)
		return

	var world := get_node_or_null("/root/GameRoot/World") as Node2D
	if world == null:
		var candidate := get_tree().current_scene
		world = candidate as Node2D
	if world == null:
		push_error("[WorldIngressSite] Missing world root for %s" % ingress_id)
		return

	var existing := world.get_node_or_null("%s_Approach" % String(ingress_id))
	var approach := existing
	if approach == null:
		approach = approach_scene.instantiate()
		if approach == null:
			push_error("[WorldIngressSite] Could not instantiate approach scene for %s" % ingress_id)
			return
		approach.name = "%s_Approach" % String(ingress_id)
		world.add_child(approach)
		_align_approach_entry_to_ingress(approach)

	if approach.has_method("configure_ingress"):
		approach.call("configure_ingress", {
			"target_scene_path": target_scene_path,
			"target_spawn_id": target_spawn_id,
			"return_world_position": global_position,
		})

	if actor is Node2D and approach.has_method("get_entry_position"):
		(actor as Node2D).global_position = approach.call("get_entry_position")


func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("operator") or String(body.name) == "Operator"


func _align_approach_entry_to_ingress(approach: Node) -> void:
	if not (approach is Node2D) or not approach.has_method("get_entry_position"):
		return
	var approach_2d := approach as Node2D
	var entry_position: Vector2 = approach.call("get_entry_position")
	approach_2d.global_position += global_position - entry_position


func _ensure_collision() -> void:
	if get_node_or_null("CollisionShape2D") != null:
		return
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = interaction_distance
	shape.shape = circle
	add_child(shape)


func _ensure_visual() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "IngressMarker"
	_sprite.centered = true
	_sprite.modulate = Color(0.48, 0.70, 0.86, 0.42)
	add_child(_sprite)

	var marker := Polygon2D.new()
	marker.name = "IngressMarkerDiamond"
	marker.color = Color(0.48, 0.70, 0.86, 0.28)
	marker.polygon = PackedVector2Array([
		Vector2(-28, 0),
		Vector2(0, -16),
		Vector2(28, 0),
		Vector2(0, 16),
	])
	add_child(marker)
