# Ranged Ballistic Aim Resolution (Retired Authority Experiment)

- Status: `superseded by single player-intent firing authority`
- Authority: `design/02_features/operator/CROSSHAIR_SYSTEM.md`, `design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md`, and `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`
- Prerequisite: completed `OPERATOR_FRAME_AWARE_WEAPON_SOCKETS.md` slice.
- Historical goal: test release-time physical weapon-axis authority and an
  honest dual-reticle presentation.
- Superseding decision: the experiment cost more player explanation and
  calibration than its weapon-weight benefit justified. Sockets retain muzzle,
  grip, ejection, layering, and debug ownership; accepted player aim owns the
  shot distribution center for all ranged weapons.
- Current acceptance: zero-spread shots travel from the release-frame muzzle
  through the trigger-time accepted world aim point; spread applies afterward;
  the intent reticle is the only production ranged reticle.

## Historical Completion and Retirement

- Trigger-time state now stores `accepted_aim_direction` only; the delayed
  release samples the synchronized frame-aware Carbine grip-to-muzzle axis.
- Absolute ±24-degree correction covers the full eight-sector interval and
  pursues intent at a frame-rate-independent response of 20.0. It ramps during
  raise, commits through firing, and resumes current intent during recovery.
- Pursuit advances at most once per process frame, so repeated status, muzzle,
  or HUD queries cannot accelerate the weapon or accumulate rotation.
- Spread is applied after the physical baseline; muzzle obstruction uses the
  final shot direction; `bullet.gd` remains collision/damage authority.
- Operator status publishes primitive ballistic solution fields and
  Observatory gauges without exposing collider Nodes to the HUD.
- Procedural 16x16 pip is wired beside the unchanged 48x48 intent reticle and
  hides when offscreen or when ordinary HUD gates hide ranged presentation.
- Required focused smokes, ranged balance regression, import, and main-scene
  boot pass. Moment Forge `combat/ranged_ballistic_alignment` passed in full
  mode after the full-sector pursuit tuning at
  `reports/moment_forge/combat/ranged_ballistic_alignment/20260809T045112-0400`.
  The reviewed reversal frame shows leftward intent while muzzle flash and the
  physical projectile retain the committed rightward barrel line, followed by
  visible barrel/pip convergence. No baseline was accepted or replaced. Earlier
  no-capture repetitions produced an identical required stable fingerprint
  (`20260809T032001-0400_r1` and `20260809T032005-0400_r2`).

- Follow-up audit found that production frame-aware authority still covers only
  E/W/SE/SW. Runtime now refuses stale grip-to-muzzle authority when an
  uncovered octant fails resolution, and the pip implements the documented
  severity grammar. Full N/NE/S/NW promotion remains blocked on complete
  authored upper-body stance/aim/fire tracks and painted-barrel calibration.

The subsequent simplification retired physical-axis ballistic authority,
target-depth prediction status, alignment gauges, and the production ballistic
pip. The resolver remains only where presentation correction/debug calibration
still consumes its pure helpers; it is not firing authority.

## Authority Chain

```text
player input -> accepted world aim point + committed visual sector
frame-aware socket -> muzzle position
muzzle-to-accepted-point direction + per-shot spread -> physical projectile
physical projectile -> actual collision and damage
```

## Validation

- Import and main-scene boot.
- New ballistic aim and HUD pip smokes.
- Existing socket, modular-fire, ready-input, and ranged-balance smokes.
- Moment Forge selection and full capture; never auto-accept a baseline.
