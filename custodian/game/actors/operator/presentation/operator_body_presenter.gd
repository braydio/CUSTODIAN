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
##   - which overlays belong to which owner, and their owner-scoped retirement
##   - exclusive-owner classification
##   - body visibility mutation and stopping retired body animations
##   - visible-owner observability
##
## It deliberately does NOT: choose semantic animations, resolve animation
## identities, own gameplay state, own attack or posture timing, read input,
## move the body, cancel gameplay lifecycles, or decide whether an action
## should occur. It never reaches back into the Operator: the Operator creates
## nodes and registers them here.

enum Owner {
	NONE,
	LEGACY_FULL_BODY,
	MODULAR_BODY,
	VIGIL_POSTURE_TRANSITION,
	VIGIL_FAST_STARTUP,
	VIGIL_GUARD,
}

## Owners whose rig is a complete authored body composition. While one holds the
## body, ordinary locomotion/attack composition must not draw.
const EXCLUSIVE_OWNERS := [
	Owner.VIGIL_POSTURE_TRANSITION,
	Owner.VIGIL_FAST_STARTUP,
	Owner.VIGIL_GUARD,
]

var _owner: int = Owner.NONE

## owner -> Array of body renderers.
var _layers_by_owner: Dictionary = {}
## body renderer -> owner. A body layer belongs to exactly one owner.
var _owner_of_layer: Dictionary = {}
## owner -> Array of overlay renderers scoped to that owner's lifetime.
var _overlays_by_owner: Dictionary = {}
## overlay renderer -> Array of owners. An overlay may be worn by several
## owners (the cape rides both the legacy strips and the modular rig), which is
## why overlays are not restricted to a single owner the way bodies are.
var _owners_of_overlay: Dictionary = {}


# --- registration ------------------------------------------------------------
#
# The Operator creates its renderers and registers them. Dynamic rigs register
# when they are lazily built. The presenter performs no scene-tree discovery.

## Declare body renderers for `owner`.
##
## A body layer may belong to exactly one owner: two owners sharing a body
## renderer is the ambiguity this class exists to prevent, so a conflicting
## registration is rejected rather than silently reassigned.
func register_body_layers(owner: int, layers: Array) -> bool:
	if not _is_known_owner(owner) or owner == Owner.NONE:
		push_error("[OperatorBodyPresenter] register_body_layers() for unknown owner %d" % owner)
		return false
	var registered: Array = _layers_by_owner.get(owner, [])
	var accepted := true
	for layer in layers:
		if layer == null or registered.has(layer):
			continue
		var existing: int = _owner_of_layer.get(layer, Owner.NONE)
		if existing != Owner.NONE and existing != owner:
			push_error(
				"[OperatorBodyPresenter] body layer already registered to owner %d,"
				% existing
				+ " refusing to reassign it to owner %d" % owner
			)
			accepted = false
			continue
		registered.append(layer)
		_owner_of_layer[layer] = owner
	_layers_by_owner[owner] = registered
	return accepted


## Declare overlays whose lifetime tracks `owner`.
##
## Owner-scoped so that retiring one owner can never blank another owner's
## cosmetics, and so preempting an owner takes its overlays down with its body.
func register_overlay_layers(owner: int, overlays: Array) -> bool:
	if not _is_known_owner(owner) or owner == Owner.NONE:
		push_error("[OperatorBodyPresenter] register_overlay_layers() for unknown owner %d" % owner)
		return false
	var registered: Array = _overlays_by_owner.get(owner, [])
	for overlay in overlays:
		if overlay == null:
			continue
		if _owner_of_layer.has(overlay):
			push_error(
				"[OperatorBodyPresenter] renderer is already a body layer;"
				+ " it cannot also be an overlay"
			)
			continue
		if not registered.has(overlay):
			registered.append(overlay)
		var owners: Array = _owners_of_overlay.get(overlay, [])
		if not owners.has(owner):
			owners.append(owner)
		_owners_of_overlay[overlay] = owners
	_overlays_by_owner[owner] = registered
	return true


func is_registered_body_layer(layer) -> bool:
	return layer != null and _owner_of_layer.has(layer)


func is_registered_overlay(layer) -> bool:
	return layer != null and _owners_of_overlay.has(layer)


## Any renderer this presenter is authoritative for.
func is_registered_layer(layer) -> bool:
	return is_registered_body_layer(layer) or is_registered_overlay(layer)


# --- observability -----------------------------------------------------------

func current_owner() -> int:
	return _owner


## Which owner a registered body renderer belongs to, or Owner.NONE.
func layer_owner(layer) -> int:
	return _owner_of_layer.get(layer, Owner.NONE)


