class_name OperatorBodyPresenter
extends RefCounted

## Sole owner of Operator BODY renderer visibility.
##
## At any instant exactly ONE system may own the Operator body. Weapon and FX
## overlays are allowed alongside the body owner; a second body representation
## is not. The invariant is one BODY, not one CanvasItem.
##
## This class owns:
##   - the current body owner
##   - which renderers are body-capable, grouped by owner
##   - owner-scoped overlay retirement
##   - exclusive-owner classification
##   - body visibility mutation and stopping retired body animations
##   - visible-owner observability
##
## It deliberately does NOT: choose semantic animations, resolve animation
## identities, own gameplay state, own attack or posture timing, read input,
## move the body, or decide whether an action should occur. It never reaches
## back into the Operator: the Operator creates nodes and registers them here.

enum Owner {
	NONE,
	LEGACY_FULL_BODY,
	MODULAR_BODY,
	VIGIL_POSTURE_TRANSITION,
	VIGIL_FAST_STARTUP,
}

## Owners whose rig is a complete authored body composition. While one holds the
## body, ordinary locomotion/attack composition must not draw.
const EXCLUSIVE_OWNERS := [
	Owner.VIGIL_POSTURE_TRANSITION,
	Owner.VIGIL_FAST_STARTUP,
]

var _owner: int = Owner.NONE
var _layers_by_owner: Dictionary = {}
var _owner_of_layer: Dictionary = {}
var _overlays: Array = []


# --- registration ------------------------------------------------------------
#
# The Operator creates its renderers and registers them. Dynamic rigs register
# when they are lazily built. The presenter performs no scene-tree discovery.

func register_body_layers(owner: int, layers: Array) -> void:
	var registered: Array = _layers_by_owner.get(owner, [])
	for layer in layers:
		if layer == null or registered.has(layer):
			continue
		registered.append(layer)
		_owner_of_layer[layer] = owner
	_layers_by_owner[owner] = registered


func register_overlay_layers(overlays: Array) -> void:
	for overlay in overlays:
		if overlay != null and not _overlays.has(overlay):
			_overlays.append(overlay)


func is_registered_body_layer(layer) -> bool:
	return layer != null and _owner_of_layer.has(layer)


# --- observability -----------------------------------------------------------

func current_owner() -> int:
	return _owner


## Which owner a registered renderer belongs to, or Owner.NONE if unregistered.
func layer_owner(layer) -> int:
	return _owner_of_layer.get(layer, Owner.NONE)


func is_exclusive_owner_active() -> bool:
	return EXCLUSIVE_OWNERS.has(_owner)


## Owners that currently have at least one visible body layer. The ownership
## invariant is that this never holds more than one entry.
func visible_owners() -> Array:
	var found: Array = []
	for candidate in _layers_by_owner:
		for layer in _layers_by_owner[candidate]:
			if layer != null and layer.visible:
				found.append(candidate)
				break
	return found


# --- presentation ------------------------------------------------------------

## Atomically hand the body to `plan.owner`.
##
## Retires every registered body renderer and owner-scoped overlay, assigns the
## new owner, then enables only the layers the plan asks for. Nothing is drawn
## between the retire and the enable, so no rendered frame contains two bodies.
##
## A plan may legitimately name no layers: authored rigs acquire the body first
## and show their own layers as they start playing, which keeps art selection
## with the caller while ownership stays here.
func present(plan: OperatorBodyPresentationPlan) -> void:
	if plan == null:
		push_error("[OperatorBodyPresenter] present() requires a plan")
		return
	for layer in plan.body_layers:
		if _owner_of_layer.get(layer, plan.owner) != plan.owner:
			push_error(
				"[OperatorBodyPresenter] plan for owner %d names a body layer owned by %d"
				% [plan.owner, _owner_of_layer[layer]]
			)
			return
	_retire_all()
	_owner = plan.owner
	for layer in plan.body_layers:
		show_layer(layer)
	for overlay in plan.overlays:
		show_layer(overlay)


## Take the body for the legacy full-body sprite and display it.
##
## This owner is a single sprite, so acquiring it shows it outright; existing
## callers depend on that. Multi-layer owners cannot behave this way because
## their constituent animations need configuring before display, so their
## layers stay hidden here and are enabled by their own play functions before
## the frame is drawn — which is what keeps the handoff atomic.
func present_legacy_full_body() -> void:
	present(OperatorBodyPresentationPlan.create(
		Owner.LEGACY_FULL_BODY, _layers_by_owner.get(Owner.LEGACY_FULL_BODY, [])
	))


