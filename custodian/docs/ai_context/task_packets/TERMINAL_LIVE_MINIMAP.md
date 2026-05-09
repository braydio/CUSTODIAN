# TERMINAL LIVE MINIMAP

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-08
- Created: 2026-05-08
- Last updated: 2026-05-08

## Task

Replace the command terminal's placeholder/legacy tactical map preview with the same live custom minimap used by the HUD.

## Outcome

The terminal map panel displays live procgen terrain and dynamic actor pips through the shared minimap controller/view path, while terminal map click-to-place behavior continues to convert panel clicks into world positions.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/MINIMAP_SPEC.md`, `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
- Active runtime/docs files: `custodian/game/ui/minimap/`, `custodian/game/ui/hud/ui.gd`, `custodian/scenes/game.tscn`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/ui/minimap/minimap_view.gd`
  - `custodian/game/ui/minimap/minimap_controller.gd`
  - `custodian/game/ui/hud/ui.gd`
  - `custodian/scenes/game.tscn`
  - `design/MINIMAP_SPEC.md`
  - `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/game/ui/terminal/terminal_map_preview.gd`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Out-of-scope areas:
  - fog-of-war/reveal masking
  - new minimap art frame
  - terminal page layout redesign

## Constraints

- Determinism concerns: minimap remains visual-only and reads authoritative procgen state.
- Simulation/UI boundary concerns: terminal click conversion may request placement systems, but the minimap itself does not own placement.
- Asset requirements: none.
- Compatibility or migration concerns: keep terminal scroll handling and map click-to-place behavior.
- Clarifying questions or assumptions: the user wants the terminal panel to reuse the live tactical minimap now, not wait for a separate expanded map mode.

## Implementation Plan

1. Add minimap view/controller helpers for immediate refresh and local-position to world-position conversion.
2. Replace the terminal `MapPreview` `TextureRect` with an instance of `minimap_panel.tscn`.
3. Update HUD terminal preview refresh and input handling to route through the live minimap control.
4. Update active docs and run headless validation.

## Acceptance

- Runtime behavior: terminal map panel displays live minimap data, not generated placeholder pixels.
- Runtime behavior: terminal map hover/click still resolves world positions for placement preview/place actions.
- Documentation: design/context/task packet reflect terminal minimap reuse.
- Path/reference validation: all touched runtime paths remain under `custodian/`.
- Automated/headless validation: Godot script parse and scene boot pass without new script errors.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No; existing minimap and terminal entries remain valid.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, `design/MINIMAP_SPEC.md` and terminal spec note.

## Completion Notes

- Implemented: the terminal `MapPreview` is now an instance of `res://game/ui/minimap/minimap_panel.tscn`; `MinimapController` exposes `refresh_now()` and `local_to_world()`; `MinimapView` converts local panel coordinates through procgen minimap helpers; HUD terminal preview refresh/input no longer depends on the old generated texture bounds.
- Validated: `godot --headless --check-only --script res://game/ui/minimap/minimap_view.gd`; `godot --headless --check-only --script res://game/ui/minimap/minimap_controller.gd`; `godot --headless --check-only --script res://game/ui/hud/ui.gd`; `godot --headless --quit --scene res://scenes/game.tscn`.
- Deferred: no manual viewport screenshot tuning; the old `TerminalMapPreview` texture renderer remains as legacy code until terminal decursification removes all fallback preview paths.

## Next Steps

- Next action: manually inspect terminal map sizing in a graphical Godot run and tune `MapPreview.custom_minimum_size` if needed.
- Best starting files: `custodian/game/ui/minimap/minimap_controller.gd`, `custodian/game/ui/hud/ui.gd`, `custodian/scenes/game.tscn`
- Required context: `design/MINIMAP_SPEC.md`, `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
- Validation to run: Godot script parse and game scene boot.
- Blockers or open questions: none.
