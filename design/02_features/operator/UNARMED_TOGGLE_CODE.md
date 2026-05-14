# Unarmed Toggle Implementation Notes

Status: implementation-ready

## Runtime Files

- `custodian/game/actors/operator/operator_weapon_definition.gd`
- `custodian/game/actors/operator/operator.gd`
- `custodian/game/actors/operator/unarmed_definition.tres`
- `custodian/project.godot`

## Weapon Definition Additions

`OperatorWeaponDefinition` owns profile metadata and combat/movement multipliers:

```gdscript
@export var display_name: String = ""
@export var weapon_kind: String = "melee"
@export var primary_intent: String = "melee_fast"
@export var secondary_intent: String = "melee_heavy"
@export var move_speed_multiplier: float = 1.0
@export var acceleration_multiplier: float = 1.0
@export var recovery_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var stagger_multiplier: float = 1.0
```

## Fists Resource

`unarmed_definition.tres` uses:

```text
weapon_id = fists
display_name = Fists
weapon_kind = unarmed
primary_intent = unarmed_fast
secondary_intent = unarmed_heavy
move_speed_multiplier = 1.15
acceleration_multiplier = 1.30
recovery_multiplier = 0.80
range_multiplier = 0.70
damage_multiplier = 0.65
stagger_multiplier = 0.55
```

## Operator Selection API

Required API:

```gdscript
func get_current_combat_profile() -> OperatorWeaponDefinition
func request_toggle_unarmed() -> void
func request_cycle_weapon(direction: int) -> void
func try_apply_pending_weapon_selection() -> void
func can_apply_weapon_selection_now() -> bool
```

All selection requests queue a dictionary and apply only from safe states. Runtime input calls request methods only;
it must not mutate visual equipment or animation state directly.

After a queued selection applies, runtime refreshes weapon presentation and requests the existing `equip_weapon`
state if available. If the `equip_weapon` clip is missing, the state exits safely to `idle`.

## Attack Resolution

Primary and secondary attacks resolve through profile intent:

```gdscript
var profile := get_current_combat_profile()
var intent := profile.primary_intent # or secondary_intent
_request_attack_state(_attack_kind_from_intent(intent))
```

Unarmed attack behavior is therefore data-driven by the fists resource and reuses existing attack states.
`unarmed_fast` routes to the shared `attack_fast` state and `unarmed_heavy` routes to the shared
`attack_heavy` state. Do not add unarmed-only combat states for these actions.

Until production unarmed heavy art exists, the runtime may fall back to a compatible body-only attack animation,
but it must not play weapon-specific anticipation or weapon overlays while the fists profile is active.

## Movement

Movement speed and acceleration multiply by the current combat profile:

```gdscript
var profile := get_current_combat_profile()
move_speed *= profile.move_speed_multiplier
accel_rate *= profile.acceleration_multiplier
```

No `if using_unarmed` movement branch should be required.
