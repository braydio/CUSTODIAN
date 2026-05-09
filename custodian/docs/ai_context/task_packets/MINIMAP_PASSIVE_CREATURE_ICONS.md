# MINIMAP PASSIVE CREATURE ICONS

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-08
- Created: 2026-05-08
- Last updated: 2026-05-08

## Task

Differentiate passive creatures such as Shrumbs from hostile enemies on the shared minimap.

## Outcome

Hostile enemies remain red dots. Passive ambient creatures render with a separate non-hostile marker so the HUD and terminal minimap both distinguish them.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/MINIMAP_SPEC.md`
- Active runtime/docs files: `custodian/game/ui/minimap/minimap_view.gd`, `custodian/game/actors/enemies/enemy.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/ui/minimap/minimap_view.gd`
  - `design/MINIMAP_SPEC.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/game/ui/minimap/minimap_controller.gd`
  - `custodian/game/actors/enemies/enemy.gd`
- Out-of-scope areas:
  - adding bitmap icon assets
  - changing enemy groups or AI behavior

## Constraints

- Determinism concerns: visual-only minimap rendering.
- Simulation/UI boundary concerns: minimap reads passive/ambient state but does not mutate actor state.
- Asset requirements: none; use a procedural marker until authored icons exist.
- Compatibility or migration concerns: terminal minimap uses the same view, so this should apply there automatically.
- Clarifying questions or assumptions: "passive creatures" means nodes in `ambient_critter` or nodes reporting `is_passive_enemy()`.

## Implementation Plan

1. Add passive creature marker styling to `MinimapView`.
2. Classify enemy nodes during minimap draw and render passive markers separately from hostile red dots.
3. Update docs and run headless validation.

## Acceptance

- Runtime behavior: hostile enemies render as red dots.
- Runtime behavior: passive creatures render as a distinct non-red marker.
- Documentation: current state and minimap spec mention passive creature icons.
- Automated/headless validation: minimap view script parse and game scene boot pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, `design/MINIMAP_SPEC.md`.

## Completion Notes

- Implemented: `MinimapView` now classifies `ambient_critter` / `is_passive_enemy()` actors separately from hostiles and draws passive creatures with a green diamond marker while keeping hostiles as red dots.
- Validated: `godot --headless --check-only --script res://game/ui/minimap/minimap_view.gd`; `godot --headless --quit --scene res://scenes/game.tscn`.
- Deferred: authored bitmap minimap icons; the current marker is procedural.

## Next Steps

- Next action: manually inspect HUD and terminal minimap readability in a graphical run.
- Best starting files: `custodian/game/ui/minimap/minimap_view.gd`
- Required context: passive enemy methods/groups in `custodian/game/actors/enemies/enemy.gd`
- Validation to run: Godot script parse and game scene boot.
- Blockers or open questions: none.
