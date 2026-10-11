class_name OperatorPresentationController
extends RefCounted

## Translates semantic animation intent into the mechanical body-owner plan and
## the existing canonical playback authority.

var _body_presenter: OperatorBodyPresenter
var _animation_player: OperatorAnimationPlayer
var _animation_selector: OperatorAnimationSelector
var _completion_clock: AnimatedSprite2D


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
	var played := _animation_player.play(sprite, identity, restart)
	if played:
		_completion_clock = sprite
	return played


## Present one bounded lower/upper body pair. Callers choose semantic actions,
## directions, fallback and which visible layer clocks completion; this method
## validates the complete composition before taking ownership, then preserves
## already-running clips when their identities have not changed.
func present_split_body_action(
	plan: OperatorBodyPresentationPlan,
	lower_sprite: AnimatedSprite2D,
	lower_identity: StringName,
	upper_sprite: AnimatedSprite2D,
	upper_identity: StringName,
	completion_sprite: AnimatedSprite2D = null,
	lower_restart := false,
	upper_restart := false,
	lower_speed_scale := 1.0,
	upper_speed_scale := 1.0,
	upper_reverse := false,
	overlay_sprite: AnimatedSprite2D = null,
	overlay_identity: StringName = &"",
	overlay_restart := false
) -> bool:
	if _body_presenter == null or _animation_player == null or plan == null:
		return false
	if not plan.body_layers.has(lower_sprite) or not plan.body_layers.has(upper_sprite):
		return false
	if not _animation_player.can_play(lower_sprite, lower_identity) \
		or not _animation_player.can_play(upper_sprite, upper_identity):
		return false
	if overlay_sprite != null:
		if not plan.overlays.has(overlay_sprite) \
			or not _animation_player.can_play(overlay_sprite, overlay_identity):
			return false
	if not _body_presenter.can_present(plan):
		return false
	if _body_presenter.current_owner() != plan.owner:
		if not _body_presenter.present(plan):
			return false
	else:
		_body_presenter.show_layer(lower_sprite)
		_body_presenter.show_layer(upper_sprite)
		if overlay_sprite != null:
			_body_presenter.show_layer(overlay_sprite)
	var lower_played := _animation_player.play(
		lower_sprite, lower_identity, lower_restart
	)
	var upper_played := _animation_player.play_backwards(
		upper_sprite, upper_identity, upper_restart
	) if upper_reverse else (
		_animation_player.play(upper_sprite, upper_identity, upper_restart)
		if upper_restart else _animation_player.play(upper_sprite, upper_identity)
	)
	if not lower_played or not upper_played:
		return false
	lower_sprite.speed_scale = lower_speed_scale
	upper_sprite.speed_scale = upper_speed_scale
	if overlay_sprite != null:
		var overlay_played := _animation_player.play(
			overlay_sprite, overlay_identity, overlay_restart
		)
		if not overlay_played:
			return false
	_completion_clock = completion_sprite if completion_sprite != null else upper_sprite
	return true


func is_current_action_complete() -> bool:
	return _completion_clock == null or not _completion_clock.is_playing()


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
