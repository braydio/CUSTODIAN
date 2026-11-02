# MINIMAP EXPAND AND UTILITY MARKERS

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-08
- Created: 2026-05-08
- Last updated: 2026-05-08

## Task

Add an expandable HUD minimap mode on `M` and show command terminals, vehicles, and turrets on the minimap.

## Outcome

The HUD minimap can toggle between compact and expanded sizes with `M`. Both HUD and terminal minimap instances render distinct markers for the command terminal, vehicle buggy, and turrets.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/MINIMAP_SPEC.md`
- Active runtime/docs files: `custodian/game/ui/minimap/`, `custodian/game/actors/terminal/command_terminal.gd`, `custodian/project.godot`, `custodian/scenes/game.tscn`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/ui/minimap/minimap_controller.gd`
  - `custodian/game/ui/minimap/minimap_view.gd`
  - `custodian/game/actors/terminal/command_terminal.gd`
  - `custodian/project.godot`
  - `custodian/scenes/game.tscn`
  - `design/MINIMAP_SPEC.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - vehicle and turret scripts for group names
- Out-of-scope areas:
  - bitmap minimap icon art
  - pan/zoom controls in expanded minimap
  - click selection for minimap markers

## Constraints

- Determinism concerns: visual-only marker rendering and UI sizing.
- Simulation/UI boundary concerns: minimap reads actor groups but does not own gameplay state.
- Asset requirements: none; markers are procedural.
- Compatibility or migration concerns: terminal-embedded minimap should not expand with `M`.
- Clarifying questions or assumptions: `M` expands/collapses the main HUD minimap only.

## Implementation Plan

1. Add `toggle_minimap_expand` input action on `M`.
2. Add minimap controller compact/expanded sizing and action handling.
3. Add terminal/vehicle/turret marker feeds and renderers.
4. Add command terminal group membership.
5. Update docs and validate.

## Acceptance

- Runtime behavior: `M` toggles the HUD minimap expanded/compact.
- Runtime behavior: terminal minimap instance remains embedded and does not expand with `M`.
- Runtime behavior: command terminal, vehicle, and turret markers render with distinct symbols/colors.
- Documentation: current state and minimap spec reflect the new markers and expand action.
- Automated/headless validation: relevant scripts parse and scene boot passes.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, `design/MINIMAP_SPEC.md`.

## Completion Notes

- Implemented: added `toggle_minimap_expand` on `M`, compact/expanded HUD minimap sizing, terminal/vehicle/turret runtime marker feeds, procedural marker shapes, command terminal group registration, and terminal minimap opt-out from expansion.
- Validated: `godot --headless --check-only --script res://game/ui/minimap/minimap_controller.gd`; `godot --headless --check-only --script res://game/ui/minimap/minimap_view.gd`; `godot --headless --check-only --script res://game/actors/terminal/command_terminal.gd`; `godot --headless --quit --scene res://scenes/game.tscn`.
- Deferred: authored bitmap icon art, marker hover/selection, minimap pan/zoom.

## Next Steps

- Next action: optional playtest tuning for expanded size and marker colors.
- Best starting files: `custodian/game/ui/minimap/minimap_controller.gd`, `custodian/game/ui/minimap/minimap_view.gd`
- Required context: existing actor group names.
- Validation to run: Godot script parse and scene boot.
- Blockers or open questions: none.
