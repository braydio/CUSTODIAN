class_name OperatorPresentationController
extends RefCounted

## Translates semantic animation intent into the mechanical body-owner plan and
## the existing canonical playback authority.

var _body_presenter: OperatorBodyPresenter
var _animation_player: OperatorAnimationPlayer
var _animation_selector: OperatorAnimationSelector
var _completion_clock: AnimatedSprite2D

const COMPOSITION_FULL_BODY := &"full_body"
const COMPOSITION_SPLIT := &"split_body"
const COMPOSITION_EXCLUSIVE := &"exclusive_rig"
const COMPOSITION_READY := &"STRUCTURALLY_READY"
const COMPOSITION_BLOCKED := &"BLOCKED"
const COMPOSITION_UNKNOWN := &"UNKNOWN/BLOCKED"


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


## Read-only, fixture-only composition guard. It is not called by production
## presentation paths and cannot authorize a generation switch.
## A clip record contains sprite/profile/group/action/sector/layer/weapon_id and
## optional generation. The latter is deliberately never trusted: current
## runtime SpriteFrames and generated manifests do not bind clip identity to an
## approved generation. 2.5D requests therefore remain UNKNOWN/BLOCKED until
## WB25-6 supplies that provenance contract.
func preflight_composition_fixture_only(
	plan: OperatorBodyPresentationPlan,
	mode: StringName,
	clips: Array,
	completion_sprite: AnimatedSprite2D = null
) -> Dictionary:
	var result := {
		"status": COMPOSITION_BLOCKED,
		"structural_status": COMPOSITION_BLOCKED,
		"generation_status": COMPOSITION_UNKNOWN,
		"movement_permission": false,
		"reason": "invalid composition",
		"mutated": false,
	}
	if _body_presenter == null or _animation_player == null or plan == null:
		result.reason = "presentation authorities or plan are unavailable"
		return result
	if mode not in [COMPOSITION_FULL_BODY, COMPOSITION_SPLIT, COMPOSITION_EXCLUSIVE]:
		result.reason = "unknown composition mode"
		return result
	var exclusive_owner := OperatorBodyPresenter.EXCLUSIVE_OWNERS.has(plan.owner)
	if (mode == COMPOSITION_EXCLUSIVE) != exclusive_owner:
		result.reason = "composition mode does not match the registered owner class"
		return result
	var expected_count := 2 if mode == COMPOSITION_SPLIT else 1
	if clips.size() != expected_count or plan.body_layers.size() != expected_count:
		result.reason = "composition has missing or extra body layers"
		return result
	var unique_plan_layers: Dictionary = {}
	for body_layer in plan.body_layers:
		if unique_plan_layers.has(body_layer):
			result.reason = "composition repeats a body renderer"
			return result
		unique_plan_layers[body_layer] = true
	if completion_sprite == null:
		result.reason = "composition has no visible completion clock"
		return result
	if not plan.body_layers.has(completion_sprite):
		result.reason = "completion clock is not part of the proposed body"
		return result
	if not _body_presenter.can_present(plan):
		result.reason = "owner, body renderer, or overlay registration is invalid"
		return result
	var requested_25d := false
	for clip in clips:
		var profile := StringName(clip.get("profile", ""))
		requested_25d = requested_25d or profile == &"operator_2_5d_128"
	if requested_25d:
		result.status = COMPOSITION_UNKNOWN
		result.structural_status = COMPOSITION_UNKNOWN
		result.reason = "runtime metadata does not prove a common approved 2.5D generation and profile"
		return result
	var unique_clip_sprites: Dictionary = {}
	var split_semantic_layers: Dictionary = {}
	for clip in clips:
		var sprite := clip.get("sprite") as AnimatedSprite2D
		var profile := StringName(clip.get("profile", ""))
		var group := StringName(clip.get("group", ""))
		var action := StringName(clip.get("action", ""))
		var sector := StringName(clip.get("sector", ""))
		var layer := StringName(clip.get("layer", ""))
		var weapon_id := StringName(clip.get("weapon_id", ""))
		if sprite == null or not plan.body_layers.has(sprite):
			result.reason = "clip renderer is not a proposed body layer"
			return result
		if unique_clip_sprites.has(sprite):
			result.reason = "composition assigns multiple clips to one body renderer"
			return result
		unique_clip_sprites[sprite] = true
		if mode == COMPOSITION_FULL_BODY and layer != &"full_body":
			result.reason = "full-body mode requires the full_body semantic layer"
			return result
		if mode == COMPOSITION_SPLIT:
			if layer not in [&"lower_body", &"upper_body"] or split_semantic_layers.has(layer):
				result.reason = "split mode requires one lower_body and one upper_body identity"
				return result
			split_semantic_layers[layer] = true
		if _animation_selector == null or not _animation_selector.has_sector_identity(
			profile, group, action, sector, layer, weapon_id
		):
			result.reason = "exact semantic identity is unavailable"
			return result
		var identity := OperatorAnimationSelector.animation_name(
			profile, group, action, sector, layer, weapon_id
		)
		if not _animation_player.can_play(sprite, identity):
			result.reason = "proposed body renderer cannot play its exact identity"
			return result
	if mode == COMPOSITION_SPLIT and not (
		split_semantic_layers.has(&"lower_body") and split_semantic_layers.has(&"upper_body")
	):
		result.reason = "split mode is missing a semantic body layer"
		return result
	result.status = COMPOSITION_READY
	result.structural_status = &"READY"
	result.reason = "complete exact-identity composition is structurally playable"
	return result


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
