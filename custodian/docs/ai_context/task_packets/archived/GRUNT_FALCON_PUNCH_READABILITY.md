# Grunt Falcon Punch Readability

- Status: `complete`
- Authority: `design/02_features/animation/ENEMY_GRUNT_RUNTIME_WIRING.md`
- Goal: Make Falcon Punch a deliberate, readable commitment that stops short of the Operator, hard-cancels on parry, and produces clear impact feedback without actor overlap.
- Files: `game/actors/enemies/enemy.gd`, `game/actors/operator/operator.gd`, `tools/validation/grunt_falcon_punch_smoke.gd`, active design and AI-context docs.
- Constraints: Preserve fixed-step gameplay ownership and the shared enemy-hit gateway; use deterministic special cadence; do not add the optional Operator counter-kick in this slice.
- Acceptance: Falcon has a readable target-tracking tell followed by a committed leap, travel stops at a reliable contact point, recovery never drifts forward, parry cancels all Falcon phases, damaging hits invoke Operator impact, recent parry and occupied ally lanes block normal launch, `spawn_grunt falcon` gives deterministic debug access, and focused/current reaction smokes pass.
- Completed: Retuned the live grunt scene with a `0.75s` target-tracking tell, committed leap, forgiving contact envelope, stop-short travel, contact and enemy separation, independent cooldown and deterministic cadence, recent-parry and ally-lane gates, hard parry cancellation, dedicated Operator impact feedback, `spawn_grunt falcon`, focused smoke coverage, and active documentation updates.
- Deferred: Contextual Operator counter-kick remains a separate combat-design slice.
