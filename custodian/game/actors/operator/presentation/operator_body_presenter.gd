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

func owner() -> int:
	return _owner


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


## Convenience acquisition for callers that have no layer list to hand.
##
## LEGACY_FULL_BODY is enabled outright because it is a single sprite. The
## multi-layer owners compose from whatever art exists for the direction, so
## their layers stay hidden here and are enabled by their own play functions
## before the frame is drawn - which is what keeps the handoff atomic.
func set_owner(owner: int) -> void:
	var layers: Array = []
	if owner == Owner.LEGACY_FULL_BODY:
		layers = _layers_by_owner.get(owner, [])
	present(OperatorBodyPresentationPlan.create(owner, layers))


## Declared by a modular composition that has already configured its layers.
## Retires the legacy body and both authored rigs without disturbing the
## modular layers the caller just set up.
func claim_modular() -> void:
	# The legacy body is hidden but NOT stopped: while hidden it still serves as
	# a frame clock that explicit weapon layers synchronise against, so stopping
	# it here would change presentation timing.
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


## Show one registered layer.
##
## Showing a body layer IS a claim on the body: if the layer belongs to another
## owner, that owner is adopted here and whoever held the body is retired in the
## same call, before anything is drawn. So the one-body invariant holds even
## when a deliberate presentation preempts an authored rig - which the runtime
## legitimately does, for example when a draw/equip presentation interrupts a
## posture bridge.
##
## Preemption is deliberately NOT refused here. Preventing *incidental*
## composition from drawing behind an authored rig is the job of the callers
## that own that decision - `_update_animation()` and the legacy fallback both
## check `is_exclusive_owner_active()` first - and that is where the
## duplicate-body regression tests point.
func show_layer(layer) -> bool:
	if layer == null:
		return false
	if _owner_of_layer.has(layer):
		var layer_owner: int = _owner_of_layer[layer]
		if layer_owner != _owner:
			if layer_owner == Owner.MODULAR_BODY:
				claim_modular()
			else:
				set_owner(layer_owner)
		layer.visible = true
		return true
	if _overlays.has(layer):
		layer.visible = true
		return true
	push_error("[OperatorBodyPresenter] show_layer() on an unregistered renderer")
	return false


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
