# DEVCONSOLE INTEGRATION — TASK PACKET

## Packet Status

- Status: ready
- Owner: agent
- Agent/session: devconsole_integration_2026-05-04
- Created: 2026-05-04
- Last updated: 2026-05-04

## Task

Integrate the existing `DevConsole` addon (`custodian/addons/dev-console/`) as the primary debug toggle for the game, keeping `F` mapped to `toggle_unarmed` (unarmed combat profile).

## Outcome

- Pressing `~` (tilde/backtick) toggles the DevConsole in-game
- Custom debug commands are registered: `debug_hud`, `show_cognitive`, `test_spawn`
- `F` key continues to toggle unarmed/Fists combat profile (no change)
- DevConsole is draggable, resizable, and supports command history
- Debug HUD visibility (`UI.show_debug_hud`) can be toggled via console command

## Authority

- Root routing: `custodian/AGENTS.md`
- Local routing: `custodian/docs/ai_context/CURRENT_STATE.md` (line 49: "default HUD is essentials-only; camera/aim/time/director/supply/button diagnostics are hidden unless UI.show_debug_hud is enabled")
- Active runtime: `custodian/project.godot` (DevConsole autoload at line 22)
- DevConsole source: `custodian/addons/dev-console/` (plugin.cfg, dev-console.gd, dev-console.tscn)
- Historical reference only: N/A

## Work Surface

- Files expected to change:
  - `custodian/project.godot` (add `debug_toggle` action if changing from `~` to `F`)
  - `custodian/game/ui/hud/ui.gd` (register custom debug commands with DevConsole)
  - `custodian/docs/ai_context/CURRENT_STATE.md` (update to reflect new debug method)

- Files expected to be read but not changed:
  - `custodian/addons/dev-console/dev-console.gd` (understand registration API)
  - `custodian/addons/dev-console/dev-console.tscn` (understand UI structure)

- Out-of-scope areas:
  - Changing `toggle_unarmed` binding (stays on `F`)
  - Removing existing debug panel in `ui.gd` (keep as fallback)
  - New UI art for console (use existing dev-console theme)

## Constraints

- Deterministic simulation: no changes to simulation authority
- Simulation/UI boundary: debug commands are UI-only, must not affect simulation state
- No new features: integration only, per user instructions
- Minimal scope: register 3-5 useful debug commands, no elaborate debug UI

## Implementation Plan

1. ✅ Read `custodian/addons/dev-console/dev-console.gd` to understand `add_command()` API
2. ✅ Verify DevConsole autoload is active in `project.godot` (line 22: `DevConsole="*uid://ccoijpiv8l45j"`)
3. ⬜ In `ui.gd` `_ready()`: get DevConsole node and register custom commands:
   - `debug_hud` → toggle `UI.show_debug_hud`
   - `show_cognitive` → print cognitive state (if CognitiveState autoload exists)
   - `test_spawn <enemy_type>` → spawn test enemy at operator position
4. ⬜ Test: Press `~` to open console, type `debug_hud`, verify HUD toggles
5. ⬜ Update `CURRENT_STATE.md` to reflect new debug method (DevConsole + `~` key)

## Acceptance

- Runtime behavior:
  - ⬜ Pressing `~` opens/closes DevConsole
  - ⬜ Typing `help` shows registered commands
  - ⬜ Typing `debug_hud` toggles debug HUD visibility
  - ⬜ Typing `cls` clears console output
  - ⬜ `F` key still toggles unarmed combat (no regression)
  - ⬜ Console is draggable and resizable

- Documentation:
  - ⬜ `CURRENT_STATE.md` updated to mention DevConsole as debug method

- Path/reference validation:
  - ✅ DevConsole autoload path verified in `project.godot`

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update?
  - ⬜ Yes — line 49 mentions "UI.show_debug_hud" but doesn't mention DevConsole method
- Does `custodian/docs/ai_context/CONTEXT.md` need an update?
  - No — working model unchanged
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update?
  - No — DevConsole already listed in autoloads
- Does `custodian/AGENTS.md` need an update?
  - No
- Do any design docs need an update?
  - No — debug integration is runtime-only

## Completion Notes

- Implemented:
  - ⬜ DevConsole integration (register 3+ custom commands)
  - ⬜ `~` key toggles console (default DevConsole behavior)

- Validated:
  - ⬜ Godot runtime test pending

- Deferred:
  - Elaborate debug commands ( Phase 2)
  - Custom debug UI art (Phase 2)
  - F12 or other key for alternative debug access

## Next Steps

- Next action: Register custom commands in `ui.gd` `_ready()`
- Best starting files: `custodian/addons/dev-console/dev-console.gd`, `custodian/game/ui/hud/ui.gd`
- Required context: `custodian/project.godot` (DevConsole autoload), `custodian/docs/ai_context/CURRENT_STATE.md`
- Validation to run: Press `~`, type `help`, `debug_hud`, verify behavior
- Blockers or open questions: None
