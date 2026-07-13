Yes — that is the right direction. You need a **secondary action resolver**, not hardcoded “secondary = parry” or “secondary = aim.”

The clean rule should be:

```text
Secondary button asks equipped secondary slot what it wants to do.
If no usable secondary item exists, fall back to parry.
If the equipped secondary item is a parry enhancer, still use parry, but modify it.
```

That gives you sidearm, shield/parry gear, tools, relics, etc. without rewriting input logic every time.

---

# Recommended rule

## Secondary action priority

```text
1. If Secondary Slot contains active sidearm:
   → secondary = sidearm aim / fire-ready

2. If Secondary Slot contains parry modifier / defensive focus:
   → secondary = parry with modifier

3. If Secondary Slot is empty:
   → secondary = base parry

4. If Secondary Slot contains non-combat utility:
   → secondary = utility action, or fallback to parry depending on item config
```

So your exact idea becomes:

```text
Secondary slot equipped with sidearm = use sidearm
Secondary slot empty = parry
Secondary slot equipped with parry enhancer = improved parry
```

That is good because it makes the sidearm a **loadout decision**, not a free permanent extra button.

---

# Player-facing behavior

## No secondary equipped

```text
Primary: melee / current weapon attack
Secondary: parry
```

This keeps early game tactical.

## Sidearm equipped

```text
Primary: melee / current weapon attack
Secondary hold: ready sidearm
Primary while ready: fire sidearm
Secondary release: lower sidearm
```

This preserves your existing “hold secondary to aim, primary to fire” idea.

## Parry relic / guard module equipped

```text
Primary: melee / current weapon attack
Secondary: enhanced parry
```

Examples:

```text
Timing Widening Module: +0.06s perfect parry window
Kinetic Catcher: successful parry refunds stamina
Grief Mirror: perfect parry reflects light projectiles
Anchor Brace: late guard reduces more damage but slows movement
```

---

# The design advantage

This gives the player a real choice:

```text
Equip sidearm:
  more ranged flexibility
  less defensive timing power

Equip parry enhancer:
  stronger dueling / anti-melee defense
  less ranged utility

Equip nothing:
  simple base parry
  no bonus
```

That is way better than “sidearm is always available forever” because then the optimal answer becomes obvious.

---

# Implementation shape

Add a secondary slot item contract.

Something like:

```gdscript
enum SecondaryActionKind {
	NONE,
	SIDEARM,
	PARRY_MODIFIER,
	UTILITY
}
```

Or in data:

```gdscript
class_name SecondarySlotProfile
extends Resource

@export var id: StringName
@export var display_name: String
@export var action_kind: StringName = &"none"

@export var sidearm_profile: Resource
@export var parry_modifier: Resource
@export var utility_profile: Resource

@export var fallback_to_parry := true
```

Then input does not decide directly. It asks:

```gdscript
func resolve_secondary_action() -> StringName:
	var item := equipment.get_secondary_slot_item()

	if item == null:
		return &"parry"

	match item.action_kind:
		&"sidearm":
			return &"sidearm"
		&"parry_modifier":
			return &"parry"
		&"utility":
			if item.fallback_to_parry:
				return &"parry"
			return &"utility"
		_:
			return &"parry"
```

Then:

```gdscript
func _on_secondary_pressed() -> void:
	match resolve_secondary_action():
		&"sidearm":
			_enter_sidearm_ready()
		&"parry":
			_start_parry_with_equipped_modifier()
		&"utility":
			_use_secondary_utility()
```

---

# Parry modifier profile

Make parry-enhancing secondary items modify values rather than replace the whole parry system.

```gdscript
class_name ParryModifierProfile
extends Resource

@export var perfect_window_bonus := 0.0
@export var guard_window_bonus := 0.0
@export var whiff_recovery_multiplier := 1.0
@export var guard_damage_multiplier := 1.0
@export var stagger_multiplier := 1.0
@export var stamina_refund_on_success := 0.0
@export var can_deflect_projectiles := false
@export var can_parry_heavy := true
```

Base parry uses:

```text
perfect window: 0.16s
guard window: 0.18s
whiff recovery: 0.45s
```

A parry relic could change it to:

```text
perfect window: 0.22s
guard window: 0.20s
whiff recovery: 0.50s
```

That creates tradeoffs.

---

# Sidearm profile

The sidearm should be an actual secondary-slot item.

```gdscript
class_name SidearmProfile
extends Resource

@export var id: StringName
@export var display_name: String
@export var ammo_kind: StringName
@export var damage := 1.0
@export var stagger := 0.25
@export var aim_move_speed_multiplier := 0.65
@export var fire_cooldown := 0.35
@export var reload_time := 1.0
@export var magazine_size := 6
@export var noise_radius := 220.0
```

