class_name OperatorBodyPresentationPlan
extends RefCounted

## A presentation-only request for the Operator body.
##
## Deliberately small: it names an owner and the body layers that owner wants
## visible, plus any owner-scoped overlays. It carries no gameplay state, no
## attack metadata, no weapon stats, no input and no animation timing
## authority. Semantic animation choice and identity resolution stay with the
## caller and with OperatorAnimationSelector.

## The body owner this presentation belongs to (OperatorBodyPresenter.Owner).
var owner: int = 0

## Body layers to enable. Every entry must be registered to `owner`; the
## presenter rejects a plan that reaches for another owner's layers.
##
## An empty list is meaningful and common: an authored rig acquires the body
## first and then shows its own layers as it plays them, which keeps the
## handoff atomic without the presenter having to know which art exists.
var body_layers: Array = []

## Cosmetic layers that ride along with this body (cape, rig weapon overlay).
## They are not body layers and never count toward the one-body invariant.
var overlays: Array = []


static func create(plan_owner: int, layers: Array = [], plan_overlays: Array = []) -> OperatorBodyPresentationPlan:
	var plan := OperatorBodyPresentationPlan.new()
	plan.owner = plan_owner
	plan.body_layers = layers
	plan.overlays = plan_overlays
	return plan
