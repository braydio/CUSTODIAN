extends Area2D
class_name RoofOccluder2D

@export_range(0.0, 1.0, 0.01) var faded_alpha := 0.24
@export_range(0.01, 1.0, 0.01) var fade_in_duration := 0.18
@export_range(0.01, 1.0, 0.01) var fade_out_duration := 0.26

var _targets: Array[CanvasItem] = []
var _original_alpha: Dictionary = {}
var _occupants: Dictionary = {}
var _active_tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func configure(targets: Array[CanvasItem]) -> void:
	_targets = targets
	_original_alpha.clear()

	for target in _targets:
		if target == null:
			continue

		_original_alpha[target.get_instance_id()] = target.modulate.a


func _on_body_entered(body: Node) -> void:
	if not _is_player(body):
		return

	_occupants[body.get_instance_id()] = true
	_tween_to(faded_alpha, fade_in_duration)


func _on_body_exited(body: Node) -> void:
	if not _is_player(body):
		return

	_occupants.erase(body.get_instance_id())

	if _occupants.is_empty():
		_restore_targets()


func _restore_targets() -> void:
	if _active_tween != null:
		_active_tween.kill()

	_active_tween = create_tween() \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	for target in _targets:
		if target == null:
			continue

		var alpha := float(
			_original_alpha.get(
				target.get_instance_id(),
				1.0
			)
		)

		_active_tween.parallel().tween_property(
			target,
			"modulate:a",
			alpha,
			fade_out_duration
		)


func _tween_to(alpha: float, duration: float) -> void:
	if _active_tween != null:
		_active_tween.kill()

	_active_tween = create_tween() \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	for target in _targets:
		if target == null:
			continue

		_active_tween.parallel().tween_property(
			target,
			"modulate:a",
			alpha,
			duration
		)


func _is_player(body: Node) -> bool:
	return body.is_in_group("player") \
		or body.is_in_group("operator") \
		or String(body.name) == "Operator"
