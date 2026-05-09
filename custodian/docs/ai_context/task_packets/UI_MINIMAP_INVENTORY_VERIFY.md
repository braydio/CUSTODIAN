# UI Minimap Inventory Verify

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Verify and repair HUD minimap visibility and the attempted inventory UI `I` key toggle.

## Outcome

The custom minimap is not hidden by the debug HUD gate, does not block world input, and remains visible in the normal HUD. The inventory UI is loaded by the live game scene as a hidden overlay and can open/close from the `I` key.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/MINIMAP_SYSTEM.md`
- Active runtime/docs files: `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/minimap/`, `custodian/game/ui/inventory/`, `custodian/scenes/game.tscn`, `custodian/project.godot`
- Historical reference only: legacy Python runtime docs

## Work Surface

- Files or folders expected to change: HUD UI script, game scene, inventory UI scene/script, AI context docs
- Files or folders expected to be read but not changed: minimap controller/view scripts, project input map
- Out-of-scope areas: inventory gameplay data model expansion, minimap visual redesign

## Constraints

- Determinism concerns: UI toggles must not alter simulation state.
- Simulation/UI boundary concerns: minimap and inventory remain presentation/input UI only.
- Asset requirements: no new assets.
- Compatibility or migration concerns: inventory currently has a raw `KEY_I` handler; keep that working and prefer an input action if present.
- Clarifying questions or assumptions: the forgotten third item is left untouched until the user remembers it.

## Implementation Plan

1. Inspect current minimap and inventory scene wiring.
2. Move minimap out of the debug-only HUD node set.
3. Mount the inventory scene in the live game UI and repair any scene loading issues.
4. Validate scripts and full headless boot.

## Acceptance

- Runtime behavior: minimap is normally visible; inventory overlay opens/closes on `I`.
- Documentation: current state and task packet reflect the repair.
- Path/reference validation: scene resources resolve.
- Manual validation: scene tree/status inspection confirms nodes are mounted.
- Automated/headless validation: parse checks and headless boot pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes if inventory UI becomes live scene wiring.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: moved minimap into the essential HUD visibility set, added `toggle_inventory` on `I`, repaired `inventory_ui.tscn` resource declarations, mounted `InventoryUI` under the live `UI` CanvasLayer, and made the inventory script toggle/open safely.
- Validated: `inventory_ui.gd` check-only, `ui.gd` check-only, inventory scene headless load, and full game scene headless boot.
- Deferred: the third user item is unknown; inventory still uses current sample/Shrumb item loading rather than a full gameplay inventory integration pass.

## Next Steps

- Next action: implement the scene/script repairs.
- Best starting files: `custodian/scenes/game.tscn`, `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/inventory/inventory_ui.tscn`
- Required context: custom minimap is meant to remain visible with the minimal HUD.
- Validation to run: Godot script checks and headless game boot.
- Blockers or open questions: third requested item is currently unknown.
