# Enemy Marine Dash Tuning

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: codex-2026-06-11
- Created: 2026-06-11
- Last updated: 2026-06-11

## Task

Tune the tactical marine dash so it connects more reliably without reverting to spam behavior.

## Outcome

The marine dash lands more consistently, charged commits still trade distance against damage, and the dash remains readable and punishable.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/enemy_objective/ENEMY_MARINE_DASH_ATTACK.md`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/actors/enemies/enemy_marine.tscn`, `custodian/game/world/sundered_keep/sundered_keep_marine_ambush.gd`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change: marine runtime, marine scene defaults, marine smoke, current-state docs
- Files or folders expected to be read but not changed: marine animation assets and tactical ambush scene
- Out-of-scope areas: new art assets or a different marine behavior architecture

## Constraints

- Determinism concerns: tuning should stay in deterministic state and geometry, not random spread.
- Simulation/UI boundary concerns: use presentation to signal the lock, not to change hit authority.
- Asset requirements: reuse existing marine dash body/FX sheets.
- Compatibility or migration concerns: preserve the tactical V2 behavior model.
- Clarifying questions or assumptions: the main complaint is under-hit reliability, so widen contact before adding more complexity.

## Implementation Plan

1. Widen the dash hit envelope and sharpen the lock cue.
2. Raise base impact slightly so successful hits read clearly.
3. Keep the tactical loop and recovery/reset intact.
4. Update smoke and docs to the tuned values.

## Acceptance

- Runtime behavior: the dash lands more often in ordinary combat.
- Documentation: active design/current-state reflect the tuned values.
- Path/reference validation: scene and runtime paths remain valid.
- Manual validation: live feel remains recommended.
- Automated/headless validation: marine and Great Hall smokes pass.

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md`: update required.
- `custodian/docs/ai_context/CONTEXT.md`: no update required.
- `custodian/docs/ai_context/FILE_INDEX.md`: no update required.
- `custodian/AGENTS.md`: no update required.
- Design docs: updated before implementation.

## Completion Notes

- Implemented: marine dash damage, knockback, hit window, reach, prediction, and reset tuning were applied in runtime and scene defaults.
- Validated: `authored_vault_grunt_loot_marine_smoke.gd`, `sundered_keep_large_layout_smoke.gd`, `godot --headless --editor --quit-after 2`, and `git diff --check`.
- Deferred: live combat-feel tuning beyond this reliability pass.

## Next Steps

- Next action: none for this packet.
- Best starting files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/actors/enemies/enemy_marine.tscn`, `custodian/tools/validation/authored_vault_grunt_loot_marine_smoke.gd`, `custodian/tools/validation/sundered_keep_large_layout_smoke.gd`.
- Required context: this packet and the tactical dash packet.
- Validation to run: re-run only if marine combat feel changes again.
- Blockers or open questions: none.
