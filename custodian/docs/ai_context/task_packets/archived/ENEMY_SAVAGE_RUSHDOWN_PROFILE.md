# ENEMY SAVAGE RUSHDOWN PROFILE

- Status: `complete`
- Authority: `design/02_features/animation/ENEMY_SAVAGE_RUNTIME_WIRING.md`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Goal: Make `enemy_savage` a low-discipline rushdown enemy with lower durability, fast two-hit pressure, a distinct pounce, weak self-preservation, and no theft behavior.
- Files: `game/actors/enemies/enemy.gd`, `game/actors/enemies/enemy_savage.tscn`, `game/actors/operator/operator.gd`, `game/actors/enemies/components/enemy_behavior_profile.gd`, focused validation, active design/context docs, and required-asset routing docs.
- Constraints: Preserve deterministic fixed-step ownership; use the shared enemy-hit gateway; do not reuse grunt Falcon Punch; keep current idle-only Savage art as an explicit fallback; root `REQUIRED_ASSETS.md` is the only canonical tracker.
- Acceptance: Scene/profile values match the approved block; Savage cannot steal; aggression exceeds grunt; self-preservation is lower than grunt; chain and pounce are enabled and interruptible; second chain hit costs 22 guard stamina when blocked; focused Savage smokes and project boot pass.
- Completed: Scene/profile stats, WaveManager default profile, chain, pounce, guard-cost override, focused profile/runtime smokes, grunt regressions, full ingest no-op validation, normal project boot, active documentation updates, retired design-path migration, and single-tracker cleanup.
- Deferred: Dedicated Savage movement, chain, pounce, flinch, stagger, and death sheets beyond the currently ingested directional idle suite.
