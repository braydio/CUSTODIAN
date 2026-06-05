# Debug Screen UI Task Packet

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-04
- Created: 2026-06-04
- Last updated: 2026-06-04

## Task

Replace scattered normal-HUD debug labels with a working debug screen opened by F12 or the existing `debug_hud` DevConsole command.

## Outcome

Normal gameplay keeps debug diagnostics off the HUD. Debug mode now opens a tabbed overlay screen with runtime, player, combat, world, systems, and inventory/cognitive snapshots.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/20_features/in_progress/BLACK_RELIQUARY_UI.md`
- Active runtime/docs files: `custodian/game/ui/hud/`, `custodian/docs/ai_context/*`
- Historical reference only: legacy Python runtime

## Work Surface

- Changed runtime files: `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/hud/debug_screen.gd`, `custodian/game/ui/hud/debug_screen.tscn`
- Added validation: `custodian/tools/validation/debug_screen_smoke.gd`
- Changed docs: AI context pack and Black Reliquary UI design doc
- Out-of-scope areas: final visual screenshot tuning, new debug art assets, legacy Python runtime

## Constraints

- Determinism concerns: debug UI is read-only and must not mutate simulation state.
- Simulation/UI boundary concerns: debug screen reads snapshots from existing autoloads/groups/helpers; gameplay authority remains outside UI.
- Asset requirements: no new assets required.
- Compatibility concerns: keep existing F12/debug-toggle and `debug_hud` command path working.

## Implementation Plan

1. Add a reusable debug screen scene/script under `game/ui/hud/`.
2. Replace the old generated inventory/cognitive debug box with the new screen.
3. Keep `debug_hud [on|off]` and F12 as toggle inputs.
4. Force old scattered diagnostic HUD nodes to remain hidden in normal and debug mode.
5. Add a focused smoke test and update docs.

## Acceptance

- Runtime behavior: F12/debug command opens a dedicated debug screen instead of normal HUD label clutter.
- Documentation: AI context and Black Reliquary UI docs describe debug-screen ownership.
- Path/reference validation: debug screen scene loads and exposes expected API.
- Automated/headless validation: touched HUD scripts check-only and debug screen smoke pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, Black Reliquary UI behavior rules.

## Completion Notes

- Implemented: dedicated tabbed debug screen, `ui.gd` snapshot feed, F12/DevConsole toggle compatibility, legacy diagnostic label suppression, and smoke test.
- Validated: debug screen script check-only, `ui.gd` check-only, debug screen smoke, Black Reliquary UI smoke, and Home beginning smoke.
- Deferred: in-editor visual pass for exact overlay spacing and tab readability.

## Next Steps

- Next action: run an in-editor F12 visual check during normal play and terminal-open play.
- Best starting files: `custodian/game/ui/hud/debug_screen.gd`, `custodian/game/ui/hud/ui.gd`
- Required context: debug screen is read-only and must not become gameplay authority.
- Validation to run: `cd custodian && godot --headless --script res://tools/validation/debug_screen_smoke.gd`
- Blockers or open questions: none.
