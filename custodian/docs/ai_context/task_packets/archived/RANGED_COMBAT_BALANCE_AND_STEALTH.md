# RANGED COMBAT BALANCE AND STEALTH

- Status: `complete`
- Authority: `design/02_features/balance/COMBAT_BALANCE.md`; normalized implementation spec at `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`
- Goal: Make ranged combat burst-limited and positionally consequential through capped ammo, heat, range falloff, noise-driven perception, search/leash behavior, and ambient hostile camps.
- Files: weapon data/schema/factory, Operator, bullet, ammo cache/supply drops, stealth noise bus, enemy perception/blackboard/state machine, ambient camp/spawner, game scene, active docs, focused validation.
- Constraints: Preserve fixed-step gameplay authority; keep runtime state out of shared weapon resources; retain legacy ammo/status keys; extend the existing enemy behavior stack; do not implement vehicle weapons.
- Acceptance: All phases in the authority brief have a live implementation or an explicitly documented deferment; headless runtime and focused smoke validation pass.
- Completed: Typed/capped ammo and pickups, persistent magazines, range/falloff, movement accuracy, per-weapon heat/overheat, generic noise events, enemy hearing, LOS-loss search/leash, authored/marker ambient camp systems, main-scene camps, status exposure, focused smoke coverage, and active docs.
- Deferred: Production heat UI/art/audio, suppressor inventory, cover/light modifiers, large procedural bases, squad alarms, vehicle-mounted weapon firing.

## Ownership And Timing

- Owner: gameplay/combat + enemy behavior
- Agent/session: Codex
- Created: 2026-06-20
- Last updated: 2026-06-20

## Work Surface

- Read: combat balance authority, combat feel and weapon-data docs, AI context, validation recipes, Operator/projectile/ammo runtime, enemy perception/behavior, procgen/game scene.
- Change: the scoped runtime systems, focused smoke validation, active documentation, and this packet.
- Out of scope: new production assets, full stealth cover/light simulation, vehicle combat, large-scale encounter-base generation.

## Plan

1. Normalize weapon ammo/range/handling/heat/noise data and runtime state.
2. Add generic noise events and connect Operator shots to enemy perception.
3. Add loss-of-contact search/leash behavior and ambient hostile camps.
4. Add status/debug exposure, validate, and update active docs.

## Drift Review

- Primary authority: `design/02_features/balance/COMBAT_BALANCE.md` references stale `custodian/assets/weapons/`; live data is under `custodian/content/weapons/`. The normalized spec records the live paths.
- `CURRENT_STATE.md`: update after runtime validation.
- `CONTEXT.md`: update because NoiseEventBus becomes shared system authority.
- `FILE_INDEX.md`: append new ownership entries without disturbing unrelated in-progress edits.
- Local routing/readmes: `custodian/AGENTS.md` already correctly declares `design/` as active authority; no routing edit required.

## Handoff

- Next action: manual combat-feel and UI/audio follow-up from the normalized spec's Next Agent Slice.
- Best starting files: `operator.gd`, `enemy_perception_component.gd`, `enemy_behavior_state_machine.gd`.
- Validation to run: focused ranged balance smoke, Godot headless boot, JSON parse/schema checks.
- Blockers or open questions: full main-scene boot still reports a pre-existing missing Forlorn Ritualant rubble texture from unrelated dirty worktree changes; no new ranged-balance parse errors remain.
