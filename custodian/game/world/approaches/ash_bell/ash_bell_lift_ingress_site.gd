extends WorldIngressSite
class_name AshBellLiftIngressSite

const PRESENTATION_SCENE := preload(
	"res://game/world/approaches/ash_bell/"
	+ "ash_bell_lift_ingress_presentation.tscn"
)

var _presentation: AshBellLiftIngressPresentation


func _init() -> void:
	requires_explicit_interaction = true


func _ensure_visual() -> void:
	_presentation = (
		PRESENTATION_SCENE.instantiate()
		as AshBellLiftIngressPresentation
	)
	if _presentation == null:
		push_error("[AshBellLiftIngressSite] Presentation scene failed to instantiate")
		return
	_presentation.name = "AshBellLiftIngressPresentation"
	add_child(_presentation)


func get_interaction_position() -> Vector2:
	if _presentation != null:
		return _presentation.get_boarding_position()
	return global_position


func get_procgen_dressing_clearance_world_rect() -> Rect2:
	if _presentation == null:
		return Rect2()
	return _presentation.get_procgen_dressing_clearance_world_rect()


func interact(actor: Node) -> void:
	if not (actor is Node2D):
		return
	if _presentation == null:
		return
	if not _presentation.is_actor_boarded(actor as Node2D):
		return
	super.interact(actor)


func _play_entry_presentation(actor: Node) -> void:
	if _presentation == null or not (actor is Node2D):
		return
	await _presentation.play_descent(actor as Node2D)


func reset_after_level_return() -> void:
	super.reset_after_level_return()
	if _presentation != null:
		call_deferred("_play_return_presentation")


func _play_return_presentation() -> void:
	if _presentation == null:
		return
	var actor := get_tree().get_first_node_in_group("player") as Node2D
	if actor == null:
		_presentation.reset_presentation()
		return
	await _presentation.play_ascent(actor)
