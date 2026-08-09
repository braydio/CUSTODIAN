# Melee Targeting And Range Readability

- **Status:** implemented-v1
- **Owner:** gameplay/combat
- **Runtime target:** Godot 4 (`custodian/`)
- **Last updated:** 2026-08-09

## Contract

Free aim remains player authority. Before a melee attack, the deterministic
soft-target resolver scores eligible enemies by angle, distance, reliable
reach, and current-target stickiness. It publishes the passive target and a
progressive range preview without moving or rotating the Operator.

At attack input, the current target is revalidated once. A profile may apply
one bounded facing correction and one bounded additive drive-distance override.
The authored fast-chain direction clamp then resolves final facing. Attack
commit freezes facing, target identity, and drive direction for that link.
Target motion and cursor motion never steer an active swing; a new chain link
may resolve a new solution under the existing 75-degree retarget limit.

## Reach Model

```text
reliable drive = authored drive × reliable fraction
reliable reach = hit range + reliable drive
assist reach   = reliable reach + profile acquire extra
preview reach  = min(180 px, assist reach + 48 px)
```

Reliable contact means stationary current geometry predicts contact from an
attack begun now, including bounded facing correction and the conservative
drive fraction. It is not guaranteed damage. Collision, interruption, or target
movement may still cause a miss, and the ordinary hitbox/contact pipeline is
the only damage authority.

## Selection And Hysteresis

- New candidates use a 42-degree acquire cone.
- The current target may remain inside a 58-degree retain cone and 20 px range
  grace.
- Score weights are angle `0.58`, distance `0.30`, reliable-reach bonus `0.12`,
  and current-target bonus `0.18`.
- A challenger must exceed the retained score by `0.14` before switching.
- Melee preview is weapon-aware and hard-capped at 180 px; the legacy 360 px
  combat presentation radius is not melee assist authority.

## Ring Language

The procedural target ring is passive presentation. Far selection is larger
and faint red-orange. Approach contracts toward amber while four cardinal
ticks converge. Reliable attack-start contact is tight green with a one-shot
settle pulse. Presentation smooths at response `14.0` and never feeds values
back into targeting.

## Ownership And Non-goals

- `melee_target_resolver.gd`: scoring, reach, correction, and assist-drive math.
- `operator.gd`: candidate gathering, immutable per-link commitment, telemetry.
- `MeleeAttackProfile`: opt-in assist tuning.
- existing attack drive: collision-safe displacement authority.
- existing melee hitbox/contact logic: damage authority.
- enemy parry-critical capture: separate authority, unchanged.

Hard lock, camera orbit, target-relative strafing, target cycling, homing,
teleportation, enlarged hitboxes, and guaranteed damage are non-goals. Hard
lock remains an optional follow-up after soft-target feel review.
