class_name OperatorPresentationController
extends RefCounted

## Translates semantic animation intent into the mechanical body-owner plan and
## the existing canonical playback authority.
##
## It also owns the bounded movement-permissive composition decision: movement-owned
## lower locomotion + action-owned upper body, with independent lower/upper identity
## (and therefore direction), lower-progress preservation, an explicit upper restart
## and a complete-presentation fallback (a `false` result means nothing was changed
## and the caller must present the complete paired action instead). It is not a
## layer graph or mixer, and it holds no gameplay state: callers pass facts in.

## Guard phases the unarmed guard composition understands (legacy phase vocabulary).
enum GuardComposition { PAIRED, MOVEMENT_LOWER_UPPER_ACTION }

const MOVEMENT_PERMISSIVE_GUARD_PHASES: Array[StringName] = [&"enter", &"hold", &"recoil", &"exit"]

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


## Which composition a guard phase should present.
##
## Pure: gameplay facts in, decision out. `impact_locked` (guard break / break
## recovery) always wins, because those phases are movement-locked by gameplay and
## may carry recoil velocity that is not movement intent.
static func decide_guard_composition(phase: StringName, moving: bool, impact_locked: bool) -> int:
	if impact_locked or not moving:
		return GuardComposition.PAIRED
	if phase in MOVEMENT_PERMISSIVE_GUARD_PHASES:
		return GuardComposition.MOVEMENT_LOWER_UPPER_ACTION
	return GuardComposition.PAIRED


## Whether a lower+upper composition could play right now. Changes nothing.
func can_compose_lower_upper(
	lower_sprite: AnimatedSprite2D, lower_identity: StringName,
	upper_sprite: AnimatedSprite2D, upper_identity: StringName
) -> bool:
	return _animation_player != null \
		and _animation_player.can_play(lower_sprite, lower_identity) \
		and _animation_player.can_play(upper_sprite, upper_identity)


## Play a movement-owned lower identity under an action-owned upper identity.
##
## Body ownership is declared by the caller beforehand (resolve, declare, then
## configure); this only drives playback, so it never retires a running layer.
##
## * The lower clip is left running whenever the identity is unchanged, so only a
##   genuine locomotion identity/direction change restarts it.
## * The upper clip starts when its identity changes or `restart_upper` is set (a
##   phase transition). Re-driving the same one-shot action every frame never
##   restarts it, and a finished one-shot is not replayed; a looping action that
##   stopped is resumed.
## * `upper_backwards` plays the upper identity in reverse (guard exit).
## * `overlay_sync` is called last with no arguments and is the caller's owner-scoped
##   overlay hook (for example the held guard FX).
##
## Returns false without touching anything when either identity cannot play.
func compose_lower_upper(
	lower_sprite: AnimatedSprite2D, lower_identity: StringName, lower_speed_scale: float,
	upper_sprite: AnimatedSprite2D, upper_identity: StringName, upper_speed_scale := 1.0,
	restart_upper := false, upper_backwards := false, overlay_sync := Callable()
) -> bool:
	if not can_compose_lower_upper(lower_sprite, lower_identity, upper_sprite, upper_identity):
		return false
	lower_sprite.flip_h = false
	_animation_player.set_speed_scale(lower_sprite, lower_speed_scale)
	if lower_sprite.animation != lower_identity or not lower_sprite.is_playing():
		_animation_player.play(lower_sprite, lower_identity)
	upper_sprite.flip_h = false
	_animation_player.set_speed_scale(upper_sprite, upper_speed_scale)
	var upper_changed := upper_sprite.animation != upper_identity
	var looping := upper_sprite.sprite_frames.get_animation_loop(upper_identity)
	var resume_loop := looping and not upper_sprite.is_playing()
	if restart_upper or upper_changed or resume_loop:
		if upper_backwards:
			upper_sprite.play_backwards(upper_identity)
		else:
			_animation_player.play(upper_sprite, upper_identity, restart_upper and not upper_changed)
	if overlay_sync.is_valid():
		overlay_sync.call()
	return true