Then an equipped sidearm profile suppresses parry on secondary button because it claims the secondary action.

---

# Important input distinction

I would use:

```text
Secondary pressed/held = ready sidearm or start parry
Primary while sidearm-ready = fire sidearm
```

Not:

```text
Secondary tap = parry
Secondary hold = sidearm
```

That sounds flexible, but it gets messy and causes accidental parries/aims. Better to let the **loadout** decide the meaning.

So:

```text
No sidearm equipped:
  Secondary press = parry

Sidearm equipped:
  Secondary hold = sidearm ready
  Primary = fire
  Release secondary = lower sidearm

Parry enhancer equipped:
  Secondary press = enhanced parry
```

---

# What happens when sidearm is unlocked?

Unlocking sidearm should not automatically override the secondary button forever.

Instead:

```text
Player unlocks sidearm inventory slot item.
Player can equip sidearm into Secondary Slot.
If equipped, secondary becomes sidearm-ready.
If unequipped, secondary returns to parry.
```

This preserves player agency.

I would not make the sidearm a universal built-in fallback unless the game fantasy demands it. A permanent sidearm fallback makes parry less central and can reintroduce spam.

---

# Suggested equipment examples

## Empty secondary slot

```text
Secondary action: Base Parry
```

Good for early game.

## Default Pistol

```text
Secondary action: Sidearm Ready
Tradeoff: no parry enhancer
```

Good for mixed melee/ranged play.

## Kinetic Parry Lattice

```text
Secondary action: Enhanced Parry
Effect: +0.05s perfect window, +25% enemy stagger
Tradeoff: no sidearm
```

Good for Souls-like timing play.

## Anchor Guard

```text
Secondary action: Heavy Guard / Parry
Effect: late guard damage multiplier improves from 0.35 to 0.20
Tradeoff: longer whiff recovery
```

Good for cautious players.

## Signal Deflector

```text
Secondary action: Enhanced Parry
Effect: perfect parry can deflect light projectiles
Tradeoff: weaker melee stagger
```

Good for ranged enemy zones.

---

# Codex instruction

Give Codex this:

```text
Implement secondary-action resolution for CUSTODIAN so the secondary button is loadout-driven instead of hardcoded.

Design:
- The secondary slot determines what the secondary input does.
- If the secondary slot contains a sidearm, secondary enters sidearm-ready / aim mode.
- If the secondary slot is empty, secondary performs base parry.
- If the secondary slot contains a parry-enhancing item, secondary performs parry with that item's modifiers.
- If the secondary slot contains utility, use that utility only if the item explicitly claims the secondary action; otherwise fallback to parry.
- Unlocking the sidearm should not permanently override parry. It should only override parry while the sidearm is equipped in the secondary slot.

Rules:
- Preserve ranged-ready behavior for equipped sidearm.
- Preserve base parry when no secondary sidearm is equipped.
- Do not use tap-vs-hold ambiguity for deciding parry vs sidearm. Use equipped item type.
- Primary while sidearm-ready fires the sidearm.
- Releasing secondary exits sidearm-ready.
- Parry modifiers should alter ParryComponent parameters, not replace the parry system.

Add/extend:
- Secondary slot equipment data/profile.
- Secondary action resolver on the Operator or equipment component.
- SidearmProfile resource if not already present.
- ParryModifierProfile resource.
- Operator input routing:
  - secondary pressed -> resolve action
  - sidearm -> enter sidearm-ready
  - parry -> start parry with equipped modifier
  - utility -> use utility action
- Validation tests/manual checks:
  1. Empty secondary slot = secondary parries.
  2. Default pistol equipped in secondary slot = secondary readies pistol.
  3. Primary while pistol-ready fires pistol.
  4. Releasing secondary lowers pistol.
  5. Parry enhancer equipped = secondary parries with modified timing/stagger.
  6. Sidearm unlock alone does not override parry unless sidearm is equipped.
  7. Ranged primary behavior is not broken.
  8. Attack spam cannot freely cancel into parry unless explicitly allowed by combat state rules.

Update docs:
- design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md
- Create or update a secondary-slot/loadout section in the combat/equipment docs.
- Update custodian/docs/ai_context/CURRENT_STATE.md.
- Call out any documentation drift between existing sidearm fallback behavior and the new loadout-driven secondary action resolver.
```

---

# My recommendation

Your rule should be:

```text
Secondary slot empty = parry
Secondary slot sidearm = sidearm
Secondary slot parry item = better parry
```

That is clean, understandable, and gives you actual buildcraft. It also solves the “too easy / button spam” problem better than simply adding more buttons.

