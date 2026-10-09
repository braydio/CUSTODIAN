# Melee Soft Targeting And Range Readability

- Status: `complete`
- Authority: `design/02_features/combat_feel/MELEE_TARGETING_AND_RANGE_READABILITY.md`
- Goal: aim-relative stable melee selection, honest progressive range feedback, and bounded pre-commit dagger assistance.
- Files: resolver/profile, Operator, procedural target ring, dagger link resources, focused smokes, active combat docs/context.
- Constraints: no homing, teleport, hard lock, damage shortcut, parry-critical coupling, or replacement drive controller; preserve unrelated worktree changes.
- Acceptance: angle beats nearest distance, target hysteresis is stable, green uses shared reliable reach, each link freezes direction/drive, hitbox and `move_and_slide()` remain authority, focused regressions and Moment Forge pass.
- Completed: deterministic scoring/reach resolver, passive target preview, per-link immutable solution, additive 3/4/5 px dagger drive caps, 12/13/14-degree correction, progressive procedural ring, telemetry/status, validation and drift remediation.
- Deferred: hard lock; production review of occlusion penalties; authored ring art; broader weapon opt-in; dedicated feel tuning after playtest.

## Moment Forge

- `combat/melee_soft_target_spacing`, full capture, passed at
  `reports/moment_forge/combat/melee_soft_target_spacing/20260809T153415-0400`.
- The supported fixture demonstrates the ring staying on the aim-relative
  target while a nearer off-axis grunt exists, contracting through approach,
  and changing targets only after redirected intent. Dagger-specific assist is
  proven by focused live-resource/runtime smokes because the fixture exposes
  only its supported unarmed equip action after setup.
- No baseline was accepted or replaced.

## Drift Review

- Corrected stale Combat Feel language that described all Vigil links as shared Chain 01.
- Updated current state, context, file index, validation recipes, and index dates.
- Preserved dedicated Fast 02/Fast 03 animation authority and existing attack-drive no-magnetism contract.
