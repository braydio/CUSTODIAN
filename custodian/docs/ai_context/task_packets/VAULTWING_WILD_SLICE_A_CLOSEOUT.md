# Common Vaultwing Wild Slice A Closeout

- Status: `complete_with_presentation_followup`
- Authority: `design/02_features/ambient/VAULTWING_SYSTEM.md`
- Goal: close the wild predator runtime with spatial attacks, organic interest, deterministic perching/retreat, production spawning, and focused validation.
- Files: Vaultwing actor/controller/profile, Vaultwing spawner, contract world marker bridge, `game.tscn`, validation, and current-state documentation.
- Constraints: preserve Asset V2 art and semantic presentation; no bonding, companion commands, mounting, generic enemy refactor, or sprite regeneration.
- Acceptance: spatial dive/bite contact, committed dive direction, HIGH interaction policy, organic player/noise interest, real perch/retreat paths, production `World/Ambient` spawning, 56-strip contract smoke, runtime/world-spawn validation.
- Completed: runtime/profile/spawner closeout work, generic hostile-team integration, living-population accounting, interaction hardening, 56/56 art contract, focused runtime/world-spawn validation, production marker wiring, post-engagement pacing, and the dive-readability/forced-landing Moment Forge scenarios.
- Deferred: Vaultwing production SFX, bonding/companions, and mounting. Authored Vaultwing SFX remains the presentation follow-up.

## Ownership And Timing

- Owner: CUSTODIAN gameplay/runtime
- Agent/session: Codex
- Created: 2026-09-23
- Last updated: 2026-09-23

## Work Surface

- Read: Vaultwing actor/controller/spawner, ambient enemy spawner, contract world loader, Operator hit receiver, NoiseEventBus, validation recipes, and Asset V2 family contract.
- Change: actor interaction gating; behavior tuning and spatial combat; production fauna markers/container/spawner; contract and runtime validation; docs.
- Out of scope: art replacement, bonding, companion behavior, mounting, and generic enemy architecture.

## Plan

1. Centralize tuning and repair spatial/terminal behavior defects.
2. Wire deterministic perception, perches, retreat, and production markers.
3. Add asset/runtime/world-spawn validation and reconcile docs.

## Drift Review

- Primary authority: `VAULTWING_SYSTEM.md`
- `CURRENT_STATE.md`: update after focused validation.
- `CONTEXT.md`: no separate authority identified.
- `FILE_INDEX.md`: update runtime/spawn/validation ownership.
- Local routing/readmes: preserve Asset V2 source/runtime truth.

## Handoff

- Next action: run focused asset contract, Vaultwing runtime, world-spawn, import, and Moment Forge checks.
- Best starting files: `vaultwing_behavior_controller.gd`, `vaultwing.gd`, `vaultwing_spawner.gd`, `contract_world_loader.gd`.
- Validation to run: `vaultwing_asset_contract`, `vaultwing_runtime`, `vaultwing_world_spawn`, Godot import, changed validation, archive-boundary validation.
- Blockers or open questions: production Vaultwing-specific SFX remains deferred unless suitable authored assets are found.