# ADDENDUM / CORRECTIONS

Yes — that is probably better.

For **sidearm equipped**, make:

```text
Tap Secondary  = quick / unaimed sidearm shot
Hold Secondary = aim sidearm
Primary while aiming = aimed sidearm shot
```

Then for **no sidearm / parry module**, make:

```text
Tap Secondary  = parry
Hold Secondary = guard
```

So the secondary slot changes the tap behavior too.

## Clean final rule

| Secondary slot    | Tap Secondary        | Hold Secondary   | Primary while held     |
| ----------------- | -------------------- | ---------------- | ---------------------- |
| Empty             | Parry                | Guard            | Current primary attack |
| Parry/guard item  | Enhanced parry       | Enhanced guard   | Current primary attack |
| Sidearm           | Quick shot           | Aim sidearm      | Fire aimed shot        |
| Shield/brace item | Shield bash or parry | Strong guard     | Current primary attack |
| Tool/relic        | Quick use            | Charged/held use | Current primary attack |

That makes the sidearm feel like an actual equipped secondary weapon instead of awkwardly sharing parry.

## Sidearm behavior

### Tap Secondary — quick shot

This should be fast but imperfect.

```text
Startup: 0.10–0.14s
Accuracy: lower
Damage: normal or 85–100%
Stagger: low-medium
Recovery: 0.30–0.45s
Ammo cost: 1
Movement: brief slowdown
```

Use it for:

```text
panic shot
finishing weak enemies
interrupting a light enemy
shooting while not fully committed to aim stance
```

It should not be a machine-gun spam button. Add recovery and ammo pressure.

### Hold Secondary — aim

After threshold:

```text
Hold threshold: 0.18s
Enter sidearm-ready
Movement speed: 60–70%
Facing/aim locks or slows
Primary fires aimed shot
Release Secondary lowers weapon
```

Aimed shot should be better:

```text
Accuracy: high
Damage: normal or +10%
Stagger: higher
Recovery: slightly longer than quick shot
```

## What happens to parry when sidearm is equipped?

This is the tradeoff:

```text
If sidearm is equipped, you lose tap-parry and hold-guard on Secondary.
```

That is good. It makes the sidearm a real build choice.

So:

```text
Empty slot = defense
Sidearm slot = ranged secondary
Parry module = stronger defense
```

That is much cleaner than trying to make one button do quick shot, aim, parry, and guard all at once.

## My corrected recommendation

Use this:

```text
Empty secondary slot:
  Tap Secondary  = parry
  Hold Secondary = guard

Parry/guard secondary item:
  Tap Secondary  = enhanced parry
  Hold Secondary = enhanced guard

Sidearm secondary item:
  Tap Secondary  = quick unaimed shot
  Hold Secondary = aim sidearm
  Primary while aiming = aimed shot
```

This gives you three build identities:

```text
Defensive: no sidearm, reliable parry/guard
Duelist: parry module, better defensive timing
Gunslinger: sidearm, quick shot/aimed shot but weaker defense
```

## Codex correction

Send this as a correction to the prior spec:

```text
Correction to secondary input design:

When a sidearm is equipped in the secondary slot, tap secondary should NOT parry. Tap secondary should perform a quick unaimed sidearm shot.

Final secondary-slot behavior:
- Empty secondary slot:
  - tap secondary = base parry
  - hold secondary = base guard
- Parry/guard enhancer equipped:
  - tap secondary = enhanced parry
  - hold secondary = enhanced guard
- Sidearm equipped:
  - tap secondary = quick unaimed sidearm shot
  - hold secondary = sidearm-ready / aim
  - primary while sidearm-ready = aimed sidearm shot
  - release secondary = lower sidearm
- Sidearm equipped replaces both parry and guard on the secondary input.
- Sidearm unlock alone does not change controls; the sidearm must be equipped in the secondary slot.

Balance:
- Quick unaimed shot should have short startup but meaningful recovery and lower accuracy/stagger than aimed shot.
- Aimed shot should require holding secondary past the hold threshold, slow movement while aiming, and use primary to fire.
- Defensive parry/guard should remain available by unequipping sidearm or equipping a parry/guard secondary item.

Validation:
1. Empty slot tap parries.
2. Empty slot hold guards.
3. Parry item tap enhanced-parries.
4. Parry item hold enhanced-guards.
5. Sidearm tap quick-shoots.
6. Sidearm hold aims.
7. Primary while sidearm-ready fires aimed shot.
8. Releasing secondary lowers sidearm.
9. Sidearm equipped does not also parry from tap secondary.
10. Sidearm unlock alone does not override empty-slot parry/guard.
```

That is the better design.
