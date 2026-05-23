# FAB TERMINAL DEPLOYABLE

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-10
- Created: 2026-05-10
- Last updated: 2026-05-10

## Task

Make the in-world fabrication terminal pickup-able and redeployable while keeping the existing terminal HUD shell and source sheets.

## Outcome

The world terminal can be picked up with the build interaction, carried as a ghost, and redeployed at a new world position. The HUD shell and fabrication page still open from the same terminal node.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
- Active runtime/docs files: `custodian/game/actors/terminal/command_terminal.gd`, `custodian/game/systems/core/systems/terminal_deployment.gd`, `custodian/scenes/game.tscn`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: older static-only command terminal behavior

## Work Surface

- Files or folders expected to change: `custodian/game/actors/terminal/command_terminal.gd`, `custodian/game/systems/core/systems/terminal_deployment.gd`, `custodian/scenes/game.tscn`, active AI context docs
- Files or folders expected to be read but not changed: terminal UI shell widgets, fabrication autoloads
- Out-of-scope areas: new terminal art, terminal HUD redesign, save/load persistence

## Constraints

- Determinism concerns: pickup/redeploy should not mutate simulation state beyond terminal placement.
- Simulation/UI boundary concerns: UI shell stays separate from world deployment logic.
- Asset requirements: reuse the existing terminal source sheets for now.
- Compatibility or migration concerns: keep the current terminal shell entrypoint unchanged.
- Clarifying questions or assumptions: use the build interaction as the pickup/redeploy trigger for now.

## Implementation Plan

1. Add a terminal deployment runtime node and terminal carry/deploy state.
2. Wire operator build input to pick up or redeploy the terminal before wall build fallback.
3. Update the active design and context docs.

## Acceptance

- Runtime behavior: the terminal can be picked up and redeployed in world space.
- Documentation: current state, file index, and terminal spec describe the deployable terminal slice.
- Path/reference validation: the new deployment script and scene node load correctly.
- Manual validation: build interaction picks up the terminal and allows redeploying it.
- Automated/headless validation: script load check for the new deployment runtime script.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Yes

## Completion Notes

- Implemented: added a dedicated terminal deployment runtime node, carried-state handling on `CommandTerminal`, and operator build-input routing for pickup/redeploy.
- Implemented: added a dedicated terminal deployment runtime node, carried-state handling on `CommandTerminal`, and operator build-input routing for pickup/redeploy. The redeploy visual reuses the pickup sheet in reverse.
- Validated: headless script load check succeeded for `command_terminal.gd`, `terminal_deployment.gd`, and `scenes/game.tscn`.
- Deferred: dedicated pickup icon / art pass.

## Next Steps

- Next action: playtest the pickup/redeploy feel and decide whether the terminal should snap to grid or remain free-positioned.
- Best starting files: `custodian/game/systems/core/systems/terminal_deployment.gd`
- Required context: current terminal HUD shell and world terminal prop
- Validation to run: runtime smoke test in-editor
- Blockers or open questions: none
