# Enemy Marine Tactical Dash V2

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: codex-2026-06-07
- Created: 2026-06-07
- Last updated: 2026-06-07

## Task

Replace repeated marine dash spam with a tactical launch loop and add charged-dash optionality constrained by a shared distance/damage budget.

## Outcome

The marine repositions between attacks, selects quick or charged commits deterministically, predicts target movement during the final windup phase, and exposes a punishable recovery/reset window.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/enemy_objective/ENEMY_MARINE_DASH_ATTACK.md`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/world/sundered_keep/sundered_keep_marine_ambush.gd`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change: marine runtime, Great Hall ambush controller, marine smoke, active design/current-state docs
- Files or folders expected to be read but not changed: marine animation library and current dash assets
- Out-of-scope areas: new marine animation/audio assets and broader enemy behavior architecture

## Constraints

- Determinism concerns: tactical choice must derive from range, target velocity, and previous result without random rolls.
- Simulation/UI boundary concerns: charge allocation and tactics own gameplay values; animation speed/telegraph only present them.
- Asset requirements: reuse the current dash strip and FX.
- Compatibility or migration concerns: preserve existing marine scene and generic spawn paths.
- Clarifying questions or assumptions: use predictive target lock as the third windup-phase mechanic.

## Implementation Plan

1. Add launch-band/reset tactical state.
2. Add quick/charged selection and bounded distance/damage charge allocation.
3. Add final-third predictive target lock and charged animation timing.
4. Hand the Great Hall ambush marine to the shared tactical runtime.
5. Extend focused smoke validation.

## Acceptance

- Runtime behavior: marine cannot immediately chain dash after dash; charged variants trade distance against damage; final windup third locks predicted movement.
- Documentation: active design and current-state describe V2.
- Path/reference validation: existing marine asset paths remain unchanged.
- Manual validation: live combat feel remains recommended.
- Automated/headless validation: marine smoke and Sundered Keep large-layout smoke pass.

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md`: update required.
- `custodian/docs/ai_context/CONTEXT.md`: no update required.
- `custodian/docs/ai_context/FILE_INDEX.md`: no update required.
- `custodian/AGENTS.md`: no update required.
- Design docs: updated before implementation.

## Completion Notes

- Implemented: launch-band evaluation, deterministic quick/charged selection, bounded distance/damage charge allocation, final-third predictive lock with a brighter lock cue, lateral reset, and Great Hall handoff to the shared marine runtime.
- Validated: `authored_vault_grunt_loot_marine_smoke.gd`, `sundered_keep_large_layout_smoke.gd`, `git diff --check`, and a headless editor parse pass.
- Deferred: live combat-feel tuning and additional directional/phase-specific art; existing project UID duplicate/unrecognized-UID warnings remain outside this task.

## Next Steps

- Next action: verify and tune quick/charged marine behavior in live combat.
- Best starting files: marine runtime and focused smoke.
- Required context: this packet and active design doc.
- Validation to run: authored marine smoke and Sundered Keep large-layout smoke.
- Blockers or open questions: none.