## Which owners wear a registered overlay.
func overlay_owners(overlay) -> Array:
	return (_owners_of_overlay.get(overlay, []) as Array).duplicate()


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


## Overlays currently visible for `owner`. Observability for the regression
## coverage that a preempted owner leaves nothing of itself on screen.
func visible_overlays(owner: int) -> Array:
	var found: Array = []
	for overlay in _overlays_by_owner.get(owner, []):
		if overlay != null and overlay.visible:
			found.append(overlay)
	return found


# --- presentation ------------------------------------------------------------

## Atomically hand the body to `plan.owner`. Returns whether it was accepted.
##
## Transactional: the whole plan is validated BEFORE anything is retired and
## before `_owner` moves. A plan that names an unregistered renderer, or one
## belonging to another owner, changes nothing at all — the previous owner keeps
## the body rather than being torn down on the way to a rejected presentation.
##
## A plan may legitimately name no layers: authored rigs acquire the body first
## and show their own layers as they start playing, which keeps art selection
## with the caller while ownership stays here.
## `report_rejection` exists so negative-control tests can drive this exact path
## without emitting engine errors the strict harness would read as failures.
## Production callers leave it true: a rejected presentation is a real bug.
func present(plan: OperatorBodyPresentationPlan, report_rejection := true) -> bool:
	if not _validate(plan, report_rejection):
		return false
	# Validation passed; only now is it safe to mutate.
	_retire_all()
	_owner = plan.owner
	for layer in plan.body_layers:
		show_layer(layer)
	for overlay in plan.overlays:
		show_layer(overlay)
	return true


## Whether `plan` would be accepted, changing nothing and reporting nothing.
## `present()` is still the only thing that may alter presentation.
func can_present(plan: OperatorBodyPresentationPlan) -> bool:
	return _validate(plan, false)


## The single validity rule, shared by `present()` and `can_present()`, so a
## probe can never disagree with what the mutation would actually accept.
func _validate(plan: OperatorBodyPresentationPlan, report: bool) -> bool:
	if plan == null:
		if report:
			push_error("[OperatorBodyPresenter] present() requires a plan")
		return false
	if not _is_known_owner(plan.owner) or plan.owner == Owner.NONE:
		if report:
			push_error("[OperatorBodyPresenter] present() for unknown owner %d" % plan.owner)
		return false
	for layer in plan.body_layers:
		if layer == null:
			if report:
				push_error("[OperatorBodyPresenter] plan names a null body layer")
			return false
		if not _owner_of_layer.has(layer):
			if report:
				push_error("[OperatorBodyPresenter] plan names an unregistered body layer")
			return false
		if _owner_of_layer[layer] != plan.owner:
			if report:
				push_error(
					"[OperatorBodyPresenter] plan for owner %d names a body layer owned by %d"
					% [plan.owner, _owner_of_layer[layer]]
				)
			return false
	for overlay in plan.overlays:
		if overlay == null:
			if report:
				push_error("[OperatorBodyPresenter] plan names a null overlay")
			return false
		if not _owners_of_overlay.has(overlay):
			if report:
				push_error("[OperatorBodyPresenter] plan names an unregistered overlay")
			return false
		if not (_owners_of_overlay[overlay] as Array).has(plan.owner):
			if report:
				push_error(
					"[OperatorBodyPresenter] plan for owner %d names an overlay it does not wear"
					% plan.owner
				)
			return false
	return true


## Take the body for the legacy full-body sprite and display it.
##
## This owner is a single sprite, so acquiring it shows it outright; existing
## callers depend on that. Multi-layer owners cannot behave this way because
## their constituent animations need configuring before display, so their
## layers stay hidden here and are enabled by their own play functions before
## the frame is drawn — which is what keeps the handoff atomic.
func present_legacy_full_body() -> bool:
	return present(OperatorBodyPresentationPlan.create(
		Owner.LEGACY_FULL_BODY, _layers_by_owner.get(Owner.LEGACY_FULL_BODY, [])
	))


## Acquisition by owner id, for callers that have no layer list to hand.
## LEGACY_FULL_BODY routes through `present_legacy_full_body()` so the display
## semantics live in one clearly named place.
func set_owner(owner: int) -> bool:
	if owner == Owner.LEGACY_FULL_BODY:
		return present_legacy_full_body()
	return present(OperatorBodyPresentationPlan.create(owner))


