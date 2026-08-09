# Operator Melee Attack Drive

- **Status:** implemented-v1
- **Owner:** gameplay/combat
- **Runtime target:** Godot 4 (`custodian/`)

## Purpose

Attack drive is profile-owned world-space momentum contributed by a melee
attack. It advances the `CharacterBody2D` through velocity,
`move_and_slide()`, and collision resolution; it never tweens or restores the
Operator position and never magnetically tracks a target.

Soft targeting may resolve one bounded facing correction and one additive
drive-distance override before an attack link commits. Once drive begins its
direction and distance are immutable: target movement cannot steer it, no
homing occurs, and collision remains authoritative.

`MeleeAttackProfile` owns distance, delay, duration, retained input influence,
falloff, and collision-stop policy. `OperatorWeaponDefinition` may supply one
profile per fast-chain link. `operator.gd` consumes both contracts generically.

## Runtime Contract

- Positive distance and duration begin drive along locked attack facing.
- Sampling is bounded by configured remaining distance.
- Forward and lateral input retain only the configured influence.
- Backward input cannot reverse an active drive.
- Whiffs and hits carry identical momentum.
- Blocking geometry truncates unused drive.
- No return-to-origin occurs.
- Block, dodge, damage reaction, critical execution, weapon selection,
  portal/ARRN locks, and death cancel remaining drive.

The Vigil dagger is the reference at 7/9/11 pixels. The Sword-Cleaver uses
9/11/14 pixels with progressively lower steering. The Katana remains separate
and retains zero drive pending its own tuning.

## Validation

`operator_vigil_dagger_smoke.gd` covers input filtering, collision truncation,
no snapback, and interruption cancellation.
`operator_sword_cleaver_smoke.gd` covers per-link profile selection, bounded
finisher drive, canonical dagger default, and frame-synchronized layers.

## Limitations

- The integration remains inside the existing Operator velocity coordinator.
- Cleaver heavy drive remains design guidance until heavy art exists.
- Enemy melee does not consume this Operator-specific integration.

## Next Agent Slice

Goal: tune per-link delay/duration against live gameplay capture.

Constraints: preserve collision authority, bounded distance, and no target
magnetism or return movement.

Acceptance: measured displacement matches the reviewed silhouettes at fixed
physics rates and all interruption regressions remain green.