## Acquisition by owner id, for callers that have no layer list to hand.
## LEGACY_FULL_BODY routes through `present_legacy_full_body()` so the display
## semantics live in one clearly named place.
func set_owner(owner: int) -> void:
	if owner == Owner.LEGACY_FULL_BODY:
		present_legacy_full_body()
		return
	present(OperatorBodyPresentationPlan.create(owner))


## Declared by a modular composition that has already configured its layers.
## Retires the legacy body and both authored rigs without disturbing the
## modular layers the caller just set up.
func claim_modular() -> void:
	# MIGRATION DEBT:
	# LegacyFullBody remains hidden-but-playing because some weapon/presentation
	# layers still slave frame timing to it. Slice C must eliminate this hidden
	# animation-clock authority before LegacyFullBody can always be stopped on
	# retire. A hidden renderer being authoritative for timing is exactly the
	# split-brain the melee timing doctrine forbids; it survives here only
	# because removing it inside an extraction slice would change timing.
	_hide_layers(_layers_by_owner.get(Owner.LEGACY_FULL_BODY, []), false)
	_hide_layers(_layers_by_owner.get(Owner.VIGIL_POSTURE_TRANSITION, []), true)
	_hide_layers(_layers_by_owner.get(Owner.VIGIL_FAST_STARTUP, []), true)
	_owner = Owner.MODULAR_BODY


## Clear the modular layers without handing the body to the legacy sprite.
## Used when another owner is taking over, where re-showing legacy would draw a
## second body behind the incoming animation.
func release_modular() -> void:
	_retire_layers(_layers_by_owner.get(Owner.MODULAR_BODY, []))
	_retire_layers(_overlays)
	if _owner == Owner.MODULAR_BODY:
		_owner = Owner.NONE


## Stop and hide an authored rig and surrender the body, so the next owner
## starts from a clean slate rather than layering onto this one.
func release_rig(owner: int) -> void:
	_retire_layers(_layers_by_owner.get(owner, []))
	if _owner == owner:
		_owner = Owner.NONE


## Show one registered layer. STRICT: a body layer must already belong to the
## current owner.
##
## Showing a renderer is a mechanism; changing presentation ownership is a
## decision. This verb deliberately does not imply the other — an innocent
## `show_layer()` must never be able to overthrow an exclusive presentation.
## Callers that intend to take the body say so with `preempt_with_owner()`.
func show_layer(layer) -> bool:
	if layer == null:
		return false
	if _owner_of_layer.has(layer):
		var owner_of_layer: int = _owner_of_layer[layer]
		if owner_of_layer != _owner:
			push_error(
				"[OperatorBodyPresenter] show_layer() for owner %d while owner is %d;"
				% [owner_of_layer, _owner]
				+ " use preempt_with_owner() to take the body explicitly"
			)
			return false
		layer.visible = true
		return true
	if _overlays.has(layer):
		layer.visible = true
		return true
	push_error("[OperatorBodyPresenter] show_layer() on an unregistered renderer")
	return false


## Explicitly transfer the body to `owner`, atomically retiring whoever held it.
##
## This is the honest name for the decision that `show_layer()` refuses to make
## implicitly. `layers` may be empty: an authored rig takes the body first and
## enables its own layers as it starts playing them.
func preempt_with_owner(owner: int, layers: Array = []) -> void:
	if owner == _owner:
		for layer in layers:
			show_layer(layer)
		return
	if owner == Owner.MODULAR_BODY:
		claim_modular()
	else:
		set_owner(owner)
	for layer in layers:
		show_layer(layer)


## Hide one registered layer without changing ownership. Used by the incremental
## modular composition paths that drop a layer they could not fill.
func hide_layer(layer, stop_playback := true) -> void:
	if layer == null:
		return
	if not (_owner_of_layer.has(layer) or _overlays.has(layer)):
		push_error("[OperatorBodyPresenter] hide_layer() on an unregistered renderer")
		return
	layer.visible = false
	if stop_playback and layer.is_playing():
		layer.stop()


# --- internals ---------------------------------------------------------------

func _retire_all() -> void:
	for candidate in _layers_by_owner:
		_retire_layers(_layers_by_owner[candidate])
	# Owner-scoped overlays are not body layers, but they belong to whichever
	# body wore them, so they retire with it and the new owner re-adds its own.
	_retire_layers(_overlays)


func _retire_layers(layers: Array) -> void:
	_hide_layers(layers, true)


func _hide_layers(layers: Array, stop_playback: bool) -> void:
	for layer in layers:
		if layer == null:
			continue
		layer.visible = false
		if stop_playback and layer.is_playing():
			layer.stop()
