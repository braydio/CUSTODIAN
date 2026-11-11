# Actor Relationship Foundation V1.1 — Closing Summary

## Delivered

- Preserved legacy `neutral` projectile permissiveness without changing the
  semantic meaning of neutral allegiance.
- Revalidated turret candidates during pruning, acquisition, retention, and
  firing so dynamic allegiance and Vaultwing flight-band changes release stale
  targets.
- Revalidated CombatDrone autonomous and retained targets through the shared
  relationship resolver.
- Added Vaultwing's semantic `has_hostile_intent_toward()` hook and made
  EngagementTracker prefer it before legacy Enemy inspection.
- Added target-team fallback to relationship resolution and rejected invalid
  allegiance mutations without changing the current disposition.
- Expanded the relationship smoke for ordinary Enemy fallback,
  neutral-projectile compatibility, and invalid-allegiance rejection.
- Strengthened world-spawn smoke with player-start exclusion coverage.
- Updated the Vaultwing handoff, current state, and file index to point to
  Slice B bonding as the next feature.

## Verification

Passed focused validation:

- `actor_relationship_contract`
- `vaultwing_runtime`
- `vaultwing_world_spawn`

The Godot editor/headless class scan completed far enough to register all
modified relationship, turret, drone, Vaultwing, and engagement scripts.

## Deferred / not changed

- No bonding progression, persistence identity, or companion behavior was
  implemented.
- No Enemy.gd, AmbientCritterManager, projectile architecture, or generic NPC
  refactor was attempted.
- The production candidate-tile builder remains outside the bounded world-spawn
  fixture; the fixture exercises the live marker-placement seam and exclusion
  behavior without duplicating candidate generation.
- Vaultwing-specific production SFX remain a presentation follow-up.

## Notes

The shared worktree contained unrelated faction/lore/audio/asset changes from
another session. They were not staged as part of this slice. The implementation
landed in the concurrent commit that also added the repository closing-summary
rule; this file is the explicit V1.1 follow-up record required by that rule.
