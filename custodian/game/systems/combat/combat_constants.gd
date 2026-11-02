## Combat constants for CUSTODIAN.
##
## Shared enums and values used by Operator, Enemy, and projectile damage
## pipelines. This file is autoload-safe — it contains only constants and
## enums, no runtime state.

class_name CombatConstants

## How hard a hit lands. Affects reaction selection, not damage calculation.
##
## LIGHT  — Standard chip. Small recoil on enemies, small hit-react on Operator.
## HEAVY  — Committing strike. Guaranteed stagger on light targets, heavy
##          stagger on Operator. Overrides threshold-based branching.
## INTERRUPT — Cancel-focused. Interrupts enemy windups without requiring
##             damage-based stagger. Used by parry, future special attacks.
enum HitStrength {
	LIGHT,
	HEAVY,
	INTERRUPT,
}

## What kind of damage is being dealt. Currently informational; future
## damage-resistance and armor systems will branch on this.
##
## PHYSICAL  — Default melee and ranged.
## EXPLOSIVE — Future: grenades, traps, environmental.
## ENERGY    — Future: lasers, special attacks, cosmic.
enum DamageType {
	PHYSICAL,
	EXPLOSIVE,
	ENERGY,
}

## Melee `knockback_force` values (authored on MeleeAttackProfile/enemy
## exports, e.g. 56-840) are not pixels — Enemy.apply_melee_impact() divides
## by this constant to get the actual per-hit displacement in pixels before
## chain/contact multipliers. Use it when authoring or reading knockback_force
## so the numbers stay legible (a "840" hit is ~14px, not a launch into orbit).
const MELEE_KNOCKBACK_FORCE_TO_DISTANCE_PX := 1.0 / 60.0

## Convert a HitStrength enum value to a readable string for observability.
static func hit_strength_name(strength: int) -> String:
	match strength:
		HitStrength.LIGHT:
			return "light"
		HitStrength.HEAVY:
			return "heavy"
		HitStrength.INTERRUPT:
			return "interrupt"
		_:
			return "unknown"

## Convert a DamageType enum value to a readable string for observability.
static func damage_type_name(damage_type: int) -> String:
	match damage_type:
		DamageType.PHYSICAL:
			return "physical"
		DamageType.EXPLOSIVE:
			return "explosive"
		DamageType.ENERGY:
			return "energy"
		_:
			return "unknown"
