extends RefCounted

## Generic passive-target attack rejection.
##
## Weapons ask this helper before they decide a body is un-hittable. A body in
## the `attack_rejector` group that implements `reject_attack(context)` gets to
## answer an incoming projectile or melee sweep with its own reaction (deflect,
## disapprove, flee) and the attack resolves as a harmless block instead of
## passing through. This keeps creature-specific checks out of weapon code so
## any harmless actor can opt in.

const GROUP := &"attack_rejector"

static func is_rejector(body: Node) -> bool:
	if body == null or not is_instance_valid(body): return false
	if not body.has_method("reject_attack"): return false
	if body.is_in_group(GROUP): return true
	if body.has_method("is_attack_rejector"): return bool(body.call("is_attack_rejector"))
	return false

## Returns the rejection result, or an empty Dictionary when `body` does not
## reject attacks. A non-empty result means the attack was consumed harmlessly.
static func reject(body: Node, context: Dictionary = {}) -> Dictionary:
	if not is_rejector(body): return {}
	var result: Variant = body.call("reject_attack", context)
	if result is Dictionary and not (result as Dictionary).is_empty(): return result as Dictionary
	if result is bool and not bool(result): return {}
	return {"rejected": true, "deflected": true, "damage_applied": 0.0}
