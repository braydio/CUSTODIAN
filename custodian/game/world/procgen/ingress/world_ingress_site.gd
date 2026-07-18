extends Area2D
class_name WorldIngressSite

@export var ingress_id: StringName
@export var level_id: StringName = &""
@export var approach_scene: PackedScene
@export var target_scene_path: String = ""
@export var target_spawn_id: StringName = &""
@export var prompt_text: String = "APPROACH"
@export_range(32.0, 192.0, 1.0) var interaction_distance: float = 92.0

var _triggered := false
var _approach_enter_deferred := false
var _sprite: Sprite2D = null
var _main_map: Node = null


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


func configure_level(p_level_id: StringName, p_main_map: Node = null) -> void:
	level_id = p_level_id
	_main_map = p_main_map


func apply_ingress_definition(definition: RefCounted) -> void:
	if definition == null:
		return
	ingress_id = definition.ingress_id
	prompt_text = definition.prompt_text
	target_spawn_id = definition.target_spawn_id
	interaction_distance = definition.interaction_distance


func get_interaction_prompt() -> String:
	return prompt_text


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if _approach_enter_deferred:
		return
	if body == null:
		return
	if not _is_player_body(body):
		return
	_approach_enter_deferred = true
	call_deferred("_enter_approach_deferred", body)


func _enter_approach_deferred(body: Node) -> void:
	_approach_enter_deferred = false
	if _triggered:
		return
	if not is_instance_valid(body):
		return
	if not _is_player_body(body):
		return
	_triggered = true
	_enter_approach(body)


func _enter_approach(actor: Node) -> void:
	var world := get_node_or_null("/root/GameRoot/World") as Node2D
	if world == null:
		var candidate := get_tree().current_scene
		world = candidate as Node2D
	if world == null:
		push_error("[WorldIngressSite] Missing world root for %s" % ingress_id)
		return

	# Presentation levels must never be born for one frame inside the active
	# procgen simulation. Isolate first, then restore atomically on failure.
	_set_procgen_world_visible(false)
	_set_vista_presentation_mode(actor, true)

	if not level_id.is_empty():
		var level_loader := _find_level_loader()
		if level_loader != null:
			var instance: Node = level_loader.call("enter_level", level_id, actor, {
				"parent": world,
				"main_map": _main_map,
				"return_world_position": global_position,
				"target_spawn_id": target_spawn_id,
			}) as Node
			if instance != null:
				return
		push_warning("[WorldIngressSite] LevelLoader could not enter %s; using legacy approach fallback" % level_id)

	if approach_scene == null:
		push_error("[WorldIngressSite] Missing approach_scene for %s" % ingress_id)
		_restore_failed_approach_entry(actor)
		return

	var existing := world.get_node_or_null("%s_Approach" % String(ingress_id))
	var approach := existing
	if approach == null:
		approach = approach_scene.instantiate()
		if approach == null:
			push_error("[WorldIngressSite] Could not instantiate approach scene for %s" % ingress_id)
			_restore_failed_approach_entry(actor)
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


func _find_level_loader() -> Node:
	var candidates := get_tree().get_nodes_in_group("level_loader")
	if not candidates.is_empty():
		return candidates[0] as Node
	return null


func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("operator") or String(body.name) == "Operator"


func _align_approach_entry_to_ingress(approach: Node) -> void:
	if not (approach is Node2D) or not approach.has_method("get_entry_position"):
		return
	var approach_2d := approach as Node2D
	var entry_position: Vector2 = approach.call("get_entry_position")
	approach_2d.global_position += global_position - entry_position


func _set_procgen_world_visible(value: bool) -> void:
	_set_world_branch_visible(get_node_or_null("/root/GameRoot/World/ProcGenRuntime"), value)
	_set_world_branch_visible(get_node_or_null("/root/GameRoot/World/ConnectedMaps"), value)


func _restore_failed_approach_entry(actor: Node) -> void:
	_set_procgen_world_visible(true)
	_set_vista_presentation_mode(actor, false)
	_triggered = false


func _set_vista_presentation_mode(actor: Node, enabled: bool) -> void:
	var ui := get_node_or_null("/root/GameRoot/UI")
	if ui != null and ui.has_method("set_world_presentation_mode"):
		ui.call("set_world_presentation_mode", &"vista_approach" if enabled else &"gameplay")
	if actor != null and actor.has_method("set_vista_presentation_mode"):
		actor.call("set_vista_presentation_mode", enabled)


func _set_world_branch_visible(branch: Node, value: bool) -> void:
	if branch == null:
		return
	if branch is CanvasItem:
		(branch as CanvasItem).visible = value
	branch.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED


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
