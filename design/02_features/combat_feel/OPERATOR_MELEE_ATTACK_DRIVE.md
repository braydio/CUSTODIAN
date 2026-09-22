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
- **A genuine authored fast-chain continuation carries momentum across the
  handoff.** Every other `_begin_attack_drive()` still hard-cancels.

The Vigil dagger is the reference at 7/9/11 pixels. The Sword-Cleaver uses
9/11/14 pixels with progressively lower steering. Fists use 5/7/9/13 pixels
across its four links. The Katana remains separate and retains zero drive
pending its own tuning.

### Chain continuity

`_begin_attack_drive()` opens by cancelling, which strips the outgoing drive the
instant a successor starts. The successor then waits out its own
`drive_delay_sec` before moving, so a chain read as drive, gap, drive. The gap
was about 2-3 physics frames per seam on the Fists chain.

A continuation is recognised structurally, not by animation name: the live drive
records the chain step it belongs to, and only step N+1 of the same chain may
inherit from step N. A fresh attack, a chain restart at step 0, and any
non-chain melee therefore inherit nothing.

The bridge runs across the incoming link's delay at a speed decaying linearly
from the outgoing link's own authored curve speed to zero. It is funded first
from whatever distance the outgoing link had authored but not yet spent, and
then from the incoming link's `_attack_drive_distance_remaining`, which the
incoming drive consequently does not get to spend later. **The bound is
therefore exact rather than approximate**: total drive displacement across a
seam equals the sum of the two authored distances and cannot exceed it. Any
unspent bridge is dropped the moment the incoming drive starts, so nothing
stacks.

A drive that runs out of distance or duration on its own now *completes* rather
than cancels, which preserves the chain step and the handoff speed. An
interruption still cancels, and cancelling still clears the carry, so every
interruption above takes carried momentum with it.

## Validation

`operator_vigil_dagger_smoke.gd` covers input filtering, collision truncation,
no snapback, and interruption cancellation.
`operator_sword_cleaver_smoke.gd` covers per-link profile selection, bounded
finisher drive, canonical dagger default, and frame-synchronized layers.
`operator_unarmed_fast_chain_smoke.gd` covers the Fists per-link distances, the
chain-handoff continuity above, the exact displacement bound at each seam, that
a chain restart inherits nothing, that dodge/damage/block clear carried
momentum, that blocking geometry still truncates it, and that opposing input
cannot reverse it mid-handoff.

## Limitations

- The integration remains inside the existing Operator velocity coordinator.
- Cleaver heavy drive remains design guidance until heavy art exists.
- Enemy melee does not consume this Operator-specific integration.

## Next Agent Slice

Goal: tune per-link delay/duration against live gameplay capture. Note that the
Fists delays were chosen partly to keep the pre-continuity gap short; with the
seam bridged they can be re-read purely for how the swing lands.

Constraints: preserve collision authority, bounded distance, and no target
magnetism or return movement.

Acceptance: measured displacement matches the reviewed silhouettes at fixed
physics rates and all interruption regressions remain green.
