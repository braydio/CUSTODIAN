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
