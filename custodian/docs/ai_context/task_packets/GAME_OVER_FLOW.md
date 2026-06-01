# Game Over Flow

## Packet Status

- Status: in_progress
- Owner: Codex
- Agent/session: Codex 2026-05-31
- Created: 2026-05-31
- Last updated: 2026-05-31

## Task

Implement the missing runtime slice for `design/02_features/game_over/GAME_OVER_FLOW.md`.

## Outcome

When a fail condition calls `GameState.trigger_game_over(...)`, the world pauses, a modal appears, basic run stats are shown, and the player can restart the current facility scene or leave through the available menu/main-scene fallback.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/game_over/GAME_OVER_FLOW.md`
- Active runtime/docs files: `custodian/game/systems/core/state/game_state.gd`, `custodian/game/ui/`, `custodian/project.godot`, `custodian/docs/ai_context/`
- Historical reference only: legacy Python runtime under `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/systems/core/state/`, `custodian/game/ui/game_over/`, `custodian/project.godot`, targeted validation, AI context docs.
- Files or folders expected to be read but not changed: command-post, wave, enemy, HUD, and scene wiring.
- Out-of-scope areas: production art/audio, main menu creation, campaign meta-progression, broad phase-state rewrite.

## Constraints

- Determinism concerns: stats must be derived from authoritative runtime events, not UI guesses.
- Simulation/UI boundary concerns: `GameState` owns terminal fail state; modal only displays and dispatches restart/menu commands.
- Asset requirements: no production art is required for this MVP.
- Compatibility or migration concerns: preserve the existing `game_over` and `game_over_reason` fields for HUD/debug callers.
- Clarifying questions or assumptions: no main-menu scene currently exists, so Return to Menu should use a configured scene if present and fall back safely.

## Implementation Plan

1. Add a lightweight stats authority and connect it to wave/enemy runtime events.
2. Extend `GameState.trigger_game_over(...)` to pause and show a modal once.
3. Add a small modal scene/script with restart and menu fallback actions.
4. Add a headless smoke test for trigger, stats snapshot, modal display, and restart reset.
5. Update active AI context docs.

## Acceptance

- Runtime behavior: command-post or explicit `GameState.trigger_game_over(...)` shows a game-over modal and pauses the tree.
- Documentation: current state and file index mention the new runtime slice.
- Path/reference validation: new scene/script paths are indexed and loadable.
- Manual validation: destroy command post or call `GameState.trigger_game_over("Command Post destroyed")` in a running scene and choose Restart Facility.
- Automated/headless validation: run the targeted game-over smoke script and Godot headless boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, completion notes in the active game-over spec.

## Completion Notes

- Implemented: pending.
- Validated: pending.
- Deferred: production defeat VFX/audio and a real main-menu scene.

## Next Steps

- Next action: implement and validate the runtime slice.
- Best starting files: `custodian/game/systems/core/state/game_state.gd`, `custodian/game/ui/game_over/`.
- Required context: `design/02_features/game_over/GAME_OVER_FLOW.md`.
- Validation to run: `cd custodian && godot --headless --script tools/validation/game_over_flow_smoke.gd`.
- Blockers or open questions: none.
