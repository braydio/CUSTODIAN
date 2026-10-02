class_name OperatorPresentationController
extends RefCounted

## Translates semantic animation intent into the mechanical body-owner plan and
## the existing canonical playback authority.

var _body_presenter: OperatorBodyPresenter
var _animation_player: OperatorAnimationPlayer
var _animation_selector: OperatorAnimationSelector


func _init(
	body_presenter: OperatorBodyPresenter = null,
	animation_player: OperatorAnimationPlayer = null,
	animation_selector: OperatorAnimationSelector = null
) -> void:
	_body_presenter = body_presenter
	_animation_player = animation_player
	_animation_selector = animation_selector


func can_present(plan: OperatorBodyPresentationPlan) -> bool:
	return _body_presenter != null and _body_presenter.can_present(plan)


func present(plan: OperatorBodyPresentationPlan, report_rejection := true) -> bool:
	return _body_presenter != null and _body_presenter.present(plan, report_rejection)


func present_animation(
	plan: OperatorBodyPresentationPlan,
	sprite: AnimatedSprite2D,
	identity: StringName,
	restart := false
) -> bool:
	if _body_presenter == null or _animation_player == null:
		return false
	if not _animation_player.can_play(sprite, identity) or not _body_presenter.can_present(plan):
		return false
	if not _body_presenter.present(plan):
		return false
	return _animation_player.play(sprite, identity, restart)


func play_animation(sprite: AnimatedSprite2D, identity: StringName, restart := false) -> bool:
	return _animation_player != null and _animation_player.play(sprite, identity, restart)


func present_resolved_animation(
	plan: OperatorBodyPresentationPlan,
	sprite: AnimatedSprite2D,
	profile: StringName,
	group: StringName,
	action: StringName,
	sector: StringName,
	layer: StringName,
	restart := false,
	weapon_id: StringName = &""
) -> StringName:
	if _animation_selector == null:
		return &""
	var identity := _animation_selector.resolve_sector(
		profile, group, action, sector, layer, weapon_id
	)
	if identity.is_empty() or not present_animation(plan, sprite, identity, restart):
		return &""
	return identity


func present_omni_animation(
	plan: OperatorBodyPresentationPlan,
	sprite: AnimatedSprite2D,
	profile: StringName,
	group: StringName,
	action: StringName,
	layer: StringName,
	restart := false,
	weapon_id: StringName = &""
) -> StringName:
	if _animation_selector == null:
		return &""
	var identity := _animation_selector.resolve_omni(
		profile, group, action, layer, weapon_id
	)
	if identity.is_empty() or not present_animation(plan, sprite, identity, restart):
		return &""
	return identity