## Declared by a modular composition that has already configured its layers.
## Retires the legacy body and every authored rig — including their overlays —
## without disturbing the modular layers the caller just set up.
func claim_modular() -> void:
	# LegacyFullBody is stopped, not merely hidden. It used to be left playing
	# because overlay synchronization and the melee hit-window scan both read its
	# frame, which made a renderer nobody could see the timing authority for
	# visible animation and for gameplay. Slice C1 moved both onto the visible
	# presentation clock, so the hidden clock is gone and the legacy body retires
	# like any other body layer.
	for owner in _layers_by_owner:
		if owner == Owner.MODULAR_BODY:
			continue
		_retire_layers(_layers_by_owner[owner])
	# Preempting an owner must take its overlays down with its body, or a
	# retired rig leaves its weapon floating over the incoming composition.
	# Overlays the modular rig itself wears are kept: the cape is worn by both
	# the legacy strips and the modular rig, and retiring it here would blank a
	# cosmetic the incoming owner is still wearing.
	_retire_layers(_overlays_not_worn_by(Owner.MODULAR_BODY))
	_owner = Owner.MODULAR_BODY


## Clear the modular layers without handing the body to the legacy sprite.
## Used when another owner is taking over, where re-showing legacy would draw a
## second body behind the incoming animation.
##
## Strictly modular-scoped: this must never disturb an authored rig that
## currently owns the body, which is exactly what a single global overlay pool
## used to do.
func release_modular() -> void:
	_retire_layers(_layers_by_owner.get(Owner.MODULAR_BODY, []))
	_retire_layers(_modular_only_overlays())
	if _owner == Owner.MODULAR_BODY:
		_owner = Owner.NONE


## Stop and hide an authored rig, including its owner-scoped overlays, and
## surrender the body so the next owner starts from a clean slate.
func release_rig(owner: int) -> void:
	_retire_layers(_layers_by_owner.get(owner, []))
	_retire_layers(_overlays_by_owner.get(owner, []))
	if _owner == owner:
		_owner = Owner.NONE


## Show one registered layer. STRICT: the renderer must belong to the current
## owner.
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
	if _owners_of_overlay.has(layer):
		if not (_owners_of_overlay[layer] as Array).has(_owner):
			push_error(
				"[OperatorBodyPresenter] show_layer() on an overlay owner %d does not wear"
				% _owner
			)
			return false
		layer.visible = true
		return true
	push_error("[OperatorBodyPresenter] show_layer() on an unregistered renderer")
	return false


## Explicitly transfer the body to `owner`, atomically retiring whoever held it.
##
## This is the honest name for the decision that `show_layer()` refuses to make
## implicitly. `layers` may be empty: an authored rig takes the body first and
## enables its own layers as it starts playing them.
##
## Cancelling the outgoing owner's gameplay lifecycle is the CALLER's job. This
## class moves pixels; it does not know what a posture bridge or an attack
## startup means, and must not learn.
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
	if not is_registered_layer(layer):
		push_error("[OperatorBodyPresenter] hide_layer() on an unregistered renderer")
		return
	layer.visible = false
	if stop_playback and layer.is_playing():
		layer.stop()


# --- internals ---------------------------------------------------------------

func _is_known_owner(owner: int) -> bool:
	return Owner.values().has(owner)


## Overlays worn only by the modular rig. A shared overlay such as the cape is
## also worn by the legacy body, so releasing modular must leave it to whoever
## takes the body next rather than blanking it here.
func _modular_only_overlays() -> Array:
	var scoped: Array = []
	for overlay in _overlays_by_owner.get(Owner.MODULAR_BODY, []):
		if (_owners_of_overlay.get(overlay, []) as Array).size() == 1:
			scoped.append(overlay)
	return scoped


## Every registered overlay that `owner` does not wear. Retiring by owner has to
## respect sharing, or taking the body blanks a cosmetic the new owner wears too.
func _overlays_not_worn_by(owner: int) -> Array:
	var retire: Array = []
	for overlay in _owners_of_overlay:
		if not (_owners_of_overlay[overlay] as Array).has(owner):
			retire.append(overlay)
	return retire


func _retire_all() -> void:
	for candidate in _layers_by_owner:
		_retire_layers(_layers_by_owner[candidate])
	# Owner-scoped overlays are not body layers, but they belong to whichever
	# body wore them, so they retire with it and the new owner re-adds its own.
	for candidate in _overlays_by_owner:
		_retire_layers(_overlays_by_owner[candidate])


func _retire_layers(layers: Array) -> void:
	_hide_layers(layers, true)


func _hide_layers(layers: Array, stop_playback: bool) -> void:
	for layer in layers:
		if layer == null:
			continue
		layer.visible = false
		if stop_playback and layer.is_playing():
			layer.stop()
