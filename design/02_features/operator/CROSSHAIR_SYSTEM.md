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

## Intent and Ballistic Feedback (two indicators)

The ranged aiming presentation has two complementary cues. The existing
procedural ranged reticle remains player intent; the smaller ballistic pip is
read-only prediction from the current frame-aware muzzle and physical weapon
axis. Neither cue is hit authority.

### Target / intent indicator

Follows mouse/controller desired aim, communicates posture/readiness/recoil,
and is not a hit guarantee. `TargetRing` remains separate enemy-selection and
melee strike-zone feedback.

### Ballistic pip

A procedural 16x16 marker answers "where does the current weapon centerline
pass through my intended target depth?" It is projected from the current
frame-aware muzzle, follows traversal/fine-angle lag and obstruction, predicts
only, and never deals damage:

```text
                       desired target
                            ◎
                           /
                          /
Operator ---- rifle ----> •
                          ^
                    ballistic pip
```

As the weapon catches up:

```text
T=0            T=.08          T=.16
  ◎ intent      ◎ intent       ◎
  • ballistic    •              •  aligned
```

Once the indicators merge, the shot is fully settled.

### Pip presentation by alignment

The pip consumes angular error / alignment from the aim solution
(`design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`,
Physical Aim Authority Contract):

- badly misaligned: dim, slightly wider/open, amber, visibly trailing
- improving: tightens and becomes brighter
- settled: the two visual states merge (⊕)

No floating percentage text. The player learns naturally: "the small inner
mark has not caught up yet -> firing now is a snap shot."

### Wall case

When the cursor is over an enemy but a wall occludes the barrel ray, the pip
sits on the wall: "my target is him, but my current firing solution hits this
wall." This is visible before the trigger is pulled.

### What this buys

Weapon traverse time, weight, commitment, readable handling differences,
meaningful aim recovery, meaningful snap shots, and meaningful ergonomics —
and when the player misses a snap shot, they can see why. That legibility is
the missing piece a single cursor-authoritative reticle cannot provide.

## Validation

- `operator_primary_ranged_modular_fire_smoke.gd` validates transition retargeting, committed fire direction, recovery direction, posture sequence, and upper/weapon direction plus frame agreement.
- `operator_ranged_ready_input_smoke.gd` validates readiness gating and exposed status.
- Main-scene parse/boot validates reticle scene wiring.
- `operator_ranged_ballistic_aim_smoke.gd` validates committed intent versus
  release-frame axis, physical muzzle origin, bounded/non-accumulating
  correction, target-depth prediction, obstruction, and snap-fire.
- `ranged_ballistic_reticle_smoke.gd` validates procedural aligned/tracking/
  obstructed pip state and read-only separation from the intent reticle.
- Moment Forge `combat/ranged_ballistic_alignment` provides full-capture review
  of cursor reversal, pip/intent separation, physical projectile travel, and
  subsequent alignment.
