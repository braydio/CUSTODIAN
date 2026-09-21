class_name UnarmedPosturePresentation
extends RefCounted
## Unarmed READY/RELAXED posture, as presentation only.
##
## This owns three things and deliberately nothing else: which posture the
## Operator is presenting, which authored sector that posture draws, and which
## transition is currently running. It does not decide whether the Operator may
## attack, does not scan for enemies, and does not own the body -- `operator.gd`
## keeps ownership through `OperatorBodyPresenter`.
##
## Transition safety needs no token or timer. A transition is a piece of state,
## not a scheduled callback: it ends when its own clip reports completion, and
## `advance()` drops it the instant posture stops being available. Preemption
## therefore has nothing to race against -- the new owner retires the layer, and
## the forgotten transition has no continuation to fire.
##
## The READY/RELAXED model itself is `MeleePostureState`, reused rather than
## reimplemented, so there is exactly one such state machine in the codebase. Its
## SHEATHED state and draw grace are melee concepts and are simply never entered
## here: unarmed hands are never sheathed and never drawn.
##
## Engagement is not computed here either. `EngagementTracker` is the authority
## and this consumes its answer, including whatever quiet hysteresis it applies.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const PROFILE := &"unarmed"
const POSTURE_GROUP := &"posture"
const TRANSITION_GROUP := &"transition"

const IDLE_RELAXED := &"idle_relaxed_01"
const IDLE_READY := &"idle_ready_01"
const RELAXED_TO_READY := &"relaxed_to_ready_01"
const READY_TO_RELAXED := &"ready_to_relaxed_01"

## The authored posture art covers east and west only, on purpose. Choosing what a
## north- or south-facing request presents is a caller-owned authoring decision,
## exactly as `FULL_BODY_AUTHORED_SECTORS` is for sparse full-body locomotion.
## `OperatorAnimationSelector` stays exact-only and is asked for the projected
## sector, never asked to search.
const AUTHORED_SECTORS: Array[StringName] = [&"e", &"w"]

var _state := MeleePostureState.new()
var _transition_action: StringName = &""


func posture() -> MeleePostureState.Posture:
	return _state.posture


func is_ready() -> bool:
	return _state.posture == MeleePostureState.Posture.READY


## Advance the posture model. Returns the transition to start, or empty.
##
## `posture_available` is the caller's judgement that unarmed posture may present
## at all -- unarmed loadout, stationary, neutral, nothing higher-priority owning
## the body. `presentation_locked` freezes the posture where it is without
## retiring it, which is how a brief lock avoids a spurious transition on release.
func advance(
	delta: float,
	posture_available: bool,
	engagement_active: bool,
	presentation_locked: bool
) -> StringName:
	if not posture_available:
		# Retire without emitting a transition. Posture that is not presenting has
		# nothing to transition between, and emitting one here is how a stale clip
		# would later wake up over whoever took the body.
		cancel_transition()
		_state.posture = MeleePostureState.Posture.RELAXED
		return &""
	var previous := _state.posture
	_state.resolve(delta, true, engagement_active, presentation_locked)
	if previous == _state.posture:
		return &""
	if previous == MeleePostureState.Posture.RELAXED \
	and _state.posture == MeleePostureState.Posture.READY:
		return RELAXED_TO_READY
	if previous == MeleePostureState.Posture.READY \
	and _state.posture == MeleePostureState.Posture.RELAXED:
		return READY_TO_RELAXED
	return &""


## East/west projection. Everything not facing west presents east, north and
## south included, because no north or south posture art is authored and none
## should be fabricated.
func authored_sector(direction: Vector2) -> StringName:
	return &"w" if direction.x < -0.05 else &"e"


func idle_action() -> StringName:
	return IDLE_READY if _state.posture == MeleePostureState.Posture.READY else IDLE_RELAXED


func transition_action() -> StringName:
	return _transition_action


func is_transitioning() -> bool:
	return not _transition_action.is_empty()


func begin_transition(action: StringName) -> void:
	_transition_action = action


## Complete whatever transition is running, if the finished clip is that
## transition's own. Completion rides the presentation clock rather than a
## wall-clock timer, so it stays correct when the authored placeholders are
## replaced with real multi-frame art, and so a preempted transition simply never
## reports completion.
func complete_transition_for(finished_animation: String) -> bool:
	if not is_transitioning():
		return false
	if not finished_animation.contains("/%s/" % _transition_action):
		return false
	_transition_action = &""
	return true


## Drop any in-flight transition.
##
## Called from `advance()` the moment posture stops being available, which is how
## preemption works: nothing is scheduled and nothing is awaited, so once the
## transition is forgotten there is no continuation left to fire. The old clip
## stops because the new owner retires the layer, not because a timer was
## cancelled.
func cancel_transition() -> void:
	_transition_action = &""


## The action this posture should currently draw: the transition while one is
## running, otherwise the settled idle.
func current_action() -> StringName:
	return _transition_action if is_transitioning() else idle_action()


func current_group() -> StringName:
	return TRANSITION_GROUP if is_transitioning() else POSTURE_GROUP
