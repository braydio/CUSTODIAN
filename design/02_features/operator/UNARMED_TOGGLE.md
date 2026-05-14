# Unarmed Toggle / Fists Selection System

Status: implementation-ready

## Purpose

Unarmed combat is a first-class selectable `OperatorWeaponDefinition` profile. It is not a separate combat mode,
not a separate attack state, and not part of normal armed weapon cycling.

## Input Behavior

- `toggle_unarmed`: switches between fists and the last selected armed weapon.
- `cycle_next_weapon` / `cycle_prev_weapon`: select armed weapons only; fists are excluded.
- `attack_primary`: resolves through the current combat profile's `primary_intent`.
- `attack_secondary`: resolves through the current combat profile's `secondary_intent`.

Canonical profile/action intents:

- `ranged.primary`: `ranged_fire`
- `ranged.secondary`: reserved for a future ranged secondary action; likely aimed/focused shot
- `melee.primary`: `melee_fast`
- `melee.secondary`: `melee_heavy`
- `unarmed.primary`: `unarmed_fast`
- `unarmed.secondary`: `unarmed_heavy`

Unarmed is a combat profile, not an animation state. `unarmed_fast` and `unarmed_heavy` reuse the shared
`attack_fast` and `attack_heavy` states while resolving profile-specific animation names, hit windows, FX, and
stat multipliers through `unarmed_definition.tres`.

Keyboard defaults:

- `F`: toggle fists
- `E`: cycle next armed weapon
- `Q`: cycle previous armed weapon
- `M1`: primary attack
- `Shift + M1`: secondary attack

## Selection Model

Operator selection state is simulation-owned:

- `armed_weapon_index`
- `last_armed_weapon_index`
- `using_unarmed`
- `pending_weapon_selection`

The active combat profile is:

```text
using_unarmed ? unarmed_definition : armed_weapons[armed_weapon_index]
```

If no armed weapons exist, the active profile is always fists.

## State Rules

Selection changes are queued and applied only in safe states:

- idle
- walk
- sprint

Unsafe states:

- attack states
- block
- stagger
- death
- equip weapon

Queued selection must not mutate an already-started attack. Attack resolution snapshots the intent and combat
numbers at attack start.

## Edge Cases

- Toggling from armed queues/selects fists.
- Toggling from fists queues/restores `last_armed_weapon_index`.
- Cycling while fists are selected selects an armed weapon and exits fists.
- Cycling with no armed weapons leaves fists active.
- Removing a selected weapon clamps to a valid armed index or falls back to fists.
- `pending_weapon_selection` is runtime-only and should not be persisted.

## Acceptance Tests

- Armed katana -> `toggle_unarmed` -> current profile is `fists`.
- Fists -> `toggle_unarmed` -> previous armed profile is restored.
- Fists -> `cycle_next_weapon` -> armed weapon selected, not fists.
- No armed weapons -> cycle/toggle -> profile remains fists.
- Fists + primary attack -> `unarmed_fast` intent enters the shared `attack_fast` state.
- Fists + secondary attack -> `unarmed_heavy` intent enters the shared `attack_heavy` state.
- Toggle during attack queues selection and applies after returning to a safe state.
- Fists movement uses `move_speed_multiplier = 1.15` and `acceleration_multiplier = 1.30`.
