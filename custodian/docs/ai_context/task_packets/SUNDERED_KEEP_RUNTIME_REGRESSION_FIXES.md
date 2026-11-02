# Sundered Keep Runtime Regression Fixes

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: codex-2026-06-07
- Created: 2026-06-07
- Last updated: 2026-06-07

## Task

Fix overlapping Great Hall roof occlusion, modular sidearm draw looping, and siege objective pressure continuing after the encounter enemies are defeated.

## Outcome

All roof regions above the Operator cut away, sidearm draw/fire phases complete once and transition correctly, and clearing the three required opening-wave siege enemies secures the siege and stops objective damage.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Active runtime/docs files: `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/game/actors/operator/operator.gd`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change: Sundered Keep map runtime/smoke, Operator runtime/smoke, current-state docs
- Files or folders expected to be read but not changed: enemy spawn bridge, authored keep layout
- Out-of-scope areas: new production animation assets, siege encounter redesign

## Constraints

- Determinism concerns: completion follows explicit spawned-enemy lifecycle, not frame-rate-dependent polling.
- Simulation/UI boundary concerns: siege state owns damage shutdown; roof and animation changes remain presentation state.
- Asset requirements: none.
- Compatibility or migration concerns: preserve existing boolean enemy-spawn APIs.
- Clarifying questions or assumptions: the three enemies in the opening gatehouse siege wave are its completion condition; timed reinforcements are not required for victory.

## Implementation Plan

1. Support simultaneous cutaway for overlapping authored interior regions.
2. Start each modular sidearm action phase once and let all layers finish without restart.
3. Track locally spawned siege enemies and secure the siege when none remain.
4. Add focused regression assertions and run headless validation.

## Acceptance

- Runtime behavior: reported roof, sidearm, and siege regressions are resolved.
- Documentation: current state records the corrected behavior.
- Path/reference validation: unchanged runtime paths remain valid.
- Manual validation: deferred to live play.
- Automated/headless validation: Operator modular layers and Sundered Keep large-layout smokes pass.

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md`: update required.
- `custodian/docs/ai_context/CONTEXT.md`: no update required.
- `custodian/docs/ai_context/FILE_INDEX.md`: no update required.
- `custodian/AGENTS.md`: no update required.
- Design docs: existing intended behavior already covers sidearm phase transitions; no authority change required.

## Completion Notes

- Implemented: simultaneous overlapping roof cutaways, one-shot modular sidearm action phases, and opening-wave siege victory shutdown.
- Validated: `operator_modular_layers_smoke.gd`, `sundered_keep_large_layout_smoke.gd`, `git diff --check`, and a headless editor parse pass.
- Deferred: live play feel verification; existing project UID duplicate/unrecognized-UID warnings remain outside this task.

## Next Steps

- Next action: verify the three corrected flows in live play.
- Best starting files: runtime and smoke files listed above.
- Required context: this packet.
- Validation to run: Operator modular layers and Sundered Keep large-layout smokes.
- Blockers or open questions: none.
