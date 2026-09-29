# Terminal Overlay Suppression Task Packet

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Hide gameplay UI overlays while the terminal interface is open so the terminal is the only active foreground UI surface.

## Outcome

`ui.gd` now masks legacy HUD labels, minimap/crosshair, `gameplay_overlay` HUD scenes such as `CustodianHUD`, and the dedicated debug screen while `_terminal_open` is true. Closing the terminal restores prior overlay/debug visibility.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime files: `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/hud/custodian_hud.gd`
- Active validation: `custodian/tools/validation/terminal_overlay_visibility_smoke.gd`

## Work Surface

- Changed runtime files: `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/hud/custodian_hud.gd`
- Changed validation: `custodian/tools/validation/terminal_overlay_visibility_smoke.gd`
- Changed docs: AI context current state, context primer, file index, task packet index

## Constraints

- Terminal UI remains visible and interactive.
- Gameplay overlays are suppressed only while terminal focus is active.
- Debug screen desired state is preserved: if it was enabled before terminal open, it returns after close.
- Placement-mode behavior remains compatible with the existing terminal map placement flow.

## Acceptance

- Opening the terminal hides compact gameplay HUD overlays.
- Opening the terminal hides the dedicated debug screen even if debug visibility was enabled.
- Closing the terminal restores prior overlay/debug visibility.
- No giant debug or interaction prompt labels appear over the terminal.
- Focused Godot smoke passes.

## Completion Notes

- Added `gameplay_overlay` / `custodian_hud` groups to `CustodianHUD`.
- Added terminal-aware effective hidden state in `ui.gd`.
- Removed the legacy `TERMINAL ACTIVE` interaction-label overlay while terminal is open.
- Added focused smoke coverage for terminal-open/close overlay behavior.

## Next Steps

- Manual playtest: open the command terminal in the main scene and Home/Sundered Keep contexts; confirm compact HUD, debug screen, minimap, prompt plaques, and legacy labels do not draw over the terminal.
