# RANGED RETICLE SYSTEM

Status: active Godot implementation authority
Owner: gameplay presentation / HUD
Runtime: `custodian/game/ui/hud/components/ranged_reticle.gd`, `custodian/game/ui/hud/ui.gd`

## Purpose

Communicate the Operator's primary-ranged posture and fire readiness without a permanent READY label. Gameplay authority remains in `operator.gd`; the HUD reads `get_weapon_status()` and renders a procedural reticle.

## Ownership

- Operator owns ranged posture, transition progress, committed shot direction, ammunition, heat, cooldown, and `can_fire_now`.
- HUD owns screen positioning and feeds an immutable status snapshot to the reticle.
- `RangedReticle` owns only interpolation and `_draw()` presentation. It cannot change gameplay state.
- The existing `Crosshair` TextureRect remains available for drone command targeting and legacy arrow-aim fallback; it is not ranged-readiness authority.

## Posture Presentation

```text
relaxed     hidden
raising     fade in; brackets contract 18px -> 8px; center dot appears
ready       compact bright brackets and dot; one confirmation pulse on entry
firing      brackets kick outward using recoil/spread; center flashes
recovering  brackets settle toward ready
lowering    brackets expand and fade
reloading   open and dim
overheated  broken/open warning presentation
```

The reticle is procedural and requires no texture asset. Mouse aim places it at the current cursor. Controller/arrow aim places it at a clamped world-space aim point in front of the Operator. It hides with the main HUD, terminal, placement mode, non-primary ranged contexts, and relaxed/none posture.

## Status Contract

`get_weapon_status()` provides:

- `ranged_posture`
- `ranged_transition_ratio`
- `ranged_ready`
- `can_fire_now`
- `committed_aim_direction`
- existing heat, recoil/cooldown, ammo, aim mode, aim direction, and player position values

A future authored ready sound may play once on `raising -> ready`; direction retargets must not retrigger it. No sound asset is required for the procedural V1.

## Validation

- `operator_primary_ranged_modular_fire_smoke.gd` validates transition retargeting, committed fire direction, recovery direction, posture sequence, and upper/weapon direction plus frame agreement.
- `operator_ranged_ready_input_smoke.gd` validates readiness gating and exposed status.
- Main-scene parse/boot validates reticle scene wiring.
